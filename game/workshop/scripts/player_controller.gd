extends RefCounted
## First-person body: creation, walking, crouch, jump and mouse look.
var game: Node

func _init(workshop: Node) -> void:
	game = workshop

func make() -> void:
	game.player = CharacterBody3D.new()
	game.player.name = "Player"
	game.player.collision_layer = 8
	game.player.collision_mask = game.WORLD_MASK
	game.add_child(game.player)
	game.player.position = Vector3(0.0,0.1,6.4)
	var col = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	game.player_collision = col
	capsule.radius = 0.26
	capsule.height = 1.7
	col.shape = capsule
	col.position.y = 0.86
	game.player.add_child(col)
	game.camera = Camera3D.new()
	game.camera.position.y = 1.63
	game.camera.near = 0.035
	game.camera.far = 60.0
	game.camera.fov = 75
	game.player.add_child(game.camera)
	game.camera.current = true

## `spawn` is [x, y, z, yaw]; an empty spawn keeps the default position.
func spawn(at: Array) -> void:
	if at.is_empty():return
	game.player.position = Vector3(at[0],at[1],at[2])
	game.player.rotation.y = at[3]

func movement_pressed(code: Key) -> bool:
	return bool(game.scripted_controls.get(code,false)) if game.automated_test else Input.is_physical_key_pressed(code)

func physics(delta: float) -> void:
	if not game.paused and not game.desktop_input.modal_active():
		update_crouch(movement_pressed(KEY_CTRL),delta)
		var move = Vector2(float(movement_pressed(KEY_D))-float(movement_pressed(KEY_A)),float(movement_pressed(KEY_S))-float(movement_pressed(KEY_W))).normalized()
		var direction = game.player.basis*Vector3(move.x,0,move.y)
		var speed = 4.5 if movement_pressed(KEY_SHIFT) else 2.8
		if game.crouched: speed = 1.5
		game.player.velocity.x = move_toward(game.player.velocity.x,direction.x*speed,delta*16)
		game.player.velocity.z = move_toward(game.player.velocity.z,direction.z*speed,delta*16)
	else:
		game.player.velocity.x = 0
		game.player.velocity.z = 0
	if game.jump_requested and not game.paused and not game.hud.browser.visible and game.player.is_on_floor():
		game.player.velocity.y = game.JUMP_SPEED
	elif not game.player.is_on_floor():game.player.velocity.y -= 14*delta
	else:game.player.velocity.y = -0.1
	# Airborne presses expire immediately; they cannot turn into a landing jump.
	game.jump_requested = false
	game.player.move_and_slide()

func look(relative: Vector2) -> void:
	game.player.rotate_y(-relative.x*0.0022)
	game.camera.rotation.x = clampf(game.camera.rotation.x-relative.y*0.0022,-1.35,1.35)

func update_crouch(wants_crouch: bool, delta: float) -> void:
	if game.crouched and not wants_crouch:
		var shape = CapsuleShape3D.new()
		shape.radius = 0.26
		# Leave a small floor clearance in this occupancy query. The movement
		# capsule remains full height; floor contact must not prevent standing.
		shape.height = 1.68
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(game.player.global_basis,game.player.global_position+Vector3.UP*0.87)
		query.collision_mask = game.WORLD_MASK
		var excluded: Array[RID] = [game.player.get_rid()]
		for body in game.bodies.values():
			if body.held:excluded.append(body.get_rid())
		if is_instance_valid(game.components.held_body):excluded.append(game.components.held_body.get_rid())
		query.exclude = excluded
		query.margin = 0.001
		wants_crouch = not game.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
	game.crouched = wants_crouch
	game.player_collision.shape.height = 1.0 if game.crouched else 1.7
	game.player_collision.position.y = 0.51 if game.crouched else 0.86
	game.camera.position.y = move_toward(game.camera.position.y,0.93 if game.crouched else 1.63,delta*4.5)
