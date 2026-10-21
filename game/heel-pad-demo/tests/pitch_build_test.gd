extends "res://tests/demo_test.gd"
## Full source-backed actuator loop through desktop collection, targeting and placement.
var installed_count: int = 0

# Optional renderer-backed inspection; ordinary tests keep this a no-op.
func review_checkpoint(_owner: String, _phase: String, _sid: String = "") -> void:
	pass

func matches_source_geometry(visual: MeshInstance3D, expected: Transform3D, source_id: String) -> bool:
	# Source rotations can be baked into vertices. Comparing node transforms alone
	# misses a washer or bolt taken from an instance with a different local axis.
	var actual_vertices = visual.mesh.get_faces()
	var source_vertices = game.source[source_id].mesh.get_faces()
	if actual_vertices.size() != source_vertices.size():return false
	for i in range(source_vertices.size()):
		if (visual.global_transform*actual_vertices[i]).distance_to(expected*source_vertices[i]) > 0.00001:return false
	return true

func collect_kind(kind: String) -> void:
	var bin: Node3D = game.bins[kind]
	await aim(bin.global_position+Vector3(0,0.13,0.27),1.1)
	key(KEY_E)
	# A large component uses the actual grip and must clear its storage cradle.
	await frames(20)

func place_slot(owner: String, sid: String) -> bool:
	var d: Dictionary = game.model.slot_definition(owner,sid)
	var kind: String = d.accepts
	if game.model.find_item(kind,"pocket").is_empty():await collect_kind(kind)
	else:select_kind(kind)
	if not game.model.held_item().is_empty():
		# Travel through the open side aisle; teleporting the scripted camera straight
		# through occupied stations correctly leaves a solid carried part behind.
		await aim(Vector3(-9.5,1.4,-2.4),1.4)
		await frames(100)
		await aim(Vector3(-9.5,1.4,1.0),1.4)
		await frames(100)
	await aim(game.components.slot_point(owner,sid),1.6)
	await frames(100 if not game.model.held_item().is_empty() else 12)
	game._update_target()
	game._update_ghost()
	var target_ok: bool = game.target.get("type","") == "component" and game.target.get("owner","") == owner
	var matched: String = game.target.get("sid","")
	var before: int = game.model.assemblies[owner].history.size()
	await review_checkpoint(owner,"preview",matched)
	click()
	var ok: bool = target_ok and game.model.assemblies[owner].history.size() == before+1
	if not ok and is_instance_valid(game.components.held_body):
		var body: WorkshopPart = game.components.held_body
		var q = PhysicsRayQueryParameters3D.create(body.global_position,game.components.slot_pose(owner,sid).origin,3)
		q.exclude = [body.get_rid(),game.bodies[owner].get_rid()] if owner != "foot" else [body.get_rid()]
		print("CARRY_DIAGNOSTIC position=",body.global_position," destination=",game.components.slot_pose(owner,sid)," ray=",game.get_world_3d().direct_space_state.intersect_ray(q))
	if not ok:print("PITCH_DIAGNOSTIC ",sid," target=",game.target," toast=",game.hud.toast_label.text," selected=",game.selected_kind," held=",game.model.held_item())
	expect(ok,"Collect and attach "+sid)
	if ok:
		installed_count += 1
		var occupant: String = game.model.assemblies[owner].slots[matched]
		expect(game.model.items[occupant].kind == kind,"Placement preserves compatible type for "+matched)
		await review_checkpoint(owner,"installed",matched)
	return ok

func complete_page(owner: String, page_index: int) -> bool:
	game.hud.open_manual(owner,page_index)
	await frames(2)
	expect(game.get_viewport().get_visible_rect().encloses(game.hud.manual.get_global_rect()),"Manual page fits viewport: %s %d"%[owner,page_index+1])
	var step: Dictionary = game.components.definition(owner).manual[page_index]
	await review_checkpoint(owner,"begin")
	for pass_index in range(step.slots.size()+1):
		var remaining: Array = []
		for sid in step.slots:
			if game.model.assemblies[owner].slots[sid].is_empty():remaining.append(sid)
		if remaining.is_empty():
			await review_checkpoint(owner,"end")
			return true
		var next_slot = ""
		for sid in remaining:
			var d: Dictionary = game.model.slot_definition(owner,sid)
			if d.has("assembly"):continue
			if d.requires.all(func(r):return not game.model.assemblies[owner].slots[r].is_empty()):next_slot=sid;break
		if next_slot.is_empty():expect(false,"Reachable manual step "+step.title);return false
		if not await place_slot(owner,next_slot):return false
	expect(false,"Manual step terminates: "+step.title)
	return false

func run(workshop: Node) -> void:
	game = workshop
	rendered = DisplayServer.get_name() != "headless"
	await frames(12)
	game.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	expect(game.model.items.size()==135 and game.source.size()==745,"135 active identities from the complete 745-piece source")
	expect(game.builds.size()==3 and game.stations.size()==3,"Three independent builds and preparation stations")
	expect(game.model.assemblies.pitch.slots.size()==91,"Actuator definition contains all 91 physical pieces")
	game.hud.open_manual("foot",3)
	key(KEY_ENTER)
	expect(game.hud.manual_id=="pitch","Foot clevis page opens the compatible pitch child")
	game.hud.open_manual("pitch",4)
	expect(game.hud.action_slots.size()==10,"All manuals share ten persistent pocket slots")
	game.hud.open_manual("pad_1",1)
	game.hud.open_manual("pitch")
	expect(game.hud.page==4,"Actuator remembers its own page across pad manuals")
	# Collect the starting barrel from the floor and suspend it through normal input.
	await aim(game.bodies.pitch.global_position)
	key(KEY_E)
	await frames(40)
	await aim(game.stations.prep3.global_position)
	await frames(40)
	game._update_target()
	click()
	# Inspect pad geometry while carrying another recipe's selection.
	game.model.move_assembly("pad_1","station:prep")
	game._activate("pad_1")
	game._set_pad_station("prep")
	game.model.stock_pocket("h-12030")
	await aim(game.connection(0))
	expect(game.target.get("type","")=="slot" and game.hud.target_label.text.contains("M12"),"Pad target explains a different recipe's selected part without a missing-title error")
	game.model.move_assembly("pad_1","loose")
	game.bodies.pad_1.reparent(game)
	game.bodies.pad_1.global_position = game.home_position("pad_1")
	game.bodies.pad_1.freeze = false
	# Wrong family and premature cap closure are rejected by the public model.
	var cap: String = "FA-511__001"
	game.model.transfer(game.model.items[cap].kind,"bin","pocket")
	var rejected: Dictionary = game.model.install("pitch",cap,cap)
	expect(not rejected.ok and rejected.error.contains("prerequisite"),"Cap cannot close over unfinished internals")
	game.model.transfer(game.model.items[cap].kind,"pocket","bin")
	var pin: String = "FA-221__001"
	game.model.transfer(game.model.items[pin].kind,"bin","pocket")
	expect(not game.model.install("foot","pitch/"+pin,pin).ok,"Eye pin requires the mounted complete actuator")
	game.model.transfer(game.model.items[pin].kind,"pocket","bin")
	# All 90 remaining pieces are collected and fitted via real input/rays.
	for page_index in range(13):
		if not await complete_page("pitch",page_index):await conclude();return
		expect(game.model.integrity_errors().is_empty(),"Identity and dependency integrity after actuator page %d"%(page_index+1))
		var geometry_correct = true
		for visual in game.bodies.pitch.get_children():
			if not visual.has_meta("component_uid"):continue
			var item: Dictionary = game.model.items[visual.get_meta("component_uid")]
			if not visual.global_transform.is_equal_approx(game.components.slot_pose("pitch",item.slot)):
				expect(false,"Installed component follows its authored source pose")
			var source_id: String = game.model.slot_definition("pitch",item.slot).pose_source
			var expected: Transform3D = game.bodies.pitch.global_transform*game.source["FA-510__001"].transform.affine_inverse()*game.source[source_id].transform
			if not matches_source_geometry(visual,expected,source_id):geometry_correct = false
		expect(geometry_correct,"Installed geometry matches source orientation after actuator page %d"%(page_index+1))
		if page_index == 0:
			await aim(game.stations.prep3.global_position)
			game._rotate_station(Vector2(65,40))
			await frames(15)
			expect(game.bodies.pitch.global_transform.is_equal_approx(game.stations.prep3.global_transform),"Actuator follows preparation-station rotation after physics settles")
			game.reset_station("prep3")
			await frames(15)
		if page_index==3:
			game.hud.open_manual("pad_2")
			expect(game.builds.pad_2.installed("sleeve")==0,"Actuator progress leaves both pad branches untouched")
			game.hud.open_manual("pitch")
	expect(game.model.milestone("pitch","prepared") and installed_count==90,"Complete 91-piece actuator includes its original barrel")
	game.hud.open_manual("pitch",13)
	await review_checkpoint("pitch","ready")
	await aim(game.bodies.pitch.global_position)
	key(KEY_E)
	await frames(40)
	expect(game.held_build()=="pitch","Completed actuator uses the shared assisted assembly grip")
	expect(not game.model.placement_error("foot","pitch","pitch").is_empty(),"Actuator mounting requires both secured clevises")
	await aim(game.stations.prep3.global_position)
	await frames(40)
	game._update_target()
	click()
	expect(game.builds.pitch.pad_location=="prep","Actuator can return to a preparation station")
	for page_index in [3,4]:
		if not await complete_page("foot",page_index):await conclude();return
	game.hud.open_manual("foot",5)
	await aim(game.bodies.pitch.global_position)
	key(KEY_E)
	await aim(Vector3(-6.4,1.5,1.8))
	await frames(100)
	await aim(game.mount_point("pitch"),2.0)
	await frames(100)
	game._update_target()
	game._update_ghost()
	expect(game.target.get("mount","")=="pitch" and game.ghost.visible,"Completed actuator previews at its receiving connections")
	var complete_preview = game.ghost.get_child_count()==90
	for visual in game.ghost.get_children():
		var uid: String = visual.get_meta("component_uid")
		var sid: String = game.model.items[uid].slot
		var source_id: String = game.model.slot_definition("pitch",sid).pose_source
		var expected: Transform3D = game.ghost.global_transform*game.source["FA-510__001"].transform.affine_inverse()*game.source[source_id].transform
		complete_preview = complete_preview and matches_source_geometry(visual,expected,source_id)
	expect(complete_preview,"Mount preview includes all 90 fitted pieces at their source-relative poses")
	await review_checkpoint("foot","mount-preview","pitch")
	click()
	expect(game.model.assemblies.foot.slots.pitch=="pitch","Mount the physical actuator once at both clevises")
	if game.model.assemblies.foot.slots.pitch.is_empty():print("MOUNT_DIAGNOSTIC ",game.hud.toast_label.text);await conclude();return
	key(KEY_ENTER)
	key(KEY_Z)
	expect(game.model.milestone("pitch","prepared"),"Mounted child internals are locked against undo")
	if not await complete_page("foot",5):await conclude();return
	expect(game.model.milestone("foot","pitch_secured"),"Both eye pins, keepers, washers and screws secure the actuator")
	await aim(game.foot.global_position,2.5)
	game._rotate_station(Vector2(75,55))
	await frames(15)
	var mounted_pose: Transform3D = game.foot.global_transform*Transform3D(Basis.IDENTITY,-game.FOOT_CENTER)*game.source["FA-510__001"].transform
	expect(game.bodies.pitch.global_transform.is_equal_approx(mounted_pose),"Mounted actuator follows foot rotation after physics settles")
	game.reset_station("foot")
	await frames(15)
	await review_checkpoint("foot","mounted")
	expect(not game.model.milestone("foot","complete"),"Pitch completion does not complete the untouched pad branches")
	expect(game.model.items.values().filter(func(i):return i.location=="installed").size()==111,"109 pitch pieces plus the two pad roots installed exactly once")
	game.hud.open_manual("foot",0)
	expect(game.hud.page_body.text.contains("Pitch actuator: secured"),"Parent overview reports actuator preparation and installation")
	# Parent undo removes eight retention pieces, then returns the intact child.
	for i in range(9):key(KEY_Z)
	expect(game.builds.pitch.pad_location=="prep" and game.model.milestone("pitch","prepared"),"Nested undo preserves all 91 child parts at a free station")
	expect(game.model.assemblies.foot.slots["pitch/FA-220__001"]!="","Undoing the child mount retains its clevises")
	game.hud.open_manual("pitch")
	key(KEY_Z)
	expect(not game.builds.pitch.prepared(),"Detached child can resume editing in its own manual")
	expect(game.model.integrity_errors().is_empty(),"Final source ownership and dependencies remain valid")
	await conclude()

func conclude() -> void:
	var passed = checks.all(func(c):return c.passed)
	FileAccess.open("res://verification/pitch-build-audit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"rendered":rendered},"  "))
	print("PITCH_BUILD_AUDIT ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	await finish(passed)
