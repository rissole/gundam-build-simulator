extends "res://scripts/equipment.gd"
## The leg rig, operated mechanism by mechanism. Each control moves exactly one
## mechanism and sits beside it: drag the foot support, a turnover box at the head
## end of the table, a transfer table lever, one bogie box (travel, leg rise,
## next leg) and a clamp switch on the bogie. Controls refuse, naming the other
## mechanism and where its control is; they never operate another machine.
## Model ownership changes only at a supported mount/unmount.
signal changed
const Sweep = preload("res://scripts/motion_sweep.gd")
const Codec = preload("res://scripts/pose_codec.gd")
const EquipmentButton = preload("res://scripts/equipment_button.gd")
const RigTarget = preload("res://scripts/rig_target.gd")
const SAVE_SHAPE = 3
## Initial constant rates (per second), derived from the former phase speeds.
const TRAVEL_SPEED = 1.38
const TILT_SPEED = 10.8
const RISE_SPEED = .144
const LIFT_SPEED = .375
const ROLL_SPEED = 20.0
const SUPPORT_SPEED = .3
const TABLE_SPEED = .8
const RELEASE_SPEED = .6
const LEVER_ANGLE = 28.0
const HOLDS = ["travel+","travel-","rise+","rise-","lift+","lift-","roll+","roll-"]
const DRAGS = ["support","lever"]
const TAPS = ["clamps","next_leg"]
const FIELDS = ["index_x","travel_z","tilt_deg","rise_m","roll_deg","roll_height_m","foot_support","release"]
const MANUAL_COMMANDS = ["support:away","table:hip","travel:bay","rise","clamps:release","lower","travel:home","table:build","clamps:grab","next_leg","table:park"]
## Exact mechanical stops only.
const EPS = .0005
const GREEN = Color("73d995")
const RED = Color("e2735f")
var layout: Node3D
var spec: Dictionary
var active_assembly = "left_leg"
var receiver = "pelvis"
var receiver_slot = "left_leg"
var support = "leg_holder"
var lane = "left"
var index_x: float = 14.0
var travel_z: float = 14.5
var tilt_deg: float = 0.0
var rise_m: float = 0.0
var roll_deg: float = 0.0
var roll_height_m: float = 0.0
## 0 under the foot, 1 pulled clear along the side bands.
var foot_support: float = 0.0
## Clamp linkage, 0 gripping to 5 released: open, drop, pull back, fold, slide clear.
var release: float = 0.0
var engaged = true
## Transient input and motion; never saved.
var jog = ""
var jog_done = false
var drag: Dictionary = {}
var support_goal: float = -1.0
var table_goal: float = -1.0
var service_goal: float = -1.0
var lever_angle: float = 0.0
var moving = false
var blocked_reason = ""
var buttons: Array[Dictionary] = []
var labels: Array[Label3D] = []
var lamps: Dictionary = {}
var lever_pivot: Node3D
var clamp_switch: Node3D
var ghost: Node3D
var load_geometry = Sweep.RigidGeometry.new()

func save_version() -> int:return SAVE_SHAPE

func setup(workshop: Node3D, scene_layout: Node3D) -> void:
	game=workshop;layout=scene_layout;spec=layout.layout().workshop.rail;equipment_id="leg_rail"
	index_x=spec.station_x;travel_z=spec.home_z
	build_controls()
	ghost=RigTarget.new(game.runtime);game.add_child(ghost)
	game.model.changed.connect(_model_changed)
	_pose()

## Physical controls, each beside its mechanism (layout `rail.controls`).
func build_controls() -> void:
	var at: Dictionary=spec.controls
	var bogie=_box(AssemblyRuntime.vec(at.bogie_box),0.0,"BOGIE · LEG LIFT","bogie")
	_key(bogie,"travel-","TO TABLE",Vector3(-.09,1.2,.12))
	_key(bogie,"travel+","TO BAY",Vector3(-.09,1.2,.42))
	_key(bogie,"rise+","RISE",Vector3(-.09,.95,.27))
	_key(bogie,"rise-","LOWER",Vector3(-.09,.72,.27))
	_key(bogie,"next_leg","NEXT LEG",Vector3(-.09,.45,.27))
	var turnover=_box(AssemblyRuntime.vec(at.turnover_box),PI,"TURNOVER","turnover")
	_key(turnover,"lift+","RAISE",Vector3(-.09,1.15,.15))
	_key(turnover,"lift-","LOWER",Vector3(-.09,.92,.15))
	_key(turnover,"roll+","ROLL ↻",Vector3(-.09,1.15,.45))
	_key(turnover,"roll-","ROLL ↺",Vector3(-.09,.92,.45))
	_lever(AssemblyRuntime.vec(at.lever))
	clamp_switch=Node3D.new();add_child(clamp_switch)
	var dark=game.material(Color("263a43"),.4)
	game.box(clamp_switch,Vector3(0,.45,0),Vector3(.1,.9,.1),dark)
	var key=EquipmentButton.make(game,clamp_switch,Vector3(-.07,.95,0),"LEG CLAMPS",-PI/2,true)
	buttons.append(control_entry(key,"clamps","clamps",.14))
	for side in [-1,1]:
		var piece: Dictionary=layout.cradle.pieces["BolsterPad_"+str(side)]
		EquipmentButton.set_hold_handler(piece.visual,_hold.bind("support"))
		# The pad and its link are the control's own solids: a sightline that
		# reaches either sees the foot support.
		var own: Array=[piece.body,layout.cradle.pieces["BolsterLink_"+str(side)].body]
		buttons.append(control_entry(piece.visual,"support","support",.3,{"side":side,"allowed":own,"allow_body_hit":true,"sight_self":true}))

## A control box whose face points along local −X; `yaw` turns the whole box.
func _box(at: Vector3, yaw: float, title: String, id: String) -> Node3D:
	var panel=Node3D.new();add_child(panel);panel.position=at;panel.rotation.y=yaw
	game.box(panel,Vector3(0,.7,0),Vector3(.12,1.4,1.2),game.material(Color("263a43"),.4),true)
	labels.append(game.sign_panel(panel,title,Vector3(-.08,1.62,0),Vector2(1.2,.26),26,.0015,-PI/2))
	lamps[id]=[]
	for row in range(10):
		var lamp=Label3D.new();panel.add_child(lamp);lamp.position=Vector3(-.08,1.28-row*.085,-.55)
		lamp.rotation.y=-PI/2;lamp.font_size=20;lamp.pixel_size=.0013;lamp.outline_size=0
		lamp.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT;lamps[id].append(lamp)
	return panel

func _key(panel: Node3D, action: String, caption: String, at: Vector3) -> void:
	var key=EquipmentButton.make(game,panel,at,caption,-PI/2,action=="rise+")
	if action in HOLDS:EquipmentButton.set_hold_handler(key,_hold.bind(action))
	buttons.append(control_entry(key,action,action,.11))

## A floor lever thrown parallel to the table's travel, with one notch per
## destination named on its quadrant plate.
func _lever(at: Vector3) -> void:
	var base=Node3D.new();add_child(base);base.position=at
	var dark=game.material(Color("263a43"),.4)
	game.box(base,Vector3(0,.08,0),Vector3(1.1,.16,.3),dark,true)
	lever_pivot=Node3D.new();base.add_child(lever_pivot);lever_pivot.position=Vector3(0,.16,0)
	game.box(lever_pivot,Vector3(0,.5,0),Vector3(.06,1.0,.06),game.material(Color("8a9aa1"),.6))
	var knob=game.box(lever_pivot,Vector3(0,1.02,0),Vector3(.14,.14,.14),game.material(Color("e8b46b"),.3))
	EquipmentButton.set_hold_handler(knob,_hold.bind("lever"))
	buttons.append(control_entry(knob,"lever","lever",.2))
	labels.append(game.sign_panel(base,"TRANSFER TABLE",Vector3(0,.45,.2),Vector2(1.0,.2),24,.0015,PI))
	for notch in notches():
		var plate=Label3D.new();base.add_child(plate);plate.text=notch.name;plate.font_size=18;plate.pixel_size=.0013
		plate.rotation.y=PI;plate.position=Vector3(sin(deg_to_rad(notch.angle))*.55,.2,.16);plate.outline_size=0
	lamps["lever"]=[]
	for row in range(4):
		var lamp=Label3D.new();base.add_child(lamp);lamp.position=Vector3(.5,.35-row*.07,.16)
		lamp.rotation.y=PI;lamp.font_size=16;lamp.pixel_size=.0013;lamp.outline_size=0
		lamp.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT;lamps.lever.append(lamp)

## Lever notches in table order: their X is where the table stops.
func notches() -> Array:
	return [{"name":"LEFT HIP","x":float(spec.lanes.left),"angle":-LEVER_ANGLE},
		{"name":"RIGHT HIP · BUILD","x":float(spec.station_x),"angle":0.0},
		{"name":"PARK","x":float(spec.lanes.parking),"angle":LEVER_ANGLE}]

func _notch_for(x: float) -> Dictionary:
	var best: Dictionary={}
	for notch in notches():
		if best.is_empty() or absf(notch.x-x)<absf(best.x-x):best=notch
	return best

func _hold(held: bool, _delta: float, action: String) -> void:
	if action in DRAGS:
		if held:_drag_tick(action)
		else:_drag_end()
	else:set_jog(action if held else "")

## The one held arrow. Automation drives the same input as Hold E.
func set_jog(action: String) -> void:
	if action==jog:return
	jog=action;jog_done=false;blocked_reason="";motion_obstruction={}
	if action.is_empty():_settle_roll()
	else:load_geometry.invalidate()
	_sync_moving();_refresh()

## Reached a stop or detent with nothing waiting. Release E to continue.
func jog_settled() -> bool:return not jog.is_empty() and jog_done and blocked_reason.is_empty()

func _sync_moving() -> void:
	moving=not jog.is_empty() or not drag.is_empty() or support_goal>=0 or table_goal>=0 or service_goal>=0

## Hand point: where the grabbed point sits in front of the camera while E is held.
func _hand() -> Variant:
	var camera=game.get("camera")
	if not is_instance_valid(camera):return null
	return camera.global_position-camera.global_transform.basis.z*float(drag.get("distance",1.5))

func _drag_tick(action: String) -> void:
	if drag.is_empty():
		var error=action_error(action)
		if not error.is_empty():blocked_reason=error;_refresh();return
		var camera=game.get("camera")
		var pad: String=_aimed_pad(camera) if action=="support" else ""
		var grabbed: Vector3=layout.cradle.pieces[pad].visual.global_position if action=="support" else lever_pivot.global_transform*Vector3(0,1.02,0)
		drag={"kind":action,"pad":pad,"distance":camera.global_position.distance_to(grabbed) if is_instance_valid(camera) else 1.5}
		_sync_moving()
	var hand=_hand()
	if hand==null:return
	if action=="support":pull_support(_support_param(hand,drag.pad))
	else:
		var pivot: Vector3=lever_pivot.global_position
		lever_angle=clampf(rad_to_deg(atan2(hand.x-pivot.x,maxf(.05,hand.y-pivot.y))),-LEVER_ANGLE,LEVER_ANGLE)
		_refresh()

func _drag_end() -> void:
	var kind: String=drag.get("kind","")
	drag={}
	if kind=="support":support_goal=-1.0
	_sync_moving()
	# Releasing the lever leaves it in the nearest notch and starts the table.
	if kind=="lever":throw_lever(_nearest_notch_angle().x)
	_refresh()

func _nearest_notch_angle() -> Dictionary:
	var best: Dictionary={}
	for notch in notches():
		if best.is_empty() or absf(notch.angle-lever_angle)<absf(best.angle-lever_angle):best=notch
	return best

## The foot support pad nearest the camera's line of sight: either pad drags.
func _aimed_pad(camera) -> String:
	if not is_instance_valid(camera):return "BolsterPad_1"
	var best: String="";var best_d=INF
	for side in [-1,1]:
		var id: String="BolsterPad_"+str(side)
		var offset: Vector3=layout.cradle.pieces[id].visual.global_position-camera.global_position
		var d: float=offset.cross(-camera.global_basis.z).length()
		if d<best_d:best_d=d;best=id
	return best

## Foot support stroke nearest the hand, along the grabbed pad's spread-then-slide path.
func _support_param(hand: Vector3, pad: String = "BolsterPad_1") -> float:
	var fraction: float=spec.holder.bolster.spread_fraction
	var points: Array=[]
	for t in [0.0,fraction,1.0]:
		var state=_state();state.foot_support=t
		var at=snapshot_pose(state)
		for record in layout.cradle.geometry(at.frame,at.bogie_x,at.bogie_z,at.opening,at.compact,t):
			if record.id==pad:points.append(record.pose.origin)
	var best_t=foot_support;var best_d=INF
	for segment in 2:
		var a: Vector3=points[segment];var b: Vector3=points[segment+1]
		var u=clampf((hand-a).dot(b-a)/maxf(.0001,(b-a).length_squared()),0,1)
		var d=hand.distance_to(a.lerp(b,u))
		if d<best_d:best_d=d;best_t=lerpf([0.0,fraction][segment],[fraction,1.0][segment],u)
	return best_t

## The foot support follows a requested stroke, at most SUPPORT_SPEED per second.
func pull_support(goal: float) -> String:
	var error=action_error("support") if drag.is_empty() else ""
	if not error.is_empty():return error
	support_goal=clampf(goal,0,1);_sync_moving()
	return ""

## Selects a notch; the table drives there and stops. A locked lever refuses.
func throw_lever(x: float) -> String:
	var error=action_error("lever") if drag.is_empty() else ""
	if not error.is_empty():lever_angle=_notch_for(index_x).angle;_refresh();return error
	var notch=_notch_for(x);lever_angle=notch.angle
	table_goal=-1.0 if absf(notch.x-index_x)<=EPS else notch.x
	_sync_moving();_refresh()
	return ""

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var other := "right" if active_assembly=="left_leg" else "left"
	for button in buttons:
		var entry: Dictionary=button.duplicate();entry.point=entry.node.global_position
		entry.label={"travel+":"Bogie: travel to the bay","travel-":"Bogie: travel to the table","rise+":"Leg: rise into the hip","rise-":"Leg: lower","next_leg":"Next leg: load the "+other+" leg",
			"lift+":"Turnover: raise","lift-":"Turnover: lower","roll+":"Turnover: roll ↻","roll-":"Turnover: roll ↺","lever":"Transfer table lever",
			"clamps":"Leg clamps: "+("grab" if release>=2.5 else "release"),"support":"Foot support: "+("push under the foot" if foot_support>=.5 else "pull away from the foot")}[str(entry.action)]
		result.append(entry)
	return result

## The manual's gold glow marks small on-rig controls only (foot support, clamp
## switch); the transfer table lever and control box buttons never glow.
func manual_control_actions(objective: Dictionary) -> Array:
	return {"support:away":["support"],"clamps:release":["clamps"],"clamps:grab":["clamps"]}.get(str(objective.get("command","")),[])

func manual_commands() -> Array:return MANUAL_COMMANDS
func command_label(action: String, _task: String = "") -> String:
	var side: String=active_assembly.trim_suffix("_leg").to_upper()
	return {"support:away":"look at it, hold E and pull it away from the foot","table:hip":"pull it to "+side+" HIP","travel:bay":"hold TO BAY","rise":"hold RISE","clamps:release":"tap RELEASE",
		"lower":"hold LOWER","travel:home":"hold TO TABLE","table:build":"pull it to RIGHT HIP · BUILD","clamps:grab":"tap GRAB","next_leg":"tap NEXT LEG","table:park":"pull it to PARK"}.get(action,"")
func manual_subject(objective: Dictionary) -> String:
	return {"support:away":"Foot support","table:hip":"Transfer table lever","table:build":"Transfer table lever","table:park":"Transfer table lever","clamps:release":"Leg clamps switch","clamps:grab":"Leg clamps switch"}.get(str(objective.get("command","")),"Bogie box")
func manual_hint(objective: Dictionary) -> String:
	return {"support:away":"until it stops","travel:bay":"until the bogie stops at the bay","rise":"until it seats in the hip","clamps:release":"after hip retention and both lock pins",
		"lower":"until the empty holder lies flat","travel:home":"until the bogie stops on the table","clamps:grab":"to extend the empty holder"}.get(str(objective.get("command","")),"")
## Arrival evidence from coordinates and model ownership only.
func manual_state() -> Dictionary:
	var load: Dictionary=game.model.assemblies.get(active_assembly,{})
	var mounted: bool=load.get("parent","")==receiver and load.get("parent_slot","")==receiver_slot
	return {"active_assembly":active_assembly,"engaged":engaged,"support_away":foot_support>=1-EPS,
		"at_hip":absf(index_x-_lane_x())<=EPS,"at_bay":absf(travel_z-float(spec.bay_z))<=EPS,
		"seated":mounted and _at_dock(),"lying":tilt_deg<=EPS,"on_table":on_table(),"at_station":at_station(),"home":at_home(),"parked":parked()}
func _parking_x() -> float:
	var lanes = spec.get("lanes",{})
	return float(lanes.get("parking",spec.get("station_x",index_x))) if lanes is Dictionary else float(spec.get("station_x",index_x))
func manual_effect(objective: Dictionary) -> Dictionary:
	return {"support:away":{"support_away":true},"table:hip":{"at_hip":true},"travel:bay":{"at_bay":true},"rise":{"seated":true},"clamps:release":{"engaged":false},
		"lower":{"lying":true},"travel:home":{"on_table":true},"table:build":{"at_station":true},"clamps:grab":{"home":true},
		"next_leg":{"active_assembly":"right_leg","engaged":true},"table:park":{"parked":true}}.get(str(objective.get("command","")),{})

## Peer queries. Each accepts a capture()-shaped snapshot, defaulting to live state.
func on_table(state: Dictionary = {}) -> bool:
	var s: Dictionary=capture() if state.is_empty() else state
	return absf(float(s.travel_z)-float(spec.home_z))<=EPS and float(s.tilt_deg)<=EPS and float(s.rise_m)<=EPS
func at_station(state: Dictionary = {}) -> bool:
	var s: Dictionary=capture() if state.is_empty() else state
	return on_table(s) and absf(float(s.index_x)-float(spec.station_x))<=EPS
func parked(state: Dictionary = {}) -> bool:
	var s: Dictionary=capture() if state.is_empty() else state
	return on_table(s) and absf(float(s.index_x)-_parking_x())<=EPS
func at_home() -> bool:
	return not moving and at_station() and release==0 and roll_deg==0 and roll_height_m==0
func can_construct() -> bool:
	return engaged and at_home()
func supports_seated(assembly: String) -> bool:
	return active_assembly==assembly and engaged and release==0 and not moving and _at_dock()
func supports_construction(assembly: String) -> bool:
	return active_assembly==assembly and can_construct() and foot_support==0
## A leg still on the rig and tilted up stands inside the lower front's swing.
func gantry_occupant(front: String) -> String:
	return "leg on the leg rig" if front=="lower" and _carrying() and tilt_deg>EPS else ""

func _lane_x() -> float:return float(spec.lanes[lane])
func _at_dock(any_rise: bool = false, state: Dictionary = {}) -> bool:
	var s: Dictionary=_state() if state.is_empty() else state
	var docked=absf(float(s.index_x)-float(spec.lanes[s.lane]))<=EPS and absf(float(s.travel_z)-float(spec.bay_z))<=EPS and absf(float(s.tilt_deg)-90)<=EPS
	return docked and (any_rise or absf(float(s.rise_m)-float(spec.dock_rise))<=EPS)
func _lift_max() -> float:return float(spec.roll_axis_y)-float(spec.base_y)-float(spec.lying_lift)
func _carrying() -> bool:return engaged and game.model.assemblies[active_assembly].parent.is_empty()
func _mounted() -> bool:
	var load: Dictionary=game.model.assemblies[active_assembly]
	return load.parent==receiver and load.parent_slot==receiver_slot

func retention_state(model: AssemblyModel = null, controls_state: Dictionary = {}, assembly: String = "") -> String:
	var m: AssemblyModel=game.model if model==null else model
	var selected=active_assembly if assembly.is_empty() else assembly
	var milestone: String=selected+"_secured"
	var required: Array=m.definitions.assemblies[m.assemblies[receiver].definition].milestones[milestone]
	var controls=game.equipment.get_equipment("captive_controls")
	if m.milestone(receiver,milestone) and controls!=null and controls.group_ready(selected+"_neutral",controls_state):return "complete"
	if required.any(func(sid):return sid!=selected and not m.assemblies[receiver].slots[sid].is_empty()):return "partial"
	return "none"

## One condition another mechanism must meet: a lamp label, its state, and the
## refusal naming that mechanism and where its control is.
func _need(label: String, ok: bool, refusal: String) -> Dictionary:return {"label":label,"ok":ok,"refusal":refusal}

func _needs(action: String) -> Array:
	var carrying=_carrying();var side: String=active_assembly.trim_suffix("_leg")
	var braces=game.equipment.get_equipment("joint_restraints")
	var brace_error: String=braces.required_error(active_assembly) if braces!=null and carrying else ""
	var access=game.equipment.get_equipment("workshop_access")
	var front_open: bool=access==null or access.front_open("lower")
	var gantry=game.equipment.get_equipment("module_supports")
	var at_build=_need("AT BUILD POSITION",carrying and at_station(),"Bring the leg to the build position first: transfer table lever to RIGHT HIP · BUILD.")
	var under=_need("FOOT SUPPORT UNDER FOOT",foot_support==0,"Push the foot support back under the foot first (under the foot, from either side of the rig).")
	var away=_need("FOOT SUPPORT AWAY",foot_support>=1,"Pull the foot support away from the foot first (under the foot, from either side of the rig).")
	var braced=_need("BRACES LOCKED",brace_error.is_empty(),brace_error)
	var turnover=_need("TURNOVER LOWERED",roll_deg==0 and roll_height_m==0,"Roll the turnover to neutral and lower it first (turnover box at the head end of the table).")
	var on=_need("BOGIE ON TABLE",on_table(),"Drive the bogie back onto the table first (bogie box: TO TABLE).")
	var at_hip=_need("TABLE AT "+side.to_upper()+" HIP",absf(index_x-_lane_x())<=EPS,"Pull the transfer table lever to "+side.to_upper()+" HIP first.")
	var flat=_need("LEG LYING FLAT",tilt_deg<=EPS and rise_m<=EPS,"Lower the leg flat first (bogie box: LOWER).")
	var clamps=_need("CLAMPS CLOSED" if carrying else "CLAMPS RELEASED",release==0 if carrying else release==5,
		"Finish moving the leg clamps first." if release>0 and release<5 else "Tap the leg clamps switch to RELEASE the empty holder first (on the bogie).")
	var bay=_need("BOGIE AT BAY STOP",absf(travel_z-float(spec.bay_z))<=EPS,"Drive the bogie to the bay stop first (bogie box: TO BAY).")
	var front=_need("LOWER GANTRY OPEN",front_open,"Open the lower gantry first (LOWER GANTRY panel at 8.4 m beside the left lift).")
	var hip=_need("HIP GANTRY SECURED",gantry==null or gantry.support_secured(),"Deliver the hip assembly, close all four gantry jaws and insert both waist lock pins first.")
	var complete=_need("LEG COMPLETE",game.model.milestone(active_assembly,"structural_ready"),"Complete the structural leg and every retaining connection first.")
	var neutral_roll=_need("ROLL NEUTRAL",roll_deg==0,"Roll the turnover back to neutral before lowering it.")
	var raised=_need("TURNOVER RAISED",roll_height_m>=_lift_max()-EPS,"Raise the turnover fully before rolling.")
	var foot=_need("FOOT RECEIVED",not game.model.assemblies[active_assembly].slots.get("foot","").is_empty(),"Transfer the prepared foot onto the leg rig first.")
	match action:
		"support":return [at_build,braced,turnover]
		"lift+":return [at_build,foot,under,braced]
		"lift-":return [at_build,under,braced,neutral_roll]
		"roll+","roll-":return [at_build,foot,under,braced,raised]
		"lever":return [on,turnover]+([away,braced] if carrying else [_need("CLAMPS AT REST",release==0 or release==5,"Finish moving the leg clamps first.")])
		"travel+":return [at_hip,flat,clamps]+([away,braced,complete] if carrying else [])
		"travel-":return [at_hip,flat,clamps]+([away,braced] if carrying else [])
		"rise+":return [bay,at_hip,front,hip,complete,braced,clamps] if carrying else [bay,at_hip,clamps]
		"rise-":return [front,braced] if engaged else [clamps]
	return []

## Lamps per box: every condition its controls need right now.
func _box_needs(id: String) -> Array:
	var actions: Array={"bogie":["travel+","rise+"],"turnover":["roll+","lift-"],"lever":["lever"]}[id]
	var result: Array=[];var seen: Dictionary={}
	for action in actions:
		for need in _needs(action):
			if seen.has(need.label):continue
			seen[need.label]=true;result.append(need)
	return result

func action_error(action: String) -> String:
	if game.paused:return "Resume the workshop before operating the leg rig."
	if action not in HOLDS and action not in DRAGS and action not in TAPS:return "Unknown leg rig control."
	if action==jog or drag.get("kind","")==action:return ""
	var retarget: bool=(action=="clamps" and service_goal>=0) or (action=="lever" and table_goal>=0)
	if moving and not retarget:return "Wait for the leg rig to stop."
	var peer: String=game.equipment.busy_reason("rail",equipment_id)
	if not peer.is_empty():return peer
	match action:
		"support":
			if not _carrying():return "The foot support only works with a leg on the rig."
		"lift+","lift-","roll+","roll-":
			if not _carrying():return "The turnover only works with a leg on the rig."
			if action in ["lift+","lift-","roll+","roll-"]:
				var reason: String=game.equipment.busy_reason("source_roll",equipment_id)
				if not reason.is_empty():return reason
		"rise-":
			if engaged and _mounted():
				if retention_state()!="none":return "Remove hip retention before lowering the seated leg."
		"rise+":
			if engaged and _mounted():return "The leg is already seated in the hip."
		"clamps":return _clamp_error()
		"next_leg":
			if not at_station() or roll_deg!=0 or roll_height_m!=0 or release!=0:return "Bring the empty rig to RIGHT HIP · BUILD with its clamps closed (GRAB) first."
			var current: Dictionary=game.model.assemblies[active_assembly]
			if current.parent.is_empty() and current.slots.values().any(func(uid):return not uid.is_empty()):return "The leg rig is occupied. Finish this leg or park it; another leg cannot use the occupied rig."
			return ""
	for need in _needs(action):
		if not need.ok:return need.refusal
	return ""

func _clamp_error() -> String:
	if service_goal>=0:return ""
	if engaged and release==0:
		if not _mounted():return "The clamps are holding a leg that is not seated. RISE to seat it in the hip first."
		if not _at_dock():return "Raise the leg fully into the hip first."
		return "" if retention_state()=="complete" else "Complete hip retention and the cylinder lock pins before releasing the leg clamps."
	if not engaged and release==0:return "" if on_table() else "Release the empty clamps only on the table."
	if release>=5:
		if _mounted() and _at_dock(true):return ""
		if at_station():return ""
		return "GRAB only under the docked leg or at RIGHT HIP · BUILD."
	return ""

func request(action: String) -> String:
	var error=action_error(action)
	if not error.is_empty():return error
	if action in HOLDS:return "Hold E on this control to operate it."
	if action in DRAGS:return "Look at it and hold E to move it."
	load_geometry.invalidate();blocked_reason="";motion_obstruction={}
	match action:
		"clamps":
			if service_goal>=0:service_goal=0.0 if service_goal>0 else 5.0
			elif release>=2.5:
				# The released head is identical in either branch at the dock; restore
				# the docked rise so the reverse sequence closes on the mounted leg.
				if not engaged and _mounted() and _at_dock(true):rise_m=spec.dock_rise
				service_goal=0.0
			else:service_goal=5.0
		"next_leg":
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
			foot_support=0
	_sync_moving();_pose();changed.emit()
	return ""

## Independent joints. The tilt keeps its coupled pivot translation and early lowering.
func snapshot_pose(state: Dictionary) -> Dictionary:
	var tilt: float=state.tilt_deg;var theta=deg_to_rad(90-tilt);var rise: float=state.rise_m
	var x: float=state.index_x;var z: float=state.travel_z
	var lower=spec.delivery_lower*clampf(tilt/(90*spec.lower_during_turn),0,1)
	var root=Vector3(x,spec.base_y+spec.lying_lift*sin(theta)-lower+rise,z-spec.pivot*sin(theta))
	var basis=Basis(Vector3.RIGHT,theta)
	if state.engaged:
		root.y+=state.roll_height_m
		basis*=Basis(Vector3.UP,deg_to_rad(state.roll_deg))
	var release_value: float=state.release
	var opening=clampf(release_value,0,1);var compact=clampf(release_value-3,0,1)
	if not state.engaged or release_value>0:
		if rise>0:
			root.y-=spec.holder.lower*clampf(release_value-1,0,1)
		else:
			var empty_y: float=spec.holder.empty_root_base+spec.holder.empty_root_lift*sin(theta)
			root.y=lerpf(root.y,empty_y,clampf(release_value,0,1))
		root+=basis*Vector3(0,0,spec.holder.withdrawal*clampf(release_value-2,0,1))
		root.x+=(spec.holder.outboard if state.lane=="right" else -spec.holder.outboard)*clampf(release_value-4,0,1)
	return {"frame":Transform3D(basis,root),"bogie_x":x,"bogie_z":z,"opening":opening,"compact":compact,"bolster":state.foot_support}

func physics(delta: float) -> void:
	if game.paused:return
	motion_obstruction={}
	if not jog.is_empty():_jog_tick(delta)
	elif support_goal>=0:
		# A live drag keeps holding its goal; a programmatic pull ends on arrival.
		if _axis_tick("foot_support",support_goal,SUPPORT_SPEED,delta,"support") and drag.is_empty():support_goal=-1.0;_sync_moving();_refresh()
	elif table_goal>=0:
		if _axis_tick("index_x",table_goal,TABLE_SPEED,delta,"lever"):table_goal=-1.0;_sync_moving();_refresh()
	elif service_goal>=0:_service_tick(delta)

## Moves one joint toward a goal with the shared guarded sweep. Prerequisites are
## rechecked every tick; obstacles wait and resume. Returns true on arrival.
func _axis_tick(field: String, goal: float, speed: float, delta: float, action: String) -> bool:
	var refusal: String=""
	for need in _needs(action):
		if not need.ok:refusal=need.refusal;break
	if not refusal.is_empty():blocked_reason=refusal;_refresh();return false
	var before=_state();var current: float=before[field]
	if absf(current-goal)<=EPS:
		set(field,goal);blocked_reason="";_refresh();return true
	var next=before.duplicate(true);next[field]=move_toward(current,goal,speed*delta)
	if absf(next[field]-goal)<=EPS:next[field]=goal
	var ahead=before.duplicate(true)
	ahead[field]=EquipmentRegistry.Motion.ahead(current,goal,next[field]-current,_travel_scale(field))
	blocked_reason=motion_error(before,ahead)
	if not blocked_reason.is_empty():_refresh();return false
	set(field,next[field]);_pose();changed.emit()
	return next[field]==goal

## The joint and goal a held control drives now. RISE stands the leg up, then
## lifts it; LOWER reverses. ROLL stops at each 90° detent.
func _jog_plan(action: String) -> Array:
	var up=action.ends_with("+")
	match action.left(-1):
		"travel":return ["travel_z",float(spec.bay_z) if up else float(spec.home_z),TRAVEL_SPEED]
		"lift":return ["roll_height_m",_lift_max() if up else 0.0,LIFT_SPEED]
		"roll":
			var stops: Array=spec.roll_stops.map(func(x):return float(x))+[360.0]
			stops.sort()
			var limit: float=stops.back() if up else stops.front()
			if up:
				for stop in stops:
					if stop>roll_deg+EPS:limit=stop;break
			else:
				for k in range(stops.size()-1,-1,-1):
					if stops[k]<roll_deg-EPS:limit=stops[k];break
			return ["roll_deg",limit,ROLL_SPEED]
		"rise":
			if up:
				if tilt_deg<90-EPS:return ["tilt_deg",90.0,TILT_SPEED]
				if _carrying() and rise_m<float(spec.dock_rise)-EPS:return ["rise_m",float(spec.dock_rise),RISE_SPEED]
			else:
				if rise_m>EPS and engaged:return ["rise_m",0.0,RISE_SPEED]
				if tilt_deg>EPS:return ["tilt_deg",0.0,TILT_SPEED]
	return []

func _jog_tick(delta: float) -> void:
	if jog_done:return
	blocked_reason=action_error(jog)
	if blocked_reason.is_empty():
		for need in _needs(jog):
			if not need.ok:blocked_reason=need.refusal;break
	if not blocked_reason.is_empty():_refresh();return
	if jog=="rise-" and engaged and _mounted():
		var unseat=_unseat()
		if not unseat.is_empty():blocked_reason=unseat;_refresh();return
	# A cyclic roll below neutral starts from the identical 360° orientation.
	if jog=="roll-" and roll_deg<=EPS:roll_deg=360.0
	var plan=_jog_plan(jog)
	if plan.is_empty():jog_done=true;_settle_roll();_refresh();return
	if _axis_tick(plan[0],plan[1],plan[2],delta,jog):
		if plan[0]=="rise_m" and plan[1]==float(spec.dock_rise) and _carrying():
			_seat();jog_done=true
		elif plan[0] in ["roll_deg","travel_z","roll_height_m"]:jog_done=true;_settle_roll()
		_refresh()

func _settle_roll() -> void:
	if roll_deg>=360-EPS:roll_deg=0.0

## Arrival at the top of RISE installs the supported leg exactly once.
func _seat() -> void:
	var result: Dictionary=game.model.install_supported(receiver,receiver_slot,active_assembly,support)
	if result.ok:game.runtime.mount(receiver,receiver_slot,active_assembly);game.refresh_assembly_collision(receiver)
	else:blocked_reason=result.error
	changed.emit()

## LOWER from the top: the supported undo, only with no hip retention fitted.
func _unseat() -> String:
	var previous: Transform3D=game.runtime.node(active_assembly).global_transform
	var result: Dictionary=game.model.undo_supported(receiver,support)
	if not result.ok:return result.error
	game.runtime.node(active_assembly).reparent(game);game.runtime.node(active_assembly).global_transform=previous
	game.refresh_assembly_collision(receiver);game.refresh_assembly_collision(active_assembly)
	return ""

## The clamp linkage: open, drop, pull back, fold and slide clear. Contact rules
## change at each integer, so each boundary is reached first.
func _service_tick(delta: float) -> void:
	var before=_state();var next=before.duplicate(true)
	var phase_goal = minf(service_goal,floorf(release+.00001)+1) if service_goal>release else maxf(service_goal,ceilf(release-.00001)-1)
	next.release=move_toward(release,phase_goal,RELEASE_SPEED*delta)
	if is_equal_approx(next.release,phase_goal):next.release=phase_goal
	var ahead=before.duplicate(true)
	ahead.release=EquipmentRegistry.Motion.ahead(release,phase_goal,next.release-release,_travel_scale("release"))
	blocked_reason=motion_error(before,ahead,true)
	if not blocked_reason.is_empty():_refresh();return
	release=next.release;_pose()
	if is_equal_approx(release,service_goal):
		release=service_goal;service_goal=-1.0
		# Withdrawal already lowered the empty head; the empty holder has rise zero.
		if release==5:engaged=false;rise_m=0.0
		elif release==0 and not engaged and _mounted() and _at_dock():engaged=true
		_sync_moving();_pose()
	_refresh();changed.emit()

## Conservative surface metres per joint unit, including the long leg's rotation.
func _travel_scale(field: String) -> float:
	match field:
		"tilt_deg":return (PI/2*(10.0+spec.lying_lift+spec.pivot)+spec.delivery_lower/spec.lower_during_turn)/90.0
		"roll_deg":return deg_to_rad(1.0)*10.0
		"release":return maxf(2.0,maxf(spec.holder.withdrawal,maxf(spec.holder.lower,spec.holder.outboard)))
		"foot_support":return maxf(absf(spec.holder.bolster.x[1]-spec.holder.bolster.x[0])/spec.holder.bolster.spread_fraction,spec.holder.bolster.lift/(1-spec.holder.bolster.spread_fraction))
	return 1.0

func motion_error(from: Dictionary, to: Dictionary, contact: bool = false) -> String:
	var a=snapshot_pose(from);var b=snapshot_pose(to)
	var excluded: Array[RID]=layout.cradle.hardware.duplicate()
	var body: Node3D=game.runtime.node(active_assembly)
	var shapes: Array[Dictionary]=[]
	var carried: bool=game.model.assemblies[active_assembly].parent.is_empty() and from.engaged
	if carried:
		load_geometry.read(body)
		excluded.append_array(load_geometry.rids);shapes = load_geometry.shapes
	# Receiver support and a mated load are excluded only during their intentional
	# contact withdrawal. Empty travel continues to collide with the mounted leg.
	if contact and from.release<3 and to.release<=3:Sweep.collect_rids(body,excluded)
	var carrier=game.equipment.get_equipment("foot_carrier")
	if carrier!=null and on_table(from):excluded.append_array(carrier.hardware)
	var samples=Sweep.steps(a.frame,b.frame,10,.025)
	samples=maxi(samples,ceili(absf(to.release-from.release)*2/.025))
	var state_at=func(t: float) -> Dictionary:
		var state=from.duplicate(true)
		for field in FIELDS:state[field]=lerpf(from[field],to[field],t)
		return snapshot_pose(state)
	var rig=func(_frame: Transform3D,t: float) -> Array:
		var at: Dictionary=state_at.call(t)
		return layout.cradle.query_geometry(at.frame,at.bogie_x,at.bogie_z,at.opening,at.compact,at.bolster)
	var changed_fields=FIELDS.filter(func(field):return not is_equal_approx(float(from[field]),float(to[field])))
	var neutral: bool=from.roll_deg==0 and to.roll_deg==0 and from.roll_height_m==0 and to.roll_height_m==0
	# Index and lying travel translate every holder member rigidly; tilt, mast,
	# clamps and foot support still use sampled geometry.
	var linear: bool=neutral and not changed_fields.is_empty() and changed_fields.all(func(field):return field=="index_x" or (field=="travel_z" and from.tilt_deg==0 and to.tilt_deg==0))
	var load_linear: bool=linear or (changed_fields==["rise_m"] and from.engaged and to.engaged and from.release==0 and to.release==0)
	var groups=[{"shapes":shapes,"margin":.001,"linear":load_linear},{"shapes_at":rig,"linear":linear}]
	return EquipmentRegistry.Motion.sweep(self,groups,samples,func(t):return state_at.call(t).frame,excluded).get("error","")

func _pose() -> void:
	var at=snapshot_pose(_state())
	var body: Node3D=game.runtime.node(active_assembly)
	if game.model.assemblies[active_assembly].location=="support:"+support:body.global_transform=at.frame
	layout.cradle.apply_geometry(layout.cradle.geometry(at.frame,at.bogie_x,at.bogie_z,at.opening,at.compact,at.bolster))
	for id in game.runtime.descendants(active_assembly):
		var node: CollisionObject3D=game.runtime.node(id)
		if node is AnimatableBody3D:PhysicsServer3D.body_set_mode(node.get_rid(),PhysicsServer3D.BODY_MODE_STATIC)
		node.force_update_transform();PhysicsServer3D.body_set_state(node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,node.global_transform)
	var braces=game.equipment.get_equipment("joint_restraints")
	if braces!=null:braces.sync_pose()
	_refresh()

## The ghost shows only the current manual objective's target for a carried leg,
## fixed until that objective is done, whatever control is pressed.
func objective_target() -> Variant:
	var guide=game.get("manual_control_guidance")
	if guide==null or guide.get("machine")!=self or not _carrying():return null
	var coords={"index_x":_lane_x(),"travel_z":float(spec.home_z),"tilt_deg":0.0,"rise_m":0.0}
	match str(guide.objective.get("command","")):
		"table:hip":pass
		"travel:bay":coords.travel_z=float(spec.bay_z)
		"table:build":coords.index_x=float(spec.station_x)
		"table:park":coords.index_x=_parking_x()
		"rise":return game.runtime.mount_pose(receiver,receiver_slot,active_assembly)
		_:return null
	var state=_state();state.merge(coords,true);state.roll_deg=0.0;state.roll_height_m=0.0
	return snapshot_pose(state).frame

func _refresh() -> void:
	if parked() and not moving:game.zones.release("limb_station",equipment_id)
	else:game.zones.claim("limb_station",equipment_id)
	for id in lamps:
		var needs: Array=_box_needs(id)
		for row in lamps[id].size():
			var lamp: Label3D=lamps[id][row]
			lamp.visible=row<needs.size()
			if lamp.visible:lamp.text="● "+needs[row].label;lamp.modulate=GREEN if needs[row].ok else RED
	var text: String=status_text()
	if not labels.is_empty():labels[0].text="BOGIE · LEG LIFT\n"+text
	if is_instance_valid(lever_pivot):
		var angle: float=lever_angle if drag.get("kind","")=="lever" else (_notch_for(table_goal).angle if table_goal>=0 else _notch_for(index_x).angle)
		if drag.get("kind","")!="lever":lever_angle=angle
		lever_pivot.rotation.z=-deg_to_rad(angle)
	if is_instance_valid(clamp_switch):clamp_switch.global_position=Vector3(index_x-1.0,0,travel_z)
	if is_instance_valid(ghost):
		var frame=objective_target()
		if frame is Transform3D:ghost.show_target(active_assembly,frame)
		else:ghost.clear()

func _model_changed() -> void:
	load_geometry.invalidate();_refresh()

## Explicit articulation of the carried leg (braces) invalidates cached copies.
func articulation_changed() -> void:
	load_geometry.invalidate()
	if is_instance_valid(ghost):ghost.invalidate()

func status_text() -> String:
	if not blocked_reason.is_empty():return blocked_reason
	if service_goal>=0:return "Leg clamps "+("releasing" if service_goal>release else "grabbing")
	if table_goal>=0:return "Transfer table moving to "+str(_notch_for(table_goal).name)
	return active_assembly.replace("_"," ").to_upper()+(" · on the rig" if _carrying() else " · seated" if engaged else " · rig empty")

func busy_reason(subject: String) -> String:
	if subject in ["mobile_platform","foot_transfer",active_assembly,"rail","crane"] and moving:return "Wait for the leg rig to finish and lock."
	return ""

func access_error(owner: String) -> String:
	if owner in [active_assembly,receiver] and moving:return "Wait for the leg rig to lock."
	if owner==active_assembly and game.model.assemblies[owner].parent.is_empty() and not at_station():return "Return the leg to the build position for construction."
	return ""

func undo(owner: String) -> Dictionary:
	if owner==receiver and not game.model.assemblies[owner].history.is_empty():
		var sid: String=game.model.assemblies[owner].history.back().slot
		for build in ["left_leg","right_leg"]:
			if sid in game.runtime.definition(receiver).milestones[build+"_secured"] and not supports_seated(build):return {"handled":true,"error":"Grab the matching leg with the leg clamps before removing its retention."}
	return {"handled":false,"error":""}

## Internal joint state for poses and sweeps.
func _state() -> Dictionary:
	return {"index_x":index_x,"travel_z":travel_z,"tilt_deg":tilt_deg,"rise_m":rise_m,"roll_deg":roll_deg,"roll_height_m":roll_height_m,"foot_support":foot_support,"release":release,"engaged":engaged,"lane":lane}

func _state_from(data: Dictionary) -> Dictionary:
	var state=data.duplicate();state.release=float(data.clamps)*5.0;state.lane=str(data.assembly).trim_suffix("_leg")
	return state

## At-rest coordinates only: no held control, drag, goal or refusal text.
func capture() -> Dictionary:
	return {"version":SAVE_SHAPE,"assembly":active_assembly,"receiver":receiver,"slot":receiver_slot,"index_x":index_x,"travel_z":travel_z,"tilt_deg":tilt_deg,"rise_m":rise_m,"roll_deg":roll_deg,"roll_height_m":roll_height_m,"foot_support":foot_support,"clamps":release/5.0,"engaged":engaged}

func validate(data: Variant, candidate: AssemblyModel = null, world: Dictionary = {}) -> Array[String]:
	if not Codec.same_keys(data,capture().keys()) or data.version!=SAVE_SHAPE:return ["Invalid leg rig snapshot."]
	var model: AssemblyModel=game.model if candidate==null else candidate
	if data.assembly not in ["left_leg","right_leg"] or data.receiver!=receiver or data.slot!=data.assembly:return ["Unknown leg rig destination or load."]
	if not data.engaged is bool:return ["Invalid leg rig support state."]
	for field in ["index_x","travel_z","tilt_deg","rise_m","roll_deg","roll_height_m","foot_support","clamps"]:
		if not Codec.number(data[field],360):return ["Invalid leg rig coordinates."]
	var state=_state_from(data)
	var lanes: Array=spec.lanes.values()
	if data.index_x<float(lanes.min())-EPS or data.index_x>float(lanes.max())+EPS or data.travel_z<float(spec.home_z)-EPS or data.travel_z>float(spec.bay_z)+EPS or data.tilt_deg<0 or data.tilt_deg>90 or data.rise_m<0 or data.rise_m>float(spec.dock_rise)+EPS:return ["Leg rig joint exceeds its range."]
	if data.roll_deg<0 or data.roll_deg>=360 or data.roll_height_m<0 or data.roll_height_m>_lift_max()+EPS or data.foot_support<0 or data.foot_support>1 or data.clamps<0 or data.clamps>1:return ["Holder construction joint out of range."]
	var table: bool=on_table(data)
	if (data.roll_deg!=0 or data.roll_height_m!=0) and not at_station(data):return ["Turnover is only supported at the build position."]
	if data.roll_deg!=0 and absf(data.roll_height_m-_lift_max())>EPS:return ["Raise the turnover before rolling."]
	var load: Dictionary=model.assemblies[data.assembly]
	var occupant: String=model.support_occupant(support)
	if not occupant.is_empty() and occupant!=data.assembly:return ["The leg rig carries a different selected leg."]
	for owner in ["left_leg","right_leg"]:
		var queued: Dictionary=model.assemblies[owner]
		if queued.location.begins_with("support:leg_queue_") and queued.slots.values().any(func(value):return not value.is_empty()):return ["A leg with physical construction cannot wait in the empty-build queue."]
	if not table:
		if absf(data.index_x-float(spec.lanes[state.lane]))>EPS:return ["The bogie leaves the table only from its leg's hip notch."]
		if data.tilt_deg>EPS and absf(data.travel_z-float(spec.bay_z))>EPS:return ["The leg rig tilts only at the bay stop."]
		if data.rise_m>EPS and absf(data.tilt_deg-90)>EPS:return ["The leg rig rises only upright below the hip."]
	if load.parent.is_empty():
		if load.location!="support:"+support or not data.engaged or state.release!=0:return ["Uninstalled leg has no engaged leg rig."]
		if not table and not model.milestone(data.assembly,"structural_ready"):return ["Incomplete leg cannot leave the table."]
		if not table and data.foot_support!=1:return ["Pull the foot support away before transport."]
		if absf(data.index_x-float(spec.station_x))>EPS and data.foot_support!=1:return ["Pull the foot support away before moving the table."]
	elif load.parent!=receiver or load.parent_slot!=data.slot:return ["Holder load is mounted elsewhere."]
	elif data.engaged and not _at_dock(state.release>0,state):return ["Mounted leg contact is only available at its dock."]
	if not data.engaged and data.rise_m>EPS and (load.parent.is_empty() or not _at_dock(true,state)):return ["An empty holder rises only at the docked leg."]
	if not data.engaged and not table and state.release!=5 and data.rise_m<=EPS:return ["An empty holder leaves the table only fully released."]
	if not load.parent.is_empty() and (not data.engaged or state.release>0) and retention_state(model,world.get("equipment",{}).get("captive_controls",{}),data.assembly)!="complete":return ["Leg clamp release requires full hip retention and lock pins."]
	if world.has("fixtures") and load.parent.is_empty() and not Codec.to_pose(world.fixtures[data.assembly]).is_equal_approx(snapshot_pose(state).frame):return ["Leg pose disagrees with its leg rig."]
	return []

## Restores coordinates and supported pose; input and motion reset.
func apply(data: Dictionary) -> void:
	load_geometry.invalidate()
	motion_obstruction = {}
	active_assembly=data.assembly;receiver=data.receiver;receiver_slot=data.slot;lane=active_assembly.trim_suffix("_leg")
	for field in ["index_x","travel_z","tilt_deg","rise_m","roll_deg","roll_height_m","foot_support","engaged"]:set(field,data[field])
	release=float(data.clamps)*5.0
	jog="";jog_done=false;drag={};support_goal=-1.0;table_goal=-1.0;service_goal=-1.0
	blocked_reason="";_sync_moving();_pose()
