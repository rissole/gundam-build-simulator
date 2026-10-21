extends TextureRect
## Reusable instruction view: geometry and poses come from authored slots.
var viewport: SubViewport
var stage: Node3D
var camera: Camera3D
var signature: String = ""

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

func show_parts(game: Node, entries: Array) -> void:
	var key = str(entries)
	if key == signature:return
	signature = key
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	for child in stage.get_children():
		stage.remove_child(child)
		child.queue_free()
	if entries.is_empty():return
	var bounds = AABB()
	var first = true
	for entry in entries:
		var ref: Dictionary = game.source[entry.source]
		var mesh = MeshInstance3D.new()
		mesh.mesh = ref.mesh
		mesh.transform = ref.transform
		mesh.material_override = game.material(Color("536a7c"),0.0)
		if entry.get("highlight",false):
			mesh.material_override = game.material(Color("80dfbd"),0.15)
			if not entry.get("installed",false):mesh.position.y -= 0.055
		if entry.get("faint",false):
			mesh.material_override = game.material(Color(0.38,0.52,0.61,0.16))
			mesh.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		stage.add_child(mesh)
		var aabb: AABB = mesh.transform*mesh.mesh.get_aabb()
		bounds = aabb if first else bounds.merge(aabb)
		first = false
	var center = bounds.get_center()
	camera.position = center+Vector3(0.35,-1.8,0.65)
	camera.look_at(center,Vector3.FORWARD)
	camera.size = maxf(bounds.size.length()*0.95,0.6)
