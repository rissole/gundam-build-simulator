extends Node3D
## One authority for the disclosed M1 load. No manual, rigging or persistence flow.
const Layout = preload("res://scripts/m1_layout.gd")
const TITLES = ["Travel to final bay","Tilt upright","Dock upward"]
const RETENTION_REQUIRED = "Secure the hip retainers before releasing the holder."
const RETENTION_BLOCKS_RETURN = "Remove all hip retainers before returning the supported leg."
const RELEASE_OUTSIDE_M1 = "Hip retention is complete. Holder release is outside this M1 trial."
const OWNERSHIP_OUTSIDE_M1 = "Pelvis-mounted leg handling is outside this M1 trial."
const DURATIONS = [12.0,10.0,3.0]
var game: Node3D
var layout: Node3D
var load_body: AnimatableBody3D
var path = 0.0
var goal = 0.0
var moving = false
var blocked_reason = ""
var buttons: Array[Dictionary] = []
var labels: Array[Label3D] = []
var solids: Array[Dictionary] = []
var mesh_bounds: Array[Dictionary] = []
var excluded: Array[RID] = []
var checked_steps = 0

func setup(workshop: Node3D, scene_layout: Node3D) -> void:
	game = workshop;layout = scene_layout
	preload("res://scripts/m1_staging.gd").prepare(game)
	load_body = game.runtime.node("left_leg")
	_collect(load_body,load_body.global_transform.affine_inverse())
	for body in game.runtime.nodes.values():
		if body is CollisionObject3D:excluded.append(body.get_rid())
	excluded.append_array(layout.hardware)
	_pose()
	game.model.changed.connect(_model_changed)
	for at in [Vector3(9.2,0,11.4),Vector3(5.1,0,24.2)]:_panel(at)
	var lift = preload("res://scripts/work_access_lift.gd").new()
	game.add_child(lift)
	var levels: Array[float] = [.15,8.4]
	lift.setup(game,"hip",Layout.LIFT_ORIGIN,Vector2(2.6,2.6),levels)
	lift.name = "M1HipLift"
	lift.rotation.y = PI
	game.access_lifts.hip = lift
	game.player.position = Vector3(8.3,.03,10.5)
	game.player.rotation.y = -PI/2

func _collect(node: Node, inverse: Transform3D) -> void:
	if node is MeshInstance3D and node.mesh != null:
		mesh_bounds.append({"node":node,"pose":inverse*node.global_transform,"bounds":node.mesh.get_aabb()})
	if node is CollisionShape3D and not node.disabled:
		var shape: Shape3D = node.shape
		var pose = inverse*node.global_transform
		if shape is ConcavePolygonShape3D:
			var bounds = shape.get_debug_mesh().get_aabb()
			shape = BoxShape3D.new();shape.size = bounds.size.max(Vector3.ONE*.004)
			pose *= Transform3D(Basis.IDENTITY,bounds.get_center())
		solids.append({"shape":shape,"pose":pose})
	for child in node.get_children():_collect(child,inverse)

func _panel(at: Vector3) -> void:
	var panel = Node3D.new();panel.name = "M1LocalControls";add_child(panel);panel.position = at
	var steel = game.material(Color("263a43"),.4)
	game.box(panel,Vector3(.10,.6,0),Vector3(.14,1.2,1.65),steel,true)
	for index in range(3):
		var action: String = ["advance","stop","return"][index]
		var point = Vector3(-.02,1.20,-.52+index*.52)
		var mat = game.material(Color("d57562") if index == 1 else Color("e8b46b"),.2)
		var button = game.box(panel,point,Vector3(.12,.16,.20),mat)
		buttons.append({"type":"equipment","controller":self,"node":button,"action":action,"label":["Advance","Stop","Return"][index],"radius":.14})
		game.sign_panel(panel,["ADVANCE","STOP","RETURN"][index],point+Vector3(-.06,-.20,0),Vector2(.45,.13),32,.0018,-PI/2)
	var label = game.sign_panel(panel,"",Vector3(-.04,2.0,0),Vector2(2.4,.8),32,.002,-PI/2)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.width = 1100
	labels.append(label)
	_refresh()

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for button in buttons:
		var entry = button.duplicate();entry.point = entry.node.global_position
		if entry.action == "advance":entry.label = "Advance / "+next_action()
		result.append(entry)
	return result

func next_action() -> String:
	return TITLES[clampi(floori(path+.0001),0,2)] if path < 2.9999 else "Docked / holder supporting leg"

func retention_state() -> String:
	# The seat is positioning, not retention. Derive both halves and every
	# washer/bolt from the authored secure milestone, rather than a first-bolt flag.
	var slots: Dictionary = game.model.assemblies.pelvis.slots
	var required: Array = game.runtime.definition("pelvis").milestones.left_leg_secured.filter(func(sid):return sid != "left_leg")
	if not required.any(func(sid):return not slots[sid].is_empty()):return "none"
	var leg: Dictionary = game.model.assemblies.left_leg
	if required.all(func(sid):return not slots[sid].is_empty()) and slots.left_leg == "left_leg" and leg.parent == "pelvis" and leg.parent_slot == "left_leg" and game.model.milestone("pelvis","left_leg_secured"):return "complete"
	return "partial"

func status_text() -> String:
	if not blocked_reason.is_empty():return "STOPPED / "+blocked_reason
	if moving:return "MOVING / "+(TITLES[clampi(floori(minf(path,goal)),0,2)] if goal > path else "Return · supported reverse")
	if path >= 2.9999:
		var guidance = "M1 ends at docking · Return lowers the supported leg."
		if retention_state() != "none":guidance = RETENTION_BLOCKS_RETURN
		return "DOCKED / Holder supporting leg\n"+action_error("advance")+"\n"+guidance
	return "M1 SAMPLE / "+next_action()+"\nE or click · one motion at a time"

func action_error(action: String) -> String:
	if game.paused:return "Resume the trial before moving equipment."
	if not action in ["advance","stop","return"]:return "Unknown sample control."
	if action == "stop":return "" if moving else "The fixture is stopped."
	if moving:return "Stop the motion before selecting a different direction."
	if action == "return" and retention_state() != "none":return RETENTION_BLOCKS_RETURN
	if action == "advance" and path >= 2.9999:
		return RELEASE_OUTSIDE_M1 if retention_state() == "complete" else RETENTION_REQUIRED
	# Normal M1 never mounts into pelvis: preserve a real externally mounted child
	# rather than changing its world pose under a second equipment authority.
	if game.model.assemblies.left_leg.location != "support:m1_leg_rail":return OWNERSHIP_OUTSIDE_M1
	if action == "return" and path <= .001:return "The loaded fixture is already home."
	return ""

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():
		if not moving:blocked_reason = error
		_refresh()
		return error
	if action == "stop":
		moving = false;goal = path;blocked_reason = "";_refresh();return ""
	goal = minf(3, floorf(path+.0001)+1) if action == "advance" else maxf(0,ceilf(path-.0001)-1)
	moving = true;blocked_reason = "";_refresh()
	return ""

static func rail_pose(t: float) -> Dictionary:
	var p = clampf(t,0,3)
	var z = Layout.HOME_Z
	var x = Layout.RAIL_X
	var theta = PI/2
	var dock = 0.0
	if p <= 1:z = lerpf(Layout.HOME_Z,Layout.BAY_Z,p)
	elif p <= 2:z = Layout.BAY_Z;theta = (2-p)*PI/2
	elif p <= 3:z = Layout.BAY_Z;theta = 0;dock = (p-2)*.9
	var basis = Basis(Vector3.RIGHT,theta)
	var origin = Vector3(x,.5+.85*sin(theta)+dock,z-5.1*sin(theta))
	return {"load":Transform3D(basis,origin),"z":z,"x":x}

func _pose() -> void:
	var pose = rail_pose(path)
	if game.model.assemblies.left_leg.location == "support:m1_leg_rail":load_body.global_transform = pose.load
	layout.set_pose(pose.load,pose.z,pose.x)
	for member in game.runtime.descendants("left_leg"):
		var body: CollisionObject3D = game.runtime.node(member)
		body.force_update_transform()
		# Scene parenting otherwise defers the PhysicsServer write until the next
		# tick. M1 can move from an input callback, so publish this frozen hierarchy
		# immediately as one supported pose, including foot context and rigid children.
		PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)

func physics(delta: float) -> void:
	if not moving or game.paused:return
	var index = clampi(floori(minf(path,goal)),0,2)
	var next = move_toward(path,goal,delta/float(DURATIONS[index]))
	blocked_reason = motion_error(path,next)
	if not blocked_reason.is_empty():moving = false;goal = path;_refresh();return
	path = next
	_pose()
	if is_equal_approx(path,goal):
		moving = false
	_refresh()

func motion_error(from: float, to: float) -> String:
	# Tiny travel samples plus conservative angular margins cover motion between
	# physics ticks. Tests additionally sample every actual mesh, including context.
	var a: Transform3D = rail_pose(from).load
	var b: Transform3D = rail_pose(to).load
	var steps = SolidHandling.sweep_steps(a,b,11,.018)
	var space = get_world_3d().direct_space_state
	var angular = a.basis.get_rotation_quaternion().angle_to(b.basis.get_rotation_quaternion())
	var margin = .002+(11*angular+a.origin.distance_to(b.origin)+absf(to-from)*2)/steps*.5
	for index in range(steps+1):
		var t = lerpf(from,to,float(index)/steps)
		var sample = rail_pose(t)
		var pose: Transform3D = sample.load
		for solid in solids:
			var query = PhysicsShapeQueryParameters3D.new()
			query.shape = solid.shape;query.transform = pose*solid.pose
			query.margin = margin
			query.collision_mask = 15;query.exclude = excluded
			var hits = space.intersect_shape(query,1)
			if not hits.is_empty():return "Clear the load route ("+str(hits[0].collider.name)+")."
		# The holder and load remain one supported journey through docking.
		for piece in layout.motion_geometry(pose,sample.z,sample.x):
			var query = PhysicsShapeQueryParameters3D.new()
			query.shape = piece.shape;query.transform = piece.pose
			query.margin = .001 if piece.id == "RailWheel" else margin;query.collision_mask = 15;query.exclude = excluded
			var hits = space.intersect_shape(query,1)
			if not hits.is_empty():return "Clear the fixture route ("+str(hits[0].collider.name)+")."
		checked_steps += 1
	return ""

func _refresh() -> void:
	for label in labels:label.text = status_text()

func _model_changed() -> void:
	blocked_reason = ""
	_refresh()
