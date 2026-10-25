extends SceneTree
## Real-time mouse-look benchmark. Do not use --fixed-fps or --disable-render-loop.
## ./play.command --script tools/benchmark_mouse_look.gd
## --headless measures CPU only. Optional user args: --seconds=4 --tag=baseline
## --variant=no-shadows|four-split-shadows|no-msaa|no-context|no-feedback
## --input-events=8 dispatches a burst through Godot; default 1. 0 calls the adapter directly.
## --benchmark-windowed requests a 1440x900 window; actual size is recorded.
## --force-draw measures explicit render throughput, not normal presentation pacing.
## --feet aims at the current left/right foot mesh bounds instead of generic bay views.
var game: Node
var seconds := 4.0
var tag := "baseline"
var variant := "normal"
var yaw_radius := 0.70
var pitch_radius := 0.38
var period := 2.0
var input_events := 1
var force_draw := false
var windowed := false
var feet := false
var initial_pitch := 0.0
var phase_target := Vector3.ZERO
var targeting_foot := false
var rendered_frames := 0
var max_look_error := 0.0
var reports: Array[Dictionary] = []
var output_dir: String

func _initialize() -> void:
	run.call_deferred()

func frame_rendered() -> void:
	rendered_frames += 1

func stats(values: Array[float]) -> Dictionary:
	if values.is_empty():return {}
	var ordered := values.duplicate()
	ordered.sort()
	var total := 0.0
	for value in values:total += value
	return {"mean":total / values.size(),"p50":ordered[int((ordered.size()-1)*0.50)],
		"p95":ordered[int((ordered.size()-1)*0.95)],"p99":ordered[int((ordered.size()-1)*0.99)],"max":ordered.back()}

func feedback() -> Dictionary:
	var start := Time.get_ticks_usec()
	game._update_target()
	var targeted := Time.get_ticks_usec()
	game._update_markers()
	# Targeting refreshes both prompt and preview using one access result.
	return {"target_ms":(targeted-start)/1000.0,
		"markers_ms":(Time.get_ticks_usec()-targeted)/1000.0}

func drive_look(elapsed: float, moving: bool, initial_yaw: float) -> float:
	var angle := elapsed*TAU/period
	var yaw := initial_yaw + (yaw_radius*sin(angle) if moving else 0.0)
	var pitch := initial_pitch + (pitch_radius*(cos(angle)-1.0) if moving else 0.0)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2((game.player.rotation.y-yaw)/0.0022,(game.camera.rotation.x-pitch)/0.0022)
	motion.screen_relative = motion.relative
	motion.position = root.get_visible_rect().size/2.0
	var start := Time.get_ticks_usec()
	if input_events == 0:
		game.handle_desktop_input(motion)
	else:
		motion.relative /= input_events
		motion.screen_relative /= input_events
		# Only these synchronous synthetic events enter live desktop dispatch.
		# Real desktop events remain isolated by the automated_test guard.
		game.automated_test = false
		for event in range(input_events):root.push_input(motion.duplicate(),true)
		game.automated_test = true
	max_look_error = maxf(max_look_error,absf(game.player.rotation.y-yaw)+absf(game.camera.rotation.x-pitch))
	return (Time.get_ticks_usec()-start)/1000.0

func phase(label: String, eye: Vector3, initial_yaw: float, moving: bool) -> void:
	game.player.global_position = eye-Vector3.UP*1.63
	game.player.rotation = Vector3(0,initial_yaw,0)
	game.camera.rotation = Vector3.ZERO
	game.camera.rotation.x = initial_pitch
	game.player.velocity = Vector3.ZERO
	var start := Time.get_ticks_usec()
	while (Time.get_ticks_usec()-start)/1000000.0 < 2.0:
		drive_look((Time.get_ticks_usec()-start)/1000000.0,moving,initial_yaw)
		if variant != "no-feedback":feedback()
		if force_draw:RenderingServer.force_draw(true)
		await process_frame
	var samples: Array[Dictionary] = []
	start = Time.get_ticks_usec()
	var previous := start
	var drawn := rendered_frames
	while (Time.get_ticks_usec()-start)/1000000.0 < seconds:
		var sample := {"input_ms":drive_look((Time.get_ticks_usec()-start)/1000000.0,moving,initial_yaw)}
		if variant != "no-feedback":sample.merge(feedback())
		if force_draw:RenderingServer.force_draw(true)
		await process_frame
		var now := Time.get_ticks_usec()
		sample.merge({"frame_ms":(now-previous)/1000.0,
			"rendered_frames":rendered_frames-drawn,"window_has_focus":float(root.has_focus()),
			"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,
			"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0,
			"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
		if targeting_foot:sample["foot_center_in_frustum"] = float(game.camera.is_position_in_frustum(phase_target))
		samples.append(sample)
		previous = now
		drawn = rendered_frames
	var metrics := {}
	for metric in samples[0]:
		var values: Array[float] = []
		for sample in samples:values.append(float(sample[metric]))
		metrics[metric] = stats(values)
	var slow_frames := 0
	for sample in samples:
		if sample.frame_ms > 25.0:slow_frames += 1
	var report := {"phase":label,"moving":moving,"samples":samples.size(),
		"camera_eye":str(game.camera.global_position),"initial_yaw":initial_yaw,"initial_pitch":initial_pitch,
		"fps":1000.0/metrics.frame_ms.mean,"frames_over_25ms":slow_frames,"metrics":metrics,"raw":samples}
	reports.append(report)
	print("LOOK_PHASE ",label," fps=",snappedf(report.fps,0.1)," frame_p95_ms=",metrics.frame_ms.p95,
		" target_p95_ms=",metrics.get("target_ms",{}).get("p95",0)," draws=",metrics.draw_calls.mean)

func foot_phases(owner: String) -> void:
	var body: Node3D = game.runtime.nodes[owner]
	var bounds := AABB()
	var found := false
	for mesh in body.find_children("*", "MeshInstance3D", true, false):
		if not mesh.is_visible_in_tree() or mesh.mesh == null:continue
		var box: AABB = mesh.global_transform * mesh.mesh.get_aabb()
		bounds = bounds.merge(box) if found else box
		found = true
	assert(found, "Foot benchmark needs visible meshes: " + owner)
	phase_target = bounds.get_center()
	targeting_foot = true
	# Approach from the side: the feet are parked in a row along Z, so a
	# front-facing camera for the left foot would sit inside the right foot.
	var eye := phase_target + Vector3(4.0, 0.6, 0)
	var direction := (phase_target - eye).normalized()
	initial_pitch = asin(direction.y)
	var yaw := atan2(-direction.x, -direction.z)
	print("LOOK_FOOT ",owner," target=",phase_target," bounds=",bounds)
	await phase(owner+"-still", eye, yaw, false)
	await phase(owner+"-circle", eye, yaw, true)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seconds="):seconds = maxf(1.0,float(arg.trim_prefix("--seconds=")))
		elif arg.begins_with("--tag="):tag = arg.trim_prefix("--tag=").validate_filename()
		elif arg.begins_with("--variant="):variant = arg.trim_prefix("--variant=")
		elif arg.begins_with("--yaw="):yaw_radius = float(arg.trim_prefix("--yaw="))
		elif arg.begins_with("--pitch="):pitch_radius = clampf(float(arg.trim_prefix("--pitch=")),0.0,0.65)
		elif arg.begins_with("--period="):period = maxf(0.1,float(arg.trim_prefix("--period=")))
		elif arg.begins_with("--input-events="):input_events = clampi(int(arg.trim_prefix("--input-events=")),0,64)
		elif arg == "--force-draw":force_draw = true
		elif arg == "--benchmark-windowed":windowed = true
		elif arg == "--feet":feet = true
	if not variant in ["normal","no-shadows","four-split-shadows","no-msaa","no-context","no-feedback"]:
		push_error("Unknown benchmark variant: "+variant)
		quit(2)
		return
	game = load("res://scenes/workshop.tscn").instantiate()
	RenderingServer.frame_post_draw.connect(frame_rendered)
	if windowed:
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1440,900)
		root.always_on_top = true
		root.move_to_foreground()
	root.add_child(game)
	game.automated_test = true
	game.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if input_events > 0 else Input.MOUSE_MODE_VISIBLE
	# Same work as the live _process, timed separately; physics and rendering stay live.
	game.set_process(false)
	if feet:
		# Fixed inspection cameras must not fall or be displaced by foot collisions.
		game.player.set_physics_process(false)
		yaw_radius = 0.15
		pitch_radius = 0.08
	if force_draw:RenderingServer.render_loop_enabled = false
	if variant == "no-shadows":
		for light in game.find_children("*","Light3D",true,false):light.shadow_enabled = false
	elif variant == "four-split-shadows":
		for light in game.find_children("*","DirectionalLight3D",true,false):
			light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			light.directional_shadow_split_1 = 0.1
	elif variant == "no-msaa":root.msaa_3d = Viewport.MSAA_DISABLED
	elif variant == "no-context":
		for mesh in game.foot.find_children("*","MeshInstance3D",true,false):mesh.visible = false
	# macOS applies its initial fullscreen/window resize asynchronously.
	for frame in range(10):await process_frame
	# Measure steady rendering after asynchronous derived geometry is ready.
	var render_groups: Array = game.find_children("AssemblyRenderGroup","",true,false)
	var ready_deadline := Time.get_ticks_msec()+10000
	while render_groups.any(func(group):return group.busy()) and Time.get_ticks_msec()<ready_deadline:
		await process_frame
	if render_groups.any(func(group):return group.busy()):
		push_error("Render groups did not settle; reject this benchmark.")
		quit(1);return
	output_dir = "res://verification/mouse-look-%s-%s" % [tag,Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(output_dir)
	var metadata := {"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),
		"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),
		"window_size":str(DisplayServer.window_get_size()),"viewport_size":str(root.get_visible_rect().size),
		"viewport_texture_reported_size":str(root.get_texture().get_size()),"window_mode":DisplayServer.window_get_mode(),
		"window_has_focus":root.has_focus(),
		"scaling_3d_scale":root.scaling_3d_scale,"feet":feet,
		"screen_refresh_hz":DisplayServer.screen_get_refresh_rate(),"msaa_3d":root.msaa_3d,
		"max_fps":Engine.max_fps,"vsync":DisplayServer.window_get_vsync_mode(),"variant":variant,
		"yaw_radius":yaw_radius,"pitch_radius":pitch_radius,"circle_period_seconds":period,
		"input_events_per_frame":input_events,
		"force_draw":force_draw,
		"seconds_per_phase":seconds,"headless_cpu_only":DisplayServer.get_name() == "headless",
		"project_sha256":FileAccess.get_sha256("res://project.godot"),
		"workshop_sha256":FileAccess.get_sha256("res://scripts/workshop.gd")}
	print("LOOK_ENV ",JSON.stringify(metadata))
	if feet:
		await foot_phases("foot")
		await foot_phases("right_foot")
	else:
		await phase("arrival-still",Vector3(0,1.66,6.4),0.0,false)
		await phase("arrival-circle",Vector3(0,1.66,6.4),0.0,true)
		await phase("bay-still",Vector3(0,1.66,1.5),-0.60,false)
		await phase("bay-circle",Vector3(0,1.66,1.5),-0.60,true)
		await phase("arrival-circle-repeat",Vector3(0,1.66,6.4),0.0,true)
	metadata["max_look_error_radians"] = max_look_error
	metadata["valid_camera_path"] = max_look_error < 0.001
	metadata["valid_rendering"] = not metadata.headless_cpu_only and reports.all(func(report):return report.metrics.rendered_frames.mean >= 0.99)
	metadata["valid_foot_framing"] = not feet or reports.all(func(report):return report.metrics.foot_center_in_frustum.mean == 1.0)
	FileAccess.open(output_dir.path_join("audit.json"),FileAccess.WRITE).store_string(JSON.stringify({"environment":metadata,"phases":reports},"  "))
	print("LOOK_BENCHMARK_OUTPUT ",ProjectSettings.globalize_path(output_dir))
	if not metadata.valid_camera_path:push_error("Camera input was blocked; reject this benchmark.")
	if not metadata.headless_cpu_only and not metadata.valid_rendering:push_error("Frames were skipped, possibly by an occluded window; reject this benchmark.")
	game.queue_free()
	await process_frame
	quit(0 if metadata.valid_camera_path and metadata.valid_foot_framing and (metadata.headless_cpu_only or metadata.valid_rendering) else 1)
