extends "res://tests/kit/harness.gd"
## Isolated production fronts and crane decisions; no stage replay or rendering.
const Layout=preload("res://scripts/leg_bay_layout.gd")
const Access=preload("res://scripts/workshop_access.gd")
class World extends "res://tests/kit/model_workshop.gd":
	var player: CharacterBody3D
	var primitives=preload("res://scripts/primitives.gd").new()
	func material(color: Color,metal: float=0.0) -> Material:return primitives.material(color,metal)
	func box(parent: Node3D,at: Vector3,size: Vector3,mat: Material,solid: bool=false) -> MeshInstance3D:return primitives.box(parent,at,size,mat,solid)
class Crane extends "res://scripts/service_crane.gd":
	func _refresh() -> void:pass
	func _route_error(_from: float,_to: float) -> String:return ""
class Console extends CanvasLayer:
	func physics() -> void:pass
class Occupant extends WorkshopEquipment:
	var front="lower"
	func gantry_occupant(which: String) -> String:return "test load" if which==front else ""
var game: World
var access: Node
var crane: Crane
func _initialize() -> void:run.call_deferred()
func select(task: String,loaded: bool=true) -> void:
	var spec: Dictionary=crane.tasks[task]
	var route: Array[Transform3D]=[]
	for index in spec.route_positions.size():
		var rotation=spec.route_rotations[index] if spec.has("route_rotations") else spec.source_pose.rotation_degrees if index<2 else spec.receiver_pose.rotation_degrees
		route.append(Transform3D(Basis.from_euler(AssemblyRuntime.vec(rotation)*PI/180),AssemblyRuntime.vec(spec.route_positions[index])))
	crane.task=task;crane._configure_task({"spec":spec,"source_pose":route[0],"receiver_pose":route.back(),"route":route})
	for index in crane.END_IDS.size():crane.endpoints[crane.END_IDS[index]]={"state":"attached" if loaded else "stowed","point":crane.POINT_IDS[index] if loaded else ""}
	crane.station="source";crane.raised=true;crane.motion="go:receiver";crane.moving=true;crane.progress=0;crane.travel_from=null
func operate(action: String) -> void:
	expect(access.request(action).is_empty(),action+" accepted")
	access.physics(6)
func run() -> void:
	game=World.new();root.add_child(game);expect(game.setup().is_empty(),"real content configures")
	var block=preload("res://scripts/workshop_blockout.gd").new();game.add_child(block)
	block.spec={"access":Layout.layout().workshop.access,"elevators":Layout.layout().workshop.elevators,"groups":{}}
	access=Access.new();game.add_child(access);access.setup(game,block);game.equipment.register(access)
	expect(access.controls().size()==4 and access.get_child_count()==2,"one labelled row on each of two level banks")
	for bank in access.get_children():
		var labels=[]
		for node in bank.get_children():
			if node is Label3D:labels.append(node.text)
		var front="lower" if is_equal_approx(bank.position.y,8.4) else "upper"
		expect(labels==[front.to_upper()+" GANTRY"],"each bank has only its own level’s row")
		for action in Access.MANUAL_COMMANDS:
			expect(access.controls().filter(func(entry):return bank.is_ancestor_of(entry.node) and entry.action==action).size()==(1 if action.begins_with(front) else 0),"bank exposes only its level’s action: "+action)
	for front in ["upper","lower"]:
		expect(access.front_closed(front) and not access.front_open(front),front+" starts fully closed")
		expect(access.request(front+"_open").is_empty(),front+" opens by tap")
		access.physics(2)
		expect(not access.front_open(front) and not access.front_closed(front),front+" partial travel is neither locked state")
		expect(access.request(front+"_close").is_empty(),front+" reverses without Stop")
		access.physics(6)
		expect(access.front_closed(front),front+" reverses to fully closed")
		operate(front+"_open")
		expect(access.front_open(front),front+" reaches fully open")
		access.request(front+"_close");access.physics(2);access.request(front+"_open");access.physics(6)
		expect(access.front_open(front),front+" can reverse a closing trip")
		operate(front+"_close")
	operate("upper_open");access.request("lower_open");access.physics(1)
	expect(access.front_open("upper") and not access.front_open("lower"),"a moving lower front does not invalidate the locked upper front")
	access.request("upper_close");access.physics(6)
	expect(access.front_closed("upper") and access.front_open("lower"),"fronts keep independent goals")
	var occupant=Occupant.new();game.add_child(occupant);game.equipment.register(occupant)
	for front in ["lower","upper"]:
		occupant.front=front;operate(front+"_open")
		var before=access.capture()
		var expected="Move the test load out of the gantry before closing the "+("lower gantry" if front=="lower" else "upper gantry")+"."
		expect(access.action_error(front+"_close")==expected and access.request(front+"_close")==expected and before==access.capture(),"named occupant refuses Close atomically for "+front)
		var other="upper" if front=="lower" else "lower"
		operate(other+"_close")
		expect(access.front_closed(other),"occupant does not reserve the other front")
	occupant.free();operate("upper_close");operate("lower_close")
	expect(access.manual_commands()==["upper_open","upper_close","lower_open","lower_close"],"manual commands follow panel order")
	for action in access.manual_commands():
		var front: String=action.get_slice("_",0);var open=action.ends_with("_open")
		var objective={"command":action}
		expect(access.manual_effect(objective)=={front+"_open":open,front+"_closed":not open},action+" declares its end state and clears the opposite one")
		# Isolated manual tests stand in a stub for the fronts; keep its manual API identical.
		var stub=preload("res://tests/kit/manual_fronts.gd").new()
		expect(stub.manual_effect(objective)==access.manual_effect(objective) and stub.manual_subject(objective)==access.manual_subject(objective) and stub.manual_hint(objective)==access.manual_hint(objective) and stub.command_label(action)==access.command_label(action),action+" manual stub matches the real fronts")
		stub.free()
		expect(access.manual_control_actions(objective)==[action] and access.manual_control_entries(objective).size()==1,action+" cues its one physical bank")
		expect(access.manual_subject(objective)==("Upper gantry" if action.begins_with("upper") else "Lower gantry") and access.manual_hint(objective)==access.manual_subject(objective).to_upper()+" panel at "+("20.6" if action.begins_with("upper") else "8.4")+" m beside the left lift",action+" names the panel")
		expect(access.command_label(action)==("Open" if action.ends_with("open") else "Close"),action+" uses the panel's verb")
	# Closing an opened front keeps its OPEN evidence until CLOSE arrives.
	operate("lower_open");access.request("lower_close");access.physics(.05)
	var mid: Dictionary=access.manual_state()
	expect(access.moving and mid.lower_open and not mid.lower_closed,"a closing front still reads opened, not yet closed")
	var stub_front=preload("res://tests/kit/manual_fronts.gd").new();stub_front.set_front("lower",.5,0.0,true)
	expect(stub_front.manual_state().lower_open and not stub_front.manual_state().lower_closed,"the manual stub reads a closing front the same way")
	stub_front.free();operate("lower_close")
	expect(not access.manual_state().lower_open and access.manual_state().lower_closed,"a closed front reads closed only")
	for obsolete in ["stop","advance","return"]:expect(not access.request(obsolete).is_empty(),"removed action "+obsolete+" is rejected")
	operate("lower_open")
	var saved: Dictionary=JSON.parse_string(JSON.stringify(access.capture()))
	expect(saved.keys().size()==3 and saved.version==2 and access.validate(saved).is_empty(),"version 2 has only version, channels and moving")
	operate("lower_close");access.apply(saved)
	expect(access.manual_state()=={"upper_open":false,"upper_closed":true,"lower_open":true,"lower_closed":false},"save restores independent front state")
	var old=saved.duplicate(true);old.version=1
	expect(not access.validate(old).is_empty(),"version 1 is rejected without migration")
	old.mode="work";expect(not access.validate(old).is_empty(),"old mode snapshot shape is rejected")
	operate("lower_close")
	crane=Crane.new();game.add_child(crane);crane.game=game;crane.tasks=Layout.layout().crane.tasks;crane.equipment_id="service_crane";game.equipment.register(crane)
	crane.console=Console.new();crane.add_child(crane.console)
	select("pelvis");crane.progress=.83
	var before=access.capture();crane.physics(.2)
	expect(crane.progress==.83 and crane.moving and crane.blocked_reason=="Open the upper gantry (UPPER GANTRY panel at 20.6 m beside the left lift)." and before==access.capture(),"loaded crossing waits with exact instruction without operating access")
	operate("upper_open");crane.physics(.2)
	expect(crane.progress>.83 and crane.blocked_reason.is_empty(),"player Open resumes the pending loaded crossing")
	select("pelvis",false);crane.station="receiver";crane.motion="go:park";crane.progress=.12
	operate("upper_close");crane.physics(.9)
	expect(crane.progress==.12 and crane.moving and crane.blocked_reason==Crane.UPPER_WAIT,"empty return crossing waits too")
	operate("upper_open");crane.physics(.9)
	expect(crane.progress>.12 and crane.blocked_reason.is_empty(),"empty return resumes after player Open")
	var shoulder=preload("res://scripts/shoulder_support.gd").new();game.add_child(shoulder);shoulder.game=game;shoulder.equipment_id="left_shoulder"
	shoulder.mass=preload("res://scripts/arm_delivery_geometry.gd").mass_properties(game.leg_content,game.runtime.definition("left_arm"));game.equipment.register(shoulder)
	select("left_arm");before=access.capture();crane.physics(.05)
	expect(crane.progress==0 and crane.moving and crane.blocked_reason=="Open the lower gantry (LOWER GANTRY panel at 8.4 m beside the left lift)." and before==access.capture(),"arm waits for lower front without moving it")
	operate("lower_open")
	expect(crane._access_error(.01).is_empty(),"arm wait clears after lower Open")
	var passed=checks.all(func(c):return c.passed)
	print("GANTRY_FRONTS ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
