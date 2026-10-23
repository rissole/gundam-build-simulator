extends Node3D
## Leg bay hangar: home rail, pelvis gantry and the trial's source equipment.
const RAIL_X = 11.9
const HOME_Z = 14.5
const BAY_Z = 26.0
const LIFT_ORIGIN = Vector3(9.6,0,24.3)
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
var carrier_post: MeshInstance3D
var mast_head: MeshInstance3D
var jaws: Array[Node3D] = []
var contacts: Array[Dictionary] = []
var static_pieces: Array[Dictionary] = []
var moving_pieces: Array[Dictionary] = []
var hardware: Array[RID] = []
var source_pose = Transform3D(Basis(Vector3.RIGHT,PI/2),Vector3(7.6,1.35,15.4))
var rack_hardware: Array[RID] = []
var cradle_hardware: Array[RID] = []
var crane_bridge: Node3D
var crane_trolley: MeshInstance3D

func setup(workshop: Node3D) -> void:
	game = workshop
	steel = game.material(Color("506971"),.55)
	dark = game.material(Color("263a43"),.4)
	yellow = game.material(Color("e8b46b"),.25)
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
	sign_at("M2 / HANDS-ON EQUIPMENT\n"+("Hip retainer" if game.profile.trial == "retention" else "Crane delivery"),Vector3(10,3.5,7),6)
	sign_at("HORIZONTAL LEG STATION",Vector3(12,3.7,19.9),4)
	sign_at("FINAL BAY / SUPPORTED HIP CONNECTION",Vector3(13,14,31),7)

func _tracks() -> void:
	rail = Node3D.new();rail.name = "RailFloor";add_child(rail)
	# Flush rail heads keep the entire walking and axle-extraction aisle usable.
	for center in [RAIL_X,14.1]:
		for dx in [-.62,.62]:box(rail,"Rail",Vector3(center+dx,.012,20.2),Vector3(.10,.024,14.0),steel,false)
		for z in [14.0,17.0,20.0,23.0,26.8]:box(rail,"RailTie",Vector3(center,.006,z),Vector3(1.6,.012,.18),dark,false)
	for x in [10.16,11.36]:box(self,"AxleAisle",Vector3(x,.018,HOME_Z),Vector3(.035,.012,1.1),yellow,false)
	sign_at("KNEE AXLE / 1.2 m CLEAR AISLE",Vector3(9.5,1.9,14.5),2.4,-PI/2)
	for z in [13.95,15.05]:box(self,"AxleAisle",Vector3(10.76,.018,z),Vector3(1.2,.012,.035),yellow,false)
	sign_at("RIGHT LEG ROUTE\nReserved · no second test load",Vector3(15.9,1.3,20),3,-PI/2)
	for x in [10.8,13.0]:box(self,"FootLoadingMark",Vector3(x,.018,9.4),Vector3(.04,.012,2),yellow,false)
	sign_at("FOOT LOADING POSITION\nFoot already fitted for this trial",Vector3(9,1.6,9.4),3,-PI/2)

func _gantry() -> void:
	var gantry = Node3D.new();gantry.name = "PelvisGantry";add_child(gantry)
	for x in [8.0,18.0]:
		box(gantry,"GantryFoot",Vector3(x,.15,30.8),Vector3(1.2,.3,1.5),dark)
		box(gantry,"GantryColumn",Vector3(x,10.3,30.8),Vector3(.4,20.6,.5),steel)
	box(gantry,"GantryCrown",Vector3(13,20.8,30.8),Vector3(10.4,.4,.5),steel)
	box(gantry,"PelvisCrosshead",Vector3(13,10.85,30.8),Vector3(10,.5,.5),dark)
	for x in [12.25,13.75]:
		box(gantry,"PelvisSupportArm",Vector3(x,10.65,28.65),Vector3(.24,.32,4.3),steel)
		box(gantry,"PelvisBearing",Vector3(x,10.81,26.65),Vector3(.28,.04,.40),yellow)

func _fixture() -> void:
	carrier = Node3D.new();carrier.name = "RailBogie";add_child(carrier)
	box(carrier,"Bogie",Vector3(0,.30,0),Vector3(1.5,.50,1.65),dark,true,true)
	box(carrier,"BogieTail",Vector3(0,.5,.8),Vector3(.5,.20,.50),steel,true,true)
	for x in [-.62,.62]:
		for z in [-.55,.55]:box(carrier,"RailWheel",Vector3(x,.12,z),Vector3(.18,.22,.28),yellow,true,true)
	carrier_post = box(carrier,"BogieLiftPost",Vector3(0,.6,.9),Vector3(.3,.1,.3),steel,false,true)
	mast = box(carrier,"TelescopingPivotMast",Vector3(0,.8,.9),Vector3(.25,1,.25),steel,false,true)
	mast_head = box(carrier,"MastCrosshead",Vector3(0,1.35,.6),Vector3(.35,.25,1.45),steel,false,true)
	cross_slide = box(carrier,"TelescopingCrossSlide",Vector3(0,.60,.9),Vector3(.25,.20,.35),steel,false,true)
	pivot = Node3D.new();pivot.name = "KneePivotCarriage";add_child(pivot)
	ladder = Node3D.new();ladder.name = "SupportedRotatingLadder";pivot.add_child(ladder)
	# All coordinates are canonical leg coordinates relative to the knee.
	for x in [-.38,.38]:box(ladder,"LadderSpine",Vector3(x,-.25,.48),Vector3(.14,6.5,.16),steel,true,true)
	for y in [2.8,7.0]:
		box(ladder,"LadderCrossbar",Vector3(0,y-5.1,.48),Vector3(.90,.18,.16),steel,true,true)
		for side in [-1.0,1.0]:
			var jaw_frame = Node3D.new();ladder.add_child(jaw_frame);jaws.append(jaw_frame)
			box(jaw_frame,"JawLink",Vector3(side*.21,y-5.1,.26),Vector3(.12,.16,.44),steel,true,true)
			var visual = box(jaw_frame,"LocatedJaw",Vector3(side*.21,y-5.1,0),Vector3(.12,.32,.20),yellow,true,true)
			contacts.append({"kind":"rail","visual":visual,"local_y":y,"side":side})
	box(ladder,"PivotBearing",Vector3(0,0,.48),Vector3(.95,.25,.30),dark,true,true)

func _reservations() -> void:
	if game.has_equipment("service_crane"):
		_crane_structure()
		for x in [7.6,11.9]:
			for z in [16.0,17.6]:
				var top = 1.25
				box(self,"BeamRack" if x < 10 else "BeamCradle",Vector3(x,top/2,z),Vector3(.60,top,.22),steel)
				var body: StaticBody3D = get_child(get_child_count()-1)
				if x < 10:rack_hardware.append(body.get_rid())
				else:cradle_hardware.append(body.get_rid())
		sign_at("UPPER-LEG BEAM\nGo to rack · Down · attach both magnetic ends",Vector3(7.6,2.7,19.4),4.2)
	else:sign_at("UPPER-LEG BEAM\nAlready fitted in supplied leg",Vector3(7.6,2.7,19.4),4.2)
	for x in [5.2,20.8]:box(self,"ArmApproachEnvelope",Vector3(x,.015,26),Vector3(3.2,.02,6),game.material(Color("507c78")),false)
	box(self,"RearAccessEnvelope",Vector3(13,.015,34.7),Vector3(8,.02,4),game.material(Color("507c78")),false)

func crane_contract() -> Dictionary:
	var receiver: Transform3D = game.runtime.slot_pose("left_leg","spar")
	return {"source_pose":source_pose,"receiver_pose":receiver,"route":[source_pose,Transform3D(source_pose.basis,source_pose.origin+Vector3(0,2.17,0)),Transform3D(receiver.basis,receiver.origin+Vector3(0,2.17,.20)),Transform3D(receiver.basis,receiver.origin+Vector3(0,0,.20)),receiver],"excluded":rack_hardware+cradle_hardware+hardware,"console_position":Vector3(4.9,0,21),"support":"m2_service_crane","source_support":"leg_spar_rack","uid":"LG-120__001","route_profile":2}

func _crane_structure() -> void:
	for x in [5.2,14.7]:
		for z in [12.8,19.8]:
			box(self,"CraneFloorFoot",Vector3(x,.12,z),Vector3(.80,.24,.80),dark)
			box(self,"CraneColumn",Vector3(x,10.4,z),Vector3(.28,20.8,.28),steel)
		box(self,"CraneRunway",Vector3(x,20.9,16.75),Vector3(.35,.4,9.5),steel)
	crane_bridge = Node3D.new();crane_bridge.name = "ServiceCraneBridge";add_child(crane_bridge)
	box(crane_bridge,"CraneBridge",Vector3(9.95,20.8,0),Vector3(9.85,.4,.32),steel,false)
	crane_trolley = box(crane_bridge,"CraneTrolley",Vector3(7.6,20.63,0),Vector3(.55,.06,.50),yellow,false)
	set_crane_anchor(Vector3(7.6,20.6,17.1))

func set_crane_anchor(point: Vector3) -> void:
	if not is_instance_valid(crane_bridge):return
	crane_bridge.position.z = point.z
	crane_trolley.position.x = point.x

func set_pose(load_pose: Transform3D, bogie_z: float, mast_x: float) -> void:
	var bogie_offset = .15
	carrier.position = Vector3(mast_x,0,bogie_z+bogie_offset)
	var knee = load_pose*Vector3(0,5.1,0)
	pivot.global_transform = Transform3D(load_pose.basis,knee)
	# Joint support follows the translating knee, while the rail bogie stays grounded.
	var bearing = knee+load_pose.basis*Vector3(0,0,.48)
	var cross_height = .6
	var mast_height = bearing.y-cross_height
	carrier_post.position.y = (.55+cross_height)/2
	carrier_post.scale.y = (cross_height-.55)/.1
	mast.position = Vector3(0,cross_height+mast_height/2,.9)
	mast_head.position = Vector3(0,bearing.y,(.9+bearing.z-bogie_z-bogie_offset)/2)
	mast_head.scale.z = (absf(.9-(bearing.z-bogie_z-bogie_offset))+.25)/1.45
	mast.scale.y = mast_height
	var span = .25
	cross_slide.position = Vector3(0,cross_height,.9)
	cross_slide.scale.x = span/.25
	for piece in moving_pieces:
		if not piece.has("body"):continue
		piece.body.position = piece.visual.position
		piece.body.basis = piece.visual.basis.orthonormalized()
		piece.body.get_child(0).shape.size = piece.size*piece.visual.scale

func motion_geometry(load_pose: Transform3D, bogie_z: float, mast_x: float) -> Array[Dictionary]:
	# Pure preview of the same telescoping geometry used by set_pose. Collision
	# sweeps must use the proposed mast sizes and child poses, not the last frame.
	var result: Array[Dictionary] = []
	var knee = load_pose*Vector3(0,5.1,0)
	var bearing = knee+load_pose.basis*Vector3(0,0,.48)
	var cross_height = .6
	var mast_height = bearing.y-cross_height
	var bogie_offset = .15
	var carrier_pose = Transform3D(Basis.IDENTITY,Vector3(mast_x,0,bogie_z+bogie_offset))
	var pivot_pose = Transform3D(load_pose.basis,knee)
	var ladder_pose = pivot_pose
	for piece in moving_pieces:
		var at: Vector3 = piece.at
		var size: Vector3 = piece.size
		var frame = carrier_pose
		var parent: Node = piece.visual.get_parent()
		if parent == ladder:frame = ladder_pose
		elif parent == pivot:frame = pivot_pose
		elif jaws.has(parent):frame = ladder_pose
		match piece.id:
			"BogieLiftPost":at.y = (.55+cross_height)/2;size.y = cross_height-.55
			"TelescopingPivotMast":at = Vector3(0,cross_height+mast_height/2,.9);size.y = mast_height
			"MastCrosshead":
				at = Vector3(0,bearing.y,(.9+bearing.z-bogie_z-bogie_offset)/2)
				size.z = absf(.9-(bearing.z-bogie_z-bogie_offset))+.25
			"TelescopingCrossSlide":at = Vector3(0,cross_height,.9)
		var shape = BoxShape3D.new();shape.size = size
		result.append({"id":piece.id,"pose":frame*Transform3D(Basis.IDENTITY,at),"shape":shape,"visual":piece.visual})
	return result
