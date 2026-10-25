extends "res://scripts/equipment.gd"
## Complementary crane/guide support: no unowned or remotely fastened core.
const Codec=preload("res://scripts/pose_codec.gd")
const Sweep=preload("res://scripts/motion_sweep.gd")
var spec: Dictionary
var active=false
var rig: float=0.0
var rig_goal: float=0.0
var travel: float=0.0
var goal: float=0.0
var moving=false
var blocked_reason=""
var bolts: Array[bool]=[false,false,false,false]
var connected=false
var buttons: Array[Dictionary]=[]
var bolt_nodes: Array[Node3D]=[]
var connection_nodes: Dictionary={}
var bridge: Node3D
var bridge_shapes: Array[Dictionary]=[]
var label: Label3D

func setup(workshop: Node3D, definition: Dictionary) -> void:
	game=workshop;spec=definition;equipment_id="core_guide"
	var panel=Node3D.new();game.runtime.node(spec.owner).add_child(panel);panel.position=AssemblyRuntime.vec(spec.panel)
	game.box(panel,Vector3.ZERO,Vector3(.26,.34,.12),game.material(Color("263a43")))
	for i in range(3):
		var node=game.box(panel,Vector3(0,.11-i*.11,.08),Vector3(.16,.08,.06),game.material(Color("e8b46b")))
		buttons.append(control_entry(node,["advance","stop","return"][i],["Advance core to next support stop","Stop guided core","Return core to previous support stop"][i],.09))
	label=game.sign_panel(panel,"",Vector3(0,.43,0),Vector2(2.1,.55),30,.002)
	for entry in spec.bolts:
		var node=game._mesh(entry.source);game.runtime.node(spec.uid).add_child(node);node.transform=game.source[entry.source].transform
		game.box(node,Vector3(0,0,.012),Vector3(.019,.004,.003),game.material(Color("263a43")))
		bolt_nodes.append(node)
	for key in ["connection","isolation"]:
		connection_nodes[key]=game.box(game.runtime.node(spec.owner),AssemblyRuntime.vec(spec[key]),Vector3(.10,.10,.06),game.material(Color("e8b46b")))
	bridge=Node3D.new();add_child(bridge)
	var pieces: Array=spec.bridge.shapes
	for piece in pieces:
		game.box(bridge,AssemblyRuntime.vec(piece.at),AssemblyRuntime.vec(piece.size),game.material(Color("e8b46b")))
		var shape=BoxShape3D.new();shape.size=AssemblyRuntime.vec(piece.size)
		bridge_shapes.append({"shape":shape,"transform":Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(piece.at))})
	_pose()

func _crane() -> Node:return game.equipment.get_equipment("service_crane")
func _record(model: AssemblyModel=null) -> Dictionary:return (game.model if model==null else model).assemblies[spec.uid]
func load_pose(value: float=-1) -> Transform3D:
	return game.runtime.node(spec.owner).global_transform*Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(spec.seat)+Vector3.BACK*(spec.travel-(travel if value<0 else value)))
func has_point(point: String, state: Dictionary={}) -> bool:
	var crane=_crane()
	if state.is_empty():
		if crane==null or crane.uid!=spec.uid:return false
		state=crane.capture()
	return state.endpoints.values().any(func(end):return end.state=="attached" and end.point==point)
func retained(state: Dictionary={},_model: AssemblyModel=null) -> bool:return (bolts if state.is_empty() else state.bolts).all(func(value):return value)
func secured(state: Dictionary={},_model: AssemblyModel=null) -> bool:return retained(state) and (connected if state.is_empty() else state.connected)
func receiving_error(_uid: String="core") -> String:
	var supports=game.equipment.get_equipment("module_supports")
	if not supports.support_secured("chest"):return "Retain the chest on the secured, neutral-locked waist before core delivery."
	var pack=game.equipment.get_equipment("backpack_hinge")
	if pack!=null and pack.active:return "Initial core insertion and local correction require the backpack removed; the later full maintenance-guide workflow is not fitted."
	return "" if not moving else "Stop the guide before moving the crane."
func accept() -> String:
	var error=receiving_error()
	if not error.is_empty():return error
	if active:return "The core already occupies this guide approach."
	active=true;travel=0;goal=0;_pose();return ""
func departure_error() -> String:
	if moving:return "Stop the guided insertion before moving the crane."
	if is_zero_approx(travel) and has_point(spec.front_point) and has_point(spec.aft_point):return ""
	if is_equal_approx(travel,spec.travel) and retained() and _crane().attached_count()==0:return ""
	return "Use the guide control to return to the rear approach with both magnetic connectors, or retain and connect the seated core and stow the aft magnetic connector."
func depart() -> void:
	if is_zero_approx(travel):active=false

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for entry in buttons:
		var control=entry.duplicate();control.point=control.node.global_position;result.append(control)
	for i in range(4):result.append(control_entry(bolt_nodes[i],"bolt:"+str(i),("Release" if bolts[i] else "Secure")+" captive core flange bolt",.065,{"point":bolt_nodes[i].global_position}))
	for key in connection_nodes:result.append(control_entry(connection_nodes[key],key,"Connect core rear interlock" if key=="connection" else "Isolate core rear interface",.08,{"point":connection_nodes[key].global_position}))
	return result

func rig_error(action: String, point: String) -> String:
	if moving:return "Stop the guided core before handling magnetic connectors."
	if action=="detach":
		if point==spec.front_point:
			return "" if is_equal_approx(travel,spec.capture) and has_point(spec.aft_point) else "Keep the forward bridge attached until the guides capture 0.32 m of the core."
		return "" if secured() and is_equal_approx(travel,spec.travel) else "Keep aft crane support through all four captive bolts and the rear interlock."
	if point==spec.front_point and rig>0:return "Extend the forward magnetic connector at the captured stop before refitting it."
	if point==spec.front_point and travel>spec.capture+.0001:return "Return to the captured-guide stop before refitting the forward magnetic connector."
	return ""

func action_error(action: String) -> String:
	if game.paused:return "Resume before operating the core guide."
	if action=="stop":return "" if moving else "The core guide is stopped."
	if not active:return "Deliver the core to its rear approach with both magnetic connectors first."
	var receiving=receiving_error()
	if not receiving.is_empty():return receiving
	if moving:return "Stop the guide before changing its operation."
	var error=game.hands.error(equipment_id)
	if not error.is_empty():return error
	if action.begins_with("bolt:"):
		var index=action.get_slice(":",1).to_int()
		if index<0 or index>=4:return "Unknown captive bolt."
		if _record().parent!=spec.owner:return "Seat the core flange before operating its bolts."
		if bolts[index] and connected:return "Isolate the rear interface before releasing any captive bolt."
		if not has_point(spec.aft_point):return "Refit the aft magnetic connector before changing core retention."
		return ""
	if action in ["connection","isolation"]:
		if _record().parent!=spec.owner or not bolts.all(func(value):return value):return "Seat the core and secure all four captive bolts first."
		if action=="connection" and not has_point(spec.aft_point):return "Keep the aft magnetic connector attached through rear connection."
		return ""
	if action not in ["advance","return"]:return "Unknown core guide command."
	if connected or bolts.any(func(value):return value):return "Isolate the core and release all four captive bolts before guided movement."
	var crane=_crane()
	if crane.uid!=spec.uid or crane.task!="core" or crane.station!="receiver" or crane.raised or not crane.motion.is_empty():return "Lower the matching crane at the rear guide before operating insertion."
	if not has_point(spec.aft_point):return "Keep the aft magnetic connector attached during guided movement."
	if action=="advance":
		if is_equal_approx(travel,spec.travel):return "The core is seated."
		if travel<spec.capture-.0001 and not has_point(spec.front_point):return "Both magnetic connectors are required before guide capture."
		if travel>=spec.capture-.0001 and (has_point(spec.front_point) or not crane.hand_payload().is_empty()):return "Release and stow the forward magnetic connector before advancing beyond guide capture."
	else:
		if is_zero_approx(travel):return "The core is at its rear approach."
		if travel<=spec.capture+.0001 and rig==0 and not has_point(spec.front_point):return "Refit the forward magnetic connector before returning out of the captured guides."
	return receiving_error()

func request(action: String) -> String:
	var error=action_error(action)
	if not error.is_empty():return error
	if action=="stop":moving=false
	elif action.begins_with("bolt:"):
		var i=action.get_slice(":",1).to_int();bolts[i]=not bolts[i]
	elif action in ["connection","isolation"]:connected=action=="connection"
	else:
		if _record().parent==spec.owner:
			var previous=game.runtime.node(spec.uid).global_transform
			var result: Dictionary=game.model.undo_supported(spec.owner,spec.support)
			if not result.ok:return result.error
			game.runtime.node(spec.uid).reparent(game);game.runtime.node(spec.uid).global_transform=previous
			game.refresh_assembly_collision(spec.owner)
		if action=="return" and travel<=spec.capture+.0001 and rig==0 and _record().location=="support:"+spec.support:
			error=game.model.transfer_supported_assembly(spec.uid,spec.support,"crane_rigging")
			if not error.is_empty():return error
		goal=(spec.capture if travel<spec.capture-.0001 else spec.travel) if action=="advance" else (spec.capture if travel>spec.capture+.0001 else 0.0)
		if action=="advance" and travel>=spec.capture-.0001:rig_goal=1
		if action=="return" and is_equal_approx(travel,spec.capture) and rig>0:rig_goal=0;goal=travel
		moving=true
	blocked_reason="";_pose();return ""

func beam_pose(frame: Transform3D=Transform3D.IDENTITY, amount: float=-1) -> Transform3D:
	if frame==Transform3D.IDENTITY:frame=load_pose()
	if amount<0:amount=rig
	return Transform3D(Basis.IDENTITY,frame*AssemblyRuntime.vec(spec.rig.full_center).lerp(AssemblyRuntime.vec(spec.rig.aft_center),amount))
func rig_solids(frame: Transform3D, amount: float) -> Array[Dictionary]:
	var beam_frame=beam_pose(frame,amount)
	var beam_shape=BoxShape3D.new();beam_shape.size=AssemblyRuntime.vec(spec.rig.full_size).lerp(AssemblyRuntime.vec(spec.rig.aft_size),amount)
	var result: Array[Dictionary]=[{"shape":beam_shape,"world":beam_frame}]
	var pairs=[[beam_frame.origin,Vector3(beam_frame.origin.x,spec.rig.overhead_y,beam_frame.origin.z)]]
	for index in range(2):
		var point: String=spec.front_point if index==0 else spec.aft_point
		var anchor=beam_frame.origin+AssemblyRuntime.vec(spec.rig.full_anchors[index]).lerp(AssemblyRuntime.vec(spec.rig.aft_anchors[index]),amount)
		var contact=frame*AssemblyRuntime.vec(spec.rig.contacts[index])
		var endpoint=contact if has_point(point) else anchor-Vector3.UP*spec.rig.stow_drop
		pairs.append([anchor,endpoint])
		if index==0 and not has_point(point):
			var adapter=Transform3D(Basis.IDENTITY,endpoint-AssemblyRuntime.vec(spec.bridge.position))
			for entry in bridge_shapes:result.append({"shape":entry.shape,"world":adapter*entry.transform})
	for pair in pairs:
		var direction: Vector3=pair[1]-pair[0]
		var shape=BoxShape3D.new();shape.size=Vector3(.025,maxf(.001,direction.length()),.025)
		result.append({"shape":shape,"world":Transform3D(Basis(Quaternion(Vector3.UP,direction.normalized())),(pair[0]+pair[1])/2)})
	return result

func transport_shapes() -> Array[Dictionary]:return bridge_shapes if has_point(spec.front_point) else []
func motion_error(from: float,to: float) -> String:
	var shapes: Array[Dictionary]=[];var body=game.runtime.node(spec.uid)
	Sweep.collect_shapes(body,body.global_transform.affine_inverse(),shapes);shapes.append_array(transport_shapes())
	var ignored: Array[RID]=game.leg_layout.blockout.rids_for_groups(["crane_bridge"]);Sweep.collect_rids(body,ignored)
	return Sweep.sweep(get_world_3d().direct_space_state,[{"shapes":shapes,"margin":0.0001,"error":"Clear the guided core path ({collider})."},{"shapes_at":func(frame: Transform3D,_p: float)->Array:return rig_solids(frame,rig),"margin":.001,"error":"Clear the core rigging path ({collider})."}],maxi(1,ceili(absf(to-from)/.01)),func(p: float)->Transform3D:return load_pose(lerpf(from,to,p)),15,ignored,equipment_id).get("error","")

func physics(delta: float) -> void:
	if game.paused:return
	if moving:
		if not is_equal_approx(rig,rig_goal):
			var next_rig=move_toward(rig,rig_goal,delta*.5)
			var ignored: Array[RID]=game.leg_layout.blockout.rids_for_groups(["crane_bridge"]);Sweep.collect_rids(game.runtime.node(spec.uid),ignored)
			blocked_reason=Sweep.sweep(get_world_3d().direct_space_state,[{"shapes_at":func(frame: Transform3D,p: float)->Array:return rig_solids(frame,lerpf(rig,next_rig,p)),"margin":.001,"error":"Clear the folding core rig ({collider})."}],maxi(1,ceili(absf(next_rig-rig)*30)),func(_p: float)->Transform3D:return load_pose(),15,ignored,equipment_id).get("error","")
			if not blocked_reason.is_empty():moving=false;_pose();return
			rig=next_rig;moving=not is_equal_approx(rig,rig_goal) or not is_equal_approx(travel,goal);_pose();return
		var next=move_toward(travel,goal,delta*.30)
		blocked_reason=motion_error(travel,next)
		if not blocked_reason.is_empty():moving=false;_pose();return
		travel=next
		if is_equal_approx(travel,spec.capture) and _record().location=="support:crane_rigging":
			blocked_reason=game.model.transfer_supported_assembly(spec.uid,"crane_rigging",spec.support)
		if is_equal_approx(travel,spec.travel) and _record().parent.is_empty():
			game.runtime.node(spec.uid).global_transform=load_pose()
			var result: Dictionary=game.model.install_supported(spec.owner,spec.slot,spec.uid,spec.support)
			if result.ok:game.runtime.mount(spec.owner,spec.slot,spec.uid);game.refresh_assembly_collision(spec.owner)
			else:blocked_reason=result.error
		moving=not is_equal_approx(travel,goal) and blocked_reason.is_empty()
		_pose()
	refresh_rig()

func refresh_rig() -> void:
	var crane=_crane()
	bridge.visible=crane!=null and crane.uid==spec.uid
	if not bridge.visible:return
	var amount=rig if active and crane.task=="core" else 0.0
	crane.rig_bar.mesh.size=AssemblyRuntime.vec(spec.rig.full_size).lerp(AssemblyRuntime.vec(spec.rig.aft_size),amount)
	var end_id=""
	for id in crane.endpoints:
		if crane.endpoints[id].point==spec.front_point:end_id=id
	if not end_id.is_empty():bridge.global_transform=game.runtime.node(spec.uid).global_transform;return
	var forward_end: String=crane.config.spec.point_ends[spec.front_point]
	var held=crane.endpoints[forward_end].state=="held"
	bridge.global_transform=Transform3D(Basis.IDENTITY,crane.end_nodes[forward_end].global_position-AssemblyRuntime.vec(spec.bridge.handle if held else spec.bridge.position))

func _pose() -> void:
	if active and _record().parent.is_empty():
		var body: CollisionObject3D=game.runtime.node(spec.uid);body.global_transform=load_pose();body.force_update_transform()
		PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	for i in range(4):
		bolt_nodes[i].rotation.z=PI/2 if bolts[i] else 0
		bolt_nodes[i].material_override=game.material(Color("7cc7a7") if bolts[i] else Color("e8b46b"))
	label.text=status_text()
	if _crane()!=null:_crane()._refresh()
	refresh_rig()

func status_text() -> String:
	return "CORE GUIDE / "+("awaiting crane" if not active else "moving" if moving else "seated" if is_equal_approx(travel,spec.travel) else "captured stop" if is_equal_approx(travel,spec.capture) else "rear approach")+"\n"+(blocked_reason if not blocked_reason.is_empty() else "%d / 4 captive bolts · %s"%[bolts.count(true),"connected" if connected else "isolated"])
func undo(owner: String) -> Dictionary:
	if owner==spec.owner and not game.model.assemblies[owner].history.is_empty() and game.model.assemblies[owner].history.back().slot==spec.slot:return {"handled":true,"error":"Isolate and release captive bolts, then use Return at the supported core guide."}
	return {"handled":false,"error":""}
func capture() -> Dictionary:return {"version":1,"active":active,"rig":rig,"rig_goal":rig_goal,"travel":travel,"goal":goal,"moving":moving,"bolts":bolts.duplicate(),"connected":connected}

func validate_crane(crane: Dictionary, model: AssemblyModel, state: Dictionary={}) -> Array[String]:
	var data=capture() if state.is_empty() else state
	var forward=has_point(spec.front_point,crane);var aft=has_point(spec.aft_point,crane)
	if not data.active:return ["No guided core operation is active."]
	if data.travel<spec.capture-.0001 and (not forward or not aft):return ["Uncaptured core needs both crane ends."]
	if data.travel>=spec.capture-.0001 and not aft and not (is_equal_approx(data.travel,spec.travel) and retained(data)):return ["Core needs aft crane support through retention and connection."]
	if data.travel>spec.capture+.0001 and forward:return ["Forward bridge cannot remain inside the captured guide."]
	if data.rig>0 and forward:return ["Folded core rig cannot carry the forward bridge on the load."]
	if data.travel>spec.capture+.0001 and data.rig!=1:return ["Deep core insertion requires the folded aft rig."]
	if data.moving and crane.endpoints.values().any(func(end):return end.state=="held"):return ["Guided core movement has an unstowed crane end."]
	var expected="support:crane_rigging" if data.travel<spec.capture-.0001 else "support:"+spec.support
	if is_equal_approx(data.travel,spec.capture) and data.goal==0:expected="support:crane_rigging"
	if is_equal_approx(data.travel,spec.travel):expected="parent"
	if model.assemblies[spec.uid].location!=expected:return ["Core guide ownership disagrees with captured travel."]
	return []

func validate(data: Variant,candidate: AssemblyModel=null,world: Dictionary={}) -> Array[String]:
	if not Codec.same_keys(data,capture().keys()) or data.version!=1:return ["Invalid core guide state."]
	for key in ["active","moving","connected"]:
		if not data[key] is bool:return ["Invalid core guide flag."]
	for key in ["rig","rig_goal"]:
		if not Codec.number(data[key],1) or data[key]<0:return ["Invalid core rig progress."]
	if data.rig_goal!=0 and data.rig_goal!=1:return ["Invalid core rig stop."]
	if data.rig!=data.rig_goal and not is_equal_approx(data.travel,spec.capture):return ["Core rig adjustment requires the captured stop."]
	for key in ["travel","goal"]:
		if not Codec.number(data[key],spec.travel) or data[key]<0:return ["Invalid core guide travel."]
	if not data.bolts is Array or data.bolts.size()!=4 or not data.bolts.all(func(value):return value is bool):return ["Invalid captive core bolts."]
	if not [0.0,float(spec.capture),float(spec.travel)].any(func(value):return is_equal_approx(value,data.goal)):return ["Core guide skips its support stop."]
	if not data.active and (data.travel!=0 or data.rig!=0 or data.moving or data.connected or data.bolts.any(func(value):return value)):return ["Inactive core guide contains work."]
	if data.connected and not data.bolts.all(func(value):return value):return ["Core connection requires all four captive bolts."]
	if data.bolts.any(func(value):return value) and not is_equal_approx(data.travel,spec.travel):return ["Core bolts require flange seating."]
	var model: AssemblyModel=game.model if candidate==null else candidate
	if model.assemblies[spec.uid].location in ["parent","support:"+spec.support] and not data.active:return ["Installed or guided core has no active support state."]
	if data.active:
		if not model.milestone("pelvis","chest_secured"):return ["Guided core requires secured chest support."]
		if world.has("equipment"):
			var crane: Dictionary=world.equipment.service_crane
			if crane.task=="core" and crane.station=="receiver" and not crane.raised and crane.motion.is_empty():
				var errors=validate_crane(crane,model,data)
				if not errors.is_empty():return errors
			elif not is_equal_approx(data.travel,spec.travel) or not retained(data):return ["Unsecured guide operation lost its crane."]
		if world.has("fixtures") and model.assemblies[spec.uid].parent.is_empty():
			var parent_pose=Codec.to_pose(world.fixtures[spec.owner])
			var expected=parent_pose*Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(spec.seat)+Vector3.BACK*(spec.travel-data.travel))
			if not Codec.to_pose(world.fixtures[spec.uid]).is_equal_approx(expected):return ["Core pose disagrees with its guide travel."]
	return []

func apply(data: Dictionary) -> void:
	active=data.active;rig=data.rig;rig_goal=data.rig_goal;travel=data.travel;goal=data.goal;moving=data.moving;bolts.assign(data.bolts);connected=data.connected;blocked_reason="";_pose()
