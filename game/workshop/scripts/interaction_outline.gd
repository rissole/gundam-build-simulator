extends Node3D
## Thin depth-tested contours on the focused, usable object. Copies never alter
## source materials, collision, service visibility or installed-piece ownership.
var focused: Node3D
var copies: Dictionary = {}
var outline_material: ShaderMaterial

func _init() -> void:
	outline_material = ShaderMaterial.new()
	outline_material.shader = preload("res://scripts/interaction_outline.gdshader")

func clear() -> void:
	focused = null
	visible = false
	for entry in copies.values():
		entry.outline.queue_free()
	copies.clear()

func focus(object: Node3D) -> void:
	if not is_instance_valid(object):
		clear()
		return
	if focused != object:clear()
	focused = object
	visible = true
	var meshes: Array[MeshInstance3D] = []
	_collect(object,meshes)
	var live: Dictionary = {}
	for source in meshes:
		var id = source.get_instance_id()
		live[id] = true
		if not copies.has(id):
			var contour = MeshInstance3D.new()
			contour.material_override = outline_material
			contour.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			contour.extra_cull_margin = 0.04
			add_child(contour)
			copies[id] = {"source":source,"outline":contour}
		var outline: MeshInstance3D = copies[id].outline
		outline.mesh = source.mesh
		outline.global_transform = source.global_transform
	for id in copies.keys():
		if not live.has(id):
			copies[id].outline.queue_free()
			copies.erase(id)

func _collect(node: Node3D, result: Array[MeshInstance3D]) -> void:
	if not node.is_visible_in_tree():return
	if node is MeshInstance3D and node.mesh != null and _writes_depth(node):result.append(node)
	for child in node.get_children():
		if child is Node3D:_collect(child,result)

func _writes_depth(visual: MeshInstance3D) -> bool:
	# An inverted hull needs the original opaque surface to hide its interior.
	# Service-view enclosures are translucent and must stay open to inspection.
	for surface in visual.mesh.get_surface_count():
		var material = visual.get_active_material(surface)
		if material is BaseMaterial3D and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:return false
	return true
