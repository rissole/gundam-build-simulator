extends "res://tests/kit/harness.gd"
## Small real-geometry, physics and desktop-input fixture; no workshop sweep.
class Hud extends Node:
	var caption = ""
	var message = ""
	var quiet_errors = false
	func present_target(text: String, _key = "", _label = "", _point = Vector2.ZERO, _usable = false):caption = text
	func toast(text: String, _good = false):message = text
	func refresh():pass
	func handle_manual_browser_input(_event):return false
class Equipment extends RefCounted:
	var entries: Array[Dictionary] = []
	func controls() -> Array[Dictionary]:return entries
	func obstruction_target():return null
class Shelf extends RefCounted:
	var game: Node
	var uid = "small"
	var cargo: WorkshopPart
	var click_operates = true
	func action_error(_action):return "" if game.model.held_item().is_empty() else "Hands occupied"
	func request(_action):
		var previous: Transform3D = cargo.global_transform
		var error: String = game.model.carry_supported_item(uid,"test_shelf")
		if not error.is_empty():return error
		cargo.free()
		game.components.hold_at(uid,previous)
		game.equipment.entries.clear()
		return ""
	func status_text():return "Shelf component collected"
class Hands extends RefCounted:
	func payload_holder():return null
class Fixture extends Node3D:
	const WORLD_MASK = 3
	const SNAP_DISCOVERY_RANGE = 4.0
	const REACH = 2.0
	const SNAP_DISTANT_COLOR = Color.YELLOW
	const SNAP_READY_COLOR = Color.GREEN
	var model = AssemblyModel.new()
	var runtime: AssemblyRuntime
	var builds: Array = []
	var bodies = {}
	var stations = {}
	var bins = {}
	var loose = {}
	var source = {}
	var target = {}
	var selected_kind = ""
	var journey = null
	var paused = false
	var started = true
	var automated_test = false
	var camera = Camera3D.new()
	var player = CharacterBody3D.new()
	var ghost = MeshInstance3D.new()
	var ghost_material = StandardMaterial3D.new()
	var interaction_outline = preload("res://scripts/interaction_outline.gd").new()
	var hud = Hud.new()
	var equipment = Equipment.new()
	var hands = Hands.new()
	var components: Node
	var targeting: RefCounted
	var input: RefCounted
	func _spawn_loose(uid):
		var result = WorkshopPart.new();result.uid = uid;result.kind = uid;result.freeze = true;result.collision_layer = 2
		add_child(result)
		var visual = MeshInstance3D.new();visual.mesh = source[uid].mesh;result.add_child(visual)
		loose[uid] = result
	func held_build():return ""
	func source_uid(uid):return uid
	func interact(_all = false):components.interact()
	func _update_target():targeting.update_target()
	func _ready():
		for node in [camera,player,ghost,interaction_outline,hud]:add_child(node)
		player.position = Vector3(20,0,0)
		components = preload("res://scripts/component_interaction.gd").new(self);add_child(components)
		targeting = preload("res://scripts/targeting.gd").new(self)
		input = preload("res://scripts/desktop_input.gd").new(self)
## A fresh E press and its release; E acts only on a fresh press.
func press_e(game) -> void:
	for down in [true,false]:
		var event = InputEventKey.new();event.physical_keycode = KEY_E;event.pressed = down;game.input.handle(event)

func _initialize():run.call_deferred()
func body(game: Fixture, uid: String, mesh: Mesh, pose = Transform3D.IDENTITY) -> WorkshopPart:
	var result = WorkshopPart.new();result.uid = uid;result.freeze = true;result.collision_layer = 2
	game.add_child(result);result.global_transform = pose
	var visual = MeshInstance3D.new();visual.mesh = mesh;result.add_child(visual)
	var shape = CollisionShape3D.new();var box = BoxShape3D.new();box.size = mesh.get_aabb().size
	shape.shape = box;shape.position = mesh.get_aabb().get_center();result.add_child(shape)
	game.loose[uid] = result
	return result
func aim(game: Fixture, eye: Vector3, at: Vector3):
	game.camera.global_position = eye;game.camera.look_at(at,Vector3.FORWARD if absf((at-eye).normalized().dot(Vector3.UP)) > .99 else Vector3.UP)
	game.targeting.update_target()
func run():
	var game = Fixture.new();root.add_child(game)
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/leg-prototype-content.json"))
	content.sources.merge(JSON.parse_string(FileAccess.get_file_as_string("res://assets/robot-content.json")).sources)
	var sources = ["PV-120__001","PV-120__002","PV-200__001","PV-200__003"]
	var parts = {};var items = []
	for uid in sources:
		parts[uid] = {"family":uid,"title":uid,"carry_class":"two_hand"};items.append({"instance_id":uid,"kind":uid,"location":"loose"})
	parts.small = {"family":"small","title":"small","carry_class":"hand"};items.append({"instance_id":"small","kind":"small","location":"loose"})
	expect(game.model.configure({"version":1,"parts":parts,"assemblies":{}},{"version":1,"parts":items,"builds":[],"parents":[],"supports":{"test_shelf":{"parts":["small"]}}}).is_empty(),"Pickup fixture configures real item ownership")
	for uid in sources:
		var mesh = LegSourceGeometry.make_mesh(content.sources[uid]);game.source[uid] = {"mesh":mesh}
		# Keep the authored source orientation paired with its geometry, then
		# add a representative dropped rotation and a mirrored instance basis.
		var angles = LegSourceGeometry.vec(content.sources[uid].rotation_degrees)*PI/180.0
		var basis = Basis.from_euler(Vector3(.35,.7,-.2))*Basis.from_euler(angles)
		if uid == "PV-200__003":basis.x *= -1
		var item = body(game,uid,mesh,Transform3D(basis,Vector3.ZERO))
		var local_point = Vector3(0,-.46,0) if uid.begins_with("PV-200") else Vector3(0,0,-.49)
		var at = item.global_transform*local_point
		var eye = at+item.global_basis*(Vector3(0,0,1.0) if uid.begins_with("PV-200") else Vector3(0,1,0))
		await frames(2)
		aim(game,eye,at)
		expect(game.target.get("uid","") == uid and game.interaction_outline.focused == item,"Visible material selects and outlines "+uid+" under source/dropped transforms")
		press_e(game)
		expect(game.model.held_item() == uid and game.components.held_body == item,"Desktop E takes the aimed identity "+uid)
		game.model.release_item("loose");game.components.held_body = null;item.free()
	# A real half-ring's central hole, with its coarse solid-box collider, must
	# leave the ordinary compact object behind it available to the same E path.
	var ring = body(game,sources[0],game.source[sources[0]].mesh)
	var cube_mesh = BoxMesh.new();cube_mesh.size = Vector3(.1,.1,.1)
	game.source.small = {"mesh":cube_mesh}
	var cube = body(game,"small",cube_mesh,Transform3D(Basis.IDENTITY,Vector3(0,-.4,-.12)))
	await frames(2)
	aim(game,Vector3(0,1,-.12),cube.global_position)
	expect(game.target.get("uid","") == "small" and game.interaction_outline.focused == cube,"Empty ring gap does not select its origin or let the coarse collider hide the item behind")
	var query = game.targeting.pickup_surfaces
	var builds: int = query.builds;var collections: int = query.collections
	for frame in 30:game.targeting.update_target()
	expect(query.builds == builds and query.collections == collections,"Warm aim reuses mesh BVHs and hierarchy membership without face or tree scans")
	press_e(game)
	expect(game.model.held_item() == "small","Desktop E through the real hole collects the visible object behind")
	game.model.release_item("loose");game.components.held_body = null;game.loose.small = cube;cube.held = false
	var wall = StaticBody3D.new();wall.collision_layer = 1;game.add_child(wall)
	var shape = CollisionShape3D.new();var box = BoxShape3D.new();box.size = Vector3(2,.1,2);shape.shape = box;wall.add_child(shape);wall.position.y = .5
	await frames(2)
	aim(game,Vector3(0,1,-.12),cube.global_position)
	expect(game.target.is_empty() and game.interaction_outline.focused == null,"Unrelated wall blocks selection and clears the same pickup outline")
	press_e(game)
	expect(game.model.held_item().is_empty(),"Desktop E cannot collect through unrelated scenery")
	wall.free();ring.free()
	await frames(2)
	# Supported pickup consumes exactly the same surface metadata as loose stock.
	game.model.items.small.location = "support:test_shelf"
	game.loose.erase("small")
	var shelf = Shelf.new();shelf.game = game;shelf.cargo = cube
	game.equipment.entries.assign([{"type":"equipment","controller":shelf,"action":"take:0","label":"Shelf component","point":Vector3(8,8,8),"radius":.3,"input":"pickup","node":cube,"pickup_body":cube,"allowed":[cube],"allow_body_hit":true}])
	aim(game,Vector3(0,1,-.12),cube.global_position)
	expect(game.target.get("type","") == "equipment" and game.interaction_outline.focused == cube,"Supported pickup uses the mesh hit even when its proxy target is off screen")
	press_e(game)
	expect(game.model.held_item() == "small" and is_instance_valid(game.components.held_body),"Desktop E transfers supported ownership through the ordinary equipment pickup path")
	game.components.held_body.free();game.components.held_body = null;game.model.release_item("loose");game.loose.clear()
	var near = body(game,"small",cube_mesh,Transform3D(Basis.IDENTITY,Vector3(0,0,-2.04)))
	await frames(2)
	aim(game,Vector3.ZERO,near.global_position)
	expect(game.target.get("uid","") == "small" and game.targeting.access(game.targeting.target_receivers()).is_empty(),"Reach uses the near visible surface rather than the out-of-reach body origin")
	near.position.z = -2.2
	await frames(2)
	aim(game,Vector3.ZERO,near.global_position)
	press_e(game)
	expect(game.model.held_item().is_empty(),"Desktop E preserves the reach limit at the actual pickup surface")
	near.free();game.loose.clear()
	var passed = checks.all(func(c):return c.passed)
	print("PICKUP_SURFACES ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
