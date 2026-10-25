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
	var game = preload("res://tests/kit/model_workshop.gd").new();root.add_child(game)
	expect(game.setup().is_empty(),"authored stock configures")
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
	expect(same_ticks(seated,[true,true,true,true,true,true]) and seated.machine_complete,"lowered at delivery completes the machine sequence, got "+str(seated.ticked)+" complete "+str(seated.machine_complete))
	crane.raised = true
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
	for index in [1,2,3]:ankle_text.append(Objectives.text(game,"left_leg",ankle.objectives[index]))
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
	var pelvis_page := page_named(definitions.pelvis.manual,"Deliver the prepared pelvis and waist")
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
	expect(closed.objectives.size() == 9 and str(closed.objectives[0].op) == "connect","backpack close starts by refitting the connectors on the lowered crane, got "+str(closed.objectives.size()))
	var struts := page_named(definitions.chest.manual,"Attach the backpack struts")
	expect(str(struts.objectives.back().op) == "detach" and struts.objectives.size() == 4,"struts page leaves the crane lowered at the backpack")
	var pelvis_pin := Objectives.text(game,"pelvis",pelvis_page.objectives[0])
	var pelvis_pickup := Objectives.text(game,"pelvis",pelvis_page.objectives[1])
	var pelvis_receiver := Objectives.text(game,"pelvis",pelvis_page.objectives[5])
	var pelvis_jaws := Objectives.text(game,"pelvis",pelvis_page.objectives[7])
	expect(pelvis_page.objectives.size() == 11 and pelvis_pin == "Waist: Insert both lock pins" and pelvis_pin == "Waist: "+supports.command_label("insert_pins"),"pelvis pin objective, got "+pelvis_pin)
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
	expect(same_ticks(at_seat,[true,true,true]) and at_seat.machine_complete,"foot rig at 3 completes docking, got "+str(at_seat.ticked)+" complete "+str(at_seat.machine_complete))
	var dock_text: Array[String] = []
	for objective in dock.objectives:dock_text.append(Objectives.text(game,"left_leg",objective))
	expect(dock_text == ["Foot rig: Next — raises the foot","Foot rig: Next — moves it to the leg rig","Foot rig: Next to seat the prepared foot"],"dock text, got "+str(dock_text))
	var pins = preload("res://scripts/captive_controls.gd").new();game.add_child(pins);pins.equipment_id="captive_controls";game.equipment.register(pins)
	pins.specs=content.equipment.captive_controls
	for id in pins.specs:pins.locked[id]=false
	var rail = preload("res://scripts/indexed_leg_rail.gd").new();game.add_child(rail);rail.equipment_id="leg_rail";game.equipment.register(rail)
	rail.spec={"station_x":14.0,"lanes":{"left":10.0,"right":18.0}}
	rail.lane="left";rail.active_assembly="left_leg";rail.engaged=true;rail.path=0.0;rail.bolster=0.0;rail.release=0.0;rail.index_x=14.0;rail.moving=false;rail.mode=""
	var seat := page_named(definitions.pelvis.manual,"Seat the leg in the pelvis")
	var seat_text: Array[String] = []
	for objective in seat.objectives:seat_text.append(Objectives.text(game,"pelvis",objective))
	var seat_prefix := true
	for index in range(seat_text.size()-1):
		if not seat_text[index].begins_with("Leg rig: Next — "):seat_prefix=false
	expect(seat_prefix and seat_text[seat_text.size()-1]=="Leg rig: Next to seat the structural left leg","seat text, got "+str(seat_text))
	var at_home = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(at_home,[false,false,false,false,false]),"leg rig at home ticks nothing, got "+str(at_home.ticked))
	rail.bolster=1.0
	var stowed = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(stowed,[true,false,false,false,false]),"stowed bolster ticks the first phase, got "+str(stowed.ticked))
	rail.index_x=10.0
	var indexed = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(indexed,[true,true,false,false,false]),"indexed lane ticks two, got "+str(indexed.ticked))
	rail.path=0.4
	var traveling = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(traveling,[true,true,false,false,false]),"travel in motion keeps the lane, got "+str(traveling.ticked))
	rail.path=1.0
	var at_bay = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(at_bay,[true,true,true,false,false]),"bay arrival ticks travel, got "+str(at_bay.ticked))
	rail.path=1.6
	var turning = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(turning,[true,true,true,false,false]),"turning keeps travel, got "+str(turning.ticked))
	rail.path=2.0
	var upright = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(upright,[true,true,true,true,false]),"upright ticks four, got "+str(upright.ticked))
	rail.path=3.0
	var docked = Objectives.evaluate(game,"pelvis",seat)
	expect(same_ticks(docked,[true,true,true,true,true]) and docked.machine_complete,"dock completes seating, got "+str(docked.ticked)+" complete "+str(docked.machine_complete))
	var cylinders: Array = []
	var releases: Array = []
	for step in definitions.pelvis.manual:
		if str(step.title)=="Mount hip cylinder 1":cylinders.append(step)
		if str(step.title)=="Release the leg rig":releases.append(step)
	var cylinder_text := Objectives.text(game,"pelvis",cylinders[0].objectives[2])
	expect(cylinder_text=="Hip cylinder 1: Insert lock pin","cylinder lock text, got "+cylinder_text)
	expect(str(cylinders[1].objectives[2].command)=="lock:right_hip_1","right cylinder lock, got "+str(cylinders[1].objectives[2].command))
	var has_build := false
	for objective in releases[1].objectives:
		if str(objective.get("command",""))=="build":has_build=true
	expect(not has_build,"right release has no build objective")
	rail.engaged=false;rail.release=5.0;rail.path=2.0
	var let_go = Objectives.evaluate(game,"pelvis",releases[0])
	expect(same_ticks(let_go,[true,false,false,false]),"release arrival ticks only the let-go, got "+str(let_go.ticked))
	rail.path=1.4
	var returning = Objectives.evaluate(game,"pelvis",releases[0])
	expect(same_ticks(returning,[true,false,false,false]),"return in motion keeps the let-go, got "+str(returning.ticked))
	rail.path=0.0;rail.index_x=14.0;rail.release=0.0
	var rig_home = Objectives.evaluate(game,"pelvis",releases[0])
	expect(same_ticks(rig_home,[true,true,false,false]),"empty rig home ticks the return, got "+str(rig_home.ticked))
	rig.path=0.0
	var foot_home = Objectives.evaluate(game,"pelvis",releases[0])
	expect(same_ticks(foot_home,[true,true,true,false]),"foot rig dispatch ticks its return, got "+str(foot_home.ticked))
	rail.active_assembly="right_leg";rail.engaged=true;rail.lane="right"
	var selected = Objectives.evaluate(game,"pelvis",releases[0])
	expect(same_ticks(selected,[true,true,true,true]) and selected.machine_complete,"build selects the right leg, got "+str(selected.ticked)+" complete "+str(selected.machine_complete))
	var passed = checks.all(func(check):return check.passed)
	print("MANUAL_OBJECTIVES ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
