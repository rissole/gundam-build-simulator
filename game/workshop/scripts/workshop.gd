extends Node3D
## Workshop bootstrap and facade for the one robot workshop. Input, player,
## targeting, world building and primitives live in their own modules.
const Part = preload("res://scripts/loose_part.gd")
const HUD = preload("res://scripts/hud.gd")
const Automation = preload("res://scripts/workshop_automation.gd")
const Registry = preload("res://scripts/equipment_registry.gd")
const Hands = preload("res://scripts/hand_slot.gd")
const Content = preload("res://scripts/workshop_content.gd")
const Stages = preload("res://scripts/build_stages.gd")
const Save = preload("res://scripts/workshop_save.gd")
## Interaction and physics order; earlier equipment answers aggregate queries first.
const EQUIPMENT_ORDER = ["rope_access","workshop_access","rail_gates","mobile_platform","module_supports","core_guide","backpack_hinge","captive_controls","joint_restraints","foot_carrier","leg_rail","arm_cassette","left_shoulder","right_shoulder","left_shelf","right_shelf","service_crane","foot_fixture","left_lift","right_lift"]
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
const LEG_CONTENT = "res://assets/leg-prototype-content.json"
const INTRO = "Build the left foot first: prepare both heel pads and the pitch actuator at the preparation stations, then secure them to the foot on the foot rig in the Foot Bay. Next deliver the prepared hip assembly from the Heavy Module Bay to the gantry, crane the finished foot to dispatch and build each structural leg on the leg rig, then the torso, arms and head. Manuals describe each connection; shared equipment carries every large load."
## Foot, pitch-actuator and pad families that keep their own collision proxies.
const FOOT_COLLIDER_FAMILIES = ["FA-100","FA-101","FA-102","FA-103","FA-104","FA-105","FA-106","FA-200","FA-201","FA-300","FA-301","FA-302","FA-303","FA-304","FA-400","FA-401","FA-402","FA-403","FA-404"]
## Equipment created by _build_equipment, in dependency order.
const EQUIPMENT = ["foot_fixture","module_supports","core_guide","backpack_hinge","arm_cassette","left_shoulder","right_shoulder","leg_rail","left_lift","right_lift","left_shelf","right_shelf","service_crane","foot_carrier","joint_restraints","workshop_access","mobile_platform","captive_controls","rail_gates","rope_access"]
## Between the preparation stations and the foot bay, facing the stock wall.
const SPAWN = [-2.6,.03,4.2,PI/2]

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
var equipment: RefCounted
var zones: RefCounted
var hands: RefCounted
## Supplied-branch undo rules and stock placement.
var journey: RefCounted
var leg_content: Dictionary = {}
var leg_layout: Node3D
var gantry_dressing: RefCounted
## The turning foot fixture; also in `equipment`.
var foot_fixture: Node3D
var builds: Dictionary = {}
var bodies: Dictionary = {}
var stations: Dictionary = {}
var active_build: String = "pad_1"
var prepared_flags: Dictionary = {}
var completed_flags: Dictionary = {}
var automated_test: bool = false
## The --stage launch flag, or "" for a fresh workshop.
var start_stage: String = ""
## Pause-menu note describing the last --stage preparation.
var stage_notice: String = ""
## True while a --stage launch is still being prepared; nothing is saved meanwhile.
var staging: bool = false
## The save slot. Empty (no saving) unless this is a normal launch; tests opt in.
var save_path: String = ""
var save: RefCounted
var scripted_controls: Dictionary = {}
var config: Dictionary
var source: Dictionary = {}
var active_ids: Array[String] = []
## Part kinds of the foot build itself, before any milestone content is added.
var foot_kinds: Dictionary = {}
var part_defs: Dictionary = {}
var type_sources: Dictionary = {}
var ghost: MeshInstance3D
var ghost_material: StandardMaterial3D
var ghost_assembly_signature: String = ""
var manual_control_guidance: Node3D
var interaction_outline: Node3D
var foot: AnimatableBody3D
var prep: Node3D
var loose: Dictionary = {}
var bins: Dictionary = {}
var bin_labels: Dictionary = {}
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
var manual_progress: RefCounted
var selected_kind: String:
	get:return model.selected_kind()
	set(value):
		var index = model.pocket_for(value)
		if index >= 0:model.select_pocket(index)
var paused: bool = true
var target: Dictionary = {}
var rotation_station: String = ""
var chime: AudioStreamPlayer
var started: bool = false
var screenshot_mode: bool = false

# Fixture subclasses replace _ready, so the stateless modules exist from construction.
func _init() -> void:
	primitives = preload("res://scripts/primitives.gd").new()
	targeting = preload("res://scripts/targeting.gd").new(self)
	desktop_input = preload("res://scripts/desktop_input.gd").new(self)
	player_controller = preload("res://scripts/player_controller.gd").new(self)
	world = preload("res://scripts/workshop_world.gd").new(self)
	automation = Automation.new(self)
	equipment = Registry.new()
	hands = Hands.new(self)

func _update_render_scale() -> void:
	# Keep HUD/text at native resolution, but render the world at logical pixels.
	# Re-evaluate when moving between Retina and standard-density Mac displays.
	if not OS.has_feature("macos") or DisplayServer.get_name() == "headless":
		return
	var window := get_window()
	var display_scale := DisplayServer.screen_get_scale(window.current_screen)
	window.scaling_3d_scale = 1.0 / maxf(display_scale, 1.0)

func _ready() -> void:
	_update_render_scale()
	get_window().dpi_changed.connect(_update_render_scale)
	var loaded = Content.load_workshop()
	config = loaded.scenario
	var data: Dictionary = loaded.data
	foot_kinds = loaded.foot_kinds
	leg_content = loaded.content
	components = preload("res://scripts/component_interaction.gd").new(self)
	add_child(components)
	var errors = model.configure(data,config)
	assert(errors.is_empty(),str(errors))
	runtime = AssemblyRuntime.new(model,source)
	bind_build_views(config)
	active_build = config.builds[0].id
	for definition in config.parts:
		active_ids.append(definition.instance_id)
		part_defs[definition.instance_id] = definition
	world.build()
	world.load_foot()
	preload("res://scripts/leg_source_geometry.gd").add_sources(source,leg_content)
	preload("res://scripts/mirrored_sources.gd").add(source,leg_content.get("mirror_sources",{}))
	for record in leg_content.parts:type_sources[record.kind] = record.get("source_id",record.instance_id)
	world.register_parent_fixtures()
	world.make_leg_context()
	player_controller.make()
	_build_equipment(["foot_fixture"])
	for build in config.builds:components.make_build(build.id)
	components.setup()
	journey = preload("res://scripts/leg_journey_policy.gd").new(self)
	preload("res://scripts/scenario_staging.gd").prepare(self)
	_build_equipment(EQUIPMENT.filter(func(id):return id != "foot_fixture"))
	gantry_dressing = preload("res://scripts/gantry_dressing.gd").new()
	gantry_dressing.build(leg_layout.blockout,[equipment.get_equipment("left_lift"),equipment.get_equipment("right_lift")])
	start_stage = Stages.stage_flag(Array(OS.get_cmdline_user_args()))
	# Player launches keep a save; tests and tools (custom SceneTree scripts) never
	# touch it. A --stage launch starts from its stage, never the save, but Save
	# overwrites the slot with the progress made from there.
	if save_path.is_empty() and not automated_test and get_tree().get_script() == null:save_path = Save.PATH
	save = Save.new(self,save_path)
	staging = not start_stage.is_empty()
	# Closing the window is Save & quit (see _notification).
	if save.enabled():get_tree().set_auto_accept_quit(false)
	if not staging and save.load_saved():
		# Restored milestones are not new: no toast or chime on load.
		for id in builds:
			prepared_flags[id] = build_prepared(id)
			completed_flags[id] = build_complete(id)
	player_controller.spawn(SPAWN)
	save.place_player()
	storage = preload("res://scripts/part_storage.gd").new(self)
	add_child(storage)
	storage.setup()
	journey.position_stock()
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
	components.make_markers()
	manual_progress = preload("res://scripts/manual_progress.gd").new(self)
	manual_control_guidance = preload("res://scripts/manual_control_guidance.gd").new()
	add_child(manual_control_guidance)
	manual_control_guidance.setup(self)
	hud = HUD.new()
	hud.game = self
	add_child(hud)
	hud.open_manual("foot")
	model.changed.connect(_state_changed)
	_make_audio()
	_state_changed()
	world.configure_foot_rendering()
	set_paused(false)
	started = true
	if not start_stage.is_empty() and not automated_test:call_deferred("run_stage",start_stage)

func has_equipment(id: String) -> bool:
	return id in EQUIPMENT

## One factory: creates `ids` in dependency order, then registers them in EQUIPMENT_ORDER.
func _build_equipment(ids: Array) -> void:
	if zones==null:zones=preload("res://scripts/zone_register.gd").new(leg_layout.layout().get("workshop",{}).get("zones",[]) if is_instance_valid(leg_layout) else [])
	var made: Dictionary = {}
	for id in ids:
		var item: Node3D
		match id:
			"module_supports":
				item=preload("res://scripts/module_supports.gd").new();add_child(item);item.setup(self,leg_layout.blockout)
			"core_guide":
				item=preload("res://scripts/core_guide.gd").new();add_child(item);item.setup(self,leg_content.equipment.core_guide)
			"backpack_hinge":
				item=preload("res://scripts/backpack_hinge.gd").new();add_child(item);item.setup(self,leg_content.equipment.backpack_hinge)
			"arm_cassette":
				item=preload("res://scripts/arm_cassette.gd").new();add_child(item);item.setup(self,leg_layout.blockout,leg_content.equipment.arm_cassette)
			"left_shoulder","right_shoulder":
				item=preload("res://scripts/shoulder_support.gd").new();add_child(item);item.setup(self,leg_content.equipment[id])
			"rail_gates":
				item = preload("res://scripts/rail_crossing_gates.gd").new();add_child(item);item.setup(self,leg_layout.blockout)
			"captive_controls":
				item = preload("res://scripts/captive_controls.gd").new();add_child(item);item.setup(self,leg_content.equipment.captive_controls)
			"mobile_platform":
				item = preload("res://scripts/mobile_work_platform.gd").new();add_child(item);item.setup(self,leg_layout.layout().workshop.mobile_platform)
			"rope_access":
				item = preload("res://scripts/rope_access.gd").new();add_child(item);item.setup(self,leg_layout.blockout)
			"workshop_access":
				item = preload("res://scripts/workshop_access.gd").new();add_child(item);item.setup(self,leg_layout.blockout)
			"foot_fixture":
				item = preload("res://scripts/supported_fixture.gd").new();add_child(item)
				# In the hangar the fixture stands in for the left foot's bay store.
				item.setup(self,foot,{"origin":AssemblyRuntime.vec(leg_layout.layout().workshop.foot_storage.foot.position)});foot_fixture = item
				if leg_layout.blockout != null:
					for piece_id in leg_layout.blockout.pieces:
						if not piece_id.begins_with("foot_store_"):continue
						var piece: Dictionary = leg_layout.blockout.pieces[piece_id]
						piece.visual.hide()
						if piece.has("body"):piece.body.collision_layer = 0
			"joint_restraints":
				item = preload("res://scripts/passive_joint_restraints.gd").new();add_child(item);item.setup(self)
			"foot_carrier":
				item = preload("res://scripts/foot_carrier.gd").new();add_child(item);item.setup(self,leg_layout)
			"leg_rail":
				item = preload("res://scripts/indexed_leg_rail.gd").new();add_child(item);item.setup(self,leg_layout)
			"left_lift","right_lift":
				var side: String = id.trim_suffix("_lift")
				var lift_data: Dictionary = leg_layout.layout().workshop.elevators[side]
				var levels: Array[float] = [];levels.assign(lift_data.levels)
				item = preload("res://scripts/work_access_lift.gd").new();add_child(item)
				item.setup(self,side,AssemblyRuntime.vec(lift_data.origin),Vector2(lift_data.size[0],lift_data.size[1]),levels,lift_data)
			"left_shelf","right_shelf":
				var side: String = id.trim_suffix("_shelf")
				item = preload("res://scripts/lift_shelf.gd").new();add_child(item)
				item.setup(self,made[side+"_lift"],leg_layout.layout().workshop.elevators[side].shelf)
			"service_crane":
				item = preload("res://scripts/service_crane.gd").new();add_child(item);item.setup(self,leg_layout,leg_layout.crane_contract())
		if item != null:made[id] = item
	for id in EQUIPMENT_ORDER:
		if made.has(id):equipment.register(made[id])
	for id in leg_content.get("equipment",{}).get("receivers",{}):
		if equipment.get_equipment(id)!=null:continue
		var receiver=preload("res://scripts/staged_receiver.gd").new()
		add_child(receiver);receiver.setup(self,id,leg_content.equipment.receivers[id]);equipment.register(receiver)

func _mesh(uid: String) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	uid = source_uid(uid)
	mesh.mesh = source[uid].mesh
	mesh.set_meta("source_uid",uid)
	return mesh


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
	if value and desktop_input != null:desktop_input.release_control()
	jump_requested = false
	if value and is_instance_valid(interaction_outline):interaction_outline.clear()
	if value and is_instance_valid(manual_control_guidance):manual_control_guidance.clear()
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

func _physics_process(delta: float) -> void:
	if desktop_input != null:desktop_input.physics(delta)
	if not started: return
	# The player moves against equipment poses Jolt has already stepped; the
	# equipment then moves and carries any rider exactly.
	player_controller.physics(delta)
	equipment.physics(delta)
	components.physics(delta)
	var held = held_build()
	if not held.is_empty() and not paused:apply_carry_intent(bodies[held],delta)
	# A dropped piece cannot disappear permanently under the floor.
	for uid in loose.keys():
		if is_instance_valid(loose[uid]) and loose[uid].global_position.y < -3:
			loose[uid].global_position = Vector3(-0.4,1.2,0.6)
			loose[uid].linear_velocity = Vector3.ZERO
	for id in bodies:
		if model.assemblies[id].location == "loose" and bodies[id].global_position.y < -3:
			bodies[id].global_position = home_position(id)+Vector3.UP*0.06
			bodies[id].linear_velocity = Vector3.ZERO

func _process(_delta: float) -> void:
	if not started:return
	if paused or desktop_input.modal_active():
		manual_control_guidance.clear()
		return
	_update_target()
	_update_markers()
	manual_control_guidance.update()

func bind_build_views(scenario: Dictionary) -> void:
	builds.clear()
	for build in scenario.builds:builds[build.id] = build

func held_build() -> String:
	for id in builds:
		if model.assemblies[id].location == "held":return id
	return ""

func build_prepared(owner: String) -> bool:
	return model.milestone(owner,"prepared")

func build_complete(owner: String) -> bool:
	var assembly: Dictionary = model.assemblies[owner]
	return not assembly.parent.is_empty() and model.milestone(assembly.parent,assembly.parent_slot+"_secured")

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
	return equipment.access_error(owner)

func mount_transform(slot: String = "", owner: String = "", child: String = "") -> Transform3D:
	if child.is_empty():child = target.get("build",held_build())
	if owner.is_empty():owner = target.get("owner",model.assemblies[child].parent)
	if owner.is_empty():owner = default_parent_id()
	if slot.is_empty():slot = target.get("mount",model.assemblies[child].parent_slot)
	return runtime.mount_pose(owner,slot,child)

func mount_point(slot: String, owner: String, child: String) -> Vector3:
	var definition: Dictionary = model.slot_definition(owner,slot)
	if definition.has("target") or definition.has("target_position"):
		return assembly_node(owner).global_transform*AssemblyRuntime.vec(definition.get("target",definition.get("target_position",[])))
	var offset: Array = components.presentation.get(model.assemblies[child].definition,{}).get("mount_target_offset",[0,0,0])
	return mount_transform(slot,owner,child)*AssemblyRuntime.vec(offset)

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
	var was_waiting = body.recovery_waiting
	body.update_grip(delta)
	if body.recovery_waiting and not was_waiting:
		hud.toast("Your held component is caught. Move into clear space to bring it back to your hands.")

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
		var uid: String = visual.get_meta("component_uid","")
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
	components.interact(all_stock)

func attach() -> void:
	components.attach_target()

func suspend_build(owner: String, station: String) -> void:
	var body: WorkshopPart = bodies[owner]
	body.held = false
	# Static freeze preserves inherited station transforms between physics ticks.
	body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	body.freeze = true
	body.gravity_scale = 1
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	body.reparent(stations[station])
	body.transform = Transform3D.IDENTITY
	refresh_assembly_collision(owner)

func mount_build(owner: String) -> void:
	var assembly: Dictionary = model.assemblies[owner]
	runtime.mount(assembly.parent,assembly.parent_slot,owner)
	refresh_assembly_collision(assembly.parent)

func drop_selected() -> void:
	var dropped: Dictionary = equipment.drop()
	if dropped.handled:
		hud.toast(dropped.error if not dropped.error.is_empty() else dropped.status,dropped.error.is_empty())
		return
	if not model.held_item().is_empty():components.drop();return
	var held = held_build()
	if held.is_empty():hud.toast("Your hands are empty.");return
	var body: WorkshopPart = bodies[held]
	body.held = false
	body.freeze = false
	body.sleeping = false
	body.gravity_scale = 1
	body.linear_velocity = Vector3.ZERO
	model.move_assembly(held,"loose")

func _spawn_loose(uid: String, at_output: bool = false) -> void:
	assert(model.definitions.parts[model.items[uid].kind].carry_class != "pocket","Small items stay in drawers, pockets or assemblies.")
	var item = Part.new()
	item.uid = uid
	item.kind = model.items[uid].kind
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
	var owner: String = str(target.owner) if target.has("owner") and model.assemblies.has(str(target.owner)) else str(target.build) if target.has("build") and model.assemblies.has(str(target.build)) else hud.manual_id
	var assisted: Dictionary = equipment.undo(owner)
	if assisted.handled:
		hud.toast(assisted.error if not assisted.error.is_empty() else "Undid the last installation with equipment support.",assisted.error.is_empty())
		return
	var journey_error: String = journey.undo_error(owner) if journey != null else ""
	if not journey_error.is_empty():hud.toast(journey_error);return
	var equipment_error = equipment_access_error(owner)
	if not equipment_error.is_empty():hud.toast(equipment_error);return
	if _undo_to_hands(owner):return
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
		suspend_build(result.step.uid,destination)
		refresh_assembly_collision(owner)
	else:
		var uid: String = result.step.uid
		if model.items[uid].location == "loose":_spawn_loose(uid,true)
	for id in model.assemblies:components.sync(id)
	hud.toast("Undid the last action in "+hud.manual_title()+".",true)

## Slots authored with "undo_to":"hands" return the same identity to free hands,
## after the ordinary reach and sightline checks for that connection.
func _undo_to_hands(owner: String) -> bool:
	if not model.assemblies.has(owner) or model.assemblies[owner].history.is_empty():return false
	var sid: String = model.assemblies[owner].history.back().slot
	if model.slot_definition(owner,sid).get("undo_to","") != "hands":return false
	var error: String = hands.error()
	if error.is_empty():error = components.removal_access(owner,sid)
	if not error.is_empty():hud.toast(error);return true
	var uid: String = model.assemblies[owner].slots[sid]
	var pose: Transform3D = components.slot_pose(owner,sid)
	var result: Dictionary = model.undo_to_hands(owner)
	if not result.ok:hud.toast(result.error);return true
	components.sync(owner)
	components.hold_at(uid,pose)
	hud.refresh()
	hud.toast("Returned "+components.title(model.items[uid].kind)+" to your hands.",true)
	return true

func _state_changed() -> void:
	if hud:hud.refresh()
	if storage:storage.refresh()
	for id in builds:
		if build_prepared(id) and not prepared_flags.get(id,false):_milestone(build_label(id)+" prepared.",id)
		if build_complete(id) and not completed_flags.get(id,false):_milestone(build_label(id)+" installation COMPLETE",id)
		prepared_flags[id] = build_prepared(id)
		completed_flags[id] = build_complete(id)
	var errors = model.integrity_errors()
	assert(errors.is_empty(),"; ".join(errors))

func _milestone(message: String, owner: String) -> void:
	if hud:hud.toast(message,true)
	if chime and DisplayServer.get_name() != "headless":chime.play()
	var glow = primitives.new_material(Color(0.25,0.95,0.68,0.6),0,true)
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var glowing_mesh: MeshInstance3D = bodies[owner].get_child(0)
	glowing_mesh.material_overlay = glow
	var tween = create_tween()
	tween.tween_property(glow,"albedo_color:a",0.0,1.8)
	tween.tween_callback(func():
		if is_instance_valid(glowing_mesh) and glowing_mesh.material_overlay == glow:glowing_mesh.material_overlay = null)

func reset_demo() -> void:
	# Reloading restores the saved workshop, if any, or re-runs a --stage launch.
	get_tree().reload_current_scene()

## Pause menu Save & quit, and closing the window. A refused save keeps the game
## open on the pause menu with the reason; Quit without saving still leaves.
func save_and_quit() -> void:
	var error: String = save.save_now()
	if error.is_empty():
		get_tree().quit()
		return
	set_paused(true)
	hud.show_save_error(error)

func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_CLOSE_REQUEST or not started or not save.enabled():return
	# A stage launch saves on close only once the player has changed the build,
	# so inspecting a stage never overwrites the saved workshop.
	if not start_stage.is_empty() and (staging or not save.unsaved()):get_tree().quit()
	else:save_and_quit()

## Pause menu: forget the saved workshop and start again from a fresh launch.
func new_workshop() -> void:
	Save.delete(save_path)
	Save.notice = ""
	reset_demo()

## Overridable orchestration boundary; production always uses the real stage runner.
func create_stage_runner() -> RefCounted:return Stages.new(self)

## Development shortcut: script the sequence up to `stage`, then enter play.
## Supplied progress only; never playtest evidence.
func run_stage(stage: String) -> String:
	if stage not in Stages.ALL:
		var unknown = "Unknown stage '"+stage+"'. Use one of: "+", ".join(Stages.ALL)
		staging = false
		set_paused(true)
		if is_instance_valid(hud):hud.toast(unknown)
		# Headless suites already record the returned message. push_error would
		# fail the regression runner, which treats every ERROR line as a failure.
		if not automated_test:push_error(unknown)
		return unknown
	var title: String = Stages.TITLES[stage]
	staging = true
	# Block live input before the overlay's first frame, not after it appears.
	var was_automated = automated_test
	automated_test = true
	var overlay = CanvasLayer.new();overlay.layer = 100;add_child(overlay)
	var shade = ColorRect.new();shade.color = Color("111d26e6");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.add_child(shade)
	var note = Label.new();note.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size",24);overlay.add_child(note)
	note.text = "Preparing stage: "+title+"\nEarlier work is supplied by script, not playtested."
	await get_tree().process_frame;await get_tree().process_frame
	# Scripted controls block walking/look so the player can't step into a route.
	set_paused(false)
	var error: String = await create_stage_runner().run_to(stage,func(step: String):note.text = "Preparing stage: "+title+"\nNow: "+step)
	automated_test = was_automated
	overlay.queue_free()
	stage_notice=("Started at stage: "+title+". Earlier work was supplied by script, not playtested.") if error.is_empty() else ("Stage preparation stopped: "+error)
	# The prepared stage is the baseline: only the player's own progress is unsaved.
	save.settle()
	staging = false
	set_paused(not error.is_empty())
	if is_instance_valid(hud):hud.toast(stage_notice,error.is_empty());hud.refresh_session_status()
	if not error.is_empty():push_error("Stage "+stage+": "+error)
	return error

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
func _show_assembly_ghost(owner: String = "") -> void:targeting.show_assembly_ghost(owner)
func _aim_score(point: Vector3, radius: float) -> float:return targeting.aim_score(point,radius)
func _visible(point: Vector3, allowed: Array = [], allow_body_hit: bool = false, depth: float = 0.065) -> bool:return targeting.can_see(point,allowed,allow_body_hit,depth)
func _assembly_discovery_hit(owner: String) -> Variant:return targeting.assembly_discovery_hit(owner)
func _target_receivers() -> Array:return targeting.target_receivers()
func _access(allowed: Array = [], check_approach: bool = true) -> String:return targeting.access(allowed,check_approach)
func _snap_guidance_message() -> String:return targeting.snap_guidance_message()
func _carry_placement_error(destination: Transform3D, carried: WorkshopPart = null, receiving: PhysicsBody3D = null) -> String:return targeting.carry_placement_error(destination,carried,receiving)
