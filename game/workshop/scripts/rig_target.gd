extends Node3D
## Visual-only target for one active payload. Construct with the shared runtime,
## parent outside the carried assembly, then show_target(id, world_pose) while
## jogging and clear() at rest. No processing, collision, or target registration.
## A model change (or explicit invalidate after articulation) rebuilds on next use.
const GLOW = preload("res://scripts/manual_control_glow.gdshader")
const READY_COLOR = Color("73d995")
const ADJUST_COLOR = Color("edc378")
var runtime: AssemblyRuntime
var assembly_id = ""
var _dirty = true
var material = ShaderMaterial.new()

func _init(shared: AssemblyRuntime) -> void:
	runtime = shared
	material.shader = GLOW
	material.set_shader_parameter("glow_color",Color("80cdd9"))
	material.set_shader_parameter("dim_alpha",.10)
	material.set_shader_parameter("bright_alpha",.30)
	material.set_shader_parameter("rim_alpha",.15)
	runtime.model.changed.connect(invalidate)
	visible = false

func invalidate() -> void:
	_dirty = true
	# Never leave an obsolete payload silhouette on screen after an undo/mount.
	hide()

func clear() -> void:
	hide()

func show_target(id: String, target: Transform3D) -> void:
	if not is_instance_valid(runtime.node(id)):
		clear()
		return
	if id != assembly_id or _dirty:
		for child in get_children():child.free()
		assembly_id = id
		# Copy meshes only, including mounted children and captive brace hardware.
		# Skip renderer proxies/outlines; batching keeps the originals at layer 0.
		_copy_meshes(runtime.node(id),runtime.node(id).global_transform.affine_inverse())
		_dirty = false
	global_transform = target
	visible = get_child_count() > 0

func _copy_meshes(node: Node, inverse: Transform3D) -> void:
	if node.has_meta("assembly_render_proxy") or node.has_meta("pickup_outline"):return
	if node is Node3D and not node.is_visible_in_tree():return
	if node is MeshInstance3D and node.mesh != null:
		var copy = MeshInstance3D.new()
		copy.mesh = node.mesh
		copy.material_override = material
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(copy)
		copy.transform = inverse*node.global_transform
	for child in node.get_children():_copy_meshes(child,inverse)

## Deltas are target minus current, in the supplied display unit. Each record is
## {label, delta, tolerance, unit?}; order is the caller's panel axis order.
## Label3D has one color per label: use rows[i].text / rows[i].color for separate
## axis labels; text is the joined plain-text fallback. Empty/invalid input never
## grants SEAT. Controllers still own support/interlock checks and the commit.
static func axis_readout(axes: Array) -> Dictionary:
	var rows: Array[Dictionary] = []
	var captions = PackedStringArray()
	var all_in_tolerance = not axes.is_empty()
	for axis in axes:
		var delta: float = axis.delta
		var tolerance: float = axis.tolerance
		var valid = is_finite(delta) and is_finite(tolerance) and tolerance >= 0
		var ready = valid and absf(delta) <= tolerance
		all_in_tolerance = all_in_tolerance and ready
		var value = "%+.2f" % (0.0 if is_zero_approx(delta) else delta) if valid else "—"
		var caption = "%s %s%s" % [axis.label,value,axis.get("unit","")]
		rows.append({"text":caption,"in_tolerance":ready,"color":READY_COLOR if ready else ADJUST_COLOR})
		captions.append(caption)
	return {"text":"  ".join(captions),"rows":rows,"all_in_tolerance":all_in_tolerance}
