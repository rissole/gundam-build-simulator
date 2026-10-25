extends RefCounted
## What a workshop reload must reproduce: the normalised model, every saved
## machine's state, and the pose of every placed (non-loose) assembly body.
const Save = preload("res://scripts/workshop_save.gd")

static func state(game: Node) -> Dictionary:
	var poses = {}
	for id in game.runtime.nodes:
		var a: Dictionary = game.model.assemblies.get(id,{})
		# Loose builds reset to their home pose and settle under physics.
		if a.is_empty() or (a.parent.is_empty() and a.location == "loose"):continue
		var node: Node3D = game.runtime.node(id)
		if is_instance_valid(node):poses[id] = node.global_transform
	return {"model":JSON.stringify(game.save.normalised_model()),"equipment":game.equipment.save_capture(Save.SKIPPED),"poses":poses}

## Differences between a saved workshop's state and its reload, as messages.
static func differences(saved: Dictionary, loaded: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if saved.model != loaded.model:errors.append("model differs")
	for id in saved.equipment:
		var a: String = JSON.stringify(saved.equipment[id])
		var b: String = JSON.stringify(loaded.equipment.get(id))
		if a != b:errors.append(id+" differs: "+a+" vs "+b)
	for id in saved.poses:
		var a: Transform3D = saved.poses[id]
		var b: Transform3D = loaded.poses.get(id,Transform3D())
		if a.origin.distance_to(b.origin) > .001 or not a.basis.is_equal_approx(b.basis):errors.append(id+" body moved: "+str(a.origin)+" vs "+str(b.origin))
	return errors

## A second workshop in its own physics world, so it never collides with one still
## under test. Free it with `workshop.get_parent().free()`.
static func boot_isolated(tree: SceneTree, path: String) -> Node:
	var viewport = SubViewport.new()
	viewport.own_world_3d = true
	tree.root.add_child(viewport)
	var workshop = load("res://scenes/workshop.tscn").instantiate()
	workshop.automated_test = true
	workshop.save_path = path
	viewport.add_child(workshop)
	for tick in range(8):await tree.physics_frame
	workshop.set_paused(false)
	return workshop
