extends Node3D

const Part = preload("res://scripts/loose_part.gd")
const HUD = preload("res://scripts/hud.gd")
const FOOT_CENTER = Vector3(0,0.8,-0.7)
const PREP_POSITION = Vector3(-2.3,1.35,-1.2)
const FOOT_POSITION = Vector3(2.3,2.0,-1.8)
const PREP_BASIS = Basis(Vector3.RIGHT,-PI/2)
const FOOT_BASIS = Basis(Vector3.BACK,PI) * Basis(Vector3.RIGHT,-PI/2)
const REACH = 2.35
const WORLD_MASK = 7
const PAD_HOME = Vector3(-1.0,1.09,3.25)

var model = AssemblyModel.new()
var components: Node
var storage: Node
var pitch_workshop: bool = false
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

func _ready() -> void:
	single_pad = OS.get_cmdline_user_args().has("--single-pad")
	automated_test = OS.get_cmdline_user_args().has("--demo-test") or OS.get_cmdline_user_args().has("--multi-test") or OS.get_cmdline_user_args().has("--pitch-test") or OS.get_cmdline_user_args().has("--pockets-test")
	config = HeelAssemblyState.scenario(single_pad)
	pitch_workshop = not single_pad and not OS.get_cmdline_user_args().has("--pads-only") and not OS.get_cmdline_user_args().has("--multi-test")
	var data = HeelAssemblyState.definition_data(single_pad)
	if pitch_workshop:
		config = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pitch-workshop.json"))
		var overlay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(config.definitions))
		data.parts.merge(overlay.parts,true)
		data.assemblies.merge(overlay.assemblies,true)
	components = preload("res://scripts/component_interaction.gd").new(self)
	add_child(components)
	var errors = model.configure(data,config)
	assert(errors.is_empty(),str(errors))
	for build in config.builds:
		var view = HeelAssemblyState.new()
		view.bind(model,build.id)
		builds[build.id] = view
	state = builds[active_build]
	for definition in config.parts:
		active_ids.append(definition.instance_id)
		part_defs[definition.instance_id] = definition
	_make_world()
	_load_foot()
	_make_player()
	for build in config.builds:
		_activate(build.id)
		_make_pad()
	_activate("pad_1")
	components.setup()
	storage = preload("res://scripts/part_storage.gd").new(self)
	add_child(storage)
	storage.setup()
	ghost_material = material(Color(0.35,1.0,0.73,0.40),0.0)
	ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	ghost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ghost_material.cull_mode = BaseMaterial3D.CULL_BACK
	ghost = MeshInstance3D.new()
	ghost.material_override = ghost_material
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ghost)
	ghost.visible = false
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
	model.changed.connect(_state_changed)
	_make_audio()
	_state_changed()
	set_paused(true)
	started = true
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
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.modulate = color
	label.outline_size = 0
	label.no_depth_test = false
	parent.add_child(label)
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
	box(self,Vector3(0,-0.15,0),Vector3(22,0.3,20),floor_mat,true)
	box(self,Vector3(0,4,-7),Vector3(22,8,0.3),wall_mat,true)
	box(self,Vector3(-10.8,4,0),Vector3(0.3,8,14),wall_mat,true)
	box(self,Vector3(10.8,4,0),Vector3(0.3,8,14),wall_mat,true)
	box(self,Vector3(0,4,9.8),Vector3(22,8,0.3),wall_mat,true)
	for x in range(-10,11,2):
		box(self,Vector3(x,0.002,0),Vector3(0.016,0.004,19),material(Color("687875")))
	for z in range(-6,10,2):
		box(self,Vector3(0,0.003,z),Vector3(21,0.004,0.016),material(Color("687875")))
	for x in [-8.0,-4.0,0.0,4.0,8.0]:
		box(self,Vector3(x,4,-6.78),Vector3(0.22,8,0.26),metal)
		box(self,Vector3(x,6.7,0),Vector3(0.18,0.3,14),dark)
		box(self,Vector3(x,6.5,-1),Vector3(0.10,0.06,5),material(Color("fff3d5"),0,true))
	sign_text(self,"FA / 01",Vector3(0,5.3,-6.8),120,Color("3c555c"),0.013)
	sign_text(self,"COMPONENT ASSEMBLY    /    LOWER LIMB DIVISION",Vector3(0,4.25,-6.8),28,Color("3c555c"),0.01)
	# Pad rests on a separate preparation table; the player chooses when to carry it.
	box(self,Vector3(-0.1,0.92,PAD_HOME.z),Vector3(3.4,0.12,1.25),dark,true)
	for x in [PAD_HOME.x-0.6,PAD_HOME.x+0.6]:
		for z in [PAD_HOME.z-0.5,PAD_HOME.z+0.5]: box(self,Vector3(x,0.43,z),Vector3(0.09,0.86,0.09),metal,true)
	sign_text(self,"FA-302 / HEEL PAD",Vector3(PAD_HOME.x,0.92,PAD_HOME.z+0.64),19,Color("dfe9e5"),0.006)
	# A nearby stock tray gives organisation a physical purpose.
	box(self,Vector3(-0.4,0.86,0.6),Vector3(1.1,0.10,0.7),dark,true)
	for x in [-0.85,0.05]: box(self,Vector3(x,0.40,0.6),Vector3(0.07,0.8,0.55),metal,true)
	for x in [-0.94,0.14]: box(self,Vector3(x,0.96,0.6),Vector3(0.03,0.12,0.70),warm,true)
	for z in [0.26,0.94]: box(self,Vector3(-0.4,0.96,z),Vector3(1.1,0.12,0.03),warm,true)
	_station_frame(PREP_POSITION,Vector3(1.05,1.1,0.9),"02 / PREPARATION A",dark,warm)
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

func _station_frame(center: Vector3, dimensions: Vector3, title: String, dark: Material, warm: Material) -> void:
	var half = dimensions/2
	for x in [-half.x,half.x]:
		for z in [-half.z,half.z]:
			# Rear posts preserve an open view and access to the work volume.
			if z < 0: box(self,Vector3(center.x+x,center.y,center.z+z),Vector3(0.045,dimensions.y,0.045),dark,true)
			box(self,Vector3(center.x+x,maxf(0.03,center.y-half.y),center.z+z),Vector3(0.15,0.045,0.15),warm)
	for y in [-half.y,half.y]:
		box(self,center+Vector3(0,y,-half.z),Vector3(dimensions.x,0.035,0.035),dark)
		for x in [-half.x,half.x]:box(self,center+Vector3(x,y,0),Vector3(0.035,0.035,dimensions.z),dark)
	sign_text(self,title,center+Vector3(0,half.y+0.27,0.0),23,Color("233940"),0.008)

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
		if active_ids.has(uid):
			if sections[0] != "FA-302":type_sources[part_defs[uid].kind] = uid
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
			var aabb: AABB = node.mesh.get_aabb()
			var shape = BoxShape3D.new()
			shape.size = aabb.size.max(Vector3(0.02,0.02,0.02))
			var col = CollisionShape3D.new()
			col.shape = shape
			col.transform = node.transform
			col.position += aabb.get_center()-FOOT_CENTER
			foot.add_child(col)
	for kind in HeelAssemblyState.KINDS:
		for i in range(4):
			var definition = model.definitions.assemblies.heel_pad.slots["sleeve_%d"%i] if kind == "sleeve" else model.definitions.assemblies.foot.slots["heel_1/%s_%d"%[kind,i]]
			slot_sources[kind].append(definition.pose_source)
	assert(source.size() == 745,"Foot source must retain the full inventory.")

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
	camera.fov = 75
	player.add_child(camera)
	camera.current = true

func _mesh(uid: String) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	mesh.mesh = source[uid].mesh
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
	var col = CollisionShape3D.new()
	var bounds = BoxShape3D.new()
	var dimensions: Array = model.definitions.assemblies[model.assemblies[active_build].definition].bounds
	bounds.size = Vector3(dimensions[0],dimensions[1],dimensions[2])
	if components.is_component_build(active_build):
		# The loose starting barrel rests on its own geometry. The station restores
		# the full assembly envelope when construction begins.
		var root_bounds = pad_mesh.mesh.get_aabb()
		bounds.size = root_bounds.size
		col.position = root_bounds.get_center()
	col.name = "CollisionShape3D"
	col.shape = bounds
	pad.add_child(col)
	pad.add_collision_exception_with(player)
	player.add_collision_exception_with(pad)
	pad.position = home_position(active_build)
	bodies[active_build] = pad

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
	paused = value
	rotate_held = false
	rotation_station = ""
	last_rotate_tap = -1000
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	if hud:
		hud.pause_panel.visible = value
		hud.crosshair.visible = not value
		if value: hud.target_panel.visible = false
		hud.show_pause(value)

func _unhandled_input(event: InputEvent) -> void:
	# Verification drives the same adapter explicitly; live desktop events must
	# not rotate its scripted camera or trigger unrelated build actions.
	if not automated_test:handle_desktop_input(event)

func movement_pressed(code: Key) -> bool:
	return bool(scripted_controls.get(code,false)) if automated_test else Input.is_physical_key_pressed(code)

func handle_desktop_input(event: InputEvent) -> void:
	if automated_test and event is InputEventKey:scripted_controls[event.physical_keycode] = event.pressed
	if not started: return
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
			KEY_BACKSPACE: hud.open_manual("foot")
			KEY_ENTER: hud.open_selected_child()
			KEY_C: hud.cycle_build()
			KEY_V:
				if target.has("owner"):hud.open_manual(target.owner)
				elif target.has("build"):hud.open_manual(target.build)
				else:hud.open_manual("foot")
			KEY_F: reset_station()
		hud.refresh()
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
	if not paused:
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
	if not player.is_on_floor():player.velocity.y -= 14*delta
	else:player.velocity.y = -0.1
	player.move_and_slide()
	components.physics(delta)
	var previous_build = active_build
	var held = held_build()
	if not held.is_empty():
		_activate(held)
		pad.carry_target = camera.global_position+camera.global_basis*Vector3(0.63,-0.34,-1.25)
		pad.carry_basis = camera.global_basis*PREP_BASIS
		if not paused: pad.update_grip(delta)
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
	if not started or paused: return
	_update_target()
	_update_ghost()
	_update_markers()
	var station = _station_in_view()
	var node: Node3D = stations.get(station,foot)
	hud.set_rotation_hint(not station.is_empty() and camera.global_position.distance_to(node.global_position)<5.0,rotate_held)

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
	query.exclude = excluded
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return true
	if allowed.has(hit.collider):
		if allow_body_hit:return true
		# A surface at the destination is expected; hitting the back/side far
		# before the target is an occlusion, even on the same assembly.
		return hit.position.distance_to(point) < 0.065
	return hit.position.distance_to(point) < 0.025

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
			return family+" · "+build.label
	return "Foot"

func connection(index: int) -> Vector3:
	var point: Array = model.definitions.assemblies.heel_pad.slots["sleeve_%d"%index].target
	return pad.global_transform*Vector3(point[0],point[1],point[2])

func mount_transform(slot: String = "") -> Transform3D:
	if slot.is_empty():slot = target.get("mount",state.mount_slot)
	if slot.is_empty():slot = "heel_1"
	var uid: String = model.slot_definition("foot",slot).pose_source
	if model.slot_definition("foot",slot).assembly != "heel_pad":return foot.global_transform*Transform3D(Basis.IDENTITY,-FOOT_CENTER)*source[uid].transform
	return foot.global_transform*Transform3D(Basis.IDENTITY,source[uid].transform.origin-FOOT_CENTER)

func mount_point(slot: String = "") -> Vector3:
	return mount_transform(slot)*Vector3(0,-0.085,0)

func placement_destination() -> Transform3D:
	return stations[target.get("station","prep")].global_transform if target.type == "prep" else mount_transform()

func _update_target() -> void:
	target = {}
	var best: float = INF
	var candidates: Array[Dictionary] = []
	var previous_build = active_build
	var held = held_build()
	for id in builds:
		_activate(id)
		if not components.is_component_build(id) and ["prep","foot"].has(state.pad_location):
			for i in range(4):candidates.append({"type":"slot","build":id,"index":i,"point":connection(i),"radius":0.15})
		if state.pad_location in ["loose","prep"]:
			candidates.append({"type":"pad","build":id,"point":pad.global_position,"radius":0.40})
	if not held.is_empty():
		_activate(held)
		for station in stations:
			candidates.append({"type":"prep","build":held,"station":station,"point":stations[station].global_position,"radius":0.48})
		for mount in config.mounts:
			if model.slot_definition("foot",mount.id).assembly == model.assemblies[held].definition and model.assemblies.foot.slots[mount.id].is_empty():candidates.append({"type":"mount","build":held,"mount":mount.id,"point":mount_point(mount.id),"radius":0.30})
	_activate(previous_build if held.is_empty() else held)
	for kind in bins:candidates.append({"type":"bin","kind":kind,"point":bins[kind].global_position+Vector3(0,0.13,0.27),"radius":0.35})
	for uid in loose:
		if is_instance_valid(loose[uid]):candidates.append({"type":"loose","uid":uid,"point":loose[uid].global_position,"radius":0.12})
	candidates.append_array(components.candidates())
	for candidate in candidates:
		if camera.global_position.distance_to(candidate.point) > 6.0: continue
		var score = _aim_score(candidate.point,candidate.radius)
		# While holding hardware, a nearby socket wins over the pad's center.
		if candidate.type == "slot": score -= 0.12
		if candidate.type == "component": score -= 1.0
		if score < best:
			best = score
			target = candidate
	hud.target_panel.visible = not target.is_empty()
	if target.is_empty(): return
	if target.has("build"):_activate(target.build)
	var distance = camera.global_position.distance_to(target.point)
	var text = ""
	match target.type:
		"bin": text = components.title(target.kind)+" · %d available\n" % state.count_at(target.kind,"bin")+("E stock pocket · up to 20 · B clears selected pocket" if model.definitions.parts[target.kind].carry_class == "pocket" else "E carry from shelf · Q set down")
		"pad": text = build_label(active_build)+" · %s\nE carry · two hands · V manual" % ("Prepared" if state.prepared() else "Unfinished")
		"loose": text = components.title(state.items[target.uid].kind)+"\nE collect / carry"
		"prep": text = "PREPARATION STATION\nClick to suspend · R + mouse to rotate"
		"mount":
			var reason: String = model.placement_error("foot",target.mount,active_build)
			text = model.slot_definition("foot",target.mount).label+"\n"+("Click to seat this assembly" if reason.is_empty() else reason)
		"component":
			var d = model.slot_definition(target.owner,target.sid)
			var reason: String = model.placement_error(target.owner,target.sid,components.selected_uid(selected_kind))
			text = components.title(d.accepts)+"\n"+("Click to attach" if reason.is_empty() else reason)
		"slot":
			var reason = state.reason(selected_kind,target.index)
			if state.complete():text = "FA-302 · Heel pad complete\nZ to undo in the selected manual"
			elif selected_kind.is_empty(): text = "FA-302 · Heel pad / mounting point %d\n%s" % [target.index+1,"E carry this assembly" if state.pad_location == "prep" else "Select a stocked pocket [1–0]"]
			else:text = "Mounting point %d · %s\n%s" % [target.index+1,components.title(selected_kind),"Click to attach" if reason.is_empty() else reason]
	if target.type == "slot":text = build_label(active_build)+" · "+text
	if distance > REACH:text += "\nMove closer · %.1f m away / %.2f m reach" % [distance,REACH]
	else:
		var allowed: Array = [pad,foot]
		if target.type == "bin":allowed = [bins[target.kind]]
		elif target.type == "loose":allowed = [loose[target.uid]]
		elif target.type == "component":allowed = [foot if target.owner == "foot" else bodies[target.owner]]
		if not _visible(target.point,allowed,_target_allows_body_hit()):text += "\nView obstructed · approach the exposed side"
		elif target.type in ["prep","mount"] and state.pad_location == "held":
			var carry_error = _carry_placement_error(placement_destination())
			if not carry_error.is_empty():text += "\n"+carry_error
	hud.target_label.text = text

func _target_allows_body_hit() -> bool:
	return target.get("type","") in ["pad","loose","component"] or (target.get("type","") == "mount" and model.slot_definition("foot",target.mount).assembly != "heel_pad")

func _access(allowed: Array = []) -> String:
	if target.is_empty(): return "Aim near a part, bin, or mounting point."
	if target.type == "component":return components.access()
	if camera.global_position.distance_to(target.point) > REACH: return "Out of reach. Move closer to the connection (maximum %.2f m)." % REACH
	if not _visible(target.point,allowed,_target_allows_body_hit()): return "Connection is obstructed. Rotate the assembly or approach its exposed side."
	if target.type == "prep":
		var station: Node3D = stations[target.get("station","prep")]
		var envelope: Vector3 = pad.get_node("CollisionShape3D").shape.size
		var volume: Vector3 = station.get_meta("work_volume")
		if envelope.x > volume.x or envelope.y > volume.y or envelope.z > volume.z:return "This assembly needs a larger work volume."
		for id in builds:
			if id != active_build and model.assemblies[id].location == "station:"+target.get("station","prep"):return "This station is occupied. Move its assembly first."
	if target.type in ["prep","mount"] and state.pad_location == "held":
		return _carry_placement_error(placement_destination())
	return ""

func _carry_placement_error(destination: Transform3D, carried: WorkshopPart = null, receiving: PhysicsBody3D = null) -> String:
	if carried == null:carried = pad
	if carried.global_position.distance_to(camera.global_position) > REACH+0.75:
		return "The carried assembly is caught or too far away. Bring it alongside you first."
	var shape: Shape3D = carried.get_node("CollisionShape3D").shape
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = carried.global_transform*carried.get_node("CollisionShape3D").transform
	# The receiving foot uses layer 4. It may accept the assisted placement;
	# scenery and other loose objects must remain solid along the approach.
	query.collision_mask = 3
	var excluded: Array[RID] = [carried.get_rid()]
	if receiving:
		excluded.append(receiving.get_rid())
		# Installed children are part of the receiving workpiece, not loose obstacles.
		for body in bodies.values():
			if receiving.is_ancestor_of(body):excluded.append(body.get_rid())
	query.exclude = excluded
	query.margin = 0.002
	var space = get_world_3d().direct_space_state
	# Shape casts ignore bodies already overlapping at the start. A held body
	# pressed against a wall can penetrate by the solver's contact tolerance.
	# Reject that contact before sweeping so it cannot become a snap loophole.
	if not space.intersect_shape(query,1).is_empty():
		return "The carried assembly is touching an obstacle. Pull it clear before placing it."
	var center_path = PhysicsRayQueryParameters3D.create(carried.global_position,destination.origin,3)
	center_path.exclude = query.exclude
	if not space.intersect_ray(center_path).is_empty():
		return "The assembly's approach is blocked by scenery. Reposition before placing it."
	query.motion = destination.origin-carried.global_position
	var fractions = space.cast_motion(query)
	if fractions.size() == 2 and fractions[0] < 0.99:
		return "The assembly's approach is blocked by scenery. Reposition before placing it."
	query.transform = destination*carried.get_node("CollisionShape3D").transform
	query.motion = Vector3.ZERO
	if not space.intersect_shape(query,1).is_empty():
		return "The placement space is occupied. Move the loose obstacle first."
	return ""

func interact(all_stock: bool = false) -> void:
	if target.is_empty(): hud.toast("Look at a drawer, shelf or loose component, then press E."); return
	var allowed: Array = [pad]
	if target.type == "bin": allowed = [bins[target.kind]]
	if target.type == "loose": allowed = [loose[target.uid]]
	var error = _access(allowed)
	if not error.is_empty(): hud.toast(error);return
	match target.type:
		"bin":components.collect(target.kind,all_stock)
		"pad", "slot":
			if state.pad_location == "foot":hud.toast("The pad is mounted. Use Z to undo build actions.");return
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
			hud.toast(build_label(active_build)+" in both hands. Click a station to place it; Q sets it down.",true)
		"loose":components.collect(state.items[target.uid].kind,false,target.uid)
	hud.refresh()

func attach() -> void:
	if target.get("type","") == "component":components.attach();return
	var error = _access([pad,foot])
	if not error.is_empty():hud.toast(error);return
	if target.type == "prep" and state.pad_location == "held":
		var station: String = target.get("station","prep")
		var station_error = model.move_assembly(active_build,"station:"+station)
		if not station_error.is_empty():hud.toast(station_error);return
		_set_pad_station(station)
		hud.toast("Assembly suspended. Open its manual with V to follow the next step.",true)
	elif target.type == "mount" and state.pad_location == "held":
		var result = state.mount(target.get("mount","heel_1"))
		if not result.ok:hud.toast(result.error);return
		_set_pad_foot()
		if single_pad:hud.open_manual("foot",1)
		hud.toast("Assembly seated. Follow the foot manual to secure its connections.",true)
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
		hud.toast("Open the receiving build manual, select a part for its current step, and aim near its preview.")
	hud.refresh()

func _set_pad_station(station: String = "prep") -> void:
	var col: CollisionShape3D = pad.get_node("CollisionShape3D")
	var dimensions: Array = model.definitions.assemblies[model.assemblies[active_build].definition].bounds
	col.position = Vector3.ZERO
	col.shape.size = Vector3(dimensions[0],dimensions[1],dimensions[2])
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

func _set_pad_foot() -> void:
	pad.held = false
	pad.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	pad.freeze = true
	pad.linear_velocity = Vector3.ZERO
	pad.angular_velocity = Vector3.ZERO
	pad.reparent(foot)
	pad.global_transform = mount_transform(state.mount_slot)

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

func drop_selected() -> void:
	if not model.held_item().is_empty():components.drop();return
	var held = held_build()
	if held.is_empty():hud.toast("Q sets down a carried component. B clears the selected pocket.");return
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
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var shape = BoxShape3D.new()
	shape.size = source[uid].mesh.get_aabb().size.max(Vector3(0.012,0.012,0.012))
	col.shape = shape
	col.position = source[uid].mesh.get_aabb().get_center()
	item.add_child(col)
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
	var destination = ""
	for station in stations:
		var occupied = false
		for a in model.assemblies.values():
			if a.location == "station:"+station:occupied = true
		if not occupied:destination = station;break
	if owner == "foot" and not model.assemblies.foot.history.is_empty() and model.assemblies.foot.history.back().action == "mount" and destination.is_empty():
		hud.toast("Clear a preparation station before undoing the mount.");return
	var result = model.undo(owner,"station:"+destination)
	if not result.ok:hud.toast(result.error);return
	if result.step.action == "mount":
		_activate(result.step.uid)
		_set_pad_station(destination)
		if single_pad:hud.open_manual(active_build,1)
	else:
		var uid: String = result.step.uid
		if model.items[uid].location == "loose":_spawn_loose(uid,true)
	var previous_build = active_build
	for id in builds:
		_activate(id)
		_sync_installed_visuals()
	_activate(previous_build)
	if pitch_workshop:components.sync("foot")
	hud.toast("Undid the last action in "+hud.manual_title()+".",true)

func _state_changed() -> void:
	if hud:hud.refresh()
	if storage:storage.refresh()
	var previous_build = active_build
	for id in builds:
		_activate(id)
		if state.prepared() and not prepared_flags.get(id,false):_milestone(build_label(id)+" prepared. E to carry; Backspace for the foot manual.")
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

func _update_ghost() -> void:
	ghost.visible = false
	ghost_material.no_depth_test = target.get("type","") == "component"
	if target.get("type","") == "component":
		if not components.access().is_empty():return
		if not model.placement_error(target.owner,target.sid,components.selected_uid(selected_kind)).is_empty():return
		ghost.mesh = source[model.slot_definition(target.owner,target.sid).pose_source].mesh
		ghost.global_transform = components.slot_pose(target.owner,target.sid)
		ghost.visible = true
		return
	if target.is_empty():return
	if not _access([pad,foot]).is_empty():return
	if target.type == "slot" and HeelAssemblyState.KINDS.has(selected_kind):
		if not state.reason(selected_kind,target.index).is_empty() or state.count_at(selected_kind,"pocket") == 0:return
		var uid: String = slot_sources[selected_kind][target.index]
		ghost.mesh = source[uid].mesh
		var pose: Transform3D = source["FA-302__001"].transform.affine_inverse()*source[uid].transform
		ghost.global_transform = pad.global_transform*pose
		ghost.visible = true
	elif target.type == "mount" and state.pad_location == "held" and model.placement_error("foot",target.mount,active_build).is_empty():
		ghost.mesh = source[state.pad_id].mesh
		ghost.global_transform = mount_transform()
		ghost.visible = true
	elif target.type == "prep" and state.pad_location == "held":
		ghost.mesh = source[state.pad_id].mesh
		ghost.global_transform = stations[target.get("station","prep")].global_transform
		ghost.visible = true

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
	var station = rotation_station if rotate_held else _station_in_view()
	if station.is_empty():return
	var node: Node3D = stations.get(station,foot)
	if camera.global_position.distance_to(node.global_position)>5.0:return
	node.basis = (Basis(camera.global_basis.y,-relative.x*0.006)*Basis(camera.global_basis.x,-relative.y*0.006)*node.basis).orthonormalized()

func _rotation_key(pressed: bool) -> void:
	if pressed:
		rotate_held = true
		rotate_dragged = false
		rotate_press_time = Time.get_ticks_msec()
		rotation_station = _station_in_view()
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
	if station.is_empty():station = _station_in_view()
	if station.is_empty():return
	var node: Node3D = stations.get(station,foot)
	if camera.global_position.distance_to(node.global_position)>5.0:return
	if stations.has(station):stations[station].basis = PREP_BASIS
	elif station == "foot":foot.basis = FOOT_BASIS
	hud.toast("Station returned to its working orientation.",true)

func reset_demo() -> void:
	get_tree().reload_current_scene()

func _capture_preview() -> void:
	set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://verification/workshop.png")
	print("PREVIEW_SAVED")
	get_tree().quit()
