extends "res://scripts/equipment.gd"
## One authority for the supported leg: travel, tilt and upward dock into the pelvis.
signal changed
const Layout = preload("res://scripts/leg_bay_layout.gd")
const TITLES = ["Travel to final bay","Tilt upright","Dock upward"]
const RETENTION_BLOCKS_RETURN = "Remove all hip retainers before returning the supported leg."
static var DURATIONS: Array = [12.0,10.0,3.0]
const Sweep = preload("res://scripts/motion_sweep.gd")
const Codec = preload("res://scripts/pose_codec.gd")
var layout: Node3D
var load_body: AnimatableBody3D
var path = 0.0
var goal = 0.0
var moving = false
var blocked_reason = ""
var buttons: Array[Dictionary] = []
var labels: Array[Label3D] = []
var solids: Array[Dictionary] = []
var excluded: Array[RID] = []
var checked_steps = 0

func setup(workshop: Node3D, scene_layout: Node3D) -> void:
	game = workshop;layout = scene_layout;equipment_id = "leg_rail"
	load_body = game.runtime.node("left_leg")
	Sweep.collect_shapes(load_body,load_body.global_transform.affine_inverse(),solids)
	for body in game.runtime.nodes.values():
		if body is CollisionObject3D:excluded.append(body.get_rid())
	excluded.append_array(layout.hardware)
	_pose()
	game.model.changed.connect(_model_changed)
	var rail_data: Dictionary = Layout.layout().rail
	DURATIONS = rail_data.durations
	for point in rail_data.panels:_panel(Vector3(point[0],point[1],point[2]))

func _panel(at: Vector3) -> void:
	var panel = Node3D.new();panel.name = "RailLocalControls";add_child(panel);panel.position = at
	var steel = game.material(Color("263a43"),.4)
	game.box(panel,Vector3(.10,.6,0),Vector3(.14,1.2,1.65),steel,true)
	for index in range(3):
		var action: String = ["advance","stop","return"][index]
		var point = Vector3(-.02,1.20,-.52+index*.52)
		var mat = game.material(Color("d57562") if index == 1 else Color("e8b46b"),.2)
		var button = game.box(panel,point,Vector3(.12,.16,.20),mat)
		buttons.append(control_entry(button,action,["Advance","Stop","Return"][index],.14))
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
	if game.profile.trial == "crane":return "CRANE DELIVERY / Rail stays home\nUse the central crane console. Fit all four flange pairs before stowing the magnetic ends."
	if not blocked_reason.is_empty():return "STOPPED / "+blocked_reason
	if moving:return "MOVING / "+(TITLES[clampi(floori(minf(path,goal)),0,2)] if goal > path else "Return · supported reverse")
	if path >= 2.9999:return "DOCKED / Rail still supports leg\nFit one half from the lift. One half does not secure the hip.\nRemove all retention before Return."
	return "M2 / "+next_action()+"\nE or click · Advance / Stop / Return"

func action_error(action: String) -> String:
	if game.paused:return "Resume the trial before moving equipment."
	if not action in ["advance","stop","return"]:return "Unknown rail command."
	if action == "stop":return "" if moving else "The fixture is stopped."
	if game.profile.trial == "crane":return "The crane example keeps the rail home. Finish the beam connection and stow both cables."
	var held_by: String = game.equipment.busy_reason("rail",equipment_id)
	if not held_by.is_empty():return held_by
	if moving:return "Stop the motion before selecting a different direction."
	if action == "return" and retention_state() != "none":return RETENTION_BLOCKS_RETURN
	if action == "advance" and path >= 2.9999:return "One half does not secure the hip. Holder departure is outside M2."
	if action == "return" and path <= .001:return "The loaded fixture is already home."
	return ""

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():
		if not moving:blocked_reason = error
		_refresh();return error
	if action == "return" and game.model.assemblies.left_leg.parent == "pelvis":
		var previous = load_body.global_transform
		var result: Dictionary = game.model.undo_supported("pelvis","m2_leg_rail")
		if not result.ok:return result.error
		load_body.reparent(game)
		load_body.global_transform = previous
		game.refresh_assembly_collision("pelvis")
		game.refresh_assembly_collision("left_leg")
		_pose()
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
	if game.model.assemblies.left_leg.location == "support:m2_leg_rail":load_body.global_transform = pose.load
	layout.set_pose(pose.load,pose.z,pose.x)
	for member in game.runtime.descendants("left_leg"):
		var body: CollisionObject3D = game.runtime.node(member)
		if body is AnimatableBody3D:PhysicsServer3D.body_set_mode(body.get_rid(),PhysicsServer3D.BODY_MODE_STATIC)
		body.force_update_transform()
		# Scene parenting otherwise defers the PhysicsServer write until the next
		# tick. The rail can move from an input callback, so publish this frozen
		# hierarchy immediately as one supported pose, including foot context.
		PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)

func physics(delta: float) -> void:
	var was_moving = moving
	_advance(delta)
	if was_moving and not moving and blocked_reason.is_empty():path = goal;_pose()
	if was_moving and not moving and path >= 2.9999 and game.model.assemblies.left_leg.parent.is_empty():
		var result: Dictionary = game.model.install_supported("pelvis","left_leg","left_leg","m2_leg_rail")
		assert(result.ok,str(result))
		game.runtime.mount("pelvis","left_leg","left_leg")
		game.refresh_assembly_collision("pelvis")
		_pose()
	if was_moving:changed.emit()

func _advance(delta: float) -> void:
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
	var steps = Sweep.steps(a,b,11,.018)
	var angular = a.basis.get_rotation_quaternion().angle_to(b.basis.get_rotation_quaternion())
	var margin = .002+(11*angular+a.origin.distance_to(b.origin)+absf(to-from)*2)/steps*.5
	# The holder and load remain one supported journey through docking.
	var holder = func(_pose: Transform3D, weight: float) -> Array:
		var sample = rail_pose(lerpf(from,to,weight))
		var result: Array = []
		for piece in layout.motion_geometry(sample.load,sample.z,sample.x):
			result.append({"shape":piece.shape,"world":piece.pose,"margin":.001 if piece.id == "RailWheel" else margin})
		return result
	var groups = [{"shapes":solids,"margin":margin,"error":"Clear the load route ({collider})."},{"shapes_at":holder,"error":"Clear the fixture route ({collider})."}]
	var hit: Dictionary = Sweep.sweep(get_world_3d().direct_space_state,groups,steps,func(weight: float) -> Transform3D:return rail_pose(lerpf(from,to,weight)).load,15,excluded,equipment_id)
	checked_steps += hit.get("index",steps+1)
	return hit.get("error","")

func busy_reason(subject: String) -> String:
	return "Wait for the supported rail motion to stop." if moving and subject in ["left_leg","pelvis"] else ""

func access_error(owner: String) -> String:
	return busy_reason(owner)

func _refresh() -> void:
	for label in labels:label.text = status_text()

func _model_changed() -> void:
	blocked_reason = ""
	_refresh()

func capture() -> Dictionary:
	return {"version":1,"path":path,"goal":goal,"moving":moving,"blocked_reason":blocked_reason,"support":"m2_leg_rail","parent":game.model.assemblies.left_leg.parent,"assisting":game.model.assemblies.left_leg.parent == "pelvis"}

func validate(data: Variant, candidate: AssemblyModel = null, world: Dictionary = {}) -> Array[String]:
	if not (data.get("version") is int or data.get("version") is float) or not data.get("support") is String or not data.get("parent") is String:return ["Invalid M2 rail metadata."]
	if data.version != 1 or data.support != "m2_leg_rail":return ["Unsupported M2 rail state."]
	if not data.get("moving") is bool or not data.get("blocked_reason") is String or not data.get("assisting") is bool:return ["Invalid rail flags."]
	for key in ["path","goal"]:
		if not (data.get(key) is int or data.get(key) is float) or not is_finite(data[key]) or data[key] < 0 or data[key] > 3:return ["Invalid rail progress."]
	if not data.moving and absf(data.path-data.goal) > .0001:return ["Stopped rail has a pending target."]
	if data.moving and (is_equal_approx(data.path,data.goal) or data.goal != floorf(data.goal) or absf(data.path-data.goal)>1.001):return ["Invalid indexed rail motion."]
	var leg: Dictionary = candidate.assemblies.left_leg
	if data.parent != leg.parent or data.assisting != (leg.parent == "pelvis"):return ["Rail assistance disagrees with leg owner."]
	if leg.parent == "pelvis":
		if absf(data.path-3)>0.0001 or data.moving:return ["Mounted leg must remain docked on its rail."]
	elif leg.location != "support:m2_leg_rail":return ["Leg has no authorized rail support."]
	if game.profile.trial == "crane" and (data.path != 0 or data.goal != 0 or data.moving):return ["Crane trial rail must stay home."]
	if world.has("fixtures") and not Codec.to_pose(world.fixtures.left_leg).is_equal_approx(rail_pose(data.path).load):return ["Rail and leg transforms disagree."]
	return []

func apply(data: Dictionary) -> void:
	path = data.path;goal = data.goal;moving = data.moving;blocked_reason = data.blocked_reason
	_pose();_refresh()
