extends "res://tests/kit/harness.gd"
## Geometry, identity and support invariants; no walking or targetability checks.
func _initialize() -> void:call_deferred("run")

func run() -> void:
	var game=await boot_workshop("pelvis")
	var reflection=Basis(Vector3.LEFT,Vector3.UP,Vector3.BACK)
	for uid in ["LG-100__001","LG-110__001","LG-120__001","LG-140__001","PV-200__001","FA-100__001","FA-525__001"]:
		var left: Dictionary=game.source[uid];var right: Dictionary=game.source["R-"+uid]
		var correct=true
		for surface in range(left.mesh.get_surface_count()):
			var a: PackedVector3Array=left.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			var b: PackedVector3Array=right.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			if a.size()!=b.size():correct=false;break
			for index in range(0,a.size(),7):
				if not (reflection*(left.transform*a[index])).is_equal_approx(right.transform*b[index]):correct=false;break
		expect(correct,uid+" mirrored world vertices preserve receiving geometry")
		expect(is_equal_approx(right.transform.basis.determinant(),1),uid+" retains a right-handed frame for interpolation")
	var left_foot: Dictionary=game.model.assemblies.foot
	var right_foot: Dictionary=game.model.assemblies.right_foot
	expect(left_foot.parent.is_empty() and right_foot.parent.is_empty() and left_foot.location!=right_foot.location,"two complete prepared feet occupy distinct physical source supports")
	for owner in ["foot","right_foot"]:
		var spec: Dictionary=game.leg_layout.layout().crane.tasks[owner]
		var frame: Transform3D=game.runtime.node(owner).global_transform
		for id in spec.magnetic_points:
			var point=frame*AssemblyRuntime.vec(spec.magnetic_points[id])
			expect(rail_surface_contact(game,owner,point),owner+" "+id+" lies on its actual structural rail surface")
	var rail=game.equipment.get_equipment("leg_rail")
	var carrier=game.equipment.get_equipment("foot_carrier")
	expect(not carrier.can_receive("right_foot"),"carrier cannot accept a foot while the other leg is selected")
	expect(rail.request("build").is_empty() and carrier.can_receive("right_foot"),"empty common holder can switch before any physical construction")
	expect(rail.request("build").is_empty(),"empty common holder returns to left build without moving a foot")
	var passing=checks.all(func(check):return check.passed)
	write_evidence("res://verification/mirrored-leg-content.json",{"scope":"physical geometry and support ownership","checks":checks})
	print("MIRRORED_LEG_CONTENT ","PASS " if passing else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passing else 1)

func rail_surface_contact(game: Node, owner: String, point: Vector3) -> bool:
	# The fixed frame's conservative collision box includes raised bosses. Test
	# source triangles here so an air-filled proxy cannot establish contact.
	for index in [1,2]:
		var uid=("R-" if owner=="right_foot" else "")+"FA-100__00"+str(index)
		var source: Dictionary=game.source[uid]
		var at: Transform3D=game.runtime.frame_transform(owner)*source.transform
		var from=at.affine_inverse()*(point+Vector3.UP*.009)
		var to=at.affine_inverse()*(point-Vector3.UP*.009)
		for surface in range(source.mesh.get_surface_count()):
			var arrays: Array=source.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			for face in range(0,indices.size(),3):
				if Geometry3D.segment_intersects_triangle(from,to,vertices[indices[face]],vertices[indices[face+1]],vertices[indices[face+2]])!=null:return true
	return false
