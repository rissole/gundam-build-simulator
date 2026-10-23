extends Node3D
## Two shelf places share a two-hand capacity. Every stored UID remains model-owned.
const SUPPORTS = ["m2_lift_shelf_0","m2_lift_shelf_1"]
var game: Node3D
var lift: Node3D
var surface: MeshInstance3D
var cargo: Dictionary = {}

func setup(workshop: Node3D, platform: Node3D) -> void:
	game = workshop;lift = platform
	reparent(lift.deck);position = Vector3(.91,.68,0);rotation.y = -PI/2
	var steel = game.material(Color("506971"),.4)
	surface = game.box(self,Vector3.ZERO,Vector3(1.9,.08,.70),steel,true)
	for x in [-.83,.83]:game.box(self,Vector3(x,-.34,0),Vector3(.07,.68,.42),steel,true)
	game.sign_panel(self,"COMPONENT SHELF\n2 × one-hand / 1 × two-hand",Vector3(0,.18,.38),Vector2(1.8,.30),28,.002)
	sync()

func occupants(model: AssemblyModel = null) -> Array[String]:
	var m: AssemblyModel = game.model if model == null else model
	var result: Array[String] = []
	for support in SUPPORTS:result.append(m.support_occupant(support))
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
	return ""

func _pose(uid: String, index: int) -> Transform3D:
	var bound: AABB = game.source[game.source_uid(uid)].mesh.get_aabb()
	return global_transform*Transform3D(Basis.IDENTITY,Vector3(0 if size_of(uid)==2 else (-.46 if index==0 else .46),.04,0)-Vector3(bound.get_center().x,bound.position.y,bound.get_center().z))

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var held: String = game.model.held_item()
	if not held.is_empty():
		result.append({"type":"equipment","controller":self,"node":surface,"point":to_global(Vector3(0,.08,.26)),"radius":.4,"action":"store","label":"Store component on lift shelf · click","input":"place","allowed":[lift.deck]})
	else:
		for index in range(2):
			var uid = occupants()[index]
			if uid.is_empty():continue
			var body: Node3D = cargo[uid]
			var bounds: AABB = game.source[game.source_uid(uid)].mesh.get_aabb()
			result.append({"type":"equipment","controller":self,"node":body,"point":body.global_transform*bounds.get_center(),"radius":.3,"action":"take:"+str(index),"label":"Pick up "+game.components.title(game.model.items[uid].kind)+" · E","input":"pickup","allowed":[body,lift.deck],"allow_body_hit":true})
	return result

func action_error(action: String) -> String:
	if game.paused:return "Resume the trial first."
	if lift.moving:return "Wait for the lift to stop before moving shelf components."
	if action == "store":return capacity_error(game.model.held_item())
	if action not in ["take:0","take:1"]:return "Unknown shelf position."
	if game.model.hands_occupied():return "Set down the component in your hands first."
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
		lift._collect_bodies(self,excluded)
		error = SolidHandling.sweep_error(body,destination,excluded,game.WORLD_MASK)
		if not error.is_empty():return error
		error = game.model.store_carried_item(uid,SUPPORTS[index])
		if not error.is_empty():return error
		game.components.held_body = null;body.queue_free();sync()
	else:
		var index = int(action.get_slice(":",1));var uid = occupants()[index]
		var previous: Transform3D = cargo[uid].global_transform
		error = game.model.carry_supported_item(uid,SUPPORTS[index])
		if not error.is_empty():return error
		sync();_hold(uid,previous)
	game.hud.refresh();return ""

func _hold(uid: String, at: Transform3D) -> void:
	game._spawn_loose(uid)
	var body: WorkshopPart = game.loose[uid];game.loose.erase(uid)
	body.global_transform = at;body.held = true;body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC;body.freeze = true
	body.linear_velocity = Vector3.ZERO;body.angular_velocity = Vector3.ZERO
	body.add_collision_exception_with(game.player);game.player.add_collision_exception_with(body)
	game.components.held_body = body

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

func lift_sweep(from: float, to: float) -> String:
	var excluded: Array[RID] = lift._hardware.duplicate();lift._collect_bodies(lift.deck,excluded)
	if lift._rider()!=null:excluded.append(game.player.get_rid())
	for body in cargo.values():
		var destination: Transform3D = body.global_transform;destination.origin.y += to-from
		if not SolidHandling.sweep_error(body,destination,excluded,15).is_empty():return "Clear the stored component's lift route."
	return ""

func status_text() -> String:
	return "Lift shelf · two one-hand components or one two-hand component."

func capture() -> Dictionary:
	return {"version":1,"occupants":occupants()}

func validate(data: Variant, candidate: AssemblyModel) -> Array[String]:
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
