extends Node3D
## Workshop bootstrap and facade. Scenario choice lives in `profile`; input,
## player, targeting, world building and primitives live in their own modules.
const Part = preload("res://scripts/loose_part.gd")
const HUD = preload("res://scripts/hud.gd")
const Profiles = preload("res://scripts/scenario_profile.gd")
const Automation = preload("res://scripts/workshop_automation.gd")
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

## Set before the node enters the tree to choose a profile without CLI flags.
var profile_override: String = ""
var profile: Dictionary = {}
var primitives: RefCounted
var targeting: RefCounted
var desktop_input: RefCounted
var player_controller: RefCounted
var world: RefCounted
var automation: Automation
var model = AssemblyModel.new()
var runtime: AssemblyRuntime
var components: Node
var storage: Node
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

# Fixture subclasses replace _ready, so the stateless modules exist from construction.
func _init() -> void:
	primitives = preload("res://scripts/primitives.gd").new()
	targeting = preload("res://scripts/targeting.gd").new(self)
	desktop_input = preload("res://scripts/desktop_input.gd").new(self)
	player_controller = preload("res://scripts/player_controller.gd").new(self)
	world = preload("res://scripts/workshop_world.gd").new(self)
	automation = Automation.new(self)

func _ready() -> void:
	profile = Profiles.resolve(Array(OS.get_cmdline_user_args()),get_tree(),profile_override)
	if profile.has("selector"):
		add_child(preload("res://scripts/m2_selector.gd").new())
		return
	var single = profile.pads == "single"
	config = HeelAssemblyState.scenario(single)
	var data = HeelAssemblyState.definition_data(single)
	if profile.pitch:
		config = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pitch-workshop.json"))
		var overlay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(config.definitions))
		data.parts.merge(overlay.parts,true)
		data.assemblies.merge(overlay.assemblies,true)
	if not profile.leg_content.is_empty():_load_leg_content(data)
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
	world.build()
	world.load_foot()
	if not profile.leg_content.is_empty():
		preload("res://scripts/leg_source_geometry.gd").add_sources(source,leg_content)
		for record in leg_content.parts:type_sources[record.kind] = record.get("source_id",record.instance_id)
	world.register_parent_fixtures()
	if not profile.leg_content.is_empty():world.make_leg_context()
	player_controller.make()
	if has_equipment("foot_fixture"):
		foot_fixture = preload("res://scripts/supported_fixture.gd").new()
		add_child(foot_fixture)
		foot_fixture.setup(self,foot)
	for build in config.builds:
		_activate(build.id)
		_make_pad()
	_activate(config.builds[0].id)
	components.setup()
	if has_equipment("leg_rail"):
		m2 = preload("res://scripts/m2_workshop.gd").new();add_child(m2);m2.setup(self)
		player_controller.spawn(profile.spawn)
	storage = preload("res://scripts/part_storage.gd").new(self)
	add_child(storage)
	storage.setup()
	if is_instance_valid(m2):m2.position_stock()
	ghost_material = primitives.new_material(SNAP_READY_COLOR,0.0)
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
	if not profile.trial.is_empty():hud.open_manual("pelvis" if profile.trial == "retention" else "left_leg")
	model.changed.connect(_state_changed)
	_make_audio()
	_state_changed()
	set_paused(true)
	started = true
	saves = preload("res://scripts/m2_session.gd").new() if profile.session.codec == "trial" else preload("res://scripts/workshop_save.gd").new()
	add_child(saves)
	saves.setup(self)

func _load_leg_content(data: Dictionary) -> void:
	leg_content = JSON.parse_string(FileAccess.get_file_as_string(profile.leg_content))
	var overlay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/leg-prototype-definitions.json"))
	data.parts.merge(overlay.parts,true)
	data.assemblies.merge(overlay.assemblies,true)
	var trial: String = profile.trial
	if not trial.is_empty():
		var trial_definitions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/m2-"+trial+"-definitions.json"))
		var trial_content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/m2-"+trial+"-content.json"))
		data.parts.merge(trial_definitions.parts,true);data.assemblies.merge(trial_definitions.assemblies,true)
		for support_id in trial_content.m2.remove_supports:leg_content.supports.erase(support_id)
		leg_content.supports.merge(trial_content.supports,true)
		for field in ["parts","parents","equipment","m2"]:leg_content[field] = trial_content[field]
		if trial == "retention" and m2_half_uid != "PV-120__001":
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

func has_equipment(id: String) -> bool:
	return id in profile.get("equipment",[])

func foot_equipment_available() -> bool:
	return is_instance_valid(foot_fixture)

func equipment_controller(entry: Dictionary) -> Node:
	if entry.has("controller"):return entry.controller
	if entry.has("equipment_id"):return access_lifts.get(entry.equipment_id)
	return foot_fixture

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

func _physics_process(delta: float) -> void:
	if not started: return
	if is_instance_valid(m2):m2.physics(delta)
	if foot_equipment_available():foot_fixture.physics(delta)
	for lift in access_lifts.values():lift.physics(delta)
	player_controller.physics(delta)
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
	if not started or paused or desktop_input.modal_active(): return
	_update_target()
	_update_markers()

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
		if profile.get("pads","") == "single":hud.open_manual(model.assemblies[active_build].parent,1)
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
		if profile.get("pads","") == "single":hud.open_manual(active_build,1)
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
	var glow = primitives.new_material(Color(0.25,0.95,0.68,0.6),0,true)
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var glowing_mesh = pad_mesh
	glowing_mesh.material_overlay = glow
	var tween = create_tween()
	tween.tween_property(glow,"albedo_color:a",0.0,1.8)
	tween.tween_callback(func():
		if is_instance_valid(glowing_mesh) and glowing_mesh.material_overlay == glow:glowing_mesh.material_overlay = null)

func reset_demo() -> void:
	if is_instance_valid(saves):saves.new_workshop()
	else:get_tree().reload_current_scene()

# Facades kept for the many layout, equipment and test callers.
func material(color: Color, metal: float = 0.0, emissive: bool = false) -> StandardMaterial3D:return primitives.material(color,metal,emissive)
func box(parent: Node3D, pos: Vector3, dimensions: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:return primitives.box(parent,pos,dimensions,mat,solid)
func sign_text(parent: Node3D, text: String, pos: Vector3, font_size: int = 36, color: Color = Color("d5e2df"), pixel_size: float = 0.008) -> Label3D:return primitives.sign_text(parent,text,pos,font_size,color,pixel_size)
func sign_panel(parent: Node3D, text: String, pos: Vector3, size: Vector2, font_size: int = 64, pixel_size: float = 0.002, rotation_y: float = 0.0) -> Label3D:return primitives.sign_panel(parent,text,pos,size,font_size,pixel_size,rotation_y)
func handle_desktop_input(event: InputEvent) -> void:desktop_input.handle(event)
func reset_station(station: String = "") -> void:desktop_input.reset_station(station)
func _rotate_station(relative: Vector2) -> void:desktop_input.rotate_station(relative)
func _update_crouch(wants_crouch: bool, delta: float) -> void:player_controller.update_crouch(wants_crouch,delta)
func _update_target() -> void:targeting.update_target()
func _update_ghost(access_result: Variant = null) -> void:targeting.update_ghost(access_result)
func _update_markers() -> void:targeting.update_markers()
func _show_assembly_ghost() -> void:targeting.show_assembly_ghost()
func _aim_score(point: Vector3, radius: float) -> float:return targeting.aim_score(point,radius)
func _visible(point: Vector3, allowed: Array = [], allow_body_hit: bool = false) -> bool:return targeting.can_see(point,allowed,allow_body_hit)
func _assembly_discovery_hit(owner: String) -> Variant:return targeting.assembly_discovery_hit(owner)
func _target_receivers() -> Array:return targeting.target_receivers()
func _access(allowed: Array = [], check_approach: bool = true) -> String:return targeting.access(allowed,check_approach)
func _snap_guidance_message() -> String:return targeting.snap_guidance_message()
func _carry_placement_error(destination: Transform3D, carried: WorkshopPart = null, receiving: PhysicsBody3D = null) -> String:return targeting.carry_placement_error(destination,carried,receiving)
