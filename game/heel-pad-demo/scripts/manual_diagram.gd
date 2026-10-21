extends TextureRect
## Reusable instruction view: geometry and poses come from authored slots.
var viewport: SubViewport
var stage: Node3D
var camera: Camera3D
var signature: String = ""
var panels: HBoxContainer
static var context_shader: Shader
const CONTEXT_SHADER = """
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_prepass_alpha;
uniform vec3 clip_min;
uniform vec3 clip_max;
uniform vec3 clip_axis;
uniform vec2 clip_range;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
    if (any(lessThan(world_position, clip_min)) || any(greaterThan(world_position, clip_max))) discard;
    float axial = dot(world_position, clip_axis);
    if (axial < clip_range.x || axial > clip_range.y) discard;
    ALBEDO = vec3(0.48, 0.65, 0.74);
    ROUGHNESS = 0.8;
    ALPHA = 0.32;
}
"""

func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport = SubViewport.new()
	viewport.size = Vector2i(600,420)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	texture = viewport.get_texture()
	stage = Node3D.new()
	viewport.add_child(stage)
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("d5e7ec")
	env.environment.ambient_light_sky_contribution = 0.0
	env.environment.ambient_light_energy = 0.8
	viewport.add_child(env)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40,-25,20)
	light.light_energy = 1.5
	viewport.add_child(light)
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(65,20,-10)
	fill.light_energy = 1.0
	viewport.add_child(fill)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	viewport.add_child(camera)
	camera.current = true

func show_parts(game: Node, entries: Array, views: Array = [], options: Dictionary = {}) -> void:
	# Authored panels show a fixed instructional figure. Installation progress is
	# represented by the HUD; it does not change these panels' sources or poses.
	var key = str(views) if not views.is_empty() else str([entries,views,options])
	if key == signature:return
	signature = key
	if is_instance_valid(panels):
		remove_child(panels)
		panels.queue_free()
		panels = null
	if not views.is_empty():
		texture = null
		panels = HBoxContainer.new()
		panels.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panels.add_theme_constant_override("separation",8)
		add_child(panels)
		for view in views:
			var column = VBoxContainer.new()
			column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			panels.add_child(column)
			var label = Label.new()
			label.text = view.title
			label.add_theme_font_size_override("font_size",12)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			column.add_child(label)
			var panel = get_script().new()
			panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
			column.add_child(panel)
			panel.viewport.size = Vector2i(300 if views.size() > 1 else 600,420)
			var selected: Array = []
			for source in view.sources:
				selected.append({"source":source,"highlight":true,"installed":true})
			for source in view.get("context",[]):
				selected.append({"source":source,"highlight":false,"installed":true,"faint":true})
			panel.show_parts(game,selected,[],view)
		return
	texture = viewport.get_texture()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	for child in stage.get_children():
		stage.remove_child(child)
		child.queue_free()
	if entries.is_empty():return
	var bounds = AABB()
	var first = true
	var authored = options.has("direction")
	var context_materials: Array[ShaderMaterial] = []
	for entry in entries:
		var ref: Dictionary = game.source[game.source_uid(entry.source)]
		var mesh = MeshInstance3D.new()
		mesh.mesh = ref.mesh
		mesh.transform = ref.transform
		mesh.material_override = null if authored else game.material(Color("536a7c"),0.0)
		if entry.get("highlight",false):
			if not authored:
				mesh.material_override = game.material(Color("80dfbd"),0.15)
				if not entry.get("installed",false):mesh.position.y -= 0.055
			if options.get("offsets",{}).has(entry.source):
				var offset = options.offsets[entry.source]
				mesh.position += Vector3(offset[0],offset[1],offset[2])
		if entry.get("faint",false):
			if authored:
				if context_shader == null:
					context_shader = Shader.new()
					context_shader.code = CONTEXT_SHADER
				var context_material = ShaderMaterial.new()
				context_material.shader = context_shader
				mesh.material_override = context_material
				context_materials.append(context_material)
			else:
				mesh.material_override = game.material(Color(0.6,0.72,0.8,0.16))
				mesh.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		stage.add_child(mesh)
		var aabb: AABB = mesh.transform*mesh.mesh.get_aabb()
		if not authored or entry.get("highlight",false):
			bounds = aabb if first else bounds.merge(aabb)
			first = false
	var center = bounds.get_center()
	if authored:
		for context_material in context_materials:
			var padding: float = options.get("context_padding",0.018)
			context_material.set_shader_parameter("clip_min",bounds.position-Vector3.ONE*padding)
			context_material.set_shader_parameter("clip_max",bounds.end+Vector3.ONE*padding)
			var clip_axis = options.get("clip_axis",[0,1,0])
			var clip_range = options.get("clip_range",[-100,100])
			context_material.set_shader_parameter("clip_axis",Vector3(clip_axis[0],clip_axis[1],clip_axis[2]))
			context_material.set_shader_parameter("clip_range",Vector2(clip_range[0],clip_range[1]))
		var look = options.direction
		var up = options.get("up",[0,1,0])
		camera.position = center+Vector3(look[0],look[1],look[2]).normalized()*3.0
		camera.look_at(center,Vector3(up[0],up[1],up[2]))
		camera.near = 0.001
		var projected = camera.transform.affine_inverse()*bounds
		camera.size = maxf(maxf(projected.size.y,projected.size.x/float(viewport.size.x)*viewport.size.y)*1.2,0.085)
		return
	camera.position = center+Vector3(0.35,-1.8,0.65)
	camera.look_at(center,Vector3.FORWARD)
	camera.size = maxf(bounds.size.length()*0.95,0.6)
