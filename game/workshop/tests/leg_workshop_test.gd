extends SceneTree
## Real-scene layout, normal character access and integration smoke checks.
var game: Node3D
var checks: Array[Dictionary] = []

func _initialize() -> void:
	run.call_deferred()

func expect(ok: bool, description: String) -> void:
	checks.append({"passed":ok,"check":description})
	print("CHECK ","PASS " if ok else "FAIL ",description)
	if not ok:push_error(description)

func frames(count: int) -> void:
	for tick in range(count):await physics_frame

func walk_to(destination: Vector3, maximum_frames: int) -> bool:
	var horizontal: Vector3 = destination-game.player.global_position
	horizontal.y = 0
	game.player.basis = Basis.looking_at(horizontal.normalized())
	game.scripted_controls[KEY_W] = true
	for tick in range(maximum_frames):
		await physics_frame
		var distance: Vector3 = destination-game.player.global_position
		distance.y = 0
		if distance.length() < 0.25:
			game.scripted_controls[KEY_W] = false
			await frames(12)
			return true
	game.scripted_controls[KEY_W] = false
	return false

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate()
	game.leg_workshop = true
	root.add_child(game)
	game.automated_test = true
	game.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await frames(6)
	expect(game.started and game.leg_layout != null and game.leg_equipment != null,"The expanded workshop creates the complete equipment integration")
	expect(game.foot_fixture != null and game.stations.size() == 3,"The accepted foot support and three small preparation stations remain available")
	expect(game.model.assemblies.foot.location == "support:foot_carrier" and game.model.assemblies.left_leg.location == "support:leg_fixture","Large workpieces start at explicitly named supports")
	expect(game.assembly_node("pelvis").global_position.is_equal_approx(LegWorkshopLayout.PELVIS_ORIGIN),"The pelvis is mounted at its selected 10.6 m installation datum")
	expect(game.assembly_node("left_leg").global_position.is_equal_approx(LegWorkshopLayout.LEG_ORIGIN),"The leg fixture uses the shared ground/ankle reference")
	expect(game.access_lifts.size() == 3 and game.access_lifts.leg.stops[-1] >= 8.7 and game.access_lifts.hip.stops[-1] >= 8.4,"Both sides of the knee and the final hip provide physical access lifts")
	expect(game.model.integrity_errors().is_empty(),"All initial stock and support ownership is valid")
	expect(game.source.has("FA-605__001") and game.source.has("LG-120__001"),"Existing foot sources and new structural sources coexist")
	var roof: MeshInstance3D = game.leg_layout.get_node("Roof")
	expect(is_equal_approx(roof.position.y-roof.mesh.get_aabb().size.y/2.0,22.0),"The blockout provides 22 m of clear hangar height")
	var seated: Vector3 = LegWorkshopLayout.seated_origin()
	var approach: Vector3 = LegWorkshopLayout.approach_origin()
	expect(is_equal_approx(seated.y+9.2,10.6) and approach.y >= 0.5 and approach.y+9.2+0.45 < 10.6-0.35,"The approach clears both the floor and the underside of the socket housing")
	expect(game.bins.keys().any(func(kind):return kind.begins_with("lg-")) and game.bins.keys().any(func(kind):return kind.begins_with("pv-")),"Leg and pelvis have labelled local hardware stock")
	for kind in game.storage.drawer_kinds:
		if kind.begins_with("lg-"):expect(game.bins[kind].global_position.z > 10,"Leg drawer is local to the leg assembly area: "+kind)
		elif kind.begins_with("pv-"):expect(game.bins[kind].global_position.z > 30,"Hip drawer is local to the final bay: "+kind)
	# Cross the former front wall using actual character collision and controls.
	game.player.global_position = Vector3(7.6,0.03,8.8)
	game.player.velocity = Vector3.ZERO
	await frames(8)
	expect(await walk_to(Vector3(7.6,0,23.4),410),"Ordinary walking connects the component workshop to the final bay through the enlarged hangar")
	expect(await walk_to(Vector3(13.0,0,23.4),160),"The final bay has a continuous cross-aisle in front of the gantry")
	expect(game.player.is_on_floor() and game.player.global_position.y < 0.10,"The entire route remains on the actual hangar floor")
	# Reach and occlusion remain constraints on machinery, even with large loads.
	var controls: Array = game.leg_equipment.controls()
	expect(not controls.is_empty(),"The new workflow has physical equipment controls")
	if not controls.is_empty():
		var entry: Dictionary = controls[0]
		game.target = entry
		var old_position: Vector3 = game.player.global_position
		game.player.global_position = entry.point+Vector3(0,0,4)
		expect(game._access([]).contains("reach"),"Equipment does not grant remote control beyond normal interaction reach")
		game.player.global_position = old_position
	game.chime.stop()
	game.chime.stream = null
	var passed = checks.all(func(check):return check.passed)
	print("LEG_WORKSHOP ","PASS " if passed else "FAIL ",checks.size()," checks")
	quit(0 if passed else 1)
