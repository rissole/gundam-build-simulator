class_name LegEquipment
extends Node3D
## Powered handling retains model identity; seating and retaining are separate.
const Layout = preload("res://scripts/leg_workshop_layout.gd")
const SPEED = 0.85
const MASK = 15
const FOOT_DISPATCH = Vector3(2.3,1.55,4.4)
const FOOT_APPROACH_Z = 10.2
const FOOT_CLEARANCE_Y = 3.2
const FOOT_PHASES = ["foot_seat","foot_return"]
const OPERATIONS = ["","foot_seat","foot_return","part_install","part_return","leg_transfer","leg_seat","leg_unseat","leg_return"]
var game: Node3D
var layout: Node3D
var content: Dictionary
var parts: Dictionary = {}
var stock_bodies: Dictionary = {}
var stock_poses: Dictionary = {}
var racks: Dictionary = {}
var foot_departed = false
var assisting = false
var released = false
var stabilized = false
var fixture_engaged = true
var leg_stage = "fixture"
var operation = ""
var uid = ""
var receiving_owner = ""
var slot = ""
var support = ""
var waypoints: Array[Transform3D] = []
var segment = 0
var progress = 0.0
var start_pose = Transform3D.IDENTITY
var blocked_reason = ""
var _buttons: Array[Dictionary] = []
var _status: Label3D
var _equipment: Dictionary
var _service_yoke: Node3D
var _service_cable: MeshInstance3D
var _foot_slings: Array[MeshInstance3D] = []

var moving: bool:
	get:return not operation.is_empty()

func setup(workshop: Node3D, workshop_layout: Node3D, data: Dictionary) -> void:
	game = workshop
	layout = workshop_layout
	content = data
	_equipment = content.get("equipment",{})
	_discover_parts()
	_make_controls()
	_service_yoke = Node3D.new()
	_service_yoke.name = "ServiceHoistYoke"
	add_child(_service_yoke)
	var steel = game.material(Color("e8b46b"),0.4)
	game.box(_service_yoke,Vector3.ZERO,Vector3(1.0,0.12,0.12),steel)
	for x in [-0.42,0.42]:game.box(_service_yoke,Vector3(x,-0.25,0),Vector3(0.06,0.5,0.08),steel)
	_service_cable = game.box(self,Vector3.ZERO,Vector3(0.04,1,0.04),steel)
	for index in range(4):_foot_slings.append(game.box(self,Vector3.ZERO,Vector3(0.035,1,0.035),steel))
	_refresh()

func _discover_parts() -> void:
	var authored: Dictionary = _equipment.get("parts",{})
	var index = 0
	for item_uid in game.model.items:
		var item: Dictionary = game.model.items[item_uid]
		if game.model.definitions.parts[item.kind].carry_class != "equipment" or item.location == "installed":continue
		var spec: Dictionary = authored.get(item_uid,{}).duplicate(true)
		spec.support = spec.get("support",item.location.trim_prefix("support:"))
		if not spec.has("owner") or not spec.has("slot"):
			for candidate in ["left_leg","pelvis"]:
				for sid in game.model.assemblies[candidate].slots:
					var d: Dictionary = game.model.slot_definition(candidate,sid)
					if d.get("accepts","") == item.kind and d.get("source_supports",[]).has(spec.support):spec.owner = candidate;spec.slot = sid;break
				if spec.has("owner"):break
		var fallback = Vector3(-4.0,2.2,14.0+index*4.0) if index < 3 else Vector3(18.5+(index-3)*2.0,1.0,22.0)
		var at = fallback
		if index < 3:at.y = Layout.LEG_ORIGIN.y + source_origin_y(item_uid)
		var source: Dictionary = game.source[game.model.source_uid(item_uid)]
		var pose = Transform3D(source.transform.basis,at)
		parts[item_uid] = spec
		stock_poses[item_uid] = pose
		var body = AnimatableBody3D.new()
		body.name = item_uid.replace("/","_")+"SupportedStock"
		body.sync_to_physics = false
		body.collision_layer = 2
		body.collision_mask = 0
		add_child(body)
		body.add_child(game._mesh(item_uid))
		for entry in SolidHandling.authored_shapes(game.model.definitions.parts[item.kind].get("collision_shapes",[]),source.mesh.get_aabb()):
			var collision = CollisionShape3D.new()
			collision.shape = entry.shape
			collision.transform = entry.transform
			body.add_child(collision)
		body.global_transform = pose
		stock_bodies[item_uid] = body
		var rack = Node3D.new()
		rack.name = spec.support
		add_child(rack)
		racks[item_uid] = rack
		var bounds = SolidHandling.bounds(body)
		var lower = at.y+bounds.position.y
		var steel = game.material(Color("485f68"),0.5)
		game.box(rack,Vector3(at.x,maxf(0.08,lower-0.1),at.z),Vector3(maxf(bounds.size.x,0.7),0.18,maxf(bounds.size.z,0.7)),steel,true)
		for x in [-0.28,0.28]:
			game.box(rack,Vector3(at.x+x,maxf(0.1,lower*0.5),at.z),Vector3(0.08,maxf(0.18,lower-0.2),0.08),steel,true)
		game.sign_panel(rack,game.model.definitions.parts[item.kind].title,Vector3(at.x,0.65,at.z+0.6),Vector2(1.6,0.25),45,0.002)
		index += 1

func source_origin_y(item_uid: String) -> float:
	return game.source[game.model.source_uid(item_uid)].transform.origin.y

func _make_controls() -> void:
	var entries = [["seat_foot","Transfer prepared foot"],["return_foot","Return foot to carrier"],["pick_leg","Engage leg hoist"],["transfer_leg","Transfer leg to pelvis"],["seat_leg","Seat hip ball"],["stabilize","Engage leg stabilizer"],["release_hoist","Release hoist"],["reacquire_hoist","Reacquire hoist"],["return_leg","Return leg to fixture"]]
	for item_uid in parts:
		entries.append(["install:"+item_uid,"Fit "+game.model.definitions.parts[game.model.items[item_uid].kind].title])
	var panel = Node3D.new()
	panel.name = "LegEquipmentConsole"
	add_child(panel)
	var steel = game.material(Color("263a43"),0.4)
	var yellow = game.material(Color("e8b46b"),0.25)
	for index in range(entries.size()):
		var column = index / 5
		var row = index % 5
		var at = Vector3(-2.0-column*0.7,1.15,11.2+row*0.42)
		# Floor posts sit behind the active face, preserving the aiming aisle.
		game.box(panel,Vector3(at.x+0.10,0.04,at.z),Vector3(0.16,0.08,0.22),steel,true)
		game.box(panel,Vector3(at.x+0.10,0.415,at.z),Vector3(0.06,0.67,0.06),steel,true)
		game.box(panel,at+Vector3(0.10,-0.1,0),Vector3(0.16,0.6,0.35),steel,true)
		var button = game.box(panel,at,Vector3(0.12,0.12,0.16),yellow)
		_buttons.append({"type":"equipment","node":button,"action":entries[index][0],"label":entries[index][1],"radius":0.15,"controller":self})
		game.sign_panel(panel,entries[index][1],at+Vector3(-0.08,-0.14,0),Vector2(0.55,0.12),30,0.0015,-PI/2)
	_status = game.sign_panel(panel,"",Vector3(-2.1,1.9,12.0),Vector2(2.2,0.6),48,0.002,-PI/2)
	var final_actions = [["seat_leg","Seat hip ball"],["stabilize","Stabilizer"],["release_hoist","Release hoist"],["reacquire_hoist","Reacquire hoist"],["return_leg","Return leg"]]
	for item_uid in parts:
		if parts[item_uid].owner == "pelvis":final_actions.append(["install:"+item_uid,"Fit retainer half"])
	for location in ["ground","deck"]:
		var console = Node3D.new()
		console.name = "HipHandlingControls"+location
		if location == "deck" and game.get("access_lifts") != null and game.access_lifts.has("hip"):
			game.access_lifts.hip.deck.add_child(console)
			console.position = Vector3(-(game.access_lifts.hip.deck_size.x*0.5-0.18),0,0)
			console.rotation.y = PI
		else:
			add_child(console)
			console.position = Vector3(15.8,0,24.5)
		for index in range(final_actions.size()):
			var at = Vector3(0,1.15,-0.78+index*0.26)
			if location == "ground":
				game.box(console,Vector3(0.07,0.04,at.z),Vector3(0.16,0.08,0.16),steel,true)
				game.box(console,Vector3(0.07,0.485,at.z),Vector3(0.06,0.81,0.06),steel,true)
			# The inboard deck enclosure bolts directly to its existing side rail.
			game.box(console,at+Vector3(0.07,-0.06,0),Vector3(0.12,0.4,0.23),steel,true)
			var button = game.box(console,at,Vector3(0.10,0.10,0.13),yellow)
			_buttons.append({"type":"equipment","node":button,"action":final_actions[index][0],"label":final_actions[index][1],"radius":0.12,"controller":self})
			game.sign_panel(console,final_actions[index][1],at+Vector3(-0.06,-0.12,0),Vector2(0.25,0.09),28,0.0014,-PI/2)

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for button in _buttons:
		var entry: Dictionary = button.duplicate()
		entry.point = button.node.global_position
		result.append(entry)
	return result

func action_error(action: String) -> String:
	if moving:return blocked_reason if not blocked_reason.is_empty() else "Wait for the supported movement to finish."
	var model: AssemblyModel = game.model
	if action == "seat_foot":
		if foot_departed:return "The foot has already left its carrier."
		if not model.milestone("foot","complete"):return "Complete and secure the foot before transferring it."
		if game.foot_fixture.moving or not game.foot_fixture.at_dispatch or game.foot_fixture.work_pose != "upright":return "Dispatch the upright foot carrier first."
		var support_error = model.support_error("foot","foot_hoist")
		if not support_error.is_empty():return support_error
		if not model.support_occupant("foot_hoist").is_empty():return "The foot hoist is occupied."
		return model.placement_error("left_leg","foot","foot","foot_carrier")
	if action == "return_foot":
		if model.assemblies.left_leg.history.is_empty() or model.assemblies.left_leg.history.back().uid != "foot":return "Undo the leg's later work before returning its foot."
		return "" if model.assemblies.foot.parent == "left_leg" and leg_stage == "fixture" else "Return the leg to its fixture before removing the foot."
	if action == "pick_leg":
		if not model.milestone("left_leg","structural_ready"):return "Complete and secure the structural leg before lifting it."
		if model.assemblies.left_leg.location != "support:leg_fixture":return "The leg must be on its assembly fixture."
		return "" if model.support_occupant("leg_hoist").is_empty() else "The leg hoist is occupied."
	if action == "transfer_leg":return "" if assisting and leg_stage == "fixture" and model.assemblies.left_leg.location == "support:leg_hoist" else "Engage the hoist on the completed leg first."
	if action == "seat_leg":
		if not assisting or leg_stage != "approach":return "Bring the hoisted leg to the pelvis approach first."
		return model.placement_error("pelvis","left_leg","left_leg","leg_hoist")
	if action == "stabilize":return "" if leg_stage == "seated" and not stabilized else "Seat the leg before engaging its stabilizer."
	if action == "release_hoist":
		if not assisting:return "The hoist is already released."
		if not model.milestone("pelvis","left_leg_secured") or not stabilized:return "Secure the hip retainers and engage the stabilizer before releasing the hoist."
		return ""
	if action == "reacquire_hoist":return "" if leg_stage == "seated" and not assisting else "The seated leg already has hoist support."
	if action == "return_leg":return "" if assisting and leg_stage == "approach" and model.assemblies.left_leg.location == "support:leg_hoist" else "Undo hip seating with the hoist engaged before returning the leg."
	if action.begins_with("install:"):
		var item_uid = action.trim_prefix("install:")
		if not parts.has(item_uid):return "Unknown equipment component."
		var spec: Dictionary = parts[item_uid]
		var target_slot = _next_slot(item_uid)
		if target_slot.is_empty():return "No compatible unfinished connection is available."
		if spec.owner == "left_leg" and (leg_stage != "fixture" or not fixture_engaged):return "Return the leg to its assembly fixture first."
		if spec.owner == "pelvis" and (leg_stage != "seated" or not assisting):return "Seat the leg and keep the hoist engaged while fitting the retainers."
		return model.placement_error(spec.owner,target_slot,item_uid,spec.support)
	return "Unknown handling control."

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():return error
	if action == "seat_foot":
		var target = game.runtime.mount_pose("left_leg","foot","foot")
		error = _begin("foot_seat","foot","left_leg","foot","foot_hoist",_foot_route(target,false))
		if error.is_empty():
			error = game.model.transfer_supported_assembly("foot","foot_carrier","foot_hoist")
			if error.is_empty():foot_departed = true;game.foot_fixture.set_meta("disabled",true)
	elif action == "return_foot":return undo("left_leg").get("error","")
	elif action == "pick_leg":
		error = game.model.transfer_supported_assembly("left_leg","leg_fixture","leg_hoist")
		if error.is_empty():assisting = true;fixture_engaged = false;released = false
	elif action == "transfer_leg":error = _begin("leg_transfer","left_leg","","","leg_hoist",_leg_route(false))
	elif action == "seat_leg":error = _begin("leg_seat","left_leg","pelvis","left_leg","leg_hoist",[game.runtime.mount_pose("pelvis","left_leg","left_leg")])
	elif action == "stabilize":stabilized = true
	elif action == "release_hoist":assisting = false;released = true
	elif action == "reacquire_hoist":assisting = true;released = false
	elif action == "return_leg":error = _begin("leg_return","left_leg","","","leg_hoist",_leg_route(true))
	elif action.begins_with("install:"):
		var item_uid = action.trim_prefix("install:")
		var spec: Dictionary = parts[item_uid]
		var target_slot = _next_slot(item_uid)
		var target = game.runtime.slot_pose(spec.owner,target_slot)
		error = _begin("part_install",item_uid,spec.owner,target_slot,spec.support,_part_route(stock_poses[item_uid],target,false))
	_refresh()
	return error

func _next_slot(item_uid: String) -> String:
	var spec: Dictionary = parts[item_uid]
	# Identical retainer halves may fill either authored receiving position.
	var fallback = ""
	for sid in game.model.assemblies[spec.owner].slots:
		var d: Dictionary = game.model.slot_definition(spec.owner,sid)
		if d.get("accepts","") != game.model.items[item_uid].kind or not d.get("source_supports",[]).has(spec.support) or not game.model.assemblies[spec.owner].slots[sid].is_empty():continue
		if fallback.is_empty():fallback = sid
		if d.get("requires",[]).all(func(r):return not game.model.assemblies[spec.owner].slots[r].is_empty()):return sid
	return fallback

func _leg_route(reverse: bool) -> Array[Transform3D]:
	var travel_height = Layout.approach_origin().y
	var points = [Vector3(2.3,travel_height,10.2),Vector3(11.9,travel_height,10.2),Layout.approach_origin()]
	if reverse:points = [Vector3(11.9,travel_height,10.2),Vector3(2.3,travel_height,10.2),Layout.LEG_ORIGIN]
	var result: Array[Transform3D] = []
	for point in points:result.append(Transform3D(Basis.IDENTITY,point))
	return result

func _foot_route(target: Transform3D, reverse: bool) -> Array[Transform3D]:
	var raised_source = Transform3D(Basis.IDENTITY,Vector3(FOOT_DISPATCH.x,FOOT_CLEARANCE_Y,FOOT_DISPATCH.z))
	var raised_front = Transform3D(Basis.IDENTITY,Vector3(target.origin.x,FOOT_CLEARANCE_Y,FOOT_APPROACH_Z))
	var lowered_front = Transform3D(Basis.IDENTITY,Vector3(target.origin.x,target.origin.y,FOOT_APPROACH_Z))
	var result: Array[Transform3D] = []
	result.assign([lowered_front,raised_front,raised_source,Transform3D(Basis.IDENTITY,FOOT_DISPATCH)] if reverse else [raised_source,raised_front,lowered_front,target])
	return result

func _part_route(stock: Transform3D, target: Transform3D, reverse: bool) -> Array[Transform3D]:
	var approach = target
	approach.origin.z -= 2.2
	# Raise beside the rack, travel across the clear front aisle, then seat.
	var lift = Transform3D(target.basis,Vector3(stock.origin.x,target.origin.y,stock.origin.z))
	# Enter the clear front aisle at the rack's X before crossing toward the
	# receiver. A diagonal from the tall-part racks would cut through lift masts.
	var front = Transform3D(target.basis,Vector3(stock.origin.x,target.origin.y,approach.origin.z))
	var result: Array[Transform3D] = []
	result.assign([approach,front,lift,stock] if reverse else [lift,front,approach,target])
	return result

func _body(item_uid: String) -> CollisionObject3D:
	return stock_bodies[item_uid] if stock_bodies.has(item_uid) else game.runtime.node(item_uid)

func _begin(next_operation: String, item_uid: String, receiving_owner: String, receiving_slot: String, source_support: String, route: Array, prevalidated: bool = false) -> String:
	var body = _body(item_uid)
	var from = body.global_transform
	# Validate the complete planned route before powered movement starts.
	if not prevalidated:
		for destination in route:
			var error = _sweep(body,from,destination,receiving_owner,next_operation,item_uid)
			if not error.is_empty():return error
			from = destination
	operation = next_operation;uid = item_uid;self.receiving_owner = receiving_owner;slot = receiving_slot;support = source_support
	start_pose = body.global_transform
	waypoints.assign(route)
	segment = 0;progress = 0;blocked_reason = ""
	_refresh()
	return ""

func physics(delta: float) -> void:
	if not moving or game.paused:return
	var body = _body(uid)
	var from = start_pose if segment == 0 else waypoints[segment-1]
	var target = waypoints[segment]
	var distance = from.origin.distance_to(target.origin)
	var angle = from.basis.get_rotation_quaternion().angle_to(target.basis.get_rotation_quaternion())
	var duration = maxf(distance/SPEED,angle/(PI/10))
	var next_progress = minf(1.0,progress+delta/maxf(0.05,duration))
	var candidate = from.interpolate_with(target,next_progress)
	var error = _sweep(body,body.global_transform,candidate,receiving_owner,operation,uid)
	if not error.is_empty():blocked_reason = error;_refresh();return
	blocked_reason = ""
	progress = next_progress
	body.global_transform = candidate
	_update_hoist(body)
	if progress >= 1:
		segment += 1;progress = 0
		if segment >= waypoints.size():_finish()
	_refresh()

func _finish() -> void:
	var result: Dictionary = {"ok":true}
	if operation in ["foot_seat","part_install","leg_seat"]:
		result = game.model.install_supported(receiving_owner,slot,uid,support)
		if not result.ok:blocked_reason = result.error;segment = waypoints.size()-1;progress = 1;return
	if operation == "foot_seat":
		game.runtime.mount("left_leg","foot","foot")
		_sync("left_leg")
	elif operation == "foot_return":
		var transfer_error: String = game.model.transfer_supported_assembly("foot","foot_hoist","foot_carrier")
		if not transfer_error.is_empty():blocked_reason = transfer_error;segment = waypoints.size()-1;progress = 1;return
		foot_departed = false
		game.foot_fixture.at_dispatch = true
		game.foot_fixture.work_pose = "upright"
		game.foot_fixture.set_meta("disabled",false)
	elif operation == "part_install":_sync(receiving_owner)
	elif operation == "part_return":_sync(receiving_owner)
	elif operation == "leg_transfer" or operation == "leg_unseat":leg_stage = "approach"
	elif operation == "leg_seat":
		game.runtime.mount("pelvis","left_leg","left_leg")
		leg_stage = "seated"
		_sync("pelvis")
	elif operation == "leg_return":
		var error: String = game.model.transfer_supported_assembly("left_leg","leg_hoist","leg_fixture")
		if not error.is_empty():blocked_reason = error;segment = waypoints.size()-1;progress = 1;return
		leg_stage = "fixture";fixture_engaged = true;assisting = false;released = false
	operation = "";uid = "";receiving_owner = "";slot = "";support = "";waypoints.clear();segment = 0;progress = 0;blocked_reason = ""
	_sync_stock()

func equipment_access_error(assembly: String) -> String:
	if assembly not in ["foot","left_leg","pelvis"]:return ""
	if moving:return "Wait for supported handling to stop before changing connections."
	if assembly == "foot" and foot_departed:return "The foot is installed in the leg. Use its parent manual."
	if assembly == "left_leg" and not fixture_engaged:return "Return the leg to its assembly fixture before changing its internals."
	return ""

func undo(assembly: String) -> Dictionary:
	if assembly not in ["foot","left_leg","pelvis"]:return {"handled":false}
	if moving:return {"handled":true,"error":"Wait for supported handling to finish."}
	var history: Array = game.model.assemblies[assembly].history
	if history.is_empty():return {"handled":false}
	var step: Dictionary = history.back()
	if assembly == "pelvis" and game.model.assemblies.left_leg.parent == "pelvis" and not assisting:return {"handled":true,"error":"Reacquire the hoist before removing hip retention."}
	var d: Dictionary = game.model.slot_definition(assembly,step.slot)
	if not d.get("support_required",false):return {"handled":false}
	if assembly == "left_leg" and not fixture_engaged:return {"handled":true,"error":"Return the leg to its fixture before removing structural components."}
	var destination: String = "foot_hoist" if step.uid == "foot" else "leg_hoist" if step.uid == "left_leg" else parts[step.uid].support
	if not game.model.support_occupant(destination).is_empty():return {"handled":true,"error":"Clear the reserved output support first."}
	var old_pose = game.runtime.node(step.uid).global_transform if step.action == "mount" else game.runtime.slot_pose(assembly,step.slot)
	var route: Array[Transform3D] = []
	var next = "part_return"
	if step.uid == "foot":
		next = "foot_return";route = _foot_route(old_pose,true)
	elif step.uid == "left_leg":
		next = "leg_unseat";route = [Transform3D(Basis.IDENTITY,Layout.approach_origin())]
	else:route = _part_route(stock_poses[step.uid],old_pose,true)
	var body: CollisionObject3D = _body(step.uid)
	# Check removal while the fitted geometry still exists. Only its actual
	# receiver, supporting fixture and source rack are contact exceptions.
	var from = old_pose
	for target in route:
		var error = _sweep(body,from,target,assembly,next,step.uid)
		if not error.is_empty():return {"handled":true,"error":error}
		from = target
	var result: Dictionary = game.model.undo_supported(assembly,destination)
	if not result.ok:return {"handled":true,"error":result.error}
	if step.action == "mount":
		body.reparent(game)
		body.global_transform = old_pose
		if body is AnimatableBody3D:body.sync_to_physics = false
	else:
		body.global_transform = old_pose
	_sync(assembly)
	_sync_stock()
	body.global_transform = old_pose
	if step.uid == "left_leg":stabilized = false;released = false;leg_stage = "seated"
	var error = _begin(next,step.uid,assembly,step.slot,destination,route,true)
	return {"handled":true,"ok":error.is_empty(),"error":error}

func _sync(assembly: String) -> void:
	if game.get("components") != null:game.components.sync(assembly)
	if game.has_method("refresh_assembly_collision"):game.refresh_assembly_collision(assembly)

func _sync_stock() -> void:
	for item_uid in stock_bodies:
		var available: bool = game.model.items[item_uid].location != "installed"
		stock_bodies[item_uid].visible = available
		stock_bodies[item_uid].collision_layer = 2 if available else 0
		if available and (not moving or uid != item_uid):stock_bodies[item_uid].global_transform = stock_poses[item_uid]

func _collect(node: Node, excluded: Array[RID]) -> void:
	if node is CollisionObject3D:excluded.append(node.get_rid())
	for child in node.get_children():_collect(child,excluded)

func _sweep(body: CollisionObject3D, from: Transform3D, to: Transform3D, receiver: String, motion: String, item_uid: String) -> String:
	var excluded: Array[RID] = []
	_collect(body,excluded)
	# Explicit support contacts, never a blanket scenery exclusion.
	# Only retractable support contacts may touch their own workpiece. Rear
	# crossbars, uprights and foundations remain real swept obstacles.
	if is_instance_valid(layout.leg_fixture):
		for contact in layout.leg_fixture.find_children("*","CollisionObject3D",true,false):
			if contact.get_meta("support_contact",false):excluded.append(contact.get_rid())
	if receiver != "" and game.runtime.nodes.has(receiver):_collect(game.runtime.node(receiver),excluded)
	if racks.has(item_uid):_collect(racks[item_uid],excluded)
	if item_uid == "foot" and is_instance_valid(game.foot_fixture):
		_collect(game.foot_fixture.carriage,excluded)
	if motion in ["leg_seat","leg_unseat","part_install","part_return"] and receiver == "pelvis":
		_collect(layout.clamp,excluded)
		var brace = layout.gantry.get_node_or_null("LegStabilizer")
		if brace != null:_collect(brace,excluded)
	var bodies: Array[CollisionObject3D] = [body]
	for descendant in body.find_children("*","CollisionObject3D",true,false):bodies.append(descendant)
	var root_inverse = body.global_transform.affine_inverse()
	var space = body.get_world_3d().direct_space_state
	for member in bodies:
		var relative = root_inverse*member.global_transform
		var bounds = SolidHandling.bounds(member)
		var radius = maxf(0.1,bounds.get_center().length()+bounds.size.length()*0.5+relative.origin.length())
		var steps = SolidHandling.sweep_steps(from,to,radius,0.05)
		var query = PhysicsShapeQueryParameters3D.new()
		query.exclude = excluded;query.collision_mask = MASK
		var angle = from.basis.get_rotation_quaternion().angle_to(to.basis.get_rotation_quaternion())
		query.margin = 0.002+radius*angle/steps*0.5
		var profiles: Array[Dictionary] = []
		for collision in SolidHandling.shapes(member):
			var shape: Shape3D = collision.shape
			var local_pose = collision.transform
			if shape is ConcavePolygonShape3D:
				var proxy = BoxShape3D.new()
				var shape_bounds = shape.get_debug_mesh().get_aabb()
				proxy.size = shape_bounds.size.max(Vector3.ONE*0.004)
				local_pose = local_pose*Transform3D(Basis.IDENTITY,shape_bounds.get_center())
				shape = proxy
			profiles.append({"shape":shape,"transform":local_pose})
		for index in range(steps+1):
			var pose = from.interpolate_with(to,float(index)/steps)
			for profile in profiles:
				query.shape = profile.shape
				query.transform = pose*relative*profile.transform
				query.motion = Vector3.ZERO
				var hits = space.intersect_shape(query,1)
				if not hits.is_empty():
					if OS.has_environment("LEG_EQUIPMENT_DIAGNOSTIC"):print("HANDLING_CONTACT ",motion," ",item_uid," ",member.name," profile ",profile.transform.origin," pose ",pose.origin," hit ",hits)
					return "Clear the supported load's route, including people and loose components."
				if index < steps:
					var next_pose = from.interpolate_with(to,float(index+1)/steps)
					query.motion = (next_pose*relative*profile.transform).origin-query.transform.origin
					var fractions = space.cast_motion(query)
					if fractions.size() == 2 and fractions[0] < 0.999:
						if OS.has_environment("LEG_EQUIPMENT_DIAGNOSTIC"):
							query.transform.origin += query.motion*minf(1.0,fractions[0]+0.01)
							query.motion = Vector3.ZERO
							print("HANDLING_CAST ",motion," ",item_uid," ",member.name," profile ",profile.transform.origin," pose ",pose.origin," hit ",space.intersect_shape(query,4))
						return "An obstacle blocks the equipment route. Clear it to resume."
	return ""

func _update_hoist(body: Node3D) -> void:
	var bounds = SolidHandling.bounds(body)
	var point = body.global_transform*Vector3(bounds.get_center().x,bounds.end.y,bounds.get_center().z)
	if stock_bodies.values().has(body) or body == game.runtime.node("foot"):
		_service_yoke.visible = true;_service_cable.visible = true
		_service_yoke.global_position = point
		layout.set_service_hoist(point,true)
		var length = maxf(0.1,Layout.SERVICE_CABLE_Y-point.y)
		_service_cable.global_position = point+Vector3.UP*length*0.5
		_service_cable.scale.y = length
		if body == game.runtime.node("foot"):
			var index = 0
			for x in [-0.5,0.5]:
				for z in [-1.42,1.42]:
					var grip = body.global_transform*Vector3(x,-0.38,z)
					var delta = grip-point
					_foot_slings[index].global_transform = Transform3D(Basis(Quaternion(Vector3.UP,delta.normalized())),point+delta*0.5)
					_foot_slings[index].scale.y = delta.length()
					index += 1
	else:layout.set_hoist(point,true)

func _refresh() -> void:
	game.foot_fixture.set_meta("disabled",foot_departed)
	if is_instance_valid(_service_yoke):
		_service_yoke.visible = moving and uid != "left_leg"
		_service_cable.visible = _service_yoke.visible
		for sling in _foot_slings:sling.visible = moving and uid == "foot"
	if is_instance_valid(layout.leg_fixture):layout.set_fixture_engaged(fixture_engaged)
	var brace = layout.gantry.get_node_or_null("LegStabilizer")
	if brace != null:
		brace.visible = stabilized
		brace.set_meta("engaged",stabilized)
		# Retracted jaws are absent from the movement corridor in both the
		# rendered scene and physics; engaged jaws provide real support contact.
		for body in brace.find_children("*","CollisionObject3D",true,false):body.collision_layer = 1 if stabilized else 0
	if moving:
		_update_hoist(_body(uid))
	else:
		layout.service_trolley.set_meta("engaged",false)
		if assisting:_update_hoist(game.runtime.node("left_leg"))
		else:layout.set_hoist(game.runtime.node("left_leg").global_position+Vector3.UP*8.2,false)
	if is_instance_valid(_status):_status.text = status_text()

func status_text() -> String:
	if moving:return "HANDLING PAUSED\n"+blocked_reason if not blocked_reason.is_empty() else "SUPPORTED HANDLING\n"+operation.replace("_"," ").to_upper()
	if released:return "HIP SECURED\nHOIST RELEASED / STABILIZER ENGAGED"
	if assisting:return "LEG HOIST ENGAGED\n"+leg_stage.to_upper()
	return "LEG FIXTURE READY\nFOLLOW THE STRUCTURAL MANUAL"

static func _pose(pose: Transform3D) -> Array:
	return _vector(pose.basis.x)+_vector(pose.basis.y)+_vector(pose.basis.z)+_vector(pose.origin)

static func _vector(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

static func _transform(value: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(value[0],value[1],value[2]),Vector3(value[3],value[4],value[5]),Vector3(value[6],value[7],value[8])),Vector3(value[9],value[10],value[11]))

func capture() -> Dictionary:
	var route: Array = []
	for point in waypoints:route.append(_pose(point))
	return {"operation":operation,"uid":uid,"owner":receiving_owner,"slot":slot,"support":support,"waypoints":route,"segment":segment,"progress":progress,"start_pose":_pose(start_pose),"foot_pose":_pose(game.runtime.node("foot").global_transform),"leg_pose":_pose(game.runtime.node("left_leg").global_transform),"carrier_pose":_pose(game.foot_fixture.carriage.global_transform),"foot_departed":foot_departed,"assisting":assisting,"released":released,"stabilized":stabilized,"fixture_engaged":fixture_engaged,"leg_stage":leg_stage,"blocked_reason":blocked_reason}

static func _valid_pose(value: Variant) -> bool:
	if not value is Array or value.size() != 12:return false
	for number in value:
		if not number is float and not number is int:return false
		if not is_finite(number) or absf(number)>1000:return false
	var pose = _transform(value)
	return pose.basis.determinant()>0.99 and pose.basis.is_equal_approx(pose.basis.orthonormalized())

func validate(data: Variant, candidate_model: AssemblyModel = null) -> Array[String]:
	if not data is Dictionary or data.size() != capture().size():return ["Invalid supported equipment state."]
	for key in capture():
		if not data.has(key):return ["Missing supported equipment field: "+key]
	for key in ["operation","uid","owner","slot","support","leg_stage","blocked_reason"]:
		if not data[key] is String:return ["Invalid supported equipment text field."]
	for key in ["foot_departed","assisting","released","stabilized","fixture_engaged"]:
		if not data[key] is bool:return ["Invalid supported equipment flag."]
	if data.operation not in OPERATIONS or data.leg_stage not in ["fixture","approach","seated"]:return ["Unknown supported equipment phase."]
	for key in ["start_pose","foot_pose","leg_pose","carrier_pose"]:
		if not _valid_pose(data[key]):return ["Invalid supported equipment pose."]
	if not data.waypoints is Array or data.waypoints.size()>4:return ["Invalid equipment route."]
	for point in data.waypoints:
		if not _valid_pose(point):return ["Invalid equipment route pose."]
	if not (data.segment is int or data.segment is float) or data.segment != floor(data.segment) or not (data.progress is int or data.progress is float) or not is_finite(data.progress) or data.progress<0 or data.progress>1:return ["Invalid equipment travel progress."]
	var model: AssemblyModel = game.model if candidate_model == null else candidate_model
	var foot: Dictionary = model.assemblies.foot
	var leg: Dictionary = model.assemblies.left_leg
	if data.foot_departed and not _transform(data.carrier_pose).is_equal_approx(Transform3D(Basis.IDENTITY,Vector3(FOOT_DISPATCH.x,0,FOOT_DISPATCH.z))):return ["The foot rail carrier left its dispatch rails."]
	if data.released and (data.assisting or not data.stabilized or not model.milestone("pelvis","left_leg_secured") or leg.parent != "pelvis"):return ["Released leg lacks retention and stabilization."]
	if data.fixture_engaged != (leg.location == "support:leg_fixture"):return ["Leg fixture state disagrees with ownership."]
	if data.fixture_engaged and data.leg_stage != "fixture":return ["Engaged leg fixture has an invalid travel stage."]
	if data.assisting and leg.location != "support:leg_hoist" and leg.parent != "pelvis":return ["Leg hoist is engaged on an unsupported ownership state."]
	if leg.location == "support:leg_hoist" and not model.milestone("left_leg","structural_ready"):return ["Hoisted leg is structurally incomplete."]
	if leg.parent == "pelvis" and (data.leg_stage != "seated" or not data.foot_departed or (not data.assisting and not data.released)):return ["Mounted leg lacks its equipment state."]
	if leg.location == "support:leg_hoist" and not data.assisting:return ["Hoisted leg lacks support engagement."]
	if data.stabilized and leg.parent != "pelvis":return ["Leg stabilizer has no seated leg."]
	if data.operation.is_empty():
		if not data.waypoints.is_empty() or data.segment != 0 or data.progress != 0 or not data.uid.is_empty() or not data.owner.is_empty() or not data.slot.is_empty() or not data.support.is_empty():return ["Idle equipment retains travel state."]
		if data.foot_departed != (foot.parent == "left_leg"):return ["Foot handling state disagrees with ownership."]
		if leg.location == "support:leg_fixture" and not _transform(data.leg_pose).is_equal_approx(Transform3D(Basis.IDENTITY,Layout.LEG_ORIGIN)):return ["Leg left its engaged fixture."]
		if leg.location == "support:leg_hoist":
			var expected = Layout.LEG_ORIGIN if data.leg_stage == "fixture" else Layout.approach_origin() if data.leg_stage == "approach" else Layout.seated_origin()
			if not _transform(data.leg_pose).is_equal_approx(Transform3D(Basis.IDENTITY,expected)):return ["Hoisted leg pose disagrees with its stage."]
		return []
	if data.segment<0 or data.segment>=data.waypoints.size():return ["Equipment route segment is out of range."]
	var is_part: bool = data.operation.begins_with("part_")
	if is_part:
		if not parts.has(data.uid) or data.owner != parts[data.uid].owner or data.support != parts[data.uid].support or model.items[data.uid].location != "support:"+data.support:return ["Moving equipment part has invalid ownership."]
		var d: Dictionary = model.slot_definition(data.owner,data.slot)
		if d.get("accepts","") != model.items[data.uid].kind or not model.assemblies[data.owner].slots[data.slot].is_empty():return ["Moving equipment part targets an invalid connection."]
		if not model.placement_error(data.owner,data.slot,data.uid,data.support).is_empty():return ["Moving equipment part lacks its receiving prerequisites."]
		if data.owner == "left_leg" and not data.fixture_engaged:return ["Structural handling requires the leg fixture."]
		if data.owner == "pelvis" and (leg.parent != "pelvis" or not data.assisting):return ["Hip retainer handling requires a seated hoist-supported leg."]
	elif data.uid not in ["foot","left_leg"]:return ["Unknown supported moving assembly."]
	if data.operation in FOOT_PHASES and (data.uid != "foot" or data.owner != "left_leg" or data.slot != "foot" or data.support != "foot_hoist"):return ["Foot transfer has invalid connection metadata."]
	if data.operation in ["leg_seat","leg_unseat"] and (data.uid != "left_leg" or data.owner != "pelvis" or data.slot != "left_leg" or data.support != "leg_hoist"):return ["Leg seating has invalid connection metadata."]
	if data.operation in ["leg_transfer","leg_return"] and (data.uid != "left_leg" or not data.owner.is_empty() or not data.slot.is_empty() or data.support != "leg_hoist"):return ["Leg transport has invalid connection metadata."]
	if data.operation in FOOT_PHASES and (foot.location != "support:foot_hoist" or not data.foot_departed or not model.milestone("foot","complete")):return ["Foot handoff state is invalid."]
	if data.operation.begins_with("leg_") and (leg.location != "support:leg_hoist" or not data.assisting):return ["Moving leg is not hoist supported."]
	if data.operation == "leg_transfer" and data.leg_stage != "fixture":return ["Leg transfer must start at its fixture."]
	if data.operation in ["leg_return","leg_seat"] and data.leg_stage != "approach":return ["Leg return or seating must start at the pelvis approach."]
	if data.operation == "leg_unseat" and data.leg_stage != "seated":return ["Leg unseating must start at the hip."]
	var from = _transform(data.start_pose) if data.segment == 0 else _transform(data.waypoints[data.segment-1])
	var expected_pose = from.interpolate_with(_transform(data.waypoints[data.segment]),data.progress)
	if not is_part:
		var actual_pose = _transform(data.foot_pose if data.uid == "foot" else data.leg_pose)
		if not actual_pose.is_equal_approx(expected_pose):return ["Moving assembly pose disagrees with travel progress."]
	return _validate_route(data,model)

func _validate_route(data: Dictionary, model: AssemblyModel) -> Array[String]:
	var route: Array[Transform3D] = []
	var leg_pose = _transform(data.leg_pose)
	var foot_target = leg_pose*game.runtime.local_slot_pose("left_leg","foot")
	if data.operation == "leg_transfer":route = _leg_route(false)
	elif data.operation == "leg_return":route = _leg_route(true)
	elif data.operation == "leg_seat":route = [game.runtime.mount_pose("pelvis","left_leg","left_leg")]
	elif data.operation == "leg_unseat":route = [Transform3D(Basis.IDENTITY,Layout.approach_origin())]
	elif data.operation in FOOT_PHASES:route = _foot_route(foot_target,data.operation == "foot_return")
	else:
		var parent_pose = leg_pose if data.owner == "left_leg" else game.runtime.node(data.owner).global_transform
		var target = parent_pose*game.runtime.local_slot_pose(data.owner,data.slot)
		route = _part_route(stock_poses[data.uid],target,data.operation == "part_return")
	if route.size()!=data.waypoints.size():return ["Equipment route does not match this operation."]
	for index in range(route.size()):
		if not route[index].is_equal_approx(_transform(data.waypoints[index])):return ["Equipment route has an unauthorized destination."]
	var expected_start = _transform(data.start_pose)
	if data.operation == "foot_seat":expected_start = Transform3D(Basis.IDENTITY,FOOT_DISPATCH)
	elif data.operation == "foot_return":expected_start = foot_target
	elif data.operation in ["leg_transfer"]:expected_start = Transform3D(Basis.IDENTITY,Layout.LEG_ORIGIN)
	elif data.operation in ["leg_return","leg_seat"]:expected_start = Transform3D(Basis.IDENTITY,Layout.approach_origin())
	elif data.operation == "leg_unseat":expected_start = game.runtime.mount_pose("pelvis","left_leg","left_leg")
	elif data.operation == "part_install":expected_start = stock_poses[data.uid]
	elif data.operation == "part_return":
		var parent_pose = leg_pose if data.owner == "left_leg" else game.runtime.node(data.owner).global_transform
		expected_start = parent_pose*game.runtime.local_slot_pose(data.owner,data.slot)
	if not expected_start.is_equal_approx(_transform(data.start_pose)):return ["Equipment travel starts outside its authorized station."]
	return []

func apply(data: Dictionary) -> void:
	operation = data.operation;uid = data.uid;receiving_owner = data.owner;slot = data.slot;support = data.support
	waypoints.clear()
	for point in data.waypoints:waypoints.append(_transform(point))
	segment = int(data.segment);progress = data.progress;start_pose = _transform(data.start_pose)
	foot_departed = data.foot_departed;assisting = data.assisting;released = data.released;stabilized = data.stabilized;fixture_engaged = data.fixture_engaged;leg_stage = data.leg_stage;blocked_reason = data.blocked_reason
	game.runtime.node("foot").global_transform = _transform(data.foot_pose)
	game.runtime.node("left_leg").global_transform = _transform(data.leg_pose)
	_sync_stock()
	if moving and parts.has(uid):
		var from = start_pose if segment == 0 else waypoints[segment-1]
		stock_bodies[uid].global_transform = from.interpolate_with(waypoints[segment],progress)
	if foot_departed:
		game.foot_fixture.carriage.global_transform = _transform(data.carrier_pose)
		game.foot_fixture.rotator.global_transform = game.foot_fixture.carriage.global_transform*Transform3D(Basis.IDENTITY,Vector3.UP*FOOT_DISPATCH.y)
	_refresh()
