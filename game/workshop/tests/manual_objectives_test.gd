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
	expect(crane.command_label("pickup") == "Move to pickup","pickup label")
	expect(crane.command_label("go:receiver") == "Move to delivery","delivery label")
	expect(crane.command_label("connect") == "Attach magnetic connectors","connect label")
	var page = {"goal":"g","slots":["shin"],"objectives":[
		{"op":"operate","machine":"service_crane","command":"pickup","task":"shin"},
		{"op":"operate","machine":"service_crane","command":"down"},
		{"op":"connect","machine":"service_crane"},
		{"op":"operate","machine":"service_crane","command":"up"},
		{"op":"operate","machine":"service_crane","command":"go:receiver"},
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
	expect(texts == ["Move to pickup","Lower crane","Attach magnetic connectors","Raise crane","Move to delivery","Lower crane to seat LG-100"],"shin objective text, got "+str(texts))
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
	var commands = {"service_crane":preload("res://scripts/service_crane.gd").MANUAL_COMMANDS,"foot_carrier":preload("res://scripts/foot_carrier.gd").MANUAL_COMMANDS,"module_supports":preload("res://scripts/module_supports.gd").MANUAL_COMMANDS}
	var good = {"title":"Bolt the flange","goal":"Fasten the flange","view":"components","slots":["a","b"],"objectives":[{"op":"fit","slots":["a"]},{"op":"fit","slots":["b"]}]}
	var good_errors = Objectives.errors(manual_of(good),commands)
	expect(good_errors.is_empty(),"valid page has no objective errors: "+joined(good_errors))
	var duplicate = {"title":"Twice","goal":"g","view":"components","slots":["a"],"objectives":[{"op":"fit","slots":["a","a"]}]}
	expect(not Objectives.errors(manual_of(duplicate),commands).is_empty(),"duplicate slot is rejected")
	var mismatch = {"title":"Miss","goal":"g","view":"components","slots":["a","b"],"objectives":[{"op":"fit","slots":["a"]}]}
	expect(not Objectives.errors(manual_of(mismatch),commands).is_empty(),"slot mismatch is rejected")
	var unknown = {"title":"Move","goal":"g","view":"components","slots":[],"objectives":[{"op":"operate","machine":"service_crane","command":"fly"}]}
	expect(not Objectives.errors(manual_of(unknown),commands).is_empty(),"unknown command is rejected")
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
	expect(shin_text == ["Move to pickup","Lower crane","Attach magnetic connectors","Raise crane","Move to delivery","Lower crane to seat LG-100"],"shin delivery text, got "+str(shin_text))
	var right_shin := page_named(definitions.right_leg.manual,"Deliver the structural shin")
	expect(str(right_shin.objectives[0].task) == "right_shin","right shin pickup task, got "+str(right_shin.objectives[0].task))
	var cartridge := page_named(definitions.pitch_actuator.manual,"Drive cartridge")
	var cartridge_text := Objectives.text(game,"pitch",cartridge.objectives[1])
	expect(cartridge_text == "Fasten 4 × W-12 + H-12040 · upper holes","drive cartridge fasteners, got "+cartridge_text)
	var ankle := page_named(definitions[left_definition].manual,"Secure the ankle flange")
	var ankle_text: Array[String] = []
	for index in [1,2,3]:ankle_text.append(Objectives.text(game,"left_leg",ankle.objectives[index]))
	var park_text := "Move to Parking bay"
	if crane.command_label("go:park") != "Move to Parking bay":park_text = crane.command_label("go:park")
	expect(ankle_text == ["Detach and stow magnetic connectors","Raise crane",park_text],"ankle release text, got "+str(ankle_text))
	crane.station = "park";crane.raised = true;crane.motion = "";crane.moving = false
	crane.endpoints.a.state = "stowed";crane.endpoints.b.state = "stowed"
	var parked_labels: Array = crane.menu_options().map(func(option):return option.label)
	expect(not crane.next_route().is_empty() and not parked_labels.is_empty() and str(parked_labels[0]).begins_with("Move to pickup · "),"parked menu starts with pickup, got "+str(parked_labels)+" route "+crane.next_route())
	crane.station = "source";crane.raised = true
	crane.endpoints.a.state = "attached";crane.endpoints.b.state = "attached"
	var source_labels: Array = crane.menu_options().map(func(option):return option.label)
	var has_delivery := false
	var has_lower := false
	for label in source_labels:
		if str(label).begins_with("Move to delivery · "):has_delivery = true
		if str(label) == "↓  Lower crane":has_lower = true
	expect(has_delivery and has_lower,"source menu keeps delivery and lower, got "+str(source_labels))
	var pelvis_page := page_named(definitions.pelvis.manual,"Deliver the prepared pelvis and waist")
	var supports = preload("res://scripts/module_supports.gd").new();game.add_child(supports);supports.equipment_id = "module_supports";game.equipment.register(supports)
	var pelvis_first := Objectives.text(game,"pelvis",pelvis_page.objectives[0])
	expect(pelvis_page.objectives.size() == 11 and pelvis_first == "Insert both waist neutral pins" and pelvis_first == supports.command_label("insert_pins"),"pelvis delivery checklist, got "+str(pelvis_page.objectives.size())+" "+pelvis_first)
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
	var seat_text := Objectives.text(game,"left_leg",dock.objectives[2])
	expect(seat_text == "Advance the foot rig to seat the prepared foot","dock seat text, got "+seat_text)
	var passed = checks.all(func(check):return check.passed)
	print("MANUAL_OBJECTIVES ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
