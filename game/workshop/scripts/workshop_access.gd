extends "res://scripts/equipment.gd"
## Player-operated independent gantry fronts. Fingers retract before wing swing; rear
## guards collapse, inner leaves fold upward, then outer leaves rise. Every
## front can reverse at any intermediate phase. The gantry's access
## platforms deliberately clip through loose parts and players instead of
## sweeping for clearance (user decision, 2026-10-26): a whole-route sweep
## stalled each delivery for ~0.4 s. Retained lower decks still carry riders;
## the upper rope leaves wait until nobody is aboard and their ropes are recalled.
const Codec = preload("res://scripts/pose_codec.gd")
var blockout: Node3D
var spec: Dictionary
var channels: Dictionary = {}
const FRONTS = {"upper":["20.6"],"lower":["8.4","rear"]}
const MANUAL_COMMANDS = ["upper_open","upper_close","lower_open","lower_close"]
var moving = false
var blocked_reason = ""
var upper_controls: Array[Dictionary] = []

func setup(workshop: Node3D, geometry: Node3D) -> void:
	game = workshop;blockout = geometry;spec = geometry.spec.access
	equipment_id = "workshop_access"
	for level in spec.levels:channels[str(level)] = {"value":0.0,"goal":0.0}
	channels["rear"] = {"value":0.0,"goal":0.0}
	_make_upper_controls()
	_pose()

## Single-row banks on the fixed left hinge aprons. The low fascia and measured
## facing angles keep the near wing/leaf in view without blocking the lift route.
func _make_upper_controls() -> void:
	if not blockout.spec.has("elevators"):return
	var origin=Codec.to_vector(blockout.spec.elevators.left.origin)
	var steel=game.material(Color("485f68"),.6)
	for row in [["lower","LOWER GANTRY",8.4,Vector2(2.9,.35),-90.0],["upper","UPPER GANTRY",20.6,Vector2(2.65,.30),-75.0]]:
		var bank=StaticBody3D.new();add_child(bank)
		bank.position=Vector3(origin.x+row[3].x,row[2],origin.z+row[3].y)
		bank.rotation.y=deg_to_rad(row[4])
		for member in [[Vector3(0,.25,0),Vector3(.08,.50,.08)],[Vector3(0,.74,0),Vector3(.64,.48,.08)]]:
			game.box(bank,member[0],member[1],steel)
			var shape=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=member[1];shape.position=member[0];bank.add_child(shape)
		var label=Label3D.new();bank.add_child(label);label.position=Vector3(0,.83,.05)
		label.text=row[1];label.font_size=32;label.pixel_size=.0018;label.outline_size=0
		for control in [["open","OPEN",-.17],["close","CLOSE",.17]]:
			var action: String=row[0]+"_"+control[0]
			var key=preload("res://scripts/equipment_button.gd").make(game,bank,Vector3(control[2],.65,.075),control[1],0,control[0]=="close")
			upper_controls.append(control_entry(key,action,manual_subject({"command":action})+" · "+control[1].capitalize(),.13,{"point":key.global_position}))

func controls() -> Array[Dictionary]:return upper_controls

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

func _front_at(front: String, target: float) -> bool:
	if not FRONTS.has(front):return false
	for key in FRONTS[front]:
		if not channels.has(key) or not is_equal_approx(channels[key].value,target) or not is_equal_approx(channels[key].goal,target):return false
	return true

func front_open(front: String) -> bool:return _front_at(front,1.0)
func front_closed(front: String) -> bool:return _front_at(front,0.0)

func _occupant_error(front: String) -> String:
	for equipment in game.equipment.all():
		var occupant: String=equipment.gantry_occupant(front)
		if not occupant.is_empty():return "Move the %s out of the gantry before closing the %s." % [occupant,manual_subject({"command":front+"_close"}).to_lower()]
	return ""

func action_error(action: String) -> String:
	if action not in MANUAL_COMMANDS:return "Unknown access control."
	if game.paused:return "Resume the workshop before moving access platforms."
	return _occupant_error(action.get_slice("_",0)) if action.ends_with("_close") else ""

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():return error
	for key in FRONTS[action.get_slice("_",0)]:channels[key].goal=1.0 if action.ends_with("_open") else 0.0
	moving=channels.values().any(func(channel):return not is_equal_approx(channel.value,channel.goal))
	blocked_reason=rope_motion_error() if moving else ""
	return ""

func manual_commands() -> Array:return MANUAL_COMMANDS
func command_label(action: String, _task: String = "") -> String:return "Open" if action.ends_with("_open") else "Close"
func manual_subject(objective: Dictionary) -> String:return "Upper gantry" if str(objective.get("command","")).begins_with("upper_") else "Lower gantry"
## Each gantry's panel stands on its own level, in view of what it moves.
func manual_hint(objective: Dictionary) -> String:
	return manual_subject(objective).to_upper()+" panel at "+("20.6" if str(objective.get("command","")).begins_with("upper_") else "8.4")+" m beside the left lift"
## `<front>_open` stays true while an opened front closes, so a page's OPEN step
## stays ticked while its CLOSE step is still in progress.
func manual_state() -> Dictionary:
	return {"upper_open":front_open("upper") or _front_closing("upper"),"upper_closed":front_closed("upper"),"lower_open":front_open("lower") or _front_closing("lower"),"lower_closed":front_closed("lower")}
func _front_closing(front: String) -> bool:
	return FRONTS[front].all(func(key):return channels[key].goal==0.0) and FRONTS[front].any(func(key):return channels[key].value>0.0)
func manual_effect(objective: Dictionary) -> Dictionary:
	var command: String=objective.get("command","")
	if command not in MANUAL_COMMANDS:return {}
	# Opening and closing are opposite end states; each clears the other so a
	# page that opens then closes a front never expects both at once.
	var front: String=command.get_slice("_",0)
	return {front+"_open":command.ends_with("_open"),front+"_closed":command.ends_with("_close")}

func physics(delta: float) -> void:
	if game.paused or not moving:return
	var upper_error = rope_motion_error()
	blocked_reason = upper_error
	var lower_error = _occupant_error("lower") if channels["8.4"].goal<channels["8.4"].value else ""
	if blocked_reason.is_empty():blocked_reason=lower_error
	var next = values()
	for key in channels:
		if key=="20.6" and not upper_error.is_empty():continue
		if key in FRONTS.lower and not lower_error.is_empty():continue
		next[key] = move_toward(channels[key].value,channels[key].goal,delta/spec.duration)
	for key in channels:channels[key].value = next[key]
	_pose()
	moving = channels.values().any(func(channel):return not is_equal_approx(channel.value,channel.goal))

## Check current occupancy before moving the leaves, independent of the crane's
## later physics tick. A stopped crane can still have cables through the opening.
func rope_motion_error() -> String:
	var channel: Dictionary = channels.get("20.6",{})
	if channel.is_empty() or is_equal_approx(channel.value,channel.goal):return ""
	if channel.goal<channel.value:
		var occupied = _occupant_error("upper")
		if not occupied.is_empty():return occupied
	var rope = game.equipment.get_equipment("rope_access")
	if rope!=null and not rope.front_ropes_clear():return rope.LEAF_REASON
	var crane=game.equipment.get_equipment("service_crane")
	if channel.goal<channel.value and crane!=null and crane.has_method("upper_crossing_occupied") and crane.upper_crossing_occupied():
		return "Wait for the crane cables to clear the upper gantry."
	var floor=EquipmentRegistry.rider_floor(game)
	if floor!=null:
		for side in ["left","right"]:
			var leaf: Node=blockout.groups.get("wing_"+side+"_20.6")
			if leaf!=null and (floor==leaf or leaf.is_ancestor_of(floor)):
				return "Step off the upper gantry before it moves."
	return ""

func _pose() -> void:
	blockout.apply_frames(frames_at(values()))

func busy_reason(subject: String) -> String:
	return "Wait for the shared work platforms to lock." if moving and subject in ["rail","crane","workshop_access"] else ""

func status_text() -> String:
	if not blocked_reason.is_empty():return blocked_reason
	return "Gantry fronts"+(" · moving" if moving else " · stopped")

func capture() -> Dictionary:
	return {"version":2,"channels":channels.duplicate(true),"moving":moving}

func validate(data: Variant, _candidate: AssemblyModel = null, _world: Dictionary = {}) -> Array[String]:
	if not Codec.same_keys(data,["version","channels","moving"]) or data.version!=2:return ["Invalid access-platform snapshot."]
	if not data.moving is bool:return ["Invalid access-platform motion."]
	if not Codec.same_keys(data.channels,channels.keys()):return ["Access-platform identities changed."]
	for key in channels:
		var channel: Variant = data.channels[key]
		if not Codec.same_keys(channel,["value","goal"]):return ["Invalid platform phase."]
		for field in ["value","goal"]:
			if not Codec.number(channel[field]) or channel[field]<0 or channel[field]>1:return ["Platform phase out of range."]
		if channel.goal not in [0.0,1.0]:return ["Invalid front goal."]
	if data.channels["8.4"]!=data.channels.rear:return ["Lower gantry channels disagree."]
	if data.moving!=data.channels.values().any(func(channel):return not is_equal_approx(channel.value,channel.goal)):return ["Front motion disagrees with its phases."]
	return []

func apply(data: Dictionary) -> void:
	if not validate(data).is_empty():return
	channels = data.channels.duplicate(true);moving = data.moving
	blocked_reason = "";_pose()
