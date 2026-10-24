extends RefCounted
## Builds the room, preparation stations, foot station and parent fixtures.
var game: Node

func _init(workshop: Node) -> void:
	game = workshop

func build() -> void:
	var environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	var env = environment.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("91a4aa")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("cbd8dd")
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	game.add_child(environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-28,0)
	sun.light_energy = 0.85
	sun.light_color = Color("ffebce")
	sun.shadow_enabled = true
	# Resolve small joints within this room instead of allocating shadow detail
	# across a distant outdoor scene.
	sun.directional_shadow_max_distance = 32.0
	game.add_child(sun)
	var fill = OmniLight3D.new()
	fill.position = Vector3(-2,4,3)
	fill.light_energy = 0.65
	fill.omni_range = 14
	fill.light_color = Color("d1edff")
	game.add_child(fill)
	var floor_mat = game.material(Color("7c8886"))
	var wall_mat = game.material(Color("abb9b6"))
	var dark = game.material(Color("233940"),0.3)
	var metal = game.material(Color("49626a"),0.35)
	var warm = game.material(Color("e8b46b"),0.1)
	if game.profile.layout == "leg_bay":
		game.leg_layout = preload("res://scripts/leg_bay_layout.gd").new()
		game.add_child(game.leg_layout)
		game.leg_layout.setup(game)
		sun.directional_shadow_max_distance = 58.0
	else:
		_make_component_room(floor_mat,wall_mat,dark,metal,warm)
	_make_preparation_area(dark,metal,warm)

func _make_component_room(floor_mat: Material, wall_mat: Material, dark: Material, metal: Material, _warm: Material) -> void:
	game.box(game,Vector3(0,-0.15,0),Vector3(22,0.3,20),floor_mat,true)
	game.box(game,Vector3(0,4,-7),Vector3(22,8,0.3),wall_mat,true)
	# Side walls butt against the rear wall instead of sharing its top face.
	game.box(game,Vector3(-10.8,4,0.075),Vector3(0.3,8,13.85),wall_mat,true)
	game.box(game,Vector3(10.8,4,0.075),Vector3(0.3,8,13.85),wall_mat,true)
	game.box(game,Vector3(0,4,9.8),Vector3(22,8,0.3),wall_mat,true)
	for x in range(-10,11,2):
		game.box(game,Vector3(x,0.002,0),Vector3(0.016,0.004,19),game.material(Color("687875")))
	for z in range(-6,10,2):
		# Split at grid intersections so the floor markings have no overlapping faces.
		for x in range(-10,10,2):
			game.box(game,Vector3(x+1,0.002,z),Vector3(1.984,0.004,0.016),game.material(Color("687875")))
	for x in [-8.0,-4.0,0.0,4.0,8.0]:
		# Pilasters start at the wall face so their tops do not overlap the wall top.
		game.box(game,Vector3(x,4,-6.75),Vector3(0.22,8,0.20),metal)
		game.box(game,Vector3(x,6.7,0),Vector3(0.18,0.3,14),dark)
		game.box(game,Vector3(x,6.5,-1),Vector3(0.10,0.06,5),game.material(Color("fff3d5"),0,true))
	game.sign_panel(game,"FA / 01",Vector3(0,5.3,-6.55),Vector2(4.5,1.35),160,0.006)
	game.sign_panel(game,"COMPONENT ASSEMBLY  /  LOWER LIMB DIVISION",Vector3(0,4.35,-6.55),Vector2(5.4,0.36),64,0.0025)

func _make_preparation_area(dark: Material, metal: Material, warm: Material) -> void:
	# Pad rests on a separate preparation table; the player chooses when to carry it.
	game.box(game,Vector3(-0.1,0.92,game.PAD_HOME.z),Vector3(3.4,0.12,1.25),dark,true)
	for x in [game.PAD_HOME.x-0.6,game.PAD_HOME.x+0.6]:
		for z in [game.PAD_HOME.z-0.5,game.PAD_HOME.z+0.5]: game.box(game,Vector3(x,0.43,z),Vector3(0.09,0.86,0.09),metal,true)
	game.sign_text(game,"FA-302 / HEEL PAD",Vector3(game.PAD_HOME.x,0.92,game.PAD_HOME.z+0.64),19,Color("dfe9e5"),0.006)
	# A nearby stock tray gives organisation a physical purpose.
	game.box(game,Vector3(-0.4,0.86,0.6),Vector3(1.1,0.10,0.7),dark,true)
	for x in [-0.85,0.05]: game.box(game,Vector3(x,0.40,0.6),Vector3(0.07,0.8,0.55),metal,true)
	# Rims stand on the tray base; the front/rear rails fit between side rails.
	for x in [-0.94,0.14]: game.box(game,Vector3(x,0.965,0.6),Vector3(0.03,0.11,0.71),warm,true)
	for z in [0.26,0.94]: game.box(game,Vector3(-0.4,0.965,z),Vector3(1.05,0.11,0.03),warm,true)
	_station_frame(game.PREP_POSITION,Vector3(1.05,1.1,0.9),"02 / PREPARATION A",dark,warm)
	if game.has_equipment("legacy_foot_station"):
		_station_frame(game.FOOT_POSITION,Vector3(2.7,3.7,2.8),"03 / FOOT ASSEMBLY",dark,warm)
	game.prep = Node3D.new()
	game.prep.position = game.PREP_POSITION
	game.prep.basis = game.PREP_BASIS
	game.add_child(game.prep)
	game.stations["prep"] = game.prep
	game.prep.set_meta("work_volume",Vector3(1.05,1.1,0.9))
	if "prep2" in game.profile.prep_stations:
		var pos = Vector3(-4.6,1.35,-1.2)
		_station_frame(pos,Vector3(1.05,1.1,0.9),"04 / PREPARATION B",dark,warm)
		var other = Node3D.new()
		game.add_child(other)
		other.position = pos
		other.basis = game.PREP_BASIS
		game.stations["prep2"] = other
		other.set_meta("work_volume",Vector3(1.05,1.1,0.9))
	if "prep3" in game.profile.prep_stations:
		var pos = Vector3(-6.4,1.5,-1.2)
		_station_frame(pos,Vector3(1.05,1.1,0.9),"05 / PREPARATION C",dark,warm)
		var other = Node3D.new()
		game.add_child(other)
		other.position = pos
		other.basis = game.PREP_BASIS
		game.stations["prep3"] = other
		other.set_meta("work_volume",Vector3(1.05,1.1,0.9))
	# Spatial scale cues and a safe open route to the receiving station.
	for x in [-0.8,5.0]: game.box(game,Vector3(x,0.008,-1.8),Vector3(0.045,0.01,4.3),warm)

func _station_frame(center: Vector3, dimensions: Vector3, title: String, dark: Material, warm: Material) -> void:
	var half = dimensions/2
	for x in [-half.x,half.x]:
		for z in [-half.z,half.z]:
			# Rear posts preserve an open view and access to the work volume.
			if z < 0: game.box(game,Vector3(center.x+x,center.y,center.z+z),Vector3(0.045,dimensions.y,0.045),dark,true)
			game.box(game,Vector3(center.x+x,maxf(0.03,center.y-half.y),center.z+z),Vector3(0.15,0.045,0.15),warm)
	for y in [-half.y,half.y]:
		game.box(game,center+Vector3(0,y,-half.z),Vector3(dimensions.x,0.035,0.035),dark)
		# Side rails butt against the rear posts rather than crossing the rear rail.
		for x in [-half.x,half.x]:game.box(game,center+Vector3(x,y,0.01125),Vector3(0.035,0.035,dimensions.z-0.0225),dark)
	# Bolt the board to the rear frame, above the usable preparation volume.
	for x in [-half.x,half.x]:
		game.box(game,center+Vector3(x,half.y+0.09875,-half.z),Vector3(0.035,0.1625,0.035),dark)
	game.sign_panel(game,title,center+Vector3(0,half.y+0.17,-half.z+0.04),Vector2(maxf(1.5,dimensions.x),0.30),64,0.0018)

func load_foot() -> void:
	game.foot = AnimatableBody3D.new()
	game.foot.name = "FootStation"
	game.foot.collision_layer = 4
	game.foot.collision_mask = 0
	game.foot.sync_to_physics = false
	game.add_child(game.foot)
	game.foot.position = game.FOOT_POSITION
	game.foot.basis = game.FOOT_BASIS
	var visual = load("res://assets/foot-fa01.glb").instantiate()
	game.foot.add_child(visual)
	visual.position = -game.FOOT_CENTER
	for node in visual.get_children():
		if not node is MeshInstance3D: continue
		var sections = String(node.name).split("__")
		if sections.size() < 2: continue
		var uid: String = sections[0]+"__"+sections[1]
		game.source[uid] = {"mesh": node.mesh, "transform": node.transform, "family": sections[0]}
		if game.model.items.values().any(func(item):return item.source_id == uid):
			for item_uid in game.model.items:
				if game.source_uid(item_uid) == uid and sections[0] != "FA-302":game.type_sources[game.model.items[item_uid].kind] = uid
			visual.remove_child(node)
			node.free()
			continue
		var family: String = sections[0]
		if game.config.get("context_storage_families",[]).has(family):
			var stored = Node3D.new()
			game.add_child(stored)
			stored.position = Vector3(7,2,7.0)
			node.reparent(stored,false)
			node.position -= game.FOOT_CENTER
			# Hide staged armor until supported storage exists; otherwise it floats
			# distractingly in the base workshop and shared milestone scenes.
			node.hide()
			continue
		if game.profile.get("foot_collider_families",preload("res://scripts/scenario_profile.gd").FOOT_COLLIDER_FAMILIES).has(family):
			var collision_mode: String = game.config.get("context_collision",{}).get(uid,"bounds")
			var col = CollisionShape3D.new()
			col.transform = node.transform
			if collision_mode == "mesh":
				# Explicit fixed receiving frames need their actual openings. Concave
				# source triangles are confined to context fixtures, never carried bodies.
				var shape = node.mesh.create_trimesh_shape()
				shape.backface_collision = true
				col.shape = shape
				col.position -= game.FOOT_CENTER
			else:
				var aabb: AABB = node.mesh.get_aabb()
				var shape = BoxShape3D.new()
				shape.size = aabb.size.max(Vector3(0.02,0.02,0.02))
				col.shape = shape
				col.position += aabb.get_center()-game.FOOT_CENTER
			col.set_meta("source_uid",uid)
			col.set_meta("context_collision",collision_mode)
			game.foot.add_child(col)
	assert(game.source.size() == 745,"Foot source must retain the full inventory.")

func register_parent_fixtures() -> void:
	var index = 0
	for record in AssemblyModel.scenario_parents(game.config):
		var body: AnimatableBody3D = game.foot if index == 0 else AnimatableBody3D.new()
		if index > 0:
			body.collision_layer = 4
			body.collision_mask = 0
			body.sync_to_physics = false
			game.add_child(body)
			body.position = game.FOOT_POSITION+Vector3.RIGHT*index*4.0
		if record.has("home"):body.position = AssemblyRuntime.vec(record.home)
		if record.has("rotation_degrees"):body.basis = Basis.from_euler(AssemblyRuntime.vec(record.rotation_degrees)*PI/180.0)
		var d: Dictionary = game.model.definitions.assemblies[record.definition]
		var source_frame = null
		if record.has("frame_offset"):source_frame = Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(record.frame_offset))
		elif not d.has("root_slot") and index == 0:source_frame = Transform3D(Basis.IDENTITY,-game.FOOT_CENTER)
		game.runtime.register_node(record.id,body,source_frame)
		if d.has("root_slot"):
			var uid: String = game.model.assemblies[record.id].slots[d.root_slot]
			var visual = game._mesh(d.slots[d.root_slot].get("pose_source",game.source_uid(uid)))
			visual.transform = game.runtime.local_slot_pose(record.id,d.root_slot)
			visual.set_meta("component_uid",uid)
			visual.set_meta("slot_id",d.root_slot)
			body.add_child(visual)
			game.refresh_assembly_collision(record.id)
		index += 1

func make_leg_context() -> void:
	var pelvis = game.assembly_node("pelvis")
	var context = Node3D.new()
	context.name = "PelvisStructure"
	pelvis.add_child(context)
	var steel = game.material(Color("617880"),0.5)
	for uid in game.leg_content.context_sources:
		var mesh = game._mesh(uid)
		context.add_child(mesh)
		mesh.transform = game.source[uid].transform
		mesh.material_override = steel
		var col = CollisionShape3D.new()
		col.shape = mesh.mesh.create_trimesh_shape()
		col.shape.backface_collision = true
		col.transform = mesh.transform
		col.set_meta("source_uid",uid)
		pelvis.add_child(col)

