extends "res://tests/kit/harness.gd"
## Actual authored scenery, without robot imports, stage replay or rendering.
const Fixture = preload("res://tests/kit/equipment_fixture.gd")
const Blockout = preload("res://scripts/workshop_blockout.gd")
const Dressing = preload("res://scripts/gantry_dressing.gd")
const Audit = preload("res://tests/geometry_surface_audit.gd")
const Lift = preload("res://scripts/work_access_lift.gd")
const Platform = preload("res://scripts/mobile_work_platform.gd")
const Access = preload("res://scripts/workshop_access.gd")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var started := Time.get_ticks_msec()
	var game = Fixture.new()
	game.name = "SurfaceFixture"
	root.add_child(game)
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop-layout.json")).workshop
	var world = Blockout.new()
	world.name = "Blockout"
	game.add_child(world)
	world.setup(game, spec)
	var lifts: Array = []
	for side in spec.elevators:
		var data: Dictionary = spec.elevators[side]
		var lift = Lift.new()
		lift.name = side
		game.add_child(lift)
		var stops: Array[float] = []
		stops.assign(data.levels)
		lift.setup(game, side, AssemblyRuntime.vec(data.origin), Vector2(data.size[0], data.size[1]), stops, data)
		lifts.append(lift)
	var platform = Platform.new()
	platform.name = "MobilePlatform"
	game.add_child(platform)
	platform.setup(game, spec.mobile_platform)
	var access = Access.new()
	game.add_child(access)
	access.setup(game, world)
	Dressing.new().build(world, lifts)
	var meshes: Array[MeshInstance3D] = []
	collect(game, meshes)
	var poses: Array[Dictionary] = []
	poses.append(inspect_pose("parked", meshes))
	world.apply_frames(access.frames_at({"8.4": 1.0, "rear": 1.0, "20.6": 1.0}))
	for lift in lifts:
		lift.height = lift.stops[-1]
		lift._pose()
	platform.height = spec.mobile_platform.heights[-1]
	platform._pose()
	poses.append(inspect_pose("open_raised", meshes))
	# Prove an added duplicate of a real asset is found even while existing
	# defects keep the content assertions red. Use the same collection path.
	var original: MeshInstance3D = world.pieces.transverse_table.visual
	var duplicate := MeshInstance3D.new()
	duplicate.name = "InjectedDuplicate"
	duplicate.mesh = original.mesh
	original.get_parent().add_child(duplicate)
	duplicate.transform = original.transform
	var injected: Array[MeshInstance3D] = []
	collect(game, injected)
	expect(injected.has(duplicate), "Production mesh collection includes an injected duplicate")
	var detected := Audit.inspect([original, duplicate])
	expect(detected.size() == 1, "Duplicating the authored transverse table produces a coplanar finding")
	duplicate.free()
	var elapsed := Time.get_ticks_msec() - started
	expect(elapsed < 5000, "Two authored surface poses complete within 5 seconds (actual %d ms)" % elapsed)
	write_evidence("res://verification/workshop-surfaces.json", {"poses": poses, "elapsed_ms": elapsed,
		"scope": "Dressed authored blockout, lift cars and mobile platform at parked and open/raised poses; no robot meshes, hangar dressing, same-node overlaps or continuous motion."})
	print("WORKSHOP_SURFACES_PERFORMANCE %d ms" % elapsed)
	var passed = checks.all(func(check): return check.passed)
	print("WORKSHOP_SURFACES ", "PASS " if passed else "FAIL ", checks.size(), " checks")
	game.free()
	quit(0 if passed else 1)

func inspect_pose(label: String, meshes: Array[MeshInstance3D]) -> Dictionary:
	var findings := Audit.inspect(meshes)
	for finding in findings:
		print("COPLANAR ", label, " ", finding.path_a, " <> ", finding.path_b,
			" area=", finding.total_overlap_area, " normal=", finding.normal_a)
	expect(findings.is_empty(), "%s: authored workshop has no overlapping coplanar faces (%d meshes, %d findings)" % [label, meshes.size(), findings.size()])
	return {"pose": label, "mesh_count": meshes.size(), "findings": findings}

func collect(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.mesh != null and node.is_visible_in_tree():
		meshes.append(node)
	for child in node.get_children():
		collect(child, meshes)
