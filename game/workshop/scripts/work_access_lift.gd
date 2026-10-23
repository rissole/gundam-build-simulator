class_name WorkAccessLift
extends "res://scripts/equipment.gd"
## Powered personnel platform. Heights describe the top of the walking deck.
const SPEED = 0.75
const THICKNESS = 0.12
const MASK = 15
const Sweep = preload("res://scripts/motion_sweep.gd")
## Short name used on controls and labels; the registry id is "<name>_lift".
var lift_name = ""
var deck: AnimatableBody3D
var gate: CollisionShape3D
var deck_size = Vector2(2, 5)
var stops: Array[float] = []
var height = 0.15
var destination = 0.15
var moving = false
var blocked_reason = ""
var _buttons: Array[Dictionary] = []
var _gate_mesh: MeshInstance3D
var _label: Label3D
var _hardware: Array[RID] = []

func setup(workshop: Node3D, id: String, origin: Vector3, size: Vector2, levels: Array[float]) -> void:
	game = workshop
	equipment_id = id+"_lift"
	lift_name = id
	position = origin
	deck_size = size
	stops.assign(levels)
	stops.sort()
	height = stops[0]
	destination = height
	var steel = game.material(Color("485f68"), 0.6)
	var yellow = game.material(Color("edbd59"), 0.2)
	deck = AnimatableBody3D.new()
	deck.name = id + "Deck"
	deck.collision_layer = 1
	deck.collision_mask = 0
	deck.sync_to_physics = false
	add_child(deck)
	_hardware.append(deck.get_rid())
	_solid(deck, Vector3(0,-THICKNESS/2,0), Vector3(size.x,THICKNESS,size.y),steel)
	for x in [-size.x/2+0.04,size.x/2-0.04]:
		for z in [-size.y/2+0.04,size.y/2-0.04]:
			_solid(deck,Vector3(x,0.52,z),Vector3(0.06,1.04,0.06),yellow)
		_solid(deck,Vector3(x,1.05,0),Vector3(0.06,0.06,size.y),yellow)
	_solid(deck,Vector3(0,1.05,-size.y/2+0.04),Vector3(size.x,0.06,0.06),yellow)
	gate = _solid(deck,Vector3(0,0.62,size.y/2-0.04),Vector3(size.x-0.12,1.0,0.06),yellow)
	_gate_mesh = gate.get_meta("visual")
	# Open ground entrance has a shallow solid ramp, usable without jumping.
	var ramp = StaticBody3D.new()
	add_child(ramp)
	_hardware.append(ramp.get_rid())
	var points = PackedVector3Array()
	for x in [-size.x/2+0.12,size.x/2-0.12]:
		points.append(Vector3(x,0,size.y/2))
		points.append(Vector3(x,stops[0],size.y/2))
		points.append(Vector3(x,0,size.y/2+1.2))
	var ramp_shape = ConvexPolygonShape3D.new()
	ramp_shape.points = points
	var ramp_collision = CollisionShape3D.new()
	ramp_collision.shape = ramp_shape
	ramp.add_child(ramp_collision)
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in [1,4,2,4,5,2,0,1,2,3,5,4,0,3,1,3,4,1,0,2,3,3,2,5]:surface.add_vertex(points[index])
	surface.generate_normals()
	var ramp_mesh = MeshInstance3D.new()
	ramp_mesh.mesh = surface.commit()
	ramp_mesh.material_override = steel
	ramp.add_child(ramp_mesh)
	_make_guides(steel,yellow)
	_solid(deck,Vector3(size.x/2-0.07,1.1,0),Vector3(0.12,0.36,0.90),steel)
	for pair in [["down",-0.25],["up",0.0],["ground",0.25]]:
		_button(deck,Vector3(size.x/2-0.14,1.1,float(pair[1])),pair[0],yellow)
	var call_post = StaticBody3D.new()
	add_child(call_post)
	_hardware.append(call_post.get_rid())
	_solid(call_post,Vector3(size.x/2+0.25,0.55,size.y/2+0.3),Vector3(0.08,1.1,0.08),steel)
	_button(self,Vector3(size.x/2+0.25,1.1,size.y/2+0.3),"ground",yellow)
	_label = Label3D.new()
	_label.position = Vector3(size.x/2-0.18,1.4,0)
	_label.rotation.y = -PI/2
	_label.font_size = 32
	_label.pixel_size = 0.002
	deck.add_child(_label)
	_pose()

func _make_guides(steel: Material, yellow: Material) -> void:
	# Twin rack drives carry the platform into floor-anchored guides. Both live
	# beside the far corners; the central +Z boarding opening remains clear.
	var supports = StaticBody3D.new()
	supports.name = "FloorAnchoredLiftGuides"
	add_child(supports)
	_hardware.append(supports.get_rid())
	var top = stops[-1]+1.4
	var z = deck_size.y/2-0.4
	for side in [-1.0,1.0]:
		var x = side*(deck_size.x/2+0.04)
		_solid(supports,Vector3(x,0.10,z),Vector3(0.10,0.20,0.55),steel)
		_solid(supports,Vector3(x,top/2,z),Vector3(0.10,top,0.16),steel)
		game.box(supports,Vector3(x,top/2,z-0.09),Vector3(0.04,top-0.20,0.02),yellow)
		var shoe = _solid(deck,Vector3(x,0.20,z-0.08),Vector3(0.22,0.40,0.22),steel)
		shoe.name = "GuideCarriageLeft" if side < 0 else "GuideCarriageRight"
		var drive = MeshInstance3D.new()
		var pinion = CylinderMesh.new()
		pinion.top_radius = 0.10
		pinion.bottom_radius = 0.10
		pinion.height = 0.10
		drive.mesh = pinion
		drive.material_override = yellow
		drive.position = Vector3(x,0.20,z-0.20)
		drive.rotation.z = PI/2
		deck.add_child(drive)

func _solid(parent: CollisionObject3D, at: Vector3, size: Vector3, mat: Material) -> CollisionShape3D:
	var visual = game.box(parent,at,size,mat)
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	parent.add_child(shape)
	shape.set_meta("visual",visual)
	return shape

func _button(parent: Node3D, at: Vector3, action: String, mat: Material) -> void:
	var node = game.box(parent,at,Vector3(0.12,0.13,0.16),mat)
	_buttons.append(control_entry(node,action,lift_name.capitalize()+" lift / "+action,0.16,{"equipment_id":equipment_id,"title":lift_name.capitalize()+" lift / "+action}))

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for button in _buttons:
		var entry = button.duplicate()
		entry.point = entry.node.global_position
		result.append(entry)
	return result

func _target(action: String) -> float:
	if action == "ground":return stops[0]
	if action == "up":
		for level in stops:
			if level > height+0.01:return level
	if action == "down":
		for index in range(stops.size()-1,-1,-1):
			if stops[index] < height-0.01:return stops[index]
	if action.begins_with("stop") and action.substr(4).is_valid_int():
		var index = int(action.substr(4))
		if index >= 0 and index < stops.size():return stops[index]
	return height

func action_error(action: String) -> String:
	if game.paused:return "Resume the workshop before operating the lift."
	if moving:return blocked_reason if not blocked_reason.is_empty() else "Wait for the lift to stop."
	if is_equal_approx(_target(action),height):return "The lift is already at this level."
	return ""

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():return error
	var next = _target(action)
	error = _sweep_error(height,next)
	if not error.is_empty():return error
	destination = next
	moving = true
	blocked_reason = ""
	_pose()
	return ""

func status_text() -> String:
	if not blocked_reason.is_empty():return "LIFT BLOCKED — clear the travel area"
	return "%s LIFT — %.2f m%s" % [lift_name.to_upper(),height," / moving" if moving else ""]

func physics(delta: float) -> void:
	if not moving or game.paused:return
	var next = move_toward(height,destination,SPEED*delta)
	blocked_reason = _sweep_error(height,destination)
	if not blocked_reason.is_empty():return
	height = next
	if is_equal_approx(height,destination):moving = false
	_pose()

func rider() -> CharacterBody3D:
	var player = game.get("player") as CharacterBody3D
	if not is_instance_valid(player):return null
	var local = to_local(player.global_position)
	if absf(local.x) < deck_size.x/2-0.28 and absf(local.z) < deck_size.y/2-0.28 and absf(local.y-height) < 0.12 and player.velocity.y <= 0.1:return player
	return null

## Fixed and deck-mounted bodies that travel with, or guide, this lift.
func hardware() -> Array[RID]:
	var excluded: Array[RID] = _hardware.duplicate()
	# Work controls may be mounted after setup by another equipment controller.
	Sweep.collect_rids(deck,excluded)
	return excluded

func busy_reason(subject: String) -> String:
	return "Wait for the lift to stop." if subject == equipment_id and moving else ""

func _sweep_error(from: float, to: float) -> String:
	# Reserve the entire carriage route; thin obstacles cannot fall between samples.
	var current_rider = rider()
	var clearance = 1.12
	if current_rider != null:
		for child in current_rider.get_children():
			if child is CollisionShape3D and not child.disabled:
				clearance = maxf(clearance,child.position.y+child.shape.get_debug_mesh().get_aabb().end.y+0.06)
	var low = minf(from,to)-THICKNESS+0.008
	var high = maxf(from,to)+clearance
	var box = BoxShape3D.new()
	box.size = Vector3(deck_size.x-0.006,high-low,deck_size.y-0.006)
	var excluded: Array[RID] = hardware()
	var carried: CollisionObject3D = null
	if current_rider != null:
		excluded.append(current_rider.get_rid())
		carried = _carried_body()
		if carried != null:Sweep.collect_rids(carried,excluded)
	var space = get_world_3d().direct_space_state
	if not Sweep.overlap(space,box,global_transform*Transform3D(Basis.IDENTITY,Vector3(0,(high+low)/2,0)),MASK,excluded,0.002).is_empty():
		return "Clear the lift travel area, including overhead and loose parts."
	if carried != null:
		# An actual rider's hand load travels with the platform. Reserve its own
		# complete envelope, including overhang outside the platform footprint.
		var load_bounds: AABB = carried.global_transform*SolidHandling.bounds(carried)
		var destination_bounds = AABB(load_bounds.position+Vector3.UP*(to-from),load_bounds.size)
		var swept = load_bounds.merge(destination_bounds)
		var load_shape = BoxShape3D.new()
		load_shape.size = swept.size.max(Vector3.ONE*0.004)
		if not Sweep.overlap(space,load_shape,Transform3D(Basis.IDENTITY,swept.get_center()),MASK,excluded,0.002).is_empty():return "Clear the carried component's lift route, including overhead."
	# Equipment riding the deck reserves its own cargo route.
	var registry = game.get("equipment")
	return registry.travel_error(equipment_id,from,to) if registry != null else ""

func _carried_body() -> CollisionObject3D:
	var components = game.get("components")
	if is_instance_valid(components):
		var held = components.get("held_body") as CollisionObject3D
		if is_instance_valid(held):return held
	if game.has_method("held_build"):
		var owner: String = game.held_build()
		var bodies = game.get("bodies")
		if not owner.is_empty() and bodies is Dictionary:return bodies.get(owner) as CollisionObject3D
	return null

func _pose() -> void:
	deck.position.y = height
	var closed = moving or height > stops[0]+0.01
	gate.disabled = not closed
	_gate_mesh.visible = closed
	_label.text = status_text()
	var registry = game.get("equipment")
	if registry != null:registry.carrier_moved(equipment_id)

func capture() -> Dictionary:
	return {"height":height,"destination":destination,"moving":moving}

func validate(snapshot: Variant, _candidate: AssemblyModel = null, _world: Dictionary = {}) -> Array[String]:
	var errors: Array[String] = []
	for key in ["height","destination"]:
		if not snapshot.has(key) or not (snapshot[key] is float or snapshot[key] is int):
			errors.append("Lift %s requires numeric %s." % [lift_name,key])
		elif not is_finite(float(snapshot[key])) or float(snapshot[key]) < stops[0]-0.001 or float(snapshot[key]) > stops[-1]+0.001:
			errors.append("Lift %s has out-of-range %s." % [lift_name,key])
	if not snapshot.get("moving") is bool:errors.append("Lift %s requires a motion flag." % lift_name)
	if errors.is_empty():
		var target_is_stop = false
		for stop in stops:target_is_stop = target_is_stop or is_equal_approx(float(snapshot.destination),stop)
		if not target_is_stop:errors.append("Lift destination must be a configured stop.")
		if not snapshot.moving and not is_equal_approx(float(snapshot.height),float(snapshot.destination)):errors.append("A stopped lift must be at its destination.")
	return errors

func apply(snapshot: Dictionary) -> void:
	if not validate(snapshot).is_empty():return
	height = float(snapshot.height)
	destination = float(snapshot.destination)
	moving = snapshot.moving
	blocked_reason = ""
	_pose()
