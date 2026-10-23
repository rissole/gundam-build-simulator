extends "res://tests/kit/harness.gd"

const Audit = preload("res://tests/geometry_surface_audit.gd")
var fixture: Node3D

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_reset()
	var a := _box("PartialA", Vector3.ONE, Vector3.ZERO)
	var b := _box("PartialB", Vector3.ONE, Vector3(0.6, 0.2, 0.0))
	var found := Audit.inspect([a, b])
	expect(found.size() == 1, "Partially overlapping coplanar box faces produce one mesh-pair finding")
	if not found.is_empty():
		expect(found[0].overlap_area > 0.0 and found[0].triangle_pair_count >= 2,
			"Finding contains positive triangle overlap with compact pair grouping")
		expect(str(found[0].path_a).contains("PartialA") and found[0].vertices_a.size() == 3
			and found[0].normal_a.length() > 0.99 and found[0].surface_a >= 0
			and found[0].triangle_a >= 0 and found[0].position_b.is_equal_approx(b.global_position),
			"Finding identifies world geometry, node paths and source triangle")

	_reset()
	a = _box("NearA", Vector3.ONE, Vector3.ZERO)
	b = _box("NearB", Vector3.ONE, Vector3(0.6, 0.2, 0.0001))
	found = Audit.inspect([a, b])
	expect(found.size() == 1 and found[0].depth_separation > 0.00009,
		"Faces separated by 0.1 mm are included in the default 0.25 mm tolerance")
	expect(Audit.inspect([a, b], 0.00001).is_empty(), "Caller may tighten the plane tolerance")
	b.position.z = 0.002
	expect(Audit.inspect([a, b]).is_empty(), "A meaningful 2 mm face offset is allowed")

	_reset()
	a = _box("EdgeA", Vector3.ONE, Vector3.ZERO)
	b = _box("EdgeB", Vector3.ONE, Vector3(1.0, 0.0, 0.0))
	expect(Audit.inspect([a, b]).is_empty(), "Butt joint has opposite contact normals and only edge contact on same-facing sides")
	b.position = Vector3(1.0, 1.0, 0.0)
	expect(Audit.inspect([a, b]).is_empty(), "Box edges may touch without positive surface overlap")

	# The user's lower harness failure: runner and wheel fronts both at z=1.9,
	# despite different heights and sizes. Their positive face overlap must fail.
	_reset()
	a = _box("HarnessRunner", Vector3(0.14, 0.18, 3.8), Vector3(0.9, 0.17, 0.0))
	b = _box("HarnessWheel", Vector3(0.25, 0.15, 0.34), Vector3(0.9, 0.105, 1.73))
	found = Audit.inspect([a, b])
	expect(found.size() == 1 and found[0].total_overlap_area > 0.01,
		"Original lower harness runner/wheel fixture exposes the coplanar front-face defect")
	var floor := _box("DistantFloor", Vector3(5, 0.3, 5), Vector3(0, -0.15, 0))
	expect(Audit.inspect([a, b, floor]).size() == 1,
		"An opaque floor beneath the harness does not suppress its exposed front-face defect")

	_reset()
	a = _box("RestingA", Vector3.ONE, Vector3(0, 0.5, 0))
	b = _box("RestingB", Vector3(1, 0.6, 1), Vector3(0.3, 0.3, 0.3))
	expect(Audit.inspect([a, b]).size() == 1,
		"Overlapping resting boxes expose a shared underside without a covering floor")
	floor = _box("OpaqueFloor", Vector3(5, 0.3, 5), Vector3(0, -0.15, 0))
	expect(Audit.inspect([a, b, floor]).is_empty(),
		"Shared undersides fully enclosed beyond their visible face by an opaque floor are suppressed")
	floor.mesh.size.x = 0.3
	expect(Audit.inspect([a, b, floor]).size() == 1,
		"A floor covering only part of an overlap polygon cannot suppress the exposed remainder")
	floor.mesh.size.x = 5.0
	fixture.rotation = Vector3(0.4, -0.35, 0.2)
	fixture.scale = Vector3(-1.3, 0.8, 1.2)
	expect(Audit.inspect([a, b, floor]).is_empty(),
		"A rotated and reflected floor proves enclosure in its local box coordinates")
	var transparent := StandardMaterial3D.new()
	transparent.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	transparent.albedo_color.a = 0.5
	floor.material_override = transparent
	expect(Audit.inspect([a, b, floor]).size() == 1,
		"Transparent material override cannot prove opaque occlusion")
	floor.material_override = null
	floor.set_surface_override_material(0, transparent)
	expect(Audit.inspect([a, b, floor]).size() == 1,
		"Transparent surface material override cannot prove opaque occlusion")
	floor.set_surface_override_material(0, StandardMaterial3D.new())
	expect(Audit.inspect([a, b, floor]).is_empty(),
		"An explicitly opaque standard material proves floor coverage")
	floor.set_surface_override_material(0, ShaderMaterial.new())
	expect(Audit.inspect([a, b, floor]).size() == 1,
		"An unknown shader material cannot prove opaque occlusion")
	floor.set_surface_override_material(0, null)
	floor.visible = false
	expect(Audit.inspect([a, b, floor]).size() == 1,
		"An invisible floor cannot hide the overlapping surfaces")

	# Mesh node local coordinates alone cannot expose these overlaps. Include a
	# reflected, nonuniformly scaled parent, plus a separate nested child transform.
	_reset()
	fixture.position = Vector3(3.5, -2.0, 7.0)
	fixture.rotation = Vector3(0.37, -0.62, 0.21)
	fixture.scale = Vector3(-1.4, 0.7, 2.0)
	var nested := Node3D.new()
	nested.name = "Nested"
	nested.position = Vector3(0.2, -0.3, 0.1)
	nested.rotation = Vector3(0.2, 0.35, -0.1)
	fixture.add_child(nested)
	a = _box("RotatedA", Vector3.ONE, Vector3.ZERO, nested)
	b = _box("RotatedB", Vector3.ONE, Vector3(0.6, 0.2, 0.0), nested)
	expect(Audit.inspect([a, b]).size() == 1, "Rotated nested meshes under reflected nonuniform parent scale retain overlap")
	# Reflect just one cube: its outward faces must still match the unreflected cube.
	b.scale.x = -1.0
	expect(Audit.inspect([a, b]).size() == 1, "Independent negative mesh scale preserves face orientation")

	_reset()
	var triangle := PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 2, 0), Vector3(2, 0, 0)])
	a = _triangles("IndexedTriangle", triangle, PackedInt32Array([0, 1, 2]))
	b = _triangles("UnindexedTriangle", triangle)
	b.position = Vector3(0.2, 0.2, 0.0)
	found = Audit.inspect([a, b])
	expect(found.size() == 1 and absf(found[0].total_overlap_area - 1.28) < 0.00001,
		"Indexed/unindexed rendered triangles have the expected geometric intersection area")
	b.mesh = _array_mesh(PackedVector3Array([Vector3(2, 2, 0), Vector3(2, 0.9, 0), Vector3(0.9, 2, 0)]))
	b.position = Vector3.ZERO
	expect(Audit.inspect([a, b]).is_empty(), "Overlapping triangle AABBs without polygon overlap are allowed")
	b.mesh = _array_mesh(PackedVector3Array([triangle[0], triangle[2], triangle[1]]))
	expect(Audit.inspect([a, b]).is_empty(), "Opposite-facing coplanar triangles form a valid butt joint")
	b.mesh = _array_mesh(triangle)
	b.position = Vector3(2, 0, 0)
	expect(Audit.inspect([a, b]).is_empty(), "Triangle vertex-only contact has zero overlap area")
	b.position = Vector3(1, 1, 0)
	expect(Audit.inspect([a, b]).is_empty(), "Triangle edge-only contact has zero overlap area")

	_reset()
	# Two overlapping sloping wedge panels: no axis-aligned face assumption.
	var wedge := PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 1, 1), Vector3(2, 0, 0),
		Vector3(0, 0, 0), Vector3(2, 0, 0), Vector3(0, 0, 1)])
	a = _triangles("IndexedWedge", wedge, PackedInt32Array([0, 1, 2, 3, 4, 5]))
	b = _triangles("UnindexedWedge", wedge)
	b.position = Vector3(0.2, 0, 0)
	found = Audit.inspect([a, b])
	expect(found.size() == 1 and absf(found[0].normal_a.y) > 0.6 and absf(found[0].normal_a.z) > 0.6,
		"Sloped indexed and unindexed wedge faces supply the largest overlap evidence")
	if not found.is_empty():
		expect(absf(found[0].total_overlap_area - 0.81 * (1.0 + sqrt(2.0))) < 0.00001,
			"Projection restores actual world-space area for sloped faces")

	_reset()
	triangle = PackedVector3Array([Vector3(-1, -1, 0), Vector3(0, 2, 0), Vector3(1, -1, 0)])
	a = _triangles("Flat", triangle)
	b = _triangles("Crossing", triangle)
	b.rotation.x = 0.005
	expect(Audit.inspect([a, b]).is_empty(), "Intersecting planes with coincident centroids must pass every vertex's plane tolerance")

	_reset()
	var many: Array[MeshInstance3D] = []
	for i in range(350):
		many.append(_box("Performance_%d" % i, Vector3.ONE, Vector3(i % 20, i / 20, 0) * 1.1))
	var started := Time.get_ticks_msec()
	expect(Audit.inspect(many).is_empty(), "Broad phase permits a workshop-sized set of separate meshes")
	var elapsed := Time.get_ticks_msec() - started
	expect(elapsed < 15000, "350-mesh audit completes within 15 seconds (actual %d ms)" % elapsed)
	print("GEOMETRY_AUDIT_PERFORMANCE %d ms / 350 meshes" % elapsed)
	var passed := true
	for check in checks:
		passed = passed and check.passed
	print(("PASS" if passed else "FAIL") + " %d checks" % checks.size())
	fixture.free()
	quit(0 if passed else 1)

func _reset() -> void:
	if is_instance_valid(fixture):
		fixture.free()
	fixture = Node3D.new()
	fixture.name = "GeometryAuditFixture"
	root.add_child(fixture)

func _box(label: String, size: Vector3, position: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _instance(label, mesh, position, parent)

func _triangles(label: String, vertices: PackedVector3Array, indices: PackedInt32Array = PackedInt32Array()) -> MeshInstance3D:
	return _instance(label, _array_mesh(vertices, indices), Vector3.ZERO)

func _array_mesh(vertices: PackedVector3Array, indices: PackedInt32Array = PackedInt32Array()) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	if not indices.is_empty():
		arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _instance(label: String, mesh: Mesh, position: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.position = position
	(parent if parent != null else fixture).add_child(node)
	return node
