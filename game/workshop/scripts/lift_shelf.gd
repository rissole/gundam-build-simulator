extends "res://scripts/equipment.gd"
## Two shelf places share a two-hand capacity. Every stored UID remains model-owned.
## The shelf rides its carrier lift and reserves its cargo route on every lift move.
const Sweep = preload("res://scripts/motion_sweep.gd")
var support_ids: Array = []
var shelf: Dictionary
var lift: Node3D
var surface: MeshInstance3D
var cargo: Dictionary = {}
var _clamps: Array[Node3D] = []
var _stow_bounds: Dictionary = {}
var _clamp_occupants: Array = []

func setup(workshop: Node3D, platform: Node3D, options: Dictionary) -> void:
	game = workshop;lift = platform;shelf = options
	equipment_id = shelf.id;support_ids = shelf.supports.duplicate()
	reparent(lift.deck);position = Vector3(shelf.position[0],shelf.position[1],shelf.position[2]);rotation.y = deg_to_rad(shelf.yaw_degrees)
	var steel = game.material(Color("506971"),.4)
	var size = AssemblyRuntime.vec(shelf.get("size",[1.9,.08,.70]))
	surface = game.box(self,Vector3.ZERO,size,steel,true)
	for x in [-size.x/2+.12,size.x/2-.12]:game.box(self,Vector3(x,-.31,0),Vector3(.07,.58,size.z*.6),steel,true)
	game.sign_panel(self,"COMPONENT SHELF\n2 × one-hand / 1 × two-hand",Vector3(0,.18,size.z/2+.03),Vector2(size.x-.1,.30),28,.002)
	# Captive adjustable jaws stay on the shelf, parked when it is empty.
	for i in 4:
		var jaw = Node3D.new();add_child(jaw);_clamps.append(jaw)
		game.box(jaw,Vector3.ZERO,Vector3(.035,1,.035),steel,true)
		game.box(jaw,Vector3.ZERO,Vector3(.05,.035,.09),game.material(Color("bc9447"),.3),true)
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
	var bound = stow_bounds(uid)
	var limit = AssemblyRuntime.vec(shelf.get("two_hand_capacity",[shelf.size[0],shelf.size[2],1.2]))
	if size_of(uid)==2 and (bound.size.x>limit.x+.00001 or bound.size.z>limit.y+.00001 or bound.size.y>limit.z+.00001):return "This component does not fit the shelf in its supported storage orientation."
	return ""

func stow_basis(uid: String) -> Basis:
	var profile: Dictionary = game.model.definitions.parts[game.model.items[uid].kind].get("handling",{})
	return Basis.from_euler(AssemblyRuntime.vec(profile.get("shelf_rotation_degrees",[0,0,0]))*PI/180)

func stow_bounds(uid: String) -> AABB:
	var source_bounds: AABB = game.source[game.source_uid(uid)].mesh.get_aabb()
	var basis = stow_basis(uid)
	var profile: Array = game.model.definitions.parts[game.model.items[uid].kind].get("collision_shapes",[])
	var signature = hash(profile)
	var cached: Dictionary = _stow_bounds.get(uid,{})
	if cached.get("source") == source_bounds and cached.get("basis") == basis and cached.get("collision") == signature:return cached.bounds
	var envelope = source_bounds
	for record in SolidHandling.authored_shapes(profile,source_bounds):
		envelope = envelope.merge(record.transform*record.shape.get_debug_mesh().get_aabb())
	var bound = Transform3D(basis,Vector3.ZERO)*envelope
	_stow_bounds[uid] = {"source":source_bounds,"basis":basis,"collision":signature,"bounds":bound}
	return bound

func _pose(uid: String, index: int) -> Transform3D:
	var bound = stow_bounds(uid)
	var places: Array = shelf.places
	return global_transform*Transform3D(stow_basis(uid),Vector3(0 if size_of(uid)==2 else places[index],float(shelf.size[1])/2,0)-Vector3(bound.get_center().x,bound.position.y,bound.get_center().z))

func _pose_clamps() -> void:
	var stored = occupants()
	if _clamps.is_empty() or _clamp_occupants == stored:return
	_clamp_occupants = stored.duplicate()
	var contacts: Array[Vector3] = []
	for index in 2:
		var uid = occupants()[index]
		if uid.is_empty():continue
		var pose = global_transform.affine_inverse()*_pose(uid,index)
		for point in game.model.definitions.parts[game.model.items[uid].kind].get("handling",{}).get("shelf_clamps",[]):contacts.append(pose*AssemblyRuntime.vec(point))
	for i in _clamps.size():
		var point = contacts[i] if i<contacts.size() else Vector3(-.55 if i<2 else .55,.10,-.12 if i%2==0 else .12)
		var side = signf(point.z)
		var upright = _clamps[i].get_child(0) as MeshInstance3D
		var pad = _clamps[i].get_child(2) as MeshInstance3D
		var height = maxf(.04,point.y-.04)
		upright.position = Vector3(point.x,.04+height/2,point.z+side*.065)
		(upright.mesh as BoxMesh).size.y = height
		var post_body = _clamps[i].get_child(1) as StaticBody3D
		post_body.position = upright.position
		(post_body.get_child(0).shape as BoxShape3D).size.y = height
		pad.position = point+Vector3(0,0,side*.045)
		_clamps[i].get_child(3).position = pad.position


func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var held: String = game.model.held_item()
	if not held.is_empty():
		result.append(control_entry(surface,"store","Store component on lift shelf · click",.4,{"point":to_global(Vector3(0,.08,.26)),"input":"place","allowed":[lift.deck]}))
	else:
		var stored = occupants()
		for index in range(2):
			var uid = stored[index]
			if uid.is_empty():continue
			var body: Node3D = cargo[uid]
			var bounds: AABB = game.source[game.source_uid(uid)].mesh.get_aabb()
			result.append(control_entry(body,"take:"+str(index),"Pick up "+game.components.title(game.model.items[uid].kind)+" · E",.3,{"point":body.global_transform*bounds.get_center(),"pickup_body":body,"input":"pickup","allowed":[body,lift.deck],"allow_body_hit":true}))
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
	_pose_clamps()

func travel_error(carrier_id: String, from: float, to: float) -> String:
	if carrier_id != lift.equipment_id:return ""
	var excluded: Array[RID] = lift.without_passengers(lift.hardware())
	for body in cargo.values():
		var destination: Transform3D = body.global_transform;destination.origin.y += to-from
		var current: Transform3D = body.global_transform
		var hit = EquipmentRegistry.Motion.sweep(lift,[{"shapes":Sweep.body_shapes(body),"cast":true,"margin":.001,"error":""}],Sweep.steps(current,destination,0),func(p):return current.interpolate_with(destination,p),excluded)
		if not hit.is_empty():return hit.error
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
