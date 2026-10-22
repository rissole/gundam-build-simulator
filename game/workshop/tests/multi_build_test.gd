extends "res://tests/demo_test.gd"
## Two physical instances, public controls, shared stock and nested manuals.
var pad_review: bool = false
var review_images: Array[Dictionary] = []
const PAD_REVIEW_DIR = "res://verification/pad-runtime-review/"

func capture(name: String) -> void:
	if not pad_review:
		await super.capture(name)
		return
	if not rendered:return
	await get_tree().process_frame
	game._update_target()
	game._update_ghost()
	game.hud.refresh()
	await frames(4)
	RenderingServer.force_draw(false)
	game.get_viewport().get_texture().get_image().save_png(PAD_REVIEW_DIR+name+".png")
	_record_review(name,["pad_1","pad_2"])

func _record_review(name: String, owners: Array) -> void:
	var builds: Dictionary = {}
	for owner in owners:
		var a: Dictionary = game.model.assemblies[owner]
		builds[owner] = {"parent":a.parent,"parent_slot":a.parent_slot,"location":a.location,"slots":a.slots.duplicate(),"body_pose":str(game.bodies[owner].global_transform)}
	review_images.append({"image":name+".png","manual_id":game.hud.manual_id,"page":game.hud.page,"builds":builds,"parent_slots":game.model.assemblies.foot.slots.duplicate()})

func inspect_pads(name: String, side: float, owners: Array = ["pad_1","pad_2"]) -> void:
	if not pad_review or not rendered:return
	var saved_player: Transform3D = game.player.global_transform
	var saved_camera: Transform3D = game.camera.global_transform
	var saved_paused: bool = game.paused
	var saved_hud: bool = game.hud.visible
	game.paused = true
	game.hud.visible = false
	game.ghost.visible = false
	var center = Vector3.ZERO
	for owner in owners:center += game.bodies[owner].global_position
	center /= owners.size()
	var frame: Basis = game.foot.global_basis if owners.size() > 1 else game.bodies[owners[0]].global_basis
	game.camera.global_position = center+frame*Vector3(side,-1.5,-0.30)
	game.camera.look_at(center)
	await frames(4)
	RenderingServer.force_draw(false)
	game.get_viewport().get_texture().get_image().save_png(PAD_REVIEW_DIR+name+".png")
	_record_review(name,owners)
	game.player.global_transform = saved_player
	game.camera.global_transform = saved_camera
	game.paused = saved_paused
	game.hud.visible = saved_hud

func run(workshop: Node) -> void:
	game = workshop
	rendered = DisplayServer.get_name() != "headless"
	pad_review = OS.get_cmdline_user_args().has("--pad-review")
	if pad_review:DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PAD_REVIEW_DIR))
	await frames(15)
	expect(game.active_ids.size()==26 and game.source.size()==745,"Both pads' 26 identities are removed from the 745-object context")
	expect(game.builds.size()==2 and game.stations.size()==2,"Two builds and two interchangeable preparation stations")
	game.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	expect(game.hud.manual_id=="foot","Workshop starts at the parent manual")
	key(KEY_ENTER)
	expect(game.hud.manual_id=="pad_1","Enter opens the first available child manual")
	key(KEY_RIGHT)
	key(KEY_C)
	expect(game.hud.manual_id=="pad_2" and game.hud.page==0,"Second physical pad has independent manual position")
	key(KEY_C)
	key(KEY_ENTER)
	expect(game.hud.manual_id=="pad_1" and game.hud.page==1,"Returning to a build restores its page")
	key(KEY_LEFT)
	for kind in HeelAssemblyState.KINDS:
		await aim(game.bins[kind].global_position+Vector3(0,0.13,0.27))
		key(KEY_E,true)
	expect(game.model.pocket_count()==24 and game.model.count_at("bolt","bin")==0,"Three independent pockets hold all shared pad stock")
	await aim(game.bodies.pad_1.global_position)
	key(KEY_E)
	expect(game.builds.pad_1.pad_location=="held","Pick up pad A")
	await aim(game.bodies.pad_2.global_position)
	key(KEY_E)
	expect(game.builds.pad_2.pad_location=="loose" and game.held_build()=="pad_1","Occupied hands cannot acquire a second two-hand assembly")
	await aim(game.stations.prep.global_position)
	await frames(45)
	game._update_target()
	click()
	expect(game.builds.pad_1.station_id=="prep","Pad A occupies preparation A")
	select_kind("sleeve")
	for i in [2,0]:
		game._activate("pad_1")
		await aim(game.connection(i))
		click()
	expect(game.builds.pad_1.installed("sleeve")==2,"Partially prepare pad A")
	await aim(game.bodies.pad_2.global_position)
	expect(game.hud.manual_id=="pad_1" and game.hud.page==0,"Looking at another build does not replace the current manual")
	key(KEY_V)
	expect(game.hud.manual_id=="pad_2","V explicitly opens the inspected build's manual")
	key(KEY_E)
	await aim(game.stations.prep2.global_position)
	await frames(70)
	game._update_target()
	click()
	expect(game.builds.pad_2.station_id=="prep2","Pad B uses preparation B")
	select_kind("sleeve")
	game._activate("pad_2")
	await aim(game.connection(1))
	click()
	expect(game.builds.pad_2.installed("sleeve")==1 and game.builds.pad_1.installed("sleeve")==2,"Independent build progress with common hardware stock")
	key(KEY_BACKSPACE)
	expect(game.hud.page_body.text.contains("2 / 4 sleeves") and game.hud.page_body.text.contains("1 / 4 sleeves"),"Parent overview reports both unfinished children")
	await capture("07-multiple-builds")
	# Resume A, mount it at the opposite heel slot, then move B into A's old station.
	for i in [3,1]:
		game._activate("pad_1")
		await aim(game.connection(i))
		click()
	expect(game.builds.pad_1.prepared(),"Returning to pad A completes the same physical assembly")
	await aim(game.bodies.pad_1.global_position)
	key(KEY_E)
	await aim(game.mount_point("heel_2"))
	await frames(100)
	game._update_target()
	game._update_ghost()
	expect(game.target.get("mount")=="heel_2" and game.ghost.visible,"Prepared pad previews at the opposite compatible heel position")
	click()
	expect(game.model.assemblies.foot.slots.heel_2=="pad_1","Physical pad A fits heel position 2")
	game.hud.open_manual("foot",2)
	key(KEY_ENTER)
	expect(game.hud.manual_id=="pad_1","Parent child link resolves to the actual installed pad")
	key(KEY_Z)
	expect(game.builds.pad_1.prepared() and game.hud.toast_label.text.contains("parent"),"Child undo cannot invalidate a mounted parent")
	await aim(game.bodies.pad_2.global_position)
	key(KEY_E)
	await aim(game.stations.prep.global_position)
	await frames(75)
	game._update_target()
	click()
	expect(game.builds.pad_2.station_id=="prep" and game.builds.pad_2.installed("sleeve")==1,"Unfinished pad changes stations with its progress intact")
	select_kind("sleeve")
	for i in [3,0,2]:
		game._activate("pad_2")
		await aim(game.connection(i))
		click()
	expect(game.builds.pad_2.prepared(),"Pad B completes using the same authored definition")
	await aim(game.bodies.pad_2.global_position)
	key(KEY_E)
	await aim(game.mount_point("heel_1"))
	await frames(100)
	game._update_target()
	click()
	expect(game.model.assemblies.foot.slots.heel_1=="pad_2","Physical pad B fits remaining heel position 1")
	# Restock the four bolts that did not fit in the initial pocket load.
	await aim(game.bins.bolt.global_position+Vector3(0,0.13,0.27))
	key(KEY_E,true)
	expect(game.model.count_at("bolt","pocket")==8,"An empty drawer leaves the existing bolt stack intact")
	for id in ["pad_2","pad_1"]:
		for i in [3,0,2,1]:
			game._activate(id)
			await aim(game.connection(i))
			select_kind("washer")
			click()
			select_kind("bolt")
			game._update_ghost()
			expect(game.ghost.visible,"Valid local bolt preview for %s connection %d"%[id,i])
			click()
		expect(game.builds[id].complete(),"Complete installation: "+id)
	game.hud.open_manual("foot")
	game.hud.page = 0
	game.hud.refresh()
	expect(game.model.milestone("foot","complete") and game.hud.page_count.text.contains("2 / 2"),"Parent completion derives from both secured installations")
	expect(game.model.pocket_count()==0 and game.model.integrity_errors().is_empty(),"Exactly 26 original pieces remain accounted for after completion")
	await capture("08-two-pads-complete")
	await inspect_pads("09-complete-left",-0.5)
	await inspect_pads("10-complete-right",0.5)
	# Physics must not overwrite a mounted child's local pose after its parent moves.
	# Exercise awake bodies too; sleeping can hide a competing physics transform.
	for body in game.bodies.values():
		body.can_sleep = false
		body.sleeping = false
	await aim(game.foot.global_position,2.5)
	var follows_during_drag = true
	key(KEY_R)
	for tick in range(45):
		await get_tree().process_frame
		var motion = InputEventMouseMotion.new()
		motion.relative = Vector2(3,2)
		game.handle_desktop_input(motion)
		await frames(1)
		for id in ["pad_1","pad_2"]:
			var source_id: String = game.model.slot_definition("foot",game.builds[id].mount_slot).pose_source
			var expected: Transform3D = game.foot.global_transform*Transform3D(Basis.IDENTITY,-game.FOOT_CENTER)*game.source[source_id].transform
			if not game.bodies[id].global_transform.is_equal_approx(expected):follows_during_drag = false
	release(KEY_R)
	expect(follows_during_drag,"Both mounted pads follow a continuous R-drag between physics ticks")
	await inspect_pads("11-continuous-rotation-left",-0.5)
	await inspect_pads("12-continuous-rotation-right",0.5)
	for delta in [Vector2(80,45),Vector2(-35,90),Vector2(55,-60)]:
		var before_rotation: Basis = game.foot.basis
		game._rotate_station(delta)
		await frames(15)
		expect(not before_rotation.is_equal_approx(game.foot.basis),"Foot station rotates during mounted-child regression")
		for id in ["pad_1","pad_2"]:
			var source_id: String = game.model.slot_definition("foot",game.builds[id].mount_slot).pose_source
			var expected: Transform3D = game.foot.global_transform*Transform3D(Basis.IDENTITY,-game.FOOT_CENTER)*game.source[source_id].transform
			expect(game.bodies[id].global_transform.is_equal_approx(expected),"Mounted %s follows foot rotation %s after physics settles"%[id,delta])
			expect(game.bodies[id].get_child(0).global_transform.is_equal_approx(expected),"Mounted %s mesh follows foot rotation %s"%[id,delta])
			var physics_pose: Transform3D = PhysicsServer3D.body_get_state(game.bodies[id].get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
			expect(physics_pose.is_equal_approx(expected),"Mounted %s physics follows foot rotation %s"%[id,delta])
	game.reset_station("foot")
	await frames(15)
	# Parent history is independent of which physical build the camera targets.
	await aim(game.bodies.pad_2.global_position)
	key(KEY_Z)
	expect(not game.builds.pad_1.complete() and game.builds.pad_2.complete(),"Parent undo reverses its latest placement without touching another branch")
	key(KEY_BACKSPACE)
	for i in range(16):key(KEY_Z)
	expect(game.builds.pad_2.pad_location=="prep" and game.builds.pad_2.prepared(),"Undo parent fasteners and latest mount retains prepared child")
	expect(game.model.assemblies.foot.slots.heel_2=="pad_1","Undo does not detach the other mounted child")
	await inspect_pads("13-undo-restored-pad",-0.4,["pad_2"])
	await inspect_pads("14-remaining-mounted-pad",0.4,["pad_1"])
	key(KEY_Z)
	expect(game.builds.pad_1.pad_location=="prep" and game.builds.pad_1.prepared(),"Next mount undo selects the other free station")
	expect(game.builds.pad_1.station_id != game.builds.pad_2.station_id,"Undo output never overlaps station occupants")
	expect(game.model.integrity_errors().is_empty(),"Nested undo conserves all physical identities and dependencies")
	var passed = checks.all(func(c):return c.passed)
	if pad_review:
		FileAccess.open(PAD_REVIEW_DIR+"capture.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"rendered":rendered,"engine":Engine.get_version_info().string,"images":review_images},"  "))
	FileAccess.open("res://verification/multi-build-audit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"rendered":rendered},"  "))
	print("MULTI_BUILD_AUDIT ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	await finish(passed)
