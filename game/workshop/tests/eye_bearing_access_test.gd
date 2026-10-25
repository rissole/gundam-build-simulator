extends "res://tests/kit/harness.gd"
## The base-eye bearing seats inside a housing whose collision is a solid box.
## A standing look at preparation C must still offer that placement.
func _initialize() -> void:call_deferred("run")

func install_before(game: Node, stop: String) -> void:
	var recipe: Dictionary = game.runtime.definition("pitch")
	for _pass in recipe.slots.size():
		var changed = false
		for sid in recipe.slots:
			if sid == stop or not game.model.assemblies.pitch.slots[sid].is_empty():continue
			var spec: Dictionary = game.model.slot_definition("pitch",sid)
			if spec.has("assembly"):continue
			if not spec.get("requires",[]).all(func(id):return not game.model.assemblies.pitch.slots[id].is_empty()):continue
			var uid: String = spec.pose_source
			var item: Dictionary = game.model.items[uid]
			if game.model.definitions.parts[item.kind].carry_class == "pocket":game.model.transfer(item.kind,"bin","pocket",uid)
			else:game.model.carry_item(uid)
			var result: Dictionary = game.model.install("pitch",sid,uid)
			expect(result.ok,"Install "+sid+" before "+stop)
			changed = result.ok
		if not changed:break
	game.automation.sync_visuals("pitch")

func look_from(game: Node, point: Vector3, stand: Vector3) -> Dictionary:
	game.automation.place_player(Vector3(stand.x,0.1,stand.z))
	game.automation.look_at_point(point)
	await frames(2)
	return game.automation.refresh_target()

func expect_bearing(game: Node, sid: String, stand: Vector3, label: String) -> void:
	var point: Vector3 = game.components.slot_point("pitch",sid)
	var target: Dictionary = await look_from(game,point,stand)
	var visible: bool = game.targeting.can_see(point,game.components.receiving_bodies("pitch",sid),game.components.service_access("pitch",sid),game.components.sight_depth("pitch",sid))
	expect(visible and target.get("type","")=="component" and target.get("sid","")==sid and game.ghost.visible,label)

func run() -> void:
	var game = instantiate_workshop(self)
	await frames(8)
	game.set_paused(false)
	expect(game.automation.suspend_at_station("pitch","prep3").is_empty(),"Pitch actuator rests at preparation C")
	install_before(game,"FA-526__001")
	expect(game.model.milestone("pitch","enclosed") and not game.components.service_access("pitch","FA-526__001"),"Closed housing ends open-station access before the eye bearing")
	expect(game.model.carry_item("FA-526__001").is_empty(),"Carry the spherical eye bearing")
	var point: Vector3 = game.components.slot_point("pitch","FA-526__001")
	var pose: Transform3D = game.components.slot_pose("pitch","FA-526__001")
	await expect_bearing(game,"FA-526__001",point+Vector3(0.9,0.35,0.55),"Standing view from the open side of preparation C previews the base eye bearing")
	await expect_bearing(game,"FA-526__001",point+pose.basis.x*0.9+Vector3(0,0.2,0.15),"Looking into one bore opening previews the base eye bearing")
	await expect_bearing(game,"FA-526__001",point-pose.basis.x*0.9+Vector3(0,0.2,0.15),"Looking into the other bore opening previews the base eye bearing")
	var barrel: Vector3 = point+pose.basis.y*1.2
	await look_from(game,point,Vector3(barrel.x,barrel.y-1.63,barrel.z))
	var through_barrel: bool = game.targeting.can_see(point,game.components.receiving_bodies("pitch","FA-526__001"),false,game.components.sight_depth("pitch","FA-526__001"))
	expect(not through_barrel and not game.ghost.visible,"A look along the closed barrel does not reveal the eye bearing")
	game.stations.prep3.rotate_y(PI/2)
	await frames(2)
	point = game.components.slot_point("pitch","FA-526__001")
	await expect_bearing(game,"FA-526__001",point+Vector3(0.15,0.35,0.9),"Rotated preparation station keeps the base eye bearing preview")
	game.model.release_item("bin")
	install_before(game,"FA-526__002")
	expect(game.model.carry_item("FA-526__002").is_empty(),"Carry the second spherical eye bearing")
	var rod: Vector3 = game.components.slot_point("pitch","FA-526__002")
	var rod_pose: Transform3D = game.components.slot_pose("pitch","FA-526__002")
	await expect_bearing(game,"FA-526__002",rod+rod_pose.basis.x*0.9+Vector3(0,0.2,0.15),"Rod eye bearing previews after its housing is fitted")
	var passed = checks.all(func(c):return c.passed)
	print("EYE_BEARING_ACCESS ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free()
	quit(0 if passed else 1)
