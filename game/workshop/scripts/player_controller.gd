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
	if game.paused or game.desktop_input.modal_active():rope.reset_motion();return
	var grounded: bool=rope.on_floor()
	var at: Vector3=game.player.global_position
	var anchor: Vector3=rope.anchor(rope.attachment)
	var deck: float=rope.deck_height(rope.attachment)
	var move=Vector2(float(movement_pressed(KEY_D))-float(movement_pressed(KEY_A)),float(movement_pressed(KEY_S))-float(movement_pressed(KEY_W))).normalized()
	var direction: Vector3=game.player.basis*Vector3(move.x,0,move.y)
	var vertical=float(movement_pressed(KEY_SPACE))-float(movement_pressed(KEY_CTRL))
	var boarding: bool=at.y>=deck-.08
	# Away from the boarding solids, use the actual harness-to-anchor radius.
	# Length changes move along that radius and retain its angle.
	if not grounded and rope.below_boarding(at):
		update_crouch(false,delta)
		_swing_physics(rope,direction,vertical,delta)
		return
	rope.reset_swing()
	# Draw underneath the long rear boom before paying out. Mid-swing travel
	# is unrestricted; this guard belongs only to the top boarding corridor.
	var can_travel: bool=vertical>0 or (vertical<0 and rope.horizontal(at-anchor).length()<=rope.SLACK+.01)
	var rise: float=rope.vertical_step(vertical if can_travel else 0.0,delta)
	update_crouch(rope.boarding_duck(at.y+maxf(0,rise)),delta)
	var target=at
	if boarding:
		var toward: Vector3=rope.deck_direction(rope.attachment)
		var side=Vector3(toward.z,0,-toward.x)
		var offset: Vector3=rope.horizontal(at-anchor)+direction*delta
		var along=clampf(offset.dot(toward),-rope.SLACK,2.6 if rope.stations[rope.attachment].edge=="rear" else .8)
		var across_limit=sqrt(maxf(0,rope.SLACK*rope.SLACK-minf(along,0)*minf(along,0)))
		var across=clampf(offset.dot(side),-across_limit,across_limit)
		target=anchor+toward*along+side*across;target.y=at.y
		if not grounded and move.is_zero_approx():target.x=anchor.x;target.z=anchor.z
	elif grounded:
		var offset: Vector3=rope.horizontal(at+direction*delta-anchor).limit_length(rope.SLACK)
		target=anchor+offset;target.y=at.y
	else:
		# The deck-clearance zone has no slack steering or pendulum motion.
		target.x=anchor.x;target.z=anchor.z
	if can_travel:target.y=clampf(at.y+rise,0,anchor.y-rope.HARNESS-rope.MIN_LENGTH)
	# The front davit sits less than a capsule radius beyond the leaf edge.
	if not grounded and rope.stations[rope.attachment].edge=="front" and at.y>deck-rope.BOARDING_CLEARANCE and (vertical!=0 or at.y<deck-.08 or move.is_zero_approx()):
		var toward: Vector3=rope.deck_direction(rope.attachment)
		var offset: Vector3=rope.horizontal(target-anchor)
		if offset.dot(toward)>-.14:offset-=toward*(offset.dot(toward)+.14)
		offset=offset.limit_length(rope.SLACK)
		target.x=anchor.x+offset.x;target.z=anchor.z+offset.z
		if vertical>0 and rope.horizontal(at-anchor).dot(toward)>-.13:target.y=at.y
	_rope_move(rope.horizontal(target-at).limit_length(delta*rope.TRAVERSE_SPEED))
	_rope_move(Vector3(0,target.y-game.player.global_position.y,0))
	if absf(game.player.global_position.y-at.y)+.001<absf(rise):rope.reset_motion()
	if grounded and vertical<=0:_rope_move(Vector3.DOWN*.015)
	rope.hanging=not rope.on_floor()
	rope.ropes[rope.attachment].length=clampf(rope.pose_length(rope.attachment,game.player.global_position),rope.MIN_LENGTH,rope.max_length(rope.attachment))

func _swing_physics(rope: Node, direction: Vector3, vertical: float, delta: float) -> void:
	var anchor: Vector3=rope.anchor(rope.attachment)
	var rise: float=rope.vertical_step(vertical,delta)
	# Recheck contact so removing/moving a surface cannot leave a floating brace.
	if not rope.brace_normal.is_zero_approx():
		var hit=KinematicCollision3D.new()
		if direction.dot(rope.brace_normal)<-.15 and game.player.test_move(game.player.global_transform,-rope.brace_normal*.025,hit) and hit.get_normal().dot(rope.brace_normal)>.9:
			rope.swing_velocity=Vector3.ZERO
			if is_zero_approx(rise):return
		rope.brace_normal=Vector3.ZERO
	# Small fixed maximum steps keep the curved path swept by the capsule,
	# including a long input tick. No position is assigned outside collision.
	var steps=maxi(1,ceili(delta/rope.SWING_STEP))
	var dt=delta/steps
	for step in steps:
		var at: Vector3=game.player.global_position
		var radial: Vector3=at+Vector3.UP*rope.HARNESS-anchor
		var normal=radial.normalized()
		var length=clampf(float(rope.ropes[rope.attachment].length)-rise/steps,rope.MIN_LENGTH,rope.max_length(rope.attachment))
		var velocity: Vector3=rope.swing_velocity.slide(normal)
		var damping: float=rope.SWING_RELEASE_DAMPING if direction.is_zero_approx() else rope.SWING_DAMPING
		var force: Vector3=(Vector3.DOWN*rope.SWING_RESTORE*length+direction*rope.SWING_PUMP).slide(normal)
		velocity=(velocity+force*dt)*exp(-damping*dt)
		var next=(normal*length+velocity*dt).normalized()*length
		var offset: Vector3=rope.horizontal(next)
		var cap: float=rope.swing_radius(length)
		if offset.length()>cap:
			offset=offset.limit_length(cap)
			next=offset-Vector3.UP*sqrt(maxf(0,length*length-cap*cap))
			var outward=offset.normalized().slide(next.normalized()).normalized()
			velocity-=outward*maxf(0,velocity.dot(outward))
		var target: Vector3=anchor+next-Vector3.UP*rope.HARNESS
		# Ascend back under the davit before entering its clearance zone.
		# This is a collision-resolved draw toward plumb, never a pose snap.
		if target.y>=rope.deck_height(rope.attachment)-rope.BOARDING_CLEARANCE and offset.length()>rope.SLACK:
			target.y=minf(at.y,rope.deck_height(rope.attachment)-rope.BOARDING_CLEARANCE-.001)
			velocity.y=minf(0,velocity.y)
		rope.swing_velocity=velocity
		var normals=_rope_move(target-at,rope,cap)
		# A contact may leave a slightly slack line; retain the resolved radius
		# rather than correcting through the obstacle on the next frame.
		var actual: Vector3=game.player.global_position+Vector3.UP*rope.HARNESS-anchor
		rope.ropes[rope.attachment].length=clampf(actual.length(),rope.MIN_LENGTH,rope.max_length(rope.attachment))
		rope.swing_velocity=rope.swing_velocity.slide(actual.normalized())
		for surface in normals:
			if rope.swing_velocity.dot(surface)<0:rope.swing_velocity=rope.swing_velocity.slide(surface)
			if direction.dot(surface)<-.15 and absf(surface.y)<.65:
				rope.brace_normal=surface;rope.swing_velocity=Vector3.ZERO
		if not normals.is_empty() and not is_zero_approx(rise):rope.reset_motion()
		rope.hanging=not rope.on_floor()
		if not rope.hanging:
			rope.reset_swing();break
		if not rope.brace_normal.is_zero_approx() and is_zero_approx(rise):break

func _rope_move(motion: Vector3, rope: Node=null, cap: float=0.0) -> Array[Vector3]:
	var normals: Array[Vector3]=[]
	for slide in (3 if rope!=null else 1):
		if rope!=null:
			# Sliding against an oblique wall must also stay inside the cap.
			var at: Vector3=game.player.global_position
			var anchor: Vector3=rope.anchor(rope.attachment)
			var offset: Vector3=rope.horizontal(at+motion-anchor).limit_length(cap)
			motion.x=anchor.x+offset.x-at.x;motion.z=anchor.z+offset.z-at.z
		if motion.is_zero_approx():break
		var hit=game.player.move_and_collide(motion)
		if hit==null:break
		var normal: Vector3=hit.get_normal()
		normals.append(normal)
		motion=hit.get_remainder().slide(normal)
		if rope!=null and rope.swing_velocity.dot(normal)<0:rope.swing_velocity=rope.swing_velocity.slide(normal)
	# Boarding stops at first contact to stay within the narrow gate corridor.
	return normals
