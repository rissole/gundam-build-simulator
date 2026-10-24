extends "res://scripts/equipment.gd"
## Shared delivery configuration. Fingers retract before wing swing; rear
## guards collapse, inner leaves fold upward, then outer leaves rise. Every
## intermediate phase is stopped/resumed and serialized, with occupancy checks.
const Sweep = preload("res://scripts/motion_sweep.gd")
const Codec = preload("res://scripts/pose_codec.gd")
var blockout: Node3D
var spec: Dictionary
var channels: Dictionary = {}
var requested_mode = "work"
var moving = false
var blocked_reason = ""
var arm_services_stowed = false

func setup(workshop: Node3D, geometry: Node3D) -> void:
	game = workshop;blockout = geometry;spec = geometry.spec.access
	equipment_id = "workshop_access"
	for level in spec.levels:channels[str(level)] = {"value":0.0,"goal":0.0}
	channels["rear"] = {"value":0.0,"goal":0.0}
	_pose()

func frames_at(values: Dictionary) -> Dictionary:
	var result = {}
	for id in blockout.spec.groups:
		var record: Dictionary = blockout.spec.groups[id]
		if not record.has("joint") or record.joint == "clamp":continue
		var frame: Transform3D = blockout.authored_pose(record)
		var p: float = values.get(str(record.get("level",0)),0.0)
		var r: float = values.get("rear",0.0)
		match record.joint:
			"wing":frame.basis *= Basis(Vector3.UP,deg_to_rad(90)*clampf((p-.25)/.75,0,1)*(1 if record.side=="left" else -1))
			"finger":
				var extended = 1-clampf(p/.25,0,1)
				if record.level==11.2 and arm_services_stowed:extended = 0
				frame.origin.z += record.extension*extended*(1 if record.side=="left" else -1)
			"gate":
				# Stow inboard behind the closed wing, preserving the measured
				# outboard crane-line bypass. Close before the deck unlocks.
				frame.origin.x += record.stow_x*(1-clampf(p/.02,0,1))
			"rear_guard":frame.basis = frame.basis.scaled(Vector3(1,lerpf(1,.07,clampf(r/.15,0,1)),1))
			"rear_inner":frame.basis *= Basis(Vector3.BACK,PI*clampf((r-.15)/.45,0,1))
			"rear_outer":frame.basis *= Basis(Vector3.BACK,PI/2*clampf((r-.6)/.4,0,1))
		result[id] = frame
	return result

func values() -> Dictionary:
	var result = {}
	for key in channels:result[key] = channels[key].value
	return result

func ready_for(mode: String) -> bool:
	if not mode in spec.modes or moving:return false
	var goals = _goals(mode)
	for key in channels:
		if not is_equal_approx(channels[key].value,goals[key]):return false
	return true

func _goals(mode: String) -> Dictionary:
	var goals = {}
	for level in spec.levels:goals[str(level)] = 1.0 if level in spec.modes[mode] else 0.0
	goals.rear = 1.0 if mode=="leg" else 0.0
	return goals

func request_mode(mode: String) -> String:
	if not mode in spec.modes:return "Unknown workshop access configuration."
	if game.paused:return "Resume the workshop before moving access platforms."
	if moving and mode!=requested_mode:return "Stop the platforms before selecting another delivery."
	var goals = _goals(mode)
	var error = motion_error(values(),goals)
	if not error.is_empty():blocked_reason = error;return error
	requested_mode = mode
	for key in channels:channels[key].goal = goals[key]
	moving = not ready_for(mode)
	blocked_reason = ""
	return ""

func action_error(action: String) -> String:
	if action=="stop":return "" if moving else "The access platforms are stopped."
	if action=="advance" or action=="return":return ""
	return "Unknown access control."

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():return error
	if action=="stop":moving = false;return ""
	return request_mode(requested_mode if action=="advance" else "work")

func physics(delta: float) -> void:
	if game.paused or not moving:return
	var next = values()
	for key in channels:next[key] = move_toward(channels[key].value,channels[key].goal,delta/spec.duration)
	blocked_reason = motion_error(values(),next)
	if not blocked_reason.is_empty():moving = false;return
	for key in channels:channels[key].value = next[key]
	_pose()
	moving = channels.values().any(func(channel):return not is_equal_approx(channel.value,channel.goal))

func motion_error(from: Dictionary, to: Dictionary) -> String:
	var roots: Array = []
	for id in blockout.spec.groups:
		var record: Dictionary = blockout.spec.groups[id]
		if record.get("joint","") in ["wing","gate","rear_outer"]:roots.append(id)
	# Deliberate hinged joints and shared floor contacts are excluded only from
	# each other. Loads, workers, stock, elevators and static world remain solid.
	var excluded: Array[RID] = blockout.rids_for_groups(roots)
	for id in roots:
		for contact in blockout.spec.groups[id].get("motion_contacts",[]):excluded.append(blockout.pieces[contact].body.get_rid())
	var span = 0.0
	for key in channels:span = maxf(span,absf(to[key]-from[key]))
	if span<.000001:return ""
	# Outer wing tip travel bounds the sampling distance, including a full turn.
	var samples = maxi(1,ceili(span*spec.wing_length*PI/.025))
	var space = get_world_3d().direct_space_state
	for index in range(samples+1):
		var interpolated = {}
		for key in channels:interpolated[key] = lerpf(from[key],to[key],float(index)/samples)
		for shape in blockout.shapes_at(roots,frames_at(interpolated)):
			# Stationary channels do not reserve their occupied working platforms.
			var parent: String = blockout.pieces[shape.id].spec.parent
			while not parent.is_empty() and not blockout.spec.groups[parent].has("level"):parent = blockout.spec.groups[parent].parent
			var record: Dictionary = blockout.spec.groups.get(parent,{})
			var key = "rear" if parent.begins_with("rear_") else str(record.get("level",0))
			if not from.has(key) or is_equal_approx(from[key],to[key]):continue
			var hit = Sweep.overlap(space,shape.shape,shape.world,15,excluded,-.004)
			if not hit.is_empty():
				if OS.has_environment(Sweep.DIAGNOSTIC_ENV):
					var target=hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape))
					print("ACCESS_CONTACT ",shape.id," at=",shape.world.origin," collider=",hit.collider," source=",target.get_meta("source_uid","") if target!=null else "")
				return "Clear the access platform sweep: "+str(hit.collider.name)+" blocks "+shape.id+"."
	return ""

func _pose() -> void:
	blockout.apply_frames(frames_at(values()))

func busy_reason(subject: String) -> String:
	return "Wait for the shared work platforms to lock." if moving and subject in ["rail","crane","workshop_access"] else ""

func status_text() -> String:
	if not blocked_reason.is_empty():return blocked_reason
	return "Access / "+requested_mode+(" · moving" if moving else " · stopped")

func capture() -> Dictionary:
	return {"version":1,"channels":channels.duplicate(true),"mode":requested_mode,"moving":moving,"arm_services_stowed":arm_services_stowed}

func validate(data: Variant, _candidate: AssemblyModel = null, _world: Dictionary = {}) -> Array[String]:
	if not Codec.same_keys(data,["version","channels","mode","moving","arm_services_stowed"]) or data.version!=1:return ["Invalid access-platform snapshot."]
	if not data.mode is String or not data.mode in spec.modes or not data.moving is bool or not data.arm_services_stowed is bool:return ["Invalid access-platform mode."]
	if not Codec.same_keys(data.channels,channels.keys()):return ["Access-platform identities changed."]
	var goals = _goals(data.mode)
	for key in channels:
		var channel: Variant = data.channels[key]
		if not Codec.same_keys(channel,["value","goal"]):return ["Invalid platform phase."]
		for field in ["value","goal"]:
			if not Codec.number(channel[field]) or channel[field]<0 or channel[field]>1:return ["Platform phase out of range."]
		if not is_equal_approx(channel.goal,goals[key]):return ["Platform goal disagrees with delivery configuration."]
	return []

func apply(data: Dictionary) -> void:
	if not validate(data).is_empty():return
	channels = data.channels.duplicate(true);requested_mode = data.mode;moving = data.moving
	arm_services_stowed = data.arm_services_stowed;blocked_reason = "";_pose()
