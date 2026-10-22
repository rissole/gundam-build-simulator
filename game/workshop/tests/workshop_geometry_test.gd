extends SceneTree
## Audit the generated workshop itself, not a hand-maintained list of bad joints.
## Imported robot/source parts have their separate interface/assembly audits.
const Audit = preload("res://tests/geometry_surface_audit.gd")
var game: Node
var checks: Array[Dictionary] = []
var poses: Array[Dictionary] = []

func _initialize() -> void:
	run.call_deferred()

func expect(ok: bool, description: String) -> void:
	checks.append({"check":description,"passed":ok})
	print("CHECK ","PASS " if ok else "FAIL ",description)
	if not ok:push_error(description)

func collect(node: Node, meshes: Array[MeshInstance3D]) -> void:
	# Dynamic mesh resources cover every procedural box, cylinder and the ramp,
	# including newly added scenery. Source GLB subresources have resource paths.
	if node is MeshInstance3D and node.mesh != null and node.is_visible_in_tree() and (node.mesh is PrimitiveMesh or node.mesh.resource_path.is_empty()):
		meshes.append(node)
	for child in node.get_children():collect(child,meshes)

func audit_pose(id: String, meshes: Array[MeshInstance3D], pose: Transform3D) -> void:
	game.foot_fixture._apply_pose(pose)
	var findings: Array[Dictionary] = Audit.inspect(meshes)
	poses.append({"pose":id,"transform":str(pose),"mesh_count":meshes.size(),"findings":findings})
	expect(findings.is_empty(),id+": no overlapping same-facing surfaces (%d findings)" % findings.size())

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate()
	root.add_child(game)
	game.automated_test = true
	game.set_physics_process(false)
	game.set_process(false)
	var meshes: Array[MeshInstance3D] = []
	collect(game,meshes)
	var fixture: Node3D = game.foot_fixture
	expect(meshes.any(func(mesh):return fixture.carriage.is_ancestor_of(mesh)) and meshes.any(func(mesh):return fixture.rotator.is_ancestor_of(mesh)),"The live carrier and rotating clamps are included")
	expect(meshes.has(fixture.get_node("AccessPlatform/AccessRamp")) and meshes.any(func(mesh):return mesh.get_parent() == game),"The generated ramp and surrounding workshop scenery are included")
	# Sampling intermediate poses catches joints that only become coplanar during
	# operation. This is a geometry audit, not a substitute for movement tests.
	for degrees in range(-90,91,15):
		audit_pose("rotation_%+03d" % degrees,meshes,Transform3D(Basis(Vector3.BACK,deg_to_rad(degrees)),SupportedFootFixture.WORK_ORIGIN))
	for fraction in [0.25,0.5,0.75,1.0]:
		audit_pose("transfer_%03d" % roundi(fraction*100),meshes,Transform3D(Basis.IDENTITY,SupportedFootFixture.WORK_ORIGIN.lerp(SupportedFootFixture.DISPATCH_ORIGIN,fraction)))
	fixture._apply_pose(Transform3D(Basis.IDENTITY,SupportedFootFixture.WORK_ORIGIN))
	# Prove the real-scene collector and gate reject a newly introduced duplicate
	# on the lower harness, rather than merely passing today's authored dimensions.
	var original: MeshInstance3D
	for mesh in meshes:
		if mesh.get_parent() == fixture.carriage and mesh.global_position.y < 0.3:
			original = mesh
			break
	expect(original != null,"A lower harness surface is available for the regression mutation")
	if original != null:
		var duplicate = MeshInstance3D.new()
		duplicate.name = "InjectedCoplanarSurface"
		duplicate.mesh = original.mesh
		fixture.carriage.add_child(duplicate)
		duplicate.transform = original.transform
		var mutated: Array[MeshInstance3D] = []
		collect(game,mutated)
		var defects: Array[Dictionary] = Audit.inspect(mutated)
		expect(defects.any(func(defect):return defect.path_a.contains("InjectedCoplanarSurface") or defect.path_b.contains("InjectedCoplanarSurface")),"A new overlapping harness surface automatically fails the scene audit")
		duplicate.free()
	var passed: bool = checks.all(func(check):return check.passed)
	var path = "res://verification/workshop-geometry-%s-%s.json" % [Time.get_datetime_string_from_system().replace(":","-"),Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute("res://verification")
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"rendered":false,"checks":checks,"poses":poses,"plane_tolerance_m":0.00025,"minimum_overlap_m2":0.000001,"scope":"Visible generated workshop meshes; imported source meshes are separate assembly audit scope.","engine":Engine.get_version_info().string},"  "))
	print("GEOMETRY_REPORT ",ProjectSettings.globalize_path(path))
	print("WORKSHOP_GEOMETRY ","PASS" if passed else "FAIL"," ",checks.size()," checks; ",meshes.size()," meshes; ",poses.size()," poses")
	game.chime.stop()
	game.chime.stream = null
	quit(0 if passed else 1)
