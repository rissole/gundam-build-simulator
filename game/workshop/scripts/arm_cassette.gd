extends "res://scripts/equipment.gd"
## One reusable cassette; its retained arm remains on the same moving support.
const Codec=preload("res://scripts/pose_codec.gd")
const Sweep=preload("res://scripts/motion_sweep.gd")
const Geometry=preload("res://scripts/arm_delivery_geometry.gd")
var spec: Dictionary
var blockout: Node3D
var body: AnimatableBody3D
var floor_release=0.0
var clamps: Array=[0.0,0.0,0.0,0.0,0.0,0.0]
var clamp_groups: Array=[]
var source_nodes: Dictionary={}
var source_cols: Dictionary={}
var hardware: Array[RID]=[]
var bars: Array[MeshInstance3D]=[]
var geometry_key=""
var clamp_index=-1
var clamp_goal=0.0
var moving=false
var blocked_reason=""

func setup(workshop: Node3D, geometry: Node3D, definition: Dictionary) -> void:
	game=workshop;blockout=geometry;spec=definition;equipment_id="arm_cassette"
	body=game.runtime.node("arm_cassette")
	blockout.enable_group("arm_cassette",false)
	for id in blockout.spec.groups:
		if id.begins_with("arm_cassette_clamp_"):clamp_groups.append(id)
	for mesh in body.get_node("PreparedStructure").get_children():source_nodes[mesh.get_meta("source_uid")]=mesh
	for col in body.get_children():
		if col is CollisionShape3D and col.has_meta("source_uid"):source_cols[col.get_meta("source_uid")]=col
	for id in blockout.pieces:
		if id.begins_with("arm_cassette_floor_pad_") or id.begins_with("arm_park_pedestal_"):hardware.append(blockout.pieces[id].body.get_rid())
	for entry in Geometry.cassette_rig(Transform3D.IDENTITY):
		if entry.rig_kind not in ["spreader","equalizer","hook"]:continue
		var mesh=game.box(self,Vector3.ZERO,entry.shape.size,game.material(Color("e8b46b"),.45))
		mesh.set_meta("head_frame",entry.world.translated(-Vector3(0,3.10,3.70)));mesh.set_meta("rig_kind",entry.rig_kind);bars.append(mesh);mesh.visible=false
	game.model.changed.connect(_pose)
	call_deferred("_connect_crane")
	_pose()

func _connect_crane() -> void:
	var crane=_crane()
	if crane!=null:crane.changed.connect(refresh_rig);refresh_rig()

func _record(model: AssemblyModel=null) -> Dictionary:return (game.model if model==null else model).assemblies.arm_cassette
func occupant(model: AssemblyModel=null) -> String:return (game.model if model==null else model).support_occupant("arm_cassette")
func _crane() -> Node:return game.equipment.get_equipment("service_crane")

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for n in range(clamp_groups.size()):
		var uid="CS-"+clamp_groups[n]+"_foot";var mesh: MeshInstance3D=source_nodes[uid]
		result.append(control_entry(mesh,("stop" if moving else "resume") if clamp_index==n else "clamp:"+str(n),("Stop clamp" if moving else "Resume clamp") if clamp_index==n else ("Fold" if clamps[n]==0 else "Close")+" cassette clamp",.12,{"point":mesh.global_position,"allowed":[body],"allow_body_hit":true}))
	return result

func action_error(action: String) -> String:
	if game.paused:return "Resume before operating the cassette."
	if action=="stop":return "" if moving else "The cassette clamp is stopped."
	if action=="resume":return "" if clamp_index>=0 and not moving else "There is no stopped clamp to resume."
	if clamp_index>=0:return "Finish the moving cassette clamp first."
	if not action.begins_with("clamp:") or not action.get_slice(":",1).is_valid_int():return "Unknown cassette command."
	var index=int(action.get_slice(":",1))
	if index<0 or index>=clamps.size():return "Unknown cassette clamp."
	if not occupant().is_empty():return "Keep all cassette clamps engaged until the arm is supported by its four crane ends."
	if _record().location=="support:crane_rigging":return "Set the cassette down before adjusting its clamps."
	return ""

func request(action: String) -> String:
	var error=action_error(action)
	if not error.is_empty():return error
	if action=="stop":moving=false
	elif action=="resume":moving=true
	else:clamp_index=int(action.get_slice(":",1));clamp_goal=1.0-clamps[clamp_index];moving=true
	blocked_reason="";return ""

func physics(delta: float) -> void:
	if game.paused or not moving:return
	var next=clamps.duplicate();next[clamp_index]=move_toward(next[clamp_index],clamp_goal,delta/2)
	blocked_reason=_clamp_error(next)
	if not blocked_reason.is_empty():moving=false;return
	clamps=next
	if clamps[clamp_index]==clamp_goal:moving=false;clamp_index=-1
	_pose()

func _clamp_error(next: Array) -> String:
	var shapes: Array[Dictionary]=[]
	for uid in spec.pieces:
		var piece: Dictionary=spec.pieces[uid];var index=clamp_groups.find(piece.group)
		if index<0 or next[index]==clamps[index]:continue
		var shape=BoxShape3D.new();shape.size=AssemblyRuntime.vec(piece.size)
		var at=func(p: float)->Transform3D:return body.global_transform*_clamp_pose(uid,lerpf(clamps[index],next[index],p))
		var error=Sweep.sweep(get_world_3d().direct_space_state,[{"shapes":[{"shape":shape,"transform":Transform3D.IDENTITY}],"margin":-.0005,"error":"Clear the cassette clamp sweep ({collider})."}],maxi(1,ceili(absf(next[index]-clamps[index])*PI/2*.6/.015)),at,15,[body.get_rid()]).get("error","")
		if not error.is_empty():return error
	return ""

func _clamp_pose(uid: String,value: float) -> Transform3D:
	var piece: Dictionary=spec.pieces[uid];var group: Dictionary=blockout.spec.groups[piece.group]
	var side=signf(float(group.position[0]));var length=lerpf(.51,.11,clampf(value/.5,0,1))
	var at=AssemblyRuntime.vec(piece.position);var scale=Vector3.ONE
	if uid.ends_with("_bar"):at.x=-side*length/2;scale.x=length/.51
	else:at.x=-side*length
	return Transform3D(Basis(Vector3.BACK,deg_to_rad(group.fold_degrees)*clampf((value-.5)/.5,0,1)),AssemblyRuntime.vec(group.position))*Transform3D(Basis.IDENTITY.scaled(scale),at)

func support_secured(uid: String="arm_cassette",model: AssemblyModel=null,state: Dictionary={}) -> bool:
	var locked=_record(model).location in ["support:cassette_park","support:cassette_station"] and (floor_release if state.is_empty() else float(state.floor_release))==0
	if uid=="arm_cassette":return locked
	return locked and occupant(model)==uid and (clamps if state.is_empty() else state.clamps).all(func(value):return value==0)

func receiving_error(uid: String,destination: String="cassette_station") -> String:
	if uid!="arm_cassette":
		if _record().location!="support:cassette_station" or not support_secured():return "Lock the cassette at the common station before loading an arm."
		if occupant() not in ["",uid]:return "Install the first arm before loading the second onto this cassette."
		return "" if clamp_index<0 else "Finish the cassette clamp movement first."
	if destination=="cassette_station":
		var holder: String=game.zones.holder("limb_station")
		if holder=="leg_rail":return "Park the leg cradle at X22 before bringing the cassette into the common station."
		if holder=="foot_carrier":return "Clear the foot carrier from the common station before lowering the cassette."
	return ""

func source_error(uid: String="arm_cassette") -> String:
	if uid!="arm_cassette":return receiving_error(uid)
	if clamp_index>=0:return "Finish the cassette clamp movement before lifting."
	if not occupant().is_empty() and not clamps.all(func(value):return value==0):return "Close all six cassette clamps before moving the retained arm."
	return ""

func reacquire_error(uid: String="arm_cassette") -> String:return source_error(uid)
func release_error(uid: String="arm_cassette") -> String:
	if uid!="arm_cassette" and game.model.assemblies[uid].parent=="chest":return ""
	return "" if support_secured(uid) else "Wait for the cassette floor locks and all arm clamps before releasing a crane end."

func source_contact(release: float,uid: String="arm_cassette") -> String:
	var error=source_error(uid)
	if not error.is_empty():return error
	if uid!="arm_cassette":
		var next: Array=[];next.resize(6);next.fill(0.0 if is_zero_approx(release) else 1.0 if is_equal_approx(release,1) else release)
		error=_clamp_error(next)
		if not error.is_empty():return error
		clamps=next;_pose();return ""
	floor_release=0.0 if is_zero_approx(release) else 1.0 if is_equal_approx(release,1.0) else release
	_pose();return ""

func busy_reason(subject: String) -> String:
	if subject in ["rail","foot_transfer","source_roll"] and _record().location!="support:cassette_park":return "Park the retained arm cassette before using the leg station."
	return ""

func transport_shapes() -> Array[Dictionary]:
	var result: Array[Dictionary]=[];var arm=occupant()
	if not arm.is_empty():Sweep.collect_shapes(game.runtime.node(arm),body.global_transform.affine_inverse(),result)
	return result

func sweep_exclusions(from: Transform3D,to: Transform3D) -> Array[RID]:
	var result: Array[RID]=[];var arm=occupant()
	if not arm.is_empty():Sweep.collect_rids(game.runtime.node(arm),result)
	# Feet deliberately meet the fixed floor at the source/receiver contact.
	# Intermediate suspended travel still tests the floor as an obstacle.
	if minf(from.origin.y,to.origin.y)<.002:
		for piece in blockout.pieces.values():
			if piece.has("body") and piece.spec.id=="floor":result.append(piece.body.get_rid())
	return result

func mass_properties() -> Dictionary:
	var result={"mass":0.0,"center":Vector3.ZERO}
	for uid in source_nodes:
		var mass: float=game.leg_content.sources[uid].mass_kg
		result.mass+=mass;result.center+=source_nodes[uid].position*mass
	result.center/=result.mass
	var arm=occupant()
	if not arm.is_empty():
		var load=Geometry.mass_properties(game.leg_content,game.runtime.definition(arm))
		result.center=(result.center*result.mass+(load.center+AssemblyRuntime.vec(spec.arm_offset))*load.mass)/(result.mass+load.mass)
		result.mass+=load.mass
	return result

func rig_solids(frame: Transform3D,_amount: float=0) -> Array[Dictionary]:return Geometry.cassette_rig(frame,mass_properties().center)

func refresh_rig() -> void:
	_pose()
	var crane=_crane();var selected=crane!=null and crane.uid=="arm_cassette"
	var center: Vector3=mass_properties().center
	for mesh in bars:
		mesh.visible=selected
		if selected:
			var frame: Transform3D=mesh.get_meta("head_frame")
			if mesh.get_meta("rig_kind")=="hook":frame.origin+=Vector3(center.x,0,center.z-3.70)
			mesh.global_transform=crane.beam.global_transform*frame
	if selected:
		crane.rig_bar.visible=false
		var hook: Vector3=crane.beam.global_transform*Vector3(center.x,.24,center.z-3.70)
		crane._line(crane.mast_cable,hook,Vector3(hook.x,23,hook.z),1)
		game.leg_layout.set_crane_anchor(Vector3(hook.x,23,hook.z))

func _pose() -> void:
	if _record().location=="support:cassette_station":game.zones.claim("limb_station",equipment_id)
	else:game.zones.release("limb_station",equipment_id)
	if not is_instance_valid(body):return
	var location: String=_record().location
	if location in ["support:cassette_park","support:cassette_station"]:
		body.global_transform=Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(spec.park if location=="support:cassette_park" else spec.station))
	for uid in spec.pieces:
		var piece: Dictionary=spec.pieces[uid]
		var index=clamp_groups.find(piece.group)
		var pose: Transform3D=game.source[uid].transform
		if index>=0:
			pose=_clamp_pose(uid,clamps[index])
		if uid.begins_with("CS-LOCK-PIN"):pose.origin.y+=floor_release*.12
		if uid.begins_with("CS-LOCK-HANDLE"):pose.basis=Basis(Vector3.UP,PI/2*floor_release)
		source_nodes[uid].transform=pose;source_cols[uid].transform=pose
	var key=str(floor_release)+str(clamps)
	if key!=geometry_key:
		geometry_key=key;body.set_meta("collision_revision",int(body.get_meta("collision_revision",0))+1)
	body.force_update_transform();PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	var arm=occupant()
	if not arm.is_empty():
		var node=game.runtime.node(arm);node.global_transform=body.global_transform*Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(spec.arm_offset))
		node.force_update_transform();PhysicsServer3D.body_set_state(node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,node.global_transform)

func capture() -> Dictionary:return {"version":1,"floor_release":floor_release,"clamps":clamps.duplicate(),"clamp_index":clamp_index,"clamp_goal":clamp_goal,"moving":moving}

func validate(data: Variant,candidate: AssemblyModel=null,world: Dictionary={}) -> Array[String]:
	if not Codec.same_keys(data,capture().keys()) or data.version!=1:return ["Invalid cassette snapshot."]
	if not data.floor_release is float and not data.floor_release is int:return ["Invalid cassette floor locks."]
	if not is_finite(data.floor_release) or data.floor_release<0 or data.floor_release>1:return ["Invalid cassette floor-lock travel."]
	if not data.clamps is Array or data.clamps.size()!=6 or data.clamps.any(func(value):return not Codec.number(value,1) or value<0):return ["Invalid cassette clamp state."]
	if not Codec.number(data.clamp_index,5) or int(data.clamp_index)!=data.clamp_index or data.clamp_index< -1 or not Codec.number(data.clamp_goal,1) or (data.clamp_goal!=0 and data.clamp_goal!=1) or not data.moving is bool:return ["Invalid cassette clamp operation."]
	if data.clamp_index<0 and data.moving:return ["Moving cassette clamp has no selected clamp."]
	var m: AssemblyModel=game.model if candidate==null else candidate
	var record=_record(m);var arm=occupant(m)
	var arm_contact=false;var expected_clamp=0.0
	if world.has("equipment"):
		var crane: Dictionary=world.equipment.service_crane
		arm_contact=(crane.task in ["left_arm","right_arm"] and crane.station=="source" or crane.task=="right_arm_store" and crane.station=="receiver") and crane.motion in ["up","down"] and crane.endpoints.values().all(func(end):return end.state=="attached")
		if arm_contact:expected_clamp=clampf(crane.progress/.1,0,1) if crane.motion=="up" else 1-clampf((crane.progress-.9)/.1,0,1)
	if arm_contact:
		if not data.clamps.all(func(value):return is_equal_approx(value,expected_clamp)) or data.clamp_index>=0:return ["Arm clamps disagree with the four-end weight-transfer phase."]
	elif not arm.is_empty() and not data.clamps.all(func(value):return value==0):return ["Retained arm lost a cassette clamp."]
	if data.clamp_index>=0 and (not arm.is_empty() or record.location=="support:crane_rigging"):return ["Manual clamp movement requires an empty floor-supported cassette."]
	if not arm_contact:
		for n in range(6):
			if n!=data.clamp_index and data.clamps[n]!=0 and data.clamps[n]!=1:return ["Partial cassette clamp has no resumable movement."]
	if not world.is_empty():
		var frame: Transform3D=Codec.to_pose(world.fixtures.arm_cassette)
		if record.location=="support:crane_rigging" and frame.origin.y>.002 and data.floor_release!=1:return ["Suspended cassette floor pins must be fully retracted."]
		if record.location in ["support:cassette_park","support:cassette_station"]:
			var at=AssemblyRuntime.vec(spec.park if record.location=="support:cassette_park" else spec.station)
			if not frame.is_equal_approx(Transform3D(Basis.IDENTITY,at)):return ["Cassette pose disagrees with its floor support."]
		if not arm.is_empty() and not Codec.to_pose(world.fixtures[arm]).is_equal_approx(frame*Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(spec.arm_offset))):return ["Retained arm pose disagrees with its cassette."]
		if record.location=="support:cassette_station":
			var rail: Dictionary=world.equipment.leg_rail
			if rail.path!=0 or not is_equal_approx(rail.index_x,22) or rail.moving:return ["Cassette and leg cradle occupy the shared station together."]
		if data.floor_release>0:
			var crane: Dictionary=world.equipment.service_crane
			if crane.task!="cassette" or crane.endpoints.values().any(func(end):return end.state!="attached"):return ["Cassette lost floor retention without four-end crane support."]
		var crane: Dictionary=world.equipment.service_crane
		var expected=1.0 if record.location=="support:crane_rigging" else 0.0
		if crane.task=="cassette" and crane.endpoints.values().all(func(end):return end.state=="attached"):
			if crane.motion=="up":expected=clampf(crane.progress/.1,0,1)
			if crane.motion=="down":expected=1-clampf((crane.progress-.9)/.1,0,1)
		if not is_equal_approx(data.floor_release,expected):return ["Cassette floor-lock contact disagrees with crane weight transfer."]
	return []

func apply(data: Dictionary) -> void:
	floor_release=float(data.floor_release);clamps=data.clamps.duplicate();clamp_index=int(data.clamp_index);clamp_goal=float(data.clamp_goal);moving=data.moving;blocked_reason="";_pose()
