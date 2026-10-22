class_name AssemblyRuntime
extends RefCounted
## Scene projection of the ownership tree. Source meshes never stand in for item IDs.
var model: AssemblyModel
var sources: Dictionary
var nodes: Dictionary = {}
var source_frames: Dictionary = {}

func _init(shared: AssemblyModel, mesh_sources: Dictionary) -> void:
	model = shared
	sources = mesh_sources

func register_node(owner: String, body: Node3D, source_frame = null) -> void:
	nodes[owner] = body
	if source_frame != null:source_frames[owner] = source_frame
	body.set_meta("assembly_id",owner)

func node(owner: String) -> Node3D:
	return nodes.get(owner)

func definition(owner: String) -> Dictionary:
	return model.definitions.assemblies[model.assemblies[owner].definition]

func frame_source(owner: String) -> String:
	var d = definition(owner)
	if d.has("frame_source"):return d.frame_source
	return d.slots[d.root_slot].get("pose_source","") if d.has("root_slot") else ""

func source_to_local(owner: String) -> Transform3D:
	if source_frames.has(owner):return source_frames[owner]
	var reference = frame_source(owner)
	return sources[reference].transform.affine_inverse() if sources.has(reference) else Transform3D.IDENTITY

func frame_transform(owner: String) -> Transform3D:
	return node(owner).global_transform*source_to_local(owner)

func local_slot_pose(owner: String, sid: String) -> Transform3D:
	var slot = model.slot_definition(owner,sid)
	if slot.has("snap_position"):
		var rotation = vec(slot.get("snap_rotation_degrees",[0,0,0]))*PI/180.0
		return Transform3D(Basis.from_euler(rotation),vec(slot.snap_position))
	return source_to_local(owner)*sources[slot.pose_source].transform

func slot_pose(owner: String, sid: String) -> Transform3D:
	return node(owner).global_transform*local_slot_pose(owner,sid)

func mount_pose(parent: String, sid: String, child: String) -> Transform3D:
	# Assembly destinations place the child's logical frame (frame_source), which
	# can differ from its starting physical piece. A slot can explicitly nominate
	# a child anchor when it instead places a particular physical connection.
	var slot = model.slot_definition(parent,sid)
	var anchor: String = slot.get("child_anchor_slot","")
	var anchor_local = local_slot_pose(child,anchor) if not anchor.is_empty() else Transform3D.IDENTITY
	return slot_pose(parent,sid)*anchor_local.affine_inverse()

func descendants(owner: String, include_self: bool = true) -> Array[String]:
	var result: Array[String] = []
	if include_self:result.append(owner)
	for sid in model.assemblies[owner].slots:
		var uid: String = model.assemblies[owner].slots[sid]
		if not uid.is_empty() and model.slot_definition(owner,sid).has("assembly"):result.append_array(descendants(uid))
	return result

func mount(parent: String, sid: String, child: String) -> void:
	var body: Node3D = node(child)
	if body is RigidBody3D:
		for property in body.get_property_list():
			if property.name == "held":body.set("held",false);break
		body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		body.freeze = true
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
	elif body is AnimatableBody3D:
		body.sync_to_physics = false
	var destination = mount_pose(parent,sid,child)
	body.reparent(node(parent))
	body.global_transform = destination

func visual_pieces(owner: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var inverse = node(owner).global_transform.affine_inverse()
	for member in descendants(owner):
		for visual in node(member).get_children():
			if not visual is MeshInstance3D:continue
			if not visual.has_meta("component_uid") and not visual.has_meta("installed_uid") and not visual.has_meta("source_uid"):continue
			result.append({"visual":visual,"transform":inverse*visual.global_transform,"owner":member})
	return result

static func vec(values: Array) -> Vector3:
	return Vector3(values[0],values[1],values[2])
