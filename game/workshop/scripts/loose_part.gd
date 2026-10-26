class_name WorkshopPart
extends RigidBody3D

var uid: String = ""
var kind: String = ""
var held: bool = false:
	set(value):
		held = value
		if not value:
			_recovering = false
			recovery_waiting = false
var carry_target: Vector3
var carry_basis: Basis = Basis.IDENTITY
var max_surface_travel: float = 0.025
## Separation is measured at the solid grip centre, not the imported mesh origin.
const RECOVERY_DISTANCE = 2.0
const RECOVERY_CLEARANCE = 0.003
var recovery_waiting: bool = false
var _recovering: bool = false

func recovery_distance() -> float:
	return RECOVERY_DISTANCE+minf(SolidHandling.bounds(self).size.length()*0.25,1.5)

func _recover_grip() -> bool:
	var desired = Transform3D(carry_basis,carry_target)
	var centre = SolidHandling.bounds(self).get_center()
	var separation = (global_transform*centre).distance_to(desired*centre)
	if not _recovering and separation <= recovery_distance():return false
	_recovering = true
	var excluded: Array[RID] = []
	SolidHandling.Sweep.collect_rids(self,excluded)
	for exception in get_collision_exceptions():excluded.append(exception.get_rid())
	var shapes: Array[Dictionary] = []
	SolidHandling.Sweep.collect_shapes(self,global_transform.affine_inverse(),shapes)
	# A small fixed search stays near the intended hands. It never grows until a
	# remote empty space is found. Only recovery bypasses the snagged travel path.
	for offset in [Vector3.ZERO,Vector3(0,.3,0),Vector3(.3,0,0),Vector3(-.3,0,0),Vector3(0,0,.3)]:
		var destination = desired
		destination.origin += carry_basis*offset
		var clear = true
		for entry in shapes:
			if not SolidHandling.Sweep.overlap(get_world_3d().direct_space_state,entry.shape,destination*entry.transform,collision_mask,excluded,RECOVERY_CLEARANCE).is_empty():
				clear = false
				break
		if not clear:continue
		# Kinematic setters schedule motion for the next physics step. Recovery is
		# a teleport: briefly use static freeze so no sweep/velocity bridges the
		# snagged path and descendants see the same pose immediately.
		var previous_mode = freeze_mode
		freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		global_transform = destination
		_sync_recovered_tree(self)
		freeze_mode = previous_mode
		_recovering = false
		recovery_waiting = false
		return true
	recovery_waiting = true
	return true

func _sync_recovered_tree(node: Node) -> void:
	if node is CollisionObject3D:
		node.force_update_transform()
		PhysicsServer3D.body_set_state(node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,node.global_transform)
	if node is RigidBody3D:
		node.linear_velocity = Vector3.ZERO
		node.angular_velocity = Vector3.ZERO
	for child in node.get_children():_sync_recovered_tree(child)

func _ready() -> void:
	continuous_cd = true
	mass = 2.0 if kind == "pad" else 0.15
	linear_damp = 1.2
	angular_damp = 3.0
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.8
	physics_material_override.bounce = 0.0

func update_grip(delta: float) -> void:
	if not held:
		_recovering = false
		recovery_waiting = false
		return
	if _recover_grip():return
	# A firm grip has no spring, momentum, or delayed angular response. Sweep
	# translation against scenery; only the short pickup approach is speed-limited.
	var collision = move_and_collide((carry_target-global_position).limit_length(12.0*delta))
	if collision:
		move_and_collide(collision.get_remainder().slide(collision.get_normal()))
	# Translation above already sweeps the held solid. A settled view has no
	# angular path to check; avoid stationary shape queries every physics tick.
	if global_basis.is_equal_approx(carry_basis):return
	# Long arms use finer angular increments according to their furthest solid.
	var from = global_basis.get_rotation_quaternion()
	var to = carry_basis.get_rotation_quaternion()
	var envelope = SolidHandling.bounds(self)
	var radius = envelope.get_center().length()+envelope.size.length()/2
	var steps = SolidHandling.sweep_steps(global_transform,Transform3D(carry_basis,global_position),radius,max_surface_travel)
	var excluded: Array[RID] = [get_rid()]
	for exception in get_collision_exceptions():excluded.append(exception.get_rid())
	for i in range(1,steps+1):
		var pose = Transform3D(Basis(from.slerp(to,float(i)/steps)),global_position)
		if not SolidHandling.sweep_error(self,pose,excluded,collision_mask,max_surface_travel).is_empty():break
		global_basis = pose.basis
