extends Node3D
## Pickup contours reuse a bounded pool. Each contour inherits its source mesh's
## pose and visibility; focus never copies transforms or changes source materials.
const CACHE_LIMIT = 4
const OUTLINE_META = "pickup_outline"
var focused: Node3D
var copies: Dictionary = {}
var outline_material: ShaderMaterial
var _cache: Dictionary = {}
var _sequence = 0

func _init() -> void:
	outline_material = ShaderMaterial.new()
	outline_material.shader = preload("res://scripts/interaction_outline.gdshader")

func clear() -> void:
	if focused == null and copies.is_empty():return
	focused = null
	visible = false
	for entry in copies.values():
		if is_instance_valid(entry.outline):entry.outline.visible = false
	copies = {}

func focus(object: Node3D) -> void:
	if not is_instance_valid(object):
		clear()
		return
	for key in _cache.keys():
		if not is_instance_valid(_cache[key].object):_evict(key)
	if focused != object:clear()
	var key = object.get_instance_id()
	if not _cache.has(key):
		if _cache.size() >= CACHE_LIMIT:
			var oldest = _cache.keys()[0]
			for candidate in _cache:
				if _cache[candidate].used < _cache[oldest].used:oldest = candidate
			_evict(oldest)
		_cache[key] = {"object":object,"sources":[],"copies":{},"watches":[],"dirty":true,"revision":-1,"used":0}
	var entry: Dictionary = _cache[key]
	_sequence += 1
	entry.used = _sequence
	if entry.dirty or entry.revision != object.get_meta("visual_revision",0) or _sources_changed(entry):
		_rebuild(key,entry)
	focused = object
	visible = true
	copies = entry.copies
	for record in copies.values():
		if not record.outline.visible:record.outline.visible = true

func _sources_changed(entry: Dictionary) -> bool:
	# Resource edits invalidate through signals. Instance-level replacements do
	# not emit Resource.changed, so compare cheap handles without scanning trees,
	# querying active materials or setting renderer properties on stable focus.
	for record in entry.sources:
		var source = record.source
		if not is_instance_valid(source):return true
		if source.mesh != record.mesh or source.material_override != record.override:return true
		if source.get_surface_override_material_count() != record.surfaces.size():return true
		for i in record.surfaces.size():
			if source.get_surface_override_material(i) != record.surfaces[i]:return true
		# BaseMaterial3D rendering setters do not all emit Resource.changed.
		# Check cached depth modes without resolving active materials again.
		for depth in record.depth_modes:
			if depth.material.transparency != depth.mode:return true
	return false

func _rebuild(key: int, entry: Dictionary) -> void:
	_disconnect(entry)
	var sources: Array[MeshInstance3D] = []
	_collect(entry.object,sources,key,entry)
	var previous: Dictionary = entry.copies
	entry.copies = {}
	entry.sources = []
	for source in sources:
		var surfaces: Array = []
		for i in source.get_surface_override_material_count():surfaces.append(source.get_surface_override_material(i))
		var depth_modes: Array = []
		entry.sources.append({"source":source,"mesh":source.mesh,"override":source.material_override,"surfaces":surfaces,"depth_modes":depth_modes})
		if source.mesh == null:continue
		_watch(source.mesh,"changed",_invalidate.bind(key),entry)
		for i in source.mesh.get_surface_count():
			var material = source.get_active_material(i)
			_watch(material,"changed",_invalidate.bind(key),entry)
			if material is BaseMaterial3D:depth_modes.append({"material":material,"mode":material.transparency})
		if not _writes_depth(source):continue
		var id = source.get_instance_id()
		var contour: MeshInstance3D
		if previous.has(id) and is_instance_valid(previous[id].outline):
			contour = previous[id].outline
			previous.erase(id)
		else:
			contour = MeshInstance3D.new()
			contour.set_meta(OUTLINE_META,true)
			contour.material_override = outline_material
			contour.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			contour.extra_cull_margin = 0.04
			contour.visible = false
			source.add_child(contour)
		if contour.mesh != source.mesh:contour.mesh = source.mesh
		entry.copies[id] = {"source":source,"outline":contour}
	for record in previous.values():
		if is_instance_valid(record.outline):
			record.outline.visible = false
			record.outline.queue_free()
	entry.revision = entry.object.get_meta("visual_revision",0)
	entry.dirty = false

func _collect(node: Node3D, result: Array[MeshInstance3D], key: int, entry: Dictionary) -> void:
	if node.has_meta(OUTLINE_META) or node.has_meta("assembly_render_proxy"):return
	_watch(node,"child_entered_tree",_tree_changed.bind(key),entry)
	_watch(node,"child_exiting_tree",_tree_changed.bind(key),entry)
	# Keep hidden physical meshes in the cache. Their child contours inherit
	# visibility immediately, including enclosure/undo and ancestor visibility.
	if node is MeshInstance3D:result.append(node)
	for child in node.get_children():
		if child is Node3D:_collect(child,result,key,entry)

func _tree_changed(node: Node, key: int) -> void:
	if not node.has_meta(OUTLINE_META):_invalidate(key)

func _invalidate(key: int) -> void:
	if _cache.has(key):_cache[key].dirty = true

func _watch(object: Object, signal_name: String, callback: Callable, entry: Dictionary) -> void:
	if not is_instance_valid(object) or object.is_connected(signal_name,callback):return
	object.connect(signal_name,callback)
	entry.watches.append({"object":object,"signal":signal_name,"callback":callback})

func _disconnect(entry: Dictionary) -> void:
	for watch in entry.watches:
		if is_instance_valid(watch.object) and watch.object.is_connected(watch.signal,watch.callback):watch.object.disconnect(watch.signal,watch.callback)
	entry.watches = []

func _evict(key: int) -> void:
	var entry: Dictionary = _cache[key]
	_disconnect(entry)
	for record in entry.copies.values():
		if is_instance_valid(record.outline):
			record.outline.visible = false
			record.outline.queue_free()
	_cache.erase(key)

func _exit_tree() -> void:
	clear()
	for key in _cache.keys():_evict(key)

func _writes_depth(visual: MeshInstance3D) -> bool:
	# An inverted hull needs the original opaque surface to hide its interior.
	for surface in visual.mesh.get_surface_count():
		var material = visual.get_active_material(surface)
		if material is BaseMaterial3D and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:return false
	return true
