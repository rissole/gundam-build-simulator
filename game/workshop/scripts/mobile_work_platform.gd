extends "res://scripts/equipment.gd"
## Operated scissor lift: one local button, vehicle steering and held height input.
## Shared support carries the operator and cargo through translation and rotation.
const Sweep = preload("res://scripts/motion_sweep.gd")
const Codec = preload("res://scripts/pose_codec.gd")
const Nudge = preload("res://scripts/loose_part_nudge.gd")
const ACCELERATION = 2.4
const BRAKING = 4.0
const TURN_SPEED = PI/3
const TURN_ACCELERATION = PI*4/3
const TURN_BRAKING = PI*2
const SCISSOR_LENGTH = 1.4
const SCISSOR_BASE = .18
var spec: Dictionary
var height = .45
var moving = false
var mode = ""
var speed = 0.0
var turn_speed = 0.0
var blocked_reason = ""
var deck: AnimatableBody3D
var base: StaticBody3D
var gate: CollisionShape3D
var scissors: Array[Dictionary] = []
var label: Label3D
var drive_controls: CanvasLayer
var operate_button: MeshInstance3D

func setup(workshop: Node3D, definition: Dictionary) -> void:
	game = workshop;spec = definition;equipment_id = "mobile_platform"
	height = spec.heights[0];position = AssemblyRuntime.vec(spec.parking)
	var steel = game.material(Color("506971"),.45)
	var yellow = game.material(Color("e8b46b"),.3)
	var dark = game.material(Color("252b30"),.1)
	base = StaticBody3D.new();base.name = "MobilePlatformBase";add_child(base)
	deck = AnimatableBody3D.new();deck.name = "MobilePlatformDeck";deck.sync_to_physics = false;add_child(deck)
	var size = Vector2(spec.deck_size[0],spec.deck_size[1])
	_solid(deck,Vector3(0,-.06,0),Vector3(size.x,.12,size.y),steel)
	# Rear entry, long side rails and a front console make the orientation legible.
	for x in [-size.x/2+.035,size.x/2-.035]:
		for z in [-size.y/2+.035,size.y/2-.035]:_solid(deck,Vector3(x,.52,z),Vector3(.07,1.04,.07),yellow)
		for y in [.53,1.05]:_solid(deck,Vector3(x,y,0),Vector3(.07,.07,size.y-.14),yellow)
	for y in [.53,1.05]:_solid(deck,Vector3(0,y,-size.y/2+.035),Vector3(size.x,.07,.07),yellow)
	gate = _solid(deck,Vector3(0,.6,size.y/2-.035),Vector3(size.x-.14,1.0,.07),yellow)
	# Tapered yellow nose; the rear ends in a boarding ramp inside the footprint.
	_prism(base,[Vector2(-.5,-spec.size[1]/2),Vector2(.5,-spec.size[1]/2),Vector2(spec.size[0]/2,-size.y/2-.2),Vector2(spec.size[0]/2,size.y/2),Vector2(-spec.size[0]/2,size.y/2),Vector2(-spec.size[0]/2,-size.y/2-.2)],.07,.21,yellow)
	for x in [-spec.size[0]/2+.13,spec.size[0]/2-.13]:
		for z in [-.85,.85]:
			var wheel = _solid(base,Vector3(x,.13,z),Vector3(.22,.26,.30),dark)
			var cylinder = CylinderMesh.new();cylinder.top_radius = .13;cylinder.bottom_radius = .13;cylinder.height = .22
			wheel.get_meta("visual").mesh = cylinder;wheel.get_meta("visual").rotation.z = PI/2
	for x in [-.34,.34]:game.box(base,Vector3(x,.23,-spec.size[1]/2+.035),Vector3(.16,.09,.05),game.material(Color("e9ead3")))
	for x in [-.43,.43]:
		for tier in range(2):
			for sign in [-1,1]:
				var bar = _solid(base,Vector3.ZERO,Vector3(.055,.065,SCISSOR_LENGTH),yellow)
				scissors.append({"shape":bar,"visual":bar.get_meta("visual"),"x":x+sign*.035,"tier":tier,"sign":sign})
	# Two triangular sides and their connecting faces form a solid boarding ramp.
	var points = PackedVector3Array()
	for x in [-size.x/2,size.x/2]:
		points.append(Vector3(x,0,size.y/2));points.append(Vector3(x,height,size.y/2));points.append(Vector3(x,0,spec.size[1]/2))
	_convex(base,points,[0,2,1,3,4,5,1,2,4,2,5,4,0,1,3,1,4,3,0,3,2,3,5,2],steel)
	# One deliberately large red physical control. The hover text is simply Operate.
	game.box(deck,Vector3(0,.90,-size.y/2+.12),Vector3(.46,.34,.08),steel)
	operate_button = game.box(deck,Vector3(0,.94,-size.y/2+.18),Vector3(.28,.28,.09),game.material(Color("bd3e32"),.25))
	var cap = CylinderMesh.new();cap.top_radius = .15;cap.bottom_radius = .15;cap.height = .09
	operate_button.mesh = cap;operate_button.rotation.x = PI/2
	operate_button.set_meta("control_bank",deck)
	label = game.sign_panel(deck,"",Vector3(0,1.3,-size.y/2+.12),Vector2(1.0,.26),28,.0015)
	drive_controls = preload("res://scripts/platform_drive_controls.gd").new();add_child(drive_controls);drive_controls.setup(self)
	_make_parking_mark(yellow)
	_pose()

func _solid(parent: CollisionObject3D, at: Vector3, size: Vector3, material: Material) -> CollisionShape3D:
	var visual = game.box(parent,at,size,material)
	var col = CollisionShape3D.new();col.position = at;var shape = BoxShape3D.new();shape.size = size;col.shape = shape
	parent.add_child(col);col.set_meta("visual",visual);return col

func _convex(parent: CollisionObject3D, points: PackedVector3Array, indices: Array, material: Material) -> void:
	var collision = CollisionShape3D.new();var shape = ConvexPolygonShape3D.new();shape.points = points;collision.shape = shape;parent.add_child(collision)
	var surface = SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in indices:surface.add_vertex(points[i])
	surface.generate_normals();var visual = MeshInstance3D.new();visual.mesh = surface.commit();visual.material_override = material;parent.add_child(visual)

func _prism(parent: CollisionObject3D, outline: Array, low: float, high: float, material: Material) -> void:
	var points = PackedVector3Array();var indices: Array = [];var count = outline.size()
	for y in [low,high]:
		for p in outline:points.append(Vector3(p.x,y,p.y))
	for i in range(1,count-1):indices.append_array([0,i,i+1,count,count+i+1,count+i])
	for i in count:
		var next = (i+1)%count;indices.append_array([i,count+i,next,next,count+i,count+next])
	_convex(parent,points,indices,material)

func _make_parking_mark(material: Material) -> void:
	var mark = Node3D.new();mark.name = "PlatformParking";add_child(mark);mark.top_level = true;mark.global_position = position
	var half = Vector2(spec.size[0]/2+.25,spec.size[1]/2+.25)
	for x in [-half.x,half.x]:game.box(mark,Vector3(x,.006,0),Vector3(.035,.008,half.y*2),material)
	for z in [-half.y,half.y]:game.box(mark,Vector3(0,.006,z),Vector3(half.x*2,.008,.035),material)
	var title = game.sign_panel(mark,"FRONT ↑",Vector3(0,.018,-half.y-.2),Vector2(1,.24),40,.002);title.get_parent().rotation.x = -PI/2
	title = game.sign_panel(mark,"PLATFORM PARKING",Vector3(0,.018,half.y+.2),Vector2(2.4,.3),40,.002);title.get_parent().rotation.x = -PI/2

func controls() -> Array[Dictionary]:
	return [control_entry(operate_button,"operate","Operate",.18,{"point":operate_button.global_position,"allowed":[deck],"success_toast":false})]

func operate_access_error() -> String:
	if rider() == null:return "Step onto the platform to operate it."
	if game.camera.global_position.distance_to(operate_button.global_position)>game.REACH:return "Move within reach of the platform control."
	if not game._visible(operate_button.global_position,[deck]):return "The platform control is obstructed."
	return ""

func hardware() -> Array[RID]:
	var result: Array[RID] = [];Sweep.collect_rids(self,result);return result
func carries(body: CollisionObject3D) -> bool:return body == deck
func cargo_decks() -> Array[Dictionary]:
	return [{"body":deck,"bounds":AABB(Vector3(-spec.deck_size[0]/2,-.01,-spec.deck_size[1]/2),Vector3(spec.deck_size[0],.06,spec.deck_size[1]))}]
func action_error(action: String) -> String:
	if game.paused:return "Resume the workshop before operating the work platform."
	return operate_access_error() if action=="operate" else "Unknown work platform control."
func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():return error
	return drive_controls.open()

## Halt is also used on operation exit, pause and collision: no stored momentum.
func halt() -> void:
	speed = 0;turn_speed = 0;moving = false;mode = ""
	blocked_reason = "";motion_obstruction = {};_pose()

func ground_drive_error() -> String:
	if height>spec.heights[0]+.001:return "Lower the platform before driving."
	var rail = game.equipment.get_equipment("leg_rail")
	if rail!=null:
		var reason: String = rail.busy_reason("mobile_platform")
		if not reason.is_empty():return reason
	return game.equipment.travel_error(equipment_id,0,0)

## x steers right/left; y drives back/forward, always in the vehicle's frame.
## Turning in place is intentional for positioning in the workshop's tight bays.
func drive(input: Vector2, delta: float) -> void:
	motion_obstruction = {};blocked_reason = ""
	if game.paused:halt();return
	var dt = clampf(delta,0,.05)
	speed = move_toward(speed,clampf(-input.y,-1,1)*spec.speed,(BRAKING if is_zero_approx(input.y) else ACCELERATION)*dt)
	turn_speed = move_toward(turn_speed,clampf(-input.x,-1,1)*TURN_SPEED,(TURN_BRAKING if is_zero_approx(input.x) else TURN_ACCELERATION)*dt)
	moving = not is_zero_approx(speed) or not is_zero_approx(turn_speed);mode = "drive" if moving else ""
	if not moving:_pose();return
	blocked_reason = ground_drive_error()
	if not blocked_reason.is_empty():_blocked();return
	var from = global_transform
	var destination = from
	destination.basis = (Basis(Vector3.UP,turn_speed*dt)*from.basis).orthonormalized()
	destination.origin += -(from.basis.z+destination.basis.z).normalized()*speed*dt
	var shapes: Array[Dictionary] = []
	Sweep.collect_shapes(self,from.affine_inverse(),shapes)
	for body in passengers():Sweep.collect_shapes(body,from.affine_inverse(),shapes)
	var hit = Nudge.move(self,shapes,destination,without_passengers(hardware()))
	blocked_reason = hit.get("error","")
	if hit.is_empty():global_transform = destination
	else:speed = 0;turn_speed = 0;moving = false
	_pose()

func _blocked() -> void:
	speed = 0;turn_speed = 0;moving = false;_pose()

## Only the held input moves the deck; releasing holds any intermediate height.
func lift(direction: float, delta: float) -> void:
	speed = 0;turn_speed = 0;moving = false;mode = "";motion_obstruction = {};blocked_reason = ""
	if game.paused or is_zero_approx(direction):_pose();return
	var next = clampf(height+clampf(direction,-1,1)*spec.lift_speed*clampf(delta,0,.05),spec.heights[0],spec.heights[-1])
	if is_equal_approx(next,height):_pose();return
	blocked_reason = _height_error(next)
	if not blocked_reason.is_empty():_pose();return
	height = next;moving = true;mode = "height";_pose()

func physics(delta: float) -> void:
	if drive_controls.is_open:drive_controls.physics(delta)

func _scissor_pose(entry: Dictionary, value: float) -> Transform3D:
	var rise = (value-.12-SCISSOR_BASE)/2
	var span = sqrt(maxf(.001,SCISSOR_LENGTH*SCISSOR_LENGTH-rise*rise))
	var angle = -float(entry.sign)*atan2(rise,span)
	return Transform3D(Basis(Vector3.RIGHT,angle),Vector3(entry.x,SCISSOR_BASE+(entry.tier+.5)*rise,0))

func _height_error(next: float) -> String:
	var interlock: String = game.equipment.travel_error(equipment_id,height,next)
	if not interlock.is_empty():return interlock
	var shapes: Array[Dictionary] = [];var inverse = global_transform.affine_inverse()
	Sweep.collect_shapes(deck,inverse,shapes)
	for body in passengers():Sweep.collect_shapes(body,inverse,shapes)
	var groups = [{"shapes":shapes,"linear":true,"margin":-.002,"frame":func(pose):return pose},
		{"shapes_at":func(_pose,p):
			var bars: Array = []
			for entry in scissors:bars.append({"shape":entry.shape.shape,"world":global_transform*_scissor_pose(entry,lerpf(height,next,p))})
			return bars,"margin":-.002}]
	var destination = global_transform.translated(Vector3.UP*(next-height))
	return EquipmentRegistry.Motion.sweep(self,groups,2,func(p):return global_transform.interpolate_with(destination,p),without_passengers(hardware())).get("error","")

func _pose() -> void:
	deck.position.y = height
	gate.disabled = not moving and not drive_controls.is_open and is_equal_approx(height,spec.heights[0]);gate.get_meta("visual").visible = not gate.disabled
	for entry in scissors:
		var pose = _scissor_pose(entry,height);entry.shape.transform = pose;entry.visual.transform = pose
	base.force_update_transform();PhysicsServer3D.body_set_state(base.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,base.global_transform)
	label.text = status_text()

func status_text() -> String:
	if not blocked_reason.is_empty():return "Platform waiting\n"+blocked_reason
	if drive_controls.is_open:return "W/S drive · A/D steer\nSpace ↑ · Ctrl ↓ · E leave"
	return "Platform · %.2f m"%height+("\nParking bay" if parked() else "\nOperate")

func parked() -> bool:
	# Fit the actual rotated footprint inside the marked berth, including the ramp.
	var size = Vector3(spec.size[0],.1,spec.size[1])
	var bounds: AABB = transform*AABB(-size/2,size)
	var centre = AssemblyRuntime.vec(spec.parking)
	return bounds.position.x>=centre.x-size.x/2-.25 and bounds.end.x<=centre.x+size.x/2+.25 and bounds.position.z>=centre.z-size.z/2-.25 and bounds.end.z<=centre.z+size.z/2+.25 and is_equal_approx(height,spec.heights[0])
func busy_reason(subject: String) -> String:
	if subject in ["source_roll","arm_upend","bulky_tilt"] and (not parked() or moving):return "Return the movable work platform to parking first."
	return ""
func capture() -> Dictionary:
	return {"version":3,"position":Codec.vector(position),"yaw":rotation.y,"height":height}
func validate(data: Variant, _candidate: AssemblyModel = null, _world: Dictionary = {}) -> Array[String]:
	if not Codec.same_keys(data,["version","position","yaw","height"]) or data.version!=3:return ["Invalid mobile platform snapshot."]
	if not Codec.valid_vector(data.position) or not is_zero_approx(data.position[1]) or not Codec.number(data.yaw):return ["Invalid work platform pose."]
	if not Codec.number(data.height) or data.height<spec.heights[0] or data.height>spec.heights[-1]:return ["Work platform height exceeds its limits."]
	return []
func apply(data: Dictionary) -> void:
	if not validate(data).is_empty():return
	drive_controls.shut();halt();position = Codec.to_vector(data.position);rotation.y = data.yaw;height = data.height;_pose()
