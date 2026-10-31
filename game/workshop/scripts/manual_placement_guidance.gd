extends Node3D
## While the player holds a part the tracked manual objective needs, its
## destination pulses amber through walls and equipment so it can be found from
## anywhere. Recipe order still applies: only placements the build would accept
## now glow. Reach, access and sightlines are not checked, so the cue never uses
## the ready green; only the aimed snap preview turns green, when a click works.
const MAX_COMPONENTS = 12
var game: Node
var material: ShaderMaterial
var component_ghosts: Array[MeshInstance3D] = []
var assembly_ghost: Node3D
var assembly_signature := ""

func setup(workshop: Node) -> void:
	game = workshop
	material = ShaderMaterial.new()
	material.shader = preload("res://scripts/manual_placement_glow.gdshader")
	material.render_priority = 10
	var amber: Color = game.SNAP_DISTANT_COLOR
	material.set_shader_parameter("glow_color",Color(amber.r,amber.g,amber.b))
	for i in MAX_COMPONENTS:
		var ghost = MeshInstance3D.new()
		ghost.material_override = material
		ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ghost.visible = false
		add_child(ghost)
		component_ghosts.append(ghost)
	assembly_ghost = Node3D.new()
	assembly_ghost.visible = false
	add_child(assembly_ghost)

func clear() -> void:
	for ghost in component_ghosts:ghost.visible = false
	if is_instance_valid(assembly_ghost):assembly_ghost.visible = false

## Destinations for the held part on the tracked step's current objective:
## {"owner","sid"} for a component, {"owner","sid","build"} for a held assembly
## and {"station","build"} for the step's own build.
func placements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var step: Dictionary = game.manual_progress.tracked()
	if step.is_empty() or game.manual_progress.status(str(step.owner),int(step.page))=="locked":return result
	var owner := str(step.owner)
	var held_build: String = game.held_build()
	# The step's own build is worked on at a preparation station.
	if held_build==owner:
		var station := _free_station(owner)
		if not station.is_empty():result.append({"station":station,"build":owner})
		return result
	if not game.interactable_assembly(owner):return result
	var page: Dictionary = step.definition
	var uid: String = "" if not held_build.is_empty() else game.components.selected_uid(game.selected_kind)
	if held_build.is_empty() and uid.is_empty():return result
	var slots: Array = []
	if page.has("objectives"):
		var index := int(game.manual_progress.evaluation(owner,int(step.page)).get("current",-1))
		var objectives: Array = page.get("objectives",[])
		if index<0 or index>=objectives.size():return result
		var objective: Dictionary = objectives[index]
		var op := str(objective.get("op",""))
		if op=="fit":slots = objective.get("slots",[]) if objective.get("slots") is Array else []
		# A seat performed through a machine is guided by its controls instead.
		elif op=="seat" and not objective.has("via"):slots = [objective.get("slot","")]
	else:slots = page.get("slots",[]) if page.get("slots") is Array else []
	for entry in slots:
		var sid := str(entry)
		if not str(game.model.assemblies[owner].slots.get(sid,"")).is_empty():continue
		var definition: Dictionary = game.model.slot_definition(owner,sid)
		if not held_build.is_empty():
			if definition.get("assembly","")!=game.model.assemblies[held_build].definition:continue
			if not game.model.placement_error(owner,sid,held_build).is_empty():continue
			result.append({"owner":owner,"sid":sid,"build":held_build})
		else:
			if definition.get("accepts","")!=game.model.items[uid].kind:continue
			if not game.components.placement_error(owner,sid,uid).is_empty():continue
			result.append({"owner":owner,"sid":sid})
		if result.size()==MAX_COMPONENTS:break
	return result

## The nearest station that is empty and large enough for the build.
func _free_station(build: String) -> String:
	var envelope: Vector3 = SolidHandling.bounds(game.bodies[build]).size
	var best := ""
	var best_distance := INF
	for station in game.stations:
		var node: Node3D = game.stations[station]
		var volume: Vector3 = node.get_meta("work_volume")
		if envelope.x>volume.x or envelope.y>volume.y or envelope.z>volume.z:continue
		if game.model.assemblies.keys().any(func(id):return id!=build and game.model.assemblies[id].location=="station:"+station):continue
		var distance: float = game.camera.global_position.distance_squared_to(node.global_position)
		if distance<best_distance:
			best = station
			best_distance = distance
	return best

func update() -> void:
	clear()
	if game.paused:return
	var used := 0
	for placement in placements():
		# The aimed snap preview already shows this destination: green when a
		# click would place it, amber otherwise. The pulse would only double it.
		if _previewed(placement):continue
		if placement.has("build"):
			_show_assembly(placement)
			continue
		var ghost: MeshInstance3D = component_ghosts[used]
		ghost.mesh = game.source[game.model.slot_definition(placement.owner,placement.sid).pose_source].mesh
		ghost.global_transform = game.slot_pose(placement.owner,placement.sid)
		ghost.visible = true
		used += 1

func _previewed(placement: Dictionary) -> bool:
	if not is_instance_valid(game.ghost) or not game.ghost.visible:return false
	var target: Dictionary = game.target
	if placement.has("station"):return target.get("type","")=="prep" and target.get("station","")==placement.station
	if placement.has("build"):return target.get("type","")=="mount" and target.get("owner","")==placement.owner and target.get("mount","")==placement.sid
	return target.get("type","")=="component" and target.get("owner","")==placement.owner and target.get("sid","")==placement.sid

func _show_assembly(placement: Dictionary) -> void:
	var build: String = placement.build
	var key := build
	for member in game.runtime.descendants(build):key += ":"+member+":"+str(game.assembly_node(member).get_meta("visual_revision",0))
	if key!=assembly_signature:
		for child in assembly_ghost.get_children():
			assembly_ghost.remove_child(child)
			child.queue_free()
		for piece in game.runtime.visual_pieces(build):
			var preview = MeshInstance3D.new()
			preview.mesh = piece.visual.mesh
			preview.transform = piece.transform
			preview.material_override = material
			preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			preview.set_meta("body_visual",piece.visual)
			assembly_ghost.add_child(preview)
		assembly_signature = key
	for child in assembly_ghost.get_children():
		var visual = child.get_meta("body_visual")
		child.visible = is_instance_valid(visual) and visual.visible
	assembly_ghost.global_transform = game.stations[placement.station].global_transform if placement.has("station") else game.runtime.mount_pose(placement.owner,placement.sid,build)
	assembly_ghost.visible = true
