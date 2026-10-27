extends "res://scripts/equipment.gd"
## One indexed rail cradle the player drives joint by joint: hold E on a panel
## arrow to jog one axis, tap SEAT for the guided final lead-in. Construction
## roll/lift/bolster, both delivery lanes, passive parking and the empty-holder
## return share the same independent joint coordinates. Model ownership changes
## only at a supported mount/unmount; moving equipment controls pose.
signal changed
const Sweep = preload("res://scripts/motion_sweep.gd")
const Codec = preload("res://scripts/pose_codec.gd")
const EquipmentButton = preload("res://scripts/equipment_button.gd")
const RigTarget = preload("res://scripts/rig_target.gd")
const SAVE_SHAPE = 2
## Initial constant jog rates (per second), derived from the former phase speeds.
## Not player-approved tuning; see the operated rigs open questions.
const AXES = {
	"index":{"field":"index_x","speed":.8,"caption":"INDEX","unit":"m"},
	"travel":{"field":"travel_z","speed":1.38,"caption":"TRAVEL","unit":"m"},
	"tilt":{"field":"tilt_deg","speed":10.8,"caption":"TILT","unit":"°"},
	"rise":{"field":"rise_m","speed":.144,"caption":"RISE","unit":"m"},
	"roll":{"field":"roll_deg","speed":20.0,"caption":"ROLL","unit":"°"},
	"lift":{"field":"roll_height_m","speed":.375,"caption":"LIFT","unit":"m"},
	"bolster":{"field":"bolster","speed":.3,"caption":"BOLSTER","unit":""},
}
const DELIVERY = ["index","travel","tilt","rise"]
const CONSTRUCTION = ["roll","lift","bolster"]
## Axes that leave the transverse table close the ground crossing first.
const ROUTE_AXES = ["travel","tilt","rise"]
const FIELDS = ["index_x","travel_z","tilt_deg","rise_m","roll_deg","roll_height_m","bolster","release"]
const TAPS = ["stop","seat","release","reacquire","unseat","lane","park","build"]
const MANUAL_COMMANDS = ["bolster:stow","index:lane","travel:bay","tilt:upright","rise:dock","seat","release","tilt:lying","travel:home","index:station","extend","build","park"]
const LINEAR_TOLERANCE = .02
const TILT_TOLERANCE = .10
const RISE_CAPTURE = .04
## SEAT guides the last few centimetres upward and blends residual error.
const SEAT_LEAD = .03
const SEAT_SPEED = .06
const SEAT_POSITION = .05
const SEAT_ANGLE = .10
const RELEASE_SPEED = .6
## Exact mechanical stops only; player alignment uses the tolerances above.
const EPS = .0005
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
var bolster: float = 0.0
var release: float = 0.0
var engaged = true
## Transient input, targets and guided motion; never saved.
var jog = ""
var jog_done = false
var seating = false
var service_goal: float = -1.0
var park_target = false
var returning = false
var moving = false
var blocked_reason = ""
var buttons: Array[Dictionary] = []
var labels: Array[Label3D] = []
var readouts: Array[Dictionary] = []
var ghost: Node3D
var load_geometry = Sweep.RigidGeometry.new()

func save_version() -> int:return SAVE_SHAPE

func setup(workshop: Node3D, scene_layout: Node3D) -> void:
	game=workshop;layout=scene_layout;spec=layout.layout().workshop.rail;equipment_id="leg_rail"
	index_x=spec.station_x;travel_z=spec.home_z
	for index in spec.panels.size():_panel(AssemblyRuntime.vec(spec.panels[index]),index==0)
	ghost=RigTarget.new(game.runtime);game.add_child(ghost)
	game.model.changed.connect(_model_changed)
	_pose()

## The Limb Bay panel also carries the construction bank and table selections.
## Arrow captions name their axis; readouts give signed target-minus-current.
func _panel(at: Vector3, table: bool) -> void:
	var panel = Node3D.new();add_child(panel);panel.position=at
	var dark = game.material(Color("263a43"),.4)
	game.box(panel,Vector3(0,.8,0),Vector3(.12,1.6,2.0),dark,true)
	var rows := {}
	_bank(panel,"DELIVERY",DELIVERY,-.86,rows)
	if table:_bank(panel,"CONSTRUCTION",CONSTRUCTION,.20,rows)
	readouts.append(rows)
	var taps: Array=["stop","seat","release","reacquire","unseat"]+(["lane","park","build"] if table else [])
	for index in taps.size():
		var action: String=taps[index]
		var button = EquipmentButton.make(game,panel,Vector3(-.09,.50-(index/5)*.22,-.84+(index%5)*.30),action.to_upper(),-PI/2,action=="seat")
		buttons.append(control_entry(button,action,action,.11))
	labels.append(game.sign_panel(panel,"",Vector3(-.08,1.9,0),Vector2(1.9,.36),26,.0015,-PI/2))

func _bank(panel: Node3D, title: String, axes: Array, z: float, rows: Dictionary) -> void:
	_label(panel,title,Vector3(-.08,1.56,z+.42),22,Color("a9bcc4"))
	for row in axes.size():
		var axis: String=axes[row];var y: float=1.40-row*.22
		for side in 2:
			var action: String=axis+("-" if side==0 else "+")
			var button = EquipmentButton.make(game,panel,Vector3(-.09,y,z+side*.28),AXES[axis].caption+(" −" if side==0 else " +"),-PI/2)
			EquipmentButton.set_hold_handler(button,_hold.bind(action))
			buttons.append(control_entry(button,action,action,.11))
		rows[axis]=_label(panel,"",Vector3(-.08,y,z+.70),26,RigTarget.ADJUST_COLOR)

func _label(panel: Node3D, text: String, at: Vector3, size: int, color: Color) -> Label3D:
	var label = Label3D.new();panel.add_child(label);label.position=at;label.rotation.y=-PI/2
	label.text=text;label.font_size=size;label.pixel_size=.0013;label.modulate=color;label.outline_size=0
	return label

func _hold(held: bool, _delta: float, action: String) -> void:
	set_jog(action if held else "")

## The one latched jog. Automation drives the same input as Hold E.
func set_jog(action: String) -> void:
	if action==jog:return
	jog=action;jog_done=false;blocked_reason="";motion_obstruction={}
	if action.is_empty():_settle_roll()
	else:
		load_geometry.invalidate()
		if action.left(-1) in DELIVERY:returning=action.ends_with("-")
	_sync_moving()
	if action.is_empty():_rest_gates()
	_refresh()

## Reached a detent or end stop with nothing waiting. Release E to continue.
func jog_settled() -> bool:return not jog.is_empty() and jog_done and blocked_reason.is_empty()

func _sync_moving() -> void:
	moving=not jog.is_empty() or seating or service_goal>=0

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var other := "right" if active_assembly=="left_leg" else "left"
	for button in buttons:
		var entry: Dictionary=button.duplicate();entry.point=entry.node.global_position
		var action: String=entry.action
		if action.left(-1) in AXES:
			entry.label="Leg rig: "+AXES[action.left(-1)].caption+(" +" if action.ends_with("+") else " −")
		else:
			entry.label="Leg rig: "+{"stop":"Stop","seat":"Seat — guide the last 3 cm into the hip","release":"Release — hand the leg to the hip","reacquire":"Reacquire — close the holder on the docked leg, or extend it at the station","unseat":"Unseat — lift the unretained leg back onto the rig","lane":"Lane — "+lane+" hip","park":"Park — "+("cancel the parking target" if park_target else "select the X22 parking target"),"build":"Build — select the "+other+" leg"}[action]
		result.append(entry)
	return result

# Every leg rig command is a panel button, and rig panel buttons get no cue.
func manual_control_actions(_objective: Dictionary) -> Array:
	return []

func manual_commands() -> Array:return MANUAL_COMMANDS
func command_label(action: String, _task: String = "") -> String:
	return {"bolster:stow":"Hold BOLSTER +","index:lane":"Hold INDEX","travel:bay":"Hold TRAVEL +","tilt:upright":"Hold TILT +","rise:dock":"Hold RISE +","seat":"Tap Seat when every mark is green","release":"Release","tilt:lying":"Hold TILT −","travel:home":"Hold TRAVEL −","index:station":"Hold INDEX","extend":"Reacquire","build":"Build","park":"Park, then hold INDEX +"}.get(action,"")
func manual_subject(_objective: Dictionary) -> String:return "Leg rig"
func manual_hint(objective: Dictionary) -> String:
	return {"bolster:stow":"until the foot bolster stows","index:lane":"toward the selected hip track until the table stops on it","travel:bay":"until the bogie stops at the Final Assembly Bay","tilt:upright":"until the leg stands upright","rise:dock":"until it stops just below the hip","release":"after hip retention and both lock pins","tilt:lying":"until the empty holder lies down","travel:home":"until the bogie stops on the transverse table","index:station":"until the table stops at the Limb Bay station","extend":"extends the empty holder at the station","build":"selects the right leg","park":"until the table stops at X22"}.get(str(objective.get("command","")),"")
## Arrival evidence from physical coordinates and model ownership only. A jog
## in progress has not arrived until its coordinate reaches the stop.
func manual_state() -> Dictionary:
	var lane_x := float(spec.lanes[lane])
	var load: Dictionary=game.model.assemblies.get(active_assembly,{})
	var mounted: bool=load.get("parent","")==receiver and load.get("parent_slot","")==receiver_slot
	return {"active_assembly":active_assembly,"engaged":engaged,
		"bolster":bolster>=1-EPS,"indexed":absf(index_x-lane_x)<=LINEAR_TOLERANCE,
		"at_bay":absf(travel_z-float(spec.bay_z))<=LINEAR_TOLERANCE,"upright":absf(tilt_deg-90)<=TILT_TOLERANCE,
		"raised":rise_m>=float(spec.dock_rise)-RISE_CAPTURE,"seated":mounted and _at_dock(),
		"lying":tilt_deg<=EPS,"on_table":on_table(),"at_station":at_station(),"home":at_home(),"parked":parked()}
func _parking_x() -> float:
	var lanes = spec.get("lanes",{})
	return float(lanes.get("parking",spec.get("station_x",index_x))) if lanes is Dictionary else float(spec.get("station_x",index_x))
func manual_effect(objective: Dictionary) -> Dictionary:
	return {"bolster:stow":{"bolster":true},"index:lane":{"indexed":true},"travel:bay":{"at_bay":true},"tilt:upright":{"upright":true},"rise:dock":{"raised":true},"seat":{"seated":true},
		"release":{"engaged":false},"tilt:lying":{"lying":true},"travel:home":{"on_table":true},"index:station":{"at_station":true},"extend":{"home":true},
		"build":{"active_assembly":"right_leg","engaged":true},"park":{"parked":true}}.get(str(objective.get("command","")),{})

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
## Stationary at the Limb Bay station with neutral construction axes and an extended holder.
func at_home() -> bool:
	return not moving and at_station() and release==0 and roll_deg==0 and roll_height_m==0
func can_construct() -> bool:
	return engaged and at_home()
## Engaged, braked and at the exact docked pose of the given leg.
func supports_seated(assembly: String) -> bool:
	return active_assembly==assembly and engaged and release==0 and not moving and _at_dock()
## The full construction support that brace and source operations rely on.
func supports_construction(assembly: String) -> bool:
	return active_assembly==assembly and can_construct() and bolster==0
## Ground crossing gates may open only at a stable table pose or a docked leg.
func gates_may_open() -> bool:
	return not moving and (on_table() or (_at_dock(true) and _mounted()))

func _at_dock(any_rise: bool = false, state: Dictionary = {}) -> bool:
	var s: Dictionary=capture() if state.is_empty() else state
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

func _is_jog(action: String) -> bool:
	return (action.ends_with("+") or action.ends_with("-")) and AXES.has(action.left(-1))

func action_error(action: String) -> String:
	if game.paused:return "Resume the workshop before moving the leg rig."
	if not _is_jog(action) and action not in TAPS:return "Unknown leg rig command."
	if action=="stop":return "" if moving else "The leg rig is stopped."
	if action==jog:return ""
	if moving:return "Release E or Stop the leg rig before selecting another command."
	var peer: String=game.equipment.busy_reason("rail",equipment_id)
	if not peer.is_empty():return peer
	if _is_jog(action):return _jog_error(action)
	match action:
		"lane","park":
			if not on_table():return "Return the leg rig to the transverse table first."
			if action=="lane" and (roll_deg!=0 or roll_height_m!=0):return "Restore neutral roll and construction height before indexing."
			return ""
		"build":
			if not at_station() or roll_deg!=0 or roll_height_m!=0 or release!=0:return "Return the empty leg rig to the Limb Bay and extend its holder before selecting another leg."
			var current: Dictionary=game.model.assemblies[active_assembly]
			if current.parent.is_empty() and current.slots.values().any(func(uid):return not uid.is_empty()):return "The leg rig is occupied. Finish this leg or park it for arm work; another leg cannot use the occupied leg rig."
			return ""
		"seat":return seat_error()
		"release":
			if engaged and _mounted() and _at_dock():
				return "" if retention_state()=="complete" else "Complete hip retention and the cylinder lock pins before releasing the leg rig."
			if not engaged and release<5 and on_table():return ""
			if not engaged:return "The empty holder is already released."
			return "Seat the leg in the hip before releasing the leg rig."
		"reacquire":
			if engaged:return "" if release>0 else "The leg rig already supports this leg."
			if release==0:return "The empty holder is already extended."
			if _mounted() and _at_dock(true):return ""
			if at_station():return ""
			return "Bring the empty holder under the docked leg, or to the Limb Bay station, before reacquiring."
		"unseat":
			if not engaged or release!=0 or not _mounted() or not _at_dock():return "Reacquire the docked leg with the leg rig before unseating it."
			if retention_state()!="none":return "Remove hip retention before returning the loaded leg."
			return _braces_error()
	return ""

func _braces_error() -> String:
	var braces=game.equipment.get_equipment("joint_restraints")
	return braces.required_error(active_assembly) if braces!=null else ""

## Mechanical prerequisites for one jog direction. Checked on latch and every tick;
## refusals name the correction and never move, drop ownership or tick the manual.
func _jog_error(action: String) -> String:
	var axis: String=action.left(-1);var up=action.ends_with("+")
	var carrying=_carrying()
	if release>0 and release<5:return "Finish the holder Release or Reacquire first."
	if engaged and not carrying:
		return "Remove hip retention before returning the loaded leg." if retention_state()!="none" else "Unseat the leg before moving the loaded leg rig."
	if axis in CONSTRUCTION:
		if not carrying or not at_station():return "Roll only with the leg rig occupied in the Limb Bay."
		var braces=_braces_error()
		if not braces.is_empty():return braces
		if axis=="bolster":
			return "" if roll_deg==0 and roll_height_m==0 else "Restore neutral roll and construction height before moving the foot bolster."
		var reason: String=game.equipment.busy_reason("source_roll",equipment_id)
		if not reason.is_empty():return reason
		if game.model.assemblies[active_assembly].slots.foot.is_empty():return "Transfer the prepared foot onto the leg rig first."
		if bolster!=0:return "Engage the foot bolster under the foot before rolling."
		if axis=="roll" and roll_height_m<_lift_max()-EPS:return "Raise the construction axis before rolling."
		if axis=="lift" and not up and roll_deg!=0:return "Restore neutral roll before lowering the construction axis."
		return ""
	if carrying:
		var braces=_braces_error()
		if not braces.is_empty():return braces
		if roll_deg!=0 or roll_height_m!=0:return "Restore neutral roll and construction height before indexing."
		if bolster<1:return "Stow the foot bolster before indexing."
	elif axis!="index" and release<5:return "Release the empty holder before it leaves the transverse table."
	var lane_x: float=spec.lanes[lane]
	match axis:
		"index":
			return "" if on_table() else "Return the leg rig to the transverse table first."
		"travel":
			if tilt_deg>EPS or rise_m>EPS:return "Lower and lay the leg down before travelling."
			if absf(index_x-lane_x)>LINEAR_TOLERANCE:return "Align INDEX with the selected hip track."
		"tilt":
			if absf(index_x-lane_x)>LINEAR_TOLERANCE:return "Align INDEX with the selected hip track."
			if absf(travel_z-float(spec.bay_z))>LINEAR_TOLERANCE:return "Travel to the clear turn position before tilting."
			if rise_m>EPS:return "Lower the leg before tilting."
		"rise":
			if not carrying:return "Use Reacquire to dock the empty holder."
			if absf(tilt_deg-90)>TILT_TOLERANCE or absf(index_x-lane_x)>LINEAR_TOLERANCE or absf(travel_z-float(spec.bay_z))>LINEAR_TOLERANCE:return "Stand the leg upright under the selected hip before raising."
	if carrying:
		if lane!=active_assembly.trim_suffix("_leg"):return "Select the "+active_assembly.trim_suffix("_leg")+" hip lane for this leg."
		if up:return _delivery_error()
	return ""

func _delivery_error() -> String:
	var gantry=game.equipment.get_equipment("module_supports")
	if gantry!=null and not gantry.support_secured():return "Deliver the hip assembly, close all four gantry jaws and insert both waist lock pins before leg delivery."
	if not game.model.milestone(active_assembly,"structural_ready"):return "Complete the structural leg and every retaining connection before delivery."
	return ""

## Waiting is not a refusal: motion holds and resumes while input stays held.
func _route_wait() -> String:
	var gates=game.equipment.get_equipment("rail_gates")
	if gates!=null:
		var occupied: String=gates.occupancy_error()
		if not occupied.is_empty():return occupied
		if not gates.closed():
			if not gates.moving:
				var error: String=gates.request_closed(true)
				if not error.is_empty():return error
			return "Waiting for the ground crossing gates to close."
	if engaged:
		var access=game.equipment.get_equipment("workshop_access")
		if access!=null and not access.ready_for("leg"):
			if not access.moving:
				var error: String=access.request_mode("leg")
				if not error.is_empty():return error
			return "Waiting for the hip access platforms to clear."
	return ""

func _rest_gates() -> void:
	var gates=game.equipment.get_equipment("rail_gates")
	if gates!=null and gates.get("goal")==1 and gates_may_open():gates.request_closed(false)

func _seated_coords() -> Dictionary:
	return {"index_x":float(spec.lanes[lane]),"travel_z":float(spec.bay_z),"tilt_deg":90.0,"rise_m":float(spec.dock_rise)}

## Axis tolerances plus the mating connection's residual against the actual
## receiving frame. Being within tolerance never installs by itself.
func seat_error(check_alignment: bool = true) -> String:
	if not engaged:return "Reacquire the leg with the leg rig before seating it."
	if not _carrying():return "The leg is already seated."
	if lane!=active_assembly.trim_suffix("_leg"):return "Select the "+active_assembly.trim_suffix("_leg")+" hip lane for this leg."
	var delivery=_delivery_error()
	if not delivery.is_empty():return delivery
	var braces=_braces_error()
	if not braces.is_empty():return braces
	var placement: String=game.model.placement_error(receiver,receiver_slot,active_assembly,support)
	if not placement.is_empty():return placement
	if not check_alignment:return ""
	var aligned: bool=_readout_axes(_seated_coords(),true).all(func(axis):return absf(axis.delta)<=axis.tolerance)
	if aligned:
		var actual: Transform3D=snapshot_pose(capture()).frame
		var mount: Transform3D=game.runtime.mount_pose(receiver,receiver_slot,active_assembly)
		aligned=actual.origin.distance_to(mount.origin)<=SEAT_POSITION and rad_to_deg(actual.basis.get_rotation_quaternion().angle_to(mount.basis.get_rotation_quaternion()))<=SEAT_ANGLE+.0001
	return "" if aligned else "Align the green axis marks before seating."

func request(action: String) -> String:
	var error=action_error(action)
	if not error.is_empty():return error
	if _is_jog(action):return "Hold E on the "+AXES[action.left(-1)].caption+" arrow to jog the leg rig."
	load_geometry.invalidate()
	blocked_reason=""
	motion_obstruction={}
	match action:
		"stop":
			jog="";jog_done=false;seating=false;service_goal=-1.0;_sync_moving();_rest_gates();_refresh();return ""
		"lane":lane="right" if lane=="left" else "left";park_target=false;returning=false
		"park":park_target=not park_target
		"build":
			var current: Dictionary=game.model.assemblies[active_assembly]
			if current.parent.is_empty():
				error=game.model.transfer_supported_assembly(active_assembly,support,"leg_queue_"+active_assembly.trim_suffix("_leg"))
				if not error.is_empty():return error
			active_assembly="right_leg" if active_assembly=="left_leg" else "left_leg"
			receiver_slot=active_assembly;lane=active_assembly.trim_suffix("_leg");park_target=false;returning=false
			engaged=game.model.assemblies[active_assembly].parent.is_empty()
			if engaged:
				error=game.model.transfer_supported_assembly(active_assembly,"leg_queue_"+lane,support)
				if not error.is_empty():return error
			bolster=0
		"seat":seating=true
		"release":service_goal=5.0
		"reacquire":
			# The released head is identical in either branch at the dock; restore the
			# docked rise so the reverse service sequence closes on the mounted leg.
			if not engaged and _mounted() and _at_dock(true):rise_m=spec.dock_rise
			service_goal=0.0
		"unseat":
			var previous: Transform3D=game.runtime.node(active_assembly).global_transform
			var result: Dictionary=game.model.undo_supported(receiver,support)
			if not result.ok:return result.error
			game.runtime.node(active_assembly).reparent(game);game.runtime.node(active_assembly).global_transform=previous
			game.refresh_assembly_collision(receiver);game.refresh_assembly_collision(active_assembly)
			returning=true
	_sync_moving();_pose();changed.emit()
	return ""

## Independent joints. Only the selected joint changes on a jog tick; the tilt
## keeps its coupled pivot translation and early lowering.
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
	return {"frame":Transform3D(basis,root),"bogie_x":x,"bogie_z":z,"opening":opening,"compact":compact,"bolster":state.bolster}

func physics(delta: float) -> void:
	if game.paused:
		# Pause leaves the current supported pose; another SEAT tap revalidates.
		if seating:seating=false;_sync_moving();_refresh()
		return
	if not jog.is_empty():_jog_tick(delta)
	elif seating:_seat_tick(delta)
	elif service_goal>=0:_service_tick(delta)

## The next exact stop in the jog direction: an end stop, an indexed track or a
## roll detent. A jog halts there; a fresh press continues past it.
func _jog_limit(axis: String, up: bool) -> float:
	var current: float=get(AXES[axis].field)
	var limit: float
	match axis:
		"index","roll":
			var stops: Array=[]
			if axis=="index":stops=spec.lanes.values().map(func(x):return float(x))+[float(spec.station_x)]
			else:stops=spec.roll_stops.map(func(x):return float(x))+[360.0]
			stops.sort()
			if up:
				limit=stops.back()
				for stop in stops:
					if stop>current+EPS:limit=stop;break
			else:
				limit=stops.front()
				for k in range(stops.size()-1,-1,-1):
					if stops[k]<current-EPS:limit=stops[k];break
		"travel":limit=spec.bay_z if up else spec.home_z
		"tilt":limit=90.0 if up else 0.0
		"rise":limit=(float(spec.dock_rise)-SEAT_LEAD if _carrying() else float(spec.dock_rise)) if up else 0.0
		"lift":limit=_lift_max() if up else 0.0
		_:limit=1.0 if up else 0.0
	return maxf(limit,current) if up else minf(limit,current)

func _jog_tick(delta: float) -> void:
	motion_obstruction={}
	if jog_done:return
	var axis: String=jog.left(-1);var up=jog.ends_with("+")
	blocked_reason=_jog_error(jog)
	if blocked_reason.is_empty():blocked_reason=game.equipment.busy_reason("rail",equipment_id)
	if blocked_reason.is_empty() and axis in ROUTE_AXES:blocked_reason=_route_wait()
	if not blocked_reason.is_empty():_refresh();return
	var field: String=AXES[axis].field
	# A cyclic roll below neutral starts from the identical 360° orientation.
	if field=="roll_deg" and not up and roll_deg<=EPS:roll_deg=360.0
	var limit=_jog_limit(axis,up)
	var before=capture()
	var current: float=before[field]
	if absf(current-limit)<=EPS:
		set(field,limit);jog_done=true;_settle_roll();_refresh();return
	var next=before.duplicate(true)
	next[field]=move_toward(current,limit,AXES[axis].speed*delta)
	if absf(next[field]-limit)<=EPS:next[field]=limit
	var ahead=before.duplicate(true)
	ahead[field]=EquipmentRegistry.Motion.ahead(current,limit,next[field]-current,_travel_scale(field))
	blocked_reason=motion_error(before,ahead)
	if not blocked_reason.is_empty():_refresh();return
	set(field,next[field])
	if next[field]==limit:jog_done=true;_settle_roll()
	_pose();changed.emit()

func _settle_roll() -> void:
	if roll_deg>=360-EPS:roll_deg=0.0

func _seat_tick(delta: float) -> void:
	motion_obstruction={}
	var error=seat_error(false)
	# A changed receiver or support halts the lead-in; SEAT revalidates it.
	if not error.is_empty():seating=false;blocked_reason=error;_sync_moving();_refresh();return
	blocked_reason=_route_wait()
	if not blocked_reason.is_empty():_refresh();return
	var before=capture();var target=_seated_coords()
	var remaining: float=target.rise_m-rise_m
	var step: float=SEAT_SPEED*delta
	var fraction: float=1.0 if remaining<=step+EPS else step/remaining
	var look: float=1.0 if remaining<=EPS else minf(1.0,maxf(step,EquipmentRegistry.Motion.LOOKAHEAD)/remaining)
	var next=before.duplicate(true);var ahead=before.duplicate(true)
	for field in target:
		next[field]=target[field] if fraction>=1 else lerpf(before[field],target[field],fraction)
		ahead[field]=lerpf(before[field],target[field],look)
	blocked_reason=motion_error(before,ahead)
	if not blocked_reason.is_empty():_refresh();return
	for field in target:set(field,next[field])
	_pose()
	if fraction>=1:_arrive_seated()
	_refresh();changed.emit()

func _arrive_seated() -> void:
	seating=false;_sync_moving()
	var result: Dictionary=game.model.install_supported(receiver,receiver_slot,active_assembly,support)
	if result.ok:game.runtime.mount(receiver,receiver_slot,active_assembly);game.refresh_assembly_collision(receiver)
	else:blocked_reason=result.error
	var access=game.equipment.get_equipment("workshop_access")
	if access!=null:access.request_mode("work")
	_rest_gates()

## Holder support service: jaws, lower, withdraw, compact and outboard shift.
## Contact rules change at each integer, so each boundary is reached first.
func _service_tick(delta: float) -> void:
	motion_obstruction={}
	var before=capture();var next=before.duplicate(true)
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
		# Withdrawal already lowered the empty head. Both rise branches share this
		# released pose; the empty holder returns with rise zero.
		if release==5:engaged=false;rise_m=0.0
		elif release==0 and not engaged and _mounted() and _at_dock():engaged=true
		_sync_moving();_pose()
	_refresh();changed.emit()

## Conservative surface metres per joint unit, including the long leg's rotation
## and the holder's articulated pieces. No whole-route occupancy reservation.
func _travel_scale(field: String) -> float:
	match field:
		"tilt_deg":return (PI/2*(10.0+spec.lying_lift+spec.pivot)+spec.delivery_lower/spec.lower_during_turn)/90.0
		"roll_deg":return deg_to_rad(1.0)*10.0
		"release":return maxf(2.0,maxf(spec.holder.withdrawal,maxf(spec.holder.lower,spec.holder.outboard)))
		"bolster":return maxf(absf(spec.holder.bolster.x[1]-spec.holder.bolster.x[0])/spec.holder.bolster.spread_fraction,spec.holder.bolster.lift/(1-spec.holder.bolster.spread_fraction))
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
	# Index and lying travel translate every holder member rigidly. Tilt, the
	# telescoping mast, release and bolster still use sampled geometry.
	var linear: bool=neutral and not changed_fields.is_empty() and changed_fields.all(func(field):return field=="index_x" or (field=="travel_z" and from.tilt_deg==0 and to.tilt_deg==0))
	# An engaged rise lifts the upright leg straight up; only the mast changes the rig.
	var load_linear: bool=linear or (changed_fields==["rise_m"] and from.engaged and to.engaged and from.release==0 and to.release==0)
	var groups=[{"shapes":shapes,"margin":.001,"linear":load_linear},{"shapes_at":rig,"linear":linear}]
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
	var braces=game.equipment.get_equipment("joint_restraints")
	if braces!=null:braces.sync_pose()
	_refresh()

## The next unmet physical condition, as joint coordinates. A record, never a move.
## Reversing a delivery joint selects the corresponding return target.
func target() -> Dictionary:
	var lane_x: float=spec.lanes[lane]
	var home={"index_x":float(spec.station_x),"travel_z":float(spec.home_z),"tilt_deg":0.0,"rise_m":0.0}
	var at_lane={"index_x":lane_x,"travel_z":float(spec.home_z),"tilt_deg":0.0,"rise_m":0.0}
	var turn={"index_x":lane_x,"travel_z":float(spec.bay_z),"tilt_deg":0.0,"rise_m":0.0}
	var upright={"index_x":lane_x,"travel_z":float(spec.bay_z),"tilt_deg":90.0,"rise_m":0.0}
	var parking={"index_x":_parking_x(),"travel_z":float(spec.home_z),"tilt_deg":0.0,"rise_m":0.0}
	if engaged and not _carrying():
		return {"name":"seated","hint":"Release after hip retention, or Unseat to return","coords":_seated_coords(),"ghost":false}
	if not engaged:
		if release>0 and release<5:return {"name":"service","hint":"Finish the holder Release or Reacquire","coords":_coords(),"ghost":false}
		if not on_table():
			if tilt_deg>EPS or rise_m>EPS:return {"name":"lying","hint":"Lay the empty holder down (TILT −)","coords":turn,"ghost":false}
			return {"name":"table","hint":"Travel the empty holder home (TRAVEL −)","coords":at_lane,"ghost":false}
		if park_target:return {"name":"parking","hint":"Index to parking (INDEX +)","coords":parking,"ghost":false}
		if not at_station():return {"name":"station","hint":"Index to the Limb Bay station (INDEX)","coords":home,"ghost":false}
		if release==5:return {"name":"extend","hint":"Reacquire extends the empty holder","coords":home,"ghost":false}
		return {"name":"home","hint":"Build selects the next leg","coords":home,"ghost":false}
	if roll_deg!=0 or roll_height_m!=0:
		return {"name":"neutral","hint":"Restore neutral roll (ROLL), then lower (LIFT −)","coords":home,"ghost":false}
	if park_target:return {"name":"parking","hint":"Index to parking (INDEX +)","coords":parking,"ghost":true}
	var finished: bool=game.model.milestone(active_assembly,"structural_ready")
	if not finished or (returning and on_table()):
		return {"name":"home","hint":"Construction home" if at_station() else "Index to the Limb Bay station (INDEX)","coords":home,"ghost":not at_station()}
	if returning:
		if rise_m>EPS:return {"name":"lowered","hint":"Lower the leg (RISE −)","coords":upright,"ghost":true}
		if tilt_deg>EPS:return {"name":"lying","hint":"Lay the leg down (TILT −)","coords":turn,"ghost":true}
		return {"name":"table","hint":"Travel home (TRAVEL −)","coords":at_lane,"ghost":true}
	if bolster<1:return {"name":"bolster","hint":"Stow the foot bolster (BOLSTER +)","coords":_coords(),"ghost":false}
	if on_table() and absf(index_x-lane_x)>LINEAR_TOLERANCE:return {"name":"track","hint":"Index to the "+lane+" hip track (INDEX)","coords":at_lane,"ghost":true}
	if absf(travel_z-float(spec.bay_z))>LINEAR_TOLERANCE and tilt_deg<=EPS:return {"name":"turn","hint":"Travel to the Final Assembly Bay (TRAVEL +)","coords":turn,"ghost":true}
	if absf(tilt_deg-90)>TILT_TOLERANCE:return {"name":"upright","hint":"Stand the leg upright (TILT +)","coords":upright,"ghost":true}
	return {"name":"seated","hint":"Raise (RISE +) until every mark is green, then Seat","coords":_seated_coords(),"ghost":true}

func _coords() -> Dictionary:
	return {"index_x":index_x,"travel_z":travel_z,"tilt_deg":tilt_deg,"rise_m":rise_m}

## Readout and ghost derive from the same target record.
func _readout_axes(coords: Dictionary, seat: bool) -> Array:
	var tolerances={"index_x":LINEAR_TOLERANCE,"travel_z":LINEAR_TOLERANCE,"tilt_deg":TILT_TOLERANCE,"rise_m":RISE_CAPTURE if seat else EPS}
	var result: Array=[]
	for axis in DELIVERY:
		var field: String=AXES[axis].field
		result.append({"label":AXES[axis].caption,"delta":float(coords[field])-float(get(field)),"tolerance":tolerances[field],"unit":" "+AXES[axis].unit})
	return result

## The seated ghost is the exact runtime install pose; others follow the joints.
func target_frame(record: Dictionary) -> Transform3D:
	if record.name=="seated":return game.runtime.mount_pose(receiver,receiver_slot,active_assembly)
	var state=capture();state.merge(record.coords,true)
	state.engaged=true;state.release=0.0;state.roll_deg=0.0;state.roll_height_m=0.0
	return snapshot_pose(state).frame

func _refresh() -> void:
	if parked() and not moving:game.zones.release("limb_station",equipment_id)
	else:game.zones.claim("limb_station",equipment_id)
	var record: Dictionary=target()
	var rows: Array=RigTarget.axis_readout(_readout_axes(record.coords,record.name=="seated")).rows
	var construction={"roll":"ROLL %.1f°"%roll_deg,"lift":"LIFT %.2f m"%roll_height_m,"bolster":"BOLSTER "+("stowed" if bolster>=1 else "supporting" if bolster<=0 else "%d%%"%roundi(bolster*100))}
	var exact={"roll":spec.get("roll_stops",[0]).any(func(stop):return absf(roll_deg-float(stop))<=EPS),"lift":roll_height_m==0 or absf(roll_height_m-_lift_max())<=EPS,"bolster":bolster==0 or bolster==1}
	for panel in readouts:
		for index in DELIVERY.size():
			panel[DELIVERY[index]].text=rows[index].text;panel[DELIVERY[index]].modulate=rows[index].color
		for axis in CONSTRUCTION:
			if panel.has(axis):panel[axis].text=construction[axis];panel[axis].modulate=RigTarget.READY_COLOR if exact[axis] else RigTarget.ADJUST_COLOR
	var text: String=status_text()
	for label in labels:label.text=text
	if is_instance_valid(ghost):
		if record.ghost and _carrying():ghost.show_target(active_assembly,target_frame(record))
		else:ghost.clear()

func _model_changed() -> void:
	load_geometry.invalidate();_refresh()

## Explicit articulation of the carried leg (braces) invalidates cached copies.
func articulation_changed() -> void:
	load_geometry.invalidate()
	if is_instance_valid(ghost):ghost.invalidate()

func status_text() -> String:
	if not blocked_reason.is_empty():return blocked_reason
	var heading: String="LEG RIG / "+active_assembly.replace("_"," ").to_upper()+" · "+lane+" lane"+(" · park" if park_target else "")
	if seating:return heading+"\nSeating — guiding the last few centimetres"
	if service_goal>=0:return heading+"\n"+("Releasing the holder" if service_goal>release else "Closing the holder")
	if not jog.is_empty():return heading+"\n"+AXES[jog.left(-1)].caption+(" +" if jog.ends_with("+") else " −")+(" — at its stop" if jog_done else "")
	return heading+"\nNext: "+str(target().hint)

func busy_reason(subject: String) -> String:
	if subject in ["mobile_platform","foot_transfer",active_assembly,"rail","crane"] and moving:return "Wait for the leg rig to finish and lock."
	return ""

func access_error(owner: String) -> String:
	if owner in [active_assembly,receiver] and moving:return "Wait for the leg rig to lock."
	if owner==active_assembly and game.model.assemblies[owner].parent.is_empty() and not at_station():return "Return the leg to the Limb Bay for construction."
	return ""

func undo(owner: String) -> Dictionary:
	if owner==receiver and not game.model.assemblies[owner].history.is_empty():
		var sid: String=game.model.assemblies[owner].history.back().slot
		for build in ["left_leg","right_leg"]:
			if sid in game.runtime.definition(receiver).milestones[build+"_secured"] and not supports_seated(build):return {"handled":true,"error":"Reacquire the matching leg with the leg rig before removing its retention."}
	return {"handled":false,"error":""}

## At-rest coordinates only: no latch, direction, target, lead-in or refusal text.
func capture() -> Dictionary:
	return {"version":SAVE_SHAPE,"assembly":active_assembly,"receiver":receiver,"slot":receiver_slot,"lane":lane,"index_x":index_x,"travel_z":travel_z,"tilt_deg":tilt_deg,"rise_m":rise_m,"roll_deg":roll_deg,"roll_height_m":roll_height_m,"bolster":bolster,"release":release,"engaged":engaged}

func validate(data: Variant, candidate: AssemblyModel = null, world: Dictionary = {}) -> Array[String]:
	if not Codec.same_keys(data,capture().keys()) or data.version!=SAVE_SHAPE:return ["Invalid leg rig snapshot."]
	var model: AssemblyModel=game.model if candidate==null else candidate
	if data.assembly not in ["left_leg","right_leg"] or data.receiver!=receiver or data.slot!=data.assembly or data.lane not in ["left","right"]:return ["Unknown leg rig destination or load."]
	if not data.engaged is bool:return ["Invalid leg rig support state."]
	for field in FIELDS:
		if not Codec.number(data[field],360):return ["Invalid leg rig coordinates."]
	var lanes: Array=spec.lanes.values()
	if data.index_x<float(lanes.min())-EPS or data.index_x>float(lanes.max())+EPS or data.travel_z<float(spec.home_z)-EPS or data.travel_z>float(spec.bay_z)+EPS or data.tilt_deg<0 or data.tilt_deg>90 or data.rise_m<0 or data.rise_m>float(spec.dock_rise)+EPS:return ["Leg rig joint exceeds its range."]
	if data.roll_deg<0 or data.roll_deg>=360 or data.roll_height_m<0 or data.roll_height_m>_lift_max()+EPS or data.bolster<0 or data.bolster>1 or data.release<0 or data.release>5:return ["Holder construction joint out of range."]
	var table: bool=on_table(data)
	if (data.roll_deg!=0 or data.roll_height_m!=0) and not at_station(data):return ["Source roll is only supported in the Limb Bay."]
	if data.roll_deg!=0 and absf(data.roll_height_m-_lift_max())>EPS:return ["Raise the supported roll axis before rotation."]
	var load: Dictionary=model.assemblies[data.assembly]
	var occupant: String=model.support_occupant(support)
	if not occupant.is_empty() and occupant!=data.assembly:return ["The leg rig carries a different selected leg."]
	for owner in ["left_leg","right_leg"]:
		var queued: Dictionary=model.assemblies[owner]
		if queued.location.begins_with("support:leg_queue_") and queued.slots.values().any(func(value):return not value.is_empty()):return ["A leg with physical construction cannot wait in the empty-build queue."]
	if not table:
		if data.lane!=data.assembly.trim_suffix("_leg"):return ["Leg delivery requires its matching hip lane."]
		if absf(data.index_x-float(spec.lanes[data.lane]))>LINEAR_TOLERANCE:return ["Longitudinal travel requires a pinned hip lane."]
		if data.tilt_deg>EPS and absf(data.travel_z-float(spec.bay_z))>LINEAR_TOLERANCE:return ["The leg rig tilts only at the clear turn position."]
		if data.rise_m>EPS and absf(data.tilt_deg-90)>TILT_TOLERANCE:return ["The leg rig rises only upright below the hip."]
	if load.parent.is_empty():
		if load.location!="support:"+support or not data.engaged or data.release!=0:return ["Uninstalled leg has no engaged leg rig."]
		if not table and not model.milestone(data.assembly,"structural_ready"):return ["Incomplete leg cannot leave the construction table."]
		if not table and data.bolster!=1:return ["Stow the foot bolster before transport."]
		if absf(data.index_x-float(spec.station_x))>EPS and data.bolster!=1:return ["Stow the foot bolster before indexing."]
	elif load.parent!=receiver or load.parent_slot!=data.slot:return ["Holder load is mounted elsewhere."]
	elif data.engaged and not _at_dock(data.release>0,data):return ["Mounted leg contact is only available at its dock."]
	if not data.engaged and data.rise_m>EPS and (load.parent.is_empty() or not _at_dock(true,data)):return ["An empty holder rises only at the docked leg."]
	if not data.engaged and not table and data.release!=5 and data.rise_m<=EPS:return ["An empty holder leaves the table only fully released."]
	if not load.parent.is_empty() and (not data.engaged or data.release>0) and retention_state(model,world.get("equipment",{}).get("captive_controls",{}),data.assembly)!="complete":return ["Leg rig release requires full hip retention and lock pins."]
	var intermediate: bool=not table and not (absf(data.travel_z-float(spec.bay_z))<=EPS and absf(data.tilt_deg-90)<=TILT_TOLERANCE)
	if intermediate and world.has("equipment") and world.equipment.get("rail_gates",{}).get("goal",1)!=1:return ["A leg rig between rest positions requires closed ground crossing gates."]
	if world.has("fixtures") and load.parent.is_empty() and not Codec.to_pose(world.fixtures[data.assembly]).is_equal_approx(snapshot_pose(data).frame):return ["Leg pose disagrees with its leg rig."]
	return []

## Restores coordinates and supported pose; input and guided motion reset.
func apply(data: Dictionary) -> void:
	load_geometry.invalidate()
	motion_obstruction = {}
	active_assembly=data.assembly;receiver=data.receiver;receiver_slot=data.slot;lane=data.lane
	for field in FIELDS+["engaged"]:set(field,data[field])
	jog="";jog_done=false;seating=false;service_goal=-1.0;park_target=false;returning=false
	blocked_reason="";_sync_moving();_pose()
