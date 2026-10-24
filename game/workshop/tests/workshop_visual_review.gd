extends "res://tests/kit/harness.gd"
## Opt-in survey of the live workshop, including an elevated hangar overview. Run with:
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
	game.automation.refresh_target()
	game.automation.refresh_presentation()
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
	await capture("01-workshop",Vector3(23,4.2,22),Vector3(3,2.5,10),false)
	await capture("02-limb-bay",Vector3(18,1.66,20),Vector3(12,1.6,10),false)
	await capture("03-gantry",Vector3(3,2.5,19),Vector3(13,11,27),false)
	await capture("04-preparation",Vector3(-1,1.66,17),Vector3(3.25,1.4,13),false)
	await capture("05-stock",Vector3(-3,1.66,3),Vector3(-3,1.0,-3),false)
	for index in range(12):
		await capture("motion-%02d" % index,Vector3(10+index*.06,1.66,12),Vector3(15,0.1,16),false)
	await capture("static-a",Vector3(10,1.66,12),Vector3(15,0.1,16),false)
	await capture("static-b",Vector3(10,1.66,12),Vector3(15,0.1,16),false)
	finish(inputs)

func finish(inputs: Dictionary) -> void:
	var report = {"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"input_hashes":inputs,"inputs_unchanged":inputs == hashes(),"captures":records,"visual_approval":false}
	write_evidence(output_dir.path_join("captures.json"),report)
	print("WORKSHOP_REVIEW ",ProjectSettings.globalize_path(output_dir)," ",records.size()," captures; inputs unchanged=",report.inputs_unchanged)
	game.chime.stop()
	game.chime.stream = null
	quit(0 if report.inputs_unchanged else 1)
