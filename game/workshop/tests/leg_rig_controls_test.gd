extends "res://tests/kit/harness.gd"
## Operated leg rig contracts with the real holder geometry and a small supplied
## model: v2 controls, interlocks, continuous child poses and at-rest saves. Mechanical
## evidence only; panel readability and jog feel need a player.
const Rail = preload("res://scripts/indexed_leg_rail.gd")
const Layout = preload("res://scripts/leg_bay_layout.gd")
const RigTarget = preload("res://scripts/rig_target.gd")
const EquipmentButton = preload("res://scripts/equipment_button.gd")
class Game extends "res://tests/kit/model_workshop.gd":
	var camera: Camera3D
	var manual_control_guidance = {"machine":null,"objective":{}}
	var primitives = preload("res://scripts/primitives.gd").new()
	func material(color: Color, metal: float = 0.0) -> Material:return primitives.material(color,metal)
	func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:return primitives.box(parent,at,size,mat,solid)
	func sign_panel(parent: Node3D, text: String, at: Vector3, size: Vector2, font: int, pixel: float, yaw: float = 0.0) -> Label3D:return primitives.sign_panel(parent,text,at,size,font,pixel,yaw)
class Holder extends Node3D:
	var cradle: Node3D
class Access extends WorkshopEquipment:
	var opened := false
	var upper_opened := true
	func front_open(front: String) -> bool:return opened if front=="lower" else upper_opened
	func front_closed(front: String) -> bool:return not front_open(front)
class Braces extends WorkshopEquipment:
	var missing := ""
	func required_error(_owner: String, _milestone: String = "") -> String:return missing
	func sync_pose() -> void:pass
class Gantry extends WorkshopEquipment:
	var secured := true
	func support_secured(_assembly: String = "pelvis", _model: AssemblyModel = null, _state: Dictionary = {}) -> bool:return secured
class Pins extends WorkshopEquipment:
	var locked := false
	func group_ready(_group: String, _data: Dictionary = {}) -> bool:return locked
var game: Game
var rail
var access: Access

func _initialize() -> void:run.call_deferred()

func tick(count: int = 1, delta: float = .1) -> void:
	for step in range(count):
		rail.physics(delta)
		# Match EquipmentRegistry.physics: observe every motion transition before
		# asking save_capture for the last completed stop.
		game.equipment._remember_rest([rail])

## Holds one arrow as Hold E does, until the jog reaches its stop.
func hold(action: String, limit: int = 400) -> void:
	rail.set_jog(action)
	for step in range(limit):
		tick()
		if rail.jog_settled():break

func jog(action: String) -> void:
	var error: String=rail.action_error(action)
	expect(error.is_empty(),action+" is available: "+error)
	hold(action)
	expect(rail.jog_settled(),action+" reaches its stop")
	rail.set_jog("")

func refusal(action: String, contains: String, label: String) -> void:
	var error: String=rail.action_error(action)
	expect(error.contains(contains),label+", got "+error)

## Today's path-based holder pose, kept only to prove the new joints reproduce it.
func legacy(spec: Dictionary, state: Dictionary) -> Dictionary:
	var p: float=state.path;var angle=PI/2*(1-clampf(p-1,0,1))
	var z=lerpf(spec.home_z,spec.bay_z,clampf(p,0,1));var rise=spec.dock_rise*clampf(p-2,0,1)
	var x: float=state.index_x
	var lower=spec.delivery_lower*clampf((p-1)/spec.lower_during_turn,0,1)
	var root=Vector3(x,spec.base_y+spec.lying_lift*sin(angle)-lower+rise,z-spec.pivot*sin(angle))
	var basis=Basis(Vector3.RIGHT,angle)
	if p==0 and state.engaged:
		root.y=lerpf(spec.base_y+spec.lying_lift,spec.roll_axis_y,state.roll_height)
		basis*=Basis(Vector3.UP,deg_to_rad(state.roll))
	var release_value: float=state.release
	if not state.engaged or release_value>0:
		if p==3:root.y-=spec.holder.lower*clampf(release_value-1,0,1)
		else:
			var empty_y: float=spec.holder.empty_root_base+spec.holder.empty_root_lift*sin(angle)
			root.y=lerpf(root.y,empty_y,clampf(release_value,0,1))
		root+=basis*Vector3(0,0,spec.holder.withdrawal*clampf(release_value-2,0,1))
		root.x+=(spec.holder.outboard if state.lane=="right" else -spec.holder.outboard)*clampf(release_value-4,0,1)
	return {"frame":Transform3D(basis,root),"bogie_x":x,"bogie_z":z,"opening":clampf(release_value,0,1),"compact":clampf(release_value-3,0,1)}

func run() -> void:
	game=Game.new();root.add_child(game)
	var data={"version":1,"parts":{"foot":{"family":"foot","carry_class":"hand"},"ring":{"family":"ring","carry_class":"hand"}},"assemblies":{
		"leg":{"work_locations":["support:leg_holder","support:leg_queue_left","support:leg_queue_right"],"slots":{"foot":{"accepts":"foot"},"toe":{"assembly":"toe","milestone":"ready"}},"milestones":{"structural_ready":["foot"]}},
		"toe":{"work_locations":["fixture"],"slots":{"nail":{"accepts":"ring"}},"milestones":{"ready":["nail"]}},
		"pelvis":{"work_locations":["fixture"],"slots":{
			"left_leg":{"assembly":"leg","milestone":"structural_ready","support_required":true,"source_supports":["leg_holder"],"snap_position":[0,1,0]},
			"right_leg":{"assembly":"leg","milestone":"structural_ready","support_required":true,"source_supports":["leg_holder"],"snap_position":[2.2,1,0]},
			"ring":{"accepts":"ring","requires":["left_leg"]}},
			"milestones":{"left_leg_secured":["left_leg","ring"],"right_leg_secured":["right_leg"]}}}}
	var scenario={"version":1,"parts":[{"instance_id":"lfoot","kind":"foot"},{"instance_id":"ring1","kind":"ring"}],
		"supports":{"leg_holder":{"assemblies":["leg"]},"leg_queue_left":{"assemblies":["leg"]},"leg_queue_right":{"assemblies":["leg"]}},
		"builds":[],
		"parents":[{"id":"pelvis","definition":"pelvis"},{"id":"left_leg","definition":"leg","location":"support:leg_holder"},{"id":"toe","definition":"toe"},{"id":"right_leg","definition":"leg","location":"support:leg_queue_right"}]}
	var errors: Array=game.model.configure(data,scenario)
	expect(errors.is_empty(),"isolated legs and hip configure: "+str(errors))
	if not errors.is_empty():game.free();quit(1);return
	game.runtime=AssemblyRuntime.new(game.model,{})
	game.zones=preload("res://scripts/zone_register.gd").new(["limb_station"])
	var spec: Dictionary=Layout.layout().workshop.rail
	# The hip slot frame sits exactly at the joint-coordinate seated pose.
	var pelvis=Node3D.new();game.add_child(pelvis);pelvis.position=Vector3(spec.lanes.left,spec.base_y-spec.delivery_lower+spec.dock_rise-1,spec.bay_z);game.runtime.register_node("pelvis",pelvis)
	for id in ["left_leg","right_leg"]:
		var body=AnimatableBody3D.new();body.sync_to_physics=false;game.add_child(body);game.runtime.register_node(id,body)
		var shape=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=Vector3(.2,.2,.2);body.add_child(shape)
		var mesh=MeshInstance3D.new();mesh.mesh=BoxMesh.new();body.add_child(mesh)
	game.runtime.node("right_leg").position=Vector3(40,0,40)
	# A supplied nested child: mounted children must follow every carried pose.
	var toe=AnimatableBody3D.new();toe.sync_to_physics=false;game.runtime.node("left_leg").add_child(toe);toe.position=Vector3(0,1.5,0);game.runtime.register_node("toe",toe)
	var toe_shape=CollisionShape3D.new();toe_shape.shape=BoxShape3D.new();toe_shape.shape.size=Vector3(.1,.1,.1);toe.add_child(toe_shape)
	var toe_mesh=MeshInstance3D.new();toe_mesh.mesh=BoxMesh.new();toe_mesh.position=Vector3(.02,.03,.04);toe.add_child(toe_mesh)
	game.model.assemblies.left_leg.slots.toe="toe";game.model.assemblies.toe.parent="left_leg";game.model.assemblies.toe.parent_slot="toe";game.model.assemblies.toe.location="parent"
	var holder=Holder.new();game.add_child(holder);holder.cradle=preload("res://scripts/leg_cradle.gd").new();holder.add_child(holder.cradle);holder.cradle.setup(game,spec)
	access=Access.new();access.equipment_id="workshop_access";game.add_child(access);game.equipment.register(access)
	var braces=Braces.new();braces.equipment_id="joint_restraints";game.add_child(braces);game.equipment.register(braces)
	var gantry=Gantry.new();gantry.equipment_id="module_supports";game.add_child(gantry);game.equipment.register(gantry)
	var pins=Pins.new();pins.equipment_id="captive_controls";game.add_child(pins);game.equipment.register(pins)
	rail=Rail.new();game.add_child(rail);rail.game=game;rail.layout=holder;rail.spec=spec;rail.equipment_id="leg_rail";game.equipment.register(rail)
	rail.index_x=spec.station_x;rail.travel_z=spec.home_z
	rail.build_controls()
	rail.ghost=RigTarget.new(game.runtime);game.add_child(rail.ghost)
	rail._pose()
	await frames(2)

	# Pose function: independent joints reproduce today's holder at every endpoint.
	var pairs=[
		[{"path":0.0,"index_x":14.0},{}],[{"path":0.0,"index_x":11.9},{"index_x":11.9}],
		[{"path":.5,"index_x":11.9},{"index_x":11.9,"travel_z":20.25}],[{"path":1.0,"index_x":11.9},{"index_x":11.9,"travel_z":26.0}],
		[{"path":1.1,"index_x":11.9},{"index_x":11.9,"travel_z":26.0,"tilt_deg":9.0}],[{"path":2.0,"index_x":11.9},{"index_x":11.9,"travel_z":26.0,"tilt_deg":90.0}],
		[{"path":2.5,"index_x":11.9},{"index_x":11.9,"travel_z":26.0,"tilt_deg":90.0,"rise_m":.6}],[{"path":3.0,"index_x":11.9},{"index_x":11.9,"travel_z":26.0,"tilt_deg":90.0,"rise_m":1.2}],
		[{"path":0.0,"index_x":14.0,"roll":90.0,"roll_height":1.0},{"roll_deg":90.0,"roll_height_m":1.25}],
		[{"path":3.0,"index_x":11.9,"release":2.5},{"index_x":11.9,"travel_z":26.0,"tilt_deg":90.0,"rise_m":1.2,"release":2.5}],
		[{"path":2.0,"index_x":11.9,"release":5.0,"engaged":false},{"index_x":11.9,"travel_z":26.0,"tilt_deg":90.0,"release":5.0,"engaged":false}],
		[{"path":1.0,"index_x":11.9,"release":5.0,"engaged":false},{"index_x":11.9,"travel_z":26.0,"release":5.0,"engaged":false}],
		[{"path":0.0,"index_x":14.1,"release":5.0,"engaged":false,"lane":"right"},{"index_x":14.1,"release":5.0,"engaged":false,"lane":"right"}],
		[{"path":0.0,"index_x":14.0,"release":5.0,"engaged":false},{"release":5.0,"engaged":false}]]
	for pair in pairs:
		var old_state={"path":0.0,"index_x":14.0,"roll":0.0,"roll_height":0.0,"release":0.0,"engaged":true,"lane":"left"};old_state.merge(pair[0],true)
		var new_state=rail._state();new_state.merge({"index_x":14.0,"travel_z":14.5,"tilt_deg":0.0,"rise_m":0.0,"roll_deg":0.0,"roll_height_m":0.0,"release":0.0,"engaged":true,"lane":"left"},true);new_state.merge(pair[1],true)
		var a=legacy(spec,old_state);var b=rail.snapshot_pose(new_state)
		expect(a.frame.is_equal_approx(b.frame) and is_equal_approx(a.bogie_x,b.bogie_x) and is_equal_approx(a.bogie_z,b.bogie_z) and a.opening==b.opening and a.compact==b.compact,"joint pose reproduces legacy path "+str(pair[0]))
	expect(rail.snapshot_pose(rail._state()).frame.is_equal_approx(Transform3D(Basis(Vector3.RIGHT,PI/2),Vector3(spec.station_x,1.85,9.4))),"build home root matches the design target")
	var seated_state=rail._state();seated_state.merge({"index_x":spec.lanes.left,"travel_z":spec.bay_z,"tilt_deg":90.0,"rise_m":spec.dock_rise},true)
	expect(rail.snapshot_pose(seated_state).frame.is_equal_approx(game.runtime.mount_pose("pelvis","left_leg","left_leg")),"seated joints equal the runtime install pose")

	# Physical controls are on their authored mechanisms, with one input each.
	var actions: Dictionary={}
	for entry in rail.buttons:
		actions[entry.action]=int(actions.get(entry.action,0))+1
		expect(EquipmentButton.hold_handler(entry).is_valid()==(entry.action in Rail.HOLDS or entry.action in Rail.DRAGS),entry.action+" has the correct hold/tap input")
		if entry.action in ["travel+","travel-","rise+","rise-","next_leg"]:
			expect(entry.node.get_meta("control_bank").position.is_equal_approx(AssemblyRuntime.vec(spec.controls.bogie_box)),entry.action+" is on the bogie box")
		elif entry.action in ["lift+","lift-","roll+","roll-"]:
			expect(entry.node.get_meta("control_bank").position.is_equal_approx(AssemblyRuntime.vec(spec.controls.turnover_box)),entry.action+" is on the turnover box")
	for action in Rail.HOLDS+Rail.DRAGS+Rail.TAPS:expect(actions.get(action,0)==(2 if action=="support" else 1),action+" has exactly its specified controls")
	expect(rail.lever_pivot.get_parent().position.is_equal_approx(AssemblyRuntime.vec(spec.controls.lever)),"lever stands at the layout position")
	for side in [-1,1]:
		expect(rail.buttons.any(func(entry):return entry.action=="support" and entry.node==holder.cradle.pieces["BolsterPad_"+str(side)].visual),"support drag is attached to pad "+str(side))
	refusal("clamps","not seated","unseated leg cannot release its clamps")
	refusal("roll+","prepared foot","turnover needs the received foot")
	game.model.items.lfoot.owner="left_leg";game.model.items.lfoot.slot="foot";game.model.items.lfoot.location="installed";game.model.assemblies.left_leg.slots.foot="lfoot"
	refusal("next_leg","occupied","NEXT LEG cannot replace physical construction")
	check_lamps(braces,gantry)
	expect(rail.request("lift+").contains("Hold E"),"tap on a held arrow explains its input")
	expect(rail.request("support").contains("hold E"),"tap on a support explains dragging")
	refusal("roll+","Raise the turnover","roll needs raised turnover")
	braces.missing="Engage both knee braces first."
	refusal("support","knee braces","support needs locked braces")
	refusal("lift+","knee braces","turnover needs locked braces")
	braces.missing=""

	# Drag a real pad by moving the supplied camera/hand along both path segments.
	for stroke in [0.0,.15,float(spec.holder.bolster.spread_fraction),.7,1.0]:
		var state=rail._state();state.foot_support=stroke
		var at=rail.snapshot_pose(state)
		var pad=holder.cradle.geometry(at.frame,at.bogie_x,at.bogie_z,at.opening,at.compact,stroke).filter(func(record):return record.id=="BolsterPad_1")[0]
		expect(is_equal_approx(rail._support_param(pad.pose.origin),stroke),"hand maps to spread/slide stroke "+str(stroke))
	game.camera=Camera3D.new();game.add_child(game.camera)
	var pad: Node3D=holder.cradle.pieces.BolsterPad_1.visual
	game.camera.global_position=pad.global_position+Vector3(0,0,1.5)
	var support_handler=EquipmentButton.hold_handler(rail.buttons.filter(func(entry):return entry.action=="support")[0])
	support_handler.call(true,.1)
	var clear=rail._state();clear.foot_support=1.0
	var clear_pose=rail.snapshot_pose(clear)
	var clear_pad=holder.cradle.geometry(clear_pose.frame,clear_pose.bogie_x,clear_pose.bogie_z,clear_pose.opening,clear_pose.compact,1.0).filter(func(record):return record.id=="BolsterPad_1")[0]
	game.camera.global_position=clear_pad.pose.origin+Vector3(0,0,rail.drag.distance)
	support_handler.call(true,.1);tick()
	expect(is_equal_approx(rail.foot_support,Rail.SUPPORT_SPEED*.1),"drag follows the hand at the support speed limit")
	support_handler.call(false,0.0)
	var released_at: float=rail.foot_support;tick(3)
	expect(not rail.moving and rail.foot_support==released_at,"release stops the support immediately")
	pull(0)
	jog("lift+")
	expect(rail.roll_height_m==rail._lift_max(),"turnover reaches the raise end stop")
	refusal("support","lower it","raised turnover locks the support")
	jog("roll+");expect(rail.roll_deg==90,"roll stops at first quarter turn")
	rail.set_jog("roll+");hold("roll+");var detent: float=rail.roll_deg;tick(5)
	expect(detent==180 and rail.roll_deg==detent,"fresh press advances once and holding stays at the detent")
	rail.set_jog("")
	refusal("lift-","neutral","lowering needs neutral roll")
	jog("roll-");jog("roll-");jog("roll-")
	expect(rail.roll_deg==270,"negative roll wraps through neutral")
	jog("roll+");expect(rail.roll_deg==0,"positive roll wraps to neutral")
	refusal("lever","lower it","raised turnover locks the table")
	jog("lift-");expect(rail.roll_height_m==0,"turnover reaches the lower end stop")
	refusal("lever","foot support","table requires support away")
	var locked_angle: float=rail.lever_angle
	expect(not rail.throw_lever(spec.lanes.left).is_empty() and rail.lever_angle==locked_angle and rail.table_goal<0,"locked lever stays in its notch")
	pull(1);expect(rail.foot_support==1 and rail.manual_state().support_away,"programmatic support pull finishes at the end stop")
	refusal("lift+","support back","turnover needs support under the foot")
	refusal("travel+","LEFT HIP","travel needs this leg's hip notch")
	var notches: Array=rail.notches()
	expect(notches.map(func(n):return n.x)==[float(spec.lanes.left),float(spec.station_x),float(spec.lanes.parking)],"lever has left, build/right and park notches")
	game.manual_control_guidance={"machine":rail,"objective":{"command":"travel:bay"}}
	rail._refresh();var table_ghost: Transform3D=rail.ghost.global_transform
	lever(spec.lanes.parking,false);tick(2)
	var table_at: float=rail.index_x
	expect(table_at>spec.station_x and rail.moving,"lever throw drives the table")
	expect(rail.ghost.visible and rail.ghost.global_transform.is_equal_approx(table_ghost),"travel objective's ghost stays fixed while the table lever moves another mechanism")
	lever(spec.lanes.left)
	expect(rail.index_x==spec.lanes.left and not rail.moving,"moving table accepts a new notch and stops exactly")
	refusal("support","build position","support only operates at build")
	for pair in [["tilt_deg",1.0,"flat"],["release",.5,"clamps"],["foot_support",0.0,"foot support"]]:
		var before=rail.get(pair[0]);rail.set(pair[0],pair[1]);refusal("travel+",pair[2],"travel interlock "+pair[0]);rail.set(pair[0],before)
	braces.missing="Lock the braces.";refusal("travel+","braces","travel requires braces");braces.missing=""
	game.model.assemblies.left_leg.slots.foot=""
	refusal("travel+","Complete the structural leg","TO BAY requires a complete leg")
	expect(rail.action_error("travel-").is_empty(),"TO TABLE allows returning an incomplete leg")
	game.model.assemblies.left_leg.slots.foot="lfoot"

	# Ghost follows the objective, never the currently operated mechanism.
	game.manual_control_guidance={"machine":rail,"objective":{"command":"travel:bay"}}
	rail._refresh();var ghost_pose: Transform3D=rail.ghost.global_transform
	expect(rail.ghost.visible and ghost_pose.is_equal_approx(rail.objective_target()),"manual objective exposes its fixed target")
	game.manual_control_guidance.machine=access;rail._refresh()
	expect(not rail.ghost.visible,"another machine's objective hides the leg ghost")
	game.manual_control_guidance.machine=rail
	rail.set_jog("travel+");tick()
	expect(rail.travel_z>spec.home_z and rail.blocked_reason.is_empty(),"travel starts immediately without crossing gates")
	expect(rail.ghost.global_transform.is_equal_approx(ghost_pose),"ghost stays fixed while travel moves")
	hold("travel+");rail.set_jog("")
	expect(rail.travel_z==spec.bay_z,"TO BAY stops exactly")
	refusal("lever","onto the table","off-table bogie locks the lever")
	refusal("rise+","lower front","closed lower front refuses RISE even with the upper leaves open")
	expect(rail.gantry_occupant("lower").is_empty() and rail.gantry_occupant("upper").is_empty(),"flat rig occupies neither gantry front")
	access.opened=true;gantry.secured=false
	refusal("rise+","gantry jaws","RISE requires secured hip gantry");gantry.secured=true
	game.manual_control_guidance.objective={"command":"rise"};rail._refresh()
	expect(rail.ghost.visible and rail.ghost.global_transform.is_equal_approx(game.runtime.mount_pose("pelvis","left_leg","left_leg")),"RISE ghost equals the runtime mount pose")
	game.manual_control_guidance.objective={"command":"support:away"};rail._refresh()
	expect(not rail.ghost.visible,"non-pose objectives hide the ghost")
	game.manual_control_guidance.objective={"command":"rise"}
	var installs={"count":0,"parent":""}
	game.model.changed.connect(func():
		var parent: String=game.model.assemblies.left_leg.parent
		if parent=="pelvis" and installs.parent!="pelvis":installs.count+=1
		installs.parent=parent)
	rail.set_jog("rise+")
	var follows=true;var samples=0;var tilt_before_lift=true
	for step in range(400):
		tick()
		if rail.tilt_deg>0 and rail.tilt_deg<90:
			samples+=1
			var state: Transform3D=PhysicsServer3D.body_get_state(toe.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
			var expected: Transform3D=game.runtime.node("left_leg").global_transform*Transform3D(Basis.IDENTITY,Vector3(0,1.5,0))
			follows=follows and state.is_equal_approx(expected) and toe.global_transform.is_equal_approx(expected) and toe_mesh.global_transform.is_equal_approx(expected*toe_mesh.transform)
			tilt_before_lift=tilt_before_lift and rail.rise_m==0 and rail.gantry_occupant("lower")=="leg on the leg rig" and rail.gantry_occupant("upper").is_empty()
		if rail.jog_settled():break
	expect(samples>40 and follows,"nested child follows every intermediate tilt in node and physics poses ("+str(samples)+" samples)")
	expect(tilt_before_lift and rail.tilt_deg==90 and rail.rise_m==spec.dock_rise,"RISE tilts before lifting to the exact top stop")
	tick(5);rail.set_jog("")
	expect(installs.count==1 and game.model.assemblies.left_leg.parent=="pelvis","held RISE installs exactly once")
	expect(game.runtime.node("left_leg").global_transform.is_equal_approx(game.runtime.mount_pose("pelvis","left_leg","left_leg")),"installation mounts the exact runtime pose")
	expect(not rail.ghost.visible and rail.gantry_occupant("lower").is_empty(),"mounted leg hides its ghost and no longer occupies the lower front as a rig load")
	access.opened=false
	refusal("rise-","lower front","loaded LOWER needs the lower front open")
	access.opened=true
	refusal("clamps","Complete hip retention","RELEASE needs complete retention")
	jog("rise-")
	expect(game.model.assemblies.left_leg.parent.is_empty() and rail.tilt_deg==0 and rail.rise_m==0,"LOWER unseats without retention, lowers then lays flat")
	jog("rise+")
	game.model.items.ring1.owner="pelvis";game.model.items.ring1.slot="ring";game.model.items.ring1.location="installed";game.model.assemblies.pelvis.slots.ring="ring1"
	game.model.assemblies.pelvis.history.append({"slot":"ring"})
	refusal("rise-","Remove hip retention","retention refuses LOWER")
	refusal("clamps","Complete hip retention","ring without pins refuses RELEASE")
	pins.locked=true
	expect(rail.request("clamps").is_empty(),"complete retention permits RELEASE")
	tick(3);var opening: float=rail.release
	expect(opening>0 and opening<5 and rail.moving,"clamps move through the linkage")
	expect(rail.request("clamps").is_empty(),"tap while moving reverses clamps")
	settle();expect(rail.release==0 and rail.engaged,"reversed clamps return to closed")
	clamps();expect(rail.release==5 and not rail.engaged and rail.rise_m==0,"RELEASE finishes and leaves the rig empty")
	lamp("bogie","CLAMPS RELEASED",true)
	rail.release=4;lamp("bogie","CLAMPS RELEASED",false);rail.release=5
	clamps();expect(rail.release==0 and rail.supports_seated("left_leg"),"GRAB at dock restores leg support")
	clamps();access.opened=false
	jog("rise-");expect(rail.tilt_deg==0 and rail.rise_m==0,"empty LOWER only lays down with the lower front closed")
	jog("rise+");expect(rail.tilt_deg==90 and rail.rise_m==0,"empty RISE only stands up")
	jog("rise-");jog("travel-");expect(rail.travel_z==spec.home_z,"TO TABLE stops exactly")
	lever(spec.station_x);clamps()
	expect(not rail.engaged and rail.release==0 and rail.at_home(),"GRAB extends the empty rig at build")
	# The shared API permits a closed OR fully released empty holder on the table.
	expect(rail.action_error("lever").is_empty(),"closed empty clamps permit a table lever throw: "+rail.action_error("lever"))
	expect(rail.request("next_leg").is_empty() and rail.active_assembly=="right_leg" and rail.engaged and rail.foot_support==0,"NEXT LEG selects the queued right leg")

	# Save snapshots use the registry's last stop while motion is interrupted.
	var saved: Dictionary=rail.capture()
	expect(saved.version==3 and saved.has("clamps") and saved.has("foot_support") and not saved.has("moving") and not saved.has("release"),"v3 saves use at-rest coordinates and normalized clamps")
	expect(rail.validate(saved).is_empty(),"at-rest save validates: "+str(rail.validate(saved)))
	for version in [1,2]:
		var old=saved.duplicate();old.version=version
		expect(not rail.validate(old).is_empty(),"v"+str(version)+" saves are rejected")
	game.equipment._remember_rest([rail]);pull(1)
	game.equipment._remember_rest([rail]);var rest: Dictionary=rail.capture()
	lever(spec.lanes.parking,false);tick(3)
	var interrupted: Dictionary=game.equipment.save_capture().leg_rail
	expect(rail.moving and rail.index_x!=rest.index_x and interrupted==rest,"interrupted table motion saves its last stop, never intermediate coordinates: rest X="+str(rest.index_x)+", live X="+str(rail.index_x)+", saved X="+str(interrupted.index_x))
	rail.apply(saved)
	expect(rail.capture()==saved and not rail.moving and rail.jog.is_empty() and rail.drag.is_empty(),"at-rest v3 save round-trips and clears transient inputs")
	finish()

## Check each condition against both the box's data and its actual label color.
func lamp(box: String, label: String, ok: bool) -> void:
	rail._refresh()
	var needs: Array=rail._box_needs(box)
	var row: int=needs.find_custom(func(need):return need.label==label)
	var matches: bool=row>=0 and needs[row].ok==ok
	if row>=0:
		var light: Label3D=rail.lamps[box][row]
		matches=matches and light.visible and light.text=="● "+label and light.modulate.is_equal_approx(Rail.GREEN if ok else Rail.RED)
	expect(matches,box+" lamp "+label+" is "+("green" if ok else "red"))

func check_lamps(braces: Braces, gantry: Gantry) -> void:
	lamp("turnover","AT BUILD POSITION",true)
	rail.index_x=rail.spec.lanes.left;lamp("turnover","AT BUILD POSITION",false);lamp("bogie","TABLE AT LEFT HIP",true)
	rail.index_x=rail.spec.station_x;lamp("bogie","TABLE AT LEFT HIP",false)
	lamp("turnover","FOOT RECEIVED",true);lamp("bogie","LEG COMPLETE",true)
	game.model.assemblies.left_leg.slots.foot=""
	lamp("turnover","FOOT RECEIVED",false);lamp("bogie","LEG COMPLETE",false)
	game.model.assemblies.left_leg.slots.foot="lfoot"
	lamp("turnover","FOOT SUPPORT UNDER FOOT",true)
	for box in ["lever","bogie"]:lamp(box,"FOOT SUPPORT AWAY",false)
	rail.foot_support=1
	lamp("turnover","FOOT SUPPORT UNDER FOOT",false)
	for box in ["lever","bogie"]:lamp(box,"FOOT SUPPORT AWAY",true)
	rail.foot_support=0
	for box in ["lever","bogie","turnover"]:lamp(box,"BRACES LOCKED",true)
	braces.missing="Lock the braces."
	for box in ["lever","bogie","turnover"]:lamp(box,"BRACES LOCKED",false)
	braces.missing=""
	lamp("turnover","TURNOVER RAISED",false);lamp("lever","TURNOVER LOWERED",true)
	rail.roll_height_m=rail._lift_max()
	lamp("turnover","TURNOVER RAISED",true);lamp("lever","TURNOVER LOWERED",false)
	rail.roll_height_m=0
	lamp("turnover","ROLL NEUTRAL",true)
	rail.roll_deg=90;lamp("turnover","ROLL NEUTRAL",false);rail.roll_deg=0
	lamp("lever","BOGIE ON TABLE",true);lamp("bogie","BOGIE AT BAY STOP",false)
	rail.travel_z=rail.spec.bay_z
	lamp("lever","BOGIE ON TABLE",false);lamp("bogie","BOGIE AT BAY STOP",true)
	rail.travel_z=rail.spec.home_z
	lamp("bogie","LEG LYING FLAT",true)
	rail.tilt_deg=1;lamp("bogie","LEG LYING FLAT",false);rail.tilt_deg=0
	lamp("bogie","CLAMPS CLOSED",true)
	rail.release=.5;lamp("bogie","CLAMPS CLOSED",false);rail.release=0
	lamp("bogie","LOWER FRONT OPEN",false)
	access.opened=true;access.upper_opened=false;lamp("bogie","LOWER FRONT OPEN",true)
	access.opened=false;access.upper_opened=true
	lamp("bogie","HIP GANTRY SECURED",true)
	gantry.secured=false;lamp("bogie","HIP GANTRY SECURED",false);gantry.secured=true
	rail._pose()

func settle() -> void:
	for step in range(400):
		if not rail.moving:break
		tick()
	expect(not rail.moving,"programmatic motion finishes: "+rail.blocked_reason)
func pull(goal: float) -> void:
	var error: String=rail.pull_support(goal);expect(error.is_empty(),"support pull accepted: "+error)
	settle()
func lever(x: float, wait: bool = true) -> void:
	var error: String=rail.throw_lever(x);expect(error.is_empty(),"lever throw accepted: "+error)
	if wait:settle()
func clamps() -> void:
	var error: String=rail.request("clamps");expect(error.is_empty(),"clamps tap accepted: "+error)
	settle()
func finish() -> void:
	var passed=checks.all(func(c):return c.passed)
	print("LEG_RIG_CONTROLS ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
