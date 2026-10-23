extends Node3D

const Part = preload("res://scripts/loose_part.gd")
const HUD = preload("res://scripts/hud.gd")
const FOOT_CENTER = Vector3(0,0.8,-0.7)
const PREP_POSITION = Vector3(-2.3,1.35,-1.2)
const FOOT_POSITION = Vector3(2.3,2.0,-1.8)
const PREP_BASIS = Basis(Vector3.RIGHT,-PI/2)
const FOOT_BASIS = Basis(Vector3.BACK,PI) * Basis(Vector3.RIGHT,-PI/2)
const REACH = 2.35
const SNAP_DISCOVERY_RANGE = 6.0
const SNAP_READY_COLOR = Color(0.35,1.0,0.73,0.40)
const SNAP_DISTANT_COLOR = Color(1.0,0.78,0.12,0.55)
const WORLD_MASK = 7
const PAD_HOME = Vector3(-1.0,1.09,3.25)
const JUMP_SPEED = 5.2

var model = AssemblyModel.new()
var runtime: AssemblyRuntime
var components: Node
var storage: Node
var pitch_workshop: bool = false
var leg_workshop: bool = false
var m2_trial = ""
var m2_half_uid = "PV-120__001"
var m2: Node3D
var m2_crane: Node3D
var leg_content: Dictionary = {}
var leg_layout: Node3D
var access_lifts: Dictionary = {}
var foot_fixture: Node3D
var builds: Dictionary = {}
var bodies: Dictionary = {}
var stations: Dictionary = {}
var state: HeelAssemblyState
var active_build: String = "pad_1"
var prepared_flags: Dictionary = {}
var completed_flags: Dictionary = {}
var single_pad: bool = false
var automated_test: bool = false
var scripted_controls: Dictionary = {}
var config: Dictionary
var source: Dictionary = {}
var active_ids: Array[String] = []
var part_defs: Dictionary = {}
var type_sources: Dictionary = {}
var slot_sources: Dictionary = {"sleeve": [], "washer": [], "bolt": []}
var pad: WorkshopPart
var pad_mesh: MeshInstance3D
var ghost: MeshInstance3D
var ghost_material: StandardMaterial3D
var ghost_assembly_signature: String = ""
var interaction_outline: Node3D
var foot: AnimatableBody3D
var prep: Node3D
var loose: Dictionary = {}
var bins: Dictionary = {}
var bin_labels: Dictionary = {}
var socket_markers: Array[MeshInstance3D] = []
var player: CharacterBody3D
var camera: Camera3D
var player_collision: CollisionShape3D
var crouched: bool = false
var jump_requested: bool = false
var jump_held: bool = false
var rotate_held: bool = false
var rotate_dragged: bool = false
var rotate_press_time: int = 0
var last_rotate_tap: int = -1000
var last_rotate_station: String = ""
var hud: CanvasLayer
var selected_kind: String:
	get:return model.selected_kind()
	set(value):
		var index = model.pocket_for(value)
		if index >= 0:model.select_pocket(index)
var paused: bool = true
var target: Dictionary = {}
var rotation_station: String = ""
var completed_before: bool = false
var prepared_before: bool = false
var chime: AudioStreamPlayer
var started: bool = false
var screenshot_mode: bool = false
var saves: Node

func _ready() -> void:
	single_pad = OS.get_cmdline_user_args().has("--single-pad")
	automated_test = OS.get_cmdline_user_args().has("--demo-test") or OS.get_cmdline_user_args().has("--multi-test") or OS.get_cmdline_user_args().has("--pitch-test") or OS.get_cmdline_user_args().has("--pockets-test")
	var arguments: Array = Array(OS.get_cmdline_user_args())
	for arg in arguments:
		if str(arg).begins_with("--m2-trial="):m2_trial = str(arg).trim_prefix("--m2-trial=")
	if m2_trial.is_empty() and get_tree().has_meta("m2_trial"):m2_trial = get_tree().get_meta("m2_trial")
	if arguments.has("--m2-workshop") and m2_trial.is_empty():
		add_child(preload("res://scripts/m2_selector.gd").new())
		return
	if not m2_trial.is_empty():assert(m2_trial in ["retention","crane"])
	if not m2_trial.is_empty():single_pad = false
	# The foot workshop is the default; --foot-workshop remains an accepted alias.
	leg_workshop = not m2_trial.is_empty()
	config = HeelAssemblyState.scenario(single_pad)
	pitch_workshop = not m2_trial.is_empty() or (not single_pad and not OS.get_cmdline_user_args().has("--pads-only") and not OS.get_cmdline_user_args().has("--multi-test"))
	var data = HeelAssemblyState.definition_data(single_pad)
	if pitch_workshop:
		config = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pitch-workshop.json"))
		var overlay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(config.definitions))
		data.parts.merge(overlay.parts,true)
		data.assemblies.merge(overlay.assemblies,true)
	if leg_workshop:
		leg_content = JSON.parse_string(FileAccess.get_file_as_string("res://assets/leg-prototype-content.json"))
		var overlay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/leg-prototype-definitions.json"))
		data.parts.merge(overlay.parts,true)
		data.assemblies.merge(overlay.assemblies,true)
		if not m2_trial.is_empty():
			var trial_definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/m2-"+m2_trial+"-definitions.json"))
			var trial_content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/m2-"+m2_trial+"-content.json"))
			data.parts.merge(trial_definitions.parts,true);data.assemblies.merge(trial_definitions.assemblies,true)
			for support_id in trial_content.m2.remove_supports:leg_content.supports.erase(support_id)
			leg_content.supports.merge(trial_content.supports,true)
			for field in ["parts","parents","equipment","m2"]:leg_content[field] = trial_content[field]
			if m2_trial == "retention" and m2_half_uid != "PV-120__001":
				assert(m2_half_uid == "PV-120__002")
				for record in leg_content.parts:
					if record.instance_id == "PV-120__001":record.instance_id = m2_half_uid;record.source_id = m2_half_uid
				leg_content.m2.retention_uid = m2_half_uid
		config.parts.append_array(leg_content.parts)
		config.parents = leg_content.parents.duplicate(true)
		config.supports = leg_content.supports.duplicate(true)
		config.parent.location = "support:foot_carrier"
		config.parents[0].home = [2.3,0.75,14.4]
		config.parents[1].home = [13,10.6,26]
	components = preload("res://scripts/component_interaction.gd").new(self)
	add_child(components)
	var errors = model.configure(data,config)
	assert(errors.is_empty(),str(errors))
	runtime = AssemblyRuntime.new(model,source)
	bind_build_views(config)
	active_build = config.builds[0].id
	state = builds[active_build]
	for definition in config.parts:
		active_ids.append(definition.instance_id)
		part_defs[definition.instance_id] = definition
	_make_world()
	_load_foot()
	if leg_workshop:
		preload("res://scripts/leg_source_geometry.gd").add_sources(source,leg_content)
		for record in leg_content.parts:type_sources[record.kind] = record.get("source_id",record.instance_id)
	_register_parent_fixtures()
	if leg_workshop:_make_leg_context()
	_make_player()
	if pitch_workshop and m2_trial.is_empty() and not OS.get_cmdline_user_args().has("--legacy-stations"):
		foot_fixture = preload("res://scripts/supported_fixture.gd").new()
		add_child(foot_fixture)
		foot_fixture.setup(self,foot)
	for build in config.builds:
		_activate(build.id)
		_make_pad()
	_activate(config.builds[0].id)
	components.setup()
	if not m2_trial.is_empty():
		m2 = preload("res://scripts/m2_workshop.gd").new();add_child(m2);m2.setup(self)
	storage = preload("res://scripts/part_storage.gd").new(self)
	add_child(storage)
	storage.setup()
	if not m2_trial.is_empty():_position_m2_stock()
	ghost_material = material(SNAP_READY_COLOR,0.0)
	ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	ghost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost_material.cull_mode = BaseMaterial3D.CULL_BACK
	ghost = MeshInstance3D.new()
	ghost.material_override = ghost_material
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ghost)
	ghost.visible = false
	interaction_outline = preload("res://scripts/interaction_outline.gd").new()
	add_child(interaction_outline)
	for i in range(4*builds.size()):
		var marker = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.009
		sphere.height = 0.018
		marker.mesh = sphere
		marker.material_override = material(Color("79d8b8"),0.0,true)
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(marker)
		marker.visible = false
		socket_markers.append(marker)
	hud = HUD.new()
	hud.game = self
	add_child(hud)
	if not m2_trial.is_empty():hud.open_manual("pelvis" if m2_trial == "retention" else "left_leg")
	model.changed.connect(_state_changed)
	_make_audio()
	_state_changed()
	set_paused(true)
	started = true
	saves = preload("res://scripts/m2_session.gd").new() if not m2_trial.is_empty() else preload("res://scripts/workshop_save.gd").new()
	add_child(saves)
	saves.setup(self)
	if OS.get_cmdline_user_args().has("--pockets-test"):
		var runner = load("res://tests/pockets_workshop_test.gd").new()
		add_child(runner)
		runner.call_deferred("run",self)
	elif OS.get_cmdline_user_args().has("--pitch-review"):
		var runner = load("res://tests/pitch_visual_review.gd").new()
		add_child(runner)
		runner.call_deferred("run",self)
	elif OS.get_cmdline_user_args().has("--pitch-test"):
		var runner = load("res://tests/pitch_build_test.gd").new()
		add_child(runner)
		runner.call_deferred("run",self)
	elif OS.get_cmdline_user_args().has("--multi-test"):
		var runner = load("res://tests/multi_build_test.gd").new()
		add_child(runner)
		runner.call_deferred("run",self)
	elif OS.get_cmdline_user_args().has("--demo-test"):
		var test_script = load("res://tests/demo_test.gd")
		var runner = test_script.new()
		add_child(runner)
		runner.call_deferred("run",self)
	elif OS.get_cmdline_user_args().has("--capture"):
		_capture_preview.call_deferred()

func material(color: Color, metal: float = 0.0, emissive: bool = false) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.78
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
	var backing = material(Color("20343e"))
	backing.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var plate = box(mount,Vector3.ZERO,Vector3(size.x,size.y,0.03),backing)
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var label = sign_text(mount,text,Vector3(0,0,0.022),font_size,Color("eef5ef"),pixel_size)
	return label

func _make_world() -> void:
	var environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	var env = environment.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("91a4aa")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("cbd8dd")
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-28,0)
	sun.light_energy = 0.85
	sun.light_color = Color("ffebce")
	sun.shadow_enabled = true
	# Resolve small joints within this room instead of allocating shadow detail
	# across a distant outdoor scene.
	sun.directional_shadow_max_distance = 32.0
	add_child(sun)
	var fill = OmniLight3D.new()
	fill.position = Vector3(-2,4,3)
	fill.light_energy = 0.65
	fill.omni_range = 14
	fill.light_color = Color("d1edff")
	add_child(fill)
	var floor_mat = material(Color("7c8886"))
	var wall_mat = material(Color("abb9b6"))
	var dark = material(Color("233940"),0.3)
	var metal = material(Color("49626a"),0.35)
	var warm = material(Color("e8b46b"),0.1)
	if leg_workshop:
		leg_layout = preload("res://scripts/leg_bay_layout.gd").new()
		add_child(leg_layout)
		leg_layout.setup(self)
		sun.directional_shadow_max_distance = 58.0
	else:
		_make_component_room(floor_mat,wall_mat,dark,metal,warm)
	_make_preparation_area(dark,metal,warm)

func _make_component_room(floor_mat: Material, wall_mat: Material, dark: Material, metal: Material, _warm: Material) -> void:
	box(self,Vector3(0,-0.15,0),Vector3(22,0.3,20),floor_mat,true)
	box(self,Vector3(0,4,-7),Vector3(22,8,0.3),wall_mat,true)
	# Side walls butt against the rear wall instead of sharing its top face.
	box(self,Vector3(-10.8,4,0.075),Vector3(0.3,8,13.85),wall_mat,true)
	box(self,Vector3(10.8,4,0.075),Vector3(0.3,8,13.85),wall_mat,true)
	box(self,Vector3(0,4,9.8),Vector3(22,8,0.3),wall_mat,true)
	for x in range(-10,11,2):
		box(self,Vector3(x,0.002,0),Vector3(0.016,0.004,19),material(Color("687875")))
	for z in range(-6,10,2):
		# Split at grid intersections so the floor markings have no overlapping faces.
		for x in range(-10,10,2):
			box(self,Vector3(x+1,0.002,z),Vector3(1.984,0.004,0.016),material(Color("687875")))
	for x in [-8.0,-4.0,0.0,4.0,8.0]:
		# Pilasters start at the wall face so their tops do not overlap the wall top.
		box(self,Vector3(x,4,-6.75),Vector3(0.22,8,0.20),metal)
		box(self,Vector3(x,6.7,0),Vector3(0.18,0.3,14),dark)
		box(self,Vector3(x,6.5,-1),Vector3(0.10,0.06,5),material(Color("fff3d5"),0,true))
	sign_panel(self,"FA / 01",Vector3(0,5.3,-6.55),Vector2(4.5,1.35),160,0.006)
	sign_panel(self,"COMPONENT ASSEMBLY  /  LOWER LIMB DIVISION",Vector3(0,4.35,-6.55),Vector2(5.4,0.36),64,0.0025)

func _make_preparation_area(dark: Material, metal: Material, warm: Material) -> void:
	# Pad rests on a separate preparation table; the player chooses when to carry it.
	box(self,Vector3(-0.1,0.92,PAD_HOME.z),Vector3(3.4,0.12,1.25),dark,true)
	for x in [PAD_HOME.x-0.6,PAD_HOME.x+0.6]:
		for z in [PAD_HOME.z-0.5,PAD_HOME.z+0.5]: box(self,Vector3(x,0.43,z),Vector3(0.09,0.86,0.09),metal,true)
	sign_text(self,"FA-302 / HEEL PAD",Vector3(PAD_HOME.x,0.92,PAD_HOME.z+0.64),19,Color("dfe9e5"),0.006)
	# A nearby stock tray gives organisation a physical purpose.
	box(self,Vector3(-0.4,0.86,0.6),Vector3(1.1,0.10,0.7),dark,true)
	for x in [-0.85,0.05]: box(self,Vector3(x,0.40,0.6),Vector3(0.07,0.8,0.55),metal,true)
	# Rims stand on the tray base; the front/rear rails fit between side rails.
	for x in [-0.94,0.14]: box(self,Vector3(x,0.965,0.6),Vector3(0.03,0.11,0.71),warm,true)
	for z in [0.26,0.94]: box(self,Vector3(-0.4,0.965,z),Vector3(1.05,0.11,0.03),warm,true)
	_station_frame(PREP_POSITION,Vector3(1.05,1.1,0.9),"02 / PREPARATION A",dark,warm)
	if not pitch_workshop or OS.get_cmdline_user_args().has("--legacy-stations"):
		_station_frame(FOOT_POSITION,Vector3(2.7,3.7,2.8),"03 / FOOT ASSEMBLY",dark,warm)
	prep = Node3D.new()
	prep.position = PREP_POSITION
	prep.basis = PREP_BASIS
	add_child(prep)
	stations["prep"] = prep
	prep.set_meta("work_volume",Vector3(1.05,1.1,0.9))
	if not single_pad:
		var pos = Vector3(-4.6,1.35,-1.2)
		_station_frame(pos,Vector3(1.05,1.1,0.9),"04 / PREPARATION B",dark,warm)
		var other = Node3D.new()
		add_child(other)
		other.position = pos
		other.basis = PREP_BASIS
		stations["prep2"] = other
		other.set_meta("work_volume",Vector3(1.05,1.1,0.9))
	if pitch_workshop:
		var pos = Vector3(-6.4,1.5,-1.2)
		_station_frame(pos,Vector3(1.05,1.1,0.9),"05 / PREPARATION C",dark,warm)
		var other = Node3D.new()
		add_child(other)
		other.position = pos
		other.basis = PREP_BASIS
		stations["prep3"] = other
		other.set_meta("work_volume",Vector3(1.05,1.1,0.9))
	# Spatial scale cues and a safe open route to the receiving station.
	for x in [-0.8,5.0]: box(self,Vector3(x,0.008,-1.8),Vector3(0.045,0.01,4.3),warm)

func _make_leg_context() -> void:
	var pelvis = assembly_node("pelvis")
	var context = Node3D.new()
	context.name = "PelvisStructure"
	pelvis.add_child(context)
	var steel = material(Color("617880"),0.5)
	for uid in leg_content.context_sources:
		var mesh = _mesh(uid)
		context.add_child(mesh)
		mesh.transform = source[uid].transform
		mesh.material_override = steel
		var col = CollisionShape3D.new()
		col.shape = mesh.mesh.create_trimesh_shape()
		col.shape.backface_collision = true
		col.transform = mesh.transform
		col.set_meta("source_uid",uid)
		pelvis.add_child(col)

func foot_equipment_available() -> bool:
	return is_instance_valid(foot_fixture)

func equipment_controller(entry: Dictionary) -> Node:
	if entry.has("controller"):return entry.controller
	if entry.has("equipment_id"):return access_lifts.get(entry.equipment_id)
	return foot_fixture

func _station_frame(center: Vector3, dimensions: Vector3, title: String, dark: Material, warm: Material) -> void:
	var half = dimensions/2
	for x in [-half.x,half.x]:
		for z in [-half.z,half.z]:
			# Rear posts preserve an open view and access to the work volume.
			if z < 0: box(self,Vector3(center.x+x,center.y,center.z+z),Vector3(0.045,dimensions.y,0.045),dark,true)
			box(self,Vector3(center.x+x,maxf(0.03,center.y-half.y),center.z+z),Vector3(0.15,0.045,0.15),warm)
	for y in [-half.y,half.y]:
		box(self,center+Vector3(0,y,-half.z),Vector3(dimensions.x,0.035,0.035),dark)
		# Side rails butt against the rear posts rather than crossing the rear rail.
		for x in [-half.x,half.x]:box(self,center+Vector3(x,y,0.01125),Vector3(0.035,0.035,dimensions.z-0.0225),dark)
	# Bolt the board to the rear frame, above the usable preparation volume.
	for x in [-half.x,half.x]:
		box(self,center+Vector3(x,half.y+0.09875,-half.z),Vector3(0.035,0.1625,0.035),dark)
	sign_panel(self,title,center+Vector3(0,half.y+0.17,-half.z+0.04),Vector2(maxf(1.5,dimensions.x),0.30),64,0.0018)

func _load_foot() -> void:
	foot = AnimatableBody3D.new()
	foot.name = "FootStation"
	foot.collision_layer = 4
	foot.collision_mask = 0
	foot.sync_to_physics = false
	add_child(foot)
	foot.position = FOOT_POSITION
	foot.basis = FOOT_BASIS
	var visual = load("res://assets/foot-fa01.glb").instantiate()
	foot.add_child(visual)
	visual.position = -FOOT_CENTER
	for node in visual.get_children():
		if not node is MeshInstance3D: continue
		var sections = String(node.name).split("__")
		if sections.size() < 2: continue
		var uid: String = sections[0]+"__"+sections[1]
		source[uid] = {"mesh": node.mesh, "transform": node.transform, "family": sections[0]}
		if model.items.values().any(func(item):return item.source_id == uid):
			for item_uid in model.items:
				if source_uid(item_uid) == uid and sections[0] != "FA-302":type_sources[model.items[item_uid].kind] = uid
			visual.remove_child(node)
			node.free()
			continue
		var family: String = sections[0]
		if config.get("context_storage_families",[]).has(family):
			var stored = Node3D.new()
			add_child(stored)
			stored.position = Vector3(7,2,7.0)
			node.reparent(stored,false)
			node.position -= FOOT_CENTER
			continue
		if ["FA-100","FA-101","FA-102","FA-103","FA-104","FA-105","FA-106","FA-200","FA-201","FA-300","FA-301","FA-302","FA-303","FA-304","FA-400","FA-401","FA-402","FA-403","FA-404"].has(family):
			var collision_mode: String = config.get("context_collision",{}).get(uid,"bounds")
			var col = CollisionShape3D.new()
			col.transform = node.transform
			if collision_mode == "mesh":
				# Explicit fixed receiving frames need their actual openings. Concave
				# source triangles are confined to context fixtures, never carried bodies.
				var shape = node.mesh.create_trimesh_shape()
				shape.backface_collision = true
				col.shape = shape
				col.position -= FOOT_CENTER
			else:
				var aabb: AABB = node.mesh.get_aabb()
				var shape = BoxShape3D.new()
				shape.size = aabb.size.max(Vector3(0.02,0.02,0.02))
				col.shape = shape
				col.position += aabb.get_center()-FOOT_CENTER
			col.set_meta("source_uid",uid)
			col.set_meta("context_collision",collision_mode)
			foot.add_child(col)
	for kind in HeelAssemblyState.KINDS:
		for i in range(4):
			var definition = model.definitions.assemblies.heel_pad.slots["sleeve_%d"%i] if kind == "sleeve" else model.definitions.assemblies.foot.slots["heel_1/%s_%d"%[kind,i]]
			slot_sources[kind].append(definition.pose_source)
	assert(source.size() == 745,"Foot source must retain the full inventory.")

func _register_parent_fixtures() -> void:
	var index = 0
	for record in AssemblyModel.scenario_parents(config):
		var body: AnimatableBody3D = foot if index == 0 else AnimatableBody3D.new()
		if index > 0:
			body.collision_layer = 4
			body.collision_mask = 0
			body.sync_to_physics = false
			add_child(body)
			body.position = FOOT_POSITION+Vector3.RIGHT*index*4.0
		if record.has("home"):body.position = AssemblyRuntime.vec(record.home)
		if record.has("rotation_degrees"):body.basis = Basis.from_euler(AssemblyRuntime.vec(record.rotation_degrees)*PI/180.0)
		var d: Dictionary = model.definitions.assemblies[record.definition]
		var source_frame = null
		if record.has("frame_offset"):source_frame = Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(record.frame_offset))
		elif not d.has("root_slot") and index == 0:source_frame = Transform3D(Basis.IDENTITY,-FOOT_CENTER)
		runtime.register_node(record.id,body,source_frame)
		if d.has("root_slot"):
			var uid: String = model.assemblies[record.id].slots[d.root_slot]
			var visual = _mesh(d.slots[d.root_slot].get("pose_source",source_uid(uid)))
			visual.transform = runtime.local_slot_pose(record.id,d.root_slot)
			visual.set_meta("component_uid",uid)
			visual.set_meta("slot_id",d.root_slot)
			body.add_child(visual)
			refresh_assembly_collision(record.id)
		index += 1

func _make_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.collision_layer = 8
	player.collision_mask = WORLD_MASK
	add_child(player)
	player.position = Vector3(0.0,0.1,6.4)
	var col = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	player_collision = col
	capsule.radius = 0.26
	capsule.height = 1.7
	col.shape = capsule
	col.position.y = 0.86
	player.add_child(col)
	camera = Camera3D.new()
	camera.position.y = 1.63
	camera.near = 0.035
	camera.far = 60.0
	camera.fov = 75
	player.add_child(camera)
	camera.current = true

func _mesh(uid: String) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	uid = source_uid(uid)
	mesh.mesh = source[uid].mesh
	mesh.set_meta("source_uid",uid)
	return mesh

func _make_pad() -> void:
	pad = Part.new()
	pad.uid = state.pad_id
	pad.kind = "pad"
	pad.name = "HeelPad"
	pad.collision_layer = 2
	pad.collision_mask = WORLD_MASK
	add_child(pad)
	pad_mesh = _mesh(state.pad_id)
	pad.add_child(pad_mesh)
	pad_mesh.set_meta("component_uid",state.pad_id)
	if components.is_component_build(active_build):
		pad_mesh.transform = source[components.frame_source(active_build)].transform.affine_inverse()*source[source_uid(state.pad_id)].transform
		pad_mesh.set_meta("component_uid",state.pad_id)
		pad_mesh.set_meta("slot_id",components.definition(active_build).root_slot)
	pad.add_collision_exception_with(player)
	player.add_collision_exception_with(pad)
	pad.position = home_position(active_build)
	bodies[active_build] = pad
	runtime.register_node(active_build,pad)
	refresh_assembly_collision(active_build)

func _make_audio() -> void:
	chime = AudioStreamPlayer.new()
	add_child(chime)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var bytes = PackedByteArray()
	bytes.resize(22050*2)
	for i in range(22050):
		var t = float(i)/22050.0
		var sample = (sin(TAU*523.25*t)+0.55*sin(TAU*659.25*t)+0.35*sin(TAU*783.99*t))*exp(-t*5.5)*minf(1,t*80)*0.22
		bytes.encode_s16(i*2,int(sample*32767))
	stream.data = bytes
	chime.stream = stream
	chime.volume_db = -8

func set_paused(value: bool) -> void:
	var was_paused = paused
	paused = value
	jump_requested = false
	if value and is_instance_valid(interaction_outline):interaction_outline.clear()
	rotate_held = false
	rotation_station = ""
	last_rotate_tap = -1000
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	if hud:
		hud.pause_panel.visible = value
		hud.crosshair.visible = not value
		if value: hud.target_panel.visible = false
		hud.show_pause(value)
	if value and not was_paused and started and is_instance_valid(saves) and not saves.applying:
		saves.save_now()

func _unhandled_input(event: InputEvent) -> void:
	# Verification drives the same adapter explicitly; live desktop events must
	# not rotate its scripted camera or trigger unrelated build actions.
	if not automated_test:handle_desktop_input(event)

func movement_pressed(code: Key) -> bool:
	return bool(scripted_controls.get(code,false)) if automated_test else Input.is_physical_key_pressed(code)

func handle_desktop_input(event: InputEvent) -> void:
	if started and is_instance_valid(m2_crane) and m2_crane.console.is_open:
		m2_crane.console.handle_input(event)
		return
	if automated_test and event is InputEventKey:scripted_controls[event.physical_keycode] = event.pressed
	# Track releases even when a menu consumes input. Only a fresh press can
	# request a jump, so holding Space through landing or a menu cannot repeat it.
	if event is InputEventKey and event.physical_keycode == KEY_SPACE:
		var fresh_press = event.pressed and not event.echo and not jump_held
		jump_held = event.pressed
		if not started:return
		if hud.handle_manual_browser_input(event):
			jump_requested = false
			return
		if fresh_press and not paused:jump_requested = true
		return
	if not started: return
	if hud.handle_manual_browser_input(event):
		jump_requested = false
		return
	if event is InputEventKey and event.physical_keycode == KEY_R and not event.echo:
		if not paused: _rotation_key(event.pressed)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			set_paused(not paused)
			get_viewport().set_input_as_handled()
			return
		if paused: return
		match event.physical_keycode:
			KEY_1: model.select_pocket(0)
			KEY_2: model.select_pocket(1)
			KEY_3: model.select_pocket(2)
			KEY_4: model.select_pocket(3)
			KEY_5: model.select_pocket(4)
			KEY_6: model.select_pocket(5)
			KEY_7: model.select_pocket(6)
			KEY_8: model.select_pocket(7)
			KEY_9: model.select_pocket(8)
			KEY_0: model.select_pocket(9)
			KEY_E: interact(event.shift_pressed)
			KEY_Q: drop_selected()
			KEY_B: deposit()
			KEY_Z: undo_build()
			KEY_TAB, KEY_M: hud.manual.visible = not hud.manual.visible
			KEY_LEFT: hud.turn_page(-1)
			KEY_RIGHT: hud.turn_page(1)
			KEY_PAGEUP: hud.body_scroll.scroll_vertical -= 140
			KEY_PAGEDOWN: hud.body_scroll.scroll_vertical += 140
			KEY_BACKSPACE: hud.open_manual(hud.manual_parent(hud.manual_id))
			KEY_ENTER: hud.open_selected_child()
			KEY_C: hud.cycle_build()
			KEY_V:
				if target.has("owner"):hud.open_manual(target.owner)
				elif target.has("build"):hud.open_manual(target.build)
				else:hud.open_manual(default_parent_id())
			KEY_F: reset_station()
		hud.refresh()
		# Pocket changes can switch between pickup and placement intent. Resolve
		# that immediately so selecting a part and clicking in one frame works.
		_update_target()
	if paused: return
	if event is InputEventMouseMotion:
		if rotate_held:
			if event.relative.length() > 0.5: rotate_dragged = true
			_rotate_station(event.relative)
		else:
			player.rotate_y(-event.relative.x*0.0022)
			camera.rotation.x = clampf(camera.rotation.x-event.relative.y*0.0022,-1.35,1.35)
	if event is InputEventMouseButton and event.pressed:
		# macOS reports Control + left click as right + Control. Control is
		# also our crouch key, so accept that event as a placement click.
		var control_click = OS.has_feature("macos") and event.button_index == MOUSE_BUTTON_RIGHT and event.ctrl_pressed
		if event.button_index == MOUSE_BUTTON_LEFT or control_click: attach()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP: camera.fov = maxf(42,camera.fov-5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: camera.fov = minf(85,camera.fov+5)

func _physics_process(delta: float) -> void:
	if not started: return
	if is_instance_valid(m2):m2.physics(delta)
	if foot_equipment_available():foot_fixture.physics(delta)
	for lift in access_lifts.values():lift.physics(delta)
	if not paused and not (is_instance_valid(m2_crane) and m2_crane.console.is_open):
		_update_crouch(movement_pressed(KEY_CTRL),delta)
		var move = Vector2(float(movement_pressed(KEY_D))-float(movement_pressed(KEY_A)),float(movement_pressed(KEY_S))-float(movement_pressed(KEY_W))).normalized()
		var direction = player.basis*Vector3(move.x,0,move.y)
		var speed = 4.5 if movement_pressed(KEY_SHIFT) else 2.8
		if crouched: speed = 1.5
		player.velocity.x = move_toward(player.velocity.x,direction.x*speed,delta*16)
		player.velocity.z = move_toward(player.velocity.z,direction.z*speed,delta*16)
	else:
		player.velocity.x = 0
		player.velocity.z = 0
	if jump_requested and not paused and not hud.browser.visible and player.is_on_floor():
		player.velocity.y = JUMP_SPEED
	elif not player.is_on_floor():player.velocity.y -= 14*delta
	else:player.velocity.y = -0.1
	# Airborne presses expire immediately; they cannot turn into a landing jump.
	jump_requested = false
	player.move_and_slide()
	components.physics(delta)
	var previous_build = active_build
	var held = held_build()
	if not held.is_empty():
		_activate(held)
		if not paused:apply_carry_intent(pad,delta)
	_activate(previous_build)
	# A dropped piece cannot disappear permanently under the floor.
	for uid in loose.keys():
		if is_instance_valid(loose[uid]) and loose[uid].global_position.y < -3:
			loose[uid].global_position = Vector3(-0.4,1.2,0.6)
			loose[uid].linear_velocity = Vector3.ZERO
	for id in bodies:
		if bodies[id].global_position.y < -3:
			bodies[id].global_position = home_position(id)+Vector3.UP*0.06
			bodies[id].linear_velocity = Vector3.ZERO

func _process(_delta: float) -> void:
	if not started or paused or (is_instance_valid(m2_crane) and m2_crane.console.is_open): return
	_update_target()
	_update_markers()

func _update_crouch(wants_crouch: bool, delta: float) -> void:
	if crouched and not wants_crouch:
		var shape = CapsuleShape3D.new()
		shape.radius = 0.26
		# Leave a small floor clearance in this occupancy query. The movement
		# capsule remains full height; floor contact must not prevent standing.
		shape.height = 1.68
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(player.global_basis,player.global_position+Vector3.UP*0.87)
		query.collision_mask = WORLD_MASK
		var excluded: Array[RID] = [player.get_rid()]
		for body in bodies.values():
			if body.held:excluded.append(body.get_rid())
		if is_instance_valid(components.held_body):excluded.append(components.held_body.get_rid())
		query.exclude = excluded
		query.margin = 0.001
		wants_crouch = not get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()
	crouched = wants_crouch
	player_collision.shape.height = 1.0 if crouched else 1.7
	player_collision.position.y = 0.51 if crouched else 0.86
	camera.position.y = move_toward(camera.position.y,0.93 if crouched else 1.63,delta*4.5)

func _aim_score(point: Vector3, radius: float) -> float:
	var offset = point-camera.global_position
	var ahead = offset.dot(-camera.global_basis.z)
	if ahead < 0.05: return INF
	var perpendicular = (offset+camera.global_basis.z*ahead).length()
	if perpendicular > radius: return INF
	return perpendicular/radius + ahead*0.008

func _visible(point: Vector3, allowed: Array = [], allow_body_hit: bool = false) -> bool:
	var query = PhysicsRayQueryParameters3D.create(camera.global_position,point,WORLD_MASK)
	var excluded: Array[RID] = [player.get_rid()]
	for body in bodies.values():
		if body.held:excluded.append(body.get_rid())
	if is_instance_valid(components.held_body):excluded.append(components.held_body.get_rid())
	if allow_body_hit:
		for receiver in allowed:
			if not is_instance_valid(receiver):continue
			if receiver is CollisionObject3D:excluded.append(receiver.get_rid())
			for body in bodies.values():
				if receiver.is_ancestor_of(body):excluded.append(body.get_rid())
	query.exclude = excluded
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return true
	if allowed.has(hit.collider):
		if allow_body_hit:return true
		# A surface at the destination is expected; hitting the back/side far
		# before the target is an occlusion, even on the same assembly.
		return hit.position.distance_to(point) < 0.065
	return hit.position.distance_to(point) < 0.025

func bind_build_views(scenario: Dictionary) -> void:
	builds.clear()
	for build in scenario.builds:
		var view = HeelAssemblyState.new()
		view.bind(model,build.id)
		builds[build.id] = view

func _activate(id: String) -> void:
	active_build = id
	state = builds[id]
	if bodies.has(id):
		pad = bodies[id]
		pad_mesh = pad.get_child(0)

func held_build() -> String:
	for id in builds:
		if builds[id].pad_location == "held":return id
	return ""

func home_position(id: String) -> Vector3:
	for build in config.builds:
		if build.id == id:return Vector3(build.home[0],build.home[1],build.home[2])
	return PAD_HOME

func build_label(id: String) -> String:
	for build in config.builds:
		if build.id == id:
			var definition: Dictionary = model.definitions.assemblies[build.definition]
			var family: String = definition.get("part_id",model.definitions.parts[definition.slots[definition.root_slot].accepts].family)
			return family+" · "+build.get("label",definition.get("title",id))
	if model.assemblies.has(id):return model.definitions.assemblies[model.assemblies[id].definition].get("title",id)
	return id

func connection(index: int) -> Vector3:
	var point: Array = model.definitions.assemblies.heel_pad.slots["sleeve_%d"%index].target
	return pad.global_transform*Vector3(point[0],point[1],point[2])

func default_parent_id() -> String:
	var parents = AssemblyModel.scenario_parents(config)
	return parents[0].id if not parents.is_empty() else ""

func source_uid(uid: String) -> String:
	return model.source_uid(uid)

func assembly_node(owner: String) -> Node3D:
	return runtime.node(owner)

func assembly_frame(owner: String) -> Transform3D:
	return runtime.frame_transform(owner)

func slot_pose(owner: String, sid: String) -> Transform3D:
	return runtime.slot_pose(owner,sid)

func interactable_assembly(owner: String) -> bool:
	if not model.assemblies.has(owner):return false
	var top: String = model.top_level(owner)
	if top.is_empty():return false
	var location: String = model.assemblies[top].location
	return location == "fixture" or location.begins_with("station:") or location.begins_with("support:")

func equipment_access_error(owner: String) -> String:
	if is_instance_valid(m2):
		var error: String = m2.equipment_access_error(owner)
		if not error.is_empty():return error
	if not foot_equipment_available() or not model.assemblies.has(owner):return ""
	if model.top_level(owner) != default_parent_id():return ""
	if foot_fixture.moving:return "Wait for the foot fixture to stop before working on its connections."
	if foot_fixture.at_dispatch:return "Return the foot to the assembly bay before changing its connections."
	return ""

func mount_transform(slot: String = "", owner: String = "", child: String = "") -> Transform3D:
	if owner.is_empty():owner = target.get("owner",model.assemblies[active_build].parent)
	if owner.is_empty():owner = default_parent_id()
	if slot.is_empty():slot = target.get("mount",state.mount_slot)
	if slot.is_empty():slot = "heel_1"
	if child.is_empty():child = active_build
	return runtime.mount_pose(owner,slot,child)

func mount_point(slot: String = "", owner: String = "", child: String = "") -> Vector3:
	if owner.is_empty():owner = target.get("owner",default_parent_id())
	if slot.is_empty():slot = target.get("mount",state.mount_slot)
	if slot.is_empty():
		for sid in model.assemblies[owner].slots:
			if model.slot_definition(owner,sid).get("assembly","") == model.assemblies[active_build if child.is_empty() else child].definition:
				slot = sid
				break
	var definition: Dictionary = model.slot_definition(owner,slot)
	if definition.has("target") or definition.has("target_position"):
		return assembly_node(owner).global_transform*AssemblyRuntime.vec(definition.get("target",definition.get("target_position",[])))
	return mount_transform(slot,owner,child)*Vector3(0,-0.085,0) if definition.get("assembly","") == "heel_pad" else slot_pose(owner,slot).origin

func placement_destination() -> Transform3D:
	return stations[target.get("station","prep")].global_transform if target.type == "prep" else mount_transform()

func apply_carry_intent(body: WorkshopPart, delta: float) -> void:
	var profile: Dictionary = model.definitions.assemblies[model.assemblies[body.get_meta("assembly_id")].definition].get("handling",{}).duplicate() if body.has_meta("assembly_id") else model.definitions.parts[body.kind].get("handling",{}).duplicate()
	var grip_basis = PREP_BASIS if body.has_meta("assembly_id") else Basis.from_euler(AssemblyRuntime.vec(profile.get("rotation_degrees",[0,0,0]))*PI/180.0)
	profile["basis"] = grip_basis
	if body.has_meta("assembly_id"):
		profile["distance"] = profile.get("distance",1.25)
	body.carry_target = camera.global_position+camera.global_basis*SolidHandling.carry_offset(body,camera.global_basis,profile)
	body.carry_basis = camera.global_basis*grip_basis
	body.max_surface_travel = float(profile.get("rotation_step_travel",0.025))
	body.update_grip(delta)

func refresh_assembly_collision(owner: String) -> void:
	if not runtime or not runtime.nodes.has(owner):return
	var root: String = model.top_level(owner)
	for member in runtime.descendants(root):
		var body: CollisionObject3D = runtime.node(member)
		# Child bodies are frozen scene frames. The top owner carries the compound,
		# so carrying cannot leave competing solid child bodies behind.
		if body is RigidBody3D:
			body.collision_layer = 2 if member == root else 0
			body.collision_mask = WORLD_MASK if member == root else 0
		for col in body.get_children():
			if col is CollisionShape3D and (body is WorkshopPart or col.has_meta("assembly_collision")):
				body.remove_child(col)
				col.queue_free()
		body.set_meta("collision_revision",int(body.get_meta("collision_revision",0))+1)
	var carrier: CollisionObject3D = runtime.node(root)
	var index = 0
	for piece in runtime.visual_pieces(root):
		var visual: MeshInstance3D = piece.visual
		var uid: String = visual.get_meta("component_uid",visual.get_meta("installed_uid",""))
		var profile: Array = []
		if model.items.has(uid):profile = model.definitions.parts[model.items[uid].kind].get("collision_shapes",[])
		var sid: String = visual.get_meta("slot_id","")
		if not sid.is_empty():profile = model.slot_definition(piece.owner,sid).get("collision_shapes",profile)
		# Pocket hardware remains visible and owned, with carrying collision only
		# when its part or receiving slot authors a deliberate proxy.
		if model.items.has(uid) and model.definitions.parts[model.items[uid].kind].carry_class == "pocket" and profile.is_empty():continue
		for entry in SolidHandling.authored_shapes(profile,visual.mesh.get_aabb()):
			var col = CollisionShape3D.new()
			col.name = "CollisionShape3D" if index == 0 else "AssemblySolid%d"%index
			col.shape = entry.shape
			col.transform = piece.transform*entry.transform
			col.set_meta("assembly_collision",true)
			col.set_meta("physical_uid",uid)
			carrier.add_child(col)
			index += 1
	carrier.set_meta("collision_revision",int(carrier.get_meta("collision_revision",0))+1)

func _update_target() -> void:
	target = {}
	var best: float = INF
	var candidates: Array[Dictionary] = []
	var previous_build = active_build
	var held = held_build()
	var fitting_part = held.is_empty() and not components.selected_uid(selected_kind).is_empty()
	for id in builds:
		_activate(id)
		if held.is_empty() and (fitting_part or state.pad_location == "foot") and not components.is_component_build(id) and ["prep","foot"].has(state.pad_location):
			for i in range(4):candidates.append({"type":"slot","build":id,"index":i,"point":connection(i),"radius":0.15})
		if state.pad_location in ["loose","prep"]:
			candidates.append({"type":"pad","build":id,"point":pad.global_position,"radius":0.40})
	if not held.is_empty():
		_activate(held)
		for station in stations:
			candidates.append({"type":"prep","build":held,"station":station,"point":stations[station].global_position,"radius":0.48})
		for owner in model.assemblies:
			if owner == held or not interactable_assembly(owner):continue
			for sid in model.assemblies[owner].slots:
				var slot: Dictionary = model.slot_definition(owner,sid)
				if slot.get("assembly","") != model.assemblies[held].definition or not model.assemblies[owner].slots[sid].is_empty():continue
				if not model.assembly_access_error(owner,sid).is_empty():continue
				candidates.append({"type":"mount","owner":owner,"build":held,"mount":sid,"point":mount_point(sid,owner,held),"radius":0.30})

	_activate(previous_build if held.is_empty() else held)
	for kind in bins:candidates.append({"type":"bin","kind":kind,"point":bins[kind].global_transform*Vector3(0,0.13,0.27),"radius":0.35})
	for uid in loose:
		if is_instance_valid(loose[uid]):candidates.append({"type":"loose","uid":uid,"point":loose[uid].global_position,"radius":0.12})
	if foot_equipment_available():candidates.append_array(foot_fixture.controls())
	if is_instance_valid(m2):
		candidates = candidates.filter(func(entry):return entry.type == "loose" or (entry.type == "bin" and model.count_at(entry.kind,"bin") > 0))
		candidates.append_array(m2.controls())
	for lift in access_lifts.values():candidates.append_array(lift.controls())
	if held.is_empty():
		for candidate in components.candidates():
			# Fixed/mounted builds have no competing pickup action; retain their
			# connection inspection even when no pocket is selected.
			if not m2_trial.is_empty():
				var allowed_slots: Dictionary = leg_content.m2.playable_slots
				if not candidate.owner in allowed_slots or not candidate.sid in allowed_slots[candidate.owner]:continue
			if fitting_part or not builds.has(model.top_level(candidate.owner)):candidates.append(candidate)
	var scored: Array[Dictionary] = []
	var focused_connections: Dictionary = {}
	var discovery_hits: Dictionary = {}
	var precise_snap = false
	for candidate in candidates:
		if camera.global_position.distance_to(candidate.point) > SNAP_DISCOVERY_RANGE: continue
		var score = _aim_score(candidate.point,candidate.radius)
		if score == INF:
			if not _snap_candidate_valid(candidate):continue
			var owner: String = model.top_level(candidate.get("owner",candidate.get("build","")))
			if not discovery_hits.has(owner):discovery_hits[owner] = _assembly_discovery_hit(owner)
			if discovery_hits[owner] == null:continue
			candidate["discovery_only"] = true
			candidate["discovery_hit"] = discovery_hits[owner]
			# Precise compatible aim wins; otherwise reveal the closest compatible
			# connection on the workpiece intersected by the view ray.
			var offset: Vector3 = candidate.point-camera.global_position
			var perpendicular = (offset+camera.global_basis.z*offset.dot(-camera.global_basis.z)).length()
			score = 0.75+minf(perpendicular,10.0)*0.01
		var connection_visible = true
		# While holding hardware, a nearby socket wins over the pad's center.
		if candidate.type == "slot":
			score -= 0.12
			connection_visible = _visible(candidate.point,[bodies[candidate.build],foot])
		if candidate.type == "component":
			score -= 1.0 if candidate.get("compatible",false) else 0.12
			connection_visible = _visible(candidate.point,components.receiving_bodies(candidate.owner,candidate.sid),components.service_access(candidate.owner,candidate.sid))
			if not connection_visible:score += 1.0
		if connection_visible and candidate.type in ["slot","component"]:
			var owner: String = candidate.get("owner",candidate.get("build",""))
			focused_connections[model.top_level(owner)] = true
		if connection_visible and not candidate.get("discovery_only",false) and _snap_candidate_valid(candidate):precise_snap = true
		scored.append({"candidate":candidate,"score":score})
	for entry in scored:
		var candidate: Dictionary = entry.candidate
		if precise_snap and candidate.get("discovery_only",false):continue
		# Connection feedback and whole-assembly pickup describe the same object.
		# With a part selected, a nearby connection owns that object's focus instead
		# of trading places with its center as the geometric scores fluctuate.
		if candidate.type == "pad" and focused_connections.has(candidate.build):continue
		var score: float = entry.score
		if score < best:
			best = score
			target = candidate
	if target.has("build"):_activate(target.build)
	# Share one current access result between prompt and preview. Actual clicks
	# always recheck access, and incompatible parts never run a placement sweep.
	var access_error = _access(_target_receivers(),target.type == "prep" or _snap_candidate_valid(target)) if not target.is_empty() else ""
	_present_target(access_error)
	_update_ghost(access_error)

func _assembly_discovery_hit(owner: String) -> Variant:
	var body: CollisionObject3D = assembly_node(owner)
	var inverse = body.global_transform.affine_inverse()
	var hit: Variant = SolidHandling.bounds(body).intersects_ray(inverse*camera.global_position,inverse.basis*(-camera.global_basis.z))
	if hit == null:return null
	var point: Vector3 = body.global_transform*hit
	if camera.global_position.distance_to(point) > SNAP_DISCOVERY_RANGE:return null
	# The cheap box belongs to the workpiece, not its stand or scaffold. Test
	# scenery along the view ray as well as the eventual connection's sightline.
	return point if _visible(point,[body],true) else null

func _snap_candidate_valid(candidate: Dictionary) -> bool:
	var owner: String = candidate.get("owner",candidate.get("build",""))
	if not equipment_access_error(owner).is_empty():return false
	match candidate.get("type",""):
		"component":
			var uid: String = components.selected_uid(selected_kind)
			return not uid.is_empty() and model.placement_error(owner,candidate.sid,uid).is_empty()
		"mount":
			return model.assemblies[candidate.build].location == "held" and model.placement_error(owner,candidate.mount,candidate.build).is_empty()
		"slot":
			var view = builds[candidate.build]
			return HeelAssemblyState.KINDS.has(selected_kind) and view.count_at(selected_kind,"pocket") > 0 and view.reason(selected_kind,candidate.index).is_empty()
	return false

func _target_receivers() -> Array:
	match target.get("type",""):
		"equipment":return target.get("allowed",[])
		"bin":return [bins[target.kind]]
		"pad":return [pad]
		"loose":return [loose[target.uid]]
		"component":return components.receiving_bodies(target.owner,target.sid)
		"mount":return [pad,assembly_node(model.top_level(target.owner))]
	return [pad,foot]

func _target_object() -> Node3D:
	match target.get("type",""):
		"equipment":return target.get("node",null)
		"bin":
			var bin: Node3D = bins[target.kind]
			return bin.get_node("ShelfPart") if bin.has_node("ShelfPart") else bin
		"loose":return loose[target.uid]
		"pad", "slot":return bodies[target.build]
		"component", "mount":return assembly_node(target.owner)
	return null

func _present_target(access_error: String) -> void:
	if target.is_empty() or paused:
		hud.present_target("")
		if is_instance_valid(interaction_outline):interaction_outline.clear()
		return
	var receivers = _target_receivers()
	# A prompt should not disclose a connection through unrelated scenery. Keep
	# the target itself so attempting the action can still explain an obstruction.
	if camera.is_position_behind(target.point) or not _visible(target.point,receivers,_target_allows_body_hit()):
		hud.present_target("")
		if is_instance_valid(interaction_outline):interaction_outline.clear()
		return
	var caption = ""
	var detail = ""
	var action_key = ""
	var action_label = ""
	var usable = false
	var pickup_target = false
	match target.type:
		"equipment":
			caption = target.label
			detail = equipment_controller(target).action_error(target.action)
			usable = detail.is_empty()
			if usable:
				action_key = "Click" if target.get("input","") == "place" else "E"
				action_label = "Place" if target.get("input","") == "place" else ("Operate" if m2_trial.is_empty() else "Use")
		"bin":
			pickup_target = true
			var count: int = model.count_at(target.kind,"bin")
			var pocket: bool = model.definitions.parts[target.kind].carry_class == "pocket"
			caption = components.title(target.kind)
			detail = "%d available" % count
			if count > 0 and (pocket or not model.hands_occupied()):
				action_key = "E"
				action_label = "Stock pocket" if pocket else "Carry"
				usable = true
			elif count > 0:detail = "Set down the carried component first"
		"pad":
			pickup_target = true
			caption = build_label(active_build)
			detail = "Prepared" if state.prepared() else "Unfinished"
			if not model.hands_occupied():
				action_key = "E"
				action_label = "Carry"
				usable = true
			else:detail = "Set down the carried component first"
		"loose":
			pickup_target = true
			caption = components.title(model.items[target.uid].kind)
			if not model.hands_occupied():
				action_key = "E"
				action_label = "Carry"
				usable = true
			else:detail = "Set down the carried component first"
		"prep":
			caption = "Preparation station"
			usable = true
		"mount":
			caption = model.slot_definition(target.owner,target.mount).get("label",target.mount)
			detail = model.placement_error(target.owner,target.mount,active_build)
			usable = detail.is_empty()
		"component":
			var spec = model.slot_definition(target.owner,target.sid)
			caption = components.title(spec.accepts)
			detail = model.placement_error(target.owner,target.sid,components.selected_uid(selected_kind))
			usable = detail.is_empty()
		"slot":
			caption = build_label(active_build)+" · mounting point %d" % (target.index+1)
			if state.complete():detail = "Complete"
			elif selected_kind.is_empty():
				if state.pad_location == "prep" and not model.hands_occupied():
					action_key = "E"
					action_label = "Carry assembly"
					usable = true
					pickup_target = true
				else:detail = "Select a stocked pocket"
			else:
				caption = components.title(selected_kind)
				detail = state.reason(selected_kind,target.index)
				usable = detail.is_empty()
	if not access_error.is_empty():
		detail = _snap_guidance_message() if _snap_guidance_available() else ("" if camera.global_position.distance_to(target.point) > REACH else access_error)
		usable = false
	if not usable:
		action_key = ""
		action_label = ""
	if is_instance_valid(interaction_outline):
		# Contours advertise collection, not every available keyboard action.
		if usable and pickup_target:interaction_outline.focus(_target_object())
		else:interaction_outline.clear()
	# The green geometry is the successful attachment affordance. Only explain
	# failures here; collection still needs its small keyboard action prompt.
	if usable and action_key.is_empty():
		hud.present_target("")
		return
	if not detail.is_empty():caption += "\n"+detail
	hud.present_target(caption,action_key,action_label,camera.unproject_position(target.point),usable)

func _target_allows_body_hit() -> bool:
	if target.get("type","") == "equipment":return target.get("allow_body_hit",false)
	if target.get("type","") == "component":return components.service_access(target.owner,target.sid)
	if target.get("type","") == "mount":return components.service_access(target.get("owner",default_parent_id()),target.mount)
	return target.get("type","") in ["pad","loose"]

func _access(allowed: Array = [], check_approach: bool = true) -> String:
	if target.is_empty(): return "Aim near a part, bin, or mounting point."
	if target.get("discovery_only",false):return _snap_guidance_message()
	if target.type in ["slot","mount","component"]:
		var equipment_error = equipment_access_error(target.get("owner",target.get("build","")))
		if not equipment_error.is_empty():return equipment_error
	if target.type == "component":return components.access(check_approach)
	if camera.global_position.distance_to(target.point) > REACH: return "Out of reach. Move closer to the connection (maximum %.2f m)." % REACH
	if not _visible(target.point,allowed,_target_allows_body_hit()): return "Connection is obstructed. Approach its exposed side or use the work-position controls."
	if target.type == "equipment":return equipment_controller(target).action_error(target.action)
	if target.type == "prep":
		var station: Node3D = stations[target.get("station","prep")]
		var envelope: Vector3 = SolidHandling.bounds(pad).size
		var volume: Vector3 = station.get_meta("work_volume")
		if envelope.x > volume.x or envelope.y > volume.y or envelope.z > volume.z:return "This assembly needs a larger work volume."
		for id in builds:
			if id != active_build and model.assemblies[id].location == "station:"+target.get("station","prep"):return "This station is occupied. Move its assembly first."
	if target.type in ["prep","mount"] and state.pad_location == "held" and check_approach:
		return _carry_placement_error(placement_destination(),pad,assembly_node(target.owner) if target.has("owner") else null)
	return ""

func _carry_placement_error(destination: Transform3D, carried: WorkshopPart = null, receiving: PhysicsBody3D = null) -> String:
	if carried == null:carried = pad
	if carried.global_position.distance_to(camera.global_position) > REACH+0.75+maxf(0.0,SolidHandling.bounds(carried).size.length()-1.0)*0.7:
		return "The carried assembly is caught or too far away. Bring it alongside you first."
	var excluded: Array[RID] = [carried.get_rid()]
	for exception in carried.get_collision_exceptions():excluded.append(exception.get_rid())
	if receiving:
		if receiving.has_meta("assembly_id"):receiving = assembly_node(model.top_level(receiving.get_meta("assembly_id")))
		excluded.append(receiving.get_rid())
		# Both rigid children and large animatable fixtures belong to the receiver.
		# Unrelated workshop supports remain obstacles throughout the approach.
		if receiving.has_meta("assembly_id"):
			for member in runtime.descendants(receiving.get_meta("assembly_id"),false):
				var child_body: CollisionObject3D = assembly_node(member)
				excluded.append(child_body.get_rid())
	# Only actual receiving owners are excluded; other fixtures stay solid.
	return SolidHandling.sweep_error(carried,destination,excluded,WORLD_MASK)

func interact(all_stock: bool = false) -> void:
	if target.is_empty(): hud.toast("Aim at a drawer, shelf or loose component."); return
	if target.type == "equipment":
		if target.get("input","") == "place":hud.toast("Aim and click to seat this supported component.");return
		var access_error = _access(_target_receivers())
		if not access_error.is_empty():hud.toast(access_error);return
		var controller = equipment_controller(target)
		var equipment_error: String = controller.request(target.action)
		hud.toast(equipment_error if not equipment_error.is_empty() else controller.status_text(),equipment_error.is_empty())
		return
	if target.type == "component" or (target.type == "slot" and target.get("discovery_only",false)):
		# Pickup acts on the physical containing assembly even when its connection
		# is focused for placement. Recheck pickup reach/visibility independently.
		var owner: String = model.top_level(target.owner) if target.type == "component" else target.build
		if not builds.has(owner):hud.toast("This fixture stays at its work station.");return
		var previous_target = target
		target = {"type":"pad","build":owner,"point":target.get("discovery_hit",target.point)}
		_activate(owner)
		interact(all_stock)
		target = previous_target
		return
	var allowed: Array = [pad]
	if target.type == "bin": allowed = [bins[target.kind]]
	if target.type == "loose": allowed = [loose[target.uid]]
	var error = _access(allowed)
	if not error.is_empty(): hud.toast(error);return
	if is_instance_valid(m2) and not m2.hand_error().is_empty():hud.toast(m2.hand_error());return
	match target.type:
		"bin":components.collect(target.kind,all_stock)
		"pad", "slot":
			if state.pad_location == "foot":hud.toast("The pad is mounted. Undo its installation in the parent manual.");return
			if state.pad_location == "held":return
			var carry_error = state.move_pad("held")
			if not carry_error.is_empty():hud.toast(carry_error);return
			var previous = pad.global_transform
			pad.reparent(self)
			pad.global_transform = previous
			pad.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
			pad.freeze = true
			pad.linear_velocity = Vector3.ZERO
			pad.angular_velocity = Vector3.ZERO
			pad.held = true
			pad.gravity_scale = 0
			pad.collision_layer = 2
			pad.collision_mask = WORLD_MASK
		"loose":components.collect(state.items[target.uid].kind,false,target.uid)
	hud.refresh()

func attach() -> void:
	if is_instance_valid(m2) and target.get("type","") == "equipment":
		if target.get("input","") == "pickup":hud.toast("Use E to pick up this equipment payload.");return
		var error = _access(_target_receivers())
		if error.is_empty():error = equipment_controller(target).request(target.action)
		hud.toast(error if not error.is_empty() else equipment_controller(target).status_text(),error.is_empty())
		return
	if target.get("type","") == "component":components.attach();return
	var allowed: Array = [pad]
	if target.has("owner"):allowed.append(assembly_node(model.top_level(target.owner)))
	elif is_instance_valid(foot):allowed.append(foot)
	var error = _access(allowed)
	if not error.is_empty():hud.toast(error);return
	if target.type == "prep" and state.pad_location == "held":
		var station: String = target.get("station","prep")
		var station_error = model.move_assembly(active_build,"station:"+station)
		if not station_error.is_empty():hud.toast(station_error);return
		_set_pad_station(station)
		hud.toast("Assembly suspended.",true)
	elif target.type == "mount" and state.pad_location == "held":
		var result = model.install(target.get("owner",default_parent_id()),target.get("mount","heel_1"),active_build)
		if not result.ok:hud.toast(result.error);return
		_set_pad_foot()
		if single_pad:hud.open_manual(model.assemblies[active_build].parent,1)
		hud.toast("Assembly seated. Follow the receiving manual to secure its connections.",true)
	elif target.type == "slot":
		var was_prepared = state.prepared()
		var was_complete = state.complete()
		var kind = selected_kind
		var result = state.install(kind,target.index)
		if not result.ok:hud.toast(result.error);return
		_sync_installed_visuals()
		if state.prepared() == was_prepared and state.complete() == was_complete:
			hud.toast("Fitted %s · mounting point %d" % [components.title(kind),target.index+1],true)
	else:
		hud.toast("Select a compatible part and aim at a ready connection.")
	hud.refresh()

func _set_pad_station(station: String = "prep") -> void:
	pad.held = false
	# Attached assemblies inherit their parent's pose; the carrying mode can write
	# an older world pose back between input and physics ticks during rotation.
	pad.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	pad.freeze = true
	pad.gravity_scale = 1
	pad.linear_velocity = Vector3.ZERO
	pad.angular_velocity = Vector3.ZERO
	pad.reparent(stations[station])
	pad.transform = Transform3D.IDENTITY
	refresh_assembly_collision(active_build)

func _set_pad_foot() -> void:
	var parent: String = model.assemblies[active_build].parent
	runtime.mount(parent,state.mount_slot,active_build)
	refresh_assembly_collision(parent)

func _sync_installed_visuals() -> void:
	if components.is_component_build(active_build):components.sync(active_build);return
	for child in pad.get_children():
		if child.has_meta("installed_uid"):
			pad.remove_child(child)
			child.queue_free()
	for kind in HeelAssemblyState.KINDS:
		for i in range(4):
			var uid: String = state.slots[kind][i]
			if uid.is_empty():continue
			# Source instances can bake different axes into their vertices. Use the
			# receiving slot's geometry/pose together, retaining inventory UID below.
			var visual = _mesh(slot_sources[kind][i])
			visual.transform = source["FA-302__001"].transform.affine_inverse()*source[slot_sources[kind][i]].transform
			visual.set_meta("installed_uid",uid)
			pad.add_child(visual)
	pad.set_meta("visual_revision",int(pad.get_meta("visual_revision",0))+1)
	refresh_assembly_collision(active_build)

func drop_selected() -> void:
	if is_instance_valid(m2) and m2.drop():return
	if not model.held_item().is_empty():components.drop();return
	var held = held_build()
	if held.is_empty():hud.toast("Your hands are empty.");return
	_activate(held)
	pad.held = false
	pad.freeze = false
	pad.sleeping = false
	pad.gravity_scale = 1
	pad.linear_velocity = Vector3.ZERO
	state.move_pad("loose")

func _spawn_loose(uid: String, at_output: bool = false) -> void:
	assert(model.definitions.parts[model.items[uid].kind].carry_class != "pocket","Small items stay in drawers, pockets or assemblies.")
	var item = Part.new()
	item.uid = uid
	item.kind = state.items[uid].kind
	item.collision_layer = 2
	item.collision_mask = WORLD_MASK
	add_child(item)
	item.add_child(_mesh(uid))
	var profile: Array = model.definitions.parts[item.kind].get("collision_shapes",[])
	var shape_index = 0
	for entry in SolidHandling.authored_shapes(profile,source[source_uid(uid)].mesh.get_aabb()):
		var col = CollisionShape3D.new()
		col.name = "CollisionShape3D" if shape_index == 0 else "Solid%d"%shape_index
		col.shape = entry.shape
		col.transform = entry.transform
		item.add_child(col)
		shape_index += 1
	var desired = camera.global_position-camera.global_basis.z*0.70
	var query = PhysicsRayQueryParameters3D.create(camera.global_position,desired,WORLD_MASK)
	query.exclude = [player.get_rid(),item.get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	item.global_position = Vector3(-0.4,1.15,0.6) if at_output else (hit.position+hit.normal*0.09 if not hit.is_empty() else desired)
	loose[uid] = item

func deposit() -> void:
	var count = model.clear_pocket()
	hud.toast("Returned %d pieces to their drawer."%count if count else "Selected pocket is empty.",count>0)

func undo_build() -> void:
	var owner: String = hud.manual_id
	if is_instance_valid(m2):
		var result: Dictionary = m2.undo(owner)
		if result.get("handled",false):
			hud.toast(result.get("error","") if not result.get("error","").is_empty() else "Undid the last installation with equipment support.",result.get("error","").is_empty())
			return
	var equipment_error = equipment_access_error(owner)
	if not equipment_error.is_empty():hud.toast(equipment_error);return
	var destination = ""
	for station in stations:
		var occupied = false
		for a in model.assemblies.values():
			if a.location == "station:"+station:occupied = true
		if not occupied:destination = station;break
	if model.assemblies.has(owner) and not model.assemblies[owner].history.is_empty() and model.assemblies[owner].history.back().action == "mount" and destination.is_empty():
		hud.toast("Clear a preparation station before undoing the mount.");return
	var result = model.undo(owner,"station:"+destination)
	if not result.ok:hud.toast(result.error);return
	if result.step.action == "mount":
		_activate(result.step.uid)
		_set_pad_station(destination)
		refresh_assembly_collision(owner)
		if single_pad:hud.open_manual(active_build,1)
	else:
		var uid: String = result.step.uid
		if model.items[uid].location == "loose":_spawn_loose(uid,true)
	var previous_build = active_build
	for id in builds:
		_activate(id)
		_sync_installed_visuals()
	_activate(previous_build)
	for parent in AssemblyModel.scenario_parents(config):components.sync(parent.id)
	hud.toast("Undid the last action in "+hud.manual_title()+".",true)

func _state_changed() -> void:
	if hud:hud.refresh()
	if storage:storage.refresh()
	var previous_build = active_build
	for id in builds:
		_activate(id)
		if state.prepared() and not prepared_flags.get(id,false):_milestone(build_label(id)+" prepared.")
		if state.complete() and not completed_flags.get(id,false):_milestone(build_label(id)+" installation COMPLETE")
		prepared_flags[id] = state.prepared()
		completed_flags[id] = state.complete()
	_activate(previous_build)
	prepared_before = state.prepared()
	completed_before = state.complete()
	var errors = model.integrity_errors()
	assert(errors.is_empty(),"; ".join(errors))

func _milestone(message: String) -> void:
	if hud:hud.toast(message,true)
	if chime and DisplayServer.get_name() != "headless":chime.play()
	var glow = material(Color(0.25,0.95,0.68,0.6),0,true)
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var glowing_mesh = pad_mesh
	glowing_mesh.material_overlay = glow
	var tween = create_tween()
	tween.tween_property(glow,"albedo_color:a",0.0,1.8)
	tween.tween_callback(func():
		if is_instance_valid(glowing_mesh) and glowing_mesh.material_overlay == glow:glowing_mesh.material_overlay = null)

func _update_ghost(access_result: Variant = null) -> void:
	ghost.visible = false
	for child in ghost.get_children():child.visible = false
	if paused:return
	var distant = _snap_guidance_available()
	ghost_material.albedo_color = SNAP_DISTANT_COLOR if distant else SNAP_READY_COLOR
	ghost_material.no_depth_test = target.get("type","") == "component"
	if target.get("type","") == "component":
		if not model.placement_error(target.owner,target.sid,components.selected_uid(selected_kind)).is_empty():return
		if not distant and not (components.access() if access_result == null else access_result).is_empty():return
		ghost.mesh = source[model.slot_definition(target.owner,target.sid).pose_source].mesh
		ghost.global_transform = components.slot_pose(target.owner,target.sid)
		ghost.visible = true
		return
	if target.is_empty():return
	var allowed: Array = [pad]
	if target.has("owner"):allowed.append(assembly_node(model.top_level(target.owner)))
	elif is_instance_valid(foot):allowed.append(foot)
	if not distant and not (_access(allowed) if access_result == null else access_result).is_empty():return
	if target.type == "slot" and HeelAssemblyState.KINDS.has(selected_kind):
		if not state.reason(selected_kind,target.index).is_empty() or state.count_at(selected_kind,"pocket") == 0:return
		var uid: String = slot_sources[selected_kind][target.index]
		ghost.mesh = source[uid].mesh
		var pose: Transform3D = source["FA-302__001"].transform.affine_inverse()*source[uid].transform
		ghost.global_transform = pad.global_transform*pose
		ghost.visible = true
	elif target.type == "mount" and state.pad_location == "held" and model.placement_error(target.get("owner",default_parent_id()),target.mount,active_build).is_empty():
		ghost.mesh = source[source_uid(state.pad_id)].mesh
		ghost.global_transform = mount_transform()
		ghost.visible = true
		_show_assembly_ghost()
	elif target.type == "prep" and state.pad_location == "held":
		ghost.mesh = source[source_uid(state.pad_id)].mesh
		ghost.global_transform = stations[target.get("station","prep")].global_transform
		ghost.visible = true
		_show_assembly_ghost()

func _snap_guidance_message() -> String:
	return "Move closer to attach" if camera.global_position.distance_to(target.point) > REACH else "Aim at the highlighted connection to attach"

func _snap_guidance_available() -> bool:
	# Discovery is feedback only. Placement keeps its normal reach, carrying
	# sweep and access checks; no physics or recipe rule is relaxed here.
	if paused or target.is_empty():return false
	var distance = camera.global_position.distance_to(target.point)
	if (distance <= REACH and not target.get("discovery_only",false)) or distance > SNAP_DISCOVERY_RANGE:return false
	if camera.is_position_behind(target.point):return false
	if not _visible(target.point,_target_receivers(),_target_allows_body_hit()):return false
	if target.has("discovery_hit") and not _visible(target.discovery_hit,[assembly_node(model.top_level(target.get("owner",target.get("build",""))))],true):return false
	return _snap_candidate_valid(target)

func _show_assembly_ghost() -> void:
	ghost.mesh = null
	var pieces = runtime.visual_pieces(active_build)
	var key = active_build
	for member in runtime.descendants(active_build):key += ":"+member+":"+str(assembly_node(member).get_meta("visual_revision",0))
	if key != ghost_assembly_signature:
		for child in ghost.get_children():
			ghost.remove_child(child)
			child.queue_free()
		for piece in pieces:
			var visual: MeshInstance3D = piece.visual
			var preview = MeshInstance3D.new()
			preview.mesh = visual.mesh
			preview.transform = piece.transform
			preview.material_override = ghost_material
			preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			preview.set_meta("component_uid",visual.get_meta("component_uid",visual.get_meta("installed_uid","")))
			preview.set_meta("source_uid",visual.get_meta("source_uid",""))
			preview.set_meta("body_visual",visual)
			ghost.add_child(preview)
		ghost_assembly_signature = key
	for child in ghost.get_children():
		var visual = child.get_meta("body_visual")
		child.visible = is_instance_valid(visual) and visual.visible

func _update_markers() -> void:
	var previous_build = active_build
	var marker_index = 0
	for id in builds:
		if components.is_component_build(id):continue
		_activate(id)
		for i in range(4):
			var point = connection(i)
			var marker = socket_markers[marker_index]
			marker_index += 1
			marker.visible = ["prep","foot"].has(state.pad_location) and camera.global_position.distance_to(point)<3.5 and _visible(point,[pad,foot]) and state.slots.bolt[i] == ""
			marker.global_position = point
	_activate(previous_build)

func _station_in_view() -> String:
	var selected = "foot"
	var best = _aim_score(foot.global_position,1.9)
	for id in stations:
		var score = _aim_score(stations[id].global_position,0.9)
		if score < best:best = score;selected = id
	return "" if best == INF else selected

func _rotate_station(relative: Vector2) -> void:
	if not m2_trial.is_empty():return
	var station = rotation_station if rotate_held else _station_in_view()
	if station.is_empty():return
	if station == "foot" and is_instance_valid(foot_fixture):return
	var node: Node3D = stations.get(station,foot)
	if camera.global_position.distance_to(node.global_position)>5.0:return
	node.basis = (Basis(camera.global_basis.y,-relative.x*0.006)*Basis(camera.global_basis.x,-relative.y*0.006)*node.basis).orthonormalized()

func _rotation_key(pressed: bool) -> void:
	if not m2_trial.is_empty():
		rotate_held = false
		if pressed:hud.toast("The sample stays on its rail fixture. Use its local motion controls.")
		return
	if pressed:
		rotate_held = true
		rotate_dragged = false
		rotate_press_time = Time.get_ticks_msec()
		rotation_station = _station_in_view()
		if rotation_station == "foot" and is_instance_valid(foot_fixture):
			rotate_held = false
			rotation_station = ""
			hud.toast("Use the foot bay controls to choose a supported work position.")
	else:
		var now = Time.get_ticks_msec()
		if rotate_held and not rotate_dragged and now-rotate_press_time <= 250 and not rotation_station.is_empty():
			if now-last_rotate_tap <= 350 and last_rotate_station == rotation_station:
				reset_station(rotation_station)
				last_rotate_tap = -1000
			else:
				last_rotate_tap = now
				last_rotate_station = rotation_station
		else:last_rotate_tap = -1000
		rotate_held = false
		rotation_station = ""

func reset_station(station: String = "") -> void:
	if not m2_trial.is_empty():return
	if station.is_empty():station = _station_in_view()
	if station.is_empty():return
	if station == "foot" and is_instance_valid(foot_fixture):
		hud.toast("Choose Upright at the foot bay controls.")
		return
	var node: Node3D = stations.get(station,foot)
	if camera.global_position.distance_to(node.global_position)>5.0:return
	if stations.has(station):stations[station].basis = PREP_BASIS
	elif station == "foot":foot.basis = FOOT_BASIS
	hud.toast("Station returned to its working orientation.",true)

func reset_demo() -> void:
	if is_instance_valid(saves):saves.new_workshop()
	else:get_tree().reload_current_scene()

func _capture_preview() -> void:
	set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://verification/workshop.png")
	print("PREVIEW_SAVED")
	get_tree().quit()

func _position_m2_stock() -> void:
	# Ground stock feeds pockets and the lift's finite component shelf.
	var index = 0
	for kind in bins:
		if model.count_at(kind,"bin") == 0:
			bins[kind].hide()
			continue
		var node: Node3D = bins[kind]
		if node.get_parent() != self:node.reparent(self)
		node.global_position = Vector3(6.4+index*1.15,.7,20.7) if m2_trial == "retention" else Vector3(8.3+index*.9,.7,14.2)
		node.rotation = Vector3.ZERO
		box(leg_layout,Vector3(node.global_position.x,.245,node.global_position.z),Vector3(.8,.49,.55),material(Color("506971")),true)
		index += 1
