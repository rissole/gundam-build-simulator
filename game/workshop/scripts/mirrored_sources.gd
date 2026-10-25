extends RefCounted
## Bake X reflection into source vertices and conjugate source poses. Runtime
## assembly/collision frames stay right handed, including during quaternion motion.
static func ensure(sources: Dictionary, alias: String, original: String) -> void:
	if sources.has(alias):return
	assert(sources.has(original),"Missing mirror source: "+original)
	var entry: Dictionary=sources[original]
	var reflection=Basis(Vector3.LEFT,Vector3.UP,Vector3.BACK)
	var at: Transform3D=entry.transform
	sources[alias]={"mesh":reflect_mesh(entry.mesh),"family":entry.family,"transform":Transform3D(reflection*at.basis*reflection,reflection*at.origin)}

static func reverse_faces(indices: PackedInt32Array) -> PackedInt32Array:
	var result=indices.duplicate()
	for i in range(0,result.size(),3):
		var swap=result[i+1];result[i+1]=result[i+2];result[i+2]=swap
	return result

static func reflect_mesh(original: Mesh) -> ArrayMesh:
	var mesh=ArrayMesh.new()
	var imported=ImporterMesh.from_mesh(original)
	for surface in range(original.get_surface_count()):
		var arrays: Array=original.surface_get_arrays(surface).duplicate(true)
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
		arrays[Mesh.ARRAY_INDEX]=reverse_faces(indices)
		var lods: Dictionary={}
		for level in imported.get_surface_lod_count(surface):
			lods[imported.get_surface_lod_size(surface,level)]=reverse_faces(imported.get_surface_lod_indices(surface,level))
		mesh.add_surface_from_arrays(imported.get_surface_primitive_type(surface),arrays,[],lods)
		mesh.surface_set_material(surface,original.surface_get_material(surface))
	mesh.shadow_mesh=make_shadow(mesh)
	return mesh

static func make_shadow(mesh: ArrayMesh) -> ArrayMesh:
	# Imported compressed position-only shadow surfaces cannot reliably be
	# decoded by surface_get_arrays. Rebuild welded positions from the readable
	# detailed mesh and remap the preserved LOD indices onto that topology.
	return shadow_from_importer(ImporterMesh.from_mesh(mesh)).get_mesh()

static func shadow_from_importer(imported: ImporterMesh) -> ImporterMesh:
	var shadow=ImporterMesh.new()
	# Shadow surfaces must match the main mesh one-for-one, even when their
	# materials are omitted. Merging these surfaces can crash Compatibility.
	for surface in imported.get_surface_count():
		var arrays: Array=imported.get_surface_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var unique: Dictionary={};var positions=PackedVector3Array();var remap=PackedInt32Array()
		for vertex in vertices:
			if not unique.has(vertex):unique[vertex]=positions.size();positions.append(vertex)
			remap.append(unique[vertex])
		var output: Array=[];output.resize(Mesh.ARRAY_MAX)
		output[Mesh.ARRAY_VERTEX]=positions
		output[Mesh.ARRAY_INDEX]=remap_indices(arrays[Mesh.ARRAY_INDEX],remap)
		var lods: Dictionary={}
		for level in imported.get_surface_lod_count(surface):
			lods[imported.get_surface_lod_size(surface,level)]=remap_indices(imported.get_surface_lod_indices(surface,level),remap)
		shadow.add_surface(imported.get_surface_primitive_type(surface),output,[],lods)
	return shadow

static func remap_indices(indices: PackedInt32Array, remap: PackedInt32Array) -> PackedInt32Array:
	var result=PackedInt32Array();result.resize(indices.size())
	for i in indices.size():result[i]=remap[indices[i]]
	return result

static func add(sources: Dictionary, aliases: Dictionary) -> void:
	for alias in aliases:ensure(sources,alias,aliases[alias])
