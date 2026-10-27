extends "res://tests/kit/harness.gd"
## Operated leg rig contracts with the real holder geometry and a small supplied
## model: joint limits and stops, named refusals, waiting, SEAT gating and lead-in,
## support service, ghost/readout agreement and at-rest snapshots. Mechanical
## evidence only; panel readability and jog feel need a player.
const Rail = preload("res://scripts/indexed_leg_rail.gd")
const Layout = preload("res://scripts/leg_bay_layout.gd")
const RigTarget = preload("res://scripts/rig_target.gd")
const EquipmentButton = preload("res://scripts/equipment_button.gd")
class Game extends "res://tests/kit/model_workshop.gd":
	var primitives = preload("res://scripts/primitives.gd").new()
	func material(color: Color, metal: float = 0.0) -> Material:return primitives.material(color,metal)
	func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:return primitives.box(parent,at,size,mat,solid)
	func sign_panel(parent: Node3D, text: String, at: Vector3, size: Vector2, font: int, pixel: float, yaw: float = 0.0) -> Label3D:return primitives.sign_panel(parent,text,at,size,font,pixel,yaw)
class Holder extends Node3D:
	var cradle: Node3D
class Gates extends WorkshopEquipment:
	var goal := 0.0
	var value := 0.0
	var moving := false
	var occupied := ""
	func occupancy_error() -> String:return occupied
	func closed() -> bool:return value==1.0 and not moving
	func request_closed(close: bool) -> String:goal=1.0 if close else 0.0;moving=value!=goal;return ""
	func physics(_delta: float) -> void:
		if moving:value=goal;moving=false
class Access extends WorkshopEquipment:
	var mode := "work"
	var requested := ""
	var moving := false
	func ready_for(value: String) -> bool:return mode==value and not moving
	func request_mode(value: String) -> String:requested=value;moving=value!=mode;return ""
	func physics(_delta: float) -> void:
		if moving:mode=requested;moving=false
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
var gates: Gates
var access: Access

func _initialize() -> void:run.call_deferred()

func tick(count: int = 1, delta: float = .1) -> void:
	for step in range(count):gates.physics(delta);access.physics(delta);rail.physics(delta)

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
	game.model.assemblies.left_leg.slots.toe="toe";game.model.assemblies.toe.parent="left_leg";game.model.assemblies.toe.parent_slot="toe";game.model.assemblies.toe.location="parent"
	var holder=Holder.new();game.add_child(holder);holder.cradle=preload("res://scripts/leg_cradle.gd").new();holder.add_child(holder.cradle);holder.cradle.setup(game,spec)
	gates=Gates.new();gates.equipment_id="rail_gates";game.add_child(gates);game.equipment.register(gates)
	access=Access.new();access.equipment_id="workshop_access";game.add_child(access);game.equipment.register(access)
	var braces=Braces.new();braces.equipment_id="joint_restraints";game.add_child(braces);game.equipment.register(braces)
	var gantry=Gantry.new();gantry.equipment_id="module_supports";game.add_child(gantry);game.equipment.register(gantry)
	var pins=Pins.new();pins.equipment_id="captive_controls";game.add_child(pins);game.equipment.register(pins)
	rail=Rail.new();game.add_child(rail);rail.game=game;rail.layout=holder;rail.spec=spec;rail.equipment_id="leg_rail";game.equipment.register(rail)
	rail.index_x=spec.station_x;rail.travel_z=spec.home_z
	rail._panel(Vector3(8.78,0,14.5),true);rail._panel(Vector3(8.5,0,24),false)
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
		var new_state=rail.capture();new_state.merge({"index_x":14.0,"travel_z":14.5,"tilt_deg":0.0,"rise_m":0.0,"roll_deg":0.0,"roll_height_m":0.0,"release":0.0,"engaged":true,"lane":"left"},true);new_state.merge(pair[1],true)
		var a=legacy(spec,old_state);var b=rail.snapshot_pose(new_state)
		expect(a.frame.is_equal_approx(b.frame) and is_equal_approx(a.bogie_x,b.bogie_x) and is_equal_approx(a.bogie_z,b.bogie_z) and a.opening==b.opening and a.compact==b.compact,"joint pose reproduces legacy path "+str(pair[0]))
	expect(rail.snapshot_pose(rail.capture()).frame.is_equal_approx(Transform3D(Basis(Vector3.RIGHT,PI/2),Vector3(14,1.85,9.4))),"build home root matches the design target")
	var seated_state=rail.capture();seated_state.merge({"index_x":spec.lanes.left,"travel_z":spec.bay_z,"tilt_deg":90.0,"rise_m":spec.dock_rise},true)
	expect(rail.snapshot_pose(seated_state).frame.is_equal_approx(game.runtime.mount_pose("pelvis","left_leg","left_leg")),"seated joints equal the runtime install pose")

	# Panels: physical arrows use the Hold E latch; taps stay taps.
	var arrows=rail.buttons.filter(func(entry):return EquipmentButton.hold_handler(entry).is_valid())
	var taps=rail.buttons.filter(func(entry):return not EquipmentButton.hold_handler(entry).is_valid())
	expect(arrows.size()==8+6+8 and taps.size()==8+5,"two delivery banks, one construction bank and tap rows, got "+str(arrows.size())+" arrows and "+str(taps.size())+" taps")
	expect(arrows.all(func(entry):return rail._is_jog(entry.action)) and taps.all(func(entry):return entry.action in Rail.TAPS),"every arrow is a jog action and every tap a named command")
	EquipmentButton.hold_handler(arrows[0]).call(true,.1)
	expect(rail.jog==arrows[0].action and rail.moving,"held handler latches its own arrow")
	EquipmentButton.hold_handler(arrows[0]).call(false,0.0)
	expect(rail.jog.is_empty() and not rail.moving,"release handler clears the latch")
	expect(rail.request("bolster+").contains("Hold E"),"a click explains that arrows are held")

	# Construction axes at the Limb Bay station.
	refusal("roll+","Transfer the prepared foot","rolling needs the received foot")
	game.model.items.lfoot.owner="left_leg";game.model.items.lfoot.slot="foot";game.model.items.lfoot.location="installed";game.model.assemblies.left_leg.slots.foot="lfoot"
	refusal("roll+","Raise the construction axis","roll needs the raised axis")
	braces.missing="Engage both knee braces first."
	refusal("lift+","knee braces","loaded construction motion needs the retained braces")
	refusal("index-","knee braces","loaded indexing needs the retained braces")
	braces.missing=""
	jog("lift+")
	expect(is_equal_approx(rail.roll_height_m,1.25) and not rail.can_construct(),"LIFT + stops at the raised axis; a raised leg is not at construction home")
	jog("roll+")
	expect(rail.roll_deg==90.0,"ROLL + stops at the next 90° detent")
	jog("roll+")
	expect(rail.roll_deg==180.0,"a fresh press continues to the following detent")
	refusal("lift-","Restore neutral roll","lowering needs neutral roll")
	jog("roll-");jog("roll-")
	expect(rail.roll_deg==0.0,"ROLL − returns to neutral")
	jog("roll-")
	expect(rail.roll_deg==270.0,"ROLL − below neutral wraps cyclically to 270°")
	jog("roll+")
	expect(rail.roll_deg==0.0,"ROLL + through 360° settles at neutral")
	refusal("index-","neutral roll","indexing needs neutral construction")
	jog("lift-")
	expect(rail.roll_height_m==0.0 and rail.can_construct(),"LIFT − restores construction home")
	refusal("index-","foot bolster","loaded indexing needs the stowed bolster")
	refusal("travel+","foot bolster","delivery needs the stowed bolster")
	jog("bolster+")
	expect(rail.bolster==1.0 and rail.manual_state().bolster,"BOLSTER + stops exactly stowed")
	refusal("roll+","foot bolster","a stowed bolster blocks rolling")

	# Delivery: indexing, refusals and named waiting.
	game.model.items.lfoot.owner="";game.model.assemblies.left_leg.slots.foot=""
	refusal("travel+","Align INDEX","travel needs the selected track")
	jog("index-")
	expect(rail.index_x==spec.lanes.left and rail.manual_state().indexed,"INDEX − stops exactly on the left hip track")
	refusal("tilt+","clear turn position","tilt needs the bay end of travel")
	refusal("rise+","Stand the leg upright","rise needs the upright pose")
	refusal("travel+","Complete the structural leg","unfinished legs cannot leave")
	game.model.items.lfoot.owner="left_leg";game.model.assemblies.left_leg.slots.foot="lfoot"
	gantry.secured=false
	refusal("travel+","gantry jaws","delivery needs the secured hip gantry")
	gantry.secured=true
	expect(rail.request("lane").is_empty() and rail.lane=="right","LANE selects the other hip track")
	refusal("travel+","Align INDEX","the right track is not under the left leg")
	rail.lane="left"
	expect(rail.action_error("travel+").is_empty(),"aligned structural leg may depart: "+rail.action_error("travel+"))
	rail.set_jog("travel+");rail.physics(.1)
	expect(rail.moving and rail.travel_z==spec.home_z and rail.blocked_reason.contains("crossing gates"),"held TRAVEL waits, named, for the ground crossing to close")
	gates.physics(.1);rail.physics(.1)
	expect(rail.travel_z==spec.home_z and rail.blocked_reason.contains("access platforms") and access.requested=="leg","then waits for the hip access platforms")
	gates.occupied="Leave the ground rail corridor before moving the leg rig."
	access.physics(.1);rail.physics(.1)
	expect(rail.travel_z==spec.home_z and rail.blocked_reason==gates.occupied,"a person in the corridor holds motion with the gate message")
	gates.occupied="";hold("travel+")
	expect(rail.travel_z==spec.bay_z and rail.jog_settled() and not rail.manual_state().on_table,"the same held jog resumes and stops at the bay")
	rail.set_jog("")
	expect(gates.goal==1.0,"gates stay closed with the leg away from rest positions")
	expect(rail.manual_state().at_bay and rail.target().name=="upright","the next target is standing the leg upright")
	expect(rail.action_error("tilt+").is_empty(),"tilt+ is available: "+rail.action_error("tilt+"))
	rail.set_jog("tilt+")
	var follows=true;var samples=0
	for step in range(400):
		tick()
		var state: Transform3D=PhysicsServer3D.body_get_state(toe.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
		if rail.tilt_deg>0 and rail.tilt_deg<90:
			samples+=1
			follows=follows and state.is_equal_approx(toe.global_transform) and toe.global_transform.is_equal_approx(game.runtime.node("left_leg").global_transform*Transform3D(Basis.IDENTITY,Vector3(0,1.5,0)))
		if rail.jog_settled():break
	rail.set_jog("")
	expect(samples>40 and follows,"a mounted child's node and physics body follow every intermediate tilt pose ("+str(samples)+" ticks)")
	expect(rail.tilt_deg==90.0 and rail.manual_state().upright,"TILT + stops upright")
	jog("rise+")
	expect(is_equal_approx(rail.rise_m,spec.dock_rise-Rail.SEAT_LEAD) and rail.manual_state().raised,"RISE + stops at its loaded jog ceiling, inside the capture window")
	expect(game.model.assemblies.left_leg.parent.is_empty(),"in-tolerance alignment alone installs nothing")

	# Readouts and ghost from the same target record.
	var record: Dictionary=rail.target()
	expect(record.name=="seated" and rail.ghost.visible and rail.ghost.global_transform.is_equal_approx(game.runtime.mount_pose("pelvis","left_leg","left_leg")),"final alignment ghost is the exact runtime install pose")
	var rise_label: Label3D=rail.readouts[1].rise
	expect(rise_label.text.begins_with("RISE +0.03") and rise_label.modulate==RigTarget.READY_COLOR,"rise readout is signed and green inside the capture window, got "+rise_label.text)
	rail.tilt_deg=89.5;rail._refresh()
	expect(rail.readouts[0].tilt.modulate==RigTarget.ADJUST_COLOR and rail.readouts[0].index.modulate==RigTarget.READY_COLOR,"each axis turns green independently")
	refusal("seat","green axis marks","SEAT refuses outside a tolerance")
	rail.tilt_deg=90.0;rail.index_x=spec.lanes.left+.015;rail._refresh()
	expect(rail.seat_error().is_empty(),"SEAT accepts in-tolerance residual error: "+rail.seat_error())
	rail.set_jog("rise-")
	refusal("seat","Release E","SEAT is a tap only while every jog is released")
	rail.set_jog("")

	# Interrupted and resumed SEAT; one install on arrival.
	var installs={"count":0,"parent":""}
	game.model.changed.connect(func():
		var parent: String=game.model.assemblies.left_leg.parent
		if parent=="pelvis" and installs.parent!="pelvis":installs.count+=1
		installs.parent=parent)
	expect(rail.request("seat").is_empty() and rail.seating,"SEAT starts the guided lead-in")
	tick(2,.1)
	expect(rail.request("stop").is_empty() and not rail.moving and game.model.assemblies.left_leg.parent.is_empty(),"STOP leaves the leg supported part way up")
	var paused_at: float=rail.rise_m
	expect(paused_at>spec.dock_rise-Rail.SEAT_LEAD and paused_at<spec.dock_rise,"the lead-in moved before it stopped")
	expect(rail.validate(rail.capture()).is_empty(),"the interrupted lead-in is a valid braked rest position: "+str(rail.validate(rail.capture())))
	expect(rail.request("seat").is_empty(),"another SEAT revalidates and resumes")
	tick(10,.1)
	expect(not rail.moving and game.model.assemblies.left_leg.parent=="pelvis" and installs.count==1,"arrival installs exactly once")
	expect(rail.index_x==spec.lanes.left and rail.rise_m==spec.dock_rise and game.runtime.node("left_leg").global_transform.is_equal_approx(game.runtime.mount_pose("pelvis","left_leg","left_leg")),"arrival blends to the exact docked joints and install pose")
	expect(access.requested=="work" and gates.goal==0.0,"arrival restores work decks and reopens the crossing")
	expect(not rail.ghost.visible and rail.manual_state().seated,"seated leg hides the ghost and reports seated evidence")
	refusal("rise-","Unseat the leg","a seated leg cannot be jogged")

	# UNSEAT and retention; RELEASE and empty return; REACQUIRE.
	game.model.items.ring1.owner="pelvis";game.model.items.ring1.slot="ring";game.model.items.ring1.location="installed";game.model.assemblies.pelvis.slots.ring="ring1"
	game.model.assemblies.pelvis.history.append({"slot":"ring"})
	refusal("unseat","Remove hip retention","partial retention blocks UNSEAT")
	refusal("release","Complete hip retention","partial retention blocks RELEASE")
	pins.locked=true
	expect(rail.action_error("release").is_empty(),"complete retention and lock pins permit RELEASE")
	rail.request("release");tick(3,.1)
	expect(rail.engaged and rail.release>0 and rail.release<5 and rail.moving,"RELEASE runs the guarded support service")
	rail.request("stop")
	expect(rail.validate(rail.capture()).is_empty(),"a stopped service move is a valid at-rest snapshot")
	refusal("tilt-","Finish the holder","a partly released holder cannot jog")
	rail.request("release");tick(90,.1)
	expect(not rail.engaged and rail.release==5.0 and rail.rise_m==0.0,"release arrival hands the leg to the hip")
	expect(not rail.undo("pelvis").is_empty() and rail.undo("pelvis").handled,"retention cannot be removed while the holder is released")
	refusal("rise+","Reacquire","the empty holder cannot rise")
	expect(rail.request("reacquire").is_empty(),"REACQUIRE at the dock closes on the mounted leg")
	tick(90,.1)
	expect(rail.engaged and rail.release==0.0 and rail.supports_seated("left_leg") and not rail.undo("pelvis").handled,"reacquired holder supports the leg for retention correction")
	rail.request("release");tick(90,.1)
	jog("tilt-")
	expect(rail.tilt_deg==0.0 and gates.goal==1.0,"the empty holder lies down behind closed gates")
	jog("travel-")
	expect(rail.on_table() and gates.goal==0.0,"travel home reopens the crossing at rest")
	refusal("build","extend its holder","BUILD needs the station and an extended holder")
	jog("index+")
	expect(rail.at_station() and rail.target().name=="extend","INDEX + stops at the station")
	expect(rail.request("reacquire").is_empty(),"REACQUIRE extends the empty holder at the station")
	tick(90,.1)
	expect(not rail.engaged and rail.at_home() and rail.manual_state().home,"extended empty holder is home without supporting a leg")
	expect(rail.request("build").is_empty() and rail.active_assembly=="right_leg" and rail.engaged and rail.lane=="right","BUILD selects the queued right leg")

	# At-rest snapshots.
	var saved: Dictionary=rail.capture()
	expect(not saved.has("path") and not saved.has("moving") and not saved.has("mode") and saved.version==2,"snapshot stores joint coordinates only")
	expect(rail.validate(saved).is_empty(),"home snapshot validates: "+str(rail.validate(saved)))
	var legacy_save={"version":1,"assembly":"left_leg","receiver":"pelvis","slot":"left_leg","lane":"left","index_x":14.0,"path":0.0,"roll":0.0,"roll_height":0.0,"bolster":0.0,"release":0.0,"engaged":true,"mode":"","goal":0.0,"moving":false}
	expect(not rail.validate(legacy_save).is_empty(),"path/goal saves are rejected, not migrated")
	var away=saved.duplicate();away.travel_z=20.0
	expect(not rail.validate(away).is_empty(),"a leg off the table away from its hip track is rejected")
	var tilted=saved.duplicate();tilted.tilt_deg=30.0
	expect(not rail.validate(tilted).is_empty(),"tilt away from the turn position is rejected")
	rail.index_x=17.0;rail.bolster=1.0
	var moved: Dictionary=rail.capture()
	rail.apply(saved)
	expect(rail.index_x==saved.index_x and rail.jog.is_empty() and not rail.moving,"apply restores coordinates and resets input")
	rail.apply(moved)
	expect(rail.index_x==17.0 and rail.validate(rail.capture()).is_empty(),"a released jog between tracks round-trips")
	var passed=checks.all(func(c):return c.passed)
	print("LEG_RIG_JOG ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
