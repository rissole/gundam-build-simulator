extends RefCounted
## Box, sign and material construction. `material` returns shared palette
## instances; callers that change a material afterwards use `new_material`.
# Hallmark · pre-emit critique: P4 H4 E4 S4 R4 V3
# Hallmark · practical engineering: neutral structure, restrained safety accents.
# Palette aliases keep existing equipment's semantic colour roles consistent.
const FINISHES = {
	"7c8886":"929894", "abb9b6":"d6d8d2", "506971":"58666b",
	"485f68":"58666b", "edbd59":"bb893b", "49626a":"58666b", "657b80":"798582",
	"263a43":"303c43", "233940":"303c43", "253b45":"303c43",
	"e8b46b":"bb893b", "83bba6":"8daba3", "e0e6dd":"d6d8d2",
}
const Surfaces = preload("res://scripts/hangar_surfaces.gd")
var _palette: Dictionary = {}
var _sign_backing: StandardMaterial3D

func material(color: Color, metal: float = 0.0, emissive: bool = false) -> StandardMaterial3D:
	var coated = not emissive and FINISHES.has(color.to_html(false))
	if coated:
		color = Color(FINISHES[color.to_html(false)])
		metal = 0.0 # Intact paint is a dielectric; exposed hardware keeps its metal.
	var key = [color.r,color.g,color.b,color.a,metal,emissive,coated]
	if not _palette.has(key):
		var mat = new_material(color,metal,emissive)
		if coated:Surfaces.coating(mat)
		_palette[key] = mat
	return _palette[key]

func new_material(color: Color, metal: float = 0.0, emissive: bool = false) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.86 if color.to_html(false) in FINISHES.values() else 0.78
	mat.metallic = metal
	if emissive:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.4
	return mat

func box(parent: Node3D, pos: Vector3, dimensions: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var shape = BoxMesh.new()
	shape.size = dimensions
	mesh.mesh = shape
	mesh.material_override = mat
	mesh.position = pos
	parent.add_child(mesh)
	if solid:
		var body = StaticBody3D.new()
		parent.add_child(body)
		body.position = pos
		var collision = CollisionShape3D.new()
		var bounds = BoxShape3D.new()
		bounds.size = dimensions
		collision.shape = bounds
		body.add_child(collision)
	return mesh

func sign_text(parent: Node3D, text: String, pos: Vector3, font_size: int = 36, color: Color = Color("d5e2df"), pixel_size: float = 0.008) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.position = pos
	# Render more glyph pixels without changing physical lettering size.
	label.font_size = font_size*2
	label.pixel_size = pixel_size/2.0
	label.modulate = color
	label.outline_size = 0
	label.no_depth_test = false
	label.double_sided = false
	parent.add_child(label)
	return label

func sign_panel(parent: Node3D, text: String, pos: Vector3, size: Vector2, font_size: int = 64, pixel_size: float = 0.002, rotation_y: float = 0.0) -> Label3D:
	# Physical signs keep lettering distinct from equipment behind them. Normal
	# depth testing also prevents a sign being legible through walls or machinery.
	var mount = Node3D.new()
	mount.name = "SignPanel"
	mount.position = pos
	mount.rotation.y = rotation_y
	parent.add_child(mount)
	if _sign_backing == null:
		_sign_backing = new_material(Color("343d40"))
		_sign_backing.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var plate = box(mount,Vector3.ZERO,Vector3(size.x,size.y,0.03),_sign_backing)
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var label = sign_text(mount,text,Vector3(0,0,0.024),font_size,Color("eef0e8"),pixel_size)
	# Fit each line inside its physical plate; long operation instructions used
	# to spill across neighbouring machinery even though the board was small.
	var longest = 1
	for line in text.split("\n"):longest = maxi(longest,line.length())
	label.pixel_size = minf(label.pixel_size,(size.x-0.12)/(longest*label.font_size*0.62))
	return label
