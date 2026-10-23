extends "res://tests/kit/harness.gd"
## A placement updates progress without rebuilding an unchanged authored figure.
const Diagram = preload("res://scripts/manual_diagram.gd")

class DiagramSource extends Node:
	var source: Dictionary = {}
	func source_uid(uid: String) -> String:return uid
	func material(color: Color, metal: float = 0.0) -> StandardMaterial3D:
		var result = StandardMaterial3D.new()
		result.albedo_color = color
		result.metallic = metal
		return result

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var game = DiagramSource.new()
	root.add_child(game)
	for uid in ["part","context"]:
		game.source[uid] = {"mesh":BoxMesh.new(),"transform":Transform3D.IDENTITY}
	var diagram = Diagram.new()
	root.add_child(diagram)
	var entries: Array = [{"source":"part","highlight":true,"installed":false}]
	var views: Array = [
		{"title":"Front","sources":["part"],"context":["context"],"direction":[1,1,2],"clip_range":[-1,1]},
		{"title":"Rear","sources":["part"],"context":["context"],"direction":[-1,1,-2],"clip_range":[-2,2]}
	]
	diagram.show_parts(game,entries,views)
	var panels: Array = []
	var meshes: Array = []
	for column in diagram.panels.get_children():
		var panel = column.get_child(1)
		panels.append(panel)
		meshes.append_array(panel.stage.get_children())
		panel.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var panel_id = diagram.panels.get_instance_id()
	var first_material: ShaderMaterial = panels[0].stage.get_child(1).material_override
	var second_material: ShaderMaterial = panels[1].stage.get_child(1).material_override
	expect(first_material.shader == second_material.shader,"Authored panels share the same context shader")
	expect(first_material != second_material,"Each panel keeps independent context clipping parameters")
	expect(first_material.get_shader_parameter("clip_range") != second_material.get_shader_parameter("clip_range"),"Shared shader preserves each view's clipping range")
	for placement in range(10):
		entries[0].installed = placement % 2 == 0
		diagram.show_parts(game,entries,views)
	expect(diagram.panels.get_instance_id() == panel_id,"Ten progress changes retain the authored panel container")
	var retained_panels = 0
	var retained_meshes = 0
	for index in range(panels.size()):
		var current = diagram.panels.get_child(index).get_child(1)
		if current == panels[index]:retained_panels += 1
		for mesh in current.stage.get_children():
			if meshes.has(mesh):retained_meshes += 1
	expect(retained_panels == 2 and retained_meshes == 4,"Ten placements reuse both viewports and all four mesh instances")
	expect(diagram.panels.get_child(0).get_child(1).viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED,"Progress-only changes do not request another diagram render")
	views[0].direction = [2,1,1]
	diagram.show_parts(game,entries,views)
	expect(diagram.panels.get_instance_id() != panel_id,"Changing an authored camera rebuilds the figure")
	var updated_material: ShaderMaterial = diagram.panels.get_child(0).get_child(1).stage.get_child(1).material_override
	expect(updated_material.shader == first_material.shader,"New figures reuse the existing context shader")
	entries[0].installed = false
	diagram.show_parts(game,entries)
	var preview_mesh: MeshInstance3D = diagram.stage.get_child(0)
	expect(is_equal_approx(preview_mesh.position.y,-0.055),"Automatic diagrams retain the pending-part offset")
	entries[0].installed = true
	diagram.show_parts(game,entries)
	expect(diagram.stage.get_child(0) != preview_mesh and is_zero_approx(diagram.stage.get_child(0).position.y),"Automatic diagrams still refresh after installation")
	var passed: bool = checks.all(func(check):return check.passed)
	print("MANUAL_DIAGRAM_CACHE ","PASS" if passed else "FAIL"," ",checks.size()," checks; reused ",retained_panels,"/2 panels and ",retained_meshes,"/4 meshes across 10 progress changes")
	diagram.queue_free()
	game.queue_free()
	await process_frame
	quit(0 if passed else 1)
