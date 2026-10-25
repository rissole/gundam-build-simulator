extends "res://tests/kit/harness.gd"
## Opt-in, isolated rendering contract. No workshop boot, journeys or screenshots.
const Groups = preload("res://scripts/assembly_render_group.gd")
const Mirror = preload("res://scripts/mirrored_sources.gd")
func _initialize() -> void:call_deferred("run")

func settle(group: Node) -> void:
	var deadline := Time.get_ticks_msec()+5000
	while group.busy() and Time.get_ticks_msec()<deadline:
		await create_timer(0.005).timeout
	expect(not group.busy(),"bounded render work completes")

func proxies(body: Node3D) -> Array:
	return body.get_children().filter(func(node):return node is MeshInstance3D and node.has_meta(Groups.PROXY_META) and node.visible)

func vertices(mesh: Mesh) -> int:
	var total := 0
	for surface in mesh.get_surface_count():total += mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size()
	return total

func run() -> void:
	var body := Node3D.new();root.add_child(body)
	var material := StandardMaterial3D.new()
	var shape := BoxMesh.new();shape.size = Vector3(.1,.2,.3);shape.material = material
	var pieces: Array[MeshInstance3D] = []
	for i in 4:
		var piece := MeshInstance3D.new();piece.mesh=shape
		if i==3:
			piece.mesh=shape.duplicate();piece.mesh.material=StandardMaterial3D.new()
			piece.mesh.material.albedo_color=Color.RED
		piece.position=Vector3(.1+i*.15,.2,.2);piece.rotation.y=i*.13
		piece.set_meta("component_uid","physical-"+str(i));piece.set_meta("slot_id",str(i))
		body.add_child(piece);pieces.append(piece)
	var separate := MeshInstance3D.new();separate.mesh=shape;body.add_child(separate)
	var group := Groups.new();group.setup(body,[separate])
	await settle(group)
	expect(proxies(body).size()==1,"four installed pieces share one local material batch")
	expect(pieces.all(func(piece):return piece.layers==0 and piece.visible) and separate.layers==1,"root stays separate; physical source visibility is retained")
	var proxy: MeshInstance3D=proxies(body)[0]
	expect(vertices(proxy.mesh)==4*vertices(shape),"near geometry retains every source vertex")
	var expected := AABB()
	for i in pieces.size():
		var box: AABB=pieces[i].transform*shape.get_aabb()
		expected=box if i==0 else expected.merge(box)
	expect(proxy.mesh.get_aabb().position.is_equal_approx(expected.position) and proxy.mesh.get_aabb().size.is_equal_approx(expected.size),"combined bounds retain authored oriented geometry")
	expect(proxy.mesh.shadow_mesh != null,"batch retains a separate shadow representation")
	expect(proxy.mesh.get_surface_count()==proxy.mesh.shadow_mesh.get_surface_count(),"batch shadow surfaces correspond one-for-one")
	# Dummy rendering gives all materials the same RID, so native merging can
	# collapse them. Explicit surfaces exercise the real multi-material contract.
	var multi=ImporterMesh.new()
	multi.add_surface(Mesh.PRIMITIVE_TRIANGLES,shape.surface_get_arrays(0),[],{},material)
	multi.add_surface(Mesh.PRIMITIVE_TRIANGLES,shape.surface_get_arrays(0),[],{},pieces[3].mesh.material)
	expect(Mirror.shadow_from_importer(multi).get_surface_count()==2,"distinct shadow surfaces survive without material-based merging")
	body.transform=Transform3D(Basis(Vector3.UP,.7),Vector3(2,3,4))
	expect(proxy.global_transform.is_equal_approx(body.global_transform),"batch follows its rigid frame through rotation and transport")
	var same: Mesh=proxy.mesh;group.refresh();await settle(group)
	expect(proxies(body)[0].mesh==same,"unchanged state reuses its render representation")
	pieces[0].hide();group.refresh()
	expect(proxies(body).is_empty() and pieces[1].layers==1,"closure invalidates the old batch immediately, with original fallback")
	await settle(group)
	expect(vertices(proxies(body)[0].mesh)==3*vertices(shape),"enclosed pieces are absent from the submitted batch")
	pieces[0].show();group.refresh();await settle(group)
	expect(vertices(proxies(body)[0].mesh)==4*vertices(shape),"undoing closure restores detailed internal geometry")
	var identity: String=pieces[3].get_meta("component_uid")
	body.remove_child(pieces[3]);root.add_child(pieces[3]);group.refresh()
	await settle(group)
	expect(pieces[3].layers==1 and pieces[3].get_meta("component_uid")==identity,"detached physical piece is restored with its identity")
	# Invalidate while CPU work is queued; a stale result must never restore a
	# removed piece or cover an incomplete assembly with the old complete batch.
	pieces[0].hide();group.refresh();await process_frame
	pieces[0].show();group.refresh();await settle(group)
	expect(vertices(proxies(body)[0].mesh)==3*vertices(shape),"latest partial state wins over in-flight work")
	var outline=preload("res://scripts/interaction_outline.gd").new();root.add_child(outline);outline.focus(body)
	expect(outline.copies.size()==4,"outlines use physical pieces and exclude duplicate render proxies")
	outline.free()
	# Exercise real imported LODs/shadow topology without booting the workshop.
	var scene=load("res://assets/foot-fa01.glb").instantiate()
	var source: Mesh=scene.get_child(0).mesh
	var mirrored: ArrayMesh=Mirror.reflect_mesh(source)
	var original_lods=ImporterMesh.from_mesh(source);var reflected_lods=ImporterMesh.from_mesh(mirrored)
	expect(mirrored.shadow_mesh!=null and vertices(mirrored)==vertices(source),"mirror preserves detailed geometry and optimized shadow mesh")
	var lods_ok := original_lods.get_surface_lod_count(0)>0
	for surface in original_lods.get_surface_count():
		lods_ok=lods_ok and original_lods.get_surface_lod_count(surface)==reflected_lods.get_surface_lod_count(surface)
		for level in original_lods.get_surface_lod_count(surface):
			lods_ok=lods_ok and original_lods.get_surface_lod_size(surface,level)==reflected_lods.get_surface_lod_size(surface,level)
			lods_ok=lods_ok and Mirror.reverse_faces(original_lods.get_surface_lod_indices(surface,level))==reflected_lods.get_surface_lod_indices(surface,level)
	expect(lods_ok,"mirror retains each LOD threshold and correctly reverses its triangles")
	scene.free();body.free();pieces[3].free()
	print("FOOT_RENDER ","PASS " if checks.all(func(c):return c.passed) else "FAIL ",checks.size()," checks")
	quit(0 if checks.all(func(c):return c.passed) else 1)
