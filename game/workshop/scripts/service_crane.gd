extends "res://scripts/equipment.gd"
## Canonical LG-120 handling. Robot inventory never owns a cable endpoint.
## Model ownership: rack -> crane -> leg. Assistance remains a contact, not an owner.
signal changed
const Console = preload("res://scripts/service_crane_console.gd")
const Sweep = preload("res://scripts/motion_sweep.gd")
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
const TITLES = {"source":"Upper-leg beam rack","receiver":"Leg cradle","park":"Parking bay"}
var up_y: float
var layout: Node3D
var config: Dictionary
var support = "m2_service_crane"
var source_support = "leg_spar_rack"
var uid = "LG-120__001"
var source_pose: Transform3D
var receiver_pose: Transform3D
var route: Array[Transform3D] = []
var excluded: Array[RID] = []
var station = "park"
var raised = true
var motion = ""
var progress = 0.0
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
var complete_journey = false

var assisting: bool:
	get:return _installed() and attached_count() > 0

func setup(workshop: Node3D, scene_layout: Node3D, contract: Dictionary = {}) -> void:
	game = workshop;layout = scene_layout;config = contract;equipment_id = "service_crane"
	hand_payload_hint = "Attach or Q-stow the held magnetic end first."
	hands_full_hint = "Stow the component or assembly in your hand before handling a magnetic end."
	support = contract.get("support",support);source_support = contract.get("source_support",source_support);uid = contract.get("uid",uid)
	var crane_spec: Dictionary = preload("res://scripts/leg_bay_layout.gd").layout().crane
	complete_journey = crane_spec.has("tasks")
	if complete_journey:tasks = crane_spec.tasks;task = crane_spec.task
	_configure_task(contract)
	_make_load();_make_rig();_make_console(contract.console_position)
	console = Console.new();add_child(console);console.setup(self)
	game.model.changed.connect(_refresh)
	_refresh()


func _configure_task(contract: Dictionary) -> void:
	var spec: Dictionary = contract.get("spec",preload("res://scripts/leg_bay_layout.gd").layout().crane)
	support = spec.support;source_support = spec.source_support;uid = spec.load_uid
	load_owner = spec.owner;slot = spec.slot;secured_milestone = spec.secured.milestone
	fastener_slots = game.runtime.definition(load_owner).milestones[secured_milestone].filter(func(sid):return sid != slot)
	END_IDS = spec.endpoint_ids.duplicate();POINT_IDS = spec.magnetic_points.keys();points.clear();endpoints.clear()
	for id in END_IDS:endpoints[id] = {"state":"stowed","point":""}
	for id in POINT_IDS:points.append(AssemblyRuntime.vec(spec.magnetic_points[id]))
	up_y = spec.up_y;park_position = AssemblyRuntime.vec(spec.park_position)
	approach_offset = -AssemblyRuntime.vec(spec.approach.axis)*spec.approach.distance
	source_pose = contract.source_pose;receiver_pose = contract.receiver_pose
	route.assign(contract.route);excluded.assign(contract.get("excluded",[]))

func _make_load() -> void:
	load_body = _stock_body(uid)
	if complete_journey:
		for spec in tasks.values():_stock_body(spec.load_uid)

func _stock_body(item_uid: String) -> AnimatableBody3D:
	if stock_bodies.has(item_uid):return stock_bodies[item_uid]
	var body = AnimatableBody3D.new();body.name = "CraneLoad_"+item_uid if complete_journey else "CraneUpperLegBeam"
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
	for index in range(2):
		var id: String = END_IDS[index]
		var end = game.box(self,Vector3.ZERO,Vector3(.12,.09,.12),steel);end.name = id;end_nodes[id] = end
		cables[id] = game.box(self,Vector3.ZERO,Vector3(.025,1,.025),dark)
		var marker = game.box(self,Vector3.ZERO,Vector3(.17,.012,.17),green);marker.name = POINT_IDS[index];markers[POINT_IDS[index]] = marker
	mast_cable = game.box(self,Vector3.ZERO,Vector3(.035,1,.035),dark)

func _make_console(at: Vector3) -> void:
	var dark = game.material(Color("263a43"),.4)
	var yellow = game.material(Color("e8b46b"),.2)
	game.box(self,at+Vector3(0,.48,0),Vector3(.18,.96,.18),dark,true)
	game.box(self,at+Vector3(0,.06,0),Vector3(.65,.12,.65),dark,true)
	console_node = game.box(self,at+Vector3(0,1.15,-.08),Vector3(.48,.40,.12),yellow)
	console_node.name = "CentralCraneConsole"
	game.sign_panel(self,"SERVICE CRANE\nE · control",at+Vector3(0,1.65,.03),Vector2(1.9,.45),42,.0025)
	physical_status = game.sign_panel(self,"",at+Vector3(0,2.24,.03),Vector2(3.7,.65),34,.002)
	physical_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;physical_status.width = 1650

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
		entries.append(control_entry(end_nodes[id],("detach:" if state == "attached" else "pick:")+id,("Detach" if state == "attached" else "Pick up")+" magnetic end · E",.16,{"point":end_nodes[id].global_position,"input":"pickup","allowed":[load_body,game.runtime.node(load_owner)],"allow_body_hit":true}))
	if not hand_payload().is_empty():
		for id in POINT_IDS:
			entries.append(control_entry(markers[id],"attach:"+id,"Attach magnetic end · click",.20,{"point":point_position(id),"input":"place","allowed":[load_body,game.runtime.node(load_owner)],"allow_body_hit":true}))
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

func menu_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if not motion.is_empty():
		options.append({"action":"stop" if moving else "resume","label":"Stop" if moving else "Resume"})
		return options
	if complete_journey and station == "park" and raised and attached_count() == 0 and hand_payload().is_empty():
		for key in tasks:
			if key != task:options.append({"action":"task:"+key,"label":"Select task: "+tasks[key].title})
	options.append({"action":"down" if raised else "up","label":"Down" if raised else "Up"})
	if raised:
		for destination in STATIONS:
			var action = "go:"+destination
			if action_error(action).is_empty():options.append({"action":action,"label":"Go to "+(_station_title(destination))})
	return options

func action_error(action: String) -> String:
	if game.paused:return "Resume the trial before operating the crane."
	if complete_journey and action.begins_with("task:"):
		if action.get_slice(":",1) not in tasks:return "Unknown crane task."
		if station != "park" or not raised or not motion.is_empty() or attached_count()>0 or not hand_payload().is_empty():return "Park the empty crane and stow both magnets before changing task."
		return ""
	if action == "open_console":return console_access_error()
	if action == "close_console":return ""
	if action == "stop":return "" if moving else "The crane is stopped."
	if action == "resume":return "" if not moving and not motion.is_empty() else "There is no stopped crane movement to resume."
	if action == "stow":return "" if not hand_payload().is_empty() else "You are not holding a magnetic end."
	if action.begins_with("pick:") or action.begins_with("detach:"):
		var id = action.get_slice(":",1)
		if not END_IDS.has(id):return "Unknown magnetic end."
		if raised or not motion.is_empty() or station == "park":return "Lower the crane at a work location before handling cable ends."
		if not hand_payload().is_empty():return "Attach or stow the end already in your hand."
		var error = game.hands.error(equipment_id)
		if not error.is_empty():return error
		if action.begins_with("pick:") and endpoints[id].state != "stowed":return "That magnetic end is already attached."
		if action.begins_with("detach:"):
			if endpoints[id].state != "attached":return "That magnetic end is not attached."
			if _installed() and not secured():return "Complete this connection’s retaining hardware before detaching a magnetic end." if complete_journey else "Fit all four flange washer/bolt pairs before detaching a magnetic end."
		return _interaction_error(end_nodes[id].global_position,[load_body,game.runtime.node(load_owner)])
	if action.begins_with("attach:"):
		var point = action.get_slice(":",1)
		if not POINT_IDS.has(point):return "Choose a marked magnetic attachment point."
		if hand_payload().is_empty():return "Pick up a magnetic end first."
		if raised or not motion.is_empty() or station == "park":return "Lower the crane at the beam before attaching ends."
		if _installed() and attached_count()==0 and not complete_journey:return "Released-beam disassembly is outside this M2 trial."
		if complete_journey and station == "receiver":
			var receiver_error = _receiver_error()
			if not receiver_error.is_empty():return receiver_error
		if (station == "source") != (game.model.items[uid].location == "support:"+source_support):return "The beam is at the other work location."
		for end in endpoints.values():
			if end.point == point:return "That point is occupied. Aim at the other marked point."
		return _interaction_error(point_position(point),[load_body,game.runtime.node(load_owner)])
	if not motion.is_empty():return "Finish or resume the current motion first."
	if not hand_payload().is_empty():return "Attach or Q-stow the held magnetic end first."
	if action == "up":
		if raised:return "The crane is already up."
		if attached_count()==1:return "Attach both magnetic ends, or detach the remaining end before raising."
		if attached_count()==2:
			if hardware_count()>0:return "Undo all of this connection’s retaining hardware before lifting the component." if complete_journey else "Undo every flange washer and bolt before lifting the beam."
			if _installed():return _beam_undo_error()
			if not game.model.support_occupant(support).is_empty():return "The crane support is occupied."
		return ""
	if action == "down":
		if complete_journey and station == "receiver":
			var receiver_error = _receiver_error()
			if not receiver_error.is_empty():return receiver_error
		if not raised:return "The crane is already down."
		if station == "park":return "Go to a work location before lowering."
		if _crane_owned():
			if station == "source" and not game.model.support_occupant(source_support).is_empty():return "The source rack is occupied."
			if station == "receiver":
				var error: String = game.model.placement_error(load_owner,slot,uid,support)
				if not error.is_empty():return error
		return ""
	if action.begins_with("go:"):
		var destination = action.get_slice(":",1)
		if destination not in STATIONS:return "Unknown crane location."
		if complete_journey and destination != "park":
			var rail_error = _receiver_error()
			if not rail_error.is_empty():return rail_error
		if not raised:return "Raise the crane before travelling to another location."
		if destination == station:return "The crane is already at this location."
		if _crane_owned():
			if destination == "park":return "Set the beam on its rack or receiving connection before parking."
			if destination == "source" and not game.model.support_occupant(source_support).is_empty():return "The source rack is occupied."
			if destination == "receiver" and not game.model.assemblies[load_owner].slots[slot].is_empty():return "The receiving connection is occupied."
		return ""
	return "Unknown crane command."

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():return error
	if complete_journey and action.begins_with("task:"):
		task = action.get_slice(":",1);config = layout.crane_contract(task)
		_configure_task(config);_configure_rig_bar()
		load_body = _stock_body(uid);_refresh();return ""
	if action == "open_console":return console.open()
	if action == "close_console":console.shut();return ""
	if action == "stop":moving = false
	elif action == "resume":moving = true;blocked_reason = ""
	elif action == "stow":endpoints[hand_payload()] = {"state":"stowed","point":""}
	elif action.begins_with("pick:") or action.begins_with("detach:"):endpoints[action.get_slice(":",1)] = {"state":"held","point":""}
	elif action.begins_with("attach:"):endpoints[hand_payload()] = {"state":"attached","point":action.get_slice(":",1)}
	else:
		if action == "up" and _installed() and attached_count()==2:
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
	return m.items[uid].location == "installed" and m.items[uid].owner == load_owner and m.items[uid].slot == slot and m.assemblies[load_owner].slots[slot] == uid

func hardware_count(model: AssemblyModel = null) -> int:
	var m: AssemblyModel = game.model if model == null else model
	var count = 0
	for sid in fastener_slots:
		if not m.assemblies[load_owner].slots[sid].is_empty():count += 1
	return count

func secured(model: AssemblyModel = null) -> bool:
	var m: AssemblyModel = game.model if model == null else model
	return _installed(m) and m.milestone(load_owner,secured_milestone)

func busy_reason(subject: String) -> String:
	if complete_journey and subject in ["rail","foot_transfer"]:
		if attached_count()>0 or not motion.is_empty() and _crane_owned():return "Stow the crane magnets and set the load down before moving the fixture."
		for key in tasks:
			var spec: Dictionary = tasks[key]
			if game.model.items[spec.load_uid].location == "installed" and not game.model.milestone(spec.owner,spec.secured.milestone):return "Secure the "+spec.title+" before moving the fixture."
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
	if raised or not motion.is_empty() or station != "receiver" or attached_count()!=2:return "Keep both magnets engaged with the crane down before undoing beam seating."
	if hardware_count()>0:return "Undo all of this connection’s retaining hardware before lifting the component." if complete_journey else "Undo every flange washer and bolt before lifting the beam."
	return ""

func undo(subject: String) -> Dictionary:
	if complete_journey:return _journey_undo(subject)
	if subject != load_owner:return {"handled":false,"error":""}
	var history: Array = game.model.assemblies[load_owner].history
	if history.is_empty():return {"handled":true,"error":"The supplied construction stays assembled."}
	if fastener_slots.has(history.back().slot):
		if attached_count()!=2 or not motion.is_empty():return {"handled":true,"error":"Keep both magnets engaged with the crane down before undoing flange hardware."}
		return {"handled":false,"error":""}
	if history.back().slot == slot:return {"handled":true,"error":"Use Up at the crane console to lift the unfastened beam from its seat."}
	return {"handled":true,"error":"The supplied construction stays assembled."}

func _undo_beam() -> String:
	var result: Dictionary = game.model.undo_supported(load_owner,support)
	if not result.ok:return result.error
	game.components.sync(load_owner);game.refresh_assembly_collision(load_owner)
	return ""

func _crane_owned(model: AssemblyModel = null) -> bool:
	return (game.model if model == null else model).items[uid].location == "support:"+support

static func _path(at: String, up: bool, action: String, p: float) -> float:
	var start = (1.0 if up else 0.0) if at == "source" else (2.0 if up else 4.0)
	if at == "park":start = 0
	if action == "up":return lerpf(0,1,clampf((p-.1)/.9,0,1)) if at == "source" else lerpf(4,2,p)
	if action == "down":return lerpf(1,0,p) if at == "source" else lerpf(2,4,p)
	if action.begins_with("go:"):return lerpf(start,1 if action == "go:source" else 2,p)
	return start

func load_pose(at: float = -1.0) -> Transform3D:
	var value = path if at < 0 else at
	if at < 0 and not _crane_owned() and not (motion == "up" and attached_count()==2):return receiver_pose if _installed() else source_pose
	if value >= 4:return route[4]
	var segment = clampi(floori(value),0,3)
	return route[segment].interpolate_with(route[segment+1],value-segment)

func point_position(id: String) -> Vector3:
	return load_pose()*points[POINT_IDS.find(id)]

func _station_beam(at: String, up: bool) -> Transform3D:
	var origin = source_pose.origin if at == "source" else receiver_pose.origin+(approach_offset if up else Vector3.ZERO)
	if at == "park":origin = park_position
	origin.y = up_y if up else (source_pose.origin.y+.80 if at == "source" else receiver_pose.origin.y+.88)
	return Transform3D(Basis.IDENTITY,origin)

func _beam_at(at: String, up: bool, action: String, p: float) -> Transform3D:
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

func _beam_pose() -> Transform3D:
	return _beam_at(station,raised,motion,progress)

func physics(delta: float) -> void:
	console.physics()
	if game.paused:return
	if moving:
		var next = minf(1,progress+delta/5.0)
		if attached_count()==2:
			var error = _route_error(_path(station,raised,motion,progress),_path(station,raised,motion,next))
			if not error.is_empty():blocked_reason = error;_refresh();return
			if motion == "up" and station == "source" and next >= .1 and not _crane_owned():
				error = game.model.transfer_supported_item(uid,source_support,support)
				if not error.is_empty():blocked_reason = error;moving = false;return
		progress = next;blocked_reason = ""
		if progress >= 1:
			if motion == "down" and _crane_owned():
				if station == "source":
					var error: String = game.model.transfer_supported_item(uid,support,source_support)
					if not error.is_empty():blocked_reason = error;moving = false;return
				else:
					var result: Dictionary = game.model.install_supported(load_owner,slot,uid,support)
					if not result.ok:blocked_reason = result.error;moving = false;return
					game.components.sync(load_owner);game.refresh_assembly_collision(load_owner)
			if motion.begins_with("go:"):station = motion.get_slice(":",1)
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
	# Receiver contact shapes and its prepared geometry are authored mating surfaces.
	# Other scenery and people remain swept obstacles throughout the route.
	Sweep.collect_rids(game.runtime.node(load_owner),ignored)
	var group = {"shapes":Sweep.body_shapes(load_body),"margin":.001,"error":"Clear the crane load's route, including people and loose parts."}
	return Sweep.sweep(get_world_3d().direct_space_state,[group],Sweep.steps(from,to,4,.04),func(weight: float) -> Transform3D:return from.interpolate_with(to,weight),15,ignored,equipment_id).get("error","")

func _line(mesh: MeshInstance3D, from: Vector3, to: Vector3, width: float) -> void:
	var direction = to-from;var length = direction.length()
	mesh.global_position = (from+to)*.5
	mesh.global_basis = Basis(Quaternion(Vector3.UP,direction.normalized())) if length>.0001 else Basis.IDENTITY
	mesh.scale = Vector3(width,maxf(.001,length),width)

func _refresh() -> void:
	if not is_instance_valid(load_body):return
	if complete_journey:
		for spec in tasks.values():
			if spec.load_uid == uid:continue
			var body: AnimatableBody3D = stock_bodies[spec.load_uid]
			var at_source = game.model.items[spec.load_uid].location == "support:"+spec.source_support
			body.visible = at_source;body.collision_layer = 2 if at_source else 0
			body.global_transform = preload("res://scripts/leg_bay_layout.gd").authored_pose(spec.source_pose)
			body.force_update_transform();PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	var installed = _installed()
	load_body.visible = not installed;load_body.collision_layer = 0 if installed else 2
	load_body.global_transform = load_pose()
	load_body.force_update_transform();PhysicsServer3D.body_set_state(load_body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,load_body.global_transform)
	beam.global_transform = _beam_pose()
	for index in range(2):
		var id: String = END_IDS[index]
		var end: Dictionary = endpoints[id]
		# Cable trolleys align over the selected marked point, so either stable
		# endpoint can use either point without crossing the other load cable.
		var anchor_index = POINT_IDS.find(end.point) if end.state == "attached" else index
		var anchor = beam.global_position+Vector3(points[anchor_index].x,0,points[anchor_index].y)
		var point = anchor-Vector3(0,.55,0)
		if end.state == "held":point = game.camera.global_transform*Vector3(0,0,-.65)
		elif end.state == "attached":point = point_position(end.point)
		end_nodes[id].global_position = point
		_line(cables[id],anchor,point,1)
		markers[POINT_IDS[index]].global_position = point_position(POINT_IDS[index])+Vector3(0,.008,0)
		markers[POINT_IDS[index]].visible = not raised and motion.is_empty() and station != "park" and not hand_payload().is_empty()
	var eye = beam.global_position+Vector3(0,0,rig_center)
	if layout.has_method("set_crane_anchor"):layout.set_crane_anchor(Vector3(eye.x,20.6,eye.z))
	_line(mast_cable,eye,Vector3(eye.x,20.6,eye.z),1)
	if is_instance_valid(physical_status):physical_status.text = status_text()
	if is_instance_valid(console):console.refresh()
	changed.emit()

func status_text() -> String:
	var label: String = _station_title(station)+" · "+("Up" if raised else "Down")
	if not motion.is_empty():label += " · "+("Moving" if moving else "Stopped")
	if attached_count()>0:label += "\nMagnetic ends attached: %d/2"%attached_count()
	if _installed():label += ("\nConnection retention: %d/%d" if complete_journey else "\nFlange fasteners: %d/%d")%[hardware_count(),fastener_slots.size()]
	if not blocked_reason.is_empty():label += "\n"+blocked_reason
	return label

func capture() -> Dictionary:
	var result = {"version":VERSION,"station":station,"raised":raised,"motion":motion,"progress":progress,"moving":moving,"blocked_reason":blocked_reason,"endpoints":endpoints.duplicate(true)}
	if complete_journey:result["task"] = task
	return result

func validate(data: Variant, candidate: AssemblyModel = null, _world: Dictionary = {}) -> Array[String]:
	if not data is Dictionary or data.size()!=(9 if complete_journey else 8):return ["Incomplete crane state."]
	if complete_journey:
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
	if not data.get("endpoints") is Dictionary or data.endpoints.size()!=2:return ["Invalid cable ends."]
	var count = 0;var held = 0;var occupied: Array = []
	for id in END_IDS:
		var end = data.endpoints.get(id)
		if not end is Dictionary or end.size()!=2 or not end.get("state") is String or not end.get("point") is String:return ["Invalid magnetic end fields."]
		if end.state not in ["stowed","held","attached"]:return ["Invalid magnetic end state."]
		if end.state == "attached":
			if end.point not in POINT_IDS or end.point in occupied:return ["Invalid or occupied magnetic point."]
			count += 1;occupied.append(end.point)
		elif not end.point.is_empty():return ["Detached magnet retains a point."]
		if end.state == "held":held += 1
	var model: AssemblyModel = game.model if candidate==null else candidate
	if held>1 or held>0 and model.hands_occupied():return ["Conflicting hand payloads."]
	if (data.raised or not data.motion.is_empty()) and (held>0 or count==1):return ["Crane moved with incomplete rigging."]
	var item: Dictionary = model.items[uid]
	var rack = item.location == "support:"+source_support
	var carried = _crane_owned(model)
	var installed = _installed(model)
	if not rack and not carried and not installed:return ["Unsupported crane load load_owner."]
	if hardware_count(model)>0 and not installed:return ["Hardware has no installed beam."]
	if installed and count<2 and not secured(model):return ["Unsecured flange lost its magnets."]
	if count>0 and data.station=="park" or data.motion=="go:park" and count>0:return ["Loaded crane cannot park."]
	if count>0 and rack and (data.station!="source" or data.raised or data.motion not in ["","up"] or data.progress>=.1):return ["Rack ownership contradicts crane movement."]
	if count>0 and installed and (data.station!="receiver" or data.raised or not data.motion.is_empty()):return ["Installed beam cannot travel with crane."]
	if carried:
		if count!=2 or data.station=="park":return ["Suspended beam lacks rigging."]
		if not data.raised and data.motion!="up":return ["Suspended beam has no lifting motion."]
		if data.station=="source" and data.motion=="up" and data.progress<.1:return ["Crane took source ownership before taking weight."]
	if complete_journey:
		for key in tasks:
			var spec: Dictionary = tasks[key]
			if key == data.task:continue
			var other: Dictionary = model.items[spec.load_uid]
			if other.location == "installed":
				if other.owner != spec.owner or other.slot != spec.slot or not model.milestone(spec.owner,spec.secured.milestone):return ["Inactive crane task has unsecured work."]
			elif other.location != "support:"+spec.source_support:return ["Inactive crane load is off its rack."]
		if count > 0 and installed and _world.has("equipment"):
			var rail: Dictionary = _world.equipment.leg_rail
			if rail.path != 0 or rail.moving or not rail.engaged:return ["Attached crane task requires the engaged rail home."]
	return []

func apply(data: Dictionary) -> void:
	if complete_journey and data.task != task:
		task = data.task;config = layout.crane_contract(task);_configure_task(config);_configure_rig_bar();load_body = _stock_body(uid)
	station = data.station;raised = data.raised;motion = data.motion;progress = float(data.progress);moving = data.moving;blocked_reason = data.blocked_reason;endpoints = data.endpoints.duplicate(true)
	console.shut();_refresh()

func _station_title(at: String) -> String:
	if not complete_journey:return TITLES[at]
	if at == "source":return tasks[task].title+" rack"
	return "Leg cradle" if at == "receiver" else "Parking bay"

func _receiver_error() -> String:
	var rail = game.equipment.get_equipment("leg_rail")
	if rail == null or rail.path > .0001 or rail.moving or not rail.engaged:return "Return the engaged leg holder home before crane delivery or reacquisition."
	return ""

func _journey_undo(subject: String) -> Dictionary:
	if subject != load_owner:return {"handled":false,"error":""}
	var history: Array = game.model.assemblies[subject].history
	if history.is_empty():return {"handled":false,"error":""}
	var sid: String = history.back().slot
	var spec: Dictionary = game.model.slot_definition(subject,sid)
	if spec.get("undo_requires_support","") != support:return {"handled":false,"error":""}
	var active_security: Array = game.leg_content.m3.security_slots[task]
	if sid not in active_security:return {"handled":true,"error":"Select the matching crane task and reacquire both magnets before dismantling this connection."}
	if attached_count()!=2 or raised or not motion.is_empty() or station != "receiver" or not _receiver_error().is_empty():return {"handled":true,"error":"Lower the matching crane at the home leg cradle and attach both magnets before removing any connection hardware."}
	if sid == slot:return {"handled":true,"error":"Use Up at the crane console to lift the unfastened component from its seat."}
	return {"handled":false,"error":""}

func _validate_other_task(data: Dictionary, candidate: AssemblyModel, world: Dictionary) -> Array[String]:
	# A detached validator uses the candidate task contract; it never changes
	# live meshes/endpoints/selected task while rejecting a save.
	var probe = get_script().new()
	probe.game = game;probe.layout = layout;probe.complete_journey = true;probe.tasks = tasks;probe.task = data.task
	probe._configure_task(layout.crane_contract(data.task))
	var errors: Array[String] = probe.validate(data,candidate,world)
	probe.free()
	return errors

func _configure_rig_bar() -> void:
	if not complete_journey or not is_instance_valid(rig_bar):return
	var min_z = minf(points[0].y,points[1].y)
	var max_z = maxf(points[0].y,points[1].y)
	rig_center = (min_z+max_z)/2
	rig_bar.position = Vector3(0,0,rig_center)
	# Each selected task has its own supported two-point spread. Fork magnets
	# span across X; shin/beam magnets span along the load's canonical length.
	var mesh = BoxMesh.new();mesh.size = Vector3(absf(points[0].x-points[1].x)+.28,.18,max_z-min_z+.34)
	rig_bar.mesh = mesh
