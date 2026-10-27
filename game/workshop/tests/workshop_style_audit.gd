extends "res://tests/kit/harness.gd"
## Workshop surfaces only: robot source resources are explicitly excluded.
## Sample render poses directly; this is not walked or mechanical acceptance.
const Audit = preload("res://tests/geometry_surface_audit.gd")
var game: Node
var source_meshes: Dictionary = {}
var poses: Array[Dictionary] = []
func _initialize() -> void:run.call_deferred()
func collect(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.mesh != null and node.is_visible_in_tree() and not source_meshes.has(node.mesh) and (node.mesh is PrimitiveMesh or node.mesh.resource_path.is_empty()):meshes.append(node)
	for child in node.get_children():collect(child,meshes)
func inspect_pose(label: String) -> void:
	var meshes: Array[MeshInstance3D] = []
	collect(game,meshes)
	var findings = Audit.inspect(meshes)
	poses.append({"pose":label,"mesh_count":meshes.size(),"findings":findings})
	expect(findings.is_empty(),label+": no coplanar workshop overlaps (%d meshes, %d findings)" % [meshes.size(),findings.size()])
	for finding in findings:print(finding.path_a," <> ",finding.path_b," normal ",finding.normal_a," area ",finding.total_overlap_area)
func run() -> void:
	game = await boot_workshop("pelvis")
	game.set_physics_process(false);game.set_process(false)
	for record in game.source.values():source_meshes[record.mesh] = true
	inspect_pose("initial")
	var blockout = game.leg_layout.blockout
	var access = game.equipment.get_equipment("workshop_access")
	for p in [.125,.25,.5,.75,1.0]:
		var values = {}
		for key in access.channels:values[key] = p
		blockout.apply_frames(access.frames_at(values))
		inspect_pose("access_%s" % p)
	access._pose()
	# Fixture inserts and their sliding clamps, including inactive templates.
	for template in ["pelvis","chest","core","backpack"]:
		for id in ["pelvis","chest","core","backpack"]:blockout.enable_group("bulky_insert_"+id,id==template)
		inspect_pose("fixture_"+template)
	for id in ["pelvis","chest","core","backpack"]:blockout.enable_group("bulky_insert_"+id,id=="pelvis")
	for p in [.25,.5,1.0]:
		for id in ["left_lift","right_lift"]:
			var lift = game.equipment.get_equipment(id)
			lift.height = lerpf(lift.stops[0],lift.stops[-1],p);lift.moving = true;lift._pose()
		var platform = game.equipment.get_equipment("mobile_platform")
		platform.height = lerpf(.15,2.4,p);platform.moving = true;platform._pose()
		var cradle = game.leg_layout.cradle
		var station_x: float = game.equipment.get_equipment("leg_rail").spec.station_x
		var frame = Transform3D(Basis(Vector3.RIGHT,PI/2*(1-p)),Vector3(station_x,1.85,9.4))
		cradle.apply_geometry(cradle.geometry(frame,station_x,14.5,p,p,p))
		inspect_pose("equipment_%s" % p)
	var meshes: Array[MeshInstance3D] = [];collect(game,meshes)
	var original = blockout.pieces.transverse_table.visual
	var duplicate = MeshInstance3D.new();duplicate.mesh = original.mesh;original.get_parent().add_child(duplicate);duplicate.transform = original.transform
	meshes.append(duplicate)
	expect(not Audit.inspect(meshes).is_empty(),"Injected duplicate floor insert is rejected")
	duplicate.free()
	var passed = checks.all(func(check):return check.passed)
	write_evidence("res://verification/style-surfaces.json",{"passed":passed,"checks":checks,"poses":poses,"scope":"Workshop generated meshes, excluding robot source resources; 0.25 mm plane tolerance."})
	print("WORKSHOP_STYLE ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	game.chime.stop();game.chime.stream = null
	quit(0 if passed else 1)
