extends "res://tests/kit/harness.gd"
## Objective text, crane-sequence ticking and manual load checks.
class Crane extends "res://scripts/service_crane.gd":
	func _refresh() -> void:pass
const Objectives = preload("res://scripts/manual_objectives.gd")
func _initialize() -> void:call_deferred("run")

func same_ticks(state: Dictionary, want: Array) -> bool:
	var got: Array = state.ticked
	if got.size() != want.size():return false
	for i in want.size():
		if bool(got[i]) != bool(want[i]):return false
	return true

func part_kind(parts: Dictionary, family: String) -> String:
	for kind in parts:
		if str(parts[kind].get("family","")) == family:return str(kind)
	return ""

func manual_of(page: Dictionary) -> Dictionary:
	return {"parts":{},"assemblies":{"leg":{"slots":{"a":{"requires":[]},"b":{"requires":["a"]}},"manual":[page]}}}

func page_named(manual: Array, title: String) -> Dictionary:
	for step in manual:
		if str(step.title) == title:return step
	return {}

func joined(lines: Array) -> String:
	var text := ""
	for line in lines:text += str(line)+" | "
	return text

func option_label(options: Array, action: String) -> String:
	for option in options:
		if str(option.action) == action:return str(option.label)
	return ""

func plain_menu(options: Array) -> bool:
	for option in options:
		var label := str(option.label)
		if label.contains("pickup") or label.contains("delivery") or label.contains("Put back"):return false
	return true

func run() -> void:
	var presentation = {"objectives":[
		{"op":"operate","machine":"leg_rail","command":"table:hip"},
		{"op":"seat","slot":"left_leg","via":{"machine":"leg_rail","command":"rise"}},
		{"op":"fit","slots":["bolt"]},
		{"op":"operate","machine":"captive_controls","command":"lock"}]}
	var original = presentation.duplicate(true)
	expect(Objectives.display_indices(presentation,{})==[0,1,2,3],"first use displays all typed objectives")
	expect(Objectives.display_indices(presentation,{"repeat":true,"machines":["leg_rail"]})==[2,3],"repeat hides only procedure machine objectives, including seating")
	expect(presentation==original,"procedure presentation leaves physical evidence and supplies intact")
	var game = preload("res://tests/kit/model_workshop.gd").new();root.add_child(game)
	expect(game.setup().is_empty(),"authored stock configures")
	var front = preload("res://tests/kit/manual_fronts.gd").new();game.add_child(front);front.equipment_id="workshop_access";game.equipment.register(front)
	var crane = Crane.new();game.add_child(crane);crane.game = game
	crane.equipment_id = "service_crane";game.equipment.register(crane)
	crane.tasks = preload("res://scripts/leg_bay_layout.gd").layout().crane.tasks
	crane.task = "shin";crane.uid = "LG-100__001";crane.config = {"spec":crane.tasks.shin}
	crane.END_IDS = ["a","b"]
	crane.endpoints = {"a":{"state":"stowed","point":""},"b":{"state":"stowed","point":""}}
	crane.station = "park";crane.raised = true;crane.motion = "";crane.moving = false
	expect(crane.command_label("down") == "Lower crane","down label")
	expect(crane.command_label("up") == "Raise crane","up label")
	expect(crane.command_label("pickup","shin") == "Move to Left shin rig","pickup label")
	expect(crane.command_label("go:receiver","shin") == "Move to Limb Bay","receiver label")
	expect(crane.command_label("connect") == "Attach magnetic connectors","connect label")
	var page = {"goal":"g","slots":["shin"],"objectives":[
		{"op":"operate","machine":"service_crane","command":"pickup","task":"shin"},
		{"op":"operate","machine":"service_crane","command":"down"},
		{"op":"connect","machine":"service_crane"},
		{"op":"operate","machine":"service_crane","command":"up"},
		{"op":"operate","machine":"service_crane","command":"go:receiver","task":"shin"},
		{"op":"seat","slot":"shin","via":{"machine":"service_crane","command":"down"}}]}
	var parked = Objectives.evaluate(game,"left_leg",page)
	expect(same_ticks(parked,[false,false,false,false,false,false]) and parked.current == 0,"parked crane ticks nothing, got "+str(parked.ticked)+" current "+str(parked.current))
	crane.station = "source"
	var at_source = Objectives.evaluate(game,"left_leg",page)
	expect(same_ticks(at_source,[true,false,false,false,false,false]),"raised at source ticks pickup, got "+str(at_source.ticked))
	crane.motion = "down";crane.moving = true
	var lowering = Objectives.evaluate(game,"left_leg",page)
	expect(same_ticks(lowering,[true,false,false,false,false,false]),"lowering does not flicker the checklist, got "+str(lowering.ticked))
	crane.raised = false;crane.motion = "";crane.moving = false
	var lowered = Objectives.evaluate(game,"left_leg",page)
	expect(same_ticks(lowered,[true,true,false,false,false,false]),"lowered at source ticks pickup and down, got "+str(lowered.ticked))
	crane.endpoints.a.state = "attached"
	var one = Objectives.evaluate(game,"left_leg",page)
	expect(one.counts[2] == "1/2" and not one.ticked[2],"one connector is 1/2 and connect stays open, got "+str(one.counts)+" "+str(one.ticked))
	crane.endpoints.b.state = "attached"
	var both = Objectives.evaluate(game,"left_leg",page)
	expect(both.ticked[2],"both connectors tick connect, got "+str(both.ticked))
	crane.raised = true
	var lifted = Objectives.evaluate(game,"left_leg",page)
	expect(same_ticks(lifted,[true,true,true,true,false,false]),"raised with the load ticks four, got "+str(lifted.ticked))
	crane.station = "receiver"
	var delivered = Objectives.evaluate(game,"left_leg",page)
	expect(same_ticks(delivered,[true,true,true,true,true,false]),"delivery ticks five, got "+str(delivered.ticked))
	crane.raised = false
	var seated = Objectives.evaluate(game,"left_leg",page)
	expect(not seated.ticked[5],"lowered crane alone does not install the shin")
	game.model.assemblies.left_leg.slots.shin = "LG-100__001"
	seated = Objectives.evaluate(game,"left_leg",page)
	expect(same_ticks(seated,[true,true,true,true,true,true]) and seated.machine_complete,"lowered at delivery completes the machine sequence, got "+str(seated.ticked)+" complete "+str(seated.machine_complete))
	crane.raised = true
	game.model.assemblies.left_leg.slots.shin = ""
	var lifted_off = Objectives.evaluate(game,"left_leg",page)
	expect(same_ticks(lifted_off,[true,true,true,true,true,false]),"lifting off the seat steps the checklist back, got "+str(lifted_off.ticked))
	var texts: Array[String] = []
	for objective in page.objectives:texts.append(Objectives.text(game,"left_leg",objective))
	expect(texts == ["Crane console: Move to Left shin rig","Crane console: Lower crane","Crane: Attach magnetic connectors","Crane console: Raise crane","Crane console: Move to Limb Bay","Crane console: Lower crane to seat LG-100"],"shin objective text, got "+str(texts))
	expect(Objectives.text(game,"foot",{"op":"seat","slot":"pitch"}) == "Seat the prepared FA-500-P","pitch seat names the prepared actuator, got "+Objectives.text(game,"foot",{"op":"seat","slot":"pitch"}))
	var parts: Dictionary = game.model.definitions.parts
	var washer := part_kind(parts,"W-12")
	var screw := part_kind(parts,"H-12040")
	expect(not washer.is_empty() and not screw.is_empty(),"part families W-12 and H-12040 exist")
	var pairs: Array = []
	for _i in 4:pairs.append(washer)
	for _i in 4:pairs.append(screw)
	var fastened := Objectives.fit_text(parts,pairs)
	expect(fastened == "Fasten 4 × W-12 + H-12040","equal pairs fasten by family, got "+fastened)
	var single := Objectives.fit_text(parts,[washer])
	expect(single == "Fit "+str(parts[washer].title),"single fit uses the part title, got "+single)
	var located := Objectives.fit_text(parts,[washer],"upper holes")
	expect(located == "Fit "+str(parts[washer].title)+" · upper holes","where suffix, got "+located)
	var pin := part_kind(parts,"FA-221")
	var keeper := part_kind(parts,"FA-222")
	var screw30 := part_kind(parts,"H-12030")
	expect(not pin.is_empty() and not keeper.is_empty() and not screw30.is_empty(),"part families FA-221, FA-222 and H-12030 exist")
	var mixed := Objectives.fit_text(parts,[pin,keeper,washer,screw30],"base end")
	expect(mixed == "Fit FA-221, FA-222, W-12, H-12030 · base end","count 1 omits the multiplier, got "+mixed)
	var repeated := Objectives.fit_text(parts,[washer,washer,screw])
	expect(repeated == "Fit 2 × W-12, H-12040","counts above 1 keep the multiplier, got "+repeated)
	var content = JSON.parse_string(FileAccess.get_file_as_string("res://assets/robot-content.json"))
	var lock_ids: Array = content.equipment.captive_controls.keys()
	var layout = JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop-layout.json"))
	var supports_script = preload("res://scripts/module_supports.gd")
	var rig_commands: Array = supports_script.MANUAL_COMMANDS.duplicate()
	rig_commands.append_array(supports_script.template_commands(layout.workshop.bulky_fixture.templates.keys()))
	var commands = {"service_crane":preload("res://scripts/service_crane.gd").MANUAL_COMMANDS,"foot_carrier":preload("res://scripts/foot_carrier.gd").MANUAL_COMMANDS,"module_supports":rig_commands,"leg_rail":preload("res://scripts/indexed_leg_rail.gd").MANUAL_COMMANDS,"captive_controls":preload("res://scripts/captive_controls.gd").lock_commands(lock_ids),"core_guide":preload("res://scripts/core_guide.gd").MANUAL_COMMANDS,"backpack_hinge":preload("res://scripts/backpack_hinge.gd").MANUAL_COMMANDS}
	commands["workshop_access"] = preload("res://tests/kit/manual_fronts.gd").MANUAL_COMMANDS
	commands["joint_restraints"] = preload("res://scripts/passive_joint_restraints.gd").command_ids(layout.restraints)
	var shoulder_commands = preload("res://scripts/shoulder_support.gd").MANUAL_COMMANDS
	commands["left_shoulder"] = shoulder_commands
	commands["right_shoulder"] = shoulder_commands
	for receiver_id in content.equipment.receivers:
		var receiver_spec: Dictionary = content.equipment.receivers[receiver_id]
		var receiver_commands: Array = []
		var captive = receiver_spec.get("captive_slots", [])
		if captive is Array and not captive.is_empty():receiver_commands.append("fasten")
		for operation in receiver_spec.get("operations", []):
			receiver_commands.append("release:"+str(operation.id))
		if not receiver_commands.is_empty():commands[receiver_id] = receiver_commands
	var good = {"title":"Bolt the flange","goal":"Fasten the flange","view":"components","slots":["a","b"],"objectives":[{"op":"fit","slots":["a"]},{"op":"fit","slots":["b"]}]}
	var good_errors = Objectives.errors(manual_of(good),commands)
	expect(good_errors.is_empty(),"valid page has no objective errors: "+joined(good_errors))
	var duplicate = {"title":"Twice","goal":"g","view":"components","slots":["a"],"objectives":[{"op":"fit","slots":["a","a"]}]}
	expect(not Objectives.errors(manual_of(duplicate),commands).is_empty(),"duplicate slot is rejected")
	var mismatch = {"title":"Miss","goal":"g","view":"components","slots":["a","b"],"objectives":[{"op":"fit","slots":["a"]}]}
	expect(not Objectives.errors(manual_of(mismatch),commands).is_empty(),"slot mismatch is rejected")
	var unknown = {"title":"Move","goal":"g","view":"components","slots":[],"objectives":[{"op":"operate","machine":"service_crane","command":"fly"}]}
	expect(not Objectives.errors(manual_of(unknown),commands).is_empty(),"unknown command is rejected")
	var untasked = {"title":"Deliver","goal":"g","view":"components","slots":[],"objectives":[{"op":"operate","machine":"service_crane","command":"go:receiver"}]}
	var untasked_errors = Objectives.errors(manual_of(untasked),commands)
	expect(not untasked_errors.is_empty() and joined(untasked_errors).contains("go:receiver needs a task"),"go:receiver without a task is rejected: "+joined(untasked_errors))
	var goalless = {"title":"Bolt","view":"components","slots":["a"],"objectives":[{"op":"fit","slots":["a"]}]}
	expect(not Objectives.errors(manual_of(goalless),commands).is_empty(),"missing goal is rejected")
	var prepared = {"title":"Done","goal":"g","view":"prepared","slots":["a"],"objectives":[{"op":"fit","slots":["a"]}]}
	expect(not Objectives.errors(manual_of(prepared),commands).is_empty(),"objectives on a prepared page are rejected")
	var reversed = {"title":"Order","goal":"g","view":"components","slots":["a","b"],"objectives":[{"op":"fit","slots":["b"]},{"op":"fit","slots":["a"]}]}
	var order_errors = Objectives.errors(manual_of(reversed),commands)
	expect(not order_errors.is_empty() and joined(order_errors).contains("before its prerequisite"),"dependant before its prerequisite is rejected: "+joined(order_errors))
	var authored = Objectives.errors(preload("res://scripts/workshop_content.gd").load_workshop().data,commands)
	expect(authored.is_empty(),"authored manuals have no objective errors: "+joined(authored))
	var definitions: Dictionary = game.model.definitions.assemblies
	var left_definition := str(game.model.assemblies["left_leg"].definition)
	for def_id in ["pitch_actuator","right_pitch_actuator","foot","right_foot","heel_pad","right_heel_pad",left_definition,"right_leg"]:
		var found := false
		for step in definitions[def_id].manual:
			if step.has("objectives"):found = true
		expect(found,def_id+" has an objective page")
	for def_id in ["pitch_actuator","foot","heel_pad"]:
		for step in definitions[def_id].manual:
			var view := str(step.get("view",""))
			if view != "components" and view != "prepare":continue
			expect(step.has("objectives"),def_id+" page "+str(step.title)+" has objectives")
	var shin_page := page_named(definitions[left_definition].manual,"Deliver the structural shin")
	var shin_text: Array[String] = []
	for objective in shin_page.objectives:shin_text.append(Objectives.text(game,"left_leg",objective))
	expect(shin_text == ["Crane console: Move to Left shin rig","Crane console: Lower crane","Crane: Attach magnetic connectors","Crane console: Raise crane","Crane console: Move to Limb Bay","Crane console: Lower crane to seat LG-100"],"shin delivery text, got "+str(shin_text))
	var right_shin := page_named(definitions.right_leg.manual,"Deliver the structural shin")
	expect(str(right_shin.objectives[0].task) == "right_shin","right shin pickup task, got "+str(right_shin.objectives[0].task))
	var cartridge := page_named(definitions.pitch_actuator.manual,"Drive cartridge")
	var cartridge_text := Objectives.text(game,"pitch",cartridge.objectives[1])
	expect(cartridge_text == "Fasten 4 × W-12 + H-12040 · upper holes","drive cartridge fasteners, got "+cartridge_text)
	var ankle := page_named(definitions[left_definition].manual,"Secure the ankle flange")
	var ankle_text: Array[String] = []
	for index in [3,4,5]:ankle_text.append(Objectives.text(game,"left_leg",ankle.objectives[index]))
	expect(ankle_text == ["Crane: Detach and stow magnetic connectors","Crane console: Raise crane","Crane console: Move to Parking bay"],"ankle release text, got "+str(ankle_text))
	crane.task = "pelvis";crane.uid = "pelvis";crane.config = {"spec":crane.tasks.pelvis};crane.reacquire = ""
	crane.station = "park";crane.raised = true;crane.motion = "";crane.moving = false
	crane.endpoints.a.state = "stowed";crane.endpoints.b.state = "stowed"
	var parked_options: Array = crane.menu_options()
	expect(crane.next_route() == "pelvis" and option_label(parked_options,"pickup") == "Move to Heavy Module Bay" and plain_menu(parked_options),"pelvis pickup label, got "+str(parked_options)+" route "+crane.next_route())
	crane.station = "source";crane.raised = true
	crane.endpoints.a.state = "attached";crane.endpoints.b.state = "attached"
	var source_options: Array = crane.menu_options()
	var has_lower := false
	for option in source_options:
		if str(option.label) == "↓  Lower crane":has_lower = true
	expect(option_label(source_options,"go:receiver") == "Move to Final Assembly Bay" and has_lower and plain_menu(source_options),"source delivery label, got "+str(source_options))
	crane.station = "receiver"
	var receiver_options: Array = crane.menu_options()
	expect(option_label(receiver_options,"go:source") == "Move to Heavy Module Bay" and plain_menu(receiver_options),"receiver put-back label, got "+str(receiver_options))
	var pelvis_page := page_named(definitions.pelvis.manual,"Deliver the prepared hip assembly")
	var supports = preload("res://scripts/module_supports.gd").new();game.add_child(supports);supports.equipment_id = "module_supports";game.equipment.register(supports)
	var bring := page_named(definitions.pelvis.manual,"Bring the chest to the heavy module rig")
	var bring_fit := Objectives.text(game,"pelvis",bring.objectives[0])
	var bring_move := Objectives.text(game,"pelvis",bring.objectives[1])
	expect(bring_fit == "Heavy module rig: Fit chest contact inserts","chest rig objective, got "+bring_fit)
	expect(bring_move == "Crane console: Move to Chest rig","chest pickup objective, got "+bring_move)
	var guided := page_named(definitions.chest.manual,"Deliver and guide the core")
	var forward := ""
	for objective in guided.objectives:
		if str(objective.get("op","")) == "detach" and str(objective.get("point","")) == "core_front":
			forward = Objectives.text(game,"chest",objective)
	expect(forward == "Crane: Detach and stow the forward magnetic connector","core forward detach, got "+forward)
	var guide = preload("res://scripts/core_guide.gd").new();game.add_child(guide);guide.equipment_id = "core_guide";game.equipment.register(guide)
	guide.spec = {"capture":0.85,"travel":2.2}
	var bolts: Array[bool] = [false,false,false,false]
	guide.bolts = bolts
	var bolt_page := {"objectives":[{"op":"operate","machine":"core_guide","command":"secure_bolts"}]}
	var bolt_text := Objectives.text(game,"chest",bolt_page.objectives[0])
	var bolt_state := Objectives.evaluate(game,"chest",bolt_page)
	expect(bolt_text == "Core: Secure captive flange bolts" and bolt_state.counts[0] == "0/4","core bolts, got "+bolt_text+" "+str(bolt_state.counts))
	var closed := page_named(definitions.chest.manual,"Close and latch the backpack")
	expect(closed.objectives.size() == 11 and str(closed.objectives[0].op) == "connect","backpack close starts by refitting the connectors on the lowered crane, got "+str(closed.objectives.size()))
	var struts := page_named(definitions.chest.manual,"Attach the backpack struts")
	expect(str(struts.objectives.back().op) == "detach" and struts.objectives.size() == 4,"struts page leaves the crane lowered at the backpack")
	var pelvis_pin := Objectives.text(game,"pelvis",pelvis_page.objectives[0])
	var pelvis_pickup := Objectives.text(game,"pelvis",pelvis_page.objectives[1])
	var pelvis_receiver := Objectives.text(game,"pelvis",pelvis_page.objectives[6])
	var pelvis_jaws := Objectives.text(game,"pelvis",pelvis_page.objectives[8])
	expect(pelvis_page.objectives.size() == 15 and pelvis_pin == "Waist: Insert both lock pins" and pelvis_pin == "Waist: "+supports.command_label("insert_pins"),"pelvis pin objective, got "+pelvis_pin)
	expect(pelvis_pickup == "Crane console: Move to Heavy Module Bay","pelvis pickup objective, got "+pelvis_pickup)
	expect(pelvis_receiver == "Crane console: Move to Final Assembly Bay","pelvis receiver objective, got "+pelvis_receiver)
	expect(pelvis_jaws == "Gantry: Close the hold-down jaws" and pelvis_jaws == "Gantry: "+supports.command_label("close_jaws"),"pelvis jaw objective, got "+pelvis_jaws)
	var deliver: Dictionary = definitions[left_definition].manual[1]
	expect(str(deliver.title) == "Deliver the foot" and str(deliver.objectives[0].task) == "foot","left foot delivery, got "+str(deliver.title)+" "+str(deliver.objectives[0].get("task","")))
	var right_deliver: Dictionary = definitions.right_leg.manual[1]
	expect(str(right_deliver.objectives[0].task) == "right_foot","right foot pickup task, got "+str(right_deliver.objectives[0].get("task","")))
	var dock := page_named(definitions[left_definition].manual,"Dock the prepared foot")
	var rig = preload("res://scripts/foot_carrier.gd").new();game.add_child(rig);rig.equipment_id = "foot_carrier";game.equipment.register(rig)
	rig.path = 1.0
	var at_raise = Objectives.evaluate(game,"left_leg",dock)
	expect(same_ticks(at_raise,[true,false,false]),"foot rig at 1 ticks the raise, got "+str(at_raise.ticked))
	rig.path = 1.6
	var at_travel = Objectives.evaluate(game,"left_leg",dock)
	expect(same_ticks(at_travel,[true,false,false]),"foot rig at 1.6 stays on the raise, got "+str(at_travel.ticked))
	rig.path = 2.0
	var at_leg = Objectives.evaluate(game,"left_leg",dock)
	expect(same_ticks(at_leg,[true,true,false]),"foot rig at 2 ticks the leg approach, got "+str(at_leg.ticked))
	rig.path = 3.0
	var at_seat = Objectives.evaluate(game,"left_leg",dock)
	expect(not at_seat.ticked[2],"docking stop alone does not mount the foot")
	game.model.assemblies.left_leg.slots.foot = "foot"
	at_seat = Objectives.evaluate(game,"left_leg",dock)
	expect(same_ticks(at_seat,[true,true,true]) and at_seat.machine_complete,"foot rig at 3 completes docking, got "+str(at_seat.ticked)+" complete "+str(at_seat.machine_complete))
	var dock_text: Array[String] = []
	for objective in dock.objectives:dock_text.append(Objectives.text(game,"left_leg",objective))
	expect(dock_text == ["Foot rig: Next — raises the foot","Foot rig: Next — moves it to the leg rig","Foot rig: Next to seat the prepared foot"],"dock text, got "+str(dock_text))
	var pins = preload("res://scripts/captive_controls.gd").new();game.add_child(pins);pins.equipment_id="captive_controls";game.equipment.register(pins)
	pins.specs=content.equipment.captive_controls
	for id in pins.specs:pins.locked[id]=false
	var rail = preload("res://scripts/indexed_leg_rail.gd").new();game.add_child(rail);rail.game=game;rail.equipment_id="leg_rail";game.equipment.register(rail)
	rail.spec=layout.workshop.rail
	rail.lane="left";rail.active_assembly="left_leg";rail.engaged=true;rail.foot_support=0.0;rail.release=0.0;rail.index_x=rail.spec.station_x;rail.travel_z=rail.spec.home_z;rail.tilt_deg=0.0;rail.rise_m=0.0
	crane.task="spar"
	var seat := page_named(definitions.pelvis.manual,"Seat the leg in the hip assembly")
	var seat_text: Array[String] = []
	for objective in seat.objectives:seat_text.append(Objectives.text(game,"pelvis",objective))
	expect(seat_text==["Foot support: look at it, hold E and pull it away from the foot — until it stops","Transfer table lever: pull it to LEFT HIP","Bogie box: hold TO BAY — until the bogie stops at the bay","Lower front: Open — LOWER FRONT panel beside the left lift","Bogie box: hold RISE — until it seats in the hip to seat the structural left leg","Lower front: Close — LOWER FRONT panel beside the left lift"],"seat text names each physical control, got "+str(seat_text))
	var at_home = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(at_home,[false,false,false,false,false,false]),"leg rig at home ticks nothing, got "+str(at_home.ticked))
	rail.foot_support=1.0
	var stowed = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(stowed,[true,false,false,false,false,false]),"foot support away ticks the first control, got "+str(stowed.ticked))
	rail.index_x=rail.spec.lanes.left
	var indexed = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(indexed,[true,true,false,false,false,false]),"hip notch ticks two, got "+str(indexed.ticked))
	rail.travel_z=(rail.spec.home_z+rail.spec.bay_z)/2.0
	var traveling = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(traveling,[true,true,false,false,false,false]),"travel part way keeps the hip notch, got "+str(traveling.ticked))
	rail.travel_z=rail.spec.bay_z
	var at_bay = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(at_bay,[true,true,true,false,false,false]),"bay end stop ticks travel, got "+str(at_bay.ticked))
	front.set_front("lower",0.5,1.0,true)
	var opening = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(opening,[true,true,true,false,false,false]),"moving gantry front does not tick open, got "+str(opening.ticked))
	front.set_front("lower",1.0)
	var opened = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(opened,[true,true,true,true,false,false]),"open gantry front ticks four, got "+str(opened.ticked))
	rail.tilt_deg=50.0
	var turning = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(turning,[true,true,true,true,false,false]),"partial rise keeps front open without seating, got "+str(turning.ticked))
	rail.tilt_deg=90.0;rail.rise_m=rail.spec.dock_rise
	var docked = Objectives.evaluate(game,"pelvis",seat)
	expect(not docked.ticked[4],"dock pose alone does not mount the leg")
	game.model.assemblies.pelvis.slots.left_leg = "left_leg"
	game.model.assemblies.left_leg.parent = "pelvis";game.model.assemblies.left_leg.parent_slot = "left_leg"
	docked = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(docked,[true,true,true,true,true,false]) and not docked.machine_complete,"actual mounting ticks seating but still requires closing the front, got "+str(docked.ticked))
	front.set_front("lower",0.0)
	var closed_front = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(closed_front,[true,true,true,true,true,true]) and closed_front.machine_complete,"closed gantry front completes delivery, got "+str(closed_front.ticked))
	var cylinders: Array = []
	var releases: Array = []
	for step in definitions.pelvis.manual:
		if str(step.title)=="Mount hip cylinder 1":cylinders.append(step)
		if str(step.title)=="Release the leg rig":releases.append(step)
	var cylinder_text := Objectives.text(game,"pelvis",cylinders[0].objectives[2])
	expect(cylinder_text=="Hip cylinder 1: Insert lock pin","cylinder lock text, got "+cylinder_text)
	expect(str(cylinders[1].objectives[2].command)=="lock:right_hip_1","right cylinder lock, got "+str(cylinders[1].objectives[2].command))
	var release_text: Array[String] = []
	for objective in releases[0].objectives:release_text.append(Objectives.text(game,"pelvis",objective))
	expect(release_text==["Leg clamps switch: tap RELEASE — after hip retention and both lock pins","Bogie box: hold LOWER — until the empty holder lies flat","Bogie box: hold TO TABLE — until the bogie stops on the table","Transfer table lever: pull it to RIGHT HIP · BUILD","Leg clamps switch: tap GRAB — to extend the empty holder","Foot rig: Back — repeat until it is back at dispatch","Bogie box: tap NEXT LEG"],"release text names every physical control, got "+str(release_text))
	var has_next_leg := false
	for objective in releases[1].objectives:
		if str(objective.get("command",""))=="next_leg":has_next_leg=true
	expect(not has_next_leg and releases[1].objectives.size()==6,"right release has six objectives and no next-leg objective")
	rail.engaged=false;rail.release=5.0;rail.rise_m=0.0
	var let_go = Objectives.evaluate(game,"pelvis",releases[0])
	expect(same_ticks(let_go,[true,false,false,false,false,false,false]),"release arrival ticks only the let-go, got "+str(let_go.ticked))
	rail.tilt_deg=30.0
	var lying = Objectives.evaluate(game,"pelvis",releases[0])
	expect(same_ticks(lying,[true,false,false,false,false,false,false]),"part tilt keeps the let-go, got "+str(lying.ticked))
	rail.tilt_deg=0.0;rail.travel_z=(rail.spec.home_z+rail.spec.bay_z)/2.0
	var returning = Objectives.evaluate(game,"pelvis",releases[0])
	expect(same_ticks(returning,[true,true,false,false,false,false,false]),"flat empty holder ticks LOWER while travel is part way, got "+str(returning.ticked))
	rail.travel_z=rail.spec.home_z
	var table = Objectives.evaluate(game,"pelvis",releases[0])
	expect(same_ticks(table,[true,true,true,false,false,false,false]),"table arrival ticks travel, got "+str(table.ticked))
	rail.index_x=rail.spec.station_x
	var station = Objectives.evaluate(game,"pelvis",releases[0])
	expect(same_ticks(station,[true,true,true,true,false,false,false]),"build notch ticks table return, got "+str(station.ticked))
	rail.release=0.0
	var rig_home = Objectives.evaluate(game,"pelvis",releases[0])
	expect(same_ticks(rig_home,[true,true,true,true,true,false,false]),"extended empty holder ticks the return, got "+str(rig_home.ticked))
	rig.path=0.0
	var foot_home = Objectives.evaluate(game,"pelvis",releases[0])
	expect(same_ticks(foot_home,[true,true,true,true,true,true,false]),"foot rig dispatch ticks its return, got "+str(foot_home.ticked))
	rail.active_assembly="right_leg";rail.receiver_slot="right_leg";rail.engaged=true;rail.lane="right";rail.foot_support=0.0
	var selected = Objectives.evaluate(game,"pelvis",releases[0])
	expect(same_ticks(selected,[true,true,true,true,true,true,true]) and selected.machine_complete,"NEXT LEG selects the right leg, got "+str(selected.ticked)+" complete "+str(selected.machine_complete))
	var shoulder = preload("res://scripts/shoulder_support.gd").new();game.add_child(shoulder);shoulder.equipment_id="left_shoulder";game.equipment.register(shoulder)
	var pauldron = preload("res://scripts/staged_receiver.gd").new();game.add_child(pauldron);pauldron.equipment_id="left_pauldron_receiver"
	pauldron.spec={"title":"Prepared left pauldron carrier","operations":[{"id":"joint_restraints","label":"elbow / wrist restraints"},{"id":"digit_cradle","label":"digit cradle"}]}
	game.equipment.register(pauldron)
	var arm_rig := page_named(definitions.chest.manual,"Bring the arm rig to the Limb Bay")
	var arm_park := Objectives.text(game,"chest",arm_rig.objectives[0])
	expect(arm_park=="Transfer table lever: pull it to PARK","left arm rig starts by parking the leg rig, got "+arm_park)
	var brakes := page_named(definitions.chest.manual,"Left shoulder: connect services")
	var brake_line := Objectives.text(game,"chest",brakes.objectives[0])
	expect(brake_line=="Crane console: Check left shoulder brakes","shoulder brake check, got "+brake_line)
	var rear := page_named(definitions.chest.manual,"Left pauldron: rear closure")
	var release_line := ""
	for objective in rear.objectives:
		if str(objective.get("command",""))=="release:joint_restraints":release_line=Objectives.text(game,"chest",objective)
	expect(release_line=="Left pauldron: Release elbow / wrist restraints","pauldron release, got "+release_line)
	var head_rig := page_named(definitions.chest.manual,"Bring the head baseplate to the heavy module rig")
	var insert_line := Objectives.text(game,"chest",head_rig.objectives[0])
	expect(insert_line=="Heavy module rig: Fit head baseplate contact inserts","head inserts, got "+insert_line)
	var crown := page_named(definitions.chest.manual,"Decorative head crown: retain")
	var crown_last := Objectives.text(game,"chest",crown.objectives.back())
	expect(crown_last=="Upper leaves: Close — UPPER LEAVES panel beside the left lift","crown closes the leaves after parking, got "+crown_last)
	var prose: Array[String] = []
	var chapters = JSON.parse_string(FileAccess.get_file_as_string("res://assets/manual-chapters.json"))
	for chapter in chapters.chapters:
		for step in chapter.steps:
			var owner := str(step[0])
			var index := int(step[1])
			var recipe: Dictionary = definitions[str(game.model.assemblies[owner].definition)]
			var step_page: Dictionary = recipe.manual[index]
			var view := str(step_page.get("view",""))
			if step_page.has("body") and view != "overview" and view != "prepared" and view != "summary":
				prose.append(str(step_page.get("title", owner+":"+str(index))))
	expect(prose.is_empty(),"action pages still have body: "+joined(prose))
	var progress = preload("res://scripts/manual_progress.gd").new(game)
	var page_evidence: Array = []
	for owner in ["left_leg","right_leg","pelvis","chest","arm_cassette"]:
		var manual: Array=definitions[game.model.assemblies[owner].definition].manual
		for index in manual.size():
			var step: Dictionary=manual[index]
			if step.title not in ["Structural leg ready","Supported construction recovery","Seat the leg in the hip assembly","Release the leg rig","Reacquire support and recover","Bring the arm rig to the Limb Bay","Arm rig"]:continue
			var right: bool=owner=="right_leg" or (owner=="pelvis" and index>=13)
			rail.active_assembly="right_leg" if right else "left_leg"
			var procedure: Dictionary=progress.procedure(owner,index)
			var text_lines: Array=[]
			var displayed: Array=[]
			for objective in step.get("objectives",[]):text_lines.append(Objectives.text(game,owner,objective))
			for objective_index in Objectives.display_indices(step,procedure):displayed.append(text_lines[objective_index])
			if step.has("procedure"):
				expect(procedure.get("repeat",false)==right,"procedure keeps first-use and mirrored roles: "+owner+":"+str(index))
				if right:expect(displayed.is_empty() and not step.has("note"),"right procedure shows the goal and link without repeated controls: "+str(step.title))
				else:expect(displayed==text_lines,"first-use procedure shows every control: "+str(step.title))
			if step.title=="Seat the leg in the hip assembly":
				expect(step.slots==["right_leg" if right else "left_leg"],"delivery supplies only the prepared leg")
			else:expect(step.get("slots",[]).is_empty(),"status, recovery and rig-only page has no new components: "+str(step.title))
			page_evidence.append({"owner":owner,"page_index":index,"title":step.title,"goal":step.get("goal",""),"body":step.get("body",""),"note":Objectives.note(step,int(step.get("note",{}).get("at",-1))),"slots":step.get("slots",[]),"objectives":step.get("objectives",[]),"rendered_objective_text":text_lines,"displayed_objective_text":displayed,"procedure":procedure.get("label","") if right else ""})
	write_evidence("res://verification/r3-manual-pages.json",{"rendered_visual_review":false,"text_source":"Production ManualObjectives and ManualProgress functions used by the HUD","pages":page_evidence})
	preload("res://tests/kit/manual_gantry_audit.gd").run(self)
	var passed = checks.all(func(check):return check.passed)
	print("MANUAL_OBJECTIVES ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
