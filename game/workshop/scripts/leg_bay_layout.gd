extends Node3D
## Leg bay hangar: home rail, pelvis gantry and the trial's source equipment.
## Positions come from assets/leg-bay-layout.json, shared with the generator.
const LAYOUT_PATH = "res://assets/leg-bay-layout.json"
static var data: Dictionary = {}
static var selected_path: String = LAYOUT_PATH

static func select(path: String) -> void:
	if selected_path != path:
		selected_path = path;data = {}

static func layout() -> Dictionary:
	if data.is_empty():data = JSON.parse_string(FileAccess.get_file_as_string(selected_path))
	return data
var game: Node3D
var steel: Material
var dark: Material
var yellow: Material
var rail: Node3D
var carrier: Node3D
var pivot: Node3D
var ladder: Node3D
var mast: MeshInstance3D
var cross_slide: MeshInstance3D
var cross_riser: MeshInstance3D
var cross_upper: MeshInstance3D
var withdrawal_link: MeshInstance3D
var holder_opening = 0.0
var carrier_post: MeshInstance3D
var mast_head: MeshInstance3D
var jaws: Array[Node3D] = []
var contacts: Array[Dictionary] = []
var static_pieces: Array[Dictionary] = []
var moving_pieces: Array[Dictionary] = []
var hardware: Array[RID] = []
var source_pose: Transform3D:
	get:
		var spec: Dictionary = layout().crane
		return authored_pose(spec.tasks[spec.task].source_pose if spec.has("tasks") else spec.source_pose)
var rack_hardware: Array[RID] = []
var cradle_hardware: Array[RID] = []
var crane_bridge: Node3D
var crane_trolley: MeshInstance3D
var blockout: Node3D
var cradle: Node3D

func setup(workshop: Node3D) -> void:
	game = workshop
	steel = game.material(Color("506971"),.55)
	dark = game.material(Color("263a43"),.4)
	yellow = game.material(Color("e8b46b"),.25)
	if layout().has("workshop"):
		blockout = preload("res://scripts/workshop_blockout.gd").new();add_child(blockout)
		blockout.setup(game,layout().workshop)
	else:
		_shell()
		_tracks()
		_gantry()
	_fixture()
	_reservations()

func box(parent: Node3D, id: String, at: Vector3, size: Vector3, mat: Material, solid: bool = true, moving: bool = false) -> MeshInstance3D:
	solid = solid or moving
	var visual: MeshInstance3D = game.box(parent,at,size,mat,solid)
	visual.name = id
	visual.set_meta("layout_piece",id)
	var record = {"id":id,"visual":visual,"size":size,"at":at}
	if solid:
		var body: StaticBody3D = parent.get_child(parent.get_child_count()-1)
		body.name = id+"Collision"
		body.set_meta("layout_piece",id)
		record.body = body
		if moving:hardware.append(body.get_rid())
	if moving:moving_pieces.append(record)
	else:static_pieces.append(record)
	return visual

func sign_at(text: String, at: Vector3, width: float = 3.5, yaw: float = 0.0) -> Label3D:
	return game.sign_panel(self,text,at,Vector2(width,.55),54,.0025,yaw)

func _shell() -> void:
	var floor_material = game.material(Color("7c8886"))
	var wall = game.material(Color("abb9b6"))
	box(self,"Floor",Vector3(6,-.15,15),Vector3(40,.3,48),floor_material)
	for x in [-14.0,26.0]:box(self,"Wall",Vector3(x,11,15),Vector3(.3,22,48),wall)
	for z in [-9.0,39.0]:box(self,"Wall",Vector3(6,11,z),Vector3(40,22,.3),wall)
	box(self,"Roof",Vector3(6,22.15,15),Vector3(40,.3,48),dark)
	for z in [-6,2,10,18,26,34]:
		box(self,"RoofTruss",Vector3(6,21.7,z),Vector3(39.6,.4,.3),steel)
		for x in [-6,6,18]:
			box(self,"Light",Vector3(x,21.45,z),Vector3(6,.08,.22),game.material(Color("fff3db"),0,true),false)
			var light = OmniLight3D.new()
			light.position = Vector3(x,8,z);light.omni_range = 13;light.light_energy = .8
			add_child(light)
	for x in range(-12,25,4):box(self,"Grid",Vector3(x,.003,15),Vector3(.018,.006,47),steel,false)
	for z in range(-8,39,4):box(self,"Grid",Vector3(6,.004,z),Vector3(39,.006,.018),steel,false)
	sign_at(("M3 / COMPLETE STRUCTURAL LEG" if game.profile.trial == "m3" else "M2 / HANDS-ON EQUIPMENT\n"+("Hip retainer" if game.profile.trial == "retention" else "Crane delivery")),Vector3(10,3.5,7),6)
	sign_at("HORIZONTAL LEG STATION",Vector3(12,3.7,19.9),4)
	sign_at("FINAL BAY / SUPPORTED HIP CONNECTION",Vector3(13,14,31),7)

func _tracks() -> void:
	rail = Node3D.new();rail.name = "RailFloor";add_child(rail)
	# Flush rail heads keep the entire walking and axle-extraction aisle usable.
	for center in [layout().rail.x,layout().rail.reserved_x]:
		for dx in [-.62,.62]:box(rail,"Rail",Vector3(center+dx,.012,20.2),Vector3(.10,.024,14.0),steel,false)
		for z in [14.0,17.0,20.0,23.0,26.8]:box(rail,"RailTie",Vector3(center,.006,z),Vector3(1.6,.012,.18),dark,false)
	for x in [10.16,11.36]:box(self,"AxleAisle",Vector3(x,.018,layout().rail.home_z),Vector3(.035,.012,1.1),yellow,false)
	sign_at("KNEE AXLE / 1.2 m CLEAR AISLE",Vector3(9.5,1.9,14.5),2.4,-PI/2)
	for z in [13.95,15.05]:box(self,"AxleAisle",Vector3(10.76,.018,z),Vector3(1.2,.012,.035),yellow,false)
	sign_at("RIGHT LEG ROUTE\nReserved · no second test load",Vector3(15.9,1.3,20),3,-PI/2)
	for x in [10.8,13.0]:box(self,"FootLoadingMark",Vector3(x,.018,9.4),Vector3(.04,.012,2),yellow,false)
	sign_at(("FOOT DISPATCH / GUIDED CARRIER\nAdvance · Stop · Return" if game.profile.trial == "m3" else "FOOT LOADING POSITION\nFoot already fitted for this trial"),Vector3(9,1.6,9.4),3,-PI/2)

func _gantry() -> void:
	var gantry = Node3D.new();gantry.name = "PelvisGantry";add_child(gantry)
	gantry.position = AssemblyRuntime.vec(layout().parent_homes.pelvis)
	for x in [-5.0,5.0]:
		box(gantry,"GantryFoot",Vector3(x,-10.45,4.8),Vector3(1.2,.3,1.5),dark)
		box(gantry,"GantryColumn",Vector3(x,-.3,4.8),Vector3(.4,20.6,.5),steel)
	box(gantry,"GantryCrown",Vector3(0,10.2,4.8),Vector3(10.4,.4,.5),steel)
	box(gantry,"PelvisCrosshead",Vector3(0,.25,4.8),Vector3(10,.5,.5),dark)
	for x in [-.75,.75]:
		box(gantry,"PelvisSupportArm",Vector3(x,.05,2.65),Vector3(.24,.32,4.3),steel)
		box(gantry,"PelvisBearing",Vector3(x,.21,.65),Vector3(.28,.04,.40),yellow)

func _fixture() -> void:
	if layout().has("workshop"):
		cradle=preload("res://scripts/leg_cradle.gd").new();add_child(cradle);cradle.setup(game,layout().workshop.rail)
		hardware=cradle.hardware
		return
	carrier = Node3D.new();carrier.name = "RailBogie";add_child(carrier)
	var bogie_spec: Dictionary = layout().rail.get("bogie",{"center_y":.30,"height":.50,"tail_y":.50,"tail_height":.20})
	box(carrier,"Bogie",Vector3(0,bogie_spec.center_y,0),Vector3(1.5,bogie_spec.height,1.65),dark,true,true)
	box(carrier,"BogieTail",Vector3(0,bogie_spec.tail_y,.8),Vector3(.5,bogie_spec.tail_height,.50),steel,true,true)
	for x in [-.62,.62]:
		for z in [-.55,.55]:box(carrier,"RailWheel",Vector3(x,.12,z),Vector3(.18,.22,.28),yellow,true,true)
	carrier_post = box(carrier,"BogieLiftPost",Vector3(0,.6,.9),Vector3(.3,.1,.3),steel,false,true)
	mast = box(carrier,"TelescopingPivotMast",Vector3(0,.8,.9),Vector3(.25,1,.25),steel,false,true)
	mast_head = box(carrier,"MastCrosshead",Vector3(0,1.35,.6),Vector3(.35,.25,1.45),steel,false,true)
	cross_slide = box(carrier,"TelescopingCrossSlide",Vector3(0,.60,.9),Vector3(.25,.20,.35),steel,false,true)
	pivot = Node3D.new();pivot.name = "KneePivotCarriage";add_child(pivot)
	ladder = Node3D.new();ladder.name = "SupportedRotatingLadder";pivot.add_child(ladder)
	if layout().rail.get("holder",{}).has("support"):
		cross_riser = box(carrier,"CrossSlideRiser",Vector3(0,.6,.9),Vector3(.12,.2,.35),steel,true,true)
		cross_upper = box(carrier,"CrossSlideUpper",Vector3(0,.6,.9),Vector3(.25,.2,.35),steel,true,true)
		withdrawal_link = box(pivot,"WithdrawalBearingLink",Vector3(0,0,.66),Vector3(.30,.20,.28),steel,true,true)
	# All coordinates are canonical leg coordinates relative to the knee.
	for x in [-.38,.38]:box(ladder,"LadderSpine",Vector3(x,-.25,.48),Vector3(.14,6.5,.16),steel,true,true)
	for y in [2.8,7.0]:
		box(ladder,"LadderCrossbar",Vector3(0,y-5.1,.48),Vector3(.90,.18,.16),steel,true,true)
		for side in [-1.0,1.0]:
			var jaw_frame = Node3D.new();ladder.add_child(jaw_frame);jaws.append(jaw_frame)
			box(jaw_frame,"JawLink",Vector3(side*.21,y-5.1,.26),Vector3(.12,.16,.44),steel,true,true)
			var visual = box(jaw_frame,"LocatedJaw",Vector3(side*.21,y-5.1,0),Vector3(.12,.32,.20),yellow,true,true)
			contacts.append({"kind":"rail","visual":visual,"local_y":y,"side":side})
	box(ladder,"PivotBearing",Vector3(0,0,.65 if game.profile.trial == "m3" else .48),Vector3(.95,.25,.30),dark,true,true)

func _reservations() -> void:
	if game.has_equipment("service_crane"):
		_crane_structure()
		if game.profile.trial == "m3":
			_m3_racks()
			return
		var receiver = authored_pose(layout().crane.receiver_pose)
		for rack in [true,false]:
			var fixture_pose = source_pose if rack else receiver
			for along in ([.6,2.2] if rack else [.66,2.26]):
				var center: Vector3 = fixture_pose*Vector3(0,along,.725)
				box(self,"BeamRack" if rack else "BeamCradle",center,Vector3(.60,1.25,.22),steel)
				var body: StaticBody3D = get_child(get_child_count()-1)
				if rack:rack_hardware.append(body.get_rid())
				else:cradle_hardware.append(body.get_rid())

		sign_at("UPPER-LEG BEAM\nGo to rack · Down · attach both magnetic ends",Vector3(7.6,2.7,19.4),4.2)
	else:sign_at("UPPER-LEG BEAM\nAlready fitted in supplied leg",Vector3(7.6,2.7,19.4),4.2)
	for x in [5.2,20.8]:box(self,"ArmApproachEnvelope",Vector3(x,.015,26),Vector3(3.2,.02,6),game.material(Color("507c78")),false)
	box(self,"RearAccessEnvelope",Vector3(13,.015,34.7),Vector3(8,.02,4),game.material(Color("507c78")),false)

## Crane places name the supports at one physical location for the console's
## pickup and delivery labels.
static func crane_place(support_id: String) -> String:
	var places: Dictionary = layout().crane.get("places",{})
	for id in places:
		if support_id in places[id].supports:return id
	return ""

static func place_title(id: String) -> String:
	return layout().crane.get("places",{}).get(id,{}).get("title",id.capitalize())

static func authored_pose(record: Dictionary) -> Transform3D:
	return Transform3D(Basis.from_euler(AssemblyRuntime.vec(record.rotation_degrees)*PI/180.0),AssemblyRuntime.vec(record.position))

func crane_contract(task: String = "") -> Dictionary:
	var spec: Dictionary = layout().crane
	if spec.has("tasks"):spec = spec.tasks[spec.task if task.is_empty() else task]
	var source_frame = authored_pose(spec.source_pose)
	var receiver = authored_pose(spec.receiver_pose)
	var route: Array[Transform3D] = []
	for index in range(spec.route_positions.size()):
		var rotation=Basis.from_euler(AssemblyRuntime.vec(spec.route_rotations[index])*PI/180) if spec.has("route_rotations") else (source_frame.basis if index < 2 else receiver.basis)
		route.append(Transform3D(rotation,AssemblyRuntime.vec(spec.route_positions[index])))
	# Endpoint poses are the same receiving/source frames as their supports.
	route[0] = source_frame;route[route.size()-1] = receiver
	var exclusions: Array[RID]=[];exclusions.assign(rack_hardware+cradle_hardware+hardware)
	if spec.get("payload","")=="assembly" and is_instance_valid(blockout):
		for id in blockout.pieces:
			if id.begins_with(spec.load_uid+"_store_"):exclusions.append(blockout.pieces[id].body.get_rid())
	# A foot fixture standing in for that store releases the foot straight upward
	# out of its carriage clamps, as the store's own masts are excluded above.
	var fixture: Node3D = game.get("foot_fixture")
	if spec.get("payload","")=="assembly" and is_instance_valid(fixture) and spec.load_uid==game.default_parent_id():
		preload("res://scripts/motion_sweep.gd").collect_rids(fixture.carriage,exclusions)
	return {"spec":spec,"source_pose":source_frame,"receiver_pose":receiver,"route":route,"excluded":exclusions,"console_position":AssemblyRuntime.vec(spec.console_position),"support":spec.support,"source_support":spec.source_support,"uid":spec.load_uid,"route_profile":layout().version}

func _crane_structure() -> void:
	if is_instance_valid(blockout):
		crane_bridge = blockout.groups.crane_bridge
		crane_trolley = blockout.pieces.crane_trolley.visual
		return
	var runway: Dictionary = layout().crane.get("runway",{"center_z":16.75,"length":9.5,"columns":[12.8,19.8]})
	for x in [5.2,14.7]:
		for z in runway.columns:
			box(self,"CraneFloorFoot",Vector3(x,.12,z),Vector3(.80,.24,.80),dark)
			box(self,"CraneColumn",Vector3(x,10.4,z),Vector3(.28,20.8,.28),steel)
		box(self,"CraneRunway",Vector3(x,20.9,runway.center_z),Vector3(.35,.4,runway.length),steel)
	crane_bridge = Node3D.new();crane_bridge.name = "ServiceCraneBridge";add_child(crane_bridge)
	box(crane_bridge,"CraneBridge",Vector3(9.95,20.8,0),Vector3(9.85,.4,.32),steel,false)
	crane_trolley = box(crane_bridge,"CraneTrolley",Vector3(source_pose.origin.x,20.63,0),Vector3(.55,.06,.50),yellow,false)
	set_crane_anchor(source_pose.origin+Vector3(0,19.25,1.7))

func set_crane_anchor(point: Vector3) -> void:
	if not is_instance_valid(crane_bridge):return
	crane_bridge.position.z = point.z
	if is_instance_valid(blockout):
		blockout.groups.crane_trolley.position.x = point.x
		blockout.publish()
	else:crane_trolley.position.x = point.x

func set_pose(load_pose: Transform3D, bogie_z: float, mast_x: float) -> void:
	var bogie_offset = .15
	carrier.position = Vector3(mast_x,0,bogie_z+bogie_offset)
	var knee = load_pose*Vector3(0,5.1,0)
	pivot.global_transform = Transform3D(load_pose.basis,knee)
	# Joint support follows the translating knee, while the rail bogie stays grounded.
	var bearing = knee+load_pose.basis*Vector3(0,0,.48)
	var cross_height = .6
	var spec: Dictionary = layout().rail.get("holder",{}).get("support",{})
	var mast_base = lerpf(cross_height,spec.get("high_height",cross_height),holder_opening)
	var mast_height = bearing.y-mast_base
	var post_base: float = layout().rail.get("bogie",{}).get("post_base",.55)
	carrier_post.position.y = (post_base+cross_height)/2
	carrier_post.scale.y = (cross_height-post_base)/.1
	var lateral = bearing.x-mast_x
	mast.position = Vector3(lateral,mast_base+mast_height/2,.9)
	mast_head.position = Vector3(lateral,bearing.y,(.9+bearing.z-bogie_z-bogie_offset)/2)
	mast_head.scale.z = (absf(.9-(bearing.z-bogie_z-bogie_offset))+.25)/1.45
	mast.scale.y = mast_height
	var elbow = maxf(lateral,spec.get("elbow_offset",lateral))
	var low_lateral = elbow if not spec.is_empty() else lateral
	var span = absf(low_lateral)+spec.get("low_overhang",.25)
	cross_slide.position = Vector3(low_lateral/2,cross_height,.9)
	cross_slide.scale.x = span/.25
	if not spec.is_empty():
		cross_slide.visible = holder_opening > .00001
		cross_riser.visible = holder_opening > .00001
		cross_riser.position = Vector3(elbow,(cross_height+mast_base)/2,.9)
		cross_riser.scale = Vector3(1,(mast_base-cross_height+spec.riser_cap)/.2,1)
		cross_upper.position = Vector3((elbow+lateral)/2,mast_base,.9)
		cross_upper.scale.x = (absf(elbow-lateral)+spec.upper_overhang)/.25
		var withdrawal = ladder.position.z
		withdrawal_link.position.z = (spec.withdrawal_start+spec.withdrawal_end+withdrawal)/2
		withdrawal_link.scale.z = (spec.withdrawal_end-spec.withdrawal_start+withdrawal)/.28
	for piece in moving_pieces:
		if not piece.has("body"):continue
		piece.body.position = piece.visual.position
		piece.body.basis = piece.visual.basis.orthonormalized()
		piece.body.get_child(0).shape.size = piece.size*piece.visual.scale
		piece.body.force_update_transform()
		PhysicsServer3D.body_set_state(piece.body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,piece.body.global_transform)

func motion_geometry(load_pose: Transform3D, bogie_z: float, mast_x: float) -> Array[Dictionary]:
	# Pure preview of the same telescoping geometry used by set_pose. Collision
	# sweeps must use the proposed mast sizes and child poses, not the last frame.
	var result: Array[Dictionary] = []
	var knee = load_pose*Vector3(0,5.1,0)
	var bearing = knee+load_pose.basis*Vector3(0,0,.48)
	var cross_height = .6
	var spec: Dictionary = layout().rail.get("holder",{}).get("support",{})
	var mast_base = lerpf(cross_height,spec.get("high_height",cross_height),holder_opening)
	var mast_height = bearing.y-mast_base
	var lateral = bearing.x-mast_x
	var bogie_offset = .15
	var carrier_pose = Transform3D(Basis.IDENTITY,Vector3(mast_x,0,bogie_z+bogie_offset))
	var pivot_pose = Transform3D(load_pose.basis,knee)
	var ladder_pose = pivot_pose*ladder.transform
	for piece in moving_pieces:
		var at: Vector3 = piece.at
		var size: Vector3 = piece.size
		var frame = carrier_pose
		var parent: Node = piece.visual.get_parent()
		if parent == ladder:frame = ladder_pose
		elif parent == pivot:frame = pivot_pose
		elif jaws.has(parent):frame = ladder_pose*parent.transform
		match piece.id:
			"BogieLiftPost":
				var post_base: float = layout().rail.get("bogie",{}).get("post_base",.55)
				at.y = (post_base+cross_height)/2;size.y = cross_height-post_base
			"TelescopingPivotMast":at = Vector3(lateral,mast_base+mast_height/2,.9);size.y = mast_height
			"MastCrosshead":
				at = Vector3(lateral,bearing.y,(.9+bearing.z-bogie_z-bogie_offset)/2)
				size.z = absf(.9-(bearing.z-bogie_z-bogie_offset))+.25
			"TelescopingCrossSlide":
				var low_lateral = maxf(lateral,spec.elbow_offset) if not spec.is_empty() else lateral
				at = Vector3(low_lateral/2,cross_height,.9);size.x = absf(low_lateral)+spec.get("low_overhang",.25)
			"CrossSlideRiser":
				at = Vector3(maxf(lateral,spec.elbow_offset),(cross_height+mast_base)/2,.9)
				size.y = mast_base-cross_height+spec.riser_cap
			"CrossSlideUpper":
				var elbow = maxf(lateral,spec.elbow_offset)
				at = Vector3((elbow+lateral)/2,mast_base,.9);size.x = absf(elbow-lateral)+spec.upper_overhang
			"WithdrawalBearingLink":
				at.z = (spec.withdrawal_start+spec.withdrawal_end+ladder.position.z)/2
				size.z = spec.withdrawal_end-spec.withdrawal_start+ladder.position.z
		var shape = BoxShape3D.new();shape.size = size
		result.append({"id":piece.id,"pose":frame*Transform3D(Basis.IDENTITY,at),"shape":shape,"visual":piece.visual})
	return result

func _m3_racks() -> void:
	for task in layout().crane.tasks:
		var spec: Dictionary = layout().crane.tasks[task]
		if spec.get("payload","")=="assembly":continue
		var frame = authored_pose(spec.source_pose)
		for contact in spec.rack_contacts:
			var top: Vector3 = frame*AssemblyRuntime.vec(contact)
			box(self,"M3Rack_"+task,Vector3(top.x,top.y/2,top.z),Vector3(.20,top.y,.22),steel)
			rack_hardware.append(get_child(get_child_count()-1).get_rid())
		sign_at(spec.title.to_upper(),Vector3(frame.origin.x,2.55,frame.origin.z-.55),2.8)
	if is_instance_valid(cradle):return
	# The sole's two pads remain in contact as the foot is handed to the rail.
	var foot_frame = authored_pose(layout().foot_carrier.receiver_pose)
	var leg_frame = Transform3D(Basis(Vector3.RIGHT,PI/2),Vector3(layout().rail.x,1.35,layout().rail.home_z-layout().rail.pivot))
	for point in layout().foot_carrier.contacts:
		var local: Vector3 = leg_frame.affine_inverse()*(foot_frame*AssemblyRuntime.vec(point))
		# ladder origin is the canonical knee rather than the leg origin.
		local.y -= layout().rail.pivot
		var pad = box(ladder,"FootReceiverContact",local+Vector3(0,-.035,0),AssemblyRuntime.vec(layout().foot_carrier.sole_pad_size),yellow,true,true)
		contacts.append({"kind":"foot","visual":pad})

	for point in layout().foot_carrier.end_stop.centers:
		var local: Vector3 = leg_frame.affine_inverse()*(foot_frame*AssemblyRuntime.vec(point))
		local.y -= layout().rail.pivot
		box(ladder,"FootReceiverEndStop",local,AssemblyRuntime.vec(layout().foot_carrier.end_stop.size),yellow,true,true)

	# Outboard uprights join the receiving sole saddle to the main ladder
	# without running a spine through the foot's rear rails.
	box(ladder,"FootSaddleCrossbar",Vector3(0,-.10-layout().rail.pivot,.43),Vector3(1.76,.08,.16),steel,true,true)
	for side in [-1.0,1.0]:box(ladder,"FootOutboardUpright",Vector3(side*.8,.77-layout().rail.pivot,.43),Vector3(.12,1.74,.16),steel,true,true)
	box(ladder,"FootSupportCrosshead",Vector3(0,1.65-layout().rail.pivot,.48),Vector3(1.76,.12,.16),steel,true,true)
