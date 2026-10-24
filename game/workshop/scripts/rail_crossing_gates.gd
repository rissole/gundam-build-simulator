extends "res://scripts/equipment.gd"
## Ground pedestrian barriers close outside the complete empty-holder envelope.
## The rail owns their requested state; a stopped phase preserves it for resume.
const Sweep = preload("res://scripts/motion_sweep.gd")
const Codec = preload("res://scripts/pose_codec.gd")
var blockout: Node3D
var spec: Dictionary
var value=0.0
var goal=0.0
var moving=false
var blocked_reason=""

func setup(workshop: Node3D, geometry: Node3D) -> void:
	game=workshop;blockout=geometry;spec=geometry.spec.rail_gates;equipment_id="rail_gates";_pose()

func frames_at(progress: float) -> Dictionary:
	var result={}
	for id in spec.groups:
		var authored: Dictionary=blockout.spec.groups[id]
		var frame: Transform3D=blockout.authored_pose(authored)
		frame.basis*=Basis(Vector3.UP,deg_to_rad(lerpf(authored.open_angle,authored.closed_angle,progress)))
		result[id]=frame
	return result

func occupancy_error() -> String:
	var shape=BoxShape3D.new();shape.size=AssemblyRuntime.vec(spec.occupied_size)
	var hit=Sweep.overlap(get_world_3d().direct_space_state,shape,Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(spec.occupied_center)),8,[],0)
	return "Leave the ground rail corridor before moving the holder." if not hit.is_empty() else ""

func motion_error(from: float, to: float) -> String:
	var excluded: Array[RID]=blockout.rids_for_groups(spec.groups)
	for id in spec.groups:
		for contact in blockout.spec.groups[id].motion_contacts:excluded.append(blockout.pieces[contact].body.get_rid())
	var samples=maxi(1,ceili(absf(to-from)*PI/.025))
	for index in range(samples+1):
		for entry in blockout.shapes_at(spec.groups,frames_at(lerpf(from,to,float(index)/samples))):
			var hit=Sweep.overlap(get_world_3d().direct_space_state,entry.shape,entry.world,15,excluded,-.003)
			if not hit.is_empty():
				if OS.has_environment(Sweep.DIAGNOSTIC_ENV):print("GATE_CONTACT ",entry.id," at=",entry.world.origin," collider=",hit.collider.get_path()," at=",hit.collider.global_position)
				return "Clear the ground crossing gate sweep ("+str(hit.collider.name)+")."
	return ""

func request_closed(close: bool) -> String:
	var target=1.0 if close else 0.0
	goal=target
	if close:
		var occupied=occupancy_error()
		if not occupied.is_empty():blocked_reason=occupied;return occupied
	var error=motion_error(value,target)
	if not error.is_empty():blocked_reason=error;return error
	goal=target;moving=not is_equal_approx(value,goal);blocked_reason="";return ""

func closed() -> bool:return value==1 and not moving

func controls() -> Array[Dictionary]:
	var entries: Array[Dictionary]=[]
	for id in spec.groups:
		var handle: Node3D=blockout.pieces[id+"_bar"].visual
		var action="stop" if moving else "resume" if value!=goal else "open"
		var entry=control_entry(handle,action,action.capitalize()+" ground crossing gates",.18)
		entry["point"]=handle.global_position
		entries.append(entry)
	return entries

func action_error(action: String) -> String:
	if game.paused:return "Resume before operating the crossing."
	if action=="stop":return "" if moving else "The crossing gates are stopped."
	if action=="resume":return "" if value!=goal else "The crossing gates are already locked."
	if action!="open":return "Unknown crossing control."
	var rail=game.equipment.get_equipment("leg_rail")
	if rail!=null and (rail.moving or not rail.mode.is_empty() or rail.path not in [0.0,3.0]):return "The holder must be locked at its station or dock before opening the crossing."
	return ""

func request(action: String) -> String:
	var error=action_error(action)
	if not error.is_empty():return error
	if action=="stop":moving=false;return ""
	return request_closed(goal==1) if action=="resume" else request_closed(false)

func physics(delta: float) -> void:
	if game.paused or not moving:return
	var next=move_toward(value,goal,delta/spec.duration)
	blocked_reason=motion_error(value,next)
	if not blocked_reason.is_empty():moving=false;return
	value=next;moving=value!=goal;_pose()

func _pose() -> void:blockout.apply_frames(frames_at(value))
func status_text() -> String:return blocked_reason if not blocked_reason.is_empty() else "Ground crossing / "+("closed" if closed() else "moving" if moving else "open")
func capture() -> Dictionary:return {"version":1,"value":value,"goal":goal,"moving":moving}
func validate(data: Variant, _candidate: AssemblyModel = null, _world: Dictionary = {}) -> Array[String]:
	if not Codec.same_keys(data,["version","value","goal","moving"]) or data.version!=1:return ["Invalid ground gate snapshot."]
	if not Codec.number(data.value,1) or data.value<0 or not Codec.number(data.goal,1) or data.goal not in [0.0,1.0] or not data.moving is bool:return ["Invalid ground gate phase."]
	return []
func apply(data: Dictionary) -> void:
	value=data.value;goal=data.goal;moving=data.moving;blocked_reason="";_pose()
