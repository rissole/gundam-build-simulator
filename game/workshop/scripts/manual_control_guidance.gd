extends Node3D
## The tracked objective selects controls only on manual updates. Availability
## checks stay live, so undo and equipment motion cannot leave a cue. Like the
## held part's destination glow, a cue shows at any distance and through models;
## operating the control still checks reach and sight.
const Outline = preload("res://scripts/interaction_outline.gd")
const MAX_CONTROLS = 8
## Emitted when the tracked objective changes, so a machine's ghost can follow it.
signal objective_changed
var game: Node
var objective: Dictionary = {}
var machine: Node
var objective_owner = ""
var outlines: Array = []
var visible_controls: Array[Node3D] = []

func setup(workshop: Node) -> void:
	game = workshop
	# Pulsing face tint drawn through geometry, then a steady thin contour that
	# keeps small parts readable where they are in plain view. The contour keeps
	# its depth test: an inverted hull without one fills the whole silhouette.
	# One override renders both passes on each mesh copy.
	var contour = ShaderMaterial.new()
	contour.shader = preload("res://scripts/interaction_outline.gdshader")
	contour.set_shader_parameter("outline_color",Color("d6ad59"))
	contour.set_shader_parameter("width_pixels",1.25)
	var material = ShaderMaterial.new()
	material.shader = preload("res://scripts/manual_control_glow.gdshader")
	material.render_priority = 10
	material.next_pass = contour
	for i in MAX_CONTROLS:
		var outline = Outline.new()
		outline.outline_material = material
		add_child(outline)
		outlines.append(outline)
	game.manual_progress.updated.connect(refresh)
	refresh()

func refresh() -> void:
	var previous: Array = [objective,machine]
	_select()
	if [objective,machine]!=previous:objective_changed.emit()

func _select() -> void:
	clear()
	objective = {}
	machine = null
	var step: Dictionary = game.manual_progress.tracked()
	if step.is_empty() or game.manual_progress.status(str(step.owner),int(step.page))=="locked":return
	var evaluation: Dictionary = game.manual_progress.evaluation(str(step.owner),int(step.page))
	var index := int(evaluation.get("current",-1))
	var objectives: Array = step.definition.get("objectives",[])
	if index<0 or index>=objectives.size():return
	objective_owner = str(step.owner)
	objective = objectives[index]
	if objective.get("op","")=="seat" and objective.get("via") is Dictionary:
		objective = objective.via.duplicate()
		objective.op = "operate"
	if objective.get("op","") not in ["operate","connect","detach","fit","seat"]:
		objective = {}
		return
	machine = game.equipment.get_equipment(str(objective.get("machine","")))

func clear() -> void:
	visible_controls.clear()
	for outline in outlines:outline.clear()

func update() -> void:
	if game.paused or objective.is_empty() or game.manual_progress._queued:
		clear()
		return
	var eligible: Array[Node3D] = []
	var held: Dictionary = game.desktop_input.held_control()
	var entries: Array = machine.manual_control_entries(objective) if is_instance_valid(machine) else []
	var rope = game.equipment.get_equipment("rope_access")
	if rope!=null:entries.append_array(rope.access_control_entries(objective,objective_owner,machine))
	for entry in entries:
		var node = entry.get("node") as Node3D
		if not is_instance_valid(node) or not node.is_visible_in_tree():continue
		# Offscreen controls would only take a slot from visible ones.
		if not game.camera.is_position_in_frustum(entry.get("point",node.global_position)):continue
		# The cue rests while E holds this control, so the player knows they found it.
		if not held.is_empty() and held.get("controller")==entry.get("controller") and held.get("action")==entry.get("action"):continue
		# Pickup/obstruction focus wins over the quieter manual cue.
		var focus: Node3D = game.interaction_outline.focused
		if is_instance_valid(focus) and (focus==node or focus.is_ancestor_of(node)):continue
		if not eligible.has(node):eligible.append(node)
		if eligible.size()==MAX_CONTROLS:break
	visible_controls = eligible
	for i in outlines.size():
		if i<eligible.size():outlines[i].focus(eligible[i])
		else:outlines[i].clear()
