extends SceneTree
## Offline director. The Python wrapper owns encoding, provenance and failures.
## No live player input, save slot, wall-clock animation or alternate game scene.
const Stages = preload("res://scripts/build_stages.gd")
var game: Node
var stage_runner: RefCounted
var viewport: SubViewport
var camera: Camera3D
var job: Dictionary
var sequence: Dictionary
var trace: Array = []
var frame_index := 0
var failed := false
## Operated-rig arrows held like Hold E, by machine ID, with an optional tap
## requested once the held jog reaches its stop.
var held_jogs: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func die(message: String) -> void:
	failed = true
	push_error("PROGRESS_CAPTURE: "+message)
	quit(1)

func run() -> void:
	var job_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-job="):job_path=arg.trim_prefix("--capture-job=")
	if not FileAccess.file_exists(job_path):die("Use tools/record_progress.py to supply a capture job.");return
	job = JSON.parse_string(FileAccess.get_file_as_string(job_path))
	sequence = job.sequence
	if not job.check and DisplayServer.get_name()=="headless":die("Video requires the real renderer.");return
	seed(513)
	Engine.max_fps = 0
	game = load("res://scenes/workshop.tscn").instantiate()
	game.automated_test = true
	root.add_child(game)
	game.set_paused(false)
	game.set_physics_process(false)
	game.set_process(false)
	game.hud.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Park the operator outside every machine envelope. The camera has no collider.
	game.player.global_position = Vector3(-12,0.1,-7)
	stage_runner = Stages.new(game)
	for tick in range(8):await physics_frame
	var error: String = await stage_runner.run_to(sequence.stage,func(title: String):print("CAPTURE_PREP ",title))
	if not error.is_empty():die("Stage preparation: "+error);return
	if game.save.enabled():die("Recording must never enable the player's save slot.");return
	if not await operations(sequence.setup):return
	# Freeze loose stock only. Supported equipment retains its normal movement,
	# obstacle checks and ownership transfers; no animation is faked for the film.
	for body in game.find_children("*","RigidBody3D",true,false):
		if not body.freeze:body.freeze=true
	var groups: Array = game.find_children("AssemblyRenderGroup","",true,false)
	var deadline := Time.get_ticks_msec()+30000
	while groups.any(func(group):return group.busy()):
		if Time.get_ticks_msec()>deadline:die("Derived meshes did not finish.");return
		await process_frame
	viewport = SubViewport.new()
	viewport.size = Vector2i(job.width,job.height)
	viewport.world_3d = root.world_3d
	viewport.msaa_3d = root.msaa_3d
	viewport.positional_shadow_atlas_size = root.positional_shadow_atlas_size
	viewport.scaling_3d_scale = 1.0
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	camera = Camera3D.new()
	viewport.add_child(camera)
	camera.current = true
	camera.near = 0.05
	camera.far = 180
	root.disable_3d = true
	for shot in sequence.shots:
		if not await operations(shot.get("before",[])):return
		if not await operations(shot.get("start",[])):return
		print("CAPTURE_SHOT ",shot.id)
		var count := int(round(float(shot.seconds)*job.fps))
		var steps := int(60/job.fps)*int(shot.speed)
		for frame in range(count):
			# Capture t=0 before stepping. Every output frame advances exactly the
			# same number of 1/60-second equipment ticks, including skipped previews.
			pose_camera(shot,float(frame)/maxi(1,count-1))
			var sample := {"frame":frame_index,"shot":shot.id,"eye":vec(camera.position),"basis":str(camera.basis),"fov":camera.fov,"equipment":{}}
			for id in sequence.watch:sample.equipment[id]=game.equipment.get_equipment(id).capture()
			trace.append(sample)
			if not job.check and (not job.storyboard or frame in [0,int(count/2),count-1]):
				# Flush the cut's camera transform before drawing this frame. Without
				# this, Godot can return the previous shot at the cut boundary.
				camera.force_update_transform()
				await process_frame
				viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
				RenderingServer.force_draw(false)
				var picture := viewport.get_texture().get_image()
				if picture==null or picture.is_empty() or picture.get_size()!=viewport.size:die("Missing or incorrectly sized render.");return
				var path: String=job.output.path_join("frame-%06d.png" % frame_index)
				if picture.save_png(path)!=OK:die("Cannot write "+path);return
			frame_index+=1
			if not await advance(steps):return
	# A changed machine must fail loudly if the action no longer fits the edit.
	# Final checks run at the recorded endpoint, without offscreen completion.
	for id in sequence.get("expect",{}):
		var machine=game.equipment.get_equipment(id)
		for property in sequence.expect[id]:
			var actual=machine.get(property);var expected=sequence.expect[id][property]
			var matches: bool=is_equal_approx(float(actual),float(expected)) if expected is float or expected is int else actual==expected
			if not matches:die("Final "+id+"."+property+": expected "+str(expected)+", got "+str(actual));return
	for owner in sequence.get("locations",{}):
		if game.model.assemblies[owner].location!=sequence.locations[owner]:die("Wrong final support for "+owner);return
	for owner in sequence.get("parents",{}):
		if game.model.assemblies[owner].parent!=sequence.parents[owner]:die("Wrong final parent for "+owner);return
	if sequence.has("final_stage"):
		var errors: Array=stage_runner.stage_errors(sequence.final_stage)
		if not errors.is_empty():die("Final stage: "+str(errors));return
	var integrity: Array=game.model.integrity_errors()
	if not integrity.is_empty():die("Final model integrity: "+str(integrity));return
	var report := {"frames":frame_index,"fps":job.fps,"size":[job.width,job.height],"engine":Engine.get_version_info().string,"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"save_enabled":game.save.enabled(),"trace":trace,"final_equipment":{},"final_model":{"assemblies":game.model.assemblies,"items":game.model.items}}
	for id in sequence.watch:report.final_equipment[id]=game.equipment.get_equipment(id).capture()
	var file := FileAccess.open(job.output.path_join("capture.json"),FileAccess.WRITE)
	if file==null:die("Cannot write capture report.");return
	file.store_string(JSON.stringify(report,"\t"));file.close()
	print("CAPTURE_OK ",frame_index," frames")
	game.free()
	quit(0)

func operations(entries: Array) -> bool:
	for entry in entries:
		# Supplied construction between shots uses the same shelf/retention paths
		# as stage setup. These operations never animate fake fastener installation.
		if entry.has("shelf"):
			var error: String=stage_runner._shelf_item(entry.shelf)
			if not error.is_empty():die(error);return false
			continue
		if entry.has("retain"):
			var receiver=game.equipment.get_equipment(entry.retain)
			for sid in receiver.spec.get("captive_slots",[]):
				var error: String=receiver.request("fasten:"+sid)
				if not error.is_empty():die(error);return false
			Stages.Staging.fill(game,receiver.spec.owner,receiver.spec.retention_slots)
			if not receiver.retained():die("Could not supply retention: "+entry.retain);return false
			continue
		if entry.has("rig"):
			stage_runner.supply_rig(game.equipment.get_equipment("service_crane"),entry.rig)
			continue
		var machine=game.equipment.get_equipment(entry.equipment)
		if machine==null:die("Unknown equipment: "+entry.equipment);return false
		var error := ""
		if entry.has("jog"):
			error=machine.action_error(entry.jog)
			if error.is_empty():machine.set_jog(entry.jog);held_jogs[entry.equipment]=str(entry.get("then",""))
		elif entry.has("action"):error=machine.request(entry.action)
		elif entry.has("mode"):error=machine.request_mode(entry.mode)
		elif entry.has("closed"):error=machine.request_closed(entry.closed)
		if not error.is_empty():die(entry.equipment+": "+error);return false
		if entry.get("settle",false):
			for tick in range(7200):
				if not machine.moving:break
				if held_jogs.has(entry.equipment) and machine.jog_settled() and not finish_jog(entry.equipment):return false
				if not await advance(1):return false
			if machine.moving:die("Setup motion timed out: "+entry.equipment);return false
	return true

## Releases a settled held jog, then requests its follow-up tap.
func finish_jog(id: String) -> bool:
	var machine=game.equipment.get_equipment(id);var then: String=held_jogs[id]
	held_jogs.erase(id);machine.set_jog("")
	var error: String=machine.request(then) if not then.is_empty() else ""
	if not error.is_empty():die(id+": "+error);return false
	return true

func advance(ticks: int) -> bool:
	for tick in range(ticks):
		# Yield to Jolt so each sweep sees the preceding tick's collider poses.
		await physics_frame
		game.equipment.physics(1.0/60.0)
		for id in held_jogs.keys():
			if not held_jogs[id].is_empty() and game.equipment.get_equipment(id).jog_settled() and not finish_jog(id):return false
		for id in sequence.watch:
			var machine=game.equipment.get_equipment(id)
			var blockage=machine.get("blocked_reason")
			if blockage is String and not blockage.is_empty():die(id+": "+blockage);return false
	return true

func pose_camera(shot: Dictionary, weight: float) -> void:
	var anchor := Vector3.ZERO
	if shot.has("anchor"):anchor=game.assembly_node(shot.anchor).global_position
	var ease := weight*weight*(3.0-2.0*weight)
	camera.position=anchor+point(shot.eye_from).lerp(point(shot.eye_to),ease)
	camera.fov=shot.fov
	camera.look_at(anchor+point(shot.target),Vector3.UP)

func point(value: Array) -> Vector3:return Vector3(value[0],value[1],value[2])
func vec(value: Vector3) -> Array:return [value.x,value.y,value.z]
