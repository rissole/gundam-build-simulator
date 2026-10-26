extends "res://tests/kit/harness.gd"
const Target = preload("res://scripts/rig_target.gd")
func _initialize():call_deferred("run")
func visual(parent: Node3D, uid: String, at: Vector3) -> MeshInstance3D:
	var mesh = MeshInstance3D.new();mesh.mesh = BoxMesh.new()
	mesh.set_meta("component_uid",uid);parent.add_child(mesh);mesh.position = at
	return mesh
func run():
	var model = AssemblyModel.new()
	var data = {"version":1,"parts":{"base":{"family":"base","carry_class":"two_hand"}},"assemblies":{"parent":{"slots":{"child":{"assembly":"leaf","milestone":"ready"}}},"leaf":{"slots":{"base":{"accepts":"base"}},"milestones":{"ready":["base"]}}}}
	var scenario = {"version":1,"parents":[{"id":"load","definition":"parent"},{"id":"child","definition":"leaf"},{"id":"other","definition":"leaf"}],"builds":[],"parts":[]}
	expect(model.configure(data,scenario).is_empty(),"isolated assembly model configures")
	# Supplied ownership tree, not a claim about completing a build.
	model.assemblies.load.slots.child = "child"
	model.assemblies.child.parent = "load"
	var runtime = AssemblyRuntime.new(model,{})
	var world = Node3D.new();root.add_child(world)
	var body = StaticBody3D.new();world.add_child(body)
	body.transform = Transform3D(Basis(Vector3.UP,.4),Vector3(3,2,1))
	runtime.register_node("load",body)
	var first = visual(body,"base",Vector3(1,0,0))
	first.layers = 0 # Production render batching hides originals by render layer.
	var shape = CollisionShape3D.new();shape.shape = BoxShape3D.new();body.add_child(shape)
	var nested = RigidBody3D.new();nested.freeze = true;body.add_child(nested)
	nested.transform = Transform3D(Basis(Vector3.RIGHT,.7),Vector3(0,2,0))
	runtime.register_node("child",nested)
	var second = visual(nested,"child_part",Vector3(0,0,1))
	var hidden = visual(body,"enclosed",Vector3.ZERO);hidden.hide()
	var proxy = MeshInstance3D.new();proxy.mesh = BoxMesh.new();proxy.set_meta("assembly_render_proxy",true);body.add_child(proxy)
	var decoration = MeshInstance3D.new();decoration.mesh = BoxMesh.new();decoration.set_meta("pickup_outline",true);first.add_child(decoration)
	var brace = visual(nested,"brace",Vector3(.5,1,0));brace.remove_meta("component_uid")
	var other = Node3D.new();world.add_child(other);runtime.register_node("other",other)
	visual(other,"other_part",Vector3.ZERO)
	var ghost = Target.new(runtime);world.add_child(ghost)
	expect(not ghost.visible,"idle helper starts hidden")
	var target = Transform3D(Basis.from_euler(Vector3(.2,.8,.3)),Vector3(-2,5,9))
	ghost.show_target("load",target)
	expect(ghost.visible and ghost.get_child_count()==3,"copy contains visible meshes including mounted child and captive hardware, without proxies or outlines")
	var copy = ghost.get_child(0);var child_copy = ghost.get_child(1)
	expect(copy.mesh==first.mesh and child_copy.mesh==second.mesh,"mesh resources are shared rather than duplicated")
	expect(copy.global_transform.is_equal_approx(target*body.global_transform.affine_inverse()*first.global_transform),"root component uses target assembly frame")
	expect(child_copy.global_transform.is_equal_approx(target*body.global_transform.affine_inverse()*second.global_transform),"nested component retains its full source pose")
	expect(copy.layers!=0,"render-batched originals still produce a visible ghost")
	expect(ghost.get_children().all(func(n):return n is MeshInstance3D and n.get_child_count()==0 and n.get_meta_list().is_empty() and n.get_script()==null),"copies contain no physics, scripts, assembly IDs or targeting metadata")
	expect(copy.material_override.shader==Target.GLOW and copy.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"ghost reuses pulse shader and casts no shadow")
	expect(copy.material_override.get_shader_parameter("bright_alpha")<1,"ghost material is translucent")
	var id = copy.get_instance_id()
	var next = Transform3D(Basis(Vector3.UP,-1),Vector3(5,6,7))
	ghost.show_target("load",next)
	expect(ghost.get_child(0).get_instance_id()==id and ghost.global_transform.is_equal_approx(next),"changing target moves existing copy without rebuilding")
	ghost.clear();expect(not ghost.visible and ghost.get_child_count()==3,"idle hides and retains cached copy")
	ghost.show_target("load",target)
	expect(ghost.get_child(0).get_instance_id()==id,"resume reuses copy")
	model.changed.emit();expect(not ghost.visible,"model change hides stale preview")
	hidden.show();ghost.show_target("load",target)
	expect(ghost.get_child_count()==4 and ghost.get_child(0).get_instance_id()!=id,"model invalidation rebuilds changed payload once")
	ghost.show_target("other",next)
	expect(ghost.get_child_count()==1 and ghost.assembly_id=="other","switching assembly replaces bounded cache")
	ghost.show_target("missing",target);expect(not ghost.visible,"missing assembly hides preview")
	var axes = [{"label":"INDEX","delta":.32,"tolerance":.03},{"label":"RISE","delta":-.41,"tolerance":.02,"unit":" m"}]
	var readout = Target.axis_readout(axes)
	expect(readout.text=="INDEX +0.32  RISE -0.41 m" and not readout.all_in_tolerance,"panel text preserves signed axis errors and units")
	axes[0].delta = -.03;axes[1].delta = 0.0;readout = Target.axis_readout(axes)
	expect(readout.all_in_tolerance and readout.rows.all(func(row):return row.color==Target.READY_COLOR),"inclusive tolerance makes each matching axis green")
	axes[1].delta = .021;readout = Target.axis_readout(axes)
	expect(not readout.all_in_tolerance and readout.rows[0].in_tolerance and not readout.rows[1].in_tolerance,"per-axis status remains independent outside tolerance")
	expect(not Target.axis_readout([]).all_in_tolerance,"empty axes cannot authorize seat")
	for bad in [NAN,INF,-INF]:
		axes[1].delta = bad
		expect(not Target.axis_readout(axes).all_in_tolerance,"non-finite delta cannot authorize seat")
	axes[1].delta = 0;axes[1].tolerance = -1
	expect(not Target.axis_readout(axes).all_in_tolerance,"negative tolerance cannot authorize seat")
	var passed = checks.all(func(c):return c.passed)
	print("RIG_TARGET ","PASS " if passed else "FAIL ",checks.size()," checks")
	world.free();quit(0 if passed else 1)
