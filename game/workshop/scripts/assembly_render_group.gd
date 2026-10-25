extends Node
## Derived rendering for one rigid frame. Originals retain identity, collision and
## outline geometry; only their render layers change. No gameplay state lives here.
const CELL_SIZE = 1.0
const MAX_MEMBERS = 16
const PROXY_META = "assembly_render_proxy"
var frame: Node3D
var excluded: Array[MeshInstance3D] = []
var groups: Dictionary = {}
var inputs: Dictionary = {}
var task: int = -1
var job: Dictionary = {}
var pending: Array[String] = []

func setup(parent: Node3D, separate: Array[MeshInstance3D] = []) -> void:
	frame = parent
	excluded = separate
	name = "AssemblyRenderGroup"
	parent.add_child(self)
	parent.set_meta("assembly_render_group",self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	refresh()

func refresh() -> void:
	var cells: Dictionary = {}
	var live: Dictionary = {}
	for child in frame.get_children():
		if not child is MeshInstance3D or child.has_meta(PROXY_META) or child.has_meta("pickup_outline"):continue
		if child.mesh == null or excluded.has(child):continue
		live[child.get_instance_id()] = true
		if not child.has_meta("unbatched_layers"):child.set_meta("unbatched_layers",child.layers)
		# Unsupported individual effects remain separate. Authored visibility is
		# maintained by enclosure logic, not overridden by the batching system.
		if not child.visible or child.material_overlay != null or child.material_override != null or _has_surface_overrides(child):
			child.layers = child.get_meta("unbatched_layers")
			continue
		var center: Vector3 = child.transform * child.mesh.get_aabb().get_center()
		var cell := Vector3i((center / CELL_SIZE).floor())
		var key := "%s:%s:%s" % [cell,child.get_meta("unbatched_layers"),child.cast_shadow]
		if not cells.has(key):cells[key] = []
		cells[key].append(child)
	var desired: Dictionary = {}
	for cell in cells:
		var members: Array = cells[cell]
		for start in range(0,members.size(),MAX_MEMBERS):
			var pieces: Array = members.slice(start,start+MAX_MEMBERS)
			if pieces.size() < 2:
				for piece in pieces:piece.layers = piece.get_meta("unbatched_layers")
				continue
			var key: String = cell+":"+str(start/MAX_MEMBERS)
			var signature: Array = []
			for piece in pieces:signature.append([piece.get_instance_id(),piece.mesh.get_rid(),piece.transform])
			desired[key] = true
			if groups.has(key) and groups[key].signature == signature:continue
			_discard(key)
			groups[key] = {"signature":signature,"pieces":pieces,"proxy":null}
			if not pending.has(key):pending.append(key)
	for key in groups.keys():
		if not desired.has(key):_discard(key)
	# Do not retain source resources from every historical partial build.
	for id in inputs.keys():
		if not live.has(id):inputs.erase(id)

static func _has_surface_overrides(mesh: MeshInstance3D) -> bool:
	for surface in mesh.get_surface_override_material_count():
		if mesh.get_surface_override_material(surface) != null:return true
	return false

func _discard(key: String) -> void:
	if not groups.has(key):return
	var group: Dictionary = groups[key]
	for piece in group.pieces:
		if is_instance_valid(piece):piece.layers = piece.get_meta("unbatched_layers")
	if is_instance_valid(group.proxy):
		group.proxy.hide()
		group.proxy.queue_free()
	groups.erase(key)

func _process(_delta: float) -> void:
	if task >= 0:
		if not WorkerThreadPool.is_task_completed(task):return
		WorkerThreadPool.wait_for_task_completion(task)
		task = -1
		# An undo can invalidate an in-flight result. Keep originals until the
		# replacement corresponds exactly to the current installed pieces.
		if groups.has(job.key) and groups[job.key].signature == job.signature:
			var group: Dictionary = groups[job.key]
			var proxy := MeshInstance3D.new()
			proxy.name = "RenderBatch"
			proxy.set_meta(PROXY_META,true)
			proxy.mesh = job.mesh.get_mesh()
			proxy.mesh.shadow_mesh = job.shadow.get_mesh()
			proxy.layers = group.pieces[0].get_meta("unbatched_layers")
			proxy.cast_shadow = group.pieces[0].cast_shadow
			frame.add_child(proxy)
			group.proxy = proxy
			for piece in group.pieces:piece.layers = 0
		job = {}
	while not pending.is_empty():
		var key: String = pending.pop_front()
		if not groups.has(key) or is_instance_valid(groups[key].proxy):continue
		var group: Dictionary = groups[key]
		var meshes: Array[ImporterMesh] = []
		var transforms: Array[Transform3D] = []
		for piece in group.pieces:
			var id: int = piece.get_instance_id()
			if not inputs.has(id) or inputs[id].source != piece.mesh:
				inputs[id] = {"source":piece.mesh,"mesh":without_lods(piece.mesh)}
			meshes.append(inputs[id].mesh)
			transforms.append(piece.transform)
		job = {"key":key,"signature":group.signature,"meshes":meshes,"transforms":transforms}
		task = WorkerThreadPool.add_task(_compile.bind(job),false,"Assembly render group")
		break

static func without_lods(mesh: Mesh) -> ImporterMesh:
	var imported := ImporterMesh.new()
	for surface in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		var primitive: int = mesh.surface_get_primitive_type(surface) if mesh is ArrayMesh else Mesh.PRIMITIVE_TRIANGLES
		imported.add_surface(primitive,arrays,[],{},mesh.surface_get_material(surface))
	return imported

static func _compile(work: Dictionary) -> void:
	# CPU-only ImporterMesh work off the main thread. GPU resources are created
	# by get_mesh() on the main thread after completion. Native merge discards
	# input LODs, so regenerate them for the bounded merged groups.
	work.mesh = ImporterMesh.merge_importer_meshes(work.meshes,work.transforms)
	work.mesh.generate_lods(60,0,[])
	work.shadow = preload("res://scripts/mirrored_sources.gd").shadow_from_importer(work.mesh)

func busy() -> bool:
	return task >= 0 or not pending.is_empty()

func _exit_tree() -> void:
	if task >= 0:WorkerThreadPool.wait_for_task_completion(task)
	for key in groups.keys():_discard(key)
