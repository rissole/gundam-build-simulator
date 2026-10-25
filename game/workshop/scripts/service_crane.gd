extends "res://scripts/equipment.gd"
## Canonical LG-120 handling. Robot inventory never owns a cable endpoint.
## Model ownership: rack -> crane -> leg. Assistance remains a contact, not an owner.
signal changed
const Console = preload("res://scripts/service_crane_console.gd")
const Sweep = preload("res://scripts/motion_sweep.gd")
const Layout = preload("res://scripts/leg_bay_layout.gd")
const Codec = preload("res://scripts/pose_codec.gd")
const VERSION = 2
var END_IDS: Array = []
var POINT_IDS: Array = []
var points: Array[Vector3] = []
var load_owner: String
var slot: String
var secured_milestone: String
var fastener_slots: Array = []
var park_position: Vector3
var approach_offset: Vector3
const STATIONS = ["source","receiver","park"]
const TITLES = {"source":"Limb Bay","receiver":"Limb Bay","park":"Parking bay"}
const MANUAL_COMMANDS = ["pickup","down","up","go:source","go:receiver","go:park","connect","detach"]
var up_y: float
var layout: Node3D
var config: Dictionary
var support = "crane_rigging"
var source_support = "leg_spar_rack"
var uid = "LG-120__001"
var source_pose: Transform3D
var receiver_pose: Transform3D
var route: Array[Transform3D] = []
var excluded: Array[RID] = []
var station = "park"
var raised = true
var motion = ""
var progress: float = 0.0
var moving = false
var blocked_reason = ""
# Load path is derived from station, motion and progress; never a saved waypoint.
var path: float:
	get:return _path(station,raised,motion,progress)
var endpoints: Dictionary = {}
var load_body: AnimatableBody3D
var stock_bodies: Dictionary = {}
var beam: Node3D
var rig_bar: MeshInstance3D
var rig_center = 1.7
var end_nodes: Dictionary = {}
var cables: Dictionary = {}
var markers: Dictionary = {}
var mast_cable: MeshInstance3D
var console_node: MeshInstance3D
var console: CanvasLayer
var physical_status: Label3D

var tasks: Dictionary = {}
var task = ""
var assembly_payload = false
var receiver_support = ""
# Routes are hidden: an empty crane serves the next load in crane.order, and
# travels to it from its current beam pose. Undo can request one route back.
var travel_from: Variant = null
var reacquire = ""
var required_ends: int:
	get:return END_IDS.size()

var assisting: bool:
	get:return _installed() and attached_count() > 0

func setup(workshop: Node3D, scene_layout: Node3D, contract: Dictionary = {}) -> void:
	game = workshop;layout = scene_layout;config = contract;equipment_id = "service_crane"
	hand_payload_hint = "Attach or Q-stow the held magnetic connector first."
	hands_full_hint = "Stow the component or assembly in your hand before handling a magnetic connector."
	support = contract.get("support",support);source_support = contract.get("source_support",source_support);uid = contract.get("uid",uid)
	var crane_spec: Dictionary = preload("res://scripts/leg_bay_layout.gd").layout().crane
	tasks = crane_spec.tasks;task = crane_spec.task
	_configure_task(contract)
	_make_load();_make_rig();_make_console(contract.console_position)
	console = Console.new();add_child(console);console.setup(self)
	game.model.changed.connect(_refresh)
	_refresh()


func _configure_task(contract: Dictionary) -> void:
	config=contract
	var spec: Dictionary = contract.get("spec",preload("res://scripts/leg_bay_layout.gd").layout().crane)
	support = spec.support;source_support = spec.source_support;uid = spec.load_uid
	load_owner = spec.owner;slot = spec.slot;secured_milestone = spec.secured.milestone
	assembly_payload=spec.get("payload","")=="assembly";receiver_support=spec.get("receiver_support","")
	fastener_slots = [] if secured_milestone.is_empty() else game.runtime.definition(load_owner).milestones[secured_milestone].filter(func(sid):return sid != slot)
	END_IDS = spec.endpoint_ids.duplicate();POINT_IDS = spec.magnetic_points.keys();points.clear();endpoints.clear()
	for id in END_IDS:endpoints[id] = {"state":"stowed","point":""}
	for id in POINT_IDS:points.append(AssemblyRuntime.vec(spec.magnetic_points[id]))
	up_y = spec.up_y;park_position = AssemblyRuntime.vec(spec.park_position)
	approach_offset = -AssemblyRuntime.vec(spec.approach.axis)*spec.approach.distance
	source_pose = contract.source_pose;receiver_pose = contract.receiver_pose
	route.assign(contract.route);excluded.assign(contract.get("excluded",[]))

func _make_load() -> void:
	load_body = _stock_body(uid)
	for spec in tasks.values():_stock_body(spec.load_uid)

func _stock_body(item_uid: String) -> AnimatableBody3D:
	if stock_bodies.has(item_uid):return stock_bodies[item_uid]
	if game.model.assemblies.has(item_uid):
		stock_bodies[item_uid]=game.runtime.node(item_uid)
		# Supported assemblies follow explicit poses. Kinematic targets only reach
		# Jolt on the next physics tick, leaving same-tick collision queries stale.
		for owner in game.runtime.descendants(item_uid):
			var body=game.runtime.node(owner)
			if body is AnimatableBody3D:PhysicsServer3D.body_set_mode(body.get_rid(),PhysicsServer3D.BODY_MODE_STATIC)
			body.force_update_transform();PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
		return stock_bodies[item_uid]
	var body = AnimatableBody3D.new();body.name = "CraneLoad_"+item_uid
	body.sync_to_physics = false;body.collision_layer = 2;body.collision_mask = 0;add_child(body)
	body.set_meta("equipment_item_uid",item_uid);body.add_child(game._mesh(item_uid))
	var source: Dictionary = game.source[game.source_uid(item_uid)]
	for record in SolidHandling.authored_shapes(game.model.definitions.parts[game.model.items[item_uid].kind].get("collision_shapes",[]),source.mesh.get_aabb()):
		var shape = CollisionShape3D.new();shape.shape = record.shape;shape.transform = record.transform;body.add_child(shape)
	stock_bodies[item_uid] = body
	return body

func _make_rig() -> void:
	var steel = game.material(Color("e8b46b"),.45)
	var dark = game.material(Color("263a43"),.45)
	var green = game.material(Color("7cc7a7"),.25)
	beam = Node3D.new();beam.name = "LoweredMagneticBeam";add_child(beam)
	rig_bar = game.box(beam,Vector3(0,0,1.7),Vector3(.28,.18,2.9),steel)
	_configure_rig_bar()
	var all_ends: Array=END_IDS.duplicate();var all_points: Array=POINT_IDS.duplicate()
	for spec in tasks.values():
		for id in spec.endpoint_ids:
			if id not in all_ends:all_ends.append(id)
		for id in spec.magnetic_points:
			if id not in all_points:all_points.append(id)
	for id in all_ends:
		var end = game.box(self,Vector3.ZERO,Vector3(.12,.09,.12),steel);end.name = id;end_nodes[id] = end
		cables[id] = game.box(self,Vector3.ZERO,Vector3(.025,1,.025),dark)
	for id in all_points:
		var marker = game.box(self,Vector3.ZERO,Vector3(.17,.012,.17),green);marker.name = id;markers[id] = marker
	mast_cable = game.box(self,Vector3.ZERO,Vector3(.035,1,.035),dark)

func _make_console(at: Vector3) -> void:
	var dark = game.material(Color("263a43"),.4)
	var yellow = game.material(Color("e8b46b"),.2)
	game.box(self,at+Vector3(0,.48,0),Vector3(.18,.96,.18),dark,true)
	game.box(self,at+Vector3(0,.06,0),Vector3(.65,.12,.65),dark,true)
	console_node = game.box(self,at+Vector3(0,1.15,-.08),Vector3(.48,.40,.12),yellow)
	console_node.name = "CentralCraneConsole"
	game.sign_panel(self,"SERVICE CRANE\nE · control",at+Vector3(0,1.65,.03),Vector2(.84,.28),32,.0018)
	physical_status = game.sign_panel(self,"",at+Vector3(0,2.24,.03),Vector2(1.4,.4),28,.0015)
	physical_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;physical_status.width = 850

func _guide() -> Node:
	return game.equipment.get_equipment(config.spec.guided_receiver) if config.spec.has("guided_receiver") else null
func _guided_live() -> bool:
	var guide=_guide()
	return guide!=null and guide.active and station=="receiver" and not raised and motion.is_empty()

func hand_payload() -> String:
	for id in END_IDS:
		if endpoints[id].state == "held":return id
	return ""

static func snapshot_has_hand_payload(data: Dictionary) -> bool:
	for end in data.get("endpoints",{}).values():
		if end is Dictionary and end.get("state","") == "held":return true
	return false

func attached_count() -> int:
	var count = 0
	for end in endpoints.values():
		if end.state == "attached":count += 1
	return count

func save_version() -> int:return VERSION

func controls() -> Array[Dictionary]:
	var entries: Array[Dictionary] = [control_entry(console_node,"open_console","Crane console · E",.28,{"point":console_node.global_position,"input":"use"})]
	if raised or not motion.is_empty() or station == "park":return entries
	for id in END_IDS:
		var state: String = endpoints[id].state
		if state == "held":continue
		entries.append(control_entry(end_nodes[id],("detach:" if state == "attached" else "pick:")+id,("Detach" if state == "attached" else "Pick up")+" "+config.spec.get("endpoint_labels",{}).get(id,"magnetic connector")+" · E",.16,{"point":end_nodes[id].global_position,"input":"pickup","allowed":[load_body,game.runtime.node(load_owner)],"allow_body_hit":true}))
	if not hand_payload().is_empty():
		for id in POINT_IDS:
			entries.append(control_entry(markers[id],"attach:"+id,"Attach magnetic connector · click",.20,{"point":handle_position(id),"input":"place","allowed":[load_body,game.runtime.node(load_owner)],"allow_body_hit":true}))
	return entries

func console_access_error() -> String:
	if game.camera.global_position.distance_to(console_node.global_position)>game.REACH:return "Move within reach of the central crane console."
	if not game._visible(console_node.global_position,[]):return "The central crane console is obstructed."
	return ""

func request_console(action: String) -> String:
	if not console.is_open:return "Open the physical crane console first."
	var error = console_access_error()
	if not error.is_empty():console.shut();return error
	return request(action)

func _interaction_error(point: Vector3, allowed: Array = []) -> String:
	if game.camera.global_position.distance_to(point)>game.REACH:return "Move within reach of the magnetic connection."
	if not game._visible(point,allowed,true):return "The magnetic connection is obstructed."
	return ""

func manual_commands() -> Array:return MANUAL_COMMANDS

## The single player wording for a crane command; the console menu adds arrows and places.
func command_label(action: String) -> String:
	match action:
		"down":return "Lower crane"
		"up":return "Raise crane"
		"pickup":return "Move to pickup"
		"go:receiver":return "Move to delivery"
		"go:source":return "Put back"
		"connect":return "Attach magnetic connectors"
		"detach":return "Detach and stow magnetic connectors"
	if action.begins_with("go:"):return "Move to "+_station_title(action.get_slice(":",1))
	return ""

func manual_state() -> Dictionary:
	return {"task":task,"station":station,"raised":raised,"attached":attached_count(),"held":not hand_payload().is_empty()}

func manual_effect(objective: Dictionary) -> Dictionary:
	match objective.get("op",""):
		"connect":return {"attached":required_ends,"held":false}
		"detach":return {"attached":0,"held":false}
	var action: String = objective.get("command","")
	match action:
		"pickup":return {"task":objective.get("task",""),"station":objective.get("at","source")}
		"down":return {"raised":false}
		"up":return {"raised":true}
	if action.begins_with("go:"):return {"station":action.get_slice(":",1)}
	return {}

func manual_count(objective: Dictionary) -> Vector2i:
	return Vector2i(attached_count(),required_ends) if objective.get("op","")=="connect" else Vector2i(-1,-1)

func menu_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if _guided_live() and _guide().has_method("crane_options"):options.append_array(_guide().crane_options())
	if not motion.is_empty():
		options.append({"action":"stop" if moving else "resume","label":"Stop" if moving else "Resume"})
		if _can_return():options.append({"action":"return","label":"Return to "+_station_title(station)})
		return options
	if station != "park":options.append({"action":"down" if raised else "up","label":("↓  " if raised else "↑  ")+command_label("down" if raised else "up")})
	if raised:
		if _empty():
			var next: String = next_route()
			var role: String = _pickup_role(next)
			if not next.is_empty() and not (next == task and station == role):options.append({"action":"pickup","label":command_label("pickup")+" · "+Layout.place_title(place_of(role,next))})
		else:
			if station != "receiver":options.append({"action":"go:receiver","label":command_label("go:receiver")+" · "+_station_title("receiver")})
			if station != "source":options.append({"action":"go:source","label":command_label("go:source")+" · "+_station_title("source")})
		if station != "park" and _empty():options.append({"action":"go:park","label":command_label("go:park")})
	elif raised:
		for destination in STATIONS:
			var action = "go:"+destination
			if destination != station:options.append({"action":action,"label":command_label(action)})
	return options

## Reverse a held transport along the same authored route. Vertical phases
## keep their support-transfer interlocks and can still be stopped explicitly.
func _can_return() -> bool:
	return not blocked_reason.is_empty() and motion in ["go:source","go:receiver"] and station != "park" and travel_from == null

func action_error(action: String) -> String:
	if game.paused:return "Resume the workshop before operating the crane."
	if action.begins_with("guide:"):
		return _guide().action_error(action.trim_prefix("guide:")) if _guided_live() else "Lower the matching crane at the supported connection first."
	if action.begins_with("task:"):
		if action.get_slice(":",1) not in tasks:return "Unknown crane task."
		if station != "park" or not raised or not motion.is_empty() or attached_count()>0 or not hand_payload().is_empty():return "Park the empty crane and stow its magnetic connectors before changing task."
		return ""
	if action == "open_console":return console_access_error()
	if action == "close_console":return ""
	if action == "stop":return "" if moving else "The crane is stopped."
	if action == "return":return "" if _can_return() else "Return is available while a transport is waiting for its route to clear."
	if action == "resume":return "" if not moving and not motion.is_empty() else "There is no stopped crane movement to resume."
	if action == "stow":return "" if not hand_payload().is_empty() else "You are not holding a magnetic connector."
	if action.begins_with("pick:") or action.begins_with("detach:"):
		var id = action.get_slice(":",1)
		if not END_IDS.has(id):return "Unknown magnetic connector."
		if raised or not motion.is_empty() or station == "park":return "Lower the crane at a work location before handling magnetic connectors."
		if not hand_payload().is_empty():return "Attach or stow the magnetic connector already in your hand."
		var error = game.hands.error(equipment_id)
		if not error.is_empty():return error
		if action.begins_with("pick:") and endpoints[id].state != "stowed":return "That magnetic connector is already attached."
		if action.begins_with("detach:"):
			if endpoints[id].state != "attached":return "That magnetic connector is not attached."
			if _guided_live():
				var guide_error: String=_guide().rig_error("detach",endpoints[id].point)
				if not guide_error.is_empty():return guide_error
			if config.spec.has("source_equipment"):
				var support_error: String=game.equipment.get_equipment(config.spec.source_equipment).release_error(uid)
				if not support_error.is_empty():return support_error
			if _installed() and not secured():return "Complete this connection’s retaining hardware before detaching a magnetic connector."
		return _interaction_error(end_nodes[id].global_position,[load_body,game.runtime.node(load_owner)])
	if action.begins_with("attach:"):
		var point = action.get_slice(":",1)
		if not POINT_IDS.has(point):return "Choose a marked magnetic attachment point."
		if hand_payload().is_empty():return "Pick up a magnetic connector first."
		if config.spec.get("point_ends",{}).has(point) and config.spec.point_ends[point]!=hand_payload():return "Choose the matching magnetic connector for this point."
		if _guided_live():
			var guide_error: String=_guide().rig_error("attach",point)
			if not guide_error.is_empty():return guide_error
		if raised or not motion.is_empty() or station == "park":return "Lower the crane at the beam before attaching magnetic connectors."
		var held_by: String = game.equipment.busy_reason("rig:"+load_owner,equipment_id)
		if not held_by.is_empty():return held_by
		if station == "receiver":
			var receiver_error = _receiver_error()
			if not receiver_error.is_empty():return receiver_error
		if station=="source" and _record().location!="support:"+source_support or station=="receiver" and not _installed() and not _guided_live():return "The load is not seated at this work location."
		for end in endpoints.values():
			if end.point == point:return "That point is occupied. Aim at the other marked point."
		return _interaction_error(handle_position(point),[load_body,game.runtime.node(load_owner)])
	if not motion.is_empty():return "Finish or resume the current motion first."
	if not hand_payload().is_empty():return "Attach or Q-stow the held magnetic connector first."
	if action == "up":
		if _guided_live():return _guide().departure_error()
		if raised:return "The crane is already up."
		if attached_count()>0 and attached_count()!=required_ends:return "Attach all %d magnetic connectors, or detach the remaining connectors before raising."%required_ends
		if attached_count()==required_ends:
			if station=="source" and config.spec.has("source_equipment"):
				var source_error: String=game.equipment.get_equipment(config.spec.source_equipment).source_error(uid)
				if not source_error.is_empty():return source_error
			if hardware_count()>0:return "Undo all of this connection’s retaining hardware before lifting the component."
			if _installed():return _beam_undo_error()
			if not game.model.support_occupant(support).is_empty():return "The crane support is occupied."
		return ""
	if action == "pickup":
		var next: String = next_route() if _empty() else ""
		if next.is_empty():return "No crane load is waiting." if _empty() else "Set the load down before collecting another."
		if next == task:return action_error("go:"+_pickup_role(next))
		if not raised:return "Raise the crane before travelling to another location."
		return "" if next == reacquire else _ready_error(next)
	if action == "down":
		if station=="source" and config.spec.has("source_equipment"):
			var source_error: String=game.equipment.get_equipment(config.spec.source_equipment).source_error(uid)
			if not source_error.is_empty():return source_error
		if station == "receiver":
			var receiver_error = _receiver_error()
			if not receiver_error.is_empty():return receiver_error
		if not raised:return "The crane is already down."
		if station == "park":return "Go to a work location before lowering."
		if _crane_owned():
			if station == "source" and not game.model.support_occupant(source_support).is_empty():return "The source rig is occupied."
			if station == "receiver":
				var error: String = _placement_error()
				if not error.is_empty():return error
		return ""
	if action.begins_with("go:"):
		var destination = action.get_slice(":",1)
		if destination not in STATIONS:return "Unknown crane location."
		if destination != "park":
			var rail_error = _receiver_error()
			if not rail_error.is_empty():return rail_error
		if not raised:return "Raise the crane before travelling to another location."
		if destination == station:return "The crane is already at this location."
		if _crane_owned():
			if destination == "park":return "Set the beam on its rig or receiving connection before parking."
			if destination == "source" and not game.model.support_occupant(source_support).is_empty():return "The source rig is occupied."
			if destination == "receiver":
				var error=_placement_error()
				if not error.is_empty():return error
		return ""
	return "Unknown crane command."

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():return error
	if action.begins_with("guide:"):
		error=_guide().request(action.trim_prefix("guide:"));_refresh();return error
	if action.begins_with("task:"):
		_select_route(action.get_slice(":",1));_refresh();return ""
	if action == "pickup":
		var next: String = next_route()
		if next != task:
			# The empty beam travels from where it hangs to the next load.
			travel_from = _beam_pose();_select_route(next);station = "park"
		action = "go:"+_pickup_role(next)
	if action == "open_console":return console.open()
	if action == "close_console":console.shut();return ""
	if action == "return":
		var origin = station
		station = motion.get_slice(":",1);motion = "go:"+origin;progress = 1.0-progress
		moving = true;blocked_reason = "";motion_obstruction = {};_refresh();return ""
	if action == "stop":moving = false
	elif action == "resume":moving = true;blocked_reason = ""
	elif action == "stow":endpoints[hand_payload()] = {"state":"stowed","point":""}
	elif action.begins_with("pick:") or action.begins_with("detach:"):endpoints[action.get_slice(":",1)] = {"state":"held","point":""}
	elif action.begins_with("attach:"):
		endpoints[hand_payload()] = {"state":"attached","point":action.get_slice(":",1)}
		if reacquire == task:reacquire = ""
	else:
		if action=="up" and _guided_live():_guide().depart()
		if action == "up" and _installed() and attached_count()==required_ends and not config.spec.get("receiver_contact",false):
			error = _undo_beam()
			if not error.is_empty():return error
		motion = action;progress = 0;moving = true;blocked_reason = ""
	_refresh()
	if is_instance_valid(game.hud):game.hud.refresh()
	return ""

func cancel_hand() -> String:
	if console.is_open:console.shut();return ""
	return request("stow")

func _installed(model: AssemblyModel = null) -> bool:
	var m: AssemblyModel = game.model if model == null else model
	if not receiver_support.is_empty():return _record(m).location=="support:"+receiver_support
	if assembly_payload:return m.assemblies[uid].parent==load_owner and m.assemblies[uid].parent_slot==slot
	return m.items[uid].location == "installed" and m.items[uid].owner == load_owner and m.items[uid].slot == slot and m.assemblies[load_owner].slots[slot] == uid

func _record(model: AssemblyModel = null, identity: String = "") -> Dictionary:
	var m: AssemblyModel=game.model if model==null else model
	var id=uid if identity.is_empty() else identity
	return m.assemblies[id] if m.assemblies.has(id) else m.items[id]

func _transfer(from: String, to: String) -> String:
	return game.model.transfer_supported_assembly(uid,from,to) if assembly_payload else game.model.transfer_supported_item(uid,from,to)

func _placement_error() -> String:
	if _guide()!=null:return _guide().receiving_error(uid)
	if receiver_support.is_empty():return game.model.placement_error(load_owner,slot,uid,support)
	var error: String=game.model.support_error(uid,receiver_support)
	if not error.is_empty():return error
	return "The receiving support is occupied." if not game.model.support_occupant(receiver_support).is_empty() else ""

func _seat() -> String:
	# Publish the exact contact pose before ownership changes. A supported
	# assembly may stop following the crane during the model's changed signal.
	if assembly_payload:load_body.global_transform=receiver_pose
	if _guide()!=null:return _guide().accept()
	if not receiver_support.is_empty():return _transfer(support,receiver_support)
	var result: Dictionary=game.model.install_supported(load_owner,slot,uid,support)
	if not result.ok:return result.error
	if assembly_payload:game.runtime.mount(load_owner,slot,uid)
	else:game.components.sync(load_owner)
	game.refresh_assembly_collision(load_owner)
	return ""

func hardware_count(model: AssemblyModel = null) -> int:
	var m: AssemblyModel = game.model if model == null else model
	var count = 0
	for sid in fastener_slots:
		if not m.assemblies[load_owner].slots[sid].is_empty():count += 1
	return count

func secured(model: AssemblyModel = null) -> bool:
	var m: AssemblyModel = game.model if model == null else model
	if _guide()!=null:return _installed(m) and _guide().secured({},m)
	if not receiver_support.is_empty():
		var receiver=game.equipment.get_equipment(config.spec.receiver_equipment)
		return _installed(m) and (receiver==null or not receiver.has_method("support_secured") or receiver.support_secured(uid,m))
	return _installed(m) and m.milestone(load_owner,secured_milestone)

func busy_reason(subject: String) -> String:
	if subject == "foot_fixture":return "Detach the magnetic connectors before turning the foot." if attached_count()>0 and load_owner == game.default_parent_id() else ""
	if subject in ["rail","foot_transfer"]:
		if attached_count()>0 or not motion.is_empty() and _crane_owned():return "Stow the magnetic connectors and set the load down before moving the rig."
		for key in tasks:
			var spec: Dictionary = tasks[key]
			if spec.get("receiver_support","").is_empty() and _record(game.model,spec.load_uid).location == "installed" and not game.model.milestone(spec.owner,spec.secured.milestone):return "Secure the "+spec.title+" before moving the rig."
		return ""
	if subject != "rail":return ""
	if attached_count()>0:return "Detach and stow the crane cables before moving the leg rail."
	if _installed() and not secured():return "Secure all four beam flange washer/bolt pairs before moving the leg rail."
	return ""

func access_error(subject: String) -> String:
	if subject == load_owner and not motion.is_empty():return "Wait for the crane to stop at the connection before fastening."
	return ""

func drop() -> Dictionary:
	if hand_payload().is_empty() and not console.is_open:return {"handled":false,"error":""}
	return {"handled":true,"error":cancel_hand()}

func _beam_undo_error() -> String:
	if raised or not motion.is_empty() or station != "receiver" or attached_count()!=required_ends:return "Keep all required magnets engaged with the crane down before undoing seating."
	if hardware_count()>0:return "Undo all of this connection’s retaining hardware before lifting the component."
	if config.spec.has("source_equipment"):return game.equipment.get_equipment(config.spec.source_equipment).reacquire_error(uid)
	if config.spec.get("receiver_equipment","")=="module_supports":return game.equipment.get_equipment("module_supports").reacquire_error(uid)
	return ""

func undo(subject: String) -> Dictionary:
	return _journey_undo(subject)

func _undo_beam() -> String:
	if not receiver_support.is_empty():return _transfer(receiver_support,support)
	var previous: Transform3D=load_body.global_transform
	var result: Dictionary = game.model.undo_supported(load_owner,support)
	if not result.ok:return result.error
	if assembly_payload:load_body.reparent(game);load_body.global_transform=previous
	else:game.components.sync(load_owner)
	game.refresh_assembly_collision(load_owner)
	return ""

func _crane_owned(model: AssemblyModel = null) -> bool:
	return _record(model).location == "support:"+support

func _path(at: String, up: bool, action: String, p: float) -> float:
	var high=float(route.size()-3);var seat=float(route.size()-1)
	var start = (1.0 if up else 0.0) if at == "source" else (high if up else seat)
	if at == "park":start = 0
	if action == "up":return lerpf(0,1,clampf((p-.1)/.9,0,1)) if at == "source" else lerpf(seat,high,clampf((p-.1)/.9,0,1) if config.spec.get("receiver_contact",false) else p)
	if action == "down":return lerpf(1,0,minf(1,p/.9) if config.spec.has("source_equipment") else p) if at == "source" else lerpf(high,seat,minf(1,p/.9) if config.spec.get("receiver_contact",false) else p)
	if action.begins_with("go:"):return lerpf(start,1 if action == "go:source" else high,p)
	return start

func load_pose(at: float = -1.0) -> Transform3D:
	if at<0 and _guide()!=null and _guide().active:return _guide().load_pose()
	var value = path if at < 0 else at
	if at < 0 and not _crane_owned() and not (motion == "up" and attached_count()==required_ends):
		if assembly_payload:return load_body.global_transform
		return receiver_pose if _installed() else source_pose
	if value >= route.size()-1:return route.back()
	var segment = clampi(floori(value),0,route.size()-2)
	return route[segment].interpolate_with(route[segment+1],value-segment)

func point_position(id: String) -> Vector3:
	return load_pose()*points[POINT_IDS.find(id)]

func _end_transform(frame: Transform3D,index: int) -> Transform3D:
	if config.spec.has("rig_adapter") and game.equipment.get_equipment(config.spec.rig_adapter).has_method("end_transform"):return game.equipment.get_equipment(config.spec.rig_adapter).end_transform(frame,index)
	if _guide()!=null and _guide().has_method("end_transform"):return _guide().end_transform(frame,index)
	if config.spec.has("magnetic_normal"):
		return Transform3D(frame.basis,frame*(points[index]+AssemblyRuntime.vec(config.spec.magnetic_normal)*.045))
	return Transform3D(Basis.IDENTITY,frame*points[index])

func _cable_position(frame: Transform3D,index: int) -> Vector3:
	if config.spec.has("rig_adapter") and game.equipment.get_equipment(config.spec.rig_adapter).has_method("cable_position"):return game.equipment.get_equipment(config.spec.rig_adapter).cable_position(frame,index)
	if _guide()!=null and _guide().has_method("cable_position"):return _guide().cable_position(frame,index)
	return frame*(points[index]+AssemblyRuntime.vec(config.spec.get("magnetic_normal",[0,0,0]))*.09)

func handle_position(id: String) -> Vector3:
	return load_pose()*AssemblyRuntime.vec(config.spec.handle_points[id]) if config.spec.get("handle_points",{}).has(id) else point_position(id)

func _station_beam(at: String, up: bool) -> Transform3D:
	if at=="receiver" and _guide()!=null and _guide().active:return _guide().beam_pose().translated(Vector3.UP*(.2 if up else 0))
	if config.spec.has("rig_clearance") and at!="park":return _load_beam(load_pose(_path(at,up,"",0)))
	var origin = source_pose.origin if at == "source" else receiver_pose.origin+(approach_offset if up else Vector3.ZERO)
	if at == "park":origin = park_position
	origin.y = up_y if up else (source_pose.origin.y+.80 if at == "source" else receiver_pose.origin.y+.88)
	return Transform3D(Basis.IDENTITY,origin)

func _beam_at(at: String, up: bool, action: String, p: float) -> Transform3D:
	if travel_from != null and action.begins_with("go:"):return travel_from.interpolate_with(_station_beam(action.get_slice(":",1),true),p)
	if at=="receiver" and _guide()!=null and _guide().active and not action.begins_with("go:"):
		var lift=.2*p if action=="up" else .2*(1-p) if action=="down" else .2 if up else 0.0
		return _guide().beam_pose().translated(Vector3.UP*lift)
	if config.spec.has("rig_clearance") and at!="park" and action!="go:park":return _load_beam(load_pose(_path(at,up,action,p)))
	var from = _station_beam(at,up)
	if action.begins_with("go:"):return from.interpolate_with(_station_beam(action.get_slice(":",1),true),p)
	if action == "up" or action == "down":
		if at == "receiver":return Transform3D(Basis.IDENTITY,load_pose(_path(at,up,action,p)).origin+Vector3(0,.88,0))
		if action == "up":
			if p < .1:return _station_beam(at,false).translated(Vector3(0,.08*p/.1,0))
			from.origin.y += .08
			return from.interpolate_with(_station_beam(at,true),(p-.1)/.9)
		return from.interpolate_with(_station_beam(at,false),p)
	return from

func _load_beam(frame: Transform3D) -> Transform3D:
	if config.spec.has("rig_adapter"):
		var adapter=game.equipment.get_equipment(config.spec.rig_adapter)
		if adapter!=null and adapter.has_method("beam_for_load"):return adapter.beam_for_load(frame)
	var center=Vector3.ZERO;var top=-INF
	for point in points:
		var world: Vector3=frame*point;center+=world;top=maxf(top,world.y)
	center/=points.size();center.y=top+float(config.spec.rig_clearance)
	center+=frame.basis*AssemblyRuntime.vec(config.spec.get("rig_center_offset",[0,0,0]))
	if config.spec.has("rig_min_height"):center.y=maxf(center.y,frame.origin.y+float(config.spec.rig_min_height))
	return Transform3D(Basis.IDENTITY,center)

func _beam_pose() -> Transform3D:
	return _beam_at(station,raised,motion,progress)

func physics(delta: float) -> void:
	console.physics()
	if game.paused:return
	if moving:
		motion_obstruction = {}
		var next = minf(1,progress+delta/5.0)
		if attached_count()==required_ends:
			if config.spec.has("access_mode"):
				var access=game.equipment.get_equipment("workshop_access")
				if not access.ready_for(config.spec.access_mode):
					if not access.moving:
						var access_error: String=access.request_mode(config.spec.access_mode)
						if not access_error.is_empty():blocked_reason=access_error;moving=false
					return
			if station=="source" and config.spec.has("source_equipment") and motion in ["up","down"]:
				var release=clampf(next/.1,0,1) if motion=="up" else 1-clampf((next-.9)/.1,0,1)
				var contact_error: String=game.equipment.get_equipment(config.spec.source_equipment).source_contact(release,uid)
				if not contact_error.is_empty():blocked_reason=contact_error;moving=false;return
			if station=="receiver" and config.spec.get("receiver_contact",false) and motion in ["up","down"]:
				var value=clampf(next/.1,0,1) if motion=="up" else 1-clampf((next-.9)/.1,0,1)
				var contact_error: String=game.equipment.get_equipment(config.spec.receiver_equipment).source_contact(value,uid)
				if not contact_error.is_empty():blocked_reason=contact_error;moving=false;return
			var ahead = EquipmentRegistry.Motion.path_ahead(route,path,_path(station,raised,motion,1.0),_path(station,raised,motion,next),float(config.spec.get("sweep_radius",4)))
			var error = _route_error(path,ahead)
			if not error.is_empty():blocked_reason = error;_refresh();return
			if motion=="up" and station=="receiver" and config.spec.get("receiver_contact",false) and next>=.1 and not _crane_owned():
				error=_undo_beam()
				if not error.is_empty():blocked_reason=error;moving=false;return
			if motion == "up" and station == "source" and next >= .1 and not _crane_owned():
				error = _transfer(source_support,support)
				if not error.is_empty():blocked_reason = error;moving = false;return
		progress = next;blocked_reason = ""
		if progress >= 1:
			if motion == "down" and _crane_owned():
				if station == "source":
					if assembly_payload:load_body.global_transform=source_pose
					var error: String = _transfer(support,source_support)
					if not error.is_empty():blocked_reason = error;moving = false;return
				else:
					var error=_seat()
					if not error.is_empty():blocked_reason=error;moving=false;return
					if config.spec.get("restore_access",false):game.equipment.get_equipment("workshop_access").request_mode("work")
			if motion.begins_with("go:"):station = motion.get_slice(":",1);travel_from = null
			else:raised = motion == "up"
			motion = "";progress = 0;moving = false
	_refresh()

func _route_error(from_path: float, destination: float) -> String:
	var cursor = from_path
	var direction = 1 if destination>from_path else -1
	while absf(cursor-destination)>.0001:
		var next = minf(destination,floorf(cursor+.0001)+1) if direction>0 else maxf(destination,ceilf(cursor-.0001)-1)
		var error = _sweep(load_pose(cursor),load_pose(next))
		if not error.is_empty():return error
		cursor = next
	return ""

func _sweep(from: Transform3D, to: Transform3D) -> String:
	var ignored: Array[RID] = excluded.duplicate();ignored.append(load_body.get_rid())
	var mating_body: CollisionObject3D
	# Receiver contact shapes and its prepared geometry are authored mating surfaces.
	# Other scenery and people remain swept obstacles throughout the route.
	Sweep.collect_rids(load_body,ignored)
	if receiver_support.is_empty():
		if assembly_payload:
			if not config.spec.get("exact_receiver",false):mating_body = game.runtime.node(load_owner)
		else:Sweep.collect_rids(game.runtime.node(load_owner),ignored)
	else:
		var receiver=game.equipment.get_equipment(config.spec.receiver_equipment)
		ignored.append_array(receiver.hardware)
	if config.spec.has("source_equipment"):ignored.append_array(game.equipment.get_equipment(config.spec.source_equipment).hardware)
	var solids: Array[Dictionary]=[]
	if assembly_payload:Sweep.collect_shapes(load_body,load_body.global_transform.affine_inverse(),solids)
	else:solids=Sweep.body_shapes(load_body)
	if config.spec.has("rig_adapter"):solids.append_array(game.equipment.get_equipment(config.spec.rig_adapter).transport_shapes())
	var group = {"shapes":solids,"margin":.001}
	var groups=[group]
	if config.spec.has("rig_adapter"):
		var adapter=game.equipment.get_equipment(config.spec.rig_adapter)
		if adapter.has_method("sweep_exclusions"):ignored.append_array(adapter.sweep_exclusions(from,to))
		ignored.append_array(game.leg_layout.blockout.rids_for_groups(["crane_bridge"]))
		groups.append({"shapes_at":func(frame: Transform3D,_p: float)->Array:return adapter.rig_solids(frame,0),"margin":.001})
	elif config.spec.get("sweep_rig",false):
		ignored.append_array(game.leg_layout.blockout.rids_for_groups(["crane_bridge"]))
		groups.append({"shapes_at":func(frame: Transform3D,_p: float)->Array:return rig_solids(frame),"margin":.001})
	# Evaluate intentional receiver contact at each sampled pose. A look-ahead
	# starting outside the mating zone must not reject permitted contact inside it.
	var contacts = func(frame: Transform3D) -> Array[RID]:
		var result: Array[RID] = ignored.duplicate()
		if mating_body != null and frame.origin.distance_to(receiver_pose.origin)<.30:result.append(mating_body.get_rid())
		return result
	return EquipmentRegistry.Motion.sweep(self,groups,Sweep.steps(from,to,float(config.spec.get("sweep_radius",4)),.04),func(weight: float) -> Transform3D:return from.interpolate_with(to,weight),ignored,EquipmentRegistry.Motion.ALL,contacts if mating_body != null else Callable()).get("error","")

func rig_solids(frame: Transform3D,head_offset: Vector3=Vector3.ZERO) -> Array[Dictionary]:
	# Same authored anchors, beam dimensions, magnetic connectors and cable widths as
	# the visible rig. Used for whole-load preflight and loaded transport sweeps.
	var head=_load_beam(frame).translated(head_offset)
	var low=Vector3(INF,INF,INF);var high=-low
	for at in config.spec.spreader_points:
		var anchor=AssemblyRuntime.vec(at);low=low.min(anchor);high=high.max(anchor)
	var bar=BoxShape3D.new();bar.size=Vector3(high.x-low.x+.28,.18,high.z-low.z+.34)
	var result: Array[Dictionary]=[{"shape":bar,"world":head,"rig_kind":"bar"}]
	var pairs=[[head.origin,Vector3(head.origin.x,config.spec.overhead_y,head.origin.z),.035]]
	for i in range(points.size()):
		var anchor=head*AssemblyRuntime.vec(config.spec.spreader_points[i])
		var contact=_cable_position(frame,i)
		pairs.append([anchor,contact,.025])
		var end=BoxShape3D.new();end.size=Vector3(.12,.09,.12)
		result.append({"shape":end,"world":_end_transform(frame,i),"rig_kind":"contact"})
	for pair in pairs:
		var direction: Vector3=pair[1]-pair[0]
		var shape=BoxShape3D.new();shape.size=Vector3(pair[2],maxf(.001,direction.length()),pair[2])
		result.append({"shape":shape,"world":Transform3D(Basis(Quaternion(Vector3.UP,direction.normalized())),(pair[0]+pair[1])/2),"rig_kind":"line","from":pair[0],"to":pair[1]})
	return result

func _line(mesh: MeshInstance3D, from: Vector3, to: Vector3, width: float) -> void:
	var direction = to-from;var length = direction.length()
	mesh.global_position = (from+to)*.5
	mesh.global_basis = Basis(Quaternion(Vector3.UP,direction.normalized())) if length>.0001 else Basis.IDENTITY
	mesh.scale = Vector3(width,maxf(.001,length),width)

func _refresh() -> void:
	if not is_instance_valid(load_body):return
	for spec in tasks.values():
		if spec.load_uid == uid:continue
		var body: AnimatableBody3D = stock_bodies[spec.load_uid]
		if spec.get("payload","")=="assembly":continue
		var at_source = _record(game.model,spec.load_uid).location == "support:"+spec.source_support
		body.visible = at_source;body.collision_layer = 2 if at_source else 0
		body.global_transform = preload("res://scripts/leg_bay_layout.gd").authored_pose(spec.source_pose)
		body.force_update_transform();PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	var installed = _installed()
	if not assembly_payload:
		load_body.visible = not installed;load_body.collision_layer = 0 if installed else 2
	if not assembly_payload or _crane_owned():load_body.global_transform = load_pose()
	load_body.force_update_transform();PhysicsServer3D.body_set_state(load_body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,load_body.global_transform)
	if assembly_payload:
		for owner in game.runtime.descendants(uid):
			var body: CollisionObject3D=game.runtime.node(owner)
			body.force_update_transform();PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	beam.global_transform = _beam_pose()
	for id in end_nodes:end_nodes[id].visible=id in END_IDS;cables[id].visible=id in END_IDS
	for id in markers:markers[id].visible=false
	for index in range(required_ends):
		var id: String = END_IDS[index]
		var end: Dictionary = endpoints[id]
		# Cable trolleys align over the selected marked point, so either stable
		# endpoint can use either point without crossing the other load cable.
		var anchor_index = POINT_IDS.find(end.point) if end.state == "attached" else index
		var anchor = beam.global_position+Vector3(points[anchor_index].x,0,points[anchor_index].y)
		if config.spec.has("rig_clearance"):
			var center=Vector3.ZERO
			for point in points:center+=point
			var offset: Vector3=load_pose(_path(station,raised,motion,progress)).basis*(points[anchor_index]-center/points.size())
			if config.spec.has("spreader_points"):offset=AssemblyRuntime.vec(config.spec.spreader_points[anchor_index])
			if _guide()!=null and _guide().active and _guide().spec.get("rig",{}).has("aft_anchors"):offset=offset.lerp(AssemblyRuntime.vec(_guide().spec.rig.aft_anchors[anchor_index]),_guide().rig)
			anchor=beam.global_position+Vector3(offset.x,0,offset.z)
		var point = anchor-Vector3(0,.55,0)
		if end.state == "held":point = game.camera.global_transform*Vector3(0,0,-.65)
		elif end.state == "attached":point = _cable_position(load_pose(),POINT_IDS.find(end.point))
		end_nodes[id].global_transform = _end_transform(load_pose(),POINT_IDS.find(end.point)) if end.state=="attached" and config.spec.has("magnetic_normal") else Transform3D(Basis.IDENTITY,handle_position(end.point) if end.state=="attached" else point)
		_line(cables[id],anchor,point,1)
		markers[POINT_IDS[index]].global_position = handle_position(POINT_IDS[index])+Vector3(0,.008,0)
		markers[POINT_IDS[index]].scale=Vector3(1,15,.07) if config.spec.has("handle_points") else Vector3.ONE
		markers[POINT_IDS[index]].visible = not raised and motion.is_empty() and station != "park" and not hand_payload().is_empty()
	var eye = beam.global_position+Vector3(0,0,0 if config.spec.has("rig_clearance") else rig_center)
	var overhead: float=config.spec.get("overhead_y",20.6)
	if layout.has_method("set_crane_anchor"):layout.set_crane_anchor(Vector3(eye.x,overhead,eye.z))
	_line(mast_cable,eye,Vector3(eye.x,overhead,eye.z),1)
	if is_instance_valid(physical_status):physical_status.text = status_text()
	if is_instance_valid(console):console.refresh()
	if config.spec.has("rig_adapter"):
		var adapter=game.equipment.get_equipment(config.spec.rig_adapter)
		if adapter!=null:adapter.refresh_rig()
	if _guide()!=null and _guide().has_method("rig_changed"):_guide().rig_changed()
	changed.emit()

func status_text() -> String:
	var label: String = ("To "+_station_title(motion.get_slice(":",1)) if motion.begins_with("go:") else _station_title(station))+" · "+("Up" if raised else "Down")
	if not motion.is_empty():label += " · "+("Moving" if moving else "Stopped")
	if attached_count()>0:label += "\nMagnetic ends attached: %d/%d"%[attached_count(),required_ends]
	if _installed() and not receiver_support.is_empty():label+="\nReceiving support has taken the load."
	elif _installed():label += ("\nConnection retention: %d/%d")%[hardware_count(),fastener_slots.size()]
	if not blocked_reason.is_empty():label += "\n"+blocked_reason
	return label

## Console header: the load being carried, or the next one to collect.
func load_text() -> String:
	if _crane_owned():return "Carrying: "+_load_title(task)
	if attached_count()>0:return "Rigged: "+_load_title(task)
	var next: String = next_route()
	return "Next pickup: "+_load_title(next) if not next.is_empty() else "No load waiting"

## Why the next pickup cannot start yet, while the empty crane waits.
func next_hint() -> String:
	if not raised or not motion.is_empty() or not _empty():return ""
	var next: String = next_route()
	return "" if next.is_empty() or next == reacquire else _ready_error(next)

## The route an empty crane serves: a requested reacquire, otherwise the first
## route in crane.order whose load still waits at its source.
func next_route() -> String:
	if reacquire in tasks:return reacquire
	for key in Layout.layout().crane.get("order",tasks.keys()):
		if _waiting(key):return key
	return ""

## An undo reacquires its load where it is installed; other pickups are at the source.
func _pickup_role(key: String) -> String:
	return "receiver" if not key.is_empty() and key == reacquire else "source"

func _load_title(key: String) -> String:
	var id: String = tasks[key].load_uid
	return game.runtime.definition(id).get("title",tasks[key].title) if game.model.assemblies.has(id) else tasks[key].title

func _select_route(key: String) -> void:
	task = key;config = layout.crane_contract(task)
	_configure_task(config);_configure_rig_bar();load_body = _stock_body(uid)

## Place holding a route's source or receiver, named for the console.
func place_of(role: String, key: String = "") -> String:
	if role == "park":return "park"
	var spec: Dictionary = config.spec if key.is_empty() else tasks[key]
	var receiver: String = spec.get("receiver_support","")
	if receiver.is_empty():receiver = spec.get("guided_receiver",spec.owner)
	return Layout.crane_place(spec.source_support if role == "source" else receiver)

func _empty() -> bool:
	return attached_count()==0 and hand_payload().is_empty() and not _crane_owned()

func _waiting(key: String) -> bool:
	return _record(game.model,tasks[key].load_uid).location == "support:"+tasks[key].source_support

## Why a route cannot start now: its receiver, the connection's prerequisites,
## then its source equipment (the arm cassette must be at the station).
func _ready_error(key: String) -> String:
	var spec: Dictionary = tasks[key]
	var error: String = _receiver_error(spec)
	if error.is_empty() and spec.get("receiver_support","").is_empty() and not spec.has("guided_receiver") and not spec.slot.is_empty():
		for required in game.model.slot_definition(spec.owner,spec.slot).get("requires",[]):
			if game.model.assemblies[spec.owner].slots[required].is_empty():
				var dependency: Dictionary = game.model.slot_definition(spec.owner,required)
				error = "Fit the "+dependency.get("label",required.replace("_"," "))+" before collecting the "+_load_title(key).to_lower()+".";break
	if error.is_empty() and spec.has("source_equipment"):error = game.equipment.get_equipment(spec.source_equipment).source_error(spec.load_uid)
	return error

func capture() -> Dictionary:
	var result = {"version":VERSION,"station":station,"raised":raised,"motion":motion,"progress":progress,"moving":moving,"blocked_reason":blocked_reason,"endpoints":endpoints.duplicate(true)}
	result["task"] = task
	result["reacquire"] = reacquire
	result["travel_from"] = Codec.pose(travel_from) if travel_from != null else []
	return result

## Pickups and transfers happen partway through a move, so a save keeps the crane
## where it is, stopped; Resume continues.
func saves_in_motion() -> bool:return true

func validate(data: Variant, candidate: AssemblyModel = null, _world: Dictionary = {}) -> Array[String]:
	if not data is Dictionary or data.size()!=9:return ["Incomplete crane state."]
	if not data.get("task") is String or data.task not in tasks:return ["Unknown saved crane task."]
	if data.task != task:return _validate_other_task(data,candidate,_world)
	if not (data.get("version") is int or data.get("version") is float) or data.version!=VERSION:return ["Unsupported crane version."]
	for field in ["station","motion","blocked_reason"]:
		if not data.get(field) is String:return ["Invalid crane text field."]
	if data.station not in STATIONS or data.motion not in ["","up","down","go:source","go:receiver","go:park"]:return ["Unknown crane route."]
	if not data.get("raised") is bool or not data.get("moving") is bool:return ["Invalid crane flags."]
	if not (data.get("progress") is float or data.get("progress") is int) or not is_finite(data.progress) or data.progress<0 or data.progress>1:return ["Invalid crane progress."]
	if data.motion.is_empty() and (data.moving or data.progress!=0):return ["Idle crane has motion progress."]
	if data.motion=="up" and data.raised or data.motion=="down" and not data.raised:return ["Invalid crane elevation transition."]
	if data.motion.begins_with("go:") and (not data.raised or data.motion.get_slice(":",1)==data.station):return ["Crane travel requires Up and a different location."]
	if data.station=="park" and (not data.raised or data.motion in ["up","down"]):return ["Crane must remain raised at parking."]
	if not data.get("endpoints") is Dictionary or data.endpoints.size()!=required_ends:return ["Invalid cable ends."]
	var count = 0;var held = 0;var occupied: Array = []
	for id in END_IDS:
		var end = data.endpoints.get(id)
		if not end is Dictionary or end.size()!=2 or not end.get("state") is String or not end.get("point") is String:return ["Invalid magnetic connector fields."]
		if end.state not in ["stowed","held","attached"]:return ["Invalid magnetic connector state."]
		if end.state == "attached":
			if end.point not in POINT_IDS or end.point in occupied:return ["Invalid or occupied magnetic point."]
			if config.spec.get("point_ends",{}).has(end.point) and config.spec.point_ends[end.point]!=id:return ["Crane endpoint has the wrong lifting adapter."]
			count += 1;occupied.append(end.point)
		elif not end.point.is_empty():return ["Detached magnet retains a point."]
		if end.state == "held":held += 1
	var model: AssemblyModel = game.model if candidate==null else candidate
	if held>1 or held>0 and model.hands_occupied():return ["Conflicting hand payloads."]
	if _guide()!=null:
		var guide_state: Dictionary=_world.get("equipment",{}).get(config.spec.guided_receiver,_guide().capture())
		if guide_state.get("active",_guide().active) and data.station=="receiver" and not data.raised and data.motion.is_empty():
			var guide_errors: Array[String]=_guide().validate_crane(data,model,guide_state)
			return guide_errors if not guide_errors.is_empty() else _inactive_errors(model,uid)

	if (data.raised or not data.motion.is_empty()) and (held>0 or count>0 and count!=required_ends):return ["Crane moved with incomplete magnetic connectors."]
	var item: Dictionary = _record(model)
	var rack = item.location == "support:"+source_support
	var carried = _crane_owned(model)
	var installed = _installed(model)
	var delivered: bool=assembly_payload and item.parent==config.spec.get("follow_owner","__none__")
	if not rack and not carried and not installed and not delivered and not (assembly_payload and count==0 and _declared_assembly_support(uid,model)):return ["Unsupported crane load owner."]
	if delivered and count>0:return ["Transferred assembly is no longer at the crane receiver."]
	if hardware_count(model)>0 and not installed:return ["Hardware has no installed beam."]
	var secure=secured(model)
	if _guide()!=null:secure=installed and _guide().retained(_world.get("equipment",{}).get(config.spec.guided_receiver,_guide().capture()),model)
	if _world.has("equipment") and config.spec.get("receiver_equipment","") in ["module_supports","arm_cassette"]:
		var receiver_id: String=config.spec.receiver_equipment
		secure=game.equipment.get_equipment(receiver_id).support_secured(uid,model,_world.equipment[receiver_id])
	if installed and count<required_ends and not secure:return ["Unsecured connection lost its magnets."]
	if count>0 and data.station=="park" or data.motion=="go:park" and count>0:return ["Loaded crane cannot park."]
	if count>0 and rack and (data.station!="source" or data.raised or data.motion not in ["","up"] or data.progress>=.1):return ["Rack ownership contradicts crane movement."]
	if count>0 and installed and (data.station!="receiver" or data.raised or not data.motion.is_empty()) and not (config.spec.get("receiver_contact",false) and data.station=="receiver" and not data.raised and data.motion=="up" and data.progress<.1):return ["Installed beam cannot travel with crane."]
	if carried:
		if count!=required_ends or data.station=="park":return ["Suspended load lacks magnetic connectors."]
		if not data.raised and data.motion!="up":return ["Suspended beam has no lifting motion."]
		if data.station=="source" and data.motion=="up" and data.progress<.1:return ["Crane took source ownership before taking weight."]
	var inactive=_inactive_errors(model,uid)
	if not inactive.is_empty():return inactive
	if count > 0 and installed and _world.has("equipment") and receiver_support.is_empty() and not assembly_payload:
		var rail: Dictionary = _world.equipment.leg_rail
		if rail.path != 0 or rail.moving or not rail.engaged:return ["Attached crane task requires the engaged rail home."]
	if assembly_payload and carried and _world.has("fixtures"):
		if not preload("res://scripts/pose_codec.gd").to_pose(_world.fixtures[uid]).is_equal_approx(load_pose(_path(data.station,data.raised,data.motion,data.progress))):return ["Suspended assembly pose disagrees with its crane route."]
	if not receiver_support.is_empty() and count>0 and installed and _world.has("equipment"):
		if config.spec.receiver_equipment=="foot_carrier":
			var carrier: Dictionary=_world.equipment[config.spec.receiver_equipment]
			if carrier.path!=0 or carrier.withdrawal!=0 or carrier.moving or not carrier.handoff.is_empty():return ["Attached crane requires the receiving carrier stopped at dispatch."]
	return []

func _inactive_errors(model: AssemblyModel, active_uid: String) -> Array[String]:
	for key in tasks:
		var spec: Dictionary = tasks[key]
		if spec.load_uid == active_uid:continue
		var other: Dictionary = _record(model,spec.load_uid)
		if spec.get("payload","")=="assembly":
			if _declared_assembly_support(spec.load_uid,model):continue
			return ["Inactive crane assembly has no declared support."]
		if other.location == "installed":
			if other.owner != spec.owner or other.slot != spec.slot or not model.milestone(spec.owner,spec.secured.milestone):return ["Inactive crane task has unsecured work."]
		elif other.location != "support:"+spec.source_support:return ["Inactive crane load is off its rig."]
	return []

func _declared_assembly_support(identity: String, model: AssemblyModel) -> bool:
	var record: Dictionary=model.assemblies[identity]
	for entry in tasks.values():
		if entry.load_uid!=identity:continue
		if record.location=="support:"+entry.source_support or record.location=="support:"+entry.get("receiver_support",""):return true
		if record.parent==entry.get("follow_owner","__none__"):return true
		if not entry.slot.is_empty() and record.parent==entry.owner and record.parent_slot==entry.slot and model.milestone(entry.owner,entry.secured.milestone):return true
	return false

func placement_error(owner: String, sid: String) -> String:
	var spec: Dictionary=game.model.slot_definition(owner,sid)
	if spec.get("requires_crane_clear","")==uid and (attached_count()>0 or not hand_payload().is_empty()):return "Release and stow all crane shoes before connecting the chest services."
	return ""

func apply(data: Dictionary) -> void:
	motion_obstruction = {}
	if data.task != task:_select_route(data.task)
	station = data.station;raised = data.raised;motion = data.motion;progress = float(data.progress);moving = data.moving;blocked_reason = data.blocked_reason;endpoints = data.endpoints.duplicate(true)
	# A reload starts with empty hands: an end being carried goes back to its stow.
	for id in endpoints:
		if endpoints[id].state == "held":endpoints[id] = {"state":"stowed","point":""}
	reacquire = data.get("reacquire","")
	travel_from = Codec.to_pose(data.travel_from) if not data.get("travel_from",[]).is_empty() else null
	if console.is_open:console.shut()
	_refresh()

func _station_title(at: String) -> String:
	if at == "park":return TITLES[at]
	return Layout.place_title(place_of(at))

## Whether a route's receiver accepts its load now; the active route by default.
func _receiver_error(route: Dictionary = {}) -> String:
	var live = route.is_empty()
	var spec: Dictionary = config.spec if live else route
	var id: String = spec.load_uid;var receiving: String = spec.get("receiver_support","")
	var guide: Node = game.equipment.get_equipment(spec.guided_receiver) if spec.has("guided_receiver") else null
	if guide!=null:return guide.receiving_error(id)
	if spec.get("receiver_equipment","")=="module_supports":return game.equipment.get_equipment("module_supports").receiving_error(id,receiving)
	if not receiving.is_empty():
		var receiver=game.equipment.get_equipment(spec.receiver_equipment)
		if receiver.has_method("receiving_error"):return receiver.receiving_error(id)
		if live and _installed():return "" if receiver.path==0 and receiver.withdrawal==0 and not receiver.moving else "Return the receiving carrier to dispatch first."
		return "" if receiver.can_receive(id) else "Return the empty foot rig to dispatch, extend its sole pads and select the matching leg on the leg rig."
	var rail = game.equipment.get_equipment("leg_rail")
	if rail == null or rail.path > .0001 or rail.moving or not rail.engaged:return "Return the engaged leg rig home before crane delivery or reacquisition."
	if rail.has_method("can_construct") and not rail.can_construct():return "Return the leg rig to the Limb Bay and lock neutral roll before crane delivery."
	if rail.has_method("can_construct") and rail.active_assembly!=spec.owner:return "Select the "+spec.owner.replace("_"," ")+" build on the clear leg rig first."
	return ""

func _journey_undo(subject: String) -> Dictionary:
	if not game.model.assemblies.has(subject):return {"handled":false,"error":""}
	var history: Array = game.model.assemblies[subject].history
	if history.is_empty():return {"handled":false,"error":""}
	var sid: String = history.back().slot
	var spec: Dictionary = game.model.slot_definition(subject,sid)
	if spec.get("undo_requires_support","") != support:return {"handled":false,"error":""}
	var active_security: Array = game.leg_content.robot.security_slots.get(task,[])
	if subject!=load_owner or sid not in active_security:
		for key in tasks:
			if tasks[key].owner==subject and sid in game.leg_content.robot.security_slots.get(key,[]):reacquire = key
		return {"handled":true,"error":"Move the empty crane to pickup and attach its lifting ends before undoing this connection."}
	if attached_count()!=required_ends or raised or not motion.is_empty() or station != "receiver" or not _receiver_error().is_empty():return {"handled":true,"error":"Lower the matching crane at this connection and attach all required lifting ends before removing retention hardware."}
	if assembly_payload and game.model.assemblies[uid].slots.values().any(func(value):return not value.is_empty()):return {"handled":true,"error":"Remove dependent construction before undoing this module’s structural retention."}
	if sid == slot:return {"handled":true,"error":"Use Up at the crane console to lift the unfastened component from its seat."}
	return {"handled":false,"error":""}

func _validate_other_task(data: Dictionary, candidate: AssemblyModel, world: Dictionary) -> Array[String]:
	# A detached validator uses the candidate task contract; it never changes
	# live meshes/endpoints/selected task while rejecting a save.
	var probe = get_script().new()
	probe.game = game;probe.layout = layout;probe.tasks = tasks;probe.task = data.task
	probe._configure_task(layout.crane_contract(data.task))
	var errors: Array[String] = probe.validate(data,candidate,world)
	probe.free()
	return errors

func _configure_rig_bar() -> void:
	if not is_instance_valid(rig_bar):return
	rig_bar.visible=true
	for end in end_nodes.values():end.mesh.size=Vector3(.12,.09,.12)
	if config.spec.has("rig_clearance"):
		var frame=source_pose;var low=Vector3(INF,INF,INF);var high=-low
		var spread: Array=points
		if config.spec.has("spreader_points"):
			spread=[]
			for point in config.spec.spreader_points:spread.append(AssemblyRuntime.vec(point))
		for point in spread:
			var world: Vector3=frame*point;low=low.min(world);high=high.max(world)
		rig_center=0;rig_bar.position=Vector3.ZERO
		var mesh=BoxMesh.new();mesh.size=Vector3(high.x-low.x+.28,.18,high.z-low.z+.34);rig_bar.mesh=mesh
		return
	var min_z = minf(points[0].y,points[1].y)
	var max_z = maxf(points[0].y,points[1].y)
	rig_center = (min_z+max_z)/2
	rig_bar.position = Vector3(0,0,rig_center)
	# Each selected task has its own supported two-point spread. Fork magnets
	# span across X; shin/beam magnets span along the load's canonical length.
	var mesh = BoxMesh.new();mesh.size = Vector3(absf(points[0].x-points[1].x)+.28,.18,max_z-min_z+.34)
	rig_bar.mesh = mesh
