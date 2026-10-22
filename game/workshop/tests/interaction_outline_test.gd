extends SceneTree
## Contour cache lifetime and cost without a renderer or the product window.
class CountedOutline:
	extends "res://scripts/interaction_outline.gd"
	var collections = 0
	var material_checks = 0
	func _collect(node: Node3D, result: Array[MeshInstance3D], key: int, entry: Dictionary) -> void:
		collections += 1
		super._collect(node,result,key,entry)
	func _writes_depth(visual: MeshInstance3D) -> bool:
		material_checks += 1
		return super._writes_depth(visual)

var checks: Array[Dictionary] = []
var outline: Node3D
var world: Node3D

func _initialize() -> void:
	run.call_deferred()

func expect(ok: bool, label: String) -> void:
	checks.append({"check":label,"passed":ok})
	if not ok:push_error(label)

func piece(parent: Node3D, offset: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.position = offset
	parent.add_child(mesh)
	return mesh

func run() -> void:
	world = Node3D.new()
	root.add_child(world)
	outline = CountedOutline.new()
	world.add_child(outline)
	var assembly = Node3D.new()
	world.add_child(assembly)
	var first = piece(assembly,Vector3(0.3,0.1,0.2))
	var nested = Node3D.new()
	assembly.add_child(nested)
	var second = piece(nested,Vector3(-0.3,0,0))
	var finish = StandardMaterial3D.new()
	first.material_override = finish
	outline.focus(assembly)
	expect(outline.copies.size() == 2,"One contour per physical mesh, including nested assembly parts")
	var first_contour: MeshInstance3D = outline.copies[first.get_instance_id()].outline
	var second_contour: MeshInstance3D = outline.copies[second.get_instance_id()].outline
	expect(first_contour.get_parent() == first and first_contour.transform == Transform3D.IDENTITY,"Contour inherits the source pose without a separate global-transform update")
	expect(first.material_override == finish and first.material_overlay == null,"Outlining preserves source materials and overlays")
	var collections: int = outline.collections
	var material_checks: int = outline.material_checks
	var contour_id = first_contour.get_instance_id()
	var samples = 240
	var start = Time.get_ticks_usec()
	for frame in range(samples):outline.focus(assembly)
	var stable_us = float(Time.get_ticks_usec()-start)/samples
	expect(outline.collections == collections and outline.material_checks == material_checks,"240 stable focus updates perform zero hierarchy scans or active-material inspections")
	expect(outline.copies[first.get_instance_id()].outline.get_instance_id() == contour_id,"Stable focus reuses the same mesh instance")
	var aligned = true
	for frame in range(120):
		assembly.rotate_y(0.01)
		assembly.position += Vector3(0.001,0,0)
		nested.rotate_z(0.003)
		first.position.y += 0.0005
		aligned = aligned and first_contour.global_transform.is_equal_approx(first.global_transform) and second_contour.global_transform.is_equal_approx(second.global_transform)
	expect(aligned,"Source-driven contour motion stays aligned through 120 motion increments between focus updates")
	first.hide()
	expect(not first_contour.is_visible_in_tree() and second_contour.is_visible_in_tree(),"Hiding an enclosed part hides only its contour immediately")
	first.show()
	nested.hide()
	expect(not second_contour.is_visible_in_tree(),"Ancestor visibility also hides a nested contour")
	nested.show()
	for frame in range(120):
		outline.clear()
		outline.focus(assembly)
	expect(outline.collections == collections and outline.material_checks == material_checks and outline.copies[first.get_instance_id()].outline.get_instance_id() == contour_id,"Looking away and back 120 times reuses contours without rescanning or rebuilding")
	outline.clear()
	expect(outline.focused == null and outline.copies.is_empty() and not first_contour.visible and not second_contour.visible,"Clearing focus hides every contour immediately while retaining the cache")
	outline.focus(assembly)
	var third = piece(nested,Vector3.UP*0.4)
	outline.focus(assembly)
	expect(outline.copies.size() == 3 and outline.copies[first.get_instance_id()].outline.get_instance_id() == contour_id,"Adding a nested part refreshes membership while reusing unchanged contours")
	third.queue_free()
	await process_frame
	outline.focus(assembly)
	expect(outline.copies.size() == 2,"Removing a nested part discards its cached contour")
	# In-place material edits and per-instance replacement both need to preserve
	# service transparency, even when the cache's object identity stays the same.
	finish.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outline.focus(assembly)
	expect(not outline.copies.has(first.get_instance_id()),"Editing the existing material to translucent removes its contour")
	finish.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	outline.focus(assembly)
	expect(outline.copies.has(first.get_instance_id()),"Restoring opacity recreates the appropriate contour")
	var translucent = StandardMaterial3D.new()
	translucent.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	first.material_override = translucent
	outline.focus(assembly)
	expect(not outline.copies.has(first.get_instance_id()),"Replacing the instance material invalidates depth eligibility")
	first.material_override = null
	first.set_surface_override_material(0,translucent)
	outline.focus(assembly)
	expect(not outline.copies.has(first.get_instance_id()),"A per-surface transparent override also suppresses the contour")
	first.set_surface_override_material(0,null)
	outline.focus(assembly)
	expect(outline.copies.has(first.get_instance_id()),"Removing the per-surface override restores opaque focus")
	var replacement = SphereMesh.new()
	first.mesh = replacement
	outline.focus(assembly)
	expect(outline.copies[first.get_instance_id()].outline.mesh == replacement,"Replacing physical mesh geometry refreshes the retained contour")
	collections = outline.collections
	assembly.set_meta("visual_revision",1)
	outline.focus(assembly)
	expect(outline.collections > collections and outline.copies.size() == 2,"Authored assembly revisions invalidate cached membership without collecting contours themselves")
	var spare = Node3D.new()
	world.add_child(spare)
	var spare_piece = piece(spare)
	outline.focus(spare)
	var spare_contour: MeshInstance3D = outline.copies[spare_piece.get_instance_id()].outline
	expect(not outline._cache[assembly.get_instance_id()].copies[first.get_instance_id()].outline.visible,"Changing focus hides the previous object's contours")
	spare.queue_free()
	await process_frame
	outline.focus(assembly)
	expect(not is_instance_valid(spare_contour) and outline._cache.size() == 1,"Freeing a cached object frees its child contours and purges stale entries")
	var original_id = assembly.get_instance_id()
	var original_contour: MeshInstance3D = outline.copies[first.get_instance_id()].outline
	for i in range(outline.CACHE_LIMIT):
		var other = Node3D.new()
		world.add_child(other)
		piece(other)
		outline.focus(other)
	await process_frame
	expect(outline._cache.size() == outline.CACHE_LIMIT and not outline._cache.has(original_id) and not is_instance_valid(original_contour),"The cache evicts the least recently used object and remains bounded")
	outline.focus(assembly)
	expect(outline.copies.size() == 2,"An evicted pickup rebuilds correctly when revisited")
	var last_contour: MeshInstance3D = outline.copies[first.get_instance_id()].outline
	outline.queue_free()
	await process_frame
	await process_frame
	expect(not is_instance_valid(last_contour) and first.get_child_count() == 0,"Destroying the manager releases contours attached to surviving source objects")
	var passed = checks.all(func(check):return check.passed)
	DirAccess.make_dir_recursive_absolute("res://verification/interaction-outline")
	FileAccess.open("res://verification/interaction-outline/audit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"rendered":false,"stable_focus_mean_us":stable_us,"focus_samples":samples},"  "))
	print("INTERACTION_OUTLINE ","PASS" if passed else "FAIL"," ",checks.size()," checks; stable focus mean ",stable_us," us")
	quit(0 if passed else 1)
