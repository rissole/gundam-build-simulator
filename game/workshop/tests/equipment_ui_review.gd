extends "res://tests/workshop_visual_review.gd"
## Rendered UI fixtures, not walked playtest acceptance.
func run() -> void:
	if DisplayServer.get_name() == "headless":quit(2);return
	var tag = "after"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-tag="):tag = arg.trim_prefix("--review-tag=").validate_filename()
	output_dir = "res://verification/equipment-ui-%s-%s" % [tag,Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(output_dir)
	var inputs = hashes()
	game = instantiate_profile(self,"leg_bay_m3")
	game.set_paused(false);game.set_physics_process(false)
	await frames(5,false)
	game.hud.manual.hide();game.hud.toast_time = 0;game.hud.toast_panel.hide()
	root.content_scale_size=Vector2i(1440,900);root.size=Vector2i(1440,900)
	var crane = game.equipment.get_equipment("service_crane")
	var point: Vector3 = crane.console_node.global_position
	var eye = point+Vector3(0,.5,1.25)
	await capture("01-console-closed",eye,point)
	var error: String = crane.console.open()
	if not error.is_empty():push_error(error);quit(2);return
	await capture("02-crane-controls",eye,point,false)
	if crane.console.has_method("_show_tasks"):
		crane.console._show_tasks(true)
		await capture("03-crane-loads",eye,point,false)
		crane.console.search.text = "pelvis";crane.console.refresh()
		await capture("03b-crane-search",eye,point,false)
		crane.console._show_tasks(false)
	root.content_scale_size=Vector2i(1280,720);root.size=Vector2i(1280,720)
	await capture("04-crane-720",eye,point,false)
	# Supplied empty-crane poses illustrate the operating states; no delivery claim.
	crane.station = "source";crane.raised = true;crane._refresh()
	await capture("04b-crane-at-pickup",eye,point,false)
	crane.raised = false;crane._refresh()
	await capture("04c-crane-lowered",eye,point,false)
	crane.raised = true;crane.station = "park";crane._refresh()
	crane.console.shut()
	for id in ["left_lift","mobile_platform","leg_rail","foot_carrier","module_supports"]:
		var equipment = game.equipment.get_equipment(id)
		if equipment == null:continue
		var entries: Array = equipment.controls()
		var entry: Dictionary = entries[0]
		if id == "left_lift":
			for candidate in entries:
				if candidate.action == "up":entry = candidate;break
		point = entry.point
		var offset = Vector3(-1.1,.5,0) if id in ["leg_rail","foot_carrier","module_supports"] else Vector3(0,.5,1.1)
		await capture("05-"+id,point+offset,point)
	finish(inputs)
