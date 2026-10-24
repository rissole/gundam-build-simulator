extends RefCounted
## Bake X reflection into source vertices and conjugate source poses. Runtime
## assembly/collision frames stay right handed, including during quaternion motion.
static func ensure(sources: Dictionary, alias: String, original: String) -> void:
	if sources.has(alias):return
	assert(sources.has(original),"Missing mirror source: "+original)
	var entry: Dictionary=sources[original]
	var mesh=ArrayMesh.new()
	for surface in range(entry.mesh.get_surface_count()):
		var arrays: Array=entry.mesh.surface_get_arrays(surface).duplicate(true)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		for i in range(vertices.size()):vertices[i].x=-vertices[i].x
		arrays[Mesh.ARRAY_VERTEX]=vertices
		if arrays[Mesh.ARRAY_NORMAL]!=null:
			var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			for i in range(normals.size()):normals[i].x=-normals[i].x
			arrays[Mesh.ARRAY_NORMAL]=normals
		if arrays[Mesh.ARRAY_TANGENT]!=null:
			var tangents: PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT]
			for i in range(0,tangents.size(),4):tangents[i]=-tangents[i];tangents[i+3]=-tangents[i+3]
			arrays[Mesh.ARRAY_TANGENT]=tangents
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		if indices.is_empty():
			for i in range(vertices.size()):indices.append(i)
		for i in range(0,indices.size(),3):
			var swap=indices[i+1];indices[i+1]=indices[i+2];indices[i+2]=swap
		arrays[Mesh.ARRAY_INDEX]=indices
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		mesh.surface_set_material(surface,entry.mesh.surface_get_material(surface))
	var reflection=Basis(Vector3.LEFT,Vector3.UP,Vector3.BACK)
	var at: Transform3D=entry.transform
	sources[alias]={"mesh":mesh,"family":entry.family,"transform":Transform3D(reflection*at.basis*reflection,reflection*at.origin)}

static func add(sources: Dictionary, aliases: Dictionary) -> void:
	for alias in aliases:ensure(sources,alias,aliases[alias])
