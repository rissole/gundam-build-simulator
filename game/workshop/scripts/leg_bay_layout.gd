extends Node3D
## Robot workshop hangar: blockout, leg cradle, crane structure and source racks.
## Positions come from assets/workshop-layout.json, shared with the generators.
const LAYOUT_PATH = "res://assets/workshop-layout.json"
static var data: Dictionary = {}

static func layout() -> Dictionary:
	if data.is_empty():data = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	return data
var game: Node3D
var steel: Material
var static_pieces: Array[Dictionary] = []
var moving_pieces: Array[Dictionary] = []
var hardware: Array[RID] = []
var rack_hardware: Array[RID] = []
var crane_bridge: Node3D
var blockout: Node3D
var cradle: Node3D

func setup(workshop: Node3D) -> void:
	game = workshop
	steel = game.material(Color("506971"),.55)
	blockout = preload("res://scripts/workshop_blockout.gd").new();add_child(blockout)
	blockout.setup(game,layout().workshop)
	cradle = preload("res://scripts/leg_cradle.gd").new();add_child(cradle);cradle.setup(game,layout().workshop.rail)
	hardware = cradle.hardware
	if game.has_equipment("service_crane"):
		crane_bridge = blockout.groups.crane_bridge
		_source_racks()

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
	var exclusions: Array[RID]=[];exclusions.assign(rack_hardware+hardware)
	if spec.get("payload","")=="assembly":
		for id in blockout.pieces:
			if id.begins_with(spec.load_uid+"_store_"):exclusions.append(blockout.pieces[id].body.get_rid())
	# A foot fixture standing in for that store releases the foot straight upward
	# out of its carriage clamps, as the store's own masts are excluded above.
	var fixture: Node3D = game.get("foot_fixture")
	if spec.get("payload","")=="assembly" and is_instance_valid(fixture) and spec.load_uid==game.default_parent_id():
		preload("res://scripts/motion_sweep.gd").collect_rids(fixture.carriage,exclusions)
	return {"spec":spec,"source_pose":source_frame,"receiver_pose":receiver,"route":route,"excluded":exclusions,"console_position":AssemblyRuntime.vec(spec.console_position),"support":spec.support,"source_support":spec.source_support,"uid":spec.load_uid,"route_profile":layout().version}

func set_crane_anchor(point: Vector3) -> void:
	if not is_instance_valid(crane_bridge):return
	var bridge: Transform3D = crane_bridge.transform
	var trolley: Transform3D = blockout.groups.crane_trolley.transform
	bridge.origin.z = point.z
	trolley.origin.x = point.x
	blockout.apply_frames({"crane_bridge":bridge,"crane_trolley":trolley})

func _source_racks() -> void:
	for task in layout().crane.tasks:
		var spec: Dictionary = layout().crane.tasks[task]
		if spec.get("payload","")=="assembly":continue
		var frame = authored_pose(spec.source_pose)
		for contact in spec.rack_contacts:
			var top: Vector3 = frame*AssemblyRuntime.vec(contact)
			box(self,"CraneRack_"+task,Vector3(top.x,top.y/2,top.z),Vector3(.20,top.y,.22),steel)
			rack_hardware.append(get_child(get_child_count()-1).get_rid())
		sign_at(spec.title.to_upper(),Vector3(frame.origin.x,2.55,frame.origin.z-.55),2.8)
