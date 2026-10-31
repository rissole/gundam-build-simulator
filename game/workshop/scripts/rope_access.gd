extends "res://scripts/equipment.gd"
## Controlled descenders: length is anchor-to-harness, player origin is at feet.
## Geometry comes exclusively from the shared rope_stations contract.
const Codec = preload("res://scripts/pose_codec.gd")
const HARNESS = 1.0
const MIN_LENGTH = 0.15
const TRAVERSE_SPEED = 1.0
const TAP_SPEED = 0.6
const MAX_SPEED = 4.5
const ACCELERATION = 8.0
const TAP_TIME = 0.12
const SLACK = 0.35
const SWING_CAP = 1.5
const SWING_ANGLE = PI/3.0
# Scale effective gravity with length for a consistent 3.85 s period, even
# near the ground. At nine metres this is 24 m/s² before tangent projection.
const SWING_RESTORE = 24.0/9.0
const SWING_PUMP = 1.3
const SWING_DAMPING = 0.1
const SWING_RELEASE_DAMPING = 2.8
const SWING_STEP = 1.0/120.0
const BOARDING_CLEARANCE = 1.9
const STOW_LENGTH = 1.8
const BOARDING_DUCK = 0.75
const LEAF_REASON = "Unclip from the front rope before the upper gantry moves"
const EYE = 1.63
const SAMPLE_STEP = 0.3
const PREDICTIONS_PER_FRAME = 1
var blockout: Node3D
var stations: Dictionary = {}
var ropes: Dictionary = {}
var fixtures: Dictionary = {}
var attachment = ""
var hanging = false
var swing_velocity = Vector3.ZERO
var brace_normal = Vector3.ZERO
# Manual cue service predictions by station and connection point.
var _served: Dictionary = {}
var _prediction_budget = PREDICTIONS_PER_FRAME
# Input acceleration is transient; loading a snapshot always starts at rest.
var _vertical_direction = 0.0
var _vertical_held = 0.0

func reset_motion() -> void:
	_vertical_direction=0.0;_vertical_held=0.0

func reset_swing() -> void:
	swing_velocity=Vector3.ZERO;brace_normal=Vector3.ZERO

func below_boarding(at: Vector3) -> bool:
	return at.y<deck_height(attachment)-BOARDING_CLEARANCE

func swing_radius(length: float) -> float:
	return minf(SWING_CAP,length*sin(SWING_ANGLE))

func pose_length(id: String, at: Vector3) -> float:
	return anchor(id).distance_to(at+Vector3.UP*HARNESS) if at.y<deck_height(id)-BOARDING_CLEARANCE else anchor(id).y-at.y-HARNESS

func _vertical_distance(seconds: float) -> float:
	var ramp=(MAX_SPEED-TAP_SPEED)/ACCELERATION
	var accelerating=clampf(seconds-TAP_TIME,0,ramp)
	var cruising=maxf(0,seconds-TAP_TIME-ramp)
	return TAP_SPEED*seconds+.5*ACCELERATION*accelerating*accelerating+(MAX_SPEED-TAP_SPEED)*cruising

## Integrate the ramp across the whole tick, including its tap/cruise boundaries.
## Release, reversal and conflicting inputs start a fresh precision tap.
func vertical_step(direction: float, delta: float) -> float:
	if is_zero_approx(direction):reset_motion();return 0.0
	if direction!=_vertical_direction:reset_motion();_vertical_direction=direction
	var next=_vertical_held+delta
	var distance=_vertical_distance(next)-_vertical_distance(_vertical_held)
	_vertical_held=minf(next,TAP_TIME+(MAX_SPEED-TAP_SPEED)/ACCELERATION)
	return direction*distance

func setup(workshop: Node, geometry: Node3D) -> void:
	game = workshop;blockout = geometry;equipment_id = "rope_access"
	for record in blockout.spec.get("rope_stations",[]):
		var id: String = record.id
		stations[id] = record.duplicate(true)
		ropes[id] = {"deployed":false,"length":MIN_LENGTH}
		_build_station(id)
	physics(0)

func anchor(id: String) -> Vector3:
	var record: Dictionary = stations[id]
	var local = Codec.to_vector(record.anchor)
	return local if record.parent.is_empty() else blockout.groups[record.parent].global_transform*local

func deck_height(id: String) -> float:return anchor(id).y-1.2
func max_length(id: String) -> float:return maxf(MIN_LENGTH,anchor(id).y-HARNESS)
func horizontal(v: Vector3) -> Vector3:return Vector3(v.x,0,v.z)
func attached() -> bool:return not attachment.is_empty()

## Toward the walkway from the davit. Front follows its leaf's local frame.
func deck_direction(id: String) -> Vector3:
	var record: Dictionary = stations[id]
	if record.edge == "rear":return Vector3.BACK
	var local = Vector3(0,0,-signf(float(record.anchor[2])))
	return (blockout.groups[record.parent].global_basis*local).normalized()

func gate_point(id: String) -> Vector3:
	return anchor(id)+deck_direction(id)*(2.03 if stations[id].edge=="rear" else .18)-Vector3.UP*.65

func end_point(id: String) -> Vector3:
	return anchor(id)-Vector3.UP*float(ropes[id].length)

## Moving the leaves stows every front rope nobody is clipped to.
func stow_free_front() -> void:
	for id in stations:
		if stations[id].edge=="front" and attachment!=id and ropes[id].deployed:ropes[id]={"deployed":false,"length":MIN_LENGTH}
	physics(0)

func front_ropes_clear() -> bool:
	for id in stations:
		if stations[id].edge=="front" and (ropes[id].deployed or attachment==id):return false
	return true

## A grounded clipped rider may unclip before taking another machine's trip.
## This uses the existing short-travel guard, without special rider carrying.
func travel_error(carrier_id: String, _from: float, _to: float) -> String:
	if not attached() or hanging:return ""
	var carrier=game.equipment.get_equipment(carrier_id)
	var floor=EquipmentRegistry.rider_floor(game)
	if carrier!=null and floor!=null and carrier.carries(floor):return "Unclip the rope before riding this platform."
	return ""

func front_available(id: String) -> bool:
	if stations[id].edge!="front":return true
	var access = game.equipment.get_equipment("workshop_access")
	if access==null:return true
	var channel: Dictionary = access.channels.get("20.6",{})
	return not access.moving and (channel.is_empty() or is_zero_approx(channel.value))

## A fresh collision query also works immediately after loading a hanging save.
func on_floor() -> bool:
	if not is_instance_valid(game.get("player")):return false
	var collision = KinematicCollision3D.new()
	# At the top limit feet are .05 m above deck, plus .01 m capsule clearance.
	# Leave a small tolerance so that boarding pose can settle onto the deck.
	return game.player.test_move(game.player.global_transform,Vector3.DOWN*.08,collision) and collision.get_normal().y>.65

func gate_passable(id: String) -> bool:return attachment==id

## Neighbouring 0.9 m openings overlap. Remove the selected opening from every
## barrier it overlaps, so a closed neighbour cannot narrow the active passage.
func gate_span(id: String) -> Vector2:
	if gate_passable(id):return Vector2.ZERO
	var span=Vector2(-.45,.45)
	if not attached() or stations[id].edge!=stations[attachment].edge:return span
	var toward=deck_direction(id)
	var side=Vector3(toward.z,0,-toward.x)
	var offset=gate_point(attachment)-gate_point(id)
	if absf(offset.dot(toward))>.1:return span
	var centre=offset.dot(side)
	if centre>0:span.y=minf(span.y,maxf(span.x,centre-.45))
	else:span.x=maxf(span.x,minf(span.y,centre+.45))
	return span

func boarding_duck(feet_y: float) -> bool:
	return attached() and feet_y>=deck_height(attachment)-BOARDING_DUCK

## Guidance describes where a front rope works after its leaf is closed.
## Mechanical line positions always continue to use the live anchor().
func working_anchor(id: String) -> Vector3:
	var record: Dictionary=stations[id]
	if record.edge!="front":return anchor(id)
	var frames={}
	frames[record.parent]=blockout.authored_pose(blockout.spec.groups[record.parent])
	return blockout.frame_at(record.parent,frames)*Codec.to_vector(record.anchor)

func _build_station(id: String) -> void:
	var node = Node3D.new();add_child(node)
	var gold = StandardMaterial3D.new();gold.albedo_color=Color("bb893b")
	var line_material = StandardMaterial3D.new();line_material.albedo_color=Color("df9e71")
	var gate = StaticBody3D.new();node.add_child(gate);gate.collision_layer=1;gate.collision_mask=8
	gate.name="RopeGate"
	var shape = CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=Vector3(.9,1.1,.06);gate.add_child(shape)
	var bar = _box(gate,Vector3(0,.42,0),Vector3(.9,.09,.06),gold)
	var clip = _box(node,Vector3.ZERO,Vector3(.12,.18,.12),gold)
	var recall = _box(node,Vector3.ZERO,Vector3(.10,.10,.10),gold)
	var end = _box(node,Vector3.ZERO,Vector3(.10,.16,.10),gold)
	var line = _box(node,Vector3.ZERO,Vector3(.018,1,.018),line_material)
	fixtures[id]={"root":node,"gate":gate,"shape":shape,"bar":bar,"clip":clip,"recall":recall,"end":end,"line":line}

func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var node=MeshInstance3D.new();node.mesh=BoxMesh.new();node.mesh.size=size;node.material_override=material;parent.add_child(node);node.position=at
	return node

func _line(node: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	var offset=to-from
	node.visible=offset.length()>.01
	if not node.visible:return
	node.global_position=(from+to)*.5
	node.global_basis=Basis(Quaternion(Vector3.UP,offset.normalized()))
	node.scale=Vector3(1,offset.length(),1)

func physics(_delta: float) -> void:
	for id in stations:
		var f: Dictionary=fixtures[id]
		var toward=deck_direction(id)
		var side=Vector3(toward.z,0,-toward.x)
		var span=gate_span(id)
		var width=maxf(.001,span.y-span.x)
		if not is_equal_approx(f.shape.shape.size.x,width):
			f.shape.shape.size.x=width
			f.bar.mesh.size.x=width
		f.gate.global_position=gate_point(id)+side*(span.x+span.y)*.5
		f.gate.global_rotation.y=atan2(toward.x,toward.z)
		f.gate.collision_layer=0 if gate_passable(id) else 1
		f.bar.visible=not gate_passable(id)
		f.gate.force_update_transform()
		PhysicsServer3D.body_set_state(f.gate.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,f.gate.global_transform)
		# Controls sit at the gate's side, reachable from the walkway even with
		# the rear davit tip two metres beyond it.
		f.clip.global_position=gate_point(id)+side*.34+Vector3.UP*.45+toward*.12
		f.recall.global_position=f.clip.global_position+Vector3.UP*.25
		f.end.global_position=end_point(id)
		f.end.visible=ropes[id].deployed and attachment!=id
		var end: Vector3=game.player.global_position+Vector3.UP*HARNESS if attachment==id and is_instance_valid(game.get("player")) else end_point(id)
		_line(f.line,anchor(id),end)
		f.line.visible=ropes[id].deployed

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for id in stations:
		var f: Dictionary=fixtures[id]
		for item in [["clip:",f.clip,"Clip in · gate opens"],["recall:",f.recall,"Recall rope"]]:
			result.append(control_entry(item[1],item[0]+id,item[2],.12,{"point":item[1].global_position,"success_toast":item[0]=="recall:"}))
		if ropes[id].deployed and attachment!=id:
			result.append(control_entry(f.end,"end:"+id,"Clip into hanging rope",.14,{"point":f.end.global_position,"success_toast":false}))
	return result

func action_error(action: String) -> String:
	var parts=action.split(":",true,1)
	if parts.size()!=2 or not stations.has(parts[1]):return "Unknown rope station."
	var id: String=parts[1]
	if parts[0]!="recall" and not front_available(id):return "Close the upper gantry before using a rope."
	match parts[0]:
		"recall":
			if attachment==id:return "Unclip on a floor before recalling the rope."
			return "" if ropes[id].deployed else "The rope is already stowed."
		"clip","end":
			if attached():return "Already clipped in · Q unclips on a floor."
			if not on_floor():return "Stand on a floor before clipping in."
			if parts[0]=="end":return "" if ropes[id].deployed else "The rope is stowed."
			if absf(game.player.global_position.y-deck_height(id))>.12:return "Use the hanging rope end from below."
			return ""
	return "Unknown rope control."

func request(action: String) -> String:
	var error=action_error(action)
	if not error.is_empty():return error
	var parts=action.split(":",true,1)
	var id: String=parts[1]
	var node: Node3D=fixtures[id][{"clip":"clip","end":"end","recall":"recall"}[parts[0]]]
	if game.camera.global_position.distance_to(node.global_position)>game.REACH:return "Move within reach of the rope control."
	if not game.targeting.can_see(node.global_position,[node]):return "The rope control is obstructed."
	if parts[0]=="recall":ropes[id]={"deployed":false,"length":MIN_LENGTH}
	else:
		reset_motion();reset_swing()
		attachment=id;hanging=false
		ropes[id].deployed=true
		ropes[id].length=clampf(pose_length(id,game.player.global_position),MIN_LENGTH,max_length(id))
		if boarding_duck(game.player.global_position.y):game.player_controller.update_crouch(true,1.0)
	physics(0)
	return ""

func unclip() -> String:
	if not attached():return "Clip in at a rope station or hanging rope end."
	if not on_floor():return "Land on a floor before unclipping."
	# Leave the end at harness height for the next ascent from this floor.
	# An end left within a person's height of its davit is simply stowed.
	ropes[attachment].length=clampf(pose_length(attachment,game.player.global_position),MIN_LENGTH,max_length(attachment))
	if ropes[attachment].length<STOW_LENGTH:ropes[attachment]={"deployed":false,"length":MIN_LENGTH}
	attachment="";hanging=false;reset_motion();reset_swing();physics(0)
	return ""

func status_text() -> String:
	if not attached():return ""
	return "Rope · %s · %.1f m%s\n%s" % ["hanging" if hanging else "clipped",ropes[attachment].length, " · ducking under davit" if boarding_duck(game.player.global_position.y) else "", "Space ↑ / Ctrl ↓ (hold: faster) · WASD swing / hold into surface to brace" if hanging else "Space ↑ / Ctrl ↓ · step through your gate · Q unclip"]

func capture() -> Dictionary:
	return {"version":2,"ropes":ropes.duplicate(true),"attachment":attachment,"hanging":hanging}

func validate(data: Variant, _candidate: AssemblyModel=null, world: Dictionary={}) -> Array[String]:
	if not Codec.same_keys(data,["version","ropes","attachment","hanging"]) or data.version!=2:return ["Invalid rope snapshot."]
	if not Codec.same_keys(data.ropes,stations.keys()):return ["Rope stations changed."]
	for id in stations:
		var state: Variant=data.ropes[id]
		if not Codec.same_keys(state,["deployed","length"]) or not state.deployed is bool or not Codec.number(state.length):return ["Invalid rope state."]
		if state.length<MIN_LENGTH or state.length>max_length(id)+.001 or (not state.deployed and not is_equal_approx(state.length,MIN_LENGTH)):return ["Rope length out of range."]
	var equipment_state: Variant=world.get("equipment",{})
	if not equipment_state is Dictionary:return ["Invalid rope world state."]
	var access_state: Variant=equipment_state.get("workshop_access",{})
	if not access_state is Dictionary or not access_state.get("channels",{}) is Dictionary:return ["Invalid rope leaf state."]
	var access_channel: Variant=access_state.get("channels",{}).get("20.6",{})
	if not access_channel is Dictionary:return ["Invalid rope leaf channel."]
	if not access_channel.is_empty():
		for id in stations:
			if stations[id].edge=="front" and data.ropes[id].deployed and (not Codec.number(access_channel.get("value")) or not is_zero_approx(access_channel.value)):return ["Deployed rope is on an open leaf."]
	if not data.attachment is String or not data.hanging is bool:return ["Invalid rope attachment."]
	if data.attachment.is_empty():
		if data.hanging:return ["Unattached rope has player state."]
	else:
		if not stations.has(data.attachment) or not data.ropes[data.attachment].deployed:return ["Player attached to a stowed or unknown rope."]
		var player: Variant=world.get("player",[])
		if not world.is_empty() and not Codec.valid_vector(player,5):return ["Attached rope requires a finite player pose."]
		if player is Array and player.size()==5:
			var at=Vector3(player[0],player[1],player[2])
			var length=float(data.ropes[data.attachment].length)
			if absf(pose_length(data.attachment,at)-length)>.12:return ["Rope length disagrees with player pose."]
			var radius=swing_radius(length) if at.y<deck_height(data.attachment)-BOARDING_CLEARANCE else (2.6 if at.y>=deck_height(data.attachment)-.08 else SLACK)
			if horizontal(at-anchor(data.attachment)).length()>radius+.05:return ["Player is outside the rope envelope."]
			if at.y>anchor(data.attachment).y-HARNESS or at.y<-.05:return ["Player is outside the rope height range."]
	return []

func apply(data: Dictionary) -> void:
	if not validate(data).is_empty():return
	reset_motion();reset_swing()
	ropes=data.ropes.duplicate(true);attachment=data.attachment;hanging=data.hanging
	# Equipment restores before the saved player pose. Derive the boarding shape
	# from line length, so a reload never starts standing inside a boom.
	if attached() and boarding_duck(anchor(attachment).y-HARNESS-float(ropes[attachment].length)):
		game.player_controller.update_crouch(true,1.0)
	physics(0)

## Resolve the tracked objective's real connection points; no recipe-name list
## or wording heuristic. Existing guidance owns range, occlusion and glow.
## A station is cued only when its own rope can serve an open point.
func access_control_entries(objective: Dictionary, owner: String, machine: Node) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if attached():return result
	var work: Array[Dictionary]=[]
	if is_instance_valid(machine):
		for entry in machine.manual_control_entries(objective):
			if entry.has("point"):work.append({"point":entry.point,"allowed":entry.get("allowed",[]),"body_hit":entry.get("allow_body_hit",false),"depth":.065})
	if objective.get("op","") in ["fit","seat"] and game.model.assemblies.has(owner):
		var slots: Array=objective.get("slots",[objective.get("slot","")])
		for sid in slots:
			# Filled connections need no access; they only narrow the cue.
			if str(sid).is_empty() or not game.model.assemblies[owner].slots.has(sid) or not str(game.model.assemblies[owner].slots[sid]).is_empty():continue
			work.append({"point":game.components.slot_point(owner,sid),"allowed":game.components.receiving_bodies(owner,sid),"body_hit":game.components.service_access(owner,sid),"depth":game.components.sight_depth(owner,sid)})
	var access=game.equipment.get_equipment("workshop_access")
	var close_cued=false
	_prediction_budget=PREDICTIONS_PER_FRAME
	for entry in controls():
		if not entry.action.begins_with("clip:"):continue
		var id: String=entry.action.trim_prefix("clip:")
		for target in work:
			if not serves(id,target):continue
			if stations[id].edge=="front" and access!=null and not access.front_closed("upper"):
				if not close_cued:result.append_array(access.manual_control_entries({"command":"upper_close"}));close_cued=true
			elif action_error(entry.action).is_empty():result.append(entry)
			break
	return result

## Whether hanging on this rope reaches and sees `target` with normal reach:
## the player's capsule descends the plumb line until it meets a floor, then
## works plumb or swings toward the work until the capsule braces on contact.
## Front lines are judged closed, as they hang in service.
## Cached per point; manual guidance asks every frame, so new predictions are
## spread across frames and an unjudged station stays quiet meanwhile.
func serves(id: String, target: Dictionary) -> bool:
	var point: Vector3=target.point
	var line: Vector3=working_anchor(id)
	if point.y<=10.5 or point.y>=line.y or horizontal(point-line).length()>SWING_CAP+game.REACH:return false
	var key="%s|%.2f,%.2f,%.2f"%[id,point.x,point.y,point.z]
	if _served.has(key):return _served[key]
	if _prediction_budget<=0:return false
	_prediction_budget-=1
	if _served.size()>256:_served.clear()
	var result=_predict_service(line,target)
	_served[key]=result
	return result

func _predict_service(line: Vector3, target: Dictionary) -> bool:
	var point: Vector3=target.point
	# Start below the deck edge and davit, which the boarding corridor handles.
	var start=Vector3(line.x,line.y-1.2-BOARDING_CLEARANCE,line.z)
	var collision=KinematicCollision3D.new()
	var lowest: float=0.0
	if game.player.test_move(Transform3D(game.player.global_basis,start),Vector3.DOWN*start.y,collision):lowest=start.y-collision.get_travel().length()
	var eye_y=minf(point.y+game.REACH,start.y+EYE)
	while eye_y>=maxf(point.y-game.REACH,lowest+EYE):
		var plumb=Vector3(line.x,eye_y,line.z)
		if _sees(plumb,target):return true
		# A horizontal capsule sweep stops at the first surface: this is the
		# pose the player can hold by pumping into it, independent of ownership.
		var feet=plumb-Vector3.UP*EYE
		var direction=horizontal(point-plumb).normalized()
		var motion=direction*SWING_CAP
		# An empty-air extreme is transient; it cannot replace a held working
		# pose. Only a surface the same input can brace against qualifies.
		if not game.player.test_move(Transform3D(game.player.global_basis,feet),motion,collision) or absf(collision.get_normal().y)>=.65 or direction.dot(collision.get_normal())>=-.15:
			eye_y-=SAMPLE_STEP;continue
		motion=collision.get_travel()
		var braced=plumb+motion
		var length=line.distance_to(braced-Vector3.UP*(EYE-HARNESS))
		if horizontal(motion).length()<=swing_radius(length)+.001 and length<=line.y-HARNESS and _sees(braced,target):return true
		eye_y-=SAMPLE_STEP
	return false

func _sees(eye: Vector3, target: Dictionary) -> bool:
	return eye.distance_to(target.point)<=game.REACH and game.targeting.can_see(target.point,target.allowed,target.body_hit,target.depth,eye)
