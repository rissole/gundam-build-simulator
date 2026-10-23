extends "res://scripts/m1_layout.gd"
## Accepted M1 dimensions with real M2 source and receiving contacts.
var source_pose = Transform3D(Basis(Vector3.RIGHT,PI/2),Vector3(7.6,1.35,15.4))
var rack_hardware: Array[RID] = []
var cradle_hardware: Array[RID] = []
var crane_bridge: Node3D
var crane_trolley: MeshInstance3D

func setup(workshop: Node3D) -> void:
	super.setup(workshop)
	for child in get_children():
		if child is Label3D:
			child.text = child.text.replace("M1 / WORKSHOP SCALE TRIAL\nPreassembled test leg · session only","M2 / HANDS-ON EQUIPMENT\n"+("Hip retainer" if game.m2_trial == "retention" else "Crane delivery")).replace("FINAL BAY / SAMPLE DOCK","FINAL BAY / SUPPORTED HIP CONNECTION")

func _reservations() -> void:
	if game.m2_trial == "crane":
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
