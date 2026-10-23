extends "res://tests/kit/harness.gd"
## Whole-workpiece discovery and placement cost through real rays and input.
class MeasuredTargeting:
	extends "res://scripts/targeting.gd"
	var placement_sweeps = 0
	func carry_placement_error(destination: Transform3D, carried: WorkshopPart = null, receiving: PhysicsBody3D = null) -> String:
		placement_sweeps += 1
		return super.carry_placement_error(destination,carried,receiving)

var game: Node
var driver: Node

func _initialize() -> void:
	run.call_deferred()

func look(point: Vector3, feet: Vector3) -> void:
	await PlayerDriver.new(game).stage_aim("snap discovery sightline",point,feet,3)

func wall(point: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = 1
	game.add_child(body)
	body.global_position = point
	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3.ONE*0.25
	body.add_child(collision)
	return body

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate()
	root.add_child(game)
	game.targeting = MeasuredTargeting.new(game)
	driver = load("res://tests/kit/node_runner.gd").new()
	root.add_child(driver)
	driver.game = game
	await driver.frames(10)
	game.automated_test = true
	game.set_paused(false)
	game.set_process(false)
	var sid = "pitch/FA-220__002"
	var kind: String = game.model.slot_definition("foot",sid).accepts
	game.components.collect(kind)
	var uid: String = game.model.held_item()
	var point: Vector3 = game.components.slot_point("foot",sid)
	var envelope: AABB = SolidHandling.bounds(game.foot)
	# Aim across the body's long axis, well outside the connection's 24 cm aim
	# radius. Feet remain west of the supported foot, clear of the platform.
	var broad_point: Vector3 = game.foot.global_transform*(envelope.get_center()+Vector3(0,0,0.8))
	var feet = Vector3(-0.6,0.025,broad_point.z)
	await look(broad_point,feet)
	expect(game.targeting.aim_score(point,0.24) == INF,"Workpiece aim is outside the old narrow ring-clevis target")
	expect(game.target.get("sid","") == sid and game.target.get("discovery_only",false) and game.ghost.visible and game.ghost_material.albedo_color == game.SNAP_DISTANT_COLOR,"Aiming at the foot's box reveals the carried ring-clevis destination")
	game.targeting.placement_sweeps = 0
	game.automation.refresh_target()
	expect(game.targeting.placement_sweeps == 0 and game.interaction_outline.copies.is_empty(),"Whole-workpiece guidance performs no placement sweep or whole-foot outline duplication")
	driver.click()
	expect(game.model.held_item() == uid and game.model.assemblies.foot.slots[sid].is_empty(),"Broad discovery cannot attach the ring clevis")
	# The viewed body and the destination are separate sightlines; blocking
	# either with unrelated scenery must suppress discovery.
	var aim_hit: Variant = game.targeting.assembly_discovery_hit("foot")
	expect(aim_hit != null,"The view ray intersects the actual workpiece bounds")
	if aim_hit != null:
		var obstruction = wall(game.camera.global_position.lerp(aim_hit,0.6))
		await driver.frames(3)
		game.automation.refresh_target()
		expect(not game.ghost.visible,"Scenery in front of the aimed workpiece hides broad guidance")
		obstruction.queue_free()
		await driver.frames(3)
	await look(broad_point,feet)
	var blocker = wall(game.camera.global_position.lerp(point,0.7))
	await driver.frames(3)
	game.automation.refresh_target()
	expect(not game.ghost.visible,"Scenery on the connection sightline hides broad guidance")
	blocker.queue_free()
	await driver.frames(3)
	await look(broad_point+Vector3.UP*3,feet)
	expect(not game.ghost.visible,"Looking outside the workpiece box hides discovery")
	await look(broad_point,Vector3(-5,0.025,broad_point.z))
	expect(not game.ghost.visible,"Whole-workpiece discovery retains its six-metre range")
	await look(broad_point,feet)
	game.foot_fixture.moving = true
	game.automation.refresh_target()
	expect(not game.ghost.visible,"Moving equipment cannot advertise a broad attachment destination")
	game.foot_fixture.moving = false
	# Close to the foot but away from the socket: guidance remains yellow and
	# explicitly asks for precise aim rather than incorrectly saying closer.
	var near_feet = Vector3(point.x-1.0,0.025,broad_point.z)
	await look(broad_point,near_feet)
	expect(game.camera.global_position.distance_to(point) < game.REACH and game.target.get("discovery_only",false) and game.ghost.visible and game.hud.target_label.text.contains("Aim at the highlighted connection"),"Nearby broad aim stays yellow and explains how to focus the connection")
	driver.click()
	expect(game.model.held_item() == uid and game.model.assemblies.foot.slots[sid].is_empty(),"Being within reach does not turn body-wide guidance into remote attachment")
	# Park the physical piece at the destination to remove unrelated travel
	# obstructions, then exercise real targeting and its single collision sweep.
	await look(point,Vector3(point.x-1.0,0.025,point.z))
	game.components.held_body.global_transform = game.components.slot_pose("foot",sid)
	game.targeting.placement_sweeps = 0
	game.automation.refresh_target()
	expect(game.target.get("sid","") == sid and not game.target.get("discovery_only",false) and game.ghost.visible and game.ghost_material.albedo_color == game.SNAP_READY_COLOR,"Precise reachable aim takes priority and restores the green preview")
	expect(game.targeting.placement_sweeps == 1,"One targeting update shares one approach sweep between prompt and preview")
	expect(game.interaction_outline.copies.is_empty(),"Precise placement feedback never duplicates the receiving foot meshes")
	# A fresh obstruction after feedback must be detected by the click itself.
	blocker = wall(game.components.held_body.global_position)
	await driver.frames(2)
	game.components.held_body.global_transform = game.components.slot_pose("foot",sid)
	game.targeting.placement_sweeps = 0
	driver.click()
	expect(game.targeting.placement_sweeps == 1 and game.model.assemblies.foot.slots[sid].is_empty(),"Actual placement reruns collision checks instead of trusting cached feedback")
	blocker.queue_free()
	await driver.frames(3)
	game.components.drop(true)
	# A ready screw cannot be discovered before its washer is installed.
	game.model.stock_pocket("h-24070")
	await look(broad_point,feet)
	expect(not game.ghost.visible,"Missing construction prerequisites never produce broad yellow guidance")
	# Rotation changes the world box through the body's transform, with no new
	# collider, invisible future-part volume or per-frame mesh scan.
	game.components.collect(kind)
	var original: Transform3D = game.foot.global_transform
	game.foot.rotate_z(0.35)
	envelope = SolidHandling.bounds(game.foot)
	broad_point = game.foot.global_transform*(envelope.get_center()+Vector3(0,0,0.8))
	await look(broad_point,Vector3(-0.6,0.025,broad_point.z))
	expect(game.target.get("sid","") == sid and game.target.get("discovery_only",false) and game.ghost.visible,"Whole-workpiece discovery follows the rotated fixture's bounds")
	game.foot.global_transform = original
	var passed = checks.all(func(check):return check.passed)
	DirAccess.make_dir_recursive_absolute("res://verification/snap-discovery")
	write_evidence("res://verification/snap-discovery/audit.json",{"passed":passed,"checks":checks,"rendered":false})
	print("SNAP_DISCOVERY ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
