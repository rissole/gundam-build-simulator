extends "res://scripts/equipment.gd"
## Captive telescopic transport bridges. Retention enables their local handles;
## only arriving at the engaged stop locks a joint. Every side is independent.
const Sweep = preload("res://scripts/motion_sweep.gd")
const Codec = preload("res://scripts/pose_codec.gd")
var fixtures: Array[Dictionary] = []
var moving = false
var active = ""
var blocked_reason = ""

static func command_ids(specs: Array) -> Array:
	var result: Array = []
	for owner in ["left_leg","right_leg"]:
		for spec in specs:
			for side in ["outboard","inboard"]:result.append("engage:"+owner+":"+spec.key+":"+side)
	return result

func setup(workshop: Node) -> void:
	game = workshop;equipment_id = "joint_restraints"
	var steel = game.material(Color("506971"),.45)
	var yellow = game.material(Color("e8b46b"),.3)
	for owner in ["left_leg","right_leg"]:
		if not game.model.assemblies.has(owner):continue
		for spec in preload("res://scripts/leg_bay_layout.gd").layout().restraints:
			for side in ["outboard","inboard"]:
				var root = Node3D.new();root.name = owner+"_"+spec.key+"_"+side;add_child(root)
				var sign_x = -1 if side=="outboard" else 1
				var fixture = {"id":owner+":"+spec.key+":"+side,"owner":owner,"spec":spec,"side":side,"node":root,"pieces":[],"progress":0.0,"goal":0.0,"locked":false,"posed":-1.0,"physics_pose":null,"dirty":true}
				for piece in spec.pieces:
					if signf(piece.position[0])!=sign_x:continue
					var visual = game.box(root,Vector3.ZERO,AssemblyRuntime.vec(piece.size),yellow if piece.get("contact",false) else steel,true)
					var body = root.get_child(root.get_child_count()-1)
					body.set_meta("brace_id",fixture.id)
					fixture.pieces.append({"spec":piece,"visual":visual,"body":body})
				var handle = preload("res://scripts/equipment_button.gd").make(game,root,Vector3.ZERO,"BRACE",PI,true)
				handle.mesh.size=Vector3(.12,.12,.055)
				fixture["handle"]=handle
				fixtures.append(fixture)
	game.model.changed.connect(sync)
	sync()

func _fixture(id: String) -> Dictionary:
	for fixture in fixtures:
		if fixture.id==id:return fixture
	return {}

## Braces start on real crane stock, never the empty logical leg. Installed roots
## become direct leg children, so rail release and later mounting keep them.
func sync() -> void:
	var crane = game.equipment.get_equipment("service_crane")
	for fixture in fixtures:
		var spec: Dictionary=fixture.spec
		var fitted: bool=not game.model.assemblies[fixture.owner].slots[spec.attachment].is_empty()
		var parent: Node3D = game.runtime.node(fixture.owner) if fitted else null
		var pose = Transform3D.IDENTITY
		if not fitted and crane!=null:
			var uid: String=game.model.slot_definition(fixture.owner,spec.attachment).pose_source
			parent=crane.stock_bodies.get(uid)
			pose=game.runtime.local_slot_pose(fixture.owner,spec.attachment).affine_inverse()
		if parent!=null:
			if fixture.node.get_parent()!=parent:fixture.node.reparent(parent,false)
			if not fixture.node.transform.is_equal_approx(pose):fixture.node.transform=pose
		fixture.node.visible=parent!=null
		_pose(fixture)
	sync_pose()

func _piece_pose(fixture: Dictionary, piece: Dictionary, progress: float) -> Dictionary:
	var spec: Dictionary=fixture.spec
	var point = AssemblyRuntime.vec(piece.position)
	var size = AssemblyRuntime.vec(piece.size)
	var moving_y: float=lerpf(spec.parked_y,spec.moving_y,progress)
	if piece.id=="RigidLockLink":
		point.y=(moving_y+float(spec.fixed_y))*.5
		size.y=absf(moving_y-float(spec.fixed_y))+.24
	elif is_equal_approx(point.y,float(spec.moving_y)):point.y=moving_y
	if fixture.owner=="right_leg":point.x=-point.x
	return {"point":point,"size":size}

func _pose(fixture: Dictionary) -> void:
	for piece in fixture.pieces:
		var layer=1 if fixture.node.visible else 0
		if piece.body.collision_layer!=layer:piece.body.collision_layer=layer
	if fixture.posed==fixture.progress:return
	fixture.posed=fixture.progress;fixture.dirty=true
	for piece in fixture.pieces:
		var at = _piece_pose(fixture,piece.spec,fixture.progress)
		piece.visual.position=at.point;piece.visual.mesh.size=at.size
		piece.body.position=at.point;piece.body.get_child(0).shape.size=at.size
		piece.body.collision_layer=1 if fixture.node.visible else 0
	var side = -1.0 if fixture.side=="outboard" else 1.0
	if fixture.owner=="right_leg":side=-side
	fixture.handle.get_parent().position=Vector3(side*.74,float(fixture.spec.fixed_y),-.5)
	fixture.handle.rotation.x=lerpf(0,PI/2,fixture.progress)

func sync_pose() -> void:
	for fixture in fixtures:
		var pose: Transform3D=fixture.node.global_transform
		if not fixture.dirty and fixture.physics_pose!=null and fixture.physics_pose.is_equal_approx(pose):continue
		fixture.physics_pose=pose;fixture.dirty=false
		for piece in fixture.pieces:
			piece.body.force_update_transform()
			PhysicsServer3D.body_set_state(piece.body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,piece.body.global_transform)

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for fixture in fixtures:
		if not fixture.node.visible:continue
		var withdrawing: bool=fixture.locked or (active==fixture.id and moving and not blocked_reason.is_empty() and fixture.goal==1)
		var action: String=("stow:" if withdrawing else "engage:")+fixture.id
		result.append(control_entry(fixture.handle,action,_subject(fixture)+": "+command_label(action),.11,{"point":fixture.handle.global_position,"manual_command":"engage:"+fixture.id,"control_id":fixture.id,"allowed":[game.runtime.node(fixture.owner)],"allow_body_hit":true}))
	return result

func _subject(fixture: Dictionary) -> String:
	return fixture.owner.trim_suffix("_leg").capitalize()+" "+str(fixture.spec.label).to_lower()+" · "+fixture.side+" handle"
func manual_commands() -> Array:return command_ids(preload("res://scripts/leg_bay_layout.gd").layout().restraints)
func command_label(action: String, _task: String="") -> String:return "Stow brace" if action.begins_with("stow:") else "Engage brace"
func manual_subject(objective: Dictionary) -> String:
	var fixture = _fixture(str(objective.get("command","")).trim_prefix("engage:"))
	return _subject(fixture) if not fixture.is_empty() else ""
func manual_hint(_objective: Dictionary) -> String:return "use the handle beside the joint"
func manual_state() -> Dictionary:
	var result: Dictionary={}
	for fixture in fixtures:result[fixture.id]=fixture.locked
	return result
func manual_effect(objective: Dictionary) -> Dictionary:return {str(objective.command).trim_prefix("engage:"):true}

func _supported(owner: String) -> bool:
	var rail = game.equipment.get_equipment("leg_rail")
	return game.model.assemblies[owner].location=="support:leg_holder" and rail!=null and rail.active_assembly==owner and rail.engaged and not rail.moving and rail.mode.is_empty() and rail.release==0 and rail.path==0 and rail.roll==0 and rail.roll_height==0 and is_equal_approx(rail.index_x,rail.spec.station_x) and rail.bolster==0

func action_error(action: String) -> String:
	if not action.begins_with("engage:") and not action.begins_with("stow:"):return "Unknown brace control."
	var fixture = _fixture(action.substr(action.find(":")+1))
	if fixture.is_empty():return "Unknown brace handle."
	if game.paused:return "Resume before operating a brace."
	if moving and (active!=fixture.id or blocked_reason.is_empty()):return "Wait for the brace to reach its stop."
	if not _supported(fixture.owner):return "Return the stationary leg rig to construction height with its foot bolster engaged before changing a brace."
	if action.begins_with("engage:") and not game.model.milestone(fixture.owner,fixture.spec.milestone):return "Secure this joint's retaining hardware before engaging its brace."
	var crane = game.equipment.get_equipment("service_crane")
	if crane!=null and crane.moving:return "Stop the crane before operating a brace."
	# The upper yoke contacts the beam at Y6.10; a bare fork stops at Y5.92.
	# Until the beam is retained, its knee bridge can only open under the crane.
	if action.begins_with("stow:") and fixture.spec.key=="knee" and not game.model.milestone(fixture.owner,"spar_secured"):
		var supported: bool=crane!=null and crane.has_method("attached_count") and crane.load_owner==fixture.owner and crane.slot=="fork" and crane.station=="receiver" and not crane.raised and crane.motion.is_empty() and crane.attached_count()==crane.required_ends
		if not supported:return "Reattach both magnetic connectors with the crane down at the fork before stowing its knee braces."
	return game.hands.error(equipment_id)

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():return error
	var fixture = _fixture(action.substr(action.find(":")+1))
	fixture.goal=0.0 if action.begins_with("stow:") else 1.0
	if fixture.progress==fixture.goal:return ""
	# Unlock at the start of withdrawal; partial travel never proves retention.
	fixture.locked=false;active=fixture.id;moving=true;blocked_reason=""
	return ""

func physics(delta: float) -> void:
	sync()
	if not moving or game.paused:return
	var fixture = _fixture(active)
	var next: float=move_toward(fixture.progress,fixture.goal,delta*.8)
	var ahead = EquipmentRegistry.Motion.ahead(fixture.progress,fixture.goal,next-fixture.progress,absf(float(fixture.spec.moving_y)-float(fixture.spec.parked_y)))
	blocked_reason=motion_error(fixture,fixture.progress,ahead)
	if not blocked_reason.is_empty():return
	motion_obstruction={};fixture.progress=next;_pose(fixture);sync_pose()
	if is_equal_approx(next,fixture.goal):
		fixture.progress=fixture.goal;fixture.locked=fixture.goal==1;moving=false;active=""
	var rail = game.equipment.get_equipment("leg_rail")
	if rail!=null:rail.load_geometry.invalidate()

func motion_error(fixture: Dictionary, from: float, to: float) -> String:
	var excluded: Array[RID]=[]
	# These bridges intentionally seat onto this leg's contact pads and telescope
	# through their own captive sleeves. Unrelated equipment and people stay live.
	Sweep.collect_rids(game.runtime.node(fixture.owner),excluded)
	var shapes_at=func(_pose: Transform3D,t: float) -> Array:
		var result: Array=[]
		for piece in fixture.pieces:
			var at=_piece_pose(fixture,piece.spec,lerpf(from,to,t))
			var shape=BoxShape3D.new();shape.size=at.size
			result.append({"shape":shape,"world":fixture.node.global_transform*Transform3D(Basis.IDENTITY,at.point)})
		return result
	var distance=absf(to-from)*absf(float(fixture.spec.moving_y)-float(fixture.spec.parked_y))
	return EquipmentRegistry.Motion.sweep(self,[{"shapes_at":shapes_at}],maxi(1,ceili(distance/.025)),func(_t):return Transform3D.IDENTITY,excluded).get("error","")

func required_error(owner: String, milestone: String="") -> String:
	for fixture in fixtures:
		if fixture.owner!=owner or (not milestone.is_empty() and fixture.spec.milestone!=milestone):continue
		if game.model.milestone(owner,fixture.spec.milestone) and not fixture.locked:return "Engage the "+_subject(fixture).to_lower()+" before releasing support or moving the leg."
	return ""

func busy_reason(subject: String) -> String:
	if moving and subject in ["rail","source_roll","crane"]:return "Wait for the transport brace to lock."
	return ""
func access_error(owner: String) -> String:
	if moving and _fixture(active).owner==owner:return "Wait for the transport brace to reach its stop."
	return ""
func undo(owner: String) -> Dictionary:
	var history: Array=game.model.assemblies[owner].history
	if history.is_empty():return {"handled":false,"error":""}
	for fixture in fixtures:
		if fixture.owner!=owner or (not fixture.locked and fixture.progress==0):continue
		var protected: Array=game.runtime.definition(owner).milestones[fixture.spec.milestone].duplicate()
		protected.append(fixture.spec.attachment)
		if history.back().slot in protected:return {"handled":true,"error":"Stow the joint's braces on the stationary leg rig before removing their attachments or retaining hardware."}
	return {"handled":false,"error":""}
func status_text() -> String:return blocked_reason

## Registry snapshots moving braces at their last stop. Lock evidence itself
## stays false throughout partial travel, including withdrawal.
func capture() -> Dictionary:
	var locked: Dictionary={}
	for fixture in fixtures:locked[fixture.id]=fixture.locked
	return {"version":1,"locked":locked}
func validate(data: Variant, candidate: AssemblyModel=null, _world: Dictionary={}) -> Array[String]:
	if not Codec.same_keys(data,["version","locked"]) or data.version!=1 or not Codec.same_keys(data.locked,manual_state().keys()):return ["Invalid transport brace snapshot."]
	var model: AssemblyModel=game.model if candidate==null else candidate
	for fixture in fixtures:
		if not data.locked[fixture.id] is bool:return ["Invalid transport brace lock."]
		if data.locked[fixture.id] and not model.milestone(fixture.owner,fixture.spec.milestone):return ["A locked brace has no retained receiving joint."]
	return []
func apply(data: Dictionary) -> void:
	moving=false;active="";blocked_reason="";motion_obstruction={}
	for fixture in fixtures:
		fixture.locked=bool(data.locked[fixture.id]);fixture.progress=1.0 if fixture.locked else 0.0;fixture.goal=fixture.progress
	sync()
