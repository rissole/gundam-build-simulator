extends "res://scripts/equipment.gd"
## A retained shoulder and its four-end crane share load progressively.
const Codec=preload("res://scripts/pose_codec.gd")
const Geometry=preload("res://scripts/arm_delivery_geometry.gd")
const Sweep=preload("res://scripts/motion_sweep.gd")
var spec: Dictionary
var active=false
var brakes=false
var released=false
var tension=0.0
var goal=0.0
var moving=false
var motion=""
var blocked_reason=""
var mass: Dictionary
var rig_nodes: Array[MeshInstance3D]=[]

func setup(workshop: Node3D,definition: Dictionary) -> void:
	game=workshop;spec=definition;equipment_id=("left" if spec.side<0 else "right")+"_shoulder"
	mass=Geometry.mass_properties(game.leg_content,game.runtime.definition(spec.uid))
	for entry in Geometry.rig(Transform3D.IDENTITY,mass.center):
		var mesh=game.box(self,Vector3.ZERO,entry.shape.size,game.material(Color("e8b46b") if entry.rig_kind in ["hook","spreader","equalizer"] else Color("263a43"),.45))
		rig_nodes.append(mesh);mesh.visible=false
	call_deferred("_connect_crane")
	game.model.changed.connect(_model_changed)

func _model_changed() -> void:
	if active and brakes and not _has(spec.structural_slots):brakes=false

func _crane() -> Node:return game.equipment.get_equipment("service_crane")
func _connect_crane() -> void:
	if _crane()!=null:_crane().changed.connect(refresh_rig)
func _model(model: AssemblyModel=null) -> AssemblyModel:return game.model if model==null else model
func _has(ids: Array,model: AssemblyModel=null) -> bool:return ids.all(func(sid):return not _model(model).assemblies[spec.owner].slots[sid].is_empty())
func _any(ids: Array,model: AssemblyModel=null) -> bool:return ids.any(func(sid):return not _model(model).assemblies[spec.owner].slots[sid].is_empty())
func rigged(crane: Dictionary={}) -> bool:
	if crane.is_empty():
		if _crane()==null:return false
		crane=_crane().capture()
	return crane.task==spec.uid and crane.station=="receiver" and not crane.raised and crane.motion.is_empty() and crane.endpoints.size()==4 and crane.endpoints.values().all(func(end):return end.state=="attached")
func load_pose() -> Transform3D:return game.runtime.node(spec.owner).global_transform*Transform3D(Basis.from_euler(AssemblyRuntime.vec(spec.rotation_degrees)*PI/180),AssemblyRuntime.vec(spec.seat))
func beam_for_load(frame: Transform3D) -> Transform3D:
	var center=frame*mass.center;center.y=frame.origin.y+Geometry.HEAD_HEIGHT
	return Transform3D(Basis.IDENTITY,center)
func beam_pose() -> Transform3D:return beam_for_load(load_pose()).translated(Vector3.UP*.04*tension)
func retained(state: Dictionary={},model: AssemblyModel=null) -> bool:
	var data=capture() if state.is_empty() else state
	return data.active and data.brakes and _has(spec.structural_slots,model)
func secured(state: Dictionary={},model: AssemblyModel=null) -> bool:
	var data=capture() if state.is_empty() else state
	return retained(data,model) and data.tension==0 and data.motion.is_empty() and _has(spec.service_slots,model)
func receiving_error(_uid: String="") -> String:
	if not game.equipment.get_equipment("module_supports").support_secured("chest"):return "Secure the chest on the locked waist before shoulder delivery."
	return "" if motion.is_empty() else "Finish the shoulder load transfer before moving the crane."
func accept() -> String:
	var error=receiving_error()
	if not error.is_empty():return error
	active=true;tension=1;goal=1;brakes=false;released=false
	var result: Dictionary=game.model.install_supported(spec.owner,spec.slot,spec.uid,"m2_service_crane")
	if not result.ok:active=false;tension=0;goal=0;return result.error
	game.runtime.mount(spec.owner,spec.slot,spec.uid);game.refresh_assembly_collision(spec.owner)
	game.equipment.get_equipment("workshop_access").arm_services_stowed=true
	return ""
func departure_error() -> String:
	if not motion.is_empty():return "Finish the shoulder load transfer first."
	if _crane().attached_count()==0 and retained() and tension==0:return ""
	if rigged() and tension==1 and not _any(spec.structural_slots.filter(func(sid):return sid!=spec.slot)+spec.service_slots):return ""
	return "Keep the shoulder supported: isolate services, take arm weight, then remove the drives, brace and ring before withdrawal."
func depart() -> void:
	if _crane().attached_count()==4:active=false;tension=0;goal=0;brakes=false;released=false
func rig_changed() -> void:
	if active and _crane().uid==spec.uid and _crane().attached_count()<4 and secured():released=true
func rig_error(action: String,_point: String) -> String:
	if not motion.is_empty():return "Finish or resume the shoulder load transfer before handling a crane end."
	if action=="detach" and not secured():return "Retain the ring, brace and all drives, check brakes, transfer weight and connect services before releasing an arm end."
	return ""
func crane_options() -> Array[Dictionary]:
	if not motion.is_empty():return [{"action":"guide:stop" if moving else "guide:resume","label":"Stop load transfer" if moving else "Resume load transfer"}]
	return [{"action":"guide:check_brakes","label":"Check shoulder brakes"},{"action":"guide:transfer_weight","label":"Transfer arm weight to shoulder"},{"action":"guide:take_weight","label":"Take arm weight"}]
func action_error(action: String) -> String:
	if game.paused:return "Resume before operating the shoulder support."
	if not active:return "Seat the arm with its four crane ends first."
	if action=="stop":return "" if moving else "The shoulder load transfer is stopped."
	if action=="resume":return "" if not motion.is_empty() and not moving and rigged() else "Refit all four ends to resume this load transfer."
	if not motion.is_empty():return "Finish or resume the current shoulder load transfer."
	if not rigged():return "Lower the matching crane and attach all four arm ends."
	if action=="check_brakes":return "" if _has(spec.structural_slots) else "Complete the ring, keyed brace and all three pinned drive cartridges before checking brakes."
	if action=="transfer_weight":return "" if retained() and tension>0 else "Check the fully retained shoulder brakes before transferring weight."
	if action=="take_weight":return "" if tension<1 and not _any(spec.service_slots) else "Isolate and remove the service harness before taking arm weight."
	return "Unknown shoulder operation."
func request(action: String) -> String:
	var error=action_error(action)
	if not error.is_empty():return error
	if action=="stop":moving=false
	elif action=="resume":moving=true
	elif action=="check_brakes":brakes=true
	else:
		goal=0 if action=="transfer_weight" else 1;motion="tension";moving=true
		if goal==1:released=false
	refresh_rig();return ""
func physics(delta: float) -> void:
	if game.paused or not moving:return
	var next=move_toward(tension,goal,delta/2)
	var ignored=game.leg_layout.blockout.rids_for_groups(["crane_bridge"])
	Sweep.collect_rids(game.runtime.node(spec.uid),ignored)
	var frame=load_pose()
	var groups=[{"shapes_at":func(_frame: Transform3D,p: float)->Array:return Geometry.rig(frame,mass.center,23,.24,.04*lerpf(tension,next,p)),"margin":.001,"error":"Clear the shoulder rig during load transfer ({collider})."}]
	blocked_reason=Sweep.sweep(get_world_3d().direct_space_state,groups,2,func(_p: float)->Transform3D:return frame,15,ignored).get("error","")
	if not blocked_reason.is_empty():moving=false;return
	tension=next
	if tension==goal:moving=false;motion=""
	_crane()._refresh()
func placement_error(owner: String,sid: String) -> String:
	if owner!=spec.owner or sid not in spec.structural_slots+spec.service_slots:return ""
	if sid==spec.slot:return ""
	if not active:return "Seat the arm before shoulder handwork."
	if not motion.is_empty():return "Finish the shoulder load transfer before handwork."
	if sid in spec.service_slots:return "" if retained() and tension==0 else "Check the brakes and transfer weight to the retained shoulder before connecting isolated services."
	return "" if rigged() and tension==1 else "Keep all four ends carrying the arm while fitting shoulder retention."
func undo(owner: String) -> Dictionary:
	if owner!=spec.owner or game.model.assemblies[owner].history.is_empty():return {"handled":false,"error":""}
	var sid: String=game.model.assemblies[owner].history.back().slot
	if sid not in spec.structural_slots+spec.service_slots:return {"handled":false,"error":""}
	if not motion.is_empty():return {"handled":true,"error":"Finish shoulder load transfer before removing hardware."}
	if sid in spec.service_slots:return {"handled":false,"error":""}
	if not rigged() or tension!=1:return {"handled":true,"error":"Refit all four ends and take arm weight before removing shoulder retention."}
	return {"handled":false,"error":""}
func transport_shapes() -> Array[Dictionary]:return []
func sweep_exclusions(from: Transform3D,to: Transform3D) -> Array[RID]:
	var result: Array[RID]=[]
	var cassette=game.equipment.get_equipment("arm_cassette")
	# Only the deliberate lower pad/saddle contact is ignored. Folded clamp
	# swept geometry is tested separately before source ownership transfers.
	if minf(from.origin.y,to.origin.y)<1.552:result.append(cassette.body.get_rid())
	return result
func rig_solids(frame: Transform3D,_amount: float=0) -> Array[Dictionary]:return Geometry.rig(frame,mass.center,23,.24,.04*tension if active else 0.0)
func refresh_rig() -> void:
	var crane=_crane();var selected=crane!=null and crane.uid==spec.uid
	for mesh in rig_nodes:mesh.visible=false
	if not selected:return
	crane.rig_bar.visible=false
	var frame: Transform3D=crane.load_pose();var parts=rig_solids(frame)
	var offset: Vector3=crane.beam.global_position-beam_for_load(frame).origin-Vector3.UP*(.04*tension if active else 0.0)
	var end_index=0;var cable_index=0
	for i in range(parts.size()):
		var entry=parts[i];var mesh=rig_nodes[i]
		if entry.rig_kind=="end":
			var id: String=crane.END_IDS[end_index];end_index+=1
			if crane.endpoints[id].state=="attached":
				var p=crane.POINT_IDS.find(crane.endpoints[id].point)
				crane.end_nodes[id].mesh.size=Vector3(.08,.10,.10)
				crane.end_nodes[id].global_transform=Transform3D(frame.basis,frame*Vector3(-.72 if p%2==0 else .72,.10,.75 if p<2 else 4.40))
		elif entry.rig_kind=="suspension":
			# Endpoint identity is independent of its selected attachment face.
			for id in crane.END_IDS:
				if crane.endpoints[id].state=="attached" and crane.POINT_IDS.find(crane.endpoints[id].point)==cable_index:
					crane._line(crane.cables[id],entry.from+offset,entry.to,1)
			cable_index+=1
		elif entry.rig_kind=="hoist":
			var hook: Vector3=entry.from+offset
			crane._line(crane.mast_cable,hook,Vector3(hook.x,23,hook.z),1);game.leg_layout.set_crane_anchor(Vector3(hook.x,23,hook.z))
		else:
			mesh.visible=entry.rig_kind!="tagline" or crane.attached_count()==4
			mesh.mesh.size=entry.shape.size;mesh.global_transform=entry.world.translated(offset)
			if entry.rig_kind=="tagline" and mesh.visible:
				var end: Vector3=entry.to;var start: Vector3=entry.from+offset
				var d=end-start;mesh.mesh.size=Vector3(.018,d.length(),.018);mesh.global_transform=Transform3D(Basis(Quaternion(Vector3.UP,d.normalized())),(end+start)/2)
func capture() -> Dictionary:return {"version":1,"active":active,"brakes":brakes,"released":released,"tension":tension,"goal":goal,"motion":motion,"moving":moving}
func validate_crane(crane: Dictionary,model: AssemblyModel,state: Dictionary={}) -> Array[String]:
	var data=capture() if state.is_empty() else state
	if not secured(data,model) and not (data.released and retained(data,model) and data.tension==0) and not rigged(crane):return ["Unreleased shoulder requires all four crane ends."]
	if not retained(data,model) and data.tension!=1:return ["Unretained arm must remain fully crane-supported."]
	return []
func validate(data: Variant,candidate: AssemblyModel=null,world: Dictionary={}) -> Array[String]:
	if not Codec.same_keys(data,capture().keys()) or data.version!=1:return ["Invalid shoulder support state."]
	for key in ["active","brakes","moving","released"]:
		if not data[key] is bool:return ["Invalid shoulder support flag."]
	for key in ["tension","goal"]:
		if not Codec.number(data[key],1) or data[key]<0:return ["Invalid shoulder load fraction."]
	if not data.motion is String or data.motion not in ["","tension"] or (data.goal!=0 and data.goal!=1):return ["Invalid shoulder load transfer."]
	if data.motion.is_empty() and (data.moving or data.tension!=data.goal):return ["Stopped shoulder transfer lacks a resumable operation."]
	var model=_model(candidate)
	if data.active!=(model.assemblies[spec.uid].parent==spec.owner):return ["Shoulder support disagrees with arm ownership."]
	if not data.active:
		if data.brakes or data.released or data.tension!=0 or data.goal!=0 or not data.motion.is_empty():return ["Stored arm contains shoulder progress."]
		return []
	if not model.milestone("pelvis","chest_secured"):return ["Shoulder requires a retained chest."]
	if data.brakes and not _has(spec.structural_slots,model):return ["Brake confirmation requires every retained shoulder connection."]
	if data.released and (not retained(data,model) or data.tension!=0):return ["Released shoulder lost its independent retained support."]
	if data.tension<1 and not retained(data,model):return ["Shoulder lost crane support before retention and brake confirmation."]
	if _any(spec.service_slots,model) and (data.tension!=0 or not retained(data,model)):return ["Connected services require the retained shoulder to carry its load."]
	if world.has("equipment"):
		var crane: Dictionary=world.equipment.service_crane
		var errors=validate_crane(crane,model,data)
		if not errors.is_empty():return errors
		if (data.tension>0 or not data.motion.is_empty()) and not rigged(crane):return ["Shoulder load transfer has no matching crane."]
	return []
func apply(data: Dictionary) -> void:
	active=data.active;brakes=data.brakes;released=data.released;tension=float(data.tension);goal=float(data.goal);motion=data.motion;moving=data.moving;blocked_reason="";refresh_rig()
