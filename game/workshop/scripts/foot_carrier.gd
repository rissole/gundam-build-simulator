extends "res://scripts/equipment.gd"
## Guided sole cradle: dispatch -> raised -> turned onto the horizontal leg rail.
## Foot ownership stays with the carrier until the receiving sole pads touch.
signal changed
const Layout = preload("res://scripts/leg_bay_layout.gd")
const Sweep = preload("res://scripts/motion_sweep.gd")
const Codec = preload("res://scripts/pose_codec.gd")
var layout: Node3D
var spec: Dictionary
var path = 0.0
var goal = 0.0
var moving = false
var blocked_reason = ""
var cradle: Node3D
var mast: MeshInstance3D
var bogie: MeshInstance3D
var moving_pieces: Array[Dictionary] = []
var handoff = ""
var withdrawal = 0.0
var buttons: Array[Dictionary] = []
var label: Label3D
var hardware: Array[RID] = []

func setup(workshop: Node3D, scene_layout: Node3D) -> void:
	game = workshop;layout = scene_layout;equipment_id = "foot_carrier";spec = Layout.layout().foot_carrier
	var steel = game.material(Color("506971"),.45)
	var yellow = game.material(Color("e8b46b"),.3)
	cradle = Node3D.new();cradle.name = "GuidedSoleCradle";add_child(cradle)
	for contact in spec.contacts:
		var at = AssemblyRuntime.vec(contact)-Vector3(0,.035,0)
		_support_box(cradle,"SolePad",at,AssemblyRuntime.vec(spec.sole_pad_size),yellow)
	for at in spec.end_stop.centers:
		_support_box(cradle,"LocatedSoleEndStop",AssemblyRuntime.vec(at),AssemblyRuntime.vec(spec.end_stop.size),yellow)
	_support_box(cradle,"SoleCrossbar",AssemblyRuntime.vec(spec.bearing),Vector3(1.4,.16,.18),steel)
	bogie = _support_box(self,"FootCarrierBogie",Vector3(11.9,.152,6),Vector3(1.5,.28,1.4),steel)
	mast = _support_box(self,"FootCarrierMast",Vector3(11.9,.5,6.4),Vector3(.16,.6,.16),steel)
	# Flush guides keep the dispatch-to-rail route clear for walking.
	for x in [11.28,12.52]:game.box(self,Vector3(x,.012,7.8),Vector3(.08,.024,5),steel)
	var panel = Node3D.new();add_child(panel);panel.position = AssemblyRuntime.vec(spec.panel)
	game.box(panel,Vector3(.1,.6,0),Vector3(.14,1.2,1.65),steel,true)
	for index in range(3):
		var action: String = ["advance","stop","return"][index]
		var at = Vector3(-.02,1.2,-.52+index*.52)
		var button = game.box(panel,at,Vector3(.12,.16,.20),yellow)
		buttons.append(control_entry(button,action,["Advance foot carrier","Stop carrier","Return foot to dispatch"][index],.14))
		game.sign_panel(panel,["ADVANCE","STOP","RETURN"][index],at+Vector3(-.06,-.2,0),Vector2(.45,.13),32,.0018,-PI/2)
	label = game.sign_panel(panel,"",Vector3(-.04,2,0),Vector2(2.5,.8),32,.002,-PI/2)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;label.width = 1100
	_pose()

func _support_box(parent: Node3D, id: String, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var visual = game.box(parent,at,size,mat,true);visual.name = id
	var body: StaticBody3D = parent.get_child(parent.get_child_count()-1);body.name = id+"Collision"
	hardware.append(body.get_rid());moving_pieces.append({"id":id,"visual":visual,"body":body,"size":size})
	return visual

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for button in buttons:
		var entry = button.duplicate();entry.point = entry.node.global_position;result.append(entry)
	return result

func mounted(model: AssemblyModel = null) -> bool:
	return (game.model if model == null else model).assemblies.foot.parent == "left_leg"

func status_text() -> String:
	if not blocked_reason.is_empty():return "FOOT CARRIER / "+blocked_reason
	if moving:return "GUIDED TRANSFER / "+("Retracting empty cradle from the receiving pads" if handoff == "withdraw" else ("Reacquiring foot support before reverse" if handoff == "capture" else "Located cradle supports the foot"))
	if mounted():return "FOOT SEATED / Receiving sole pads support the foot.\nUse crane task Structural shin. Return reverses the empty leg's foot handoff."
	return "FOOT DISPATCH / "+("Advance raises the prepared foot" if path < .999 else "Advance turns and seats the foot on the leg fixture")

func action_error(action: String) -> String:
	if game.paused:return "Resume before operating the foot carrier."
	if action not in ["advance","stop","return"]:return "Unknown foot carrier command."
	if action == "stop":return "" if moving else "The foot carrier is stopped."
	if moving:return "Stop the carrier before changing direction."
	if not handoff.is_empty():return "" if action == "advance" else "Advance resumes the interrupted support transfer."
	var rail = game.equipment.get_equipment("leg_rail")
	if rail != null and (rail.path > .0001 or rail.moving or not rail.engaged):return "Return the engaged leg holder home before transferring the foot."
	if action == "advance" and path >= 1.9999:return "The foot is already seated on the leg fixture."
	if action == "return":
		if path <= .0001:return "The prepared foot is already at dispatch."
		if mounted():
			var history: Array = game.model.assemblies.left_leg.history
			if history.is_empty() or history.back().slot != "foot":return "Use the crane and reverse the leg construction before returning the foot."
	return game.equipment.busy_reason("foot_transfer",equipment_id)

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():blocked_reason = error;_pose();return error
	if action == "stop":moving = false;goal = path;blocked_reason = "";_pose();return ""
	if not handoff.is_empty():moving = true;blocked_reason = "";return ""
	if action == "return" and mounted():
		handoff = "capture";moving = true;goal = path;blocked_reason = "";return ""
	goal = minf(2,floorf(path+.0001)+1) if action == "advance" else maxf(0,ceilf(path-.0001)-1)
	moving = true;blocked_reason = "";_pose();return ""

func pose_at(value: float) -> Transform3D:
	var index = mini(1,floori(value))
	return Layout.authored_pose(spec.route[index]).interpolate_with(Layout.authored_pose(spec.route[index+1]),value-index)

func _pose() -> void:
	var frame = pose_at(path)
	cradle.global_transform = frame*Transform3D(Basis.IDENTITY,Vector3(0,-withdrawal*.45,0))
	if game.model.assemblies.foot.location == "support:"+spec.support:game.foot.global_transform = frame
	# A grounded telescoping mast follows the real cradle rather than floating.
	var bearing: Vector3 = cradle.global_transform*AssemblyRuntime.vec(spec.bearing)
	bogie.global_position = Vector3(bearing.x,.152,bearing.z)
	mast.global_position = Vector3(bearing.x,(maxf(.30,bearing.y)+.28)/2,bearing.z)
	mast.scale.y = maxf(.02,bearing.y-.28)/.6
	for piece in moving_pieces:
		piece.body.transform = Transform3D(piece.visual.basis.orthonormalized(),piece.visual.position)
		piece.body.get_child(0).shape.size = piece.size*piece.visual.scale
		piece.body.force_update_transform()
		PhysicsServer3D.body_set_state(piece.body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,piece.body.global_transform)
	for id in game.runtime.descendants("foot"):
		var body: CollisionObject3D = game.runtime.node(id)
		if body is AnimatableBody3D:PhysicsServer3D.body_set_mode(body.get_rid(),PhysicsServer3D.BODY_MODE_STATIC)
		body.force_update_transform();PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	label.text = status_text()

func physics(delta: float) -> void:
	if not moving or game.paused:return
	if not handoff.is_empty():
		var target = 1.0 if handoff == "withdraw" else 0.0
		var next_withdrawal = move_toward(withdrawal,target,delta/2)
		blocked_reason = motion_error(path,path,next_withdrawal)
		if not blocked_reason.is_empty():moving = false;_pose();return
		withdrawal = next_withdrawal
		if is_equal_approx(withdrawal,target):
			withdrawal = target
			if handoff == "capture":
				var previous: Transform3D = game.foot.global_transform
				var result: Dictionary = game.model.undo_supported("left_leg",spec.support)
				if not result.ok:blocked_reason = result.error;moving = false;_pose();return
				game.foot.reparent(game);game.foot.global_transform = previous;game.refresh_assembly_collision("left_leg")
				goal = 1
			else:moving = false
			handoff = ""
		_pose();changed.emit();return
	var next = move_toward(path,goal,delta/float(spec.durations[clampi(floori(minf(path,goal)),0,1)]))
	blocked_reason = motion_error(path,next)
	if not blocked_reason.is_empty():moving = false;goal = path;_pose();return
	path = next
	if is_equal_approx(path,goal):
		path = goal;moving = false
		if path >= 1.9999 and not mounted():
			var result: Dictionary = game.model.install_supported("left_leg","foot","foot",spec.support)
			if not result.ok:blocked_reason = result.error;_pose();return
			game.runtime.mount("left_leg","foot","foot");game.refresh_assembly_collision("left_leg")
			handoff = "withdraw";moving = true
	_pose();changed.emit()

func motion_geometry(value: float, pullback: float = -1) -> Array[Dictionary]:
	var frame = pose_at(value)*Transform3D(Basis.IDENTITY,Vector3(0,-(withdrawal if pullback < 0 else pullback)*.45,0))
	var bearing = frame*AssemblyRuntime.vec(spec.bearing)
	var result: Array[Dictionary] = []
	for piece in moving_pieces:
		var pose: Transform3D = frame*Transform3D(Basis.IDENTITY,piece.visual.position)
		var size: Vector3 = piece.size
		if piece.id == "FootCarrierBogie":pose = Transform3D(Basis.IDENTITY,Vector3(bearing.x,.152,bearing.z))
		elif piece.id == "FootCarrierMast":
			pose = Transform3D(Basis.IDENTITY,Vector3(bearing.x,(maxf(.30,bearing.y)+.28)/2,bearing.z));size.y = maxf(.02,bearing.y-.28)
		var shape = BoxShape3D.new();shape.size = size
		result.append({"id":piece.id,"shape":shape,"world":pose,"visual":piece.visual})
	return result

func motion_error(from: float, to: float, pullback: float = -1) -> String:
	var solids: Array[Dictionary] = [];var ignored: Array[RID] = hardware.duplicate()
	for id in game.runtime.nodes:Sweep.collect_rids(game.runtime.node(id),ignored)
	ignored.append_array(layout.hardware)
	if not mounted():Sweep.collect_shapes(game.foot,game.foot.global_transform.affine_inverse(),solids)
	var rig = func(_pose: Transform3D, weight: float) -> Array:
		return motion_geometry(lerpf(from,to,weight),withdrawal if pullback < 0 else lerpf(withdrawal,pullback,weight))
	var groups = [{"shapes":solids,"margin":.001,"error":"Clear the guided foot route ({collider})."},{"shapes_at":rig,"margin":.001,"error":"Clear the foot carrier route ({collider})."}]
	return Sweep.sweep(get_world_3d().direct_space_state,groups,Sweep.steps(pose_at(from),pose_at(to),3,.025),func(weight: float) -> Transform3D:return pose_at(lerpf(from,to,weight)),15,ignored,equipment_id).get("error","")

func busy_reason(subject: String) -> String:
	if subject in ["rail","left_leg"] and moving:return "Wait for the guided foot transfer to stop."
	if subject == "rail" and mounted() and (not handoff.is_empty() or withdrawal != 1):return "Advance the foot carrier to finish withdrawing its empty cradle before moving the leg holder."
	return ""

func undo(owner: String) -> Dictionary:
	if owner == "foot" or owner in ["pad_1","pad_2","pitch"]:return {"handled":true,"error":"The prepared foot stays assembled in M3."}
	if owner == "left_leg" and not game.model.assemblies.left_leg.history.is_empty() and game.model.assemblies.left_leg.history.back().slot == "foot":return {"handled":true,"error":"Use Return on the guided foot carrier to return the foot to dispatch."}
	return {"handled":false,"error":""}

func capture() -> Dictionary:
	return {"version":1,"path":path,"goal":goal,"moving":moving,"blocked_reason":blocked_reason,"handoff":handoff,"withdrawal":withdrawal}

func validate(data: Variant, candidate: AssemblyModel = null, world: Dictionary = {}) -> Array[String]:
	if not Codec.same_keys(data,["version","path","goal","moving","blocked_reason","handoff","withdrawal"]) or not Codec.number(data.version) or data.version != 1:return ["Invalid foot carrier state."]
	if not data.moving is bool or not data.blocked_reason is String or data.handoff not in ["","withdraw","capture"] or not Codec.number(data.withdrawal,1) or data.withdrawal < 0:return ["Invalid foot carrier flags."]
	for key in ["path","goal"]:
		if not Codec.number(data[key],2) or data[key] < 0:return ["Invalid foot carrier progress."]
	if not data.moving and absf(data.path-data.goal)>.0001:return ["Stopped foot carrier has a target."]
	if data.handoff.is_empty() and data.moving and (is_equal_approx(data.path,data.goal) or data.goal != floorf(data.goal) or absf(data.path-data.goal)>1.001):return ["Invalid guided carrier motion."]
	var model: AssemblyModel = game.model if candidate == null else candidate
	var foot: Dictionary = model.assemblies.foot
	if mounted(model):
		if data.path != 2 or data.moving and data.handoff.is_empty():return ["Mounted foot contradicts guided carrier."]
	elif foot.location != "support:"+spec.support or data.withdrawal != 0 or not data.handoff.is_empty():return ["Foot has no carrier support."]
	if world.has("equipment") and (data.moving or not data.handoff.is_empty() or not mounted(model)):
		var peer = world.equipment.get("leg_rail")
		if not peer is Dictionary or not Codec.number(peer.get("path"),3) or not peer.get("moving") is bool or not peer.get("engaged") is bool:return ["Invalid peer holder state."]
		var rail: Dictionary = peer
		if rail.path != 0 or rail.moving or not rail.engaged:return ["Foot carrier transfer requires the engaged holder stopped home."]
		if data.handoff == "capture":
			var history: Array = model.assemblies.left_leg.history
			if history.is_empty() or history.back().slot != "foot":return ["Foot reacquisition requires all structural work removed."]
	if not mounted(model) and world.has("fixtures") and not Codec.to_pose(world.fixtures.foot).is_equal_approx(pose_at(data.path)):return ["Foot transform disagrees with its carrier."]
	return []

func apply(data: Dictionary) -> void:
	path = data.path;goal = data.goal;moving = data.moving;blocked_reason = data.blocked_reason;handoff = data.handoff;withdrawal = data.withdrawal;_pose()
