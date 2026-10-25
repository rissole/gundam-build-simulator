extends RefCounted
## Convex chamfers and real shallow pockets INSIDE an existing box envelope.
## Surfaces are clockwise with explicit outward normals and metric face UVs.
## No CSG nodes, collision generation or runtime mesh updates.

static func box(size: Vector3, bevel: float, recesses: Dictionary = {}) -> ArrayMesh:
	var surface = SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h = size/2
	var b = minf(bevel,minf(h.x,minf(h.y,h.z))*.25)
	for axis in 3:
		var u = (axis+1)%3;var v = (axis+2)%3
		for sign_value in [-1.0,1.0]:
			var normal = Vector3.ZERO;normal[axis] = sign_value
			var key = str(axis)+("-" if sign_value<0 else "+")
			var pockets: Array = recesses.get(key,[])
			_face(surface,h,b,axis,u,v,normal,pockets)
	# Twelve edge strips connect the six inset face rectangles.
	for axis in 3:
		var u = (axis+1)%3;var v = (axis+2)%3
		for su in [-1.0,1.0]:
			for sv in [-1.0,1.0]:
				var corners: Array[Vector3] = []
				for end in [-1.0,1.0]:
					for outer_u in [true,false]:
						var p = Vector3.ZERO;p[axis] = end*(h[axis]-b)
						p[u] = su*(h[u] if outer_u else h[u]-b)
						p[v] = sv*(h[v]-b if outer_u else h[v])
						corners.append(p)
				var normal = Vector3.ZERO;normal[u]=su;normal[v]=sv
				_polygon(surface,[corners[0],corners[1],corners[3],corners[2]],normal.normalized(),h,Color(1,1,1,1))
	# Eight three-way corner facets close the box without overlapping faces.
	for sx in [-1.0,1.0]:
		for sy in [-1.0,1.0]:
			for sz in [-1.0,1.0]:
				var signs = Vector3(sx,sy,sz)
				var points: Array[Vector3] = []
				for axis in 3:
					var p = (h-Vector3.ONE*b)*signs;p[axis]=h[axis]*signs[axis];points.append(p)
				_polygon(surface,points,signs.normalized(),h,Color(1,1,1,1))
	surface.index();surface.generate_tangents()
	return surface.commit()

static func _face(surface: SurfaceTool, h: Vector3, bevel: float, axis: int, u: int, v: int, normal: Vector3, pockets: Array) -> void:
	var xs: Array[float] = [-h[u]+bevel,h[u]-bevel]
	var ys: Array[float] = [-h[v]+bevel,h[v]-bevel]
	for pocket in pockets:
		var rect: Rect2 = pocket.rect
		xs.append(rect.position.x);xs.append(rect.end.x)
		ys.append(rect.position.y);ys.append(rect.end.y)
	xs.sort();ys.sort()
	for ix in range(xs.size()-1):
		for iy in range(ys.size()-1):
			if xs[ix+1]-xs[ix]<.000001 or ys[iy+1]-ys[iy]<.000001:continue
			var middle = Vector2((xs[ix]+xs[ix+1])/2,(ys[iy]+ys[iy+1])/2)
			var depth = 0.0
			for pocket in pockets:
				if pocket.rect.has_point(middle):depth = pocket.depth
			var points: Array[Vector3] = []
			for uv in [Vector2(xs[ix],ys[iy]),Vector2(xs[ix+1],ys[iy]),Vector2(xs[ix+1],ys[iy+1]),Vector2(xs[ix],ys[iy+1])]:
				points.append(_point(axis,u,v,normal[axis]*(h[axis]-depth),uv))
			_polygon(surface,points,normal,h,Color(.50,.50,.50,0) if depth>0 else Color(1,1,1,0))
	for pocket in pockets:
		var rect: Rect2 = pocket.rect
		var ring = [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
		for i in 4:
			var a: Vector2=ring[i];var c: Vector2=ring[(i+1)%4]
			var inward = (rect.get_center()-(a+c)/2).normalized()
			var n = Vector3.ZERO;n[u]=inward.x;n[v]=inward.y
			_polygon(surface,[_point(axis,u,v,normal[axis]*h[axis],a),_point(axis,u,v,normal[axis]*h[axis],c),_point(axis,u,v,normal[axis]*(h[axis]-pocket.depth),c),_point(axis,u,v,normal[axis]*(h[axis]-pocket.depth),a)],n,h,Color(.65,.65,.65,0))

static func _point(axis: int, u: int, v: int, plane: float, uv: Vector2) -> Vector3:
	var p = Vector3.ZERO;p[axis]=plane;p[u]=uv.x;p[v]=uv.y;return p

static func _polygon(surface: SurfaceTool, points: Array, normal: Vector3, half: Vector3, tint: Color) -> void:
	# Godot's front winding is clockwise, opposite the outward cross product.
	if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal)>0:points.reverse()
	var axis = normal.abs().max_axis_index()
	var u = (axis+1)%3;var v = (axis+2)%3
	for i in range(1,points.size()-1):
		for p: Vector3 in [points[0],points[i],points[i+1]]:
			surface.set_normal(normal);surface.set_color(tint)
			surface.set_uv(Vector2(p[u],p[v]));surface.set_uv2(Vector2(half[u],half[v]))
			surface.add_vertex(p)
