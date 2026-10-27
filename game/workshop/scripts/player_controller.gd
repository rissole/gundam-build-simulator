extends RefCounted
## First-person body: creation, walking, crouch, jump and mouse look.
const Sweep = preload("res://scripts/motion_sweep.gd")
var game: Node

func _init(workshop: Node) -> void:
	game = workshop

func make() -> void:
	game.player = CharacterBody3D.new()
	game.player.name = "Player"
	game.player.collision_layer = 8
	game.player.collision_mask = game.WORLD_MASK
	ignore_platform_motion(game.player)
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

## Equipment carries its riders exactly (EquipmentRegistry.physics). The body's
## own floor-platform velocity would move them a second time, into the rails,
## and fling them on stepping off.
static func ignore_platform_motion(body: CharacterBody3D) -> void:
	body.platform_floor_layers = 0
	body.platform_wall_layers = 0
	body.platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_DO_NOTHING

## `spawn` is [x, y, z, yaw]; an empty spawn keeps the default position.
func spawn(at: Array) -> void:
	if at.is_empty():return
	game.player.position = Vector3(at[0],at[1],at[2])
	game.player.rotation.y = at[3]

func movement_pressed(code: Key) -> bool:
	return bool(game.scripted_controls.get(code,false)) if game.automated_test else Input.is_physical_key_pressed(code)

func physics(delta: float) -> void:
	var rope = game.equipment.get_equipment("rope_access")
	if rope!=null and rope.attached():
		_rope_physics(rope,delta)
		return
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
		var excluded: Array[RID] = [game.player.get_rid()]
		for body in game.bodies.values():
			if body.held:excluded.append(body.get_rid())
		if is_instance_valid(game.components.held_body):excluded.append(game.components.held_body.get_rid())
		var at = Transform3D(game.player.global_basis,game.player.global_position+Vector3.UP*0.87)
		wants_crouch = not Sweep.overlap(game.get_world_3d().direct_space_state,shape,at,game.WORLD_MASK,excluded,0.001).is_empty()
	game.crouched = wants_crouch
	game.player_collision.shape.height = 1.0 if game.crouched else 1.7
	game.player_collision.position.y = 0.51 if game.crouched else 0.86
	game.camera.position.y = move_toward(game.camera.position.y,0.93 if game.crouched else 1.63,delta*4.5)

## Rope movement uses the same capsule and collision mask as walking. No pose
## assignment, platform carrying or hand-load exception is involved.
func _rope_physics(rope: Node, delta: float) -> void:
	game.jump_requested=false
	game.player.velocity=Vector3.ZERO
	# The fixed booms are above a crouched worker, below a standing head. Use
	# ordinary crouch/uncrouch clearance before either ascent or boarding motion.
	update_crouch(rope.boarding_duck(game.player.global_position.y+delta*rope.SPEED),delta)
	if game.paused or game.desktop_input.modal_active():return
	var grounded: bool=rope.on_floor()
	var at: Vector3=game.player.global_position
	var anchor: Vector3=rope.anchor(rope.attachment)
	var deck: float=rope.deck_height(rope.attachment)
	var move=Vector2(float(movement_pressed(KEY_D))-float(movement_pressed(KEY_A)),float(movement_pressed(KEY_S))-float(movement_pressed(KEY_W))).normalized()
	var direction: Vector3=game.player.basis*Vector3(move.x,0,move.y)
	var vertical=float(movement_pressed(KEY_SPACE))-float(movement_pressed(KEY_CTRL))
	var target=at
	if rope.pull_in!=null:
		var outward: Vector3=rope.horizontal(anchor-rope.pull_in).normalized()
		target=rope.pull_in+outward*rope.PULL_GAP
		target.y=at.y # Lanyard holds this working height until G releases it.
	else:
		# At the top only, a narrow boarding corridor reaches the rear boom's
		# walkway. Below deck height WASD is strictly limited to 0.35 m slack.
		var boarding: bool=at.y>=deck-.08
		if boarding:
			var toward: Vector3=rope.deck_direction(rope.attachment)
			var side=Vector3(toward.z,0,-toward.x)
			var offset: Vector3=rope.horizontal(at-anchor)+direction*delta*1.0
			var along=clampf(offset.dot(toward),-rope.SLACK,2.6 if rope.stations[rope.attachment].edge=="rear" else .8)
			var across_limit=sqrt(maxf(0,rope.SLACK*rope.SLACK-minf(along,0)*minf(along,0)))
			var across=clampf(offset.dot(side),-across_limit,across_limit)
			target=anchor+toward*along+side*across
			target.y=at.y
			if not grounded and move.is_zero_approx():
				target.x=anchor.x;target.z=anchor.z
		elif grounded:
			target=at+direction*delta
			var offset: Vector3=rope.horizontal(target-anchor).limit_length(rope.SLACK)
			target.x=anchor.x+offset.x;target.z=anchor.z+offset.z
		else:
			rope.slack=(rope.slack+direction*delta*.5).limit_length(rope.SLACK)
			target=anchor+rope.slack;target.y=at.y
		# Do not descend alongside a two-metre boom: first draw to its plumb
		# line, with collisions, then pay out. Space still lifts from any floor.
		if vertical>0 or (vertical<0 and rope.horizontal(at-anchor).length()<=rope.SLACK+.01):
			target.y=clampf(at.y+vertical*rope.SPEED*delta,0,anchor.y-rope.HARNESS-rope.MIN_LENGTH)
	# The front davit is 0.15 m past the leaf edge, less than the capsule's
	# 0.26 m radius. Bias the line outward within its slack while passing the
	# deck, so ascent/descent does not require a precise sideways adjustment.
	if rope.pull_in==null and not grounded and rope.stations[rope.attachment].edge=="front" and at.y>deck-1.9 and (vertical!=0 or at.y<deck-.08 or move.is_zero_approx()):
		var toward: Vector3=rope.deck_direction(rope.attachment)
		var offset: Vector3=rope.horizontal(target-anchor)
		if offset.dot(toward)>-.14:offset-=toward*(offset.dot(toward)+.14)
		offset=offset.limit_length(rope.SLACK)
		target.x=anchor.x+offset.x;target.z=anchor.z+offset.z
		if vertical>0 and rope.horizontal(at-anchor).dot(toward)>-.13:target.y=at.y
	var horizontal: Vector3=rope.horizontal(target-at).limit_length(delta*rope.SPEED)
	_rope_move(horizontal)
	_rope_move(Vector3(0,target.y-game.player.global_position.y,0))
	# Establish floor contact without gravity/free fall. The locked length then
	# comes from the actual collision-resolved pose, including a deck landing.
	if grounded and vertical<=0:_rope_move(Vector3.DOWN*.015)
	rope.hanging=not rope.on_floor()
	if not rope.hanging:rope.pull_in=null
	rope.ropes[rope.attachment].length=clampf(anchor.y-game.player.global_position.y-rope.HARNESS,rope.MIN_LENGTH,rope.max_length(rope.attachment))

func _rope_move(motion: Vector3) -> void:
	if motion.is_zero_approx():return
	# A slide along a deck edge can shove the capsule beyond the slack circle
	# or under a landing. Stop at contact; subsequent input chooses a clear path.
	game.player.move_and_collide(motion)
