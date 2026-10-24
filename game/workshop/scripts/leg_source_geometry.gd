class_name LegSourceGeometry
extends RefCounted
## Independent procedural blockout meshes in metres; never modifies FA-01.
## A source's local geometry and authored pose remain paired when copies swap.
const SEGMENTS = 64

static func add_sources(destination: Dictionary, content: Dictionary) -> void:
	for uid in content.get("sources", {}):
		var descriptor: Dictionary = content.sources[uid]
		var angles = vec(descriptor.get("rotation_degrees", [0, 0, 0])) * PI / 180.0
		destination[uid] = {"mesh": make_mesh(descriptor), "family": descriptor.family,
			"transform": Transform3D(Basis.from_euler(angles), vec(descriptor.position))}

static func make_mesh(descriptor: Dictionary) -> ArrayMesh:
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for shape in descriptor.primitives:
		var center = vec(shape.get("center", [0, 0, 0]))
		match shape.shape:
			"box":
				var mesh = BoxMesh.new()
				mesh.size = vec(shape.size)
				# Keep the builder unindexed until all primitives are appended.
				# append_from(BoxMesh) introduces indices that otherwise omit later
				# manually authored vertices at commit time.
				var faces = mesh.get_faces()
				for i in range(0, faces.size(), 3):
					var normal = -(faces[i + 1] - faces[i]).cross(faces[i + 2] - faces[i]).normalized()
					_triangle(surface, center + faces[i], center + faces[i + 1], center + faces[i + 2], normal)
			"sphere":
				_sphere(surface, center, shape.radius, PI, false)
			"hemisphere_shell":
				_sphere(surface, center, shape.outer, PI / 2.0, false)
				_sphere(surface, center, shape.inner, PI / 2.0, true)
				var outer = circle(shape.outer)
				var inner = circle(shape.inner)
				# The equatorial annulus closes the shell's material thickness.
				for i in range(SEGMENTS):
					var j = (i + 1) % SEGMENTS
					_quad(surface, center + Vector3(outer[i].x, 0, outer[i].y), center + Vector3(outer[j].x, 0, outer[j].y), center + Vector3(inner[j].x, 0, inner[j].y), center + Vector3(inner[i].x, 0, inner[i].y), Vector3.DOWN)
			"tube", "ring_plate":
				var start: float = shape.get("start_degrees", 0) * PI / 180.0
				var end: float = shape.get("end_degrees", 360) * PI / 180.0
				var contours: Array[PackedVector2Array] = []
				if end - start < TAU - .001:
					var boundary = PackedVector2Array()
					var count = int(SEGMENTS * (end - start) / TAU)
					for i in range(count + 1):
						var a = lerpf(start, end, float(i) / count)
						boundary.append(Vector2(cos(a), sin(a)) * shape.outer)
					for i in range(count, -1, -1):
						var a = lerpf(start, end, float(i) / count)
						boundary.append(Vector2(cos(a), sin(a)) * shape.inner)
					contours.append(boundary)
				else:
					contours.append(circle(shape.outer))
					if shape.inner > 0:
						contours.append(circle(shape.inner))
				_add_holes(contours, shape)
				_extrude(surface, contours, shape.length, _axis_basis(shape.get("axis", "y")), center)
			"plate":
				var size = vec(shape.size)
				if shape.get("axis", "y") is String and shape.get("axis", "y") == "x":
					size = Vector3(size.y, size.x, size.z)
				var contours: Array[PackedVector2Array] = [_rectangle(Vector2.ZERO, Vector2(size.x, size.z))]
				_add_holes(contours, shape)
				for opening in shape.get("rect_holes", []):
					contours.append(_rectangle(Vector2(opening[0], opening[1]), Vector2(opening[2], opening[3])))
				_extrude(surface, contours, size.y, _axis_basis(shape.get("axis", "y")), center)
	surface.index()
	return surface.commit()

static func _axis_basis(axis: Variant) -> Basis:
	if axis is Array:
		return Basis(Quaternion(Vector3.UP, vec(axis).normalized()))
	return Basis(Vector3.BACK, -PI / 2.0) if axis == "x" else Basis.IDENTITY

static func _rectangle(center: Vector2, size: Vector2) -> PackedVector2Array:
	return PackedVector2Array([center + Vector2(-size.x, -size.y) / 2,
		center + Vector2(size.x, -size.y) / 2, center + Vector2(size.x, size.y) / 2,
		center + Vector2(-size.x, size.y) / 2])

static func circle(radius: float, center: Vector2 = Vector2.ZERO, count: int = SEGMENTS) -> PackedVector2Array:
	var points = PackedVector2Array()
	for i in range(count):
		var a = TAU * i / count
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	return points

static func _add_holes(contours: Array[PackedVector2Array], shape: Dictionary) -> void:
	for opening in shape.get("holes", []):
		contours.append(circle(opening[2], Vector2(opening[0], opening[1]), 24))

static func _extrude(surface: SurfaceTool, contours: Array[PackedVector2Array], length: float, basis: Basis, center: Vector3) -> void:
	var points = PackedVector2Array()
	for contour in contours:
		points.append_array(contour)
	var triangles = Geometry2D.triangulate_delaunay(points)
	for i in range(0, triangles.size(), 3):
		var a = points[triangles[i]]
		var b = points[triangles[i + 1]]
		var c = points[triangles[i + 2]]
		var centroid = (a + b + c) / 3.0
		if not Geometry2D.is_point_in_polygon(centroid, contours[0]):
			continue
		var inside_hole = false
		for hole_index in range(1, contours.size()):
			if Geometry2D.is_point_in_polygon(centroid, contours[hole_index]):
				inside_hole = true
				break
		if inside_hole:
			continue
		for sign_value in [-1.0, 1.0]:
			var normal = basis * Vector3.UP * sign_value
			_triangle(surface, center + basis * Vector3(a.x, sign_value * length / 2.0, a.y),
				center + basis * Vector3(b.x, sign_value * length / 2.0, b.y),
				center + basis * Vector3(c.x, sign_value * length / 2.0, c.y), normal)
	for contour_index in range(contours.size()):
		var contour = contours[contour_index]
		for i in range(contour.size()):
			var a = contour[i]
			var b = contour[(i + 1) % contour.size()]
			var delta = b - a
			var normal = basis * Vector3(delta.y, 0, -delta.x).normalized()
			if contour_index > 0:
				normal = -normal
			_quad(surface, center + basis * Vector3(a.x, -length / 2, a.y),
				center + basis * Vector3(b.x, -length / 2, b.y),
				center + basis * Vector3(b.x, length / 2, b.y),
				center + basis * Vector3(a.x, length / 2, a.y), normal)

static func _sphere(surface: SurfaceTool, center: Vector3, radius: float, end: float, inward: bool) -> void:
	var rings = 24 if end > PI * .75 else 12
	for row in range(rings):
		var a = end * row / rings
		var b = end * (row + 1) / rings
		for column in range(SEGMENTS):
			var left = TAU * column / SEGMENTS
			var right = TAU * (column + 1) / SEGMENTS
			var v0 = Vector3(sin(a) * cos(left), cos(a), sin(a) * sin(left))
			var v1 = Vector3(sin(a) * cos(right), cos(a), sin(a) * sin(right))
			var v2 = Vector3(sin(b) * cos(right), cos(b), sin(b) * sin(right))
			var v3 = Vector3(sin(b) * cos(left), cos(b), sin(b) * sin(left))
			var normal = (v0 + v1 + v2 + v3).normalized() * (-1 if inward else 1)
			_quad(surface, center + v0 * radius, center + v1 * radius, center + v2 * radius, center + v3 * radius, normal)

static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	if (b - a).cross(c - a).length_squared() < 1e-18:
		return
	# Godot's exterior winding is clockwise.
	if (b - a).cross(c - a).dot(normal) > 0:
		var temporary = b
		b = c
		c = temporary
	for point in [a, b, c]:
		surface.set_normal(normal)
		surface.add_vertex(point)

static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	_triangle(surface, a, b, c, normal)
	_triangle(surface, a, c, d, normal)

static func vec(values: Array) -> Vector3:
	return Vector3(values[0], values[1], values[2])
