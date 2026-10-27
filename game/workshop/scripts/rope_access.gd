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
const PULL_REACH = 1.6
const PULL_GAP = 0.45
const BOARDING_DUCK = 0.75
const LEAF_REASON = "Recall the ropes on the workshop-side leaves"
var blockout: Node3D
var stations: Dictionary = {}
var ropes: Dictionary = {}
var fixtures: Dictionary = {}
var attachment = ""
var hanging = false
var pull_in: Variant = null
var slack = Vector3.ZERO
# Input acceleration is transient; loading a snapshot always starts at rest.
var _vertical_direction = 0.0
var _vertical_held = 0.0

func reset_motion() -> void:
	_vertical_direction=0.0;_vertical_held=0.0

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
	var lanyard = _box(node,Vector3.ZERO,Vector3(.014,1,.014),line_material)
	fixtures[id]={"root":node,"gate":gate,"shape":shape,"bar":bar,"clip":clip,"recall":recall,"end":end,"line":line,"lanyard":lanyard}

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
		f.lanyard.hide()
		if attachment==id and pull_in!=null:_line(f.lanyard,end,pull_in)

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
	if parts[0]!="recall" and not front_available(id):return "Close and lock the workshop-side leaves before using a rope."
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
		reset_motion()
		attachment=id;hanging=false;pull_in=null;slack=Vector3.ZERO
		ropes[id].deployed=true
		ropes[id].length=clampf(anchor(id).y-game.player.global_position.y-HARNESS,MIN_LENGTH,max_length(id))
		if boarding_duck(game.player.global_position.y):game.player_controller.update_crouch(true,1.0)
	physics(0)
	return ""

func unclip() -> String:
	if not attached():return "Clip in at a rope station or hanging rope end."
	if not on_floor():return "Land on a floor before unclipping."
	# Leave the end at harness height for the next ascent from this floor.
	ropes[attachment].length=clampf(anchor(attachment).y-game.player.global_position.y-HARNESS,MIN_LENGTH,max_length(attachment))
	attachment="";hanging=false;pull_in=null;slack=Vector3.ZERO;reset_motion();physics(0)
	return ""

func rope_key() -> String:
	if not attached():return "Clip in at a rope station or hanging rope end."
	if on_floor():return "Hang on the rope to use the lanyard · Q unclips on a floor."
	reset_motion()
	if pull_in!=null:pull_in=null;slack=Vector3.ZERO;return ""
	var from: Vector3=game.camera.global_position
	var query=PhysicsRayQueryParameters3D.create(from,from-game.camera.global_basis.z*2.5,game.WORLD_MASK,[game.player.get_rid()])
	var hit=game.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():return "Aim at robot structure to clip the pull-in lanyard."
	return attach_lanyard(hit.position,hit.collider)

func attach_lanyard(point: Vector3, body: Node) -> String:
	if not attached() or not hanging:return "Hang on the rope before clipping a pull-in lanyard."
	if horizontal(point-anchor(attachment)).length()>PULL_REACH:return "Pull-in point must be within 1.6 m of the rope line."
	if game.camera.global_position.distance_to(point)>2.5:return "Aim at nearby robot structure."
	var owner: String=body.get_meta("assembly_id","")
	var model=game.get("model")
	if owner.is_empty() or model==null or not model.assemblies.has(owner):return "Clip the lanyard to robot structure."
	var top: String=model.top_level(owner)
	if model.assemblies[top].location in ["held","loose"] or str(model.assemblies[top].location).begins_with("station:"):return "Clip the lanyard to supported robot structure."
	if not game.targeting.can_see(point,[body]):return "The pull-in point is obstructed."
	pull_in=point;slack=Vector3.ZERO
	return ""

func status_text() -> String:
	if not attached():return ""
	return "Rope · %s · %.1f m%s%s\n%s" % ["hanging" if hanging else "clipped",ropes[attachment].length," · pull-in" if pull_in!=null else "", " · ducking under davit" if boarding_duck(game.player.global_position.y) else "", "Space ↑ / Ctrl ↓ (hold: faster) · WASD · G lanyard" if hanging else "Space ↑ / Ctrl ↓ · step through your gate · Q unclip"]

func capture() -> Dictionary:
	return {"version":1,"ropes":ropes.duplicate(true),"attachment":attachment,"hanging":hanging,"pull_in":[] if pull_in==null else Codec.vector(pull_in),"slack":Codec.vector(slack)}

func validate(data: Variant, _candidate: AssemblyModel=null, world: Dictionary={}) -> Array[String]:
	if not Codec.same_keys(data,["version","ropes","attachment","hanging","pull_in","slack"]) or data.version!=1:return ["Invalid rope snapshot."]
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
	if not data.attachment is String or not data.hanging is bool or not Codec.valid_vector(data.slack):return ["Invalid rope attachment."]
	if not data.pull_in is Array or (not data.pull_in.is_empty() and not Codec.valid_vector(data.pull_in)):return ["Invalid pull-in point."]
	var offset=Codec.to_vector(data.slack)
	if absf(offset.y)>.001 or offset.length()>SLACK+.001:return ["Rope slack out of range."]
	if data.attachment.is_empty():
		if data.hanging or not data.pull_in.is_empty() or not offset.is_zero_approx():return ["Unattached rope has player state."]
	else:
		if not stations.has(data.attachment) or not data.ropes[data.attachment].deployed:return ["Player attached to a stowed or unknown rope."]
		if not data.pull_in.is_empty():
			if not data.hanging or horizontal(Codec.to_vector(data.pull_in)-anchor(data.attachment)).length()>PULL_REACH:return ["Pull-in point out of range."]
		var player: Variant=world.get("player",[])
		if not world.is_empty() and not Codec.valid_vector(player,5):return ["Attached rope requires a finite player pose."]
		if player is Array and player.size()==5:
			var at=Vector3(player[0],player[1],player[2])
			if absf(anchor(data.attachment).y-HARNESS-float(data.ropes[data.attachment].length)-at.y)>.12:return ["Rope length disagrees with player height."]
			var radius=2.6 if at.y>=deck_height(data.attachment)-.08 else PULL_REACH
			if horizontal(at-anchor(data.attachment)).length()>radius+.05:return ["Player is outside the rope envelope."]
			if not data.pull_in.is_empty() and (Codec.to_vector(data.pull_in)-(at+Vector3.UP*1.63)).length()>2.51:return ["Pull-in point is beyond player reach."]
	return []

func apply(data: Dictionary) -> void:
	if not validate(data).is_empty():return
	reset_motion()
	ropes=data.ropes.duplicate(true);attachment=data.attachment;hanging=data.hanging
	pull_in=null if data.pull_in.is_empty() else Codec.to_vector(data.pull_in)
	slack=Codec.to_vector(data.slack)
	# Equipment restores before the saved player pose. Derive the boarding shape
	# from line length, so a reload never starts standing inside a boom.
	if attached() and boarding_duck(anchor(attachment).y-HARNESS-float(ropes[attachment].length)):
		game.player_controller.update_crouch(true,1.0)
	physics(0)

## Resolve the tracked objective's real connection points; no recipe-name list
## or wording heuristic. Existing guidance owns range, occlusion and glow.
func access_control_entries(objective: Dictionary, owner: String, machine: Node) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if attached():return result
	var points: Array[Vector3]=[]
	if is_instance_valid(machine):
		for entry in machine.manual_control_entries(objective):
			if entry.has("point"):points.append(entry.point)
	if objective.get("op","") in ["fit","seat"] and game.model.assemblies.has(owner):
		var slots: Array=objective.get("slots",[objective.get("slot","")])
		for sid in slots:
			if not str(sid).is_empty() and game.model.assemblies[owner].slots.has(sid):points.append(game.components.slot_point(owner,sid))
	var access=game.equipment.get_equipment("workshop_access")
	var close_cued=false
	for entry in controls():
		if not entry.action.begins_with("clip:"):continue
		var id: String=entry.action.trim_prefix("clip:")
		var working=working_anchor(id)
		for point in points:
			if point.y>10.5 and point.y<working.y and horizontal(point-working).length()<=PULL_REACH+game.REACH:
				if stations[id].edge=="front" and access!=null and not access.front_closed("upper"):
					if not close_cued:result.append_array(access.manual_control_entries({"command":"upper_close"}));close_cued=true
				elif action_error(entry.action).is_empty():result.append(entry)
				break
	return result
