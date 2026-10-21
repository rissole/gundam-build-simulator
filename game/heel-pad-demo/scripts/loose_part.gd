class_name WorkshopPart
extends RigidBody3D

var uid: String = ""
var kind: String = ""
var held: bool = false
var carry_target: Vector3
var carry_basis: Basis = Basis.IDENTITY
var max_surface_travel: float = 0.025

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
