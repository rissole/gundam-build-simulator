extends "res://scripts/equipment.gd"
## One indexed rail cradle, with resumable construction roll, both delivery
## lanes, passive parking and a separate empty-holder return. Model ownership
## changes only at a supported mount/unmount; moving equipment controls pose.
signal changed
const Sweep = preload("res://scripts/motion_sweep.gd")
const Codec = preload("res://scripts/pose_codec.gd")
const MANUAL_COMMANDS = ["next:bolster","next:index","next:travel","next:upright","next:dock","next:release","back:home","build"]
var layout: Node3D
var spec: Dictionary
var active_assembly = "left_leg"
var receiver = "pelvis"
var receiver_slot = "left_leg"
var support = "leg_holder"
var lane = "left"
var index_x: float = 14.0
var path: float = 0.0
var goal: float = 0.0
var roll: float = 0.0
var roll_height: float = 0.0
var bolster: float = 0.0
var release: float = 0.0
var engaged = true
var moving = false
var mode = ""
var blocked_reason = ""
var buttons: Array[Dictionary] = []
var labels: Array[Label3D] = []

func setup(workshop: Node3D, scene_layout: Node3D) -> void:
	game=workshop;layout=scene_layout;spec=layout.layout().workshop.rail;equipment_id="leg_rail"
	index_x=spec.station_x
	for point in spec.panels:_panel(AssemblyRuntime.vec(point))
	game.model.changed.connect(_model_changed)
	_pose()

func _panel(at: Vector3) -> void:
	var panel = Node3D.new();add_child(panel);panel.position=at
	var dark = game.material(Color("263a43"),.4)
	game.box(panel,Vector3(0,.6,0),Vector3(.12,1.2,.9),dark,true)
	for index in range(7):
		var action: String = ["advance","stop","return","lane","roll","park","build"][index]
		var caption: String = ["NEXT","STOP","BACK","LANE","ROLL","PARK","BUILD"][index]
		var button = preload("res://scripts/equipment_button.gd").make(game,panel,Vector3(-.09,1.15-(index/3)*.24,-.30+(index%3)*.30),caption,-PI/2,index == 0)
		buttons.append(control_entry(button,action,action,.11))
	labels.append(game.sign_panel(panel,"",Vector3(-.08,1.72,0),Vector2(1.3,.4),26,.0015,-PI/2))

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var other := "right" if active_assembly=="left_leg" else "left"
	for button in buttons:
		var entry: Dictionary=button.duplicate();entry.point=entry.node.global_position
		match str(entry.action):
			"advance":entry.label="Leg rig: Next — "+next_action()
			"return":entry.label="Leg rig: Back — return the leg rig"
			"stop":entry.label="Leg rig: Stop"
			"lane":entry.label="Leg rig: Lane — "+lane+" hip"
			"roll":entry.label="Leg rig: Roll"
			"park":entry.label="Leg rig: Park / retrieve"
			"build":entry.label="Leg rig: Build — select the "+other+" leg"
		result.append(entry)
	return result

func manual_commands() -> Array:return MANUAL_COMMANDS
func command_label(action: String, _task: String = "") -> String:
	if action.begins_with("next:"):return "Next"
	if action=="back:home":return "Back"
	if action=="build":return "Build"
	return ""
func manual_subject(_objective: Dictionary) -> String:return "Leg rig"
func manual_hint(objective: Dictionary) -> String:
	match str(objective.get("command","")):
		"next:bolster":return "stows the foot bolster"
		"next:index":return "indexes to the hip lane"
		"next:travel":return "travels to the Final Assembly Bay"
		"next:upright":return "turns the leg upright"
		"next:release":return "releases the leg"
		"back:home":return "repeat until the rig is home"
		"build":return "selects the right leg"
	return ""
## Arrival values only. A phase that is still moving keeps the previous stop,
## so the checklist does not tick the destination early. Release completion is
## `engaged` becoming false: that flip happens when the withdrawal arrives, and
## the same arrival forces path back to 2, so the path stop cannot represent it.
func manual_state() -> Dictionary:
	var stop := int(floorf(path+.0001))
	var lane_x := float(spec.lanes[lane])
	var station := float(spec.station_x)
	var stowed := is_equal_approx(bolster,1.0)
	if moving and mode=="bolster" and goal<1.0:stowed=true
	var on_lane := is_equal_approx(index_x,lane_x)
	if moving and mode=="index" and not is_equal_approx(float(goal),lane_x):on_lane=true
	return {"bolster":stowed,"indexed":on_lane,"stop":stop,"engaged":engaged,"home":stop==0 and is_equal_approx(index_x,station) and is_equal_approx(release,0.0),"active_assembly":active_assembly}
func manual_effect(objective: Dictionary) -> Dictionary:
	match str(objective.get("command","")):
		"next:bolster":return {"bolster":true}
		"next:index":return {"indexed":true}
		"next:travel":return {"stop":1}
		"next:upright":return {"stop":2}
		"next:dock":return {"stop":3}
		"next:release":return {"engaged":false}
		"back:home":return {"home":true}
		"build":return {"active_assembly":"right_leg","engaged":true}
	return {}

func can_construct() -> bool:
	return engaged and not moving and mode.is_empty() and path==0 and is_equal_approx(index_x,spec.station_x) and roll==0 and roll_height==0

func next_action() -> String:
	if not mode.is_empty():return "resume "+mode.replace("_"," ")
	if not engaged:return "reacquire the leg" if path>=2 else "move the empty rig toward the retained leg"
	if not is_equal_approx(index_x,spec.lanes[lane]):return "index to "+lane+" hip"
	if path>=3:return "release the secured leg"
	return ["travel to Final Assembly Bay","turn upright","dock upward"][clampi(floori(path),0,2)]

func retention_state(model: AssemblyModel = null, controls_state: Dictionary = {}, assembly: String = "") -> String:
	var m: AssemblyModel=game.model if model==null else model
	var selected=active_assembly if assembly.is_empty() else assembly
	var milestone: String=selected+"_secured"
	var required: Array=m.definitions.assemblies[m.assemblies[receiver].definition].milestones[milestone]
	var controls=game.equipment.get_equipment("captive_controls")
	if m.milestone(receiver,milestone) and controls!=null and controls.group_ready(selected+"_neutral",controls_state):return "complete"
	if required.any(func(sid):return sid!=selected and not m.assemblies[receiver].slots[sid].is_empty()):return "partial"
	return "none"

func action_error(action: String) -> String:
	if game.paused:return "Resume the workshop before moving the leg rig."
	if action=="stop":return "" if moving else "The leg rig is stopped."
	if action not in ["advance","return","lane","roll","park","build"]:return "Unknown leg rig command."
	if moving and blocked_reason.is_empty():return "Stop the leg rig before selecting another command."
	if not mode.is_empty() and action not in ["advance","return"]:return "Complete or reverse the interrupted motion first."
	var peer: String=game.equipment.busy_reason("rail",equipment_id)
	if not peer.is_empty():return peer
	if action=="build":
		if path!=0 or not is_equal_approx(index_x,spec.station_x) or roll!=0 or roll_height!=0 or release!=0:return "Return the empty leg rig to the Limb Bay before selecting another leg."
		var current: Dictionary=game.model.assemblies[active_assembly]
		if current.parent.is_empty() and current.slots.values().any(func(uid):return not uid.is_empty()):return "The leg rig is occupied. Finish this leg or park it for arm work; another leg cannot use the occupied leg rig."
		return ""
	# Advance resumes the stored phase; it is not a new delivery command.
	# In particular, an interrupted raised roll must remain resumable.
	if not mode.is_empty():
		if mode in ["roll","roll_raise"]:return game.equipment.busy_reason("source_roll",equipment_id)
		return ""
	if action in ["lane","roll","park"] and path!=0:return "Return the leg rig to the transverse table first."
	if action=="lane" and (roll!=0 or roll_height!=0):return "Restore neutral roll and construction height before indexing."
	if action=="roll":
		if not can_construct() and mode.is_empty() and (index_x!=spec.station_x or not engaged):return "Roll only with the leg rig occupied in the Limb Bay."
		var reason: String=game.equipment.busy_reason("source_roll",equipment_id)
		if not reason.is_empty():return reason
		if game.model.assemblies[active_assembly].slots.foot.is_empty():return "Transfer the prepared foot onto the leg rig first."
	if action in ["advance","park"] and engaged and path==0 and (roll!=0 or roll_height!=0):return "Return the supported source roll to neutral before indexing."
	if action=="return" and engaged and game.model.assemblies[active_assembly].parent==receiver and retention_state()!="none":return "Remove hip retention before returning the loaded leg."
	if action=="advance" and engaged:
		var gantry=game.equipment.get_equipment("module_supports")
		if gantry!=null and not gantry.support_secured():return "Deliver the pelvis, close all four gantry jaws and insert both waist lock pins before leg delivery."
		if lane!=active_assembly.trim_suffix("_leg"):return "Select the "+active_assembly.trim_suffix("_leg")+" hip lane for this leg."
		if not game.model.milestone(active_assembly,"structural_ready"):return "Complete the structural leg and every retaining connection before delivery."
		if path==3 and retention_state()!="complete":return "Complete hip retention and the cylinder lock pins before releasing the leg rig."
	return ""

func request(action: String) -> String:
	var error=action_error(action)
	if not error.is_empty():return error
	blocked_reason=""
	motion_obstruction = {}
	if action=="stop":moving=false;_refresh();return ""
	if action=="build":
		var current: Dictionary=game.model.assemblies[active_assembly]
		if current.parent.is_empty():
			error=game.model.transfer_supported_assembly(active_assembly,support,"leg_queue_"+active_assembly.trim_suffix("_leg"))
			if not error.is_empty():return error
		active_assembly="right_leg" if active_assembly=="left_leg" else "left_leg"
		receiver_slot=active_assembly;lane=active_assembly.trim_suffix("_leg")
		engaged=game.model.assemblies[active_assembly].parent.is_empty()
		if engaged:
			error=game.model.transfer_supported_assembly(active_assembly,"leg_queue_"+lane,support)
			if not error.is_empty():return error
		bolster=0;_pose();return ""
	if action=="lane":lane="right" if lane=="left" else "left";_refresh();return ""
	if not mode.is_empty():
		if action=="return":goal=_reverse_goal()
		if mode=="path":
			var gate_error: String=_request_route_access()
			if not gate_error.is_empty():blocked_reason=gate_error
			moving=true;_refresh();return ""
		moving=true;return ""
	if action=="roll":
		if roll_height<1:mode="roll_raise";goal=1
		else:mode="roll";goal=roll+90
	elif action=="return" and path==0 and (roll>0 or roll_height>0):
		mode="roll" if roll>0 else "roll_raise";goal=0
	elif action=="park":mode="index";goal=spec.station_x if is_equal_approx(index_x,spec.lanes.parking) else spec.lanes.parking
	elif not engaged:
		if action=="advance" and path>=2:path=3;mode="release";goal=0
		elif action=="advance":
			if not is_equal_approx(index_x,spec.lanes[lane]):mode="index";goal=spec.lanes[lane]
			elif release<5:mode="release";goal=5
			else:mode="path";goal=minf(3,floorf(path+.0001)+1)
		elif path>0:mode="path";goal=maxf(0,ceilf(path-.0001)-1)
		elif not is_equal_approx(index_x,spec.station_x):mode="index";goal=spec.station_x
		elif release>0:mode="release";goal=0
		else:return "The empty leg rig is home. Select the next supported build."
	elif action=="advance" and path==3:mode="release";goal=5
	elif action=="advance" and not is_equal_approx(index_x,spec.lanes[lane]):
		if bolster<1:mode="bolster";goal=1
		else:mode="index";goal=spec.lanes[lane]
	elif action=="return" and path==0:
		if not is_equal_approx(index_x,spec.station_x):mode="index";goal=spec.station_x
		elif bolster>0:mode="bolster";goal=0
		else:return "The leg rig is already in the Limb Bay."
	else:
		mode="path";goal=minf(3,floorf(path+.0001)+1) if action=="advance" else maxf(0,ceilf(path-.0001)-1)
		if path==3 and goal<3 and game.model.assemblies[active_assembly].parent==receiver:
			var previous: Transform3D=game.runtime.node(active_assembly).global_transform
			var result: Dictionary=game.model.undo_supported(receiver,support)
			if not result.ok:mode="";return result.error
			game.runtime.node(active_assembly).reparent(game);game.runtime.node(active_assembly).global_transform=previous
			game.refresh_assembly_collision(receiver);game.refresh_assembly_collision(active_assembly)
	if mode=="path":
		error=_request_route_access()
		if not error.is_empty():moving=true;blocked_reason=error;_refresh();return ""
	moving=true;_refresh();return ""

func _request_route_access() -> String:
	var error: String=game.equipment.get_equipment("rail_gates").request_closed(true)
	if not error.is_empty():return error
	if engaged and goal>path:
		var access=game.equipment.get_equipment("workshop_access")
		if not access.ready_for("leg"):return access.request_mode("leg")
	return ""

func _reverse_goal() -> float:
	match mode:
		"index":return spec.station_x
		"path":return maxf(0,ceilf(path-.0001)-1)
		"release","bolster","roll","roll_raise":return 0
	return goal

func snapshot_pose(state: Dictionary) -> Dictionary:
	var p: float=state.path;var angle=PI/2*(1-clampf(p-1,0,1))
	var z=lerpf(spec.home_z,spec.bay_z,clampf(p,0,1));var rise=spec.dock_rise*clampf(p-2,0,1)
	var x: float=state.index_x
	var lower=spec.delivery_lower*clampf((p-1)/spec.lower_during_turn,0,1)
	var root=Vector3(x,spec.base_y+spec.lying_lift*sin(angle)-lower+rise,z-spec.pivot*sin(angle))
	var basis=Basis(Vector3.RIGHT,angle)
	if p==0 and state.engaged:
		root.y=lerpf(spec.base_y+spec.lying_lift,spec.roll_axis_y,state.roll_height)
		basis*=Basis(Vector3.UP,deg_to_rad(state.roll))
	var release_value: float=state.release
	var opening=clampf(release_value,0,1);var compact=clampf(release_value-3,0,1)
	if not state.engaged or release_value>0:
		if p==3:
			root.y-=spec.holder.lower*clampf(release_value-1,0,1)
		else:
			var empty_y: float=spec.holder.empty_root_base+spec.holder.empty_root_lift*sin(angle)
			root.y=lerpf(root.y,empty_y,clampf(release_value,0,1))
		root+=basis*Vector3(0,0,spec.holder.withdrawal*clampf(release_value-2,0,1))
		root.x+=(spec.holder.outboard if state.lane=="right" else -spec.holder.outboard)*clampf(release_value-4,0,1)
	return {"frame":Transform3D(basis,root),"bogie_x":x,"bogie_z":z,"opening":opening,"compact":compact,"bolster":state.bolster}

func _motion_value(state: Dictionary) -> float:
	return state[{"path":"path","index":"index_x","release":"release","roll":"roll","roll_raise":"roll_height","bolster":"bolster"}[mode]]

func physics(delta: float) -> void:
	if not moving or game.paused:return
	motion_obstruction = {}
	if mode=="path":
		var gates=game.equipment.get_equipment("rail_gates")
		blocked_reason=gates.occupancy_error()
		if not blocked_reason.is_empty():_refresh();return
		if not gates.closed():
			if not gates.moving:
				blocked_reason=gates.request_closed(true);_refresh()
			return
	if mode=="path" and engaged and goal>path:
		var access=game.equipment.get_equipment("workshop_access")
		if not access.ready_for("leg"):
			if not access.moving:blocked_reason=access.request_mode("leg")
			return
	var before=capture();var next=before.duplicate(true)
	var field: String={"path":"path","index":"index_x","release":"release","roll":"roll","roll_raise":"roll_height","bolster":"bolster"}[mode]
	var speed: float={"path":.12,"index":.8,"release":.6,"roll":20.0,"roll_raise":.3,"bolster":.3}[mode]
	# Contact withdrawal and path turns change rules at integer boundaries.
	# Reach the boundary before reserving the next phase under its own exclusions.
	var phase_goal = goal
	if mode in ["path","release"]:
		phase_goal = minf(goal,floorf(before[field]+.00001)+1) if goal>before[field] else maxf(goal,ceilf(before[field]-.00001)-1)
	next[field]=move_toward(before[field],phase_goal,speed*delta)
	var ahead=before.duplicate(true)
	ahead[field]=EquipmentRegistry.Motion.ahead(before[field],phase_goal,next[field]-before[field],_travel_scale())
	blocked_reason=motion_error(before,ahead)
	if not blocked_reason.is_empty():_refresh();return
	set(field,next[field]);_pose()
	if is_equal_approx(next[field],goal):
		moving=false;var completed=mode;mode=""
		if completed=="release":engaged=release==0 and (path==3 or game.model.assemblies[active_assembly].parent.is_empty())
		# Withdrawal already lowered the empty head. There is no second empty
		# docking rise/lower; both route states share this same physical pose.
		if completed=="release" and release==5 and path==3:path=2
		if completed=="roll" and roll>=360:roll=0
		if completed=="path" and path==3 and engaged and game.model.assemblies[active_assembly].parent.is_empty():
			var result: Dictionary=game.model.install_supported(receiver,receiver_slot,active_assembly,support)
			if result.ok:game.runtime.mount(receiver,receiver_slot,active_assembly);game.refresh_assembly_collision(receiver)
			else:blocked_reason=result.error
			game.equipment.get_equipment("workshop_access").request_mode("work")
		if completed=="index" and not engaged and is_equal_approx(index_x,spec.station_x):
			# The fork must restore its settings clear of the mounted robot.
			mode="release";goal=0;moving=true
		if completed=="path" and path in [0.0,3.0]:game.equipment.get_equipment("rail_gates").request_closed(false)
		_pose()
	_refresh();changed.emit()

## Conservative surface metres per phase unit, including the long leg's rotation
## and the holder's articulated pieces. No whole-route occupancy reservation.
func _travel_scale() -> float:
	match mode:
		"index":return 1.0
		"roll":return deg_to_rad(1.0)*10.0
		"roll_raise":return absf(spec.roll_axis_y-spec.base_y-spec.lying_lift)
		"path":
			var segment=clampi(floori(path+.00001) if goal>path else ceili(path-.00001)-1,0,2)
			if segment==0:return absf(spec.home_z-spec.bay_z)
			if segment==2:return spec.dock_rise
			return PI/2*(10.0+spec.lying_lift+spec.pivot)+spec.delivery_lower/spec.lower_during_turn
		"release":return maxf(2.0,maxf(spec.holder.withdrawal,maxf(spec.holder.lower,spec.holder.outboard)))
	return maxf(absf(spec.holder.bolster.x[1]-spec.holder.bolster.x[0])/spec.holder.bolster.spread_fraction,spec.holder.bolster.lift/(1-spec.holder.bolster.spread_fraction))

func motion_error(from: Dictionary, to: Dictionary) -> String:
	var a=snapshot_pose(from);var b=snapshot_pose(to)
	var excluded: Array[RID]=layout.cradle.hardware.duplicate()
	var body: Node3D=game.runtime.node(active_assembly)
	var shapes: Array[Dictionary]=[]
	var carried: bool=game.model.assemblies[active_assembly].parent.is_empty() and from.engaged
	if carried:Sweep.collect_rids(body,excluded);Sweep.collect_shapes(body,body.global_transform.affine_inverse(),shapes)
	# Receiver support and a mated load are excluded only during their intentional
	# contact withdrawal. Empty travel continues to collide with the mounted leg.
	if from.release<3 and to.release<=3 and mode=="release":Sweep.collect_rids(body,excluded)
	var carrier=game.equipment.get_equipment("foot_carrier")
	if carrier!=null and path==0:excluded.append_array(carrier.hardware)
	var samples=Sweep.steps(a.frame,b.frame,10,.025)
	samples=maxi(samples,ceili(absf(to.release-from.release)*2/.025))
	var state_at=func(t: float) -> Dictionary:
		var state=from.duplicate(true)
		for field in ["path","index_x","release","roll","roll_height","bolster"]:state[field]=lerpf(from[field],to[field],t)
		return snapshot_pose(state)
	var rig=func(_frame: Transform3D,t: float) -> Array:
		var at: Dictionary=state_at.call(t);var result: Array=[]
		for record in layout.cradle.geometry(at.frame,at.bogie_x,at.bogie_z,at.opening,at.compact,at.bolster):
			var shape=BoxShape3D.new();shape.size=record.size
			result.append({"shape":shape,"world":record.pose,"margin":-.003})
		return result
	var groups=[{"shapes":shapes,"margin":.001},{"shapes_at":rig}]
	return EquipmentRegistry.Motion.sweep(self,groups,samples,func(t):return state_at.call(t).frame,excluded).get("error","")

func _pose() -> void:
	var at=snapshot_pose(capture())
	var body: Node3D=game.runtime.node(active_assembly)
	if game.model.assemblies[active_assembly].location=="support:"+support:body.global_transform=at.frame
	layout.cradle.apply_geometry(layout.cradle.geometry(at.frame,at.bogie_x,at.bogie_z,at.opening,at.compact,at.bolster))
	for id in game.runtime.descendants(active_assembly):
		var node: CollisionObject3D=game.runtime.node(id)
		if node is AnimatableBody3D:PhysicsServer3D.body_set_mode(node.get_rid(),PhysicsServer3D.BODY_MODE_STATIC)
		node.force_update_transform();PhysicsServer3D.body_set_state(node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,node.global_transform)
	_refresh()

func _refresh() -> void:
	if path==0 and is_equal_approx(index_x,spec.lanes.parking) and not moving and mode.is_empty():game.zones.release("limb_station",equipment_id)
	else:game.zones.claim("limb_station",equipment_id)
	for label in labels:label.text=status_text()

func _model_changed() -> void:_refresh()

func status_text() -> String:
	if not blocked_reason.is_empty():return blocked_reason
	return "LEG RIG / "+active_assembly.replace("_"," ").to_upper()+" · "+lane+" lane\n"+(mode.replace("_"," ") if moving else next_action())

func busy_reason(subject: String) -> String:
	if subject in ["mobile_platform","foot_transfer",active_assembly,"rail","crane"] and (moving or not mode.is_empty()):return "Wait for the leg rig to finish and lock."
	return ""

func access_error(owner: String) -> String:
	if owner in [active_assembly,receiver] and (moving or not mode.is_empty()):return "Wait for the leg rig to lock."
	if owner==active_assembly and path==0 and not is_equal_approx(index_x,spec.station_x):return "Return the leg to the Limb Bay for construction."
	return ""

func undo(owner: String) -> Dictionary:
	if owner==receiver and not game.model.assemblies[owner].history.is_empty():
		var sid: String=game.model.assemblies[owner].history.back().slot
		for build in ["left_leg","right_leg"]:
			if sid in game.runtime.definition(receiver).milestones[build+"_secured"] and (active_assembly!=build or not engaged or release>0 or path!=3):return {"handled":true,"error":"Reacquire the matching leg with the leg rig before removing its retention."}
	return {"handled":false,"error":""}

func capture() -> Dictionary:
	return {"version":1,"assembly":active_assembly,"receiver":receiver,"slot":receiver_slot,"lane":lane,"index_x":index_x,"path":path,"roll":roll,"roll_height":roll_height,"bolster":bolster,"release":release,"engaged":engaged,"mode":mode,"goal":goal,"moving":moving}

func validate(data: Variant, candidate: AssemblyModel = null, world: Dictionary = {}) -> Array[String]:
	if not Codec.same_keys(data,capture().keys()) or data.version!=1:return ["Invalid leg rig snapshot."]
	var model: AssemblyModel=game.model if candidate==null else candidate
	if data.assembly not in ["left_leg","right_leg"] or data.receiver!=receiver or data.slot!=data.assembly or data.lane not in ["left","right"]:return ["Unknown leg rig destination or load."]
	if not data.moving is bool or not data.engaged is bool or data.mode not in ["","path","index","release","roll","roll_raise","bolster"]:return ["Invalid leg rig phase."]
	for field in ["index_x","path","roll","roll_height","bolster","release","goal"]:
		if not Codec.number(data[field],360):return ["Invalid leg rig progress."]
	if data.index_x<float(spec.lanes.values().min()) or data.index_x>float(spec.lanes.values().max()) or data.path<0 or data.path>3 or data.roll<0 or data.roll>360 or data.release<0 or data.release>5:return ["Holder progress exceeds the authored route."]
	for field in ["roll_height","bolster"]:
		if data[field]<0 or data[field]>1:return ["Holder construction phase out of range."]
	if data.moving and data.mode.is_empty():return ["Holder motion has no phase."]
	var goals={"path":[0,1,2,3],"index":[spec.station_x,spec.lanes.left,spec.lanes.right,spec.lanes.parking],"release":[0,5],"roll":[0,90,180,270,360],"roll_raise":[0,1],"bolster":[0,1]}
	if not data.mode.is_empty() and not goals[data.mode].any(func(stop):return is_equal_approx(float(stop),float(data.goal))):return ["Holder goal is not a configured stop."]
	if data.mode=="path" and absf(data.goal-data.path)>1.001:return ["Holder phase skips an intermediate lock."]
	if data.mode in ["roll","roll_raise","bolster","index"] and data.path!=0:return ["Construction motion requires the transverse table."]
	if data.path==0 and (data.roll!=0 or data.roll_height!=0) and not is_equal_approx(data.index_x,spec.station_x):return ["Source roll is only supported in the Limb Bay."]
	if data.roll!=0 and data.roll_height!=1:return ["Raise the supported roll axis before rotation."]
	if data.mode!="roll" and not spec.roll_stops.any(func(stop):return is_equal_approx(float(stop),float(data.roll))):return ["Source roll has no locked orientation."]
	for phase in ["path","roll_height","bolster","release"]:
		var phase_mode: String="roll_raise" if phase=="roll_height" else phase
		if data.mode!=phase_mode and not is_equal_approx(data[phase],roundf(data[phase])):return ["Interrupted leg rig motion lost its phase."]
	if data.mode!="index" and not goals.index.any(func(stop):return is_equal_approx(float(stop),float(data.index_x))):return ["Transverse table has no locked lane."]
	var load: Dictionary=model.assemblies[data.assembly]
	var occupant: String=model.support_occupant(support)
	if not occupant.is_empty() and occupant!=data.assembly:return ["The leg rig carries a different selected leg."]
	for owner in ["left_leg","right_leg"]:
		var queued: Dictionary=model.assemblies[owner]
		if queued.location.begins_with("support:leg_queue_") and queued.slots.values().any(func(value):return not value.is_empty()):return ["A leg with physical construction cannot wait in the empty-build queue."]
	if (data.path>0 or data.mode=="path") and data.lane!=data.assembly.trim_suffix("_leg"):return ["Leg delivery requires its matching hip lane."]
	if load.parent.is_empty():
		if load.location!="support:"+support or not data.engaged or data.release!=0:return ["Uninstalled leg has no engaged leg rig."]
	elif load.parent!=receiver or load.parent_slot!=data.slot:return ["Holder load is mounted elsewhere."]
	elif data.engaged and (data.path!=3 or data.mode not in ["","release"]):return ["Mounted leg contact is only available at its dock."]
	if (not data.engaged or data.release>0) and retention_state(model,world.get("equipment",{}).get("captive_controls",{}),data.assembly)!="complete":return ["Leg rig release requires full hip retention and lock pins."]
	if (data.path>0 or data.mode=="path") and not model.milestone(data.assembly,"structural_ready"):return ["Incomplete leg cannot leave the construction table."]
	if data.path>0 and (data.roll!=0 or data.roll_height!=0 or not is_equal_approx(data.index_x,spec.lanes[data.lane])):return ["Longitudinal travel requires neutral roll and a pinned hip lane."]
	if world.has("equipment") and data.mode=="path" and world.equipment.rail_gates.goal!=1:return ["Rail travel requires a closed ground crossing request."]
	if (data.path>0 or data.mode=="path") and data.engaged and data.bolster!=1:return ["Stow the foot bolster before transport."]
	if world.has("fixtures") and load.parent.is_empty() and not Codec.to_pose(world.fixtures[data.assembly]).is_equal_approx(snapshot_pose(data).frame):return ["Leg pose disagrees with its leg rig."]
	return []

func apply(data: Dictionary) -> void:
	motion_obstruction = {}
	active_assembly=data.assembly;receiver=data.receiver;receiver_slot=data.slot;lane=data.lane
	for field in ["index_x","path","roll","roll_height","bolster","release","engaged","mode","goal","moving"]:set(field,data[field])
	blocked_reason="";_pose()
