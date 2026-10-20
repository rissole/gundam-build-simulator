class_name WorkshopPart
extends RigidBody3D

var uid: String = ""
var kind: String = ""
var held: bool = false
var carry_target: Vector3
var carry_basis: Basis = Basis.IDENTITY

func _ready() -> void:
	continuous_cd = true
	mass = 2.0 if kind == "pad" else 0.15
	linear_damp = 1.2
	angular_damp = 3.0
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.8
	physics_material_override.bounce = 0.0

func update_grip(delta: float) -> void:
	if not held: return
	# A firm grip has no spring, momentum, or delayed angular response. Sweep
	# translation against scenery; only the short pickup approach is speed-limited.
	var collision = move_and_collide((carry_target-global_position).limit_length(12.0*delta))
	if collision:
		move_and_collide(collision.get_remainder().slide(collision.get_normal()))
	# Test intermediate orientations as well as the endpoint so turning beside
	# a wall cannot swing the held object through it.
	var from = global_basis.get_rotation_quaternion()
	var to = carry_basis.get_rotation_quaternion()
	var steps = maxi(1,ceili(from.angle_to(to)/deg_to_rad(3.0)))
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = (get_node("CollisionShape3D") as CollisionShape3D).shape
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.margin = 0.002
	for i in range(1,steps+1):
		var pose = Transform3D(Basis(from.slerp(to,float(i)/steps)),global_position)
		query.transform = pose
		if not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():break
		global_basis = pose.basis
