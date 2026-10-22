extends SceneTree
## Opt-in survey of the live workshop, at standing eye height. Run with:
## ./play.command --windowed --resolution 1440x900 --disable-render-loop \
##   --fixed-fps 60 --script tests/workshop_visual_review.gd -- --review-tag=before
var game: Node
var output_dir: String
var records: Array[Dictionary] = []

func _initialize() -> void:
	run.call_deferred()

func hashes() -> Dictionary:
	var result = {}
	for folder in ["scripts", "assets", "tests"]:
		var path = ProjectSettings.globalize_path("res://"+folder)
		for file in DirAccess.get_files_at(path):
			if file.get_extension() in ["gd", "gdshader", "json", "glb"]:
				result[folder+"/"+file] = FileAccess.get_sha256(path.path_join(file))
	result["project.godot"] = FileAccess.get_sha256("res://project.godot")
	return result

func capture(id: String, eye: Vector3, point: Vector3, hud: bool = true) -> void:
	game.player.global_position = eye-Vector3(0,1.63,0)
	game.player.rotation = Vector3.ZERO
	game.camera.rotation = Vector3.ZERO
	game.camera.look_at(point)
	game.player.velocity = Vector3.ZERO
	game._update_target()
	game._update_ghost()
	game.hud.refresh()
	game.hud.visible = hud
	for frame in range(3):
		await process_frame
		RenderingServer.force_draw(false)
	var path = output_dir.path_join(id+".png")
	var error = game.get_viewport().get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Cannot save workshop capture: "+path)
		quit(2)
		return
	records.append({"id":id,"path":path,"sha256":FileAccess.get_sha256(path),"eye":str(eye),"look_at":str(point),"hud":hud,"fixture_pose":str(game.foot.global_transform)})

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Workshop visual review needs a real renderer, not --headless.")
		quit(2)
		return
	var tag = "survey"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-tag="):tag = arg.trim_prefix("--review-tag=").validate_filename()
	output_dir = "res://verification/workshop-%s-%s-%s" % [tag,Time.get_datetime_string_from_system().replace(":","-"),Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(output_dir)
	var inputs = hashes()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	game = load("res://scenes/workshop.tscn").instantiate()
	root.add_child(game)
	game.automated_test = true
	game.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Keep exact, repeatable standing views while rendering the actual live scene.
	game.set_physics_process(false)
	for frame in range(5):await process_frame
	if OS.get_cmdline_user_args().has("--review-harness"):
		await capture("01-front-west",Vector3(0.7,1.05,1.8),Vector3(1.4,0.17,0),false)
		await capture("02-front-east",Vector3(3.9,1.05,1.8),Vector3(3.2,0.17,0),false)
		await capture("03-rear-west",Vector3(0.7,1.05,-5.4),Vector3(1.4,0.17,-3.6),false)
		await capture("04-rear-east",Vector3(3.9,1.05,-5.4),Vector3(3.2,0.17,-3.6),false)
		for index in range(5):
			await capture("05-joint-motion-%02d" % index,Vector3(1.36+index*0.02,0.25,0.75),Vector3(1.4,0.15,0.1),false)
		finish(inputs)
		return
	await capture("01-arrival",Vector3(0,1.66,6.4),Vector3(0,1.6,-1.8))
	await capture("02-work-bay",Vector3(0,1.66,1.5),Vector3(2.6,1.35,-1.8),false)
	await capture("03-ramp-approach",Vector3(4.25,1.66,3.5),Vector3(4.25,0.55,-0.3),false)
	await capture("04-platform",Vector3(4.25,2.21,-0.4),Vector3(2.3,1.45,-1.8),false)
	var console: Node3D = game.foot_fixture.get_node("FixtureControls")
	await capture("05-console",console.global_position+Vector3(-1.12,1.63,0),console.global_position+Vector3(0,1.24,0))
	await capture("06-preparation",Vector3(-4.8,1.66,1.9),Vector3(-4.6,1.65,-1.2),false)
	await capture("07-small-stock",Vector3(-6.6,1.66,-4.5),Vector3(-6.6,1.35,-6.2))
	await capture("08-large-stock",Vector3(4.7,1.66,-4.45),Vector3(4.7,1.4,-6.2))
	await capture("09-carrier-joints",Vector3(0.65,1.2,0.6),Vector3(2.3,1,-0.1),false)
	await capture("10-carrier-joints-offset",Vector3(0.75,1.2,0.6),Vector3(2.3,1,-0.1),false)
	await capture("11-dispatch",Vector3(-0.5,1.66,8.1),Vector3(2.3,1.3,5.5),false)
	await capture("12-armor-storage",Vector3(5.2,1.66,5),Vector3(7,1.7,7),false)
	# Intermediate and final service poses expose otherwise hidden support joints.
	game.player.global_position = Vector3(-2,0.03,1)
	var response: String = game.foot_fixture.request("sole_left")
	if not response.is_empty():
		push_error(response)
		quit(2)
		return
	for frame in range(120):
		await physics_frame
		game.foot_fixture.physics(1.0/60.0)
	await capture("13-fixture-turning",Vector3(0,1.66,1.5),Vector3(2.3,1.55,-1.8),false)
	for frame in range(125):
		await physics_frame
		game.foot_fixture.physics(1.0/60.0)
	await capture("14-sole-access",Vector3(0,1.66,-1.8),Vector3(2.3,1.55,-1.8),false)
	finish(inputs)

func finish(inputs: Dictionary) -> void:
	var report = {"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"input_hashes":inputs,"inputs_unchanged":inputs == hashes(),"captures":records,"visual_approval":false}
	FileAccess.open(output_dir.path_join("captures.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("WORKSHOP_REVIEW ",ProjectSettings.globalize_path(output_dir)," ",records.size()," captures; inputs unchanged=",report.inputs_unchanged)
	game.chime.stop()
	game.chime.stream = null
	quit(0 if report.inputs_unchanged else 1)
