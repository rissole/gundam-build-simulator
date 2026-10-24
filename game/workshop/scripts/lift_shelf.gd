extends "res://scripts/equipment.gd"
## Two shelf places share a two-hand capacity. Every stored UID remains model-owned.
## The shelf rides its carrier lift and reserves its cargo route on every lift move.
const Sweep = preload("res://scripts/motion_sweep.gd")
var support_ids: Array = []
var shelf: Dictionary
var lift: Node3D
var surface: MeshInstance3D
var cargo: Dictionary = {}

func setup(workshop: Node3D, platform: Node3D, options: Dictionary) -> void:
	game = workshop;lift = platform;shelf = options
	equipment_id = shelf.id;support_ids = shelf.supports.duplicate()
	reparent(lift.deck);position = Vector3(shelf.position[0],shelf.position[1],shelf.position[2]);rotation.y = deg_to_rad(shelf.yaw_degrees)
	var steel = game.material(Color("506971"),.4)
	var size = AssemblyRuntime.vec(shelf.get("size",[1.9,.08,.70]))
	surface = game.box(self,Vector3.ZERO,size,steel,true)
	for x in [-size.x/2+.12,size.x/2-.12]:game.box(self,Vector3(x,-.31,0),Vector3(.07,.58,size.z*.6),steel,true)
	game.sign_panel(self,"COMPONENT SHELF\n2 × one-hand / 1 × two-hand",Vector3(0,.18,size.z/2+.03),Vector2(size.x-.1,.30),28,.002)
	sync()

func occupants(model: AssemblyModel = null) -> Array[String]:
	var m: AssemblyModel = game.model if model == null else model
	var result: Array[String] = []
	for support in support_ids:result.append(m.support_occupant(support))
	return result

func size_of(uid: String, model: AssemblyModel = null) -> int:
	var m: AssemblyModel = game.model if model == null else model
	return 2 if m.definitions.parts[m.items[uid].kind].carry_class == "two_hand" else 1

func capacity_error(uid: String) -> String:
	if not game.model.items.has(uid) or game.model.items[uid].location != "held":return "Pick up a component before storing it on the shelf."
	if game.model.definitions.parts[game.model.items[uid].kind].carry_class not in ["hand","two_hand"]:return "Small hardware stays in your pockets."
	var used = 0
	for occupant in occupants():
		if not occupant.is_empty():used += size_of(occupant)
	if used+size_of(uid)>2:return "Shelf full: it holds two one-hand components or one two-hand component."
	if size_of(uid)==2 and shelf.has("two_hand_capacity"):
		var bound: AABB=game.source[game.source_uid(uid)].mesh.get_aabb()
		var limit: Array=shelf.two_hand_capacity
		if bound.size.x>float(limit[0])+.00001 or bound.size.z>float(limit[1])+.00001 or bound.size.y>float(limit[2])+.00001:return "This component exceeds the shelf's upright panel capacity."
	return ""

func _pose(uid: String, index: int) -> Transform3D:
	var bound: AABB = game.source[game.source_uid(uid)].mesh.get_aabb()
	var places: Array = shelf.places
	return global_transform*Transform3D(Basis.IDENTITY,Vector3(0 if size_of(uid)==2 else places[index],.04,0)-Vector3(bound.get_center().x,bound.position.y,bound.get_center().z))

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var held: String = game.model.held_item()
	if not held.is_empty():
		result.append(control_entry(surface,"store","Store component on lift shelf · click",.4,{"point":to_global(Vector3(0,.08,.26)),"input":"place","allowed":[lift.deck]}))
	else:
		for index in range(2):
			var uid = occupants()[index]
			if uid.is_empty():continue
			var body: Node3D = cargo[uid]
			var bounds: AABB = game.source[game.source_uid(uid)].mesh.get_aabb()
			result.append(control_entry(body,"take:"+str(index),"Pick up "+game.components.title(game.model.items[uid].kind)+" · E",.3,{"point":body.global_transform*bounds.get_center(),"input":"pickup","allowed":[body,lift.deck],"allow_body_hit":true}))
	return result

func action_error(action: String) -> String:
	if game.paused:return "Resume the workshop first."
	if not game.equipment.busy_reason(lift.equipment_id).is_empty():return "Wait for the lift to stop before moving shelf components."
	if action == "store":return capacity_error(game.model.held_item())
	if action not in ["take:0","take:1"]:return "Unknown shelf position."
	var hand_error: String = game.hands.error(equipment_id)
	if not hand_error.is_empty():return hand_error
	return "" if not occupants()[int(action.get_slice(":",1))].is_empty() else "That shelf position is empty."

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():return error
	if action == "store":
		var uid: String = game.model.held_item()
		var index = occupants().find("")
		var body: WorkshopPart = game.components.held_body
		var destination = _pose(uid,index)
		var excluded: Array[RID] = [body.get_rid(),game.player.get_rid(),lift.deck.get_rid()]
		Sweep.collect_rids(self,excluded)
		error = SolidHandling.sweep_error(body,destination,excluded,game.WORLD_MASK)
		if not error.is_empty():return error
		error = game.model.store_carried_item(uid,support_ids[index])
		if not error.is_empty():return error
		game.components.held_body = null;body.queue_free();sync()
	else:
		var index = int(action.get_slice(":",1));var uid = occupants()[index]
		var previous: Transform3D = cargo[uid].global_transform
		error = game.model.carry_supported_item(uid,support_ids[index])
		if not error.is_empty():return error
		sync();game.components.hold_at(uid,previous)
	game.hud.refresh();return ""

func sync() -> void:
	var stored = occupants()
	for uid in cargo.keys():
		if not uid in stored:cargo[uid].free();cargo.erase(uid)
	for index in range(2):
		var uid = stored[index]
		if uid.is_empty():continue
		if not cargo.has(uid):
			var body = StaticBody3D.new();body.collision_layer = 2;add_child(body);body.add_child(game._mesh(uid));cargo[uid] = body
			for record in SolidHandling.authored_shapes(game.model.definitions.parts[game.model.items[uid].kind].get("collision_shapes",[]),game.source[game.source_uid(uid)].mesh.get_aabb()):
				var shape = CollisionShape3D.new();shape.shape = record.shape;shape.transform = record.transform;body.add_child(shape)
		cargo[uid].global_transform = _pose(uid,index)
		cargo[uid].force_update_transform();PhysicsServer3D.body_set_state(cargo[uid].get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,cargo[uid].global_transform)

func travel_error(carrier_id: String, from: float, to: float) -> String:
	if carrier_id != lift.equipment_id:return ""
	var excluded: Array[RID] = lift.without_passengers(lift.hardware())
	for body in cargo.values():
		var destination: Transform3D = body.global_transform;destination.origin.y += to-from
		if not SolidHandling.sweep_error(body,destination,excluded,15).is_empty():return "Clear the stored component's lift route."
	return ""

func carrier_moved(carrier_id: String) -> void:
	if carrier_id == lift.equipment_id:sync()

func access_error(owner: String) -> String:
	if owner == "pelvis" and not game.equipment.busy_reason(lift.equipment_id).is_empty():return "Wait for the lift to stop."
	return ""

func status_text() -> String:
	return "Lift shelf · two one-hand components or one two-hand component."

func capture() -> Dictionary:
	return {"version":1,"occupants":occupants()}

func validate(data: Variant, candidate: AssemblyModel = null, _world: Dictionary = {}) -> Array[String]:
	if not data is Dictionary or data.size()!=2 or not (data.get("version") is int or data.get("version") is float) or data.version!=1:return ["Invalid lift shelf snapshot."]
	if not data.get("occupants") is Array or data.occupants.size()!=2 or not data.occupants.all(func(v):return v is String):return ["Invalid shelf occupants."]
	if data.occupants!=occupants(candidate):return ["Shelf occupants disagree with physical ownership."]
	var used = 0
	for uid in data.occupants:
		if uid.is_empty():continue
		if not candidate.items.has(uid) or candidate.definitions.parts[candidate.items[uid].kind].carry_class not in ["hand","two_hand"]:return ["Invalid stored component."]
		used += size_of(uid,candidate)
	if used>2:return ["Lift shelf exceeds two-hand capacity."]
	return []

func apply(_data: Dictionary) -> void:
	sync()
