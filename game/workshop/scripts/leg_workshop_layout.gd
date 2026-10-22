class_name LegWorkshopLayout
extends Node3D
## Metre-scale workshop layout. Equipment and workpiece motion remain separate.
const ROOM_MIN = Vector3(-13.8, 0, -8.5)
const ROOM_MAX = Vector3(25.8, 22, 38.5)
const LEG_ORIGIN = Vector3(2.3, 0.75, 14.4)
const PELVIS_ORIGIN = Vector3(13, 10.6, 26)
const HIP_OFFSET = Vector3(-1.1, 0, 0)
const LEG_LIFT_ORIGIN = Vector3(4.8, 0, 14.0)
const KNEE_LIFT_ORIGIN = Vector3(-0.2, 0, 14.0)
const HIP_LIFT_ORIGIN = Vector3(11.9, 0, 28.5)
const HOIST_HEIGHT = 19.4
# Independent service crane covers racks and foot pickup without moving the
# main leg hoist. Its end columns stay outside the reserved future floor area.
const SERVICE_MIN_X = -5.5
const SERVICE_MAX_X = 24.8
const SERVICE_MIN_Z = 2.5
const SERVICE_MAX_Z = 37.5
const SERVICE_BRIDGE_Y = 21.0
const SERVICE_CABLE_Y = 20.6

var game: Node3D
var gantry: Node3D
var leg_fixture: Node3D
var hoist: Node3D
var crane_trolley: Node3D
var hook: Node3D
var cable: MeshInstance3D
var clamp: Node3D
var service_bridge: AnimatableBody3D
var service_trolley: Node3D
var fixture_contacts: Array[Dictionary] = []
var foot_cradle_contacts: Array[Dictionary] = []
var foot_cradle_posts: Array[Dictionary] = []
var _steel: Material
var _dark: Material
var _yellow: Material

func setup(workshop: Node3D) -> void:
	game = workshop
	_steel = game.material(Color("506971"), 0.55)
	_dark = game.material(Color("263a43"), 0.4)
	_yellow = game.material(Color("e8b46b"), 0.25)
	_make_shell()
	_make_leg_fixture()
	_make_gantry()
	_make_crane()
	_make_service_crane()
	_make_routes()
	set_hoist(LEG_ORIGIN + Vector3(0, 8.2, 0), false)

func _box(parent: Node3D, label: String, at: Vector3, size: Vector3, mat: Material, solid: bool = true) -> MeshInstance3D:
	var mesh: MeshInstance3D = game.box(parent, at, size, mat, solid)
	mesh.name = label
	mesh.set_meta("equipment_piece",label)
	if solid:
		var body = parent.get_child(parent.get_child_count()-1)
		if body is CollisionObject3D:
			body.name = label+"Collision"
			body.set_meta("equipment_piece",label)
	return mesh

func _make_shell() -> void:
	var floor_mat: Material = game.material(Color("7c8886"))
	var wall_mat: Material = game.material(Color("abb9b6"))
	var center = (ROOM_MIN + ROOM_MAX) * 0.5
	var size = ROOM_MAX - ROOM_MIN
	_box(self, "HangarFloor", Vector3(center.x,-0.15,center.z), Vector3(size.x,0.3,size.z), floor_mat)
	_box(self, "NorthWall", Vector3(center.x,11,ROOM_MIN.z-0.15), Vector3(size.x,22,0.3), wall_mat)
	_box(self, "SouthWall", Vector3(center.x,11,ROOM_MAX.z+0.15), Vector3(size.x,22,0.3), wall_mat)
	for x in [ROOM_MIN.x-0.15,ROOM_MAX.x+0.15]:
		_box(self, "SideWall", Vector3(x,11,center.z), Vector3(0.3,22,size.z+0.6), wall_mat)
	_box(self,"Roof",Vector3(center.x,22.15,center.z),Vector3(size.x+0.6,0.3,size.z+0.6),_dark)
	for z in [-6.8,2.0,10.0,18.0,26.0,34.0]:
		for x in [ROOM_MIN.x+0.25,ROOM_MAX.x-0.25]:
			_box(self,"WallColumn",Vector3(x,10.5,z),Vector3(0.3,21,0.4),_steel)
		_box(self,"RoofTruss",Vector3(center.x,21.5,z),Vector3(size.x-0.8,0.45,0.3),_steel)
		for x in [-6.0,6.0,18.0]:
			_box(self,"LightStrip",Vector3(x,21.22,z),Vector3(6.0,0.08,0.22),game.material(Color("fff3db"),0,true),false)
			var fill = OmniLight3D.new()
			fill.position = Vector3(x,8.5,z)
			fill.light_color = Color("e1ebec")
			fill.light_energy = 0.7
			fill.omni_range = 12.0
			add_child(fill)
	# A grid provides scale without making transfer corridors into physical rails.
	var grid: Material = game.material(Color("697d79"))
	for x in range(-12,25,4):
		_box(self,"FloorGrid",Vector3(x,0.002,15),Vector3(0.018,0.004,44),grid,false)
	for z in range(-6,38,4):
		for x in range(-12,24,4):
			_box(self,"FloorGrid",Vector3(x+2,0.002,z),Vector3(3.982,0.004,0.018),grid,false)
	game.sign_panel(self,"01 / COMPONENT WORKSHOP",Vector3(-1,5,-8.15),Vector2(10,0.9),110,0.004)
	game.sign_panel(self,"02 / LEG ASSEMBLY",Vector3(-4.3,4.1,16.5),Vector2(4.4,0.65),90,0.003)
	game.sign_panel(self,"03 / FINAL ASSEMBLY",Vector3(13,17,29.0),Vector2(9,1.2),130,0.005)
	game.sign_panel(self,"TORSO / SECOND LEG\nFUTURE WORK AREA",Vector3(21,2.1,35.8),Vector2(4.8,1.1),65,0.003)

func _make_leg_fixture() -> void:
	leg_fixture = Node3D.new()
	leg_fixture.name = "LegAssemblyFixture"
	add_child(leg_fixture)
	leg_fixture.position = LEG_ORIGIN
	# Rear spine and two located yokes leave the ankle flange and knee axle open.
	_box(leg_fixture,"Foundation",Vector3(0,-0.60,1.35),Vector3(2.8,0.30,1.2),_dark)
	for x in [-1.25,1.25]:
		_box(leg_fixture,"FixturePost",Vector3(x,4.0,1.35),Vector3(0.18,9.2,0.20),_steel)
	for y in [2.8,7.0]:
		_box(leg_fixture,"SupportCrossbar",Vector3(0,y,1.35),Vector3(2.5,0.20,0.20),_steel)
		for x in [-0.42,0.42]:
			_box(leg_fixture,"SaddleArm",Vector3(x,y,0.75),Vector3(0.14,0.18,1.0),_steel)
			var side = signf(x)
			_box(leg_fixture,"JawGuide",Vector3(side*0.35,y,0.25),Vector3(0.56,0.18,0.12),_steel)
			_fixture_contact("LocatedJaw",Vector3(side*0.21,y,0),Vector3(0.12,0.32,0.20),_yellow,side)
			_fixture_contact("JawLink",Vector3(side*0.21,y,0.14),Vector3(0.12,0.14,0.24),_steel,side)
	_box(leg_fixture,"UpperBrace",Vector3(0,8.7,1.35),Vector3(2.5,0.18,0.20),_steel)
	# Ground-supported bearing pads meet the prepared foot's actual heel soles.
	# The hydraulic columns telescope down before the .5 m sole-height transfer.
	for x in [-0.32,0.32]:
		_box(leg_fixture,"FootCradleBase",Vector3(x,-0.69,0.43),Vector3(0.56,0.12,0.65),_dark)
		var post = _box(leg_fixture,"FootCradleColumn",Vector3(x,-0.365,0.43),Vector3(0.16,0.53,0.16),_steel)
		var post_body: CollisionObject3D = leg_fixture.get_child(leg_fixture.get_child_count()-1)
		foot_cradle_posts.append({"visual":post,"body":post_body,"closed":post.position,"open":Vector3(x,-0.615,0.43),"closed_height":0.53,"open_height":0.03})
		var pad = _box(leg_fixture,"FootCradlePad",Vector3(x,-0.05,0.43),Vector3(0.50,0.10,0.55),_yellow)
		var pad_body: CollisionObject3D = leg_fixture.get_child(leg_fixture.get_child_count()-1)
		pad_body.set_meta("support_contact",true)
		foot_cradle_contacts.append({"visual":pad,"body":pad_body,"closed":pad.position,"open":pad.position+Vector3.DOWN*0.5})

func _fixture_contact(label: String, at: Vector3, size: Vector3, mat: Material, side: float) -> void:
	var visual = _box(leg_fixture,label,at,size,mat)
	var body: CollisionObject3D = leg_fixture.get_child(leg_fixture.get_child_count()-1)
	body.set_meta("support_contact",true)
	body.set_meta("fixture_jaw",label == "LocatedJaw")
	fixture_contacts.append({"visual":visual,"body":body,"closed":at,"open":at+Vector3(side*0.28,0,0)})

func set_fixture_engaged(engaged: bool) -> void:
	leg_fixture.set_meta("engaged",engaged)
	for contact in fixture_contacts:
		var at: Vector3 = contact.closed if engaged else contact.open
		contact.visual.position = at
		contact.body.position = at
		contact.body.collision_layer = 1 if engaged else 0
	for contact in foot_cradle_contacts:
		var at: Vector3 = contact.closed if engaged else contact.open
		contact.visual.position = at
		contact.body.position = at
		contact.body.collision_layer = 1 if engaged else 0
	for post in foot_cradle_posts:
		var at: Vector3 = post.closed if engaged else post.open
		var height: float = post.closed_height if engaged else post.open_height
		post.visual.position = at
		post.body.position = at
		post.visual.mesh.size.y = height
		post.body.get_child(0).shape.size.y = height

func _make_gantry() -> void:
	gantry = Node3D.new()
	gantry.name = "RobotSupportGantry"
	add_child(gantry)
	gantry.position = Vector3(PELVIS_ORIGIN.x,0,PELVIS_ORIGIN.z)
	# Both columns remain behind the robot and clear of the leg approach lane.
	for x in [-4.0,4.0]:
		_box(gantry,"GantryFoot",Vector3(x,0.18,1.7),Vector3(1.9,0.36,3.0),_dark)
		_box(gantry,"GantryColumn",Vector3(x,9.9,1.7),Vector3(0.45,19.44,0.55),_steel)
	_box(gantry,"GantryHead",Vector3(0,19.7,1.7),Vector3(8.45,0.5,0.55),_steel)
	clamp = Node3D.new()
	clamp.name = "PelvisClampCarriage"
	gantry.add_child(clamp)
	clamp.position.y = PELVIS_ORIGIN.y
	_box(clamp,"PelvisCrosshead",Vector3(0,0.25,1.7),Vector3(7.9,0.5,0.65),_dark)
	for x in [-0.75,0.75]:
		_box(clamp,"PelvisSupportArm",Vector3(x,0.21,0.95),Vector3(0.24,0.32,0.90),_steel)
		_box(clamp,"PelvisClampJaw",Vector3(x,0.25,0.40),Vector3(0.32,0.48,0.20),_yellow)
	# This brace stabilizes a retained but unpowered spherical hip. It is equipment.
	var brace = Node3D.new()
	brace.name = "LegStabilizer"
	gantry.add_child(brace)
	# Route its load path around the personnel platform, back to the left column.
	_box(brace,"StabilizerColumnLink",Vector3(-3.45,7.8,1.7),Vector3(1.1,0.20,0.20),_steel)
	_box(brace,"StabilizerSideArm",Vector3(-2.9,7.8,1.05),Vector3(0.20,0.20,1.10),_steel)
	_box(brace,"StabilizerCrossArm",Vector3(-1.9,7.8,0.40),Vector3(2.2,0.20,0.20),_steel)
	for x in [-1.30,-0.90]:
		_box(brace,"StabilizerJawLink",Vector3(x,7.8,0.20),Vector3(0.10,0.14,0.20),_steel)
		_box(brace,"StabilizerJaw",Vector3(x,7.8,0),Vector3(0.10,0.34,0.20),_yellow)

func _make_crane() -> void:
	hoist = Node3D.new()
	hoist.name = "LegTransferHoist"
	add_child(hoist)
	# Rail supports stand outside the load corridor and the operating platforms.
	for x in [-0.4,17.2]:
		for z in [8.5,33.0]:
			_box(hoist,"CraneColumn",Vector3(x,10.0,z),Vector3(0.32,20,0.32),_steel)
		# Cantilever over the component-bay dispatch point for supported foot pickup.
		_box(hoist,"CraneRunway",Vector3(x,20.2,18.0),Vector3(0.34,0.4,30.0),_yellow)
	crane_trolley = Node3D.new()
	crane_trolley.name = "TravellingBridge"
	hoist.add_child(crane_trolley)
	_box(crane_trolley,"BridgeBeam",Vector3(8.4,HOIST_HEIGHT+0.4,0),Vector3(17.92,0.40,0.35),_yellow)
	hook = Node3D.new()
	hook.name = "LiftingYoke"
	hoist.add_child(hook)
	_box(hook,"Yoke",Vector3.ZERO,Vector3(1.2,0.14,0.14),_yellow,false)
	for x in [-0.48,0.48]:
		_box(hook,"LiftSideLink",Vector3(x,-0.55,0),Vector3(0.10,1.1,0.18),_steel,false)
		# With the yoke at the 9.65 m crown, these pads grip the 300 mm neck.
		_box(hook,"LiftJaw",Vector3(signf(x)*0.325,-1.10,0),Vector3(0.35,0.14,0.24),_yellow,false)
	cable = MeshInstance3D.new()
	cable.name = "HoistCable"
	var rope = CylinderMesh.new()
	rope.top_radius = 0.035
	rope.bottom_radius = 0.035
	rope.height = 1.0
	rope.radial_segments = 8
	cable.mesh = rope
	cable.material_override = _dark
	hoist.add_child(cable)

func set_hoist(load_point: Vector3, engaged: bool) -> void:
	crane_trolley.position.z = load_point.z
	hook.position = load_point if engaged else load_point + Vector3.UP * 0.5
	var length = maxf(0.1, HOIST_HEIGHT-hook.position.y)
	cable.position = Vector3(load_point.x,hook.position.y+length*0.5,load_point.z)
	cable.scale = Vector3(1,length,1)
	hook.set_meta("engaged",engaged)

func _make_service_crane() -> void:
	var structure = Node3D.new()
	structure.name = "ServiceCrane"
	add_child(structure)
	var depth = SERVICE_MAX_Z-SERVICE_MIN_Z
	for x in [SERVICE_MIN_X,SERVICE_MAX_X]:
		for z in [SERVICE_MIN_Z,SERVICE_MAX_Z]:
			_box(structure,"ServiceCraneFoot",Vector3(x,0.15,z),Vector3(0.65,0.3,0.65),_dark)
			_box(structure,"ServiceCraneColumn",Vector3(x,10.3,z),Vector3(0.25,20.6,0.25),_steel)
		_box(structure,"ServiceRunway",Vector3(x,20.7,(SERVICE_MIN_Z+SERVICE_MAX_Z)*0.5),Vector3(0.30,0.30,depth+0.25),_yellow)
	service_bridge = AnimatableBody3D.new()
	service_bridge.name = "ServiceTravellingBridge"
	service_bridge.sync_to_physics = false
	service_bridge.collision_layer = 1
	service_bridge.collision_mask = 0
	structure.add_child(service_bridge)
	var width = SERVICE_MAX_X-SERVICE_MIN_X
	var center_x = (SERVICE_MAX_X+SERVICE_MIN_X)*0.5
	_moving_box(service_bridge,"ServiceBridgeBeam",Vector3(center_x,SERVICE_BRIDGE_Y,0),Vector3(width+0.30,0.30,0.28),_yellow)
	service_trolley = Node3D.new()
	service_trolley.name = "ServiceHoistTrolley"
	service_bridge.add_child(service_trolley)
	# Its top meets the bridge underside; its lower eye meets the hanging cable.
	_moving_box(service_bridge,"ServiceTrolleyGuide",Vector3(center_x,20.85,0),Vector3(width,0.12,0.42),_steel)
	_box(service_trolley,"ServiceTrolley",Vector3(0,20.75,0),Vector3(0.65,0.30,0.50),_dark,false)
	_box(service_trolley,"ServiceCableEye",Vector3(0,SERVICE_CABLE_Y,0),Vector3(0.12,0.12,0.12),_yellow,false)
	set_service_hoist(Vector3(2.3,3.2,4.4),false)

func _moving_box(body: CollisionObject3D, label: String, at: Vector3, size: Vector3, mat: Material) -> void:
	_box(body,label,at,size,mat,false)
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = at
	body.add_child(collision)

func set_service_hoist(load_point: Vector3, engaged: bool) -> void:
	service_bridge.position.z = load_point.z
	service_trolley.position.x = load_point.x
	service_trolley.set_meta("engaged",engaged)

func _make_routes() -> void:
	# The complete left leg needs more than its beam width: include the 3 m foot.
	for x in [-0.2,4.8]:
		_box(self,"TransferLaneMark",Vector3(x,0.007,8.6),Vector3(0.06,0.008,7.8),_yellow,false)
	for z in [8.0,12.4]:
		_box(self,"TransferLaneMark",Vector3(7.1,0.007,z),Vector3(12.8,0.008,0.06),_yellow,false)
	var reserve: Material = game.material(Color("7e9d98"))
	for x in [18.5,24.0]:
		_box(self,"FutureAreaMark",Vector3(x,0.007,31),Vector3(0.06,0.008,10),reserve,false)
	for z in [26.0,36.0]:
		_box(self,"FutureAreaMark",Vector3(21.25,0.007,z),Vector3(5.5,0.008,0.06),reserve,false)

static func approach_origin() -> Vector3:
	# The ball's crown must pass BELOW the housing skirt before rising inside it.
	# 0.5 + 9.2 + 0.45 = 10.15; skirt underside is 10.6 - 0.35 = 10.25.
	return Vector3(PELVIS_ORIGIN.x + HIP_OFFSET.x, 0.5, PELVIS_ORIGIN.z)

static func seated_origin() -> Vector3:
	return Vector3(PELVIS_ORIGIN.x + HIP_OFFSET.x, PELVIS_ORIGIN.y - 9.2, PELVIS_ORIGIN.z)
