extends "res://scripts/equipment.gd"
## One chest-owned hinge, prepared telescopes and the shared crane. Hardware
## remains ordinary model stock; temporary support and captive locks live here.
const Codec=preload("res://scripts/pose_codec.gd")
const Sweep=preload("res://scripts/motion_sweep.gd")
const Solid=preload("res://scripts/solid_handling.gd")
var spec: Dictionary
var active=false
var angle=0.0
var goal=0.0
var tension=0.0
var struts: Array[float]=[0,0]
var strut_goals: Array[float]=[0,0]
var locks: Array[bool]=[false,false]
var latches: Array[bool]=[false,false]
var covers: Array[bool]=[false,false]
var motion=""
var moving=false
var blocked_reason=""
var source_nodes: Dictionary={}
var source_cols: Dictionary={}
var lock_nodes: Array[Node3D]=[]
var cover_nodes: Array[Node3D]=[]
var service_lines: Array=[]
var green: Material
var amber: Material

func setup(workshop: Node3D,definition: Dictionary) -> void:
	game=workshop;spec=definition;equipment_id="backpack_hinge"
	game.runtime.mounted_poses[spec.owner+"."+spec.slot]=local_mount_pose
	var body=game.runtime.node(spec.uid)
	for mesh in body.get_node("PreparedStructure").get_children():source_nodes[mesh.get_meta("source_uid")]=mesh
	for col in body.get_children():
		if col is CollisionShape3D and col.has_meta("source_uid"):source_cols[col.get_meta("source_uid")]=col
	green=game.material(Color("7cc7a7"));amber=game.material(Color("e8b46b"))
	for n in range(2):
		lock_nodes.append(game.box(body,Vector3.ZERO,Vector3(.04,.04,.12),amber))
		cover_nodes.append(source_nodes["BP-SERVICE-COVER__%03d"%(n+1)])
		var lines: Array=[]
		for i in range(24):lines.append(game.box(self,Vector3.ZERO,Vector3(.024,1,.024),game.material(Color("31474a"))))
		service_lines.append(lines)
	game.model.changed.connect(_pose)
	_pose()

func _crane() -> Node:return game.equipment.get_equipment("service_crane")
func _record(model: AssemblyModel=null) -> Dictionary:return (game.model if model==null else model).assemblies[spec.uid]
func _has(ids: Array,model: AssemblyModel=null) -> bool:
	var m=game.model if model==null else model
	return ids.all(func(sid):return not m.assemblies[spec.owner].slots[sid].is_empty())
func _any(ids: Array,model: AssemblyModel=null) -> bool:
	var m=game.model if model==null else model
	return ids.any(func(sid):return not m.assemblies[spec.owner].slots[sid].is_empty())
func rigged(crane: Dictionary={}) -> bool:
	if crane.is_empty():
		if _crane()==null:return false
		crane=_crane().capture()
	return crane.task=="backpack" and crane.station=="receiver" and not crane.raised and crane.motion.is_empty() and crane.endpoints.size()==2 and crane.endpoints.values().all(func(end):return end.state=="attached")
func local_mount_pose(state: Dictionary={}) -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT,PI/2*(angle if state.is_empty() else state.angle)),AssemblyRuntime.vec(spec.seat))
func load_pose(value: float=-1) -> Transform3D:
	return game.runtime.node(spec.owner).global_transform*local_mount_pose({"angle":angle if value<0 else value})
func beam_pose() -> Transform3D:return _crane()._load_beam(load_pose()).translated(Vector3.UP*.06*tension)
func retained(state: Dictionary={},model: AssemblyModel=null) -> bool:
	var data=capture() if state.is_empty() else state
	if not data.active or not _has(spec.hinge_slots+spec.strut_slots,model):return false
	return (data.angle==0 and data.locks.all(func(v):return v)) or (data.angle==1 and data.latches.all(func(v):return v))
func secured(state: Dictionary={},model: AssemblyModel=null) -> bool:return retained(state,model)
func receiving_error(_uid: String="backpack") -> String:
	if not game.equipment.get_equipment("module_supports").support_secured("chest"):return "Retain the chest on the secured, neutral-locked waist first."
	var core=game.equipment.get_equipment("core_guide")
	if core.active and not core.secured():return "Finish core retention and connection before covering its rear work area."
	return "" if motion.is_empty() else "Finish or stop the backpack operation before moving the crane."
func accept() -> String:
	var error=receiving_error()
	if not error.is_empty():return error
	active=true;tension=1
	var result: Dictionary=game.model.install_supported(spec.owner,spec.slot,spec.uid,"crane_rigging")
	if not result.ok:active=false;tension=0;return result.error
	game.runtime.mount(spec.owner,spec.slot,spec.uid);game.refresh_assembly_collision(spec.owner);_pose();return ""
func departure_error() -> String:
	if not motion.is_empty():return "Finish the backpack operation before moving the crane."
	if _crane().attached_count()==0 and retained():return ""
	if rigged() and angle==0 and struts==[0.0,0.0] and not _any(spec.hinge_slots+spec.strut_slots+spec.service_slots):return ""
	return "Keep this backpack seated: use Take backpack weight and Open/Close, or undo its services, locks, strut connections and hinges for supported local removal."
func depart() -> void:
	if _crane().attached_count()==2:active=false;tension=0
func rig_error(action: String,_point: String) -> String:
	if not motion.is_empty():return "Finish or resume the backpack movement before handling rigging."
	if action=="detach" and not retained():return "Secure both hinge/strut pin pairs and both open locks, or both closed latches, before releasing either end."
	return ""
func rig_changed() -> void:
	if _crane().uid!=spec.uid or _crane().attached_count()!=2:tension=0

func crane_options() -> Array[Dictionary]:
	if not motion.is_empty():return [{"action":"guide:stop" if moving else "guide:resume","label":"Stop backpack" if moving else "Resume backpack"}]
	return [{"action":"guide:take_weight","label":"Take backpack weight"},{"action":"guide:close" if angle<1 else "guide:open","label":"Close backpack" if angle<1 else "Open backpack"}]
func controls() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	if not active:return result
	for n in range(2):
		var uid="BP-STRUT-A__%03d"%(n+1);var handle=source_nodes[uid]
		result.append(control_entry(handle,"strut:"+str(n),"Retract free strut" if struts[n]==1 else "Extend strut to chest clevis",.07,{"point":handle.global_position}))
		result.append(control_entry(lock_nodes[n],"lock:"+str(n),("Release" if locks[n] else "Engage")+" positive open lock",.075,{"point":lock_nodes[n].global_position}))
		var latch=source_nodes["BP-LATCH-LEVER__%03d"%(n+1)]
		result.append(control_entry(latch,"latch:"+str(n),("Release" if latches[n] else "Engage")+" lower draw latch",.075,{"point":load_pose()*AssemblyRuntime.vec(spec.latch_positions[n])}))
		if angle==1:result.append(control_entry(cover_nodes[n],"cover:"+str(n),("Open" if covers[n] else "Close")+" service cover",.10,{"point":cover_nodes[n].global_position}))
	return result

func action_error(action: String) -> String:
	if game.paused:return "Resume before operating the backpack."
	if not active:return "Seat the open backpack with both crane ends first."
	if action=="stop":return "" if moving else "The backpack is stopped."
	if action=="resume":return "" if not motion.is_empty() and not moving and rigged() else "Keep both crane ends fitted to resume the stopped operation."
	if not motion.is_empty():return "Stop/Resume the current backpack operation first."
	var error=game.hands.error(equipment_id)
	if not error.is_empty():return error
	if action=="take_weight":
		if not rigged():return "Refit both ends with the matching crane down at the backpack."
		return "" if tension<1 else "The crane already carries the backpack's weight."
	if action.begins_with("cover:"):
		var i=action.get_slice(":",1).to_int()
		if i not in [0,1]:return "Unknown service cover."
		if angle!=1 or not retained() or not _has(spec.service_slots):return "Close and latch the connected backpack before operating service covers."
		if _crane().uid==spec.uid and (_crane().attached_count()>0 or not _crane().hand_payload().is_empty()):return "Release and stow the crane ends before closing the small service covers."
		return ""
	if not rigged() or tension!=1:return "Refit both crane ends and take backpack weight before changing its supports."
	if covers.any(func(v):return v):return "Open both service covers before moving the backpack."
	if action.begins_with("strut:"):
		var i=action.get_slice(":",1).to_int()
		if i not in [0,1]:return "Unknown strut."
		if angle!=0 or not _has(spec.hinge_slots):return "Retain both hinges in the fully open pose before extending a strut."
		if locks[i] or _any(["backpack/strut_pin_"+str(i+1),"backpack/strut_keeper_"+str(i+1)]):return "Release this strut's lock, keeper and base pin before retracting it."
		return ""
	if action.begins_with("lock:"):
		var i=action.get_slice(":",1).to_int()
		if i not in [0,1]:return "Unknown strut lock."
		if angle!=0 or struts[i]!=1 or not _has(spec.hinge_slots+spec.strut_slots):return "Fully extend and pin both struts at the open stop before engaging their locks."
		return ""
	if action.begins_with("latch:"):
		var i=action.get_slice(":",1).to_int()
		if i not in [0,1]:return "Unknown lower latch."
		return "" if angle==1 and _has(spec.hinge_slots+spec.strut_slots) else "Reach the closed locator stop before operating lower latches."
	if action in ["close","open"]:
		if not _has(spec.hinge_slots+spec.strut_slots+spec.service_slots):return "Complete hinge/strut retention and both service connections before cover movement."
		if locks.any(func(v):return v) or latches.any(func(v):return v):return "Release both positive open locks or lower latches before moving."
		if (action=="close" and angle==1) or (action=="open" and angle==0):return "The backpack is already at this stop."
		return ""
	return "Unknown backpack operation."

func request(action: String) -> String:
	var error=action_error(action)
	if not error.is_empty():return error
	if action=="stop":moving=false
	elif action=="resume":moving=true
	elif action=="take_weight":motion="tension";moving=true
	elif action in ["close","open"]:goal=1 if action=="close" else 0;motion="hinge";moving=true
	elif action.begins_with("strut:"):
		var i=action.get_slice(":",1).to_int();strut_goals[i]=0 if struts[i]==1 else 1;motion=action;moving=true
	else:
		var i=action.get_slice(":",1).to_int()
		if action.begins_with("lock:"):locks[i]=not locks[i]
		elif action.begins_with("latch:"):latches[i]=not latches[i]
		else:covers[i]=not covers[i]
	blocked_reason="";_pose();return ""

func strut_frames(frame: Transform3D,n: int,amount: float) -> Dictionary:
	var b=frame*AssemblyRuntime.vec(spec.strut_b[n])
	var a=game.runtime.node(spec.owner).global_transform*AssemblyRuntime.vec(spec.strut_a[n])
	var local=frame.basis.inverse()*(a-b);var target=atan2(-local.y,local.z)
	var basis=frame.basis*Basis(Vector3.RIGHT,target*amount)
	var length=lerpf(spec.stowed_length,a.distance_to(b),amount)
	return {"B":Transform3D(basis,b),"MID":Transform3D(basis,b+basis.z*length/2),"A":Transform3D(basis,b+basis.z*length)}
func strut_solids(frame: Transform3D,values: Array) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for n in range(2):
		var frames=strut_frames(frame,n,values[n])
		for key in frames:
			var uid="BP-STRUT-"+key+"__%03d"%(n+1)
			for entry in Solid.authored_shapes(game.leg_content.sources[uid].motion_shapes,AABB()):result.append({"shape":entry.shape,"world":frames[key]*entry.transform})
	return result
func service_path(frame: Transform3D,n: int,_value: float) -> Array[Vector3]:
	# Bounded display/clearance proxy for each supplied protected run. Detailed
	# internal slack and minimum wire bend radius belong to its later source model.
	var parent=game.runtime.node(spec.owner).global_transform
	var a=parent*(AssemblyRuntime.vec(spec.service_fixed[n])+Vector3.BACK*.085);var b=frame*(AssemblyRuntime.vec(spec.service_pack[n])+Vector3.BACK*.05)
	var x: float=spec.service_fixed[n][0]
	var c=parent*Vector3(x,2.49,1.68);var d=b+frame.basis.z*.18
	var result: Array[Vector3]=[]
	for i in range(25):
		var t=float(i)/24;result.append(a*pow(1-t,3)+3*c*pow(1-t,2)*t+3*d*(1-t)*t*t+b*t*t*t)
	return result
func service_solids(frame: Transform3D,value: float) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for n in range(2):
		if not _has([spec.service_slots[n]]):continue
		var path=service_path(frame,n,value)
		for i in range(path.size()-1):
			var d=path[i+1]-path[i];var shape=BoxShape3D.new();shape.size=Vector3(.024,d.length(),.024)
			result.append({"shape":shape,"world":Transform3D(Basis(Quaternion(Vector3.UP,d.normalized())),(path[i+1]+path[i])/2)})
	return result
func motion_error(next_angle: float,next_struts: Array) -> String:
	var shapes: Array[Dictionary]=[]
	var body=game.runtime.node(spec.uid)
	for col in source_cols.values():
		if str(col.get_meta("source_uid")).begins_with("BP-STRUT-"):continue
		Sweep.collect_shapes(col,body.global_transform.affine_inverse(),shapes)
	var ignored: Array[RID]=game.leg_layout.blockout.rids_for_groups(["crane_bridge"]);Sweep.collect_rids(body,ignored)
	var from=load_pose();var to=load_pose(next_angle)
	var groups=[{"shapes":shapes,"margin":.0001,"error":"Clear the moving backpack ({collider})."},
		{"shapes_at":func(frame: Transform3D,p: float)->Array:return strut_solids(frame,[lerpf(struts[0],next_struts[0],p),lerpf(struts[1],next_struts[1],p)]),"margin":.0001,"error":"Clear the backpack strut ({collider})."},
		{"shapes_at":func(frame: Transform3D,_p: float)->Array:return _crane().rig_solids(frame,Vector3.UP*.06*tension),"margin":.001,"error":"Clear the backpack rigging ({collider})."},
		{"shapes_at":func(frame: Transform3D,p: float)->Array:return service_solids(frame,lerpf(angle,next_angle,p)),"margin":.0001,"error":"Clear the protected backpack services ({collider})."}]
	return Sweep.sweep(get_world_3d().direct_space_state,groups,maxi(Sweep.steps(from,to,3,.01),ceili(maxf(absf(next_struts[0]-struts[0]),absf(next_struts[1]-struts[1]))*350)),func(p: float)->Transform3D:return from.interpolate_with(to,p),15,ignored,equipment_id).get("error","")

func physics(delta: float) -> void:
	if game.paused:return
	if active and not rigged() and motion.is_empty():tension=0
	if moving:
		var next_angle=angle;var next_struts=struts.duplicate()
		if motion=="tension":
			var next_tension=move_toward(tension,1,delta*.6)
			var ignored: Array[RID]=game.leg_layout.blockout.rids_for_groups(["crane_bridge"]);Sweep.collect_rids(game.runtime.node(spec.uid),ignored)
			blocked_reason=Sweep.sweep(get_world_3d().direct_space_state,[{"shapes_at":func(frame: Transform3D,p: float)->Array:return _crane().rig_solids(frame,Vector3.UP*.06*lerpf(tension,next_tension,p)),"margin":.001,"error":"Clear the crane while taking weight ({collider})."}],2,func(_p: float)->Transform3D:return load_pose(),15,ignored,equipment_id).get("error","")
			if not blocked_reason.is_empty():moving=false;_pose();return
			tension=next_tension
		elif motion=="hinge":next_angle=move_toward(angle,goal,delta*.12)
		else:
			var i=motion.get_slice(":",1).to_int();next_struts[i]=move_toward(struts[i],strut_goals[i],delta*.30)
		blocked_reason=motion_error(next_angle,next_struts) if motion!="tension" else ""
		if not blocked_reason.is_empty():moving=false;_pose();return
		angle=next_angle;struts.assign(next_struts)
		if (motion=="tension" and tension==1) or (motion=="hinge" and angle==goal) or (motion.begins_with("strut:") and struts==strut_goals):moving=false;motion=""
	_pose()

func _pose() -> void:
	var body=game.runtime.node(spec.uid)
	if active and _record().parent==spec.owner:body.global_transform=load_pose()
	var frame: Transform3D=body.global_transform
	for n in range(2):
		var frames=strut_frames(frame,n,struts[n] if active else 0.0)
		for key in frames:
			var uid="BP-STRUT-"+key+"__%03d"%(n+1)
			source_nodes[uid].global_transform=frames[key];source_cols[uid].global_transform=frames[key]
		lock_nodes[n].global_transform=frames.B*Transform3D(Basis.IDENTITY,Vector3((-.05 if n==0 else .05),0,.55))
		lock_nodes[n].material_override=green if locks[n] else amber
		cover_nodes[n].rotation.z=0 if covers[n] else PI/3
		source_cols["BP-SERVICE-COVER__%03d"%(n+1)].rotation.z=cover_nodes[n].rotation.z
		source_nodes["BP-LATCH__%03d"%(n+1)].material_override=green if latches[n] else amber
		var lever="BP-LATCH-LEVER__%03d"%(n+1);var draw="BP-DRAW__%03d"%(n+1)
		var lever_pose: Transform3D=game.source[lever].transform*Transform3D(Basis(Vector3.UP,PI/2 if latches[n] else 0),Vector3.ZERO)
		source_nodes[lever].transform=lever_pose;source_cols[lever].transform=lever_pose
		source_nodes[draw].position=Vector3(0,-.002 if latches[n] else 0,0);source_cols[draw].position=source_nodes[draw].position
		var path=service_path(frame,n,angle)
		for i in range(24):
			var line: MeshInstance3D=service_lines[n][i];line.visible=active and _has([spec.service_slots[n]])
			var d=path[i+1]-path[i]
			line.global_transform=Transform3D(Basis(Quaternion(Vector3.UP,d.normalized())),(path[i+1]+path[i])/2);line.scale=Vector3(1,maxf(.001,d.length()),1)
	body.force_update_transform();PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	if _crane()!=null and _crane().task=="backpack":_crane()._refresh()

func placement_error(owner: String,sid: String) -> String:
	if owner!=spec.owner or not sid.begins_with("backpack/"):return ""
	if not active or angle!=0 or not motion.is_empty():return "Keep the backpack stopped fully open for its external connections."
	if sid in spec.service_slots:
		if not retained() or not locks.all(func(v):return v):return "Engage both positive open locks before connecting services."
		return "" if _crane().uid!=spec.uid or (_crane().attached_count()==0 and _crane().hand_payload().is_empty()) else "Release and stow both crane ends before connecting the service runs."
	if not rigged() or tension!=1:return "Keep both crane ends carrying the backpack during pin and keeper work."
	if "strut_" in sid and struts[sid.right(1).to_int()-1]!=1:return "Extend this strut eye to its chest clevis first."
	return ""
func undo(owner: String) -> Dictionary:
	if owner!=spec.owner or game.model.assemblies[owner].history.is_empty():return {"handled":false,"error":""}
	var sid: String=game.model.assemblies[owner].history.back().slot
	if sid!=spec.slot and not sid.begins_with("backpack/"):return {"handled":false,"error":""}
	var error=""
	if sid in spec.service_slots:error=placement_error(owner,sid)
	elif sid==spec.slot:error="Use Up at the matching crane to lift the unfastened open backpack."
	else:
		error=placement_error(owner,sid)
		if error.is_empty() and (_any(spec.service_slots) or locks.any(func(v):return v)):error="Disconnect both services and release both open locks before undoing retention."
		if error.is_empty() and sid in spec.hinge_slots and (_any(spec.strut_slots) or struts!=[0.0,0.0]):error="Remove both strut-base connections and retract the free struts before undoing hinges."
	return {"handled":not error.is_empty(),"error":error}
func status_text() -> String:
	return "BACKPACK / "+("awaiting delivery" if not active else "moving" if moving else "closed" if angle==1 else "open" if angle==0 else "stopped partway")+"\n"+(blocked_reason if not blocked_reason.is_empty() else "%d / 2 open locks · %d / 2 lower latches"%[locks.count(true),latches.count(true)])
func capture() -> Dictionary:return {"version":1,"active":active,"angle":angle,"goal":goal,"tension":tension,"struts":struts.duplicate(),"strut_goals":strut_goals.duplicate(),"locks":locks.duplicate(),"latches":latches.duplicate(),"covers":covers.duplicate(),"motion":motion,"moving":moving}

func validate_crane(crane: Dictionary,model: AssemblyModel,state: Dictionary={}) -> Array[String]:
	var data=capture() if state.is_empty() else state
	if not data.active or _record(model).parent!=spec.owner:return ["Backpack hinge has no mounted assembly."]
	if not retained(data,model) and not rigged(crane):return ["Unsecured backpack requires both crane ends at its hinge."]
	if not retained(data,model) and data.tension!=1:return ["Unsecured backpack requires the crane to carry its weight."]
	if data.tension>0 and not rigged(crane) and not retained(data,model):return ["Backpack claims crane load without both ends."]
	return []
func validate(data: Variant,candidate: AssemblyModel=null,world: Dictionary={}) -> Array[String]:
	if not Codec.same_keys(data,capture().keys()) or data.version!=1:return ["Invalid backpack hinge state."]
	for key in ["active","moving"]:
		if not data[key] is bool:return ["Invalid backpack flag."]
	for key in ["angle","goal","tension"]:
		if not Codec.number(data[key],1) or data[key]<0:return ["Invalid backpack motion progress."]
	for key in ["struts","strut_goals","locks","latches","covers"]:
		if not data[key] is Array or data[key].size()!=2:return ["Invalid paired backpack mechanism."]
		for value in data[key]:
			if key in ["struts","strut_goals"]:
				if not Codec.number(value,1) or value<0:return ["Invalid telescope progress."]
			elif not value is bool:return ["Invalid captive backpack lock."]
	if (data.goal!=0 and data.goal!=1) or not data.strut_goals.all(func(v):return v==0 or v==1):return ["Backpack targets are physical end stops."]
	if not data.motion is String or data.motion not in ["","tension","hinge","strut:0","strut:1"] or (data.motion.is_empty() and data.moving):return ["Invalid backpack operation."]
	if data.motion.is_empty() and (data.angle!=data.goal or data.struts!=data.strut_goals or (data.tension!=0 and data.tension!=1)):return ["Idle backpack has unfinished motion progress."]
	var model=game.model if candidate==null else candidate
	if data.active!=(_record(model).parent==spec.owner):return ["Backpack hinge ownership disagrees with the installed cover."]
	if not data.active:
		if data.angle!=0 or data.goal!=0 or data.tension!=0 or not data.motion.is_empty() or data.struts!=[0.0,0.0] or data.strut_goals!=[0.0,0.0] or data.locks.any(func(v):return v) or data.latches.any(func(v):return v) or data.covers.any(func(v):return v):return ["Stored backpack contains mounted mechanism progress."]
		return []
	if not model.milestone("pelvis","chest_secured"):return ["Backpack needs a secured receiving chest."]
	if data.struts.any(func(v):return v>0) and not _has(spec.hinge_slots,model):return ["Extended struts require both retained hinges."]
	for n in range(2):
		if _any(["backpack/strut_pin_"+str(n+1),"backpack/strut_keeper_"+str(n+1)],model) and data.struts[n]!=1:return ["Strut hardware has no aligned eye."]
	if data.locks.any(func(v):return v) and (data.angle!=0 or not _has(spec.hinge_slots+spec.strut_slots,model)):return ["Positive locks require the retained open stop."]
	if data.latches.any(func(v):return v) and (data.angle!=1 or not _has(spec.hinge_slots+spec.strut_slots,model)):return ["Lower latches require closed retained hinges and struts."]
	if data.angle>0 and (not _has(spec.hinge_slots+spec.strut_slots+spec.service_slots,model) or data.locks.any(func(v):return v)):return ["Cover movement lost its connections or retained open locks."]
	if data.covers.any(func(v):return v) and (data.angle!=1 or not retained(data,model) or not _has(spec.service_slots,model)):return ["Service covers require closed latched construction."]
	if data.motion=="hinge" and (not _has(spec.hinge_slots+spec.strut_slots+spec.service_slots,model) or data.locks.any(func(v):return v) or data.latches.any(func(v):return v) or data.covers.any(func(v):return v)):return ["Hinge motion has unfinished connections or engaged restraints."]
	if data.motion.begins_with("strut:"):
		var n=data.motion.get_slice(":",1).to_int()
		if data.angle!=0 or not _has(spec.hinge_slots,model) or data.locks[n] or _any(["backpack/strut_pin_"+str(n+1),"backpack/strut_keeper_"+str(n+1)],model):return ["Moving telescope is pinned or lacks retained open hinges."]
	if world.has("equipment"):
		var crane: Dictionary=world.equipment.service_crane
		if not retained(data,model) and not rigged(crane):return ["Backpack lost its shared crane before support was secured."]
		if not retained(data,model) and data.tension!=1:return ["Unsecured backpack lost crane weight support."]
		if data.tension>0 and not rigged(crane):return ["Backpack tension has no matching rig."]
		if not data.motion.is_empty() and not rigged(crane):return ["Interrupted backpack movement requires both crane ends."]
		if data.motion in ["hinge","strut:0","strut:1"] and data.tension!=1:return ["Backpack movement started before the crane took weight."]
	return []
func apply(data: Dictionary) -> void:
	active=data.active;angle=data.angle;goal=data.goal;tension=data.tension;struts.assign(data.struts);strut_goals.assign(data.strut_goals);locks.assign(data.locks);latches.assign(data.latches);covers.assign(data.covers);motion=data.motion;moving=data.moving;blocked_reason="";_pose()
