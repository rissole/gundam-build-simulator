extends "res://tests/kit/harness.gd"
## Real resolver mappings, retained contours and actual physics sightlines in a
## tiny fixture. No workshop construction, walked acceptance or rendered review.
const Guidance = preload("res://scripts/manual_control_guidance.gd")
const Objectives = preload("res://scripts/manual_objectives.gd")
class Progress extends RefCounted:
	signal updated
	var _queued=false
	var current=0
	var locked=false
	var definition={"objectives":[{"op":"operate","machine":"fixture","command":"engage:left_leg:ankle:outboard"}]}
	func tracked() -> Dictionary:return {"owner":"pelvis","page":0,"definition":definition}
	func status(_owner: String,_page: int) -> String:return "locked" if locked else "ready"
	func evaluation(_owner: String,_page: int) -> Dictionary:return {"current":current}
class Components extends RefCounted:
	var held_body: Node3D
class Fixture extends "res://scripts/equipment.gd":
	var entries: Array[Dictionary]=[]
	var unavailable: Array=[]
	func controls() -> Array[Dictionary]:return entries
	func action_error(action: String) -> String:return "Unavailable" if action in unavailable else ""
class Supports extends "res://scripts/module_supports.gd":
	var entries: Array[Dictionary]=[]
	func controls() -> Array[Dictionary]:return entries
	func action_error(_action: String) -> String:return ""
class Core extends "res://scripts/core_guide.gd":
	var entries: Array[Dictionary]=[]
	func controls() -> Array[Dictionary]:return entries
	func action_error(_action: String) -> String:return ""
class Backpack extends "res://scripts/backpack_hinge.gd":
	var entries: Array[Dictionary]=[]
	func controls() -> Array[Dictionary]:return entries
	func action_error(_action: String) -> String:return ""
class Receiver extends "res://scripts/staged_receiver.gd":
	var entries: Array[Dictionary]=[]
	func controls() -> Array[Dictionary]:return entries
	func action_error(_action: String) -> String:return ""
class Crane extends "res://scripts/service_crane.gd":
	var entries: Array[Dictionary]=[]
	var options: Array[Dictionary]=[]
	var guided_node: Node
	var unavailable: Array=[]
	func controls() -> Array[Dictionary]:return entries
	func menu_options() -> Array[Dictionary]:return options
	func _guide() -> Node:return guided_node
	func action_error(action: String) -> String:return "Unavailable" if action in unavailable else ""
class HeldInput extends RefCounted:
	var held: Dictionary={}
	func held_control() -> Dictionary:return held
class World extends Node3D:
	const WORLD_MASK=15
	var camera: Camera3D
	var player: CharacterBody3D
	var bodies={}
	var model=AssemblyModel.new()
	var components=Components.new()
	var equipment=EquipmentRegistry.new()
	var manual_progress=Progress.new()
	var targeting: RefCounted
	var interaction_outline: Node3D
	var paused=false
	var desktop_input=HeldInput.new()
var game: World
func _initialize() -> void:run.call_deferred()

func mesh() -> MeshInstance3D:
	var node=MeshInstance3D.new();node.mesh=BoxMesh.new();node.mesh.size=Vector3(.10,.10,.10)
	game.add_child(node);node.position=Vector3(0,0,-2)
	return node
func entry(machine: Node, action: String, node: Node3D) -> Dictionary:
	return machine.control_entry(node,action,action,.1,{"point":node.global_position})
func selected(machine: Node, command: String, op: String="operate") -> Array:
	return machine.manual_control_entries({"op":op,"command":command}).map(func(item):return item.action)
func mappings(node: Node3D) -> void:
	var supports=Supports.new();game.add_child(supports)
	for action in ["jaw:0","jaw:1","jaw:2","jaw:3","lock:yaw","lock:lean","advance","template:core"]:supports.entries.append(entry(supports,action,node))
	supports.jaws.assign([0.0,1.0,1.0,0.0]);supports.jaw_goals.assign([0.0,1.0,0.0,0.0]);supports.locks={"yaw":true,"lean":false}
	expect(selected(supports,"close_jaws")==["jaw:1","jaw:2"],"Grouped gantry jaws include stopped pending handles and exclude closed jaws")
	expect(selected(supports,"insert_pins")==["lock:lean"],"Grouped waist pins exclude the inserted pin")
	supports.entries.back()["cycle_templates"]=true
	expect(selected(supports,"template:head").is_empty() and selected(supports,"advance").is_empty(),"Heavy module rig panel buttons have no cue")
	var core=Core.new();game.add_child(core)
	for action in ["bolt:0","bolt:1","bolt:2","bolt:3","advance","connection"]:core.entries.append(entry(core,action,node))
	core.bolts.assign([true,false,true,false])
	expect(selected(core,"secure_bolts")==["bolt:1","bolt:3"],"Core objective resolves every remaining captive bolt")
	expect(selected(core,"next:capture").is_empty() and selected(core,"next:seat").is_empty(),"Core guide panel buttons have no cue")
	expect(selected(core,"connection")==["connection"],"Core rear interlock resolves its local control")
	var backpack=Backpack.new();game.add_child(backpack);backpack.game=game
	for action in ["strut:0","strut:1","lock:0","lock:1","latch:0","latch:1","cover:0","cover:1"]:backpack.entries.append(entry(backpack,action,node))
	backpack.struts.assign([1.0,0.0]);backpack.strut_goals.assign([1.0,0.0]);backpack.locks.assign([true,false]);backpack.latches.assign([false,true]);backpack.covers.assign([true,false])
	expect(selected(backpack,"extend_struts")==["strut:1"],"Backpack resolves its remaining extension handle")
	expect(selected(backpack,"lock_struts")==["lock:1"] and selected(backpack,"release_struts")==["lock:0"],"Positive and reverse grouped lock objectives cue opposite remaining handles")
	expect(selected(backpack,"engage_latches")==["latch:0"] and selected(backpack,"close_covers")==["cover:1"],"Backpack latch and service cover cues exclude completed controls")
	var receiver=Receiver.new();game.add_child(receiver);receiver.game=game
	game.model.assemblies={"fixture":{"slots":{"bolt_a":"","bolt_b":"installed"}}}
	receiver.spec={"owner":"fixture","captive_slots":["bolt_a","bolt_b"]}
	for action in ["fasten:bolt_a","fasten:bolt_b","release:shipping"]:receiver.entries.append(entry(receiver,action,node))
	expect(selected(receiver,"fasten")==["fasten:bolt_a"],"Shared guided receiver cues only unfastened captive bolts")
	expect(selected(receiver,"release:shipping")==["release:shipping"],"Shared guided receiver resolves its local shipping-restraint handle")
	var foot=preload("res://scripts/foot_carrier.gd").new();game.add_child(foot)
	var rail=preload("res://scripts/indexed_leg_rail.gd").new();game.add_child(rail)
	expect(foot.manual_control_actions({"command":"advance:2"}).is_empty() and foot.manual_control_actions({"command":"return:home"}).is_empty(),"Foot rig panel buttons have no cue")
	# On-rig controls glow; the bogie box buttons are rig panel buttons and do not.
	var rail_controls={"support:away":"support","table:hip":"lever","travel:bay":"","rise":"","clamps:release":"clamps","lower":"","travel:home":"","table:build":"lever","clamps:grab":"clamps","next_leg":"","table:park":"lever"}
	expect(rail_controls.size()==rail.MANUAL_COMMANDS.size(),"all leg rig manual commands have a cue expectation")
	for command in rail_controls:
		var want: Array=[] if rail_controls[command].is_empty() else [rail_controls[command]]
		expect(rail.manual_control_actions({"command":command})==want,"Leg rig "+command+(" cues its physical "+rail_controls[command]+" control" if not want.is_empty() else " (bogie box button) has no cue"))
	var front=preload("res://tests/kit/manual_fronts.gd").new();game.add_child(front)
	for command in front.MANUAL_COMMANDS:front.entries.append(entry(front,command,node))
	for command in front.MANUAL_COMMANDS:
		expect(selected(front,command)==[command],"Front contract "+command+" cues its matching panel key (R1 stub)")
	var captive=preload("res://scripts/captive_controls.gd").new();game.add_child(captive)
	captive.specs={"left_hip_1":{},"right_hip_1":{}};captive.locked={"left_hip_1":false,"right_hip_1":true}
	expect(captive.manual_control_actions({"command":"lock:left_hip_1"})==["left_hip_1"] and captive.manual_control_actions({"command":"lock:right_hip_1"}).is_empty(),"Cylinder mapping respects individual and mirrored lock state")
	var crane=Crane.new();game.add_child(crane);crane.game=game;crane.equipment_id="service_crane";crane.console_node=node
	game.equipment.register(crane)
	crane.options.assign([{"action":"up"},{"action":"guide:take_weight"},{"action":"guide:transfer_weight"}])
	expect(selected(crane,"up").is_empty(),"Offered crane console operations have no cue")
	for action in ["pick:a","pick:b","attach:front","detach:c","detach:d"]:crane.entries.append(entry(crane,action,node))
	crane.endpoints={"c":{"point":"front"},"d":{"point":"aft"}}
	crane.unavailable=["pick:b","detach:d"]
	expect(selected(crane,"","connect")==["pick:a","attach:front"],"Connector objective follows eligible pickup and attachment controls")
	expect(selected(crane,"","detach")==["detach:c"],"Detach objective excludes unavailable connectors")
	expect(crane.manual_control_entries({"op":"detach","point":"aft"}).is_empty(),"Point-specific detach never cues another connector")
	crane.guided_node=backpack
	expect(selected(backpack,"take_weight").is_empty(),"Backpack crane console operation has no cue")
	var shoulder=preload("res://scripts/shoulder_support.gd").new();game.add_child(shoulder);shoulder.game=game
	crane.guided_node=shoulder
	expect(selected(shoulder,"transfer_weight").is_empty(),"Shoulder crane console operation has no cue")

func run() -> void:
	game=World.new();root.add_child(game)
	game.camera=Camera3D.new();game.add_child(game.camera)
	game.player=CharacterBody3D.new();game.add_child(game.player)
	game.targeting=preload("res://scripts/targeting.gd").new(game)
	game.interaction_outline=preload("res://scripts/interaction_outline.gd").new();game.add_child(game.interaction_outline)
	var node=mesh()
	mappings(node)
	var machine=Fixture.new();game.add_child(machine);machine.game=game;machine.equipment_id="fixture";game.equipment.register(machine)
	var control=entry(machine,"left_leg:ankle:outboard",node)
	control.manual_command="engage:left_leg:ankle:outboard"
	machine.entries.assign([control])
	var cue=Guidance.new();game.add_child(cue);cue.setup(game);cue.update()
	expect(cue.visible_controls==[node],"Brace metadata contract resolves the actual handle without English parsing")
	var material=cue.outlines[0].outline_material
	expect(material.shader.resource_path.ends_with("manual_control_glow.gdshader") and material.next_pass.shader==game.interaction_outline.outline_material.shader and game.interaction_outline.outline_material.next_pass==null,"Control cues glow over a thin contour while pickup focus keeps its plain contour")
	var contour=cue.outlines[0].copies[node.get_instance_id()].outline
	for i in range(120):cue.update()
	expect(cue.outlines[0].copies[node.get_instance_id()].outline==contour and cue.outlines.all(func(outline):return outline.outline_material==material),"120 stable cue updates reuse contours and one shared material")
	machine.unavailable=[control.action];cue.update()
	expect(cue.visible_controls.is_empty() and not contour.visible,"Unavailable control clears immediately without a manual-state event")
	machine.unavailable=[];cue.update()
	expect(cue.visible_controls==[node],"Restored prerequisites recover the cue")
	game.manual_progress.current=-1;game.manual_progress.updated.emit();cue.update()
	expect(cue.visible_controls.is_empty(),"Completed tracked objective clears its cue")
	game.manual_progress.current=0;game.manual_progress.updated.emit();cue.update()
	expect(cue.visible_controls==[node],"Undo and loaded/restaged manual updates restore the cue")
	game.manual_progress.definition={"objectives":[{"op":"fit","slots":["pin"]}]};game.manual_progress.updated.emit();cue.update()
	expect(cue.visible_controls.is_empty(),"An earlier fitting objective supersedes the machine action")
	game.manual_progress.definition={"objectives":[{"op":"seat","slot":"shin","via":{"machine":"fixture","command":control.manual_command}}]};game.manual_progress.updated.emit();cue.update()
	expect(cue.visible_controls==[node],"Seat-via objective resolves its typed machine action")
	game.manual_progress.locked=true;game.manual_progress.updated.emit();cue.update()
	expect(cue.visible_controls.is_empty(),"Pinning a locked step never advertises future controls")
	game.manual_progress.locked=false;game.manual_progress.updated.emit();cue.update()
	game.paused=true;cue.update()
	expect(cue.visible_controls.is_empty(),"Pausing clears physical guidance")
	game.paused=false;cue.update()
	expect(cue.visible_controls==[node],"Resume retains the tracked objective and restores guidance")
	node.hide();cue.update();expect(cue.visible_controls.is_empty(),"Hidden handles cannot leave a stale cue")
	node.show();game.camera.position=Vector3(0,0,Guidance.RANGE);cue.update();expect(cue.visible_controls.is_empty(),"Distant controls have no waypoint-like cue")
	game.camera.position=Vector3.ZERO;game.camera.rotation.y=PI;cue.update();expect(cue.visible_controls.is_empty(),"Offscreen controls have no cue")
	game.camera.rotation.y=0
	game.interaction_outline.focus(node);cue.update();expect(cue.visible_controls.is_empty(),"Meaningful interaction focus takes priority over guidance")
	game.interaction_outline.clear();cue.update()
	var blocker=StaticBody3D.new();game.add_child(blocker);blocker.position=Vector3(0,0,-1)
	var shape=CollisionShape3D.new();shape.shape=BoxShape3D.new();blocker.add_child(shape)
	await frames(2)
	cue.update();expect(cue.visible_controls.is_empty(),"Real physics obstruction suppresses a fully occluded control")
	blocker.queue_free();await frames(2);cue.update()
	expect(cue.visible_controls==[node],"Removing the obstruction restores the retained cue")
	game.desktop_input.held={"controller":machine,"action":control.action};cue.update()
	expect(cue.visible_controls.is_empty(),"The cue rests while E holds its control")
	game.desktop_input.held={};cue.update()
	expect(cue.visible_controls==[node],"Letting go restores the cue")
	# A control that is its own collider (the leg rig's foot support pad).
	var pad=StaticBody3D.new();game.add_child(pad);pad.position=Vector3(0,0,-2)
	var pad_shape=CollisionShape3D.new();pad_shape.shape=BoxShape3D.new();pad_shape.shape.size=Vector3(.3,.3,.3);pad.add_child(pad_shape)
	await frames(2)
	cue.update();expect(cue.visible_controls.is_empty(),"A control's own solid hides its centre without sight_self")
	control.allowed=[pad];control.sight_self=true;cue.update()
	expect(cue.visible_controls==[node],"A sight_self control is seen when the sightline reaches its own solid")
	pad.queue_free();await frames(2);control.erase("allowed");control.erase("sight_self")
	game.manual_progress._queued=true;cue.update();expect(cue.visible_controls.is_empty(),"Queued manual changes clear stale cues before deferred recomputation")
	expect(Objectives.note({"objectives":[{"op":"operate"}],"note":{"at":0,"text":"Fit both end pins first."}},0)=="Fit both end pins first." and Objectives.note({"objectives":[{"op":"connect"}]},0).is_empty(),"Machine notes show only authored details")
	var passed=checks.all(func(check):return check.passed)
	print("MANUAL_CONTROL_GUIDANCE ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
