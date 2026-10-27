extends "res://tests/kit/harness.gd"
## Small docking/render lifecycle fixture; no workshop journey or asset imports.
const Groups = preload("res://scripts/assembly_render_group.gd")

func _initialize() -> void:call_deferred("run")

func settle(group: Node) -> void:
	var deadline := Time.get_ticks_msec()+3000
	while group.busy() and Time.get_ticks_msec()<deadline:
		await create_timer(0.005).timeout
	expect(not group.busy(),"bounded batches finish after reparenting")

func run() -> void:
	var dock := Node3D.new();root.add_child(dock)
	var body := Node3D.new();root.add_child(body)
	var shape := BoxMesh.new();shape.size=Vector3(.1,.1,.1)
	var pieces: Array[MeshInstance3D] = []
	for i in 4:
		var piece := MeshInstance3D.new();piece.mesh=shape
		piece.position=Vector3(.1+i*.15,.2,.2)
		piece.layers=5;piece.set_meta("component_uid",str(i))
		body.add_child(piece);pieces.append(piece)
	var outline := MeshInstance3D.new();outline.mesh=shape
	pieces[0].add_child(outline)
	var group := Groups.new();group.setup(body)
	# Start CPU work without allowing the main thread to consume its result.
	group._process(0)
	var task: int=group.task
	var work: Dictionary=group.job
	expect(task>=0,"fixture starts a real pending mesh compilation")
	body.reparent(dock)
	expect(group.task==task and group.job==work,"docking retains the worker task instead of joining/discarding it")
	await settle(group)
	expect(group.groups.size()==1,"pending batch survives docking")
	if group.groups.size()!=1:
		dock.free();finish();return
	var proxy: MeshInstance3D=group.groups.values()[0].proxy
	expect(is_instance_valid(proxy),"docked assembly receives its completed batch")
	if not is_instance_valid(proxy):
		dock.free();finish();return
	expect(pieces.all(func(p):return p.layers==0 and p.visible),"batching preserves original node visibility")
	expect(outline.is_visible_in_tree(),"child outlines remain visible on batched originals")
	var pose := body.global_transform
	body.reparent(root);group.refresh()
	expect(group.groups.values()[0].proxy==proxy and not group.busy(),"undocking reuses the same batch without recompiling")
	expect(body.global_transform.is_equal_approx(pose),"undocking preserves the assembly pose")
	dock.rotation=Vector3(.2,.4,.1);body.reparent(dock)
	dock.rotate_y(.3)
	expect(proxy.global_transform.is_equal_approx(body.global_transform),"retained batch follows subsequent parent rotation")
	pieces[0].hide();group.refresh()
	expect(pieces.all(func(p):return p.layers==5),"batch invalidation restores each source render mask")
	expect(not pieces[0].visible and not outline.is_visible_in_tree(),"enclosure visibility still controls source and outline")
	await settle(group)
	pieces[0].show();group.refresh();group._process(0)
	# A new refresh during CPU work must still reject the superseded result.
	pieces[1].hide();group.refresh()
	await settle(group)
	expect(pieces[0].layers==0 and pieces[1].layers==5,"latest enclosure state wins over an in-flight batch")
	expect(pieces[0].mesh==shape and pieces[0].get_meta("component_uid")=="0","source mesh and physical identity survive batching")
	# Freeing just the render controller must restore the surviving originals.
	pieces[1].show();group.refresh();group._process(0)
	group.free()
	expect(pieces.all(func(p):return p.layers==5),"final destruction joins CPU work and restores surviving sources")
	dock.free()
	await process_frame
	finish()

func finish() -> void:
	print("ASSEMBLY_RENDER_LIFECYCLE ","PASS " if checks.all(func(c):return c.passed) else "FAIL ",checks.size()," checks")
	quit(0 if checks.all(func(c):return c.passed) else 1)
