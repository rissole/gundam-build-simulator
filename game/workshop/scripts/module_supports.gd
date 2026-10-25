extends "res://scripts/equipment.gd"
## Shared bulky support and the pelvis gantry's four physical hold-down jaws.
## Ownership remains in AssemblyModel throughout lift/contact/retention phases.
const Codec=preload("res://scripts/pose_codec.gd")
const Sweep=preload("res://scripts/motion_sweep.gd")
const Layout=preload("res://scripts/leg_bay_layout.gd")
var blockout: Node3D
var spec: Dictionary
var template="pelvis"
var height: float=0.0
var goal: float=0.0
var moving=false
var blocked_reason=""
var source_release: float=0.0
var jaw_groups: Array[String]=[]
var jaws: Array[float]=[1,1,1,1]
var jaw_goals: Array[float]=[1,1,1,1]
var locks={"yaw":false,"lean":false}
var lock_nodes: Dictionary={}
var buttons: Array[Dictionary]=[]
var hardware: Array[RID]=[]
var label: Label3D

func setup(workshop: Node3D, geometry: Node3D) -> void:
	game=workshop;blockout=geometry;spec=geometry.spec.bulky_fixture;equipment_id="module_supports"
	for id in blockout.groups:
		if id.begins_with("gantry_jaw_"):jaw_groups.append(id)
	hardware=blockout.rids_for_groups(["bulky_fixture"]+jaw_groups)
	for id in blockout.pieces:
		if id.begins_with("gantry_bearing_") or id.begins_with("gantry_arm_") or id.begins_with("gantry_jaw_"):hardware.append(blockout.pieces[id].body.get_rid())
	var panel=Node3D.new();add_child(panel);panel.position=AssemblyRuntime.vec(spec.panel)
	game.box(panel,Vector3(0,.65,0),Vector3(.14,1.3,.7),game.material(Color("263a43")),true)
	for i in range(3):
		var button=preload("res://scripts/equipment_button.gd").make(game,panel,Vector3(-.10,1.2,-.26+i*.26),["↑ UP","STOP","↓ DOWN"][i],-PI/2,i == 0)
		buttons.append(control_entry(button,["advance","stop","return"][i],["Raise bulky fixture","Stop fixture","Lower bulky fixture"][i],.11))
	var insert_button=preload("res://scripts/equipment_button.gd").make(game,panel,Vector3(-.10,.90,0),"INSERT",-PI/2)
	buttons.append(control_entry(insert_button,"template:chest","Cycle fixture inserts",.15,{"cycle_templates":true}))
	label=game.sign_panel(panel,"",Vector3(-.08,1.75,0),Vector2(1.4,.4),28,.0015,-PI/2)
	for key in locks:
		var root=Node3D.new();root.name="Waist_"+key+"_lock";game.runtime.node("pelvis").add_child(root);root.position=AssemblyRuntime.vec(spec.locks[key])
		lock_nodes[key]=game.box(root,Vector3.ZERO,Vector3(.12,.10,.12),game.material(Color("e8b46b")))
	_pose()

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for entry in buttons:
		var current=entry.duplicate();current.point=current.node.global_position
		if current.get("cycle_templates",false):
			var next: String=spec.templates.keys()[(spec.templates.keys().find(template)+1)%spec.templates.size()]
			current.action="template:"+next;current.label="Fit "+next+" contact inserts (current: "+template+")"
		result.append(current)
	for index in range(4):
		var piece: Dictionary=blockout.pieces[jaw_groups[index]+"_handle"]
		var handle: MeshInstance3D=piece.visual
		var pending=not is_equal_approx(jaws[index],jaw_goals[index])
		result.append(control_entry(handle,"stop" if moving and pending else "jaw:"+str(index),("Stop" if moving and pending else "Resume" if pending else "Close" if jaws[index]>.5 else "Open")+" gantry hold-down jaw",.28,{"point":handle.global_position,"allowed":[piece.body],"allow_body_hit":true}))
	for key in locks:
		result.append(control_entry(lock_nodes[key],"lock:"+key,("Unlock " if locks[key] else "Engage ")+"waist "+key+" neutral pin",.10,{"point":lock_nodes[key].global_position}))
	return result

func _location(model: AssemblyModel=null) -> String:return (game.model if model==null else model).assemblies.pelvis.location
func waist_ready(state: Dictionary={}) -> bool:
	var values: Dictionary=locks if state.is_empty() else state.locks
	return values.yaw and values.lean
func support_secured(assembly: String="pelvis", model: AssemblyModel=null, state: Dictionary={}) -> bool:
	var m: AssemblyModel=game.model if model==null else model
	if m.assemblies[assembly].location=="support:bulky_fixture":return (source_release if state.is_empty() else state.source_release)==0
	if assembly=="chest":
		return m.assemblies.chest.parent=="pelvis" and m.milestone("pelvis","chest_secured") and support_secured("pelvis",m,state)
	if assembly!="pelvis":return false
	var values: Array=jaws if state.is_empty() else state.jaws
	return _location(model)=="support:"+spec.receiver_support and values.all(func(value):return is_zero_approx(value)) and waist_ready(state)

func receiving_error(assembly: String, destination: String="pelvis_gantry") -> String:
	if destination=="bulky_fixture":
		if template!=assembly or moving or height!=0:return "Fit matching inserts on the lowered, stopped empty bulky fixture."
		var occupant=game.model.support_occupant("bulky_fixture")
		if not occupant.is_empty() and occupant!=assembly:return "The bulky fixture is occupied."
		return ""
	if assembly=="chest":
		return "" if support_secured() else "Secure the pelvis gantry and engage both waist neutral pins before chest delivery."
	if assembly!="pelvis":return "These gantry bearings receive the pelvis bridge."
	if _location()=="support:"+spec.receiver_support:return ""
	if not game.model.support_occupant(spec.receiver_support).is_empty():return "The gantry bearings are occupied."
	if moving or not jaws.all(func(value):return is_equal_approx(value,1)):return "Open all four gantry jaws before lowering the pelvis."
	return ""

func source_error(assembly: String="pelvis") -> String:
	if template!=assembly:return "Fit the matching inserts before using this source fixture."
	if moving or height!=0:return "Lower and stop the bulky fixture at its pickup datum."
	if assembly=="pelvis" and not waist_ready():return "Engage both waist neutral pins before lifting the prepared pelvis."
	return ""

func release_error(assembly: String="pelvis") -> String:
	if assembly!="pelvis":
		if game.model.assemblies[assembly].location=="support:bulky_fixture" and source_release!=0:return "Wait for the fixture clamps to close."
		return ""
	if not waist_ready():return "Confirm both waist neutral locks before releasing rigging."
	if _location()=="support:"+spec.receiver_support and not support_secured():return "Close all four gantry hold-down jaws before releasing a lifting end."
	if _location()=="support:"+spec.source_support and source_release!=0:return "Wait for the source clamps to close before releasing rigging."
	return ""

func reacquire_error(assembly: String="pelvis") -> String:
	if assembly!="pelvis" and game.model.assemblies[assembly].location=="support:bulky_fixture":return source_error(assembly)
	if assembly=="chest":
		if game.model.assemblies.chest.slots.values().any(func(value):return not value.is_empty()):return "Remove dependent chest construction before lifting the chest."
		return "" if support_secured() else "Keep the gantry secured and both waist neutral pins engaged."
	if game.model.assemblies.pelvis.slots.values().any(func(uid):return not uid.is_empty()):return "Remove dependent gantry construction before lifting the pelvis."
	if not jaws.all(func(value):return is_equal_approx(value,1)):return "Attach all four ends, then open the four gantry jaws before lifting."
	return "" if waist_ready() else "Engage the waist neutral locks before lifting."

func action_error(action: String) -> String:
	if game.paused:return "Resume before operating the support."
	if action.begins_with("template:"):
		var selected=action.get_slice(":",1)
		if not spec.templates.has(selected):return "Unknown fixture insert set."
		if moving or height!=0 or not game.model.support_occupant("bulky_fixture").is_empty():return "Empty, lower and stop the bulky fixture before exchanging inserts."
		var crane=game.equipment.get_equipment("service_crane")
		if crane.attached_count()>0 or not crane.motion.is_empty():return "Park the empty crane before exchanging inserts."
		return game.hands.error(equipment_id)
	if action=="stop":return "" if moving else "The fixture is stopped."
	if action.begins_with("lock:"):
		var key=action.get_slice(":",1)
		if not locks.has(key):return "Unknown waist lock."
		if moving or _location() not in ["support:"+spec.source_support,"support:"+spec.receiver_support]:return "Seat the pelvis on a stationary fixture before operating its locks."
		if locks[key] and game.model.assemblies.pelvis.slots.values().any(func(uid):return not uid.is_empty()):return "Keep the waist locked while dependent gantry construction is fitted."
		if locks[key] and _location()=="support:"+spec.receiver_support:return "Keep both waist neutral pins engaged while the pelvis is on the gantry."
		var crane=game.equipment.get_equipment("service_crane")
		if crane!=null and crane.uid=="pelvis" and not crane.motion.is_empty():return "Finish the supported crane movement before changing a waist lock."
		return game.hands.error(equipment_id)
	if action.begins_with("jaw:"):
		var index=action.get_slice(":",1).to_int()
		if index<0 or index>=4:return "Unknown gantry jaw."
		if moving:return "Stop or finish the current support movement first."
		if _location()!="support:"+spec.receiver_support:return "Seat the pelvis bridge on the gantry bearings first."
		if jaws[index]<.5:
			var crane=game.equipment.get_equipment("service_crane")
			if crane.uid!="pelvis" or crane.attached_count()!=4 or crane.station!="receiver" or crane.raised or not crane.motion.is_empty():return "Reattach all four crane ends with the spreader down before opening a gantry jaw."
			if game.model.assemblies.pelvis.slots.values().any(func(uid):return not uid.is_empty()):return "The gantry jaws must hold the dependent robot construction."
		return game.hands.error(equipment_id)
	if action not in ["advance","return"]:return "Unknown bulky fixture command."
	if moving:return "Stop the fixture before changing direction."
	if jaws!=jaw_goals:return "Resume the interrupted jaw at its gantry handle."
	if source_release!=0 and not game.model.support_occupant("bulky_fixture").is_empty():return "Close the source clamps before adjusting the occupied fixture."
	var crane=game.equipment.get_equipment("service_crane")
	if crane!=null and crane.uid==template and (crane.attached_count()>0 or not crane.motion.is_empty()):return "Stow the crane ends before adjusting the occupied fixture."
	if (action=="advance" and height==1) or (action=="return" and height==0):return "The fixture is already at this height stop."
	return ""

func request(action: String) -> String:
	var error=action_error(action)
	if not error.is_empty():return error
	if action.begins_with("template:"):template=action.get_slice(":",1);source_release=1
	elif action=="stop":moving=false
	elif action.begins_with("lock:"):
		var key=action.get_slice(":",1);locks[key]=not locks[key]
	elif action.begins_with("jaw:"):
		var index=action.get_slice(":",1).to_int()
		if is_equal_approx(jaws[index],jaw_goals[index]):jaw_goals[index]=0 if jaws[index]>.5 else 1
		moving=true
	else:goal=1 if action=="advance" else 0;moving=true
	blocked_reason="";_pose();return ""

func frames_at(h: float, release: float, clamps: Array) -> Dictionary:
	var frames={"bulky_frame":Transform3D(Basis.IDENTITY,Vector3(0,h*spec.height_travel,0))}
	for id in blockout.groups:
		if not id.begins_with("bulky_jaw_"):continue
		var at=blockout.authored_pose(blockout.spec.groups[id]);at.origin.y+=release*.25;frames[id]=at
	for index in range(4):
		var id=jaw_groups[index];var at=blockout.authored_pose(blockout.spec.groups[id]);at.origin.y+=clamps[index]*.25;frames[id]=at
	return frames

func source_contact(value: float, _assembly: String="pelvis") -> String:
	if is_zero_approx(value):value=0
	elif is_equal_approx(value,1):value=1
	var error=motion_error(height,height,source_release,value,jaws,jaws)
	if not error.is_empty():return error
	source_release=value;_pose();return ""

func motion_error(from_h: float,to_h: float,from_release: float,to_release: float,from_jaws: Array,to_jaws: Array) -> String:
	var ignored: Array[RID]=hardware.duplicate();Sweep.collect_rids(game.runtime.node(template),ignored)
	var roots: Array=[]
	if from_h!=to_h:roots.append("bulky_frame")
	elif from_release!=to_release:
		for id in blockout.groups:
			if id.begins_with("bulky_jaw_"):roots.append(id)
	for i in range(4):
		if from_jaws[i]!=to_jaws[i]:roots.append(jaw_groups[i])
	var amount=maxf(absf(to_h-from_h),absf(to_release-from_release))
	for i in range(4):amount=maxf(amount,absf(to_jaws[i]-from_jaws[i]))
	if amount<.000001:return ""
	var rig=func(_pose: Transform3D,p: float) -> Array:
		var clamps: Array=[]
		for i in range(4):clamps.append(lerpf(from_jaws[i],to_jaws[i],p))
		return blockout.shapes_at(roots,frames_at(lerpf(from_h,to_h,p),lerpf(from_release,to_release,p),clamps))
	var groups=[{"shapes_at":rig,"margin":.001,"error":"Clear the moving fixture or jaw ({collider})."}]
	if game.model.support_occupant("bulky_fixture")==template and from_h!=to_h:
		var solids: Array[Dictionary]=[];var body=game.runtime.node(template)
		Sweep.collect_shapes(body,body.global_transform.affine_inverse(),solids)
		groups.append({"shapes":solids,"margin":.001,"error":"Clear the raised pelvis route ({collider})."})
	return Sweep.sweep(get_world_3d().direct_space_state,groups,maxi(1,ceili(amount*30)),func(p: float)->Transform3D:return Layout.authored_pose(spec.templates[template]).translated(Vector3.UP*lerpf(from_h,to_h,p)*spec.height_travel),15,ignored,equipment_id).get("error","")

func _pose() -> void:
	for key in spec.templates:blockout.enable_group("bulky_insert_"+key,key==template)
	blockout.apply_frames(frames_at(height,source_release,jaws))
	if game.model.support_occupant("bulky_fixture")==template:game.runtime.node(template).global_transform=Layout.authored_pose(spec.templates[template]).translated(Vector3.UP*height*spec.height_travel)
	for key in locks:lock_nodes[key].position=(Vector3.UP if key=="yaw" else Vector3.RIGHT)*(.10 if not locks[key] else 0)
	var body: CollisionObject3D=game.runtime.node(template);body.force_update_transform();PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	label.text="BULKY FIXTURE / "+("Moving" if moving else "Locked height")+"\n"+(blocked_reason if not blocked_reason.is_empty() else "Inserts: "+template+" / crane pickup at lowest stop")

func physics(delta: float) -> void:
	if game.paused or not moving:return
	var next_h=move_toward(height,goal,delta*.3);var next_jaws: Array[float]=[]
	for i in range(4):next_jaws.append(move_toward(jaws[i],jaw_goals[i],delta*.7))
	blocked_reason=motion_error(height,next_h,source_release,source_release,jaws,next_jaws)
	if not blocked_reason.is_empty():moving=false;_pose();return
	height=next_h;jaws.assign(next_jaws);moving=height!=goal or jaws!=jaw_goals;_pose()

func busy_reason(subject: String) -> String:
	if moving and subject in ["crane","pelvis","bulky_fixture"]:return "Wait for the bulky fixture and gantry jaws to stop."
	return ""

func access_error(owner: String) -> String:
	if owner=="pelvis" and not support_secured():return "Secure the pelvis on the gantry before fitting its external connections."
	return ""

func capture() -> Dictionary:return {"version":1,"template":template,"height":height,"goal":goal,"moving":moving,"source_release":source_release,"jaws":jaws.duplicate(),"jaw_goals":jaw_goals.duplicate(),"locks":locks.duplicate()}

func validate(data: Variant,candidate: AssemblyModel=null,world: Dictionary={}) -> Array[String]:
	if not Codec.same_keys(data,capture().keys()) or data.version!=1 or not data.moving is bool:return ["Invalid module support state."]
	if not data.template is String or not spec.templates.has(data.template):return ["Unknown bulky fixture inserts."]
	for key in ["height","goal","source_release"]:
		if not Codec.number(data[key],1) or data[key]<0:return ["Invalid source fixture progress."]
	for key in ["jaws","jaw_goals"]:
		if not data[key] is Array or data[key].size()!=4 or not data[key].all(func(value):return Codec.number(value,1) and value>=0):return ["Invalid gantry jaw progress."]
	if not Codec.same_keys(data.locks,locks.keys()) or not data.locks.values().all(func(value):return value is bool):return ["Invalid waist neutral locks."]
	if (data.goal!=0 and data.goal!=1) or not data.jaw_goals.all(func(value):return value==0 or value==1):return ["Fixture motion targets must be physical end stops."]
	var model: AssemblyModel=game.model if candidate==null else candidate
	var occupant=model.support_occupant("bulky_fixture")
	if not occupant.is_empty() and occupant!=data.template:return ["Occupied bulky fixture has the wrong contact inserts."]
	var location=_location(model)
	if location not in ["support:"+spec.source_support,"support:"+spec.receiver_support,"support:crane_rigging"]:return ["Pelvis has no declared workshop support."]
	if location!="support:"+spec.receiver_support and not data.jaws.all(func(value):return is_equal_approx(value,1)):return ["Empty gantry cannot have closed or moving hold-downs."]
	if model.assemblies.pelvis.slots.values().any(func(uid):return not uid.is_empty()) and not support_secured("pelvis",model,data):return ["Robot construction requires clamped gantry support and waist locks."]
	if world.has("fixtures") and location!="support:crane_rigging":
		var expected=Layout.authored_pose(spec.source_pose).translated(Vector3.UP*data.height*spec.height_travel) if location=="support:"+spec.source_support else Layout.authored_pose(spec.receiver_pose)
		if not Codec.to_pose(world.fixtures.pelvis).is_equal_approx(expected):return ["Pelvis pose disagrees with its current fixture."]
	if world.has("equipment"):
		var crane: Dictionary=world.equipment.service_crane
		var expected_release=0.0 if not occupant.is_empty() else 1.0
		if Layout.layout().crane.tasks[crane.task].get("source_equipment","")==equipment_id and crane.station=="source" and crane.endpoints.values().all(func(end):return end.state=="attached"):
			if data.height!=0:return ["Rigged source fixture is away from its pickup datum."]
			if crane.motion=="up":expected_release=clampf(crane.progress/.1,0,1)
			elif crane.motion=="down":expected_release=1-clampf((crane.progress-.9)/.1,0,1)
		if Layout.layout().crane.tasks[crane.task].get("receiver_equipment","")==equipment_id and Layout.layout().crane.tasks[crane.task].get("receiver_contact",false) and crane.station=="receiver" and crane.endpoints.values().all(func(end):return end.state=="attached"):
			if crane.motion=="down":expected_release=1-clampf((crane.progress-.9)/.1,0,1)
			elif crane.motion=="up":expected_release=clampf(crane.progress/.1,0,1)
		if not is_equal_approx(data.source_release,expected_release):return ["Source clamp contact disagrees with crane weight transfer."]
		var suspended=location=="support:crane_rigging"
		var releasing=location=="support:"+spec.source_support and data.source_release>0
		var unsecured=location=="support:"+spec.receiver_support and not support_secured("pelvis",model,data)
		if suspended or releasing or unsecured:
			if crane.task!="pelvis" or not waist_ready(data) or not crane.endpoints.values().all(func(end):return end.state=="attached"):return ["Unsecured pelvis requires all four crane ends and waist locks."]
	if world.has("fixtures"):
		for identity in spec.templates:
			if identity=="pelvis":continue
			var record: Dictionary=model.assemblies[identity]
			if record.location=="support:bulky_fixture":
				var expected=Layout.authored_pose(spec.templates[identity]).translated(Vector3.UP*data.height*spec.height_travel)
				if not Codec.to_pose(world.fixtures[identity]).is_equal_approx(expected):return ["Module pose disagrees with its fixture."]
			elif record.location=="support:"+identity+"_store":
				if not Codec.to_pose(world.fixtures[identity]).is_equal_approx(Layout.authored_pose(blockout.spec[identity+"_storage"])):return ["Module is displaced from its storage support."]
	return []

func apply(data: Dictionary) -> void:
	template=data.template;height=data.height;goal=data.goal;moving=data.moving;source_release=data.source_release;jaws.assign(data.jaws);jaw_goals.assign(data.jaw_goals);locks=data.locks.duplicate();blocked_reason="";_pose()
	# A reload starts with the pelvis on the bulky fixture; the gantry seat is fixed.
	# Builds mounted on the pelvis follow it.
	if _location()=="support:"+spec.receiver_support:
		var pelvis: CollisionObject3D=game.runtime.node("pelvis");pelvis.global_transform=Layout.authored_pose(spec.receiver_pose)
		pelvis.force_update_transform();PhysicsServer3D.body_set_state(pelvis.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,pelvis.global_transform)
