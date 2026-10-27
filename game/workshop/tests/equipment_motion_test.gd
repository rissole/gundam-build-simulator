extends "res://tests/kit/harness.gd"
## Isolated real-physics coverage of shared policy and production rail/crane ticks.
## Small supplied payloads exercise collision/state contracts, not authored journeys.
const Motion = EquipmentRegistry.Motion
const Fixture = preload("res://tests/kit/equipment_fixture.gd")
class Hands extends RefCounted:
	var held_body: CollisionObject3D
	func title(_kind: String) -> String:return "test bracket"
class Runtime extends RefCounted:
	var payload: CollisionObject3D
	func node(_id: String) -> CollisionObject3D:return payload
	func descendants(_id: String) -> Array:return []
class Game extends Fixture:
	var player: CharacterBody3D
	var components = Hands.new()
	var runtime = Runtime.new()
	var zones = preload("res://scripts/zone_register.gd").new(["limb_station"])
	var hud: Node
	var interaction_outline: Node3D
	var loose: Dictionary = {}
class Layout extends Node3D:
	var cradle: Node3D
class Console extends CanvasLayer:
	func physics() -> void:pass
class Crane extends "res://scripts/service_crane.gd":
	# Only projection is replaced; production physics, load sweeps and controls run.
	func _refresh() -> void:
		if not is_instance_valid(load_body):return
		load_body.global_transform = load_pose(path)
		PhysicsServer3D.body_set_state(load_body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,load_body.global_transform)
class Equipment extends WorkshopEquipment:
	var moving = true
class Gates extends WorkshopEquipment:
	func occupancy_error() -> String:return ""
	func closed() -> bool:return true
	func request_closed(_closed: bool) -> String:return ""
class Access extends WorkshopEquipment:
	func ready_for(_mode: String) -> bool:return true
	func request_mode(_mode: String) -> String:return ""
func _initialize() -> void:call_deferred("run")
func shape(body: CollisionObject3D, size: Vector3) -> void:
	var col = CollisionShape3D.new();var box = BoxShape3D.new();box.size = size;col.shape = box;body.add_child(col)
func obstacle(game: Node, at: Vector3, size: Vector3, layer: int = 1) -> StaticBody3D:
	var body = StaticBody3D.new();body.name = "Supplied obstruction";body.position = at;body.collision_layer = layer
	game.add_child(body);shape(body,size);return body
func until_held(equipment: Node) -> void:
	for tick in range(200):
		equipment.physics(.1)
		if not equipment.moving or not equipment.blocked_reason.is_empty():return
func until_settled(rail: Node) -> void:
	for tick in range(200):
		rail.physics(.1)
		if rail.jog_settled():return
func run() -> void:
	await shared_queries()
	await linear_queries()
	rigid_geometry_cache()
	await authored_deck_cargo()
	await loose_deck_cargo()
	await deck_cargo_obstacles()
	await mobile_deck_cargo()
	await shelf_cargo()
	await crane_motion()
	await rail_motion()
	var passed = checks.all(func(c):return c.passed)
	print("EQUIPMENT_MOTION ","PASS " if passed else "FAIL ",checks.size()," checks")
	quit(0 if passed else 1)
func shared_queries() -> void:
	var game = Game.new();root.add_child(game)
	var equipment = Equipment.new();game.add_child(equipment);equipment.game = game;equipment.equipment_id = "probe";game.equipment.register(equipment)
	var part = WorkshopPart.new();part.kind = "bracket";part.freeze = true;part.collision_layer = Motion.PARTS
	game.add_child(part);shape(part,Vector3(.002,.2,.2));part.position.x = .5
	await frames(2)
	var moving_shape = BoxShape3D.new();moving_shape.size = Vector3(.002,.1,.1)
	var groups = [{"shapes":[{"shape":moving_shape,"transform":Transform3D.IDENTITY}],"cast":true,"error":"","margin":0.0}]
	var hit = Motion.sweep(equipment,groups,1,func(p):return Transform3D(Basis.IDENTITY,Vector3(p,0,0)),[])
	expect(hit.get("collider") == part and hit.get("kind") == "part" and hit.get("error","").contains("test bracket"),"continuous cast catches and names a thin part between samples")
	var articulated = [{"shapes_at":func(_pose,p):return [{"shape":moving_shape,"world":Transform3D(Basis.IDENTITY,Vector3(p,0,0))}],"margin":0.0}]
	hit = Motion.sweep(equipment,articulated,1,func(_p):return Transform3D.IDENTITY,[])
	expect(hit.get("collider") == part,"articulated rig shapes also cast continuously between supplied poses")
	expect(game.equipment.obstruction_target() == part,"waiting loose part is exposed to the shared outline")
	game.interaction_outline = preload("res://scripts/interaction_outline.gd").new();game.add_child(game.interaction_outline)
	var targeting = preload("res://scripts/targeting.gd").new(game)
	targeting._present_outline()
	expect(game.interaction_outline.focused == part,"target presentation outlines the obstruction without requiring aim")
	var pickup = Node3D.new();game.add_child(pickup);targeting._present_outline(pickup)
	expect(game.interaction_outline.focused == pickup,"aimed pickup retains its own collection affordance")
	game.paused = true;targeting._present_outline()
	expect(game.interaction_outline.focused == null,"pause clears the obstruction outline")
	game.paused = false
	equipment.moving = false
	expect(game.equipment.obstruction_target() == null,"manual Stop removes obstruction focus")
	equipment.moving = true
	expect(Motion.overlap(equipment,moving_shape,part.global_transform,[],0,Motion.STRUCTURE).is_empty(),"category mask excludes loose parts from structure-only query")
	game.components.held_body = part
	hit = Motion.overlap(equipment,moving_shape,part.global_transform,[])
	expect(hit.get("kind") == "hand_load","same part is classified as hand load when held")
	expect(Motion.overlap(equipment,moving_shape,part.global_transform,[part.get_rid()]).is_empty(),"explicit moving-load exclusion is honored")
	game.components.held_body = null
	part.free()
	expect(game.equipment.obstruction_target() == null,"freed obstruction cannot leave a stale outline target")
	var player = obstacle(game,Vector3.ZERO,Vector3.ONE,Motion.PLAYER)
	await frames(2)
	hit = Motion.overlap(equipment,moving_shape,Transform3D.IDENTITY,[])
	expect(hit.get("kind") == "player","player mask identifies a person independently of parts")
	player.free()
	var route: Array[Transform3D] = [Transform3D.IDENTITY,Transform3D(Basis.IDENTITY,Vector3(1,0,0)),Transform3D(Basis.IDENTITY,Vector3(1,0,2))]
	expect(is_equal_approx(Motion.path_ahead(route,.9,2.0,.91,0),1.075),"look-ahead measures metres around route corners")
	expect(is_equal_approx(Motion.path_ahead(route,1.1,0.0,1.09,0),.95),"reverse look-ahead follows the same corner")
	expect(is_equal_approx(Motion.ahead(0,4,1),1) and is_equal_approx(Motion.ahead(2,0,-.01),1.75),"reservation covers long physics steps and reversed motion")
	game.free();await frames(1)
func linear_queries() -> void:
	var game = Game.new();root.add_child(game)
	var equipment = Equipment.new();game.add_child(equipment);equipment.game=game;equipment.equipment_id="linear_probe"
	var box = BoxShape3D.new();box.size=Vector3(.002,.1,.1)
	var samples: Array = []
	var pose = func(p):samples.append(p);return Transform3D(Basis.IDENTITY,Vector3(p,0,0))
	var group = {"shapes":[{"shape":box,"transform":Transform3D.IDENTITY}],"linear":true,"margin":0.0}
	expect(Motion.sweep(equipment,[group],10,pose,[]).is_empty() and samples==[0.0,1.0],"straight rigid sweep evaluates only two endpoints, independent of sample count")
	var thin = obstacle(game,Vector3(.5,0,0),Vector3(.002,.2,.2),Motion.PARTS);await frames(2)
	expect(Motion.sweep(equipment,[group],10,pose,[]).get("collider")==thin,"linear fast path retains continuous thin-obstacle detection")
	expect(Motion.sweep(equipment,[group],10,pose,[thin.get_rid()]).is_empty(),"linear fast path retains moving-body exclusions")
	for x in [0.0,1.0]:
		thin.position.x=x;PhysicsServer3D.body_set_state(thin.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,thin.global_transform)
		expect(Motion.sweep(equipment,[group],10,pose,[]).get("collider")==thin,"linear fast path detects endpoint overlap at "+str(x))
	thin.free();await frames(1)
	samples.clear()
	var changing_exclusions = func(_at):return [] as Array[RID]
	expect(Motion.sweep(equipment,[group],10,pose,[],Motion.ALL,changing_exclusions).is_empty() and samples.size()==11,"pose-dependent contact exclusions retain every original sample")
	var arc_blocker = obstacle(game,Vector3(0,1,0),Vector3(.1,.1,.1));await frames(2)
	var curved = {"shapes_at":func(_at,p):return [{"shape":box,"world":Transform3D(Basis.IDENTITY,Vector3(sin(p*TAU),1-cos(p*TAU),0)*.5)}],"margin":0.0}
	expect(Motion.sweep(equipment,[curved],10,func(_p):return Transform3D.IDENTITY,[]).get("collider")==arc_blocker,"articulated path with identical endpoint frames still checks its curved middle")
	game.free();await frames(1)

func rigid_geometry_cache() -> void:
	var body = StaticBody3D.new();root.add_child(body)
	var col = CollisionShape3D.new();col.shape=BoxMesh.new().create_trimesh_shape();body.add_child(col)
	body.set_meta("collision_revision",0)
	var cache = Motion.Sweep.RigidGeometry.new();cache.read(body)
	var proxy: Shape3D = cache.shapes[0].shape
	body.transform=Transform3D(Basis(Vector3.UP,.4),Vector3(3,2,1));cache.read(body)
	expect(cache.shapes[0].shape==proxy and cache.shapes[0].transform.is_equal_approx(Transform3D.IDENTITY),"rigid load reuses its converted proxy through translation and rotation")
	var child = StaticBody3D.new();body.add_child(child);shape(child,Vector3(.2,.2,.2));child.position.x=2
	body.set_meta("collision_revision",1);cache.read(body)
	expect(cache.shapes.size()==2 and child.get_rid() in cache.rids and cache.shapes[0].shape!=proxy,"collision revision rebuilds geometry and descendant exclusions together")
	child.position.x=3;cache.invalidate();cache.read(body)
	expect(cache.shapes[1].transform.origin.is_equal_approx(Vector3(3,0,0)),"explicit articulation invalidation refreshes local child poses")
	col.disabled=true;body.set_meta("collision_revision",2);cache.read(body)
	expect(cache.shapes.size()==1,"revision removes disabled collision geometry")
	body.remove_meta("collision_revision");cache.read(body)
	child.position.x=4;cache.read(body)
	expect(cache.shapes[0].transform.origin.is_equal_approx(Vector3(4,0,0)),"unversioned bodies collect live geometry on every read")
	var other = StaticBody3D.new();root.add_child(other);shape(other,Vector3.ONE);other.set_meta("collision_revision",2);cache.read(other)
	expect(cache.rids==[other.get_rid()] and cache.shapes.size()==1,"switching payload identity discards the old geometry and RIDs")
	body.free();other.free()
func loose_part(game: Game, uid: String, at: Vector3, size: Vector3) -> WorkshopPart:
	var body = WorkshopPart.new();body.uid = uid;body.kind = uid;body.collision_layer = 2;body.collision_mask = 15
	game.add_child(body);shape(body,size);body.global_position = at
	game.loose[uid] = body;game.model.items[uid] = {"location":"loose","kind":uid}
	return body

func cargo_tick(game: Game, count: int, delta: float = .1) -> void:
	for tick in range(count):
		game.equipment.physics(delta);await frames(1)

func authored_deck_cargo() -> void:
	var content = preload("res://scripts/workshop_content.gd").load_workshop()
	for uid in ["PV-120__001","PV-200__001"]:
		var game = Game.new();root.add_child(game)
		var lift = preload("res://scripts/work_access_lift.gd").new();game.add_child(lift)
		lift.setup(game,"authored",Vector3.ZERO,Vector2(2,3),[.15,1.5] as Array[float]);game.equipment.register(lift)
		var record: Dictionary = content.scenario.parts.filter(func(part):return part.instance_id == uid)[0]
		var definition: Dictionary = content.data.parts[record.kind]
		var mesh = LegSourceGeometry.make_mesh(content.content.sources[uid])
		var body = WorkshopPart.new();body.uid=uid;body.kind=record.kind;body.collision_layer=2;body.collision_mask=15;game.add_child(body)
		for entry in SolidHandling.authored_shapes(definition.get("collision_shapes",[]),mesh.get_aabb()):
			var col = CollisionShape3D.new();col.shape=entry.shape;col.transform=entry.transform;body.add_child(col)
		var bounds = SolidHandling.bounds(body)
		body.position = Vector3(-bounds.get_center().x,.15-bounds.position.y,-bounds.get_center().z)
		game.loose[uid]=body;game.model.items[uid]={"location":"loose","kind":record.kind}
		await frames(30);await cargo_tick(game,3,0)
		var offset = body.position-lift.deck.position
		expect(lift.passengers().has(body),uid+" actual authored collision shape rests on the deck")
		lift.request("up");await cargo_tick(game,25)
		expect(not lift.moving and body.position.is_equal_approx(lift.deck.position+offset),uid+" actual shape rides upward through the registry")
		lift.request("down");await cargo_tick(game,25)
		expect(not lift.moving and body.position.is_equal_approx(lift.deck.position+offset) and game.loose[uid]==body,uid+" rides down with the same loose identity")
		game.free();await frames(1)

func loose_deck_cargo() -> void:
	var game = Game.new();root.add_child(game)
	var lift = preload("res://scripts/work_access_lift.gd").new();game.add_child(lift)
	lift.setup(game,"cargo",Vector3.ZERO,Vector2(3,3),[.15,1.2,3.0] as Array[float]);game.equipment.register(lift)
	var load = loose_part(game,"bracket",Vector3(0,.35,0),Vector3(1.5,.4,.6))
	await frames(30);await cargo_tick(game,3,0)
	expect(lift.passengers().has(load) and load.freeze,"stable loose cargo is detected through actual deck contact")
	var offset = load.global_position-lift.deck.global_position
	lift.request("up");await cargo_tick(game,5)
	expect(lift.height>.15 and load.global_position.is_equal_approx(lift.deck.global_position+offset),"registry carries resting loose bracket through actual lift travel")
	game.model.items[load.uid].location = "held";game.loose.erase(load.uid);game.components.held_body = load;load.held = true
	load.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	var held_at = load.global_position;await cargo_tick(game,1)
	expect(not lift.passengers().has(load) and load.global_position.is_equal_approx(held_at) and load.freeze_mode == RigidBody3D.FREEZE_MODE_KINEMATIC,"pickup during motion immediately releases loose support without overwriting hand physics")
	# Supply a rider to exercise the other owner of this same physical body.
	game.player = CharacterBody3D.new();game.player.collision_layer = 8;game.add_child(game.player)
	shape(game.player,Vector3(.2,.2,.2));game.player.position = Vector3(1,lift.height+.1,.3)
	await frames(2)
	var grip = load.global_position-game.player.global_position;await cargo_tick(game,1)
	expect((load.global_position-game.player.global_position).is_equal_approx(grip),"picked-up cargo follows a rider exactly once")
	load.held = false;game.components.held_body = null;game.model.items[load.uid].location = "loose";game.loose[load.uid] = load
	load.freeze = false;load.gravity_scale = 1;load.position = Vector3(0,lift.height+.201,0)
	load.linear_velocity = Vector3.ZERO;load.angular_velocity = Vector3.ZERO
	await cargo_tick(game,60)
	expect(not lift.moving and is_equal_approx(lift.height,1.2) and game.loose[load.uid]==load and game.model.items[load.uid].location=="loose","drop while riding settles and arrives with one unchanged loose identity: "+str(lift.height)+" "+lift.blocked_reason+" "+str(load.position)+" passengers "+str(lift.passengers()))
	game.player.free();game.player = null
	# Support loss restores dynamic physics, rather than retaining a ghost ride.
	load.position.x = 5;PhysicsServer3D.body_set_state(load.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,load.global_transform)
	await cargo_tick(game,1,0)
	expect(not load.freeze and not lift.passengers().has(load),"leaving the deck relinquishes support and restores dynamic physics")
	game.loose.erase(load.uid);load.free()
	var tall = loose_part(game,"upright_panel",Vector3(0,1.7,0),Vector3(.4,1,.4))
	await frames(25);await cargo_tick(game,3,0)
	expect(lift.passengers().has(tall),"A loose panel resting upright is a deck passenger")
	offset = tall.global_position-lift.deck.global_position
	lift.request("down");await cargo_tick(game,20)
	expect(not lift.moving and tall.global_position.is_equal_approx(lift.deck.global_position+offset),"loose upright panel rides down without physics drift")
	# A real loose shaft blocker remains an obstacle and resumes when removed.
	var blocker = loose_part(game,"shaft_blocker",Vector3(.7,1.7,0),Vector3(.2,.2,.2));blocker.freeze = true
	await frames(2);lift.request("up");await cargo_tick(game,20)
	expect(lift.moving and lift.motion_obstruction.get("collider")==blocker and not lift.passengers().has(blocker),"unsupported loose shaft component holds the trip with its identity")
	blocker.free();game.loose.erase("shaft_blocker");await cargo_tick(game,40)
	expect(not lift.moving and lift.blocked_reason.is_empty(),"removing a shaft obstruction resumes the original cargo trip: "+str(lift.height)+" "+lift.blocked_reason+" cargo "+str(tall.position)+" passengers "+str(lift.passengers()))
	game.free();await frames(1)

func deck_cargo_obstacles() -> void:
	var game = Game.new();root.add_child(game)
	var lift = preload("res://scripts/work_access_lift.gd").new();game.add_child(lift)
	lift.setup(game,"overhang",Vector3.ZERO,Vector2(3,3),[.15,1.5] as Array[float]);game.equipment.register(lift)
	var load = loose_part(game,"long_panel",Vector3(0,.25,0),Vector3(4,.2,.4))
	await frames(30);await cargo_tick(game,3,0)
	var offset = load.position-lift.deck.position
	var landing = obstacle(game,Vector3(1.9,1.1,0),Vector3(.3,.1,.5));landing.name="Landing rail"
	await frames(2);lift.request("up");await cargo_tick(game,25)
	expect(lift.moving and lift.height>.15 and lift.motion_obstruction.get("collider")==landing and lift.blocked_reason.contains("Landing rail"),"cargo overhang outside deck holds actual travel and names the fixed obstacle")
	var at = load.position
	expect(lift.request("ground").is_empty() and load.position.is_equal_approx(at),"held cargo trip accepts a new destination without moving the load twice")
	await cargo_tick(game,20)
	expect(not lift.moving and load.position.is_equal_approx(lift.deck.position+offset),"loose overhang reverses down with a stable deck pose")
	lift.request("up");await cargo_tick(game,20);landing.free();await cargo_tick(game,25)
	expect(not lift.moving and lift.blocked_reason.is_empty() and load.position.is_equal_approx(lift.deck.position+offset),"overhanging cargo automatically resumes after its genuine obstacle clears")
	# Put the same loose body across two supports at the stopped deck height.
	var fixed = obstacle(game,Vector3(1.9,lift.height-.06,0),Vector3(.8,.12,.6));await frames(2)
	await cargo_tick(game,2,0)
	expect(not lift.passengers().has(load) and not load.freeze,"straddling a fixed landing relinquishes deck support instead of dragging the load")
	lift.request("down");await cargo_tick(game,2)
	expect(lift.moving and lift.motion_obstruction.get("collider")==load,"a fixed-supported bridging load holds the lift as a loose obstruction")
	fixed.free();game.free();await frames(1)

func mobile_deck_cargo() -> void:
	var game = Game.new();root.add_child(game)
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop-layout.json")).workshop.mobile_platform
	spec.docks = {"park":[0,0,0],"test":[3,0,0]};spec.routes = {"park":[],"test":[[3,0,0]]}
	var platform = preload("res://scripts/mobile_work_platform.gd").new();game.add_child(platform);platform.setup(game,spec);game.equipment.register(platform)
	var load = loose_part(game,"ordinary_bracket",Vector3(0,.30,0),Vector3(.3,.3,.3))
	await frames(30);await cargo_tick(game,3,0)
	var offset = load.position-platform.deck.global_position
	expect(platform.passengers().has(load) and platform.request("dock:test").is_empty(),"ordinary resting loose cargo permits mobile platform ground transfer")
	await cargo_tick(game,4)
	var at = load.position;platform.request("stop");await cargo_tick(game,2)
	expect(not platform.moving and load.position.is_equal_approx(at),"mobile Stop holds loose cargo without drift")
	expect(platform.request("return").is_empty(),"stopped cargo platform accepts reversal")
	await cargo_tick(game,20)
	expect(platform.dock=="park" and load.position.is_equal_approx(platform.deck.global_position+offset),"reversed ground transfer returns the same loose passenger exactly once")
	platform.request("up");await cargo_tick(game,40)
	expect(not platform.moving and is_equal_approx(platform.height,spec.heights[1]) and load.position.is_equal_approx(platform.deck.global_position+offset),"shared cargo support also follows mobile vertical travel")
	platform.request("down");await cargo_tick(game,2)
	load.position.x = 8;PhysicsServer3D.body_set_state(load.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,load.global_transform)
	await cargo_tick(game,1)
	expect(platform.moving and not load.freeze and not platform.passengers().has(load),"support loss during mobile travel restores dynamic physics without stopping an empty deck")
	var other = preload("res://scripts/work_access_lift.gd").new();game.add_child(other)
	other.setup(game,"other",Vector3(8,0,0),Vector2(3,3),[.15,1.5] as Array[float]);game.equipment.register(other)
	load.position = Vector3(8,.30,0);load.linear_velocity=Vector3.ZERO;load.angular_velocity=Vector3.ZERO
	await frames(30);await cargo_tick(game,3,0)
	expect(other.passengers().has(load) and not platform.passengers().has(load),"a loose component transfers support between machines without a second owner")
	other.request("up");await cargo_tick(game,4)
	expect(absf(load.position.y-other.height-.15)<.005 and game.model.items[load.uid].location=="loose","new supporting machine carries the transferred physical identity")
	game.loose.erase(load.uid);load.free();await cargo_tick(game,1)
	expect(other.passengers().is_empty(),"freed or consumed cargo leaves no stale passenger")
	var hovering = loose_part(game,"hovering",Vector3(8,other.height+.115,0),Vector3(.2,.2,.2));hovering.freeze=true
	await frames(2);await cargo_tick(game,3,0)
	expect(not other.passengers().has(hovering),"a stable hovering component overlapping the deck query is never claimed")
	game.free();await frames(1)

func shelf_cargo() -> void:
	var game = Game.new();root.add_child(game)
	var lift = preload("res://scripts/work_access_lift.gd").new();game.add_child(lift)
	lift.setup(game,"shelf_test",Vector3.ZERO,Vector2(2,2),[.15,3.0] as Array[float]);game.equipment.register(lift)
	var shelf = preload("res://scripts/lift_shelf.gd").new();game.add_child(shelf);shelf.game = game;shelf.lift = lift
	var cargo = obstacle(lift.deck,Vector3(2,.5,0),Vector3(.3,.3,.3),Motion.PARTS);shelf.cargo = {"test":cargo}
	var blocker = obstacle(game,Vector3(2,1.05,0),Vector3(.3,.1,.3));await frames(2)
	expect(shelf.travel_error(lift.equipment_id,.15,.4).is_empty() == false and lift.motion_obstruction.get("collider") == blocker,"overhanging shelf cargo uses shared blocker identity")
	blocker.free();await frames(2)
	expect(shelf.travel_error(lift.equipment_id,.15,.4).is_empty(),"shelf cargo clears without treating its own deck or cargo as obstacles")
	game.free();await frames(1)
func crane_motion() -> void:
	var game = Game.new();root.add_child(game)
	var crane = Crane.new();game.add_child(crane);crane.game = game;crane.equipment_id = "service_crane";game.equipment.register(crane)
	crane.console = Console.new();crane.add_child(crane.console)
	crane.uid = "payload";crane.assembly_payload = true;crane.load_owner = "receiver"
	game.model.assemblies.payload = {"parent":"","parent_slot":"","location":"support:crane_rigging"}
	crane.config = {"spec":{"exact_receiver":true,"sweep_radius":1.0}}
	crane.END_IDS = ["a"];crane.endpoints = {"a":{"state":"attached","point":"p"}}
	for at in [Vector3.ZERO,Vector3(0,1,0),Vector3(3,1,0),Vector3(3,1,3),Vector3(3,.5,3),Vector3(3,0,3)]:crane.route.append(Transform3D(Basis.IDENTITY,at))
	crane.load_body = AnimatableBody3D.new();crane.load_body.sync_to_physics = false;game.add_child(crane.load_body);shape(crane.load_body,Vector3(.2,.2,.2))
	crane.station = "source";crane.motion = "go:receiver";crane.moving = true;crane._refresh()
	var blocker = obstacle(game,Vector3(2,1,0),Vector3(.1,.5,.5),Motion.PARTS);await frames(2)
	crane.physics(.1)
	expect(crane.progress > 0 and crane.blocked_reason.is_empty(),"crane begins despite a distant obstruction")
	until_held(crane)
	expect(crane.moving and crane.motion_obstruction.get("collider") == blocker and crane.load_body.position.x < 1.85,"loaded crane waits short of the actual blocker")
	var pose = crane.load_body.global_transform
	expect(crane.request("return").is_empty() and crane.load_body.global_transform.is_equal_approx(pose),"waiting crane can reverse without a pose jump")
	until_held(crane)
	expect(not crane.moving and crane.station == "source","crane returns along the clear part of its route")
	crane.motion = "go:receiver";crane.progress = 0;crane.moving = true
	until_held(crane);blocker.free();await frames(2)
	until_held(crane)
	expect(not crane.moving and crane.station == "receiver" and crane.blocked_reason.is_empty(),"loaded crane resumes automatically and follows its route corner")
	expect(game.model.assemblies.payload.location == "support:crane_rigging","transport waiting and reversal preserve supported ownership")
	var receiver = obstacle(game,Vector3(3,0,3),Vector3(.2,.2,.2));game.runtime.payload = receiver
	crane.receiver_pose = Transform3D(Basis.IDENTITY,receiver.position);crane.config.spec.exact_receiver = false
	await frames(2)
	var approach = crane.receiver_pose.translated(Vector3.UP*.45)
	expect(crane._sweep(approach,crane.receiver_pose).is_empty(),"look-ahead may enter the authorized receiver contact zone without deadlocking outside it")
	var unrelated = obstacle(game,Vector3(3,.15,3),Vector3(.1,.1,.1),Motion.PARTS);await frames(2)
	expect(not crane._sweep(approach,crane.receiver_pose).is_empty() and crane.motion_obstruction.get("collider") == unrelated,"receiver contact excludes only its mating body, never an unrelated loose part")
	game.free();await frames(1)
func rail_motion() -> void:
	var game = Game.new();root.add_child(game)
	var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop-layout.json")).workshop.rail
	var layout = Layout.new();game.add_child(layout);layout.cradle = preload("res://scripts/leg_cradle.gd").new();layout.add_child(layout.cradle);layout.cradle.setup(game,definition)
	var rail = preload("res://scripts/indexed_leg_rail.gd").new();game.add_child(rail);rail.game = game;rail.layout = layout;rail.spec = definition;rail.equipment_id = "leg_rail";game.equipment.register(rail)
	var payload = AnimatableBody3D.new();payload.sync_to_physics = false;game.add_child(payload);shape(payload,Vector3(.2,.2,.2));game.runtime.payload = payload
	game.model.definitions = {"assemblies":{"leg":{"supplied_milestones":["structural_ready"],"slots":{}}}}
	game.model.assemblies.left_leg = {"parent":"","location":"support:leg_holder","definition":"leg","slots":{}}
	# Loaded indexing needs the stowed bolster; from the right track the next stop is parking.
	rail.bolster = 1.0;rail.index_x = definition.lanes.right;rail._pose()
	var direction = signf(definition.lanes.parking-definition.lanes.right)
	var blocker = obstacle(game,Vector3(definition.lanes.right+direction*2,definition.holder.bogie.y,definition.home_z),Vector3(.1,.3,.3),Motion.PARTS);await frames(2)
	expect(rail.action_error("index+").is_empty(),"loaded rail accepts an INDEX jog with a distant loose obstacle")
	rail.set_jog("index+");rail.physics(.1)
	expect(rail.index_x != definition.lanes.right and rail.blocked_reason.is_empty(),"held INDEX moves through the clear start of its route")
	until_held(rail)
	expect(rail.moving and rail.motion_obstruction.get("collider") == blocker,"real articulated holder pauses and identifies its obstacle while E stays held")
	var at: float = rail.index_x;rail.physics(.1)
	expect(is_equal_approx(rail.index_x,at),"waiting rail preserves progress")
	rail.set_jog("")
	expect(not rail.moving and is_equal_approx(rail.index_x,at),"releasing E brakes the waiting rail where it stands")
	expect(rail.action_error("index-").is_empty(),"the opposite arrow is available after release")
	rail.set_jog("index-");until_settled(rail)
	expect(rail.jog_settled() and rail.index_x == definition.lanes.right,"reverse jog stops exactly on the right hip track")
	rail.set_jog("");rail.set_jog("index+");until_held(rail)
	blocker.free();await frames(2);until_settled(rail)
	expect(rail.jog_settled() and rail.index_x == definition.lanes.parking,"a held jog resumes once the obstacle clears and stops at parking")
	rail.set_jog("")
	# Exercise longitudinal travel with the real holder and payload sweep. Only
	# unrelated gate/access orchestration is supplied.
	var gates=Gates.new();game.add_child(gates);gates.equipment_id="rail_gates";game.equipment.register(gates)
	var access=Access.new();game.add_child(access);access.equipment_id="workshop_access";game.equipment.register(access)
	rail.index_x=definition.lanes.left;rail.travel_z=lerpf(definition.home_z,definition.bay_z,.2);rail._pose()
	payload.set_meta("collision_revision",0)
	var resize_events: Array = []
	for piece in layout.cradle.pieces.values():piece.shape.shape.changed.connect(func():resize_events.append(true))
	var forward=Vector3(0,0,signf(definition.bay_z-definition.home_z))
	blocker=obstacle(game,payload.global_position+forward*.6,Vector3(.2,.2,.002),Motion.PARTS);await frames(2)
	expect(rail.action_error("travel+").is_empty(),"lying leg on its track accepts TRAVEL +: "+rail.action_error("travel+"))
	var start: float=rail.travel_z;rail.set_jog("travel+");rail.physics(1.0/60.0)
	expect(rail.travel_z>start and rail.blocked_reason.is_empty(),"longitudinal rail starts along clear track")
	until_held(rail)
	expect(rail.moving and rail.motion_obstruction.get("collider")==blocker,"straight rail waits for a thin obstacle in the loaded leg's path")
	expect(resize_events.is_empty(),"straight rail movement does not rebuild unchanged live holder dimensions")
	var query_count: int=layout.cradle.query_boxes.size()
	var saved_boxes: Dictionary=layout.cradle.query_boxes.duplicate()
	blocker.free();await frames(2);until_settled(rail)
	expect(rail.jog_settled() and rail.travel_z==definition.bay_z,"held TRAVEL resumes to its bay end stop after the obstacle clears")
	expect(query_count==layout.cradle.pieces.size() and layout.cradle.query_boxes==saved_boxes,"holder queries reuse one box per member across travel ticks")
	rail.set_jog("")
	var live_sizes: Dictionary={}
	for id in layout.cradle.pieces:live_sizes[id]=layout.cradle.pieces[id].shape.shape.size
	var holder_pose=rail.snapshot_pose(rail.capture())
	layout.cradle.query_geometry(holder_pose.frame,holder_pose.bogie_x,holder_pose.bogie_z,1,1,1)
	var unchanged=true
	for id in layout.cradle.pieces:
		if layout.cradle.pieces[id].shape.shape.size!=live_sizes[id]:unchanged=false
	expect(unchanged,"articulated look-ahead never resizes the live holder colliders")
	game.free();await frames(1)
