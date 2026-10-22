extends RefCounted
## Detect overlapping, same-facing coplanar mesh surfaces that can z-fight.
## Uses rendered triangles rather than box extents; contact on opposite faces and
## triangle edges is allowed. Different surfaces inside one node are not compared.

static func inspect(meshes: Array[MeshInstance3D], plane_tolerance: float = 0.00025, min_overlap_area: float = 0.000001) -> Array[Dictionary]:
	assert(plane_tolerance >= 0.0 and min_overlap_area >= 0.0)
	var geometry: Array[Dictionary] = []
	var occluders: Array[Dictionary] = []
	for instance in meshes:
		if not is_instance_valid(instance) or instance.mesh == null or not _visible(instance):
			continue
		var data := _extract(instance)
		if not data.triangles.is_empty():
			geometry.append(data)
			if instance.mesh is BoxMesh and _opaque_box(instance):
				var pose: Transform3D = data.pose
				if absf(pose.basis.determinant()) > 1e-12:
					occluders.append({"instance": instance, "inverse": pose.affine_inverse(),
						"half_size": instance.mesh.size.abs() * 0.5})
	var findings: Array[Dictionary] = []
	for i in range(geometry.size()):
		var a: Dictionary = geometry[i]
		for j in range(i + 1, geometry.size()):
			var b: Dictionary = geometry[j]
			if a.instance == b.instance or not _bounds_overlap(a, b, plane_tolerance):
				continue
			var evidence: Dictionary = {}
			var total_area := 0.0
			var pair_count := 0
			for ta in a.triangles:
				for tb in b.triangles:
					if ta.normal.dot(tb.normal) < 0.9999 or not _bounds_overlap(ta, tb, plane_tolerance):
						continue
					var depth := _plane_separation(ta, tb)
					if depth > plane_tolerance:
						continue
					var intersection := _intersection(ta.vertices, tb.vertices, ta.normal)
					var area: float = intersection.area
					if area <= min_overlap_area:
						continue
					if _occluded(intersection.polygon, ta, tb, a.instance, b.instance, occluders, plane_tolerance):
						continue
					pair_count += 1
					total_area += area
					if evidence.is_empty() or area > evidence.overlap_area:
						evidence = {
							"path_a": a.path, "path_b": b.path,
							"position_a": a.position, "position_b": b.position,
							"normal_a": ta.normal, "normal_b": tb.normal,
							"surface_a": ta.surface, "surface_b": tb.surface,
							"triangle_a": ta.triangle, "triangle_b": tb.triangle,
							"vertices_a": ta.vertices, "vertices_b": tb.vertices,
							"overlap_area": area, "depth_separation": depth,
						}
			if not evidence.is_empty():
				evidence["total_overlap_area"] = total_area
				evidence["triangle_pair_count"] = pair_count
				findings.append(evidence)
	return findings

static func _extract(instance: MeshInstance3D) -> Dictionary:
	# Reading global_transform outside a scene tree emits an engine error.
	var pose := instance.global_transform if instance.is_inside_tree() else _detached_transform(instance)
	var triangles: Array[Dictionary] = []
	var lower := Vector3(INF, INF, INF)
	var upper := Vector3(-INF, -INF, -INF)
	var orientation := -1.0 if pose.basis.determinant() >= 0.0 else 1.0
	for surface in range(instance.mesh.get_surface_count()):
		var primitive := Mesh.PRIMITIVE_TRIANGLES
		if instance.mesh is ArrayMesh:
			primitive = instance.mesh.surface_get_primitive_type(surface)
		if primitive != Mesh.PRIMITIVE_TRIANGLES and primitive != Mesh.PRIMITIVE_TRIANGLE_STRIP:
			continue
		var arrays := instance.mesh.surface_get_arrays(surface)
		if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
			continue
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var count := indices.size() if not indices.is_empty() else vertices.size()
		var step := 3 if primitive == Mesh.PRIMITIVE_TRIANGLES else 1
		for start in range(0, count - 2, step):
			var points := PackedVector3Array()
			for offset in range(3):
				var slot: int = start + offset
				if primitive == Mesh.PRIMITIVE_TRIANGLE_STRIP and start % 2 == 1 and offset < 2:
					slot = start + 1 - offset
				points.append(pose * vertices[indices[slot] if not indices.is_empty() else slot])
			var cross := (points[1] - points[0]).cross(points[2] - points[0])
			if cross.length_squared() <= 1e-20:
				continue
			var bounds := {"lower": points[0].min(points[1]).min(points[2]), "upper": points[0].max(points[1]).max(points[2])}
			lower = lower.min(bounds.lower)
			upper = upper.max(bounds.upper)
			triangles.append({"vertices": points, "normal": cross.normalized() * orientation,
				"surface": surface, "triangle": start / step,
				"lower": bounds.lower, "upper": bounds.upper})
	return {"instance": instance, "pose": pose, "path": str(instance.get_path()) if instance.is_inside_tree() else str(instance.name),
		"position": pose.origin, "triangles": triangles, "lower": lower, "upper": upper}

static func _visible(instance: MeshInstance3D) -> bool:
	if instance.is_inside_tree():
		return instance.is_visible_in_tree()
	var node: Node = instance
	while node != null:
		if node is Node3D and not node.visible:
			return false
		node = node.get_parent()
	return true

static func _opaque_box(instance: MeshInstance3D) -> bool:
	var material := instance.get_active_material(0)
	# Unknown shaders may discard pixels or displace vertices. Default material is
	# opaque; built-in transparent/alpha-scissored materials cannot prove coverage.
	return material == null or (material is StandardMaterial3D
		and material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED)

static func _occluded(polygon: PackedVector3Array, a: Dictionary, b: Dictionary,
		instance_a: MeshInstance3D, instance_b: MeshInstance3D,
		occluders: Array[Dictionary], tolerance: float) -> bool:
	var visible_points := PackedVector3Array()
	for point in polygon:
		# Polygon lies on A. Move beyond whichever face is closer to the viewer,
		# including a slightly tilted B plane, before testing opaque enclosure.
		var to_b: float = b.normal.dot(b.vertices[0] - point) / b.normal.dot(a.normal)
		visible_points.append(point + a.normal * (maxf(0.0, to_b) + maxf(0.0005, 2.0 * tolerance)))
	for box in occluders:
		if box.instance == instance_a or box.instance == instance_b:
			continue
		var covered := true
		for point in visible_points:
			var local: Vector3 = (box.inverse * point).abs()
			var half_size: Vector3 = box.half_size
			if local.x >= half_size.x - 1e-7 or local.y >= half_size.y - 1e-7 or local.z >= half_size.z - 1e-7:
				covered = false
				break
		# A convex box containing every polygon vertex contains the whole patch.
		# Partial coverage or coverage split across boxes is deliberately reported.
		if covered:
			return true
	return false

static func _detached_transform(node: Node3D) -> Transform3D:
	var pose := node.transform
	var parent := node.get_parent()
	while parent is Node3D and not node.top_level:
		pose = parent.transform * pose
		node = parent
		parent = parent.get_parent()
	return pose

static func _bounds_overlap(a: Dictionary, b: Dictionary, tolerance: float) -> bool:
	return (a.lower.x <= b.upper.x + tolerance and b.lower.x <= a.upper.x + tolerance
		and a.lower.y <= b.upper.y + tolerance and b.lower.y <= a.upper.y + tolerance
		and a.lower.z <= b.upper.z + tolerance and b.lower.z <= a.upper.z + tolerance)

static func _plane_separation(a: Dictionary, b: Dictionary) -> float:
	var distance := 0.0
	for vertex in b.vertices:
		distance = maxf(distance, absf(a.normal.dot(vertex - a.vertices[0])))
	for vertex in a.vertices:
		distance = maxf(distance, absf(b.normal.dot(vertex - b.vertices[0])))
	return distance

static func _intersection(a: PackedVector3Array, b: PackedVector3Array, normal: Vector3) -> Dictionary:
	# Drop the dominant normal axis, then restore world-space area afterwards.
	# Subtract a shared origin before clipping to keep arithmetic local.
	var axis := normal.abs().max_axis_index()
	var subject: Array[Vector2] = []
	var clip: Array[Vector2] = []
	for vertex in a:
		subject.append(_project(vertex - a[0], axis))
	for vertex in b:
		clip.append(_project(vertex - a[0], axis))
	var orientation := 1.0 if (clip[1] - clip[0]).cross(clip[2] - clip[0]) >= 0.0 else -1.0
	for edge in range(3):
		if subject.is_empty():
			return {"area": 0.0, "polygon": PackedVector3Array()}
		var output: Array[Vector2] = []
		var origin := clip[edge]
		var direction := clip[(edge + 1) % 3] - origin
		var previous := subject[-1]
		var previous_distance := direction.cross(previous - origin) * orientation
		for current in subject:
			var current_distance := direction.cross(current - origin) * orientation
			if (current_distance >= 0.0) != (previous_distance >= 0.0):
				output.append(previous.lerp(current, previous_distance / (previous_distance - current_distance)))
			if current_distance >= 0.0:
				output.append(current)
			previous = current
			previous_distance = current_distance
		subject = output
	if subject.size() < 3:
		return {"area": 0.0, "polygon": PackedVector3Array()}
	var area := 0.0
	for i in range(1, subject.size() - 1):
		area += (subject[i] - subject[0]).cross(subject[i + 1] - subject[0])
	var polygon := PackedVector3Array()
	for point in subject:
		var relative := Vector3(0.0, point.x, point.y) if axis == 0 else (
			Vector3(point.x, 0.0, point.y) if axis == 1 else Vector3(point.x, point.y, 0.0))
		relative[axis] = -normal.dot(relative) / normal[axis]
		polygon.append(a[0] + relative)
	return {"area": absf(area) * 0.5 / absf(normal[axis]), "polygon": polygon}

static func _project(point: Vector3, axis: int) -> Vector2:
	if axis == 0:
		return Vector2(point.y, point.z)
	if axis == 1:
		return Vector2(point.x, point.z)
	return Vector2(point.x, point.y)
