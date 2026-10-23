extends "res://tests/kit/harness.gd"
## Real off-origin source geometry, camera-relative grips and solid obstruction.
var scene: Node3D

func _initialize() -> void:
	run.call_deferred()

func part(size: Vector3, source_pose: Transform3D) -> WorkshopPart:
	var box = BoxMesh.new()
	box.size = size
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.append_from(box,0,source_pose)
	var visual = MeshInstance3D.new()
	visual.mesh = surface.commit()
	var body = WorkshopPart.new()
	body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	body.freeze = true
	body.held = true
	body.collision_layer = 2
	body.collision_mask = 1
	scene.add_child(body)
	body.add_child(visual)
	for entry in SolidHandling.authored_shapes([],visual.mesh.get_aabb()):
		var collision = CollisionShape3D.new()
		collision.shape = entry.shape
		collision.transform = entry.transform
		body.add_child(collision)
	return body

func visual_center(body: WorkshopPart) -> Vector3:
	var visual: MeshInstance3D = body.get_child(0)
	return visual.global_transform*visual.mesh.get_aabb().get_center()

func aim_carry(body: WorkshopPart, camera: Transform3D, profile: Dictionary) -> void:
	body.carry_target = camera.origin+camera.basis*SolidHandling.carry_offset(body,camera.basis,profile)
	body.carry_basis = camera.basis*profile.get("basis",Basis.IDENTITY)

func run() -> void:
	scene = Node3D.new()
	root.add_child(scene)
	var source_pose = Transform3D(Basis.from_euler(Vector3(0.23,-0.41,0.17)),Vector3(0.45,-0.25,0.18))
	var hand = part(Vector3(0.4,0.2,0.25),source_pose)
	var grip = Basis.from_euler(Vector3(0.3,0.4,-0.2))
	var camera = Transform3D(Basis.from_euler(Vector3(-0.2,0.7,0)),Vector3(0,4,0))
	var profile = {"basis":grip,"lateral":0.63,"height":-0.34,"distance":1.25}
	aim_carry(hand,camera,profile)
	hand.global_transform = Transform3D(hand.carry_basis,hand.carry_target)
	var centered: Vector3 = camera.affine_inverse()*visual_center(hand)
	expect(absf(centered.x)<0.0001 and absf(centered.y)<0.0001 and is_equal_approx(centered.z,-1.25),"Rotated, off-origin source geometry centers at the authored forward distance")
	# The actual firm grip must follow between camera rotations, not just agree
	# with an offset formula at one settled pose.
	var follows_view = true
	for tick in 24:
		await process_frame
		camera.basis = Basis.from_euler(Vector3(-0.2+tick*0.004,0.7+tick*0.006,tick*0.002))
		await physics_frame
		aim_carry(hand,camera,profile)
		hand.update_grip(1.0/60)
		centered = camera.affine_inverse()*visual_center(hand)
		follows_view = follows_view and Vector2(centered.x,centered.y).length()<0.001
	expect(follows_view,"The collision-aware grip keeps the mesh centered during continuous camera rotation")
	profile = {"basis":grip,"offset":[0.8,-0.5,-1.6]}
	aim_carry(hand,camera,profile)
	hand.global_transform = Transform3D(hand.carry_basis,hand.carry_target)
	centered = camera.affine_inverse()*visual_center(hand)
	expect(centered.is_equal_approx(Vector3(0,0,-1.6)),"Legacy offset profiles retain forward distance while centering the geometry")
	var large = part(Vector3(3.6,0.4,1.7),Transform3D(Basis.IDENTITY,Vector3(-0.6,0.2,0.3)))
	large.position = Vector3(10,8,0)
	var large_center = SolidHandling.carry_offset(large,Basis.IDENTITY,{})+SolidHandling.bounds(large).get_center()
	var small_center = SolidHandling.carry_offset(hand,Basis.IDENTITY,{})+SolidHandling.bounds(hand).get_center()
	expect(absf(large_center.x)<0.0001 and absf(large_center.y)<0.0001 and large_center.z<small_center.z-1.0,"Large two-hand workpieces remain centered with size-aware forward clearance")
	expect(SolidHandling.bounds(large).size.is_equal_approx(Vector3(3.6,0.4,1.7)),"Centering preserves the workpiece's actual size and collision envelope")
	# Put the centered target beyond a real wall. The target is an intention;
	# physics may keep the solid object closer when there is no clear approach.
	camera = Transform3D(Basis.IDENTITY,Vector3(0,4,0))
	profile = {"distance":1.1}
	hand.global_transform = Transform3D(Basis.IDENTITY,camera.origin+Vector3(0,0,0.5)-SolidHandling.bounds(hand).get_center())
	var wall = StaticBody3D.new()
	wall.collision_layer = 1
	scene.add_child(wall)
	wall.position = Vector3(0,4,-0.8)
	var wall_shape = CollisionShape3D.new()
	wall_shape.shape = BoxShape3D.new()
	wall_shape.shape.size = Vector3(4,4,0.08)
	wall.add_child(wall_shape)
	await physics_frame
	await physics_frame
	aim_carry(hand,camera,profile)
	for tick in 30:
		hand.update_grip(1.0/60)
		await physics_frame
	var world_bounds: AABB = hand.global_transform*SolidHandling.bounds(hand)
	centered = camera.affine_inverse()*visual_center(hand)
	expect(world_bounds.position.z>=-0.765 and centered.z>-0.6 and centered.z<0.1,"Centered carry stops the mesh before a wall instead of pulling through scenery")
	expect(Vector2(centered.x,centered.y).length()<0.001,"A frontal obstacle limits forward travel without introducing a lateral grip offset")
	var excluded: Array[RID] = [hand.get_rid()]
	expect(not SolidHandling.sweep_error(hand,Transform3D(hand.carry_basis,hand.carry_target),excluded,1).is_empty(),"Placement sweep still rejects the obstructed centered destination")
	var passed = checks.all(func(check):return check.passed)
	DirAccess.make_dir_recursive_absolute("res://verification/centered-carry")
	write_evidence("res://verification/centered-carry/audit.json",{"passed":passed,"checks":checks,"engine":Engine.get_version_info().string})
	print("CENTERED_CARRY ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	scene.queue_free()
	await process_frame
	quit(0 if passed else 1)
