extends "res://tests/pitch_build_test.gd"
## Opt-in real-renderer evidence from the normal collection/placement runner.
## Inspection viewport copies live meshes/poses; it never edits assembly state.
const OUT = "res://verification/pitch-visual-review/"
var inspection: SubViewport
var stage: Node3D
var lens: Camera3D
var records: Array = []
var page_records: Dictionary = {}
var serial: int = 0

func run(workshop: Node) -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Visual review requires a real renderer. Use --disable-render-loop, not --headless.")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	inspection = SubViewport.new()
	inspection.size = Vector2i(960,720)
	inspection.own_world_3d = true
	inspection.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(inspection)
	stage = Node3D.new()
	inspection.add_child(stage)
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("19232c")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("dce5ef")
	env.environment.ambient_light_energy = 0.75
	inspection.add_child(env)
	for rotation in [Vector3(-35,-30,0),Vector3(30,140,0)]:
		var light = DirectionalLight3D.new()
		light.rotation_degrees = rotation
		light.light_energy = 1.2
		inspection.add_child(light)
	lens = Camera3D.new()
	lens.projection = Camera3D.PROJECTION_ORTHOGONAL
	lens.near = 0.001
	inspection.add_child(lens)
	lens.current = true
	await super.run(workshop)

func copy_mesh(original: MeshInstance3D, service: bool, root: bool = false) -> void:
	var mesh = MeshInstance3D.new()
	mesh.mesh = original.mesh
	stage.add_child(mesh)
	mesh.global_transform = original.global_transform
	mesh.force_update_transform()
	mesh.material_override = original.material_override
	if root:
		mesh.material_override = null
		if service:
			mesh.material_override = game.material(Color(0.4,0.6,0.68,0.12))
			mesh.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mesh.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED

func rebuild_stage(owner: String, service: bool, preview: bool, exposed: bool = false) -> void:
	for child in stage.get_children():
		stage.remove_child(child)
		child.queue_free()
	for child in game.bodies.pitch.get_children():
		if child is MeshInstance3D:
			if exposed and not child.has_meta("component_uid"):continue
			copy_mesh(child,service,not child.has_meta("component_uid"))
	if owner == "foot":
		for child in game.components.parent_visuals.get_children():
			if child is MeshInstance3D:copy_mesh(child,service)
	if preview and game.ghost.visible:copy_mesh(game.ghost,service)

func save_inspection(path: String, center: Vector3, size: float, direction: Vector3, up: Vector3) -> void:
	lens.position = center+direction.normalized()*maxf(size*3,0.5)
	lens.look_at(center,up)
	lens.size = size
	lens.force_update_transform()
	# Materials and newly copied geometry must enter the renderer before drawing.
	await get_tree().process_frame
	inspection.render_target_update_mode = SubViewport.UPDATE_ONCE
	RenderingServer.force_draw(false)
	var error = inspection.get_texture().get_image().save_png(OUT+path)
	assert(error == OK)

func review_checkpoint(owner: String, phase: String, sid: String = "") -> void:
	serial += 1
	var page: int = game.hud.page+1
	var step: Dictionary = game.components.definition(owner).manual[page-1]
	var prefix = "%s-%02d"%[owner,page]
	var stem = "%s-%03d-%s"%[prefix,serial,phase]
	if not sid.is_empty():stem += "-"+sid.replace("/","_")
	var record = {"owner":owner,"page":page,"title":step.title,"phase":phase,"slot":sid,"captures":[],"target":str(game.target),"body_transform":str(game.bodies.pitch.global_transform)}
	if not page_records.has(prefix):
		var quantities = {}
		for slot in step.slots:
			var d = game.model.slot_definition(owner,slot)
			var kind = d.get("accepts",d.get("assembly",""))
			quantities[kind] = quantities.get(kind,0)+1
		page_records[prefix] = {"owner":owner,"page":page,"title":step.title,"slots":step.slots,"required":quantities if step.get("view","") != "prepared" else {},"body":step.body}
	game.hud.refresh()
	if sid.is_empty():
		var pose: Transform3D = game.bodies.pitch.global_transform*game.source["FA-510__001"].transform.affine_inverse()
		var midpoint: Vector3 = pose*((game.source["FA-525__001"].transform.origin+game.source["FA-525__002"].transform.origin)*0.5)
		await aim(midpoint,1.1)
	await get_tree().process_frame
	# Force both the manual's subviewport and its compositing frame.
	RenderingServer.force_draw(false)
	RenderingServer.force_draw(false)
	if sid.is_empty() or phase == "mount-preview":
		var path = stem+"-hud.png"
		game.get_viewport().get_texture().get_image().save_png(OUT+path)
		record.captures.append(path)
		page_records[prefix][phase+"_hud_text"] = game.hud.page_body.text
		game.hud.body_scroll.scroll_vertical = 10000
		await get_tree().process_frame
		RenderingServer.force_draw(false)
		path = stem+"-hud-scrolled.png"
		game.get_viewport().get_texture().get_image().save_png(OUT+path)
		record.captures.append(path)
		game.hud.body_scroll.scroll_vertical = 0
	var base: Transform3D = game.bodies.pitch.global_transform*game.source["FA-510__001"].transform.affine_inverse()
	var eye0: Vector3 = base*game.source["FA-525__001"].transform.origin
	var eye1: Vector3 = base*game.source["FA-525__002"].transform.origin
	var axial: Vector3 = (eye1-eye0).normalized()
	var crosswise: Vector3 = base.basis*Vector3.RIGHT
	var side: Vector3 = axial.cross(crosswise).normalized()
	var center: Vector3 = (eye0+eye1)*0.5
	var size: float = eye0.distance_to(eye1)*1.25
	if not sid.is_empty() and sid != "pitch":
		var d = game.model.slot_definition(owner,sid)
		var bounds: AABB = game.components.slot_pose(owner,sid)*game.source[d.pose_source].mesh.get_aabb()
		center = bounds.get_center()
		size = maxf(bounds.size.length()*1.5,0.13)
		record["slot_transform"] = str(game.components.slot_pose(owner,sid))
		record["source"] = d.pose_source
		record["consumed_uid"] = game.model.assemblies[owner].slots[sid]
		record["selected_uid"] = game.components.selected_uid(game.selected_kind)
	var modes = ["service","opaque","exposed"] if sid.is_empty() else ["service","exposed"]
	var states = ["before","preview"] if phase == "preview" else [phase]
	for state_name in states:
		for mode in modes:
			rebuild_stage(owner,mode == "service",state_name == "preview",mode == "exposed")
			var views = [crosswise+side*0.7+axial*0.4,-crosswise-side*0.7-axial*0.4]
			for angle in range(views.size()):
				var path = stem+"-%s-%s-%d.png"%[state_name,mode,angle]
				await save_inspection(path,center,size,views[angle],axial)
				record.captures.append(path)
	records.append(record)
	if phase in ["ready","mounted"]:
		await capture_rotation(owner,record,stem)
	FileAccess.open(OUT+"captures.json",FileAccess.WRITE).store_string(JSON.stringify({"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"pages":page_records,"records":records,"visual_approval":false},"  "))
	print("REVIEW_CAPTURE ",stem)

func capture_rotation(owner: String, record: Dictionary, stem: String) -> void:
	var station = "foot" if owner == "foot" else "prep3"
	var node: Node3D = game.foot if owner == "foot" else game.stations.prep3
	await aim(node.global_position,2.0)
	key(KEY_R)
	var follows = game.rotation_station == station
	for i in range(48):
		await get_tree().process_frame
		var motion = InputEventMouseMotion.new()
		motion.relative = Vector2(8,5 if i < 24 else -7)
		game.handle_desktop_input(motion)
		# Check before the next physics tick, throughout the drag.
		var expected: Transform3D = game.stations.prep3.global_transform
		if owner == "foot":expected = game.foot.global_transform*Transform3D(Basis.IDENTITY,-game.FOOT_CENTER)*game.source["FA-510__001"].transform
		follows = follows and game.bodies.pitch.global_transform.is_equal_approx(expected)
		for child in game.bodies.pitch.get_children():
			if child.has_meta("component_uid"):
				var item = game.model.items[child.get_meta("component_uid")]
				follows = follows and matches_source_geometry(child,game.components.slot_pose("pitch",item.slot),game.model.slot_definition("pitch",item.slot).pose_source)
		if i%4 == 0:
			RenderingServer.force_draw(false)
			var path = stem+"-rotation-%02d.png"%i
			game.get_viewport().get_texture().get_image().save_png(OUT+path)
			record.captures.append(path)
	release(KEY_R)
	game.reset_station(station)
	await frames(4)
	expect(follows,"Continuous rendered R-drag preserves actuator body and all installed geometry at "+station)

func conclude() -> void:
	var passed = checks.all(func(c):return c.passed)
	FileAccess.open(OUT+"behavior.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"rendered":true},"  "))
	print("PITCH_VISUAL_CAPTURE ","PASS" if passed else "FAIL"," ",checks.size()," checks; ",records.size()," checkpoints. Images require human/model visual inspection.")
	await finish(passed)
