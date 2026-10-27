extends RefCounted
## Visual replacements for the complete final-assembly access/gantry system.
## Every mesh is built from its EXISTING visual bounds, not a new layout.
## Existing MeshInstance nodes, parents, visual offsets, visibility, colliders,
## supports and controller references survive. No process loop or new lights.
const Geometry = preload("res://scripts/gantry_mesh.gd")
const Surfaces = preload("res://scripts/hangar_surfaces.gd")
const FINISH = preload("res://scripts/gantry_finish.gdshader")
const PREFIXES = ["gantry_","outer_left_","outer_right_","outer_inner_","wing_",
	"hinge_front_guard_","hinge_rear_guard_","access_gate_","finger_","hip_apron_","rear_outer_",
	"rear_inner_","hip_link_","rope_","lift_left_","lift_right_"]
var records: Array[Dictionary] = []
var additions: Array[MeshInstance3D] = []
var labels: Array[Label3D] = []
var materials: Dictionary = {}
var meshes: Dictionary = {}

func build(blockout: Node3D, lifts: Array = []) -> void:
	_materials()
	for id: String in blockout.pieces:
		if not selected(id):continue
		var piece: Dictionary = blockout.pieces[id]
		var visual: MeshInstance3D = piece.visual
		var role: String = "deck" if piece.spec.material=="deck" else "rail" if piece.spec.material=="yellow" else "frame"
		if id.begins_with("gantry_bearing_") or id.ends_with("_rod") or id.ends_with("_contact"):role="metal"
		if id.begins_with("gantry_foot_"):role="foundation"
		_replace(visual,id,role)
	for lift: Node3D in lifts:_lift(lift)
	_stencils(blockout)

static func selected(id: String) -> bool:
	for prefix: String in PREFIXES:
		if id.begins_with(prefix):return true
	return false

func _materials() -> void:
	var textures = Surfaces.maps()
	var finishes = {"frame":["58666b",0],"rail":["bb893b",1],"deck":["465359",2],"metal":["919995",3],"foundation":["39464b",0]}
	for role in finishes:
		var spec: Array = finishes[role]
		var material = ShaderMaterial.new();material.shader=FINISH
		material.set_shader_parameter("paint",Color(spec[0]))
		material.set_shader_parameter("finish",spec[1])
		material.set_shader_parameter("grain_map",textures.paint)
		material.set_shader_parameter("rough_map",textures.roughness)
		material.set_shader_parameter("normal_map",textures.normal)
		materials[role]=material

func _replace(visual: MeshInstance3D, id: String, role: String) -> void:
	if not visual.mesh is BoxMesh:return
	var original: BoxMesh = visual.mesh
	var size = original.size
	var recesses: Dictionary = {}
	var bevel = .002 if role=="deck" else .001 if role=="metal" else .006 if role=="rail" else .012
	var foot = id.begins_with("gantry_foot_")
	var column = id.begins_with("gantry_column_")
	if foot:
		bevel=.008
		# Y+ face coordinates are (Z,X); anchors follow the existing base size.
		var pockets: Array = []
		for x in [-size.x/2+.20,size.x/2-.20]:
			for z in [-size.z/2+.20,size.z/2-.25]:
				pockets.append({"rect":Rect2(Vector2(z,x)-Vector2.ONE*.07,Vector2.ONE*.14),"depth":.03})
		recesses["1+"]=pockets
	if column:
		# Forward Z- face coordinates are (X,Y), relative to the visual centre.
		recesses["2-"]=[{"rect":Rect2(-.21,1.68-visual.position.y,.42,.45),"depth":.003}]
	var key = str(size)+"/"+str(bevel)+"/"+str(recesses)
	if not meshes.has(key):meshes[key]=Geometry.box(size,bevel,recesses)
	records.append({"id":id,"visual":visual,"original_bounds":original.get_aabb(),
		"transform":visual.transform,"parent":visual.get_parent(),"visible":visual.visible,
		"role":role,"recesses":recesses})
	visual.mesh=meshes[key];visual.material_override=materials[role]
	if foot:_anchors(visual)
	if column:_cover_screws(visual)

func _anchors(parent: MeshInstance3D) -> void:
	var size = parent.mesh.get_aabb().size
	var surface = SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in [-size.x/2+.20,size.x/2-.20]:
		for z in [-size.z/2+.20,size.z/2-.25]:
			var floor_y = size.y/2-.03
			_cylinder(surface,Vector3(x,floor_y+.002,z),.055,.004,16)
			_cylinder(surface,Vector3(x,floor_y+.013,z),.043,.018,6)
			_cylinder(surface,Vector3(x,floor_y+.024,z),.020,.004,12)
	_add_hardware(parent,surface,"RecessedFoundationAnchors")

func _cover_screws(parent: MeshInstance3D) -> void:
	var surface = SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half = parent.mesh.get_aabb().size/2
	for x in [-.17,.17]:
		for y in [1.72,2.09]:
			_cylinder(surface,Vector3(x,y-parent.position.y,-half.z+.002),.009,.002,6,Basis(Vector3.RIGHT,-PI/2))
	_add_hardware(parent,surface,"CaptiveCoverScrews")

func _cylinder(surface: SurfaceTool, at: Vector3, radius: float, height: float, sides: int, basis: Basis = Basis.IDENTITY) -> void:
	var cylinder = CylinderMesh.new();cylinder.top_radius=radius;cylinder.bottom_radius=radius
	cylinder.height=height;cylinder.radial_segments=sides;cylinder.rings=1
	surface.append_from(cylinder,0,Transform3D(basis,at))

func _add_hardware(parent: MeshInstance3D, surface: SurfaceTool, title: String) -> void:
	var node = MeshInstance3D.new();node.name=title;node.mesh=surface.commit()
	# Hardware is opaque and stays in the recessed face. Use one simple shared
	# material: these meshes use cylinder UVs, not the frame's metric face UVs.
	if not materials.has("fastener"):
		var mat = StandardMaterial3D.new();mat.albedo_color=Color("8e9693");mat.metallic=.75;mat.roughness=.48
		materials.fastener=mat
	node.material_override=materials.fastener
	parent.add_child(node);additions.append(node)

func _lift(lift: Node3D) -> void:
	# Only solids' linked visuals. Buttons, screens,
	# signs, cargo and transient controller visibility remain owned by the lift.
	var pending: Array[Node] = [lift]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		for child in node.get_children():pending.append(child)
		if not node is CollisionShape3D or not node.has_meta("visual"):continue
		var visual: MeshInstance3D = node.get_meta("visual")
		if not visual.mesh is BoxMesh:continue
		var size: Vector3 = visual.mesh.size
		# The existing control stand is intentionally outside this art pass.
		if size.is_equal_approx(Vector3(.36,.52,.12)):continue
		var role = "frame"
		if visual.get_parent()==lift.deck and size.x>2 and size.z>2 and size.y<.2:role="deck"
		elif visual.material_override is StandardMaterial3D and visual.material_override.albedo_color==Color("bb893b"):role="rail"
		_replace(visual,String(lift.name)+"/"+String(node.get_path()),role)

func _stencils(blockout: Node3D) -> void:
	for side in ["8.8","17.2"]:
		var column: MeshInstance3D=blockout.pieces["gantry_column_"+side].visual
		_label(column,"02\nGANTRY",Vector3(0,2.42-column.position.y,-column.mesh.get_aabb().size.z/2-.001),.0019)
	var crosshead: MeshInstance3D=blockout.pieces.gantry_crosshead.visual
	_label(crosshead,"02  /  FINAL ASSEMBLY",Vector3(0,0,-crosshead.mesh.get_aabb().size.z/2-.001),.0038)
	for side in ["left","right"]:
		for pair in [["8.4","HIP"],["20.6","ROPE ACCESS"]]:
			var id = ("outer_" if pair[0]=="8.4" else "wing_hinge_")+side+"_"+pair[0]+"_floor"
			var deck: MeshInstance3D=blockout.pieces[id].visual
			var half = deck.mesh.get_aabb().size/2
			_label(deck,pair[0]+" m  /  "+pair[1],Vector3(0,0,-half.z-.001),.0011)

func _label(parent: MeshInstance3D, text: String, at: Vector3, pixel: float) -> void:
	var label = Label3D.new();label.name="GantryStencil";label.text=text
	label.font_size=64;label.pixel_size=pixel;label.modulate=Color("c8cec4")
	label.outline_size=0;label.shaded=true;label.double_sided=false
	label.position=at;label.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(label);labels.append(label)
