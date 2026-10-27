extends "res://scripts/equipment.gd"
## Shared delivery configuration. Fingers retract before wing swing; rear
## guards collapse, inner leaves fold upward, then outer leaves rise. Every
## intermediate phase is stopped/resumed and serialized. The gantry's access
## platforms deliberately clip through loose parts and players instead of
## sweeping for clearance (user decision, 2026-10-26): a whole-route sweep
## stalled each delivery for ~0.4 s. Retained lower decks still carry riders;
## the upper rope leaves wait until nobody is aboard and their ropes are recalled.
const Codec = preload("res://scripts/pose_codec.gd")
var blockout: Node3D
var spec: Dictionary
var channels: Dictionary = {}
var requested_mode = "work"
var moving = false
var blocked_reason = ""

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

## The crane requests the upper crossing independently of lower work access.
func upper_ready(open: bool) -> bool:
	var channel: Dictionary=channels.get("20.6",{})
	var target=1.0 if open else 0.0
	return not channel.is_empty() and is_equal_approx(channel.value,target) and is_equal_approx(channel.goal,target)

func request_upper(open: bool) -> String:
	if not channels.has("20.6"):return "The upper access leaves are unavailable."
	if game.paused:return "Resume the workshop before moving access platforms."
	channels["20.6"].goal=1.0 if open else 0.0
	moving=channels.values().any(func(channel):return not is_equal_approx(channel.value,channel.goal))
	blocked_reason=rope_motion_error() if moving else ""
	return ""

func lower_ready(mode: String) -> bool:
	if not mode in spec.modes:return false
	var goals=_goals(mode)
	for key in channels:
		if key=="20.6":continue
		if not is_equal_approx(channels[key].value,goals[key]) or not is_equal_approx(channels[key].goal,goals[key]):return false
	return true

func request_lower_mode(mode: String) -> String:
	if not mode in spec.modes:return "Unknown workshop access configuration."
	if game.paused:return "Resume the workshop before moving access platforms."
	var goals=_goals(mode)
	requested_mode=mode
	for key in channels:
		if key!="20.6":channels[key].goal=goals[key]
	moving=channels.values().any(func(channel):return not is_equal_approx(channel.value,channel.goal))
	blocked_reason=rope_motion_error() if moving else ""
	return ""

func request_mode(mode: String) -> String:
	if not mode in spec.modes:return "Unknown workshop access configuration."
	if game.paused:return "Resume the workshop before moving access platforms."
	if moving and mode!=requested_mode:return "Stop the platforms before selecting another delivery."
	var goals = _goals(mode)
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
	blocked_reason = rope_motion_error()
	var next = values()
	for key in channels:
		if key=="20.6" and not blocked_reason.is_empty():continue
		next[key] = move_toward(channels[key].value,channels[key].goal,delta/spec.duration)
	for key in channels:channels[key].value = next[key]
	_pose()
	moving = channels.values().any(func(channel):return not is_equal_approx(channel.value,channel.goal))

## A pending trip waits and resumes after free front lines are recalled.
func rope_motion_error() -> String:
	var channel: Dictionary = channels.get("20.6",{})
	if channel.is_empty() or is_equal_approx(channel.value,channel.goal):return ""
	var rope = game.equipment.get_equipment("rope_access")
	if rope!=null and not rope.front_ropes_clear():return rope.LEAF_REASON
	var floor=EquipmentRegistry.rider_floor(game)
	if floor!=null:
		for side in ["left","right"]:
			var leaf: Node=blockout.groups.get("wing_"+side+"_20.6")
			if leaf!=null and (floor==leaf or leaf.is_ancestor_of(floor)):
				return "Step off the workshop-side leaves before they move."
	return ""

func _pose() -> void:
	blockout.apply_frames(frames_at(values()))

func busy_reason(subject: String) -> String:
	return "Wait for the shared work platforms to lock." if moving and subject in ["rail","crane","workshop_access"] else ""

func status_text() -> String:
	if not blocked_reason.is_empty():return blocked_reason
	return "Access / "+requested_mode+(" · moving" if moving else " · stopped")

func capture() -> Dictionary:
	return {"version":1,"channels":channels.duplicate(true),"mode":requested_mode,"moving":moving}

func validate(data: Variant, _candidate: AssemblyModel = null, _world: Dictionary = {}) -> Array[String]:
	if not Codec.same_keys(data,["version","channels","mode","moving"]) or data.version!=1:return ["Invalid access-platform snapshot."]
	if not data.mode is String or not data.mode in spec.modes or not data.moving is bool:return ["Invalid access-platform mode."]
	if not Codec.same_keys(data.channels,channels.keys()):return ["Access-platform identities changed."]
	var goals = _goals(data.mode)
	for key in channels:
		var channel: Variant = data.channels[key]
		if not Codec.same_keys(channel,["value","goal"]):return ["Invalid platform phase."]
		for field in ["value","goal"]:
			if not Codec.number(channel[field]) or channel[field]<0 or channel[field]>1:return ["Platform phase out of range."]
		if key!="20.6" and not is_equal_approx(channel.goal,goals[key]):return ["Platform goal disagrees with delivery configuration."]
	return []

func apply(data: Dictionary) -> void:
	if not validate(data).is_empty():return
	channels = data.channels.duplicate(true);requested_mode = data.mode;moving = data.moving
	blocked_reason = "";_pose()
