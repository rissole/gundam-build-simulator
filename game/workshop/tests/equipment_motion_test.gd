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
func run() -> void:
	await shared_queries()
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
	game.model.assemblies.left_leg = {"parent":"","location":"support:leg_holder"}
	rail.index_x = definition.station_x;rail._pose()
	var direction = signf(definition.lanes.parking-definition.station_x)
	var blocker = obstacle(game,Vector3(definition.station_x+direction*2,definition.holder.bogie.y,definition.home_z),Vector3(.1,.3,.3),Motion.PARTS);await frames(2)
	expect(rail.request("park").is_empty(),"rail accepts parking with a distant loose obstacle")
	rail.physics(.1)
	expect(rail.index_x != definition.station_x and rail.blocked_reason.is_empty(),"rail moves through the clear start of its route")
	until_held(rail)
	expect(rail.moving and rail.motion_obstruction.get("collider") == blocker,"real articulated holder pauses and identifies its obstacle")
	var at: float = rail.index_x;rail.physics(.1)
	expect(is_equal_approx(rail.index_x,at),"waiting rail preserves progress")
	expect(rail.request("return").is_empty(),"waiting rail accepts return without requiring Stop")
	until_held(rail)
	expect(not rail.moving and is_equal_approx(rail.index_x,definition.station_x),"held rail returns to the station")
	rail.request("park");until_held(rail);blocker.free();await frames(2);until_held(rail)
	expect(not rail.moving and is_equal_approx(rail.index_x,definition.lanes.parking),"cleared rail resumes automatically to its original destination")
	game.free();await frames(1)
