extends "res://tests/kit/harness.gd"
## Fixed-fps headless runs can enqueue thousands of Jolt jobs faster than worker
## threads drain them. Keep the same simulated ticks, with a scheduling slice
## per tick; this prevents resource exhaustion without retries or weaker checks.
func frames(count: int = 3, physics: bool = true) -> void:
	for tick in range(count):
		await super.frames(1,physics)
		OS.delay_usec(1000)

class Holder extends Node:
	var held_body: CollisionObject3D
class Harness extends Node3D:
	var player: CharacterBody3D
	var components: Node
	var paused = false
	var lift: Node3D
	func material(color: Color, _metal = 0.0) -> StandardMaterial3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		return mat
	func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
		var mesh = MeshInstance3D.new()
		var shape = BoxMesh.new()
		shape.size = size
		mesh.mesh = shape
		mesh.material_override = mat
		mesh.position = at
		parent.add_child(mesh)
		return mesh
	func _physics_process(delta: float) -> void:
		if not is_instance_valid(lift):return
		# The workshop registry carries a rider's hand load with the deck.
		var held: Node3D = components.held_body if is_instance_valid(components) and lift.rider() != null else null
		var before: float = lift.height
		lift.physics(delta)
		if is_instance_valid(held):held.position.y += lift.height-before
		player.velocity.y = -0.1 if player.is_on_floor() else player.velocity.y-14*delta
		player.move_and_slide()
var game: Harness
var lift: Node3D
func _initialize() -> void:run.call_deferred()
func obstacle(at: Vector3, size: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.position = at
	body.collision_layer = 1
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	game.add_child(body)
	return body
## Runs a requested trip until it arrives or holds for an obstruction.
func until_held(limit: int = 900) -> void:
	for tick in range(limit):
		if not lift.moving or not lift.blocked_reason.is_empty():return
		await frames(1)

func connected_to_guides() -> bool:
	var fixed = lift.get_node("FloorAnchoredLiftGuides")
	var contacts = 0
	for shoe in lift.deck.get_children():
		if not shoe is CollisionShape3D or not shoe.name.begins_with("GuideCarriage"):continue
		var shoe_bounds: AABB = shoe.global_transform*shoe.shape.get_debug_mesh().get_aabb()
		for column in fixed.get_children():
			if not column is CollisionShape3D or column.shape.get_debug_mesh().get_aabb().size.y < 2:continue
			var column_bounds: AABB = column.global_transform*column.shape.get_debug_mesh().get_aabb()
			if shoe_bounds.intersects(column_bounds):contacts += 1
	return contacts == 2

func run() -> void:
	game = Harness.new()
	root.add_child(game)
	game.player = CharacterBody3D.new()
	game.player.collision_layer = 8
	game.player.collision_mask = 15
	var col = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.height = 1.7
	capsule.radius = 0.26
	col.shape = capsule
	col.position.y = 0.86
	game.player.add_child(col)
	game.add_child(game.player)
	obstacle(Vector3(0,-0.15,0),Vector3(30,0.3,30))
	lift = load("res://scripts/work_access_lift.gd").new()
	game.add_child(lift)
	lift.setup(game,"test",Vector3.ZERO,Vector2(2,5),[0.15,1.2,3.8,5.2,8.7] as Array[float])
	game.lift = lift
	var guide_bounds: AABB = SolidHandling.bounds(lift.get_node("FloorAnchoredLiftGuides"))
	expect(absf(guide_bounds.position.y)<0.001 and guide_bounds.end.y >= 10.0,"Solid guide structure reaches floor and spans maximum passenger travel")
	expect(connected_to_guides(),"Both ground-level carriage shoes engage solid vertical guides")
	game.player.position = Vector3(0,0.17,0)
	await frames(12)
	expect(game.player.is_on_floor(),"Rider settles on real solid deck")
	expect(lift.gate.disabled,"Ground gate is open")
	expect(lift.request("up").is_empty(),"Lift accepts reachable next stop")
	await frames(70)
	expect(absf(game.player.position.y-lift.height)<0.055,"Standing rider follows rising deck")
	expect(not lift.gate.disabled,"Gate closes during travel")
	game.paused = true
	var snapshot: Dictionary = lift.capture()
	var player_y = game.player.position.y
	await frames(12)
	expect(is_equal_approx(snapshot.height,lift.height) and absf(game.player.position.y-player_y)<0.02,"Pause preserves deck and rider pose")
	lift.apply({"height":0.15,"destination":0.15,"moving":false})
	lift.apply(snapshot)
	expect(lift.capture() == snapshot and lift.validate(snapshot).is_empty(),"Midtravel current height and destination round-trip")
	expect(not lift.validate({"height":NAN,"destination":3.8,"moving":true}).is_empty(),"Nonfinite saved pose is rejected")
	game.paused = false
	await frames(260)
	expect(absf(lift.height-1.2)<0.001 and absf(game.player.position.y-1.2)<0.06,"Standing rider arrives at new 1.2 m work stop")
	capsule.height = 1.05
	col.position.y = 0.535
	await frames(4)
	expect(lift.request("down").is_empty(),"Down travel starts with crouching rider")
	await frames(320)
	expect(absf(lift.height-0.15)<0.001 and absf(game.player.position.y-0.15)<0.06,"Crouching rider returns on real moving floor")
	expect(lift.gate.disabled,"Gate opens again at ground")
	game.player.position = Vector3(0,0.03,4.0)
	game.player.velocity = Vector3(0,0,-1.5)
	await frames(130)
	game.player.velocity.z = 0
	await frames(4)
	expect(game.player.is_on_floor() and absf(game.player.position.y-0.15)<0.06 and game.player.position.z<1.4,"Ordinary walking boards ramp and open gate without jumping")
	var loose = RigidBody3D.new()
	loose.freeze = true
	loose.collision_layer = 2
	var loose_col = CollisionShape3D.new()
	var loose_shape = BoxShape3D.new()
	loose_shape.size = Vector3(0.12,0.12,0.12)
	loose_col.shape = loose_shape
	loose.add_child(loose_col)
	game.add_child(loose)
	loose.position = Vector3(0,3,0)
	await frames(4)
	expect(lift.request("stop2").is_empty() and lift.blocked_reason.is_empty(),"A loose solid far up the shaft never refuses the call")
	await until_held()
	expect(lift.moving and lift.motion_obstruction.get("collider") == loose and lift.blocked_reason.contains(str(loose.name)) and lift.height > 1.2 and lift.height+1.2 < 3.0,"Car holds short of the loose solid and names it: "+lift.blocked_reason)
	expect(lift.request("ground").is_empty(),"A held car accepts a new destination")
	await until_held()
	expect(not lift.moving and is_equal_approx(lift.height,0.15),"Held car returns to the ground on request")
	loose.queue_free()
	await frames(3)
	capsule.height = 1.7
	col.position.y = 0.86
	var ceiling = obstacle(Vector3(0,5.0,0),Vector3(1,0.1,1))
	await frames(3)
	expect(lift.request("stop2").is_empty(),"Overhead obstruction never refuses the call")
	await until_held()
	expect(lift.moving and not lift.blocked_reason.is_empty() and lift.height < 3.8 and game.player.global_position.y+1.72 < 4.95,"Car holds before the rider's head reaches the overhead obstruction")
	expect(lift.request("ground").is_empty(),"Rider sends the held car back down")
	await until_held()
	ceiling.queue_free()
	await frames(3)
	expect(lift.request("stop2").is_empty(),"Clear route can move again")
	await frames(40)
	var blocker = obstacle(Vector3(0,2.9,0),Vector3(0.5,0.12,0.5))
	await until_held()
	var blocked_height: float = lift.height
	await frames(15)
	expect(lift.moving and not lift.blocked_reason.is_empty() and is_equal_approx(lift.height,blocked_height) and blocked_height+1.72 < 2.84,"New midmotion obstacle holds platform safely below it")
	blocker.queue_free()
	await frames(310)
	expect(absf(lift.height-3.8)<0.001 and absf(game.player.position.y-3.8)<0.06,"Clearing obstruction resumes carrying")
	expect(lift.request("up").is_empty(),"Next stop selects 5.2 m work height")
	await frames(125)
	expect(absf(lift.height-5.2)<0.001 and absf(game.player.position.y-5.2)<0.06,"Rider reaches middle work height")
	expect(lift.request("up").is_empty(),"Next stop selects 8.7 m work height")
	await frames(300)
	expect(absf(lift.height-8.7)<0.001 and absf(game.player.position.y-8.7)<0.06,"Rider reaches highest work height")
	expect(connected_to_guides(),"Both carriage shoes remain physically engaged at highest stop")
	expect(lift.request("ground").is_empty(),"Ground call selects baseline from highest stop")
	await frames(710)
	expect(absf(lift.height-0.15)<0.001 and absf(game.player.position.y-0.15)<0.06 and lift.gate.disabled,"Full-height return preserves rider and opens entrance")
	var own_control = StaticBody3D.new()
	lift.deck.add_child(own_control)
	var control_col = CollisionShape3D.new()
	var control_shape = BoxShape3D.new()
	control_shape.size = Vector3(0.08,0.2,0.2)
	control_col.shape = control_shape
	control_col.position = Vector3(0.8,1.1,0.7)
	own_control.add_child(control_col)
	var held = RigidBody3D.new()
	held.freeze = true
	held.collision_layer = 2
	game.add_child(held)
	held.position = Vector3(1.2,1.1,0)
	var held_col = CollisionShape3D.new()
	var held_shape = BoxShape3D.new()
	held_shape.size = Vector3(0.3,0.3,0.3)
	held_col.shape = held_shape
	held.add_child(held_col)
	game.components = Holder.new()
	game.add_child(game.components)
	game.components.held_body = held
	var overhang = obstacle(Vector3(1.2,4.1,0),Vector3(0.12,0.15,0.12))
	await frames(4)
	expect(lift.request("stop2").is_empty(),"Carried overhang never refuses the call")
	await until_held()
	expect(lift.moving and lift.motion_obstruction.get("collider") == overhang and lift.height < 3.8,"Carried overhang separately checks external head clearance beyond deck")
	overhang.queue_free()
	await frames(3)
	await until_held()
	expect(not lift.moving and is_equal_approx(lift.height,3.8),"Actual rider may bring held solid and mounted controls on clear lift")
	lift.moving = false
	lift.destination = lift.height
	game.player.position.x = 4
	held.position.x = 0.6
	await frames(4)
	expect(lift.request("up").is_empty() and lift.motion_obstruction.get("kind") == "hand_load" and lift.motion_obstruction.get("collider") == held,"A held body is still an obstacle when its operator is off the lift")
	game.components.held_body = null
	held.queue_free()
	for lean in [[0.08,""],[0.18,""],[0.26,"Step back out of the lift doorway."]]:
		lift.apply({"height":3.8,"destination":3.8,"moving":false})
		# Physics sees the raised deck only after a step.
		await frames(2)
		game.player.velocity = Vector3.ZERO
		game.player.position = Vector3(1.0+0.26-float(lean[0]),0.03,0)
		await frames(8)
		expect(lift.request("ground").is_empty(),"Landing call accepted with the player leaning %.2f m into the shaft" % lean[0])
		await until_held()
		expect(lift.blocked_reason == lean[1],"Leaning %.2f m: '%s', got '%s'" % [lean[0],lean[1],lift.blocked_reason])
		if lean[1].is_empty():expect(not lift.moving and game.player.position.x > 1.25 and game.player.is_on_floor(),"Arriving car nudges the leaning player back onto the landing")
	expect(lift.height > 0.15+1.72,"A player in the doorway holds the car above their head")
	print("ACCESS LIFT ","PASS" if checks.all(func(c):return c.passed) else "FAIL", " ",checks.size()," checks")
	game.queue_free()
	await process_frame
	quit(0 if checks.all(func(c):return c.passed) else 1)
