extends "res://tests/kit/harness.gd"
## Supplied stage/geometry measurement only. No walking, captures or acceptance.
const Sweep = preload("res://scripts/motion_sweep.gd")
const Stages = preload("res://scripts/build_stages.gd")
const MainCrane = preload("res://verification/c6/main_crane.gd")
var game: Node
var report = {"schema":1,"runs":[],"robot":[],"equipment":[],"layout_solids":[],"crane":[]}
var stage = ""
var payloads = {}

func _initialize() -> void:call_deferred("run")
func xyz(v: Vector3) -> Array:return [v.x,v.y,v.z]
func bounds(b: AABB) -> Dictionary:return {"min":xyz(b.position),"max":xyz(b.end)}
func stamp(source: String) -> Dictionary:
	return {"stage":stage,"source":source,"time_utc":Time.get_datetime_string_from_system(true)+"Z"}
func shape_box(shape: Shape3D) -> AABB:return shape.get_debug_mesh().get_aabb()
func node_box(node: Node, inverse = Transform3D.IDENTITY) -> AABB:
	var shapes: Array[Dictionary]=[];Sweep.collect_shapes(node,inverse,shapes)
	var result=AABB();var first=true
	for s in shapes:
		var b: AABB=s.transform*shape_box(s.shape)
		result=b if first else result.merge(b);first=false
	return result
func add_equipment(id: String, b: AABB, source: String, extra: Dictionary = {}) -> void:
	var row=stamp(source);row.merge(bounds(b));row.id=id;row.merge(extra);report.equipment.append(row)
func own_meshes(node: Node, owner: String, output: Array) -> void:
	if node.has_meta("assembly_id") and node.get_meta("assembly_id")!=owner:return
	if node is MeshInstance3D and node.mesh!=null:output.append(node.global_transform*node.mesh.get_aabb())
	for child in node.get_children():own_meshes(child,owner,output)
func record_robot() -> void:
	for id in game.model.assemblies:
		if id!="pelvis" and id not in game.runtime.descendants("pelvis"):continue
		if game.model.assemblies.pelvis.location!="support:pelvis_gantry":continue
		var boxes: Array=[];own_meshes(game.runtime.node(id),id,boxes)
		if boxes.is_empty():continue
		var box: AABB=boxes[0]
		for b in boxes:box=box.merge(b)
		var row=stamp("AssemblyRuntime.node("+id+") recursive mesh bounds excluding child assembly roots")
		row.id=id;row.merge(bounds(box));report.robot.append(row)
func capture_payloads() -> void:
	# Snapshot prepared source before downstream children are mounted.
	var at={"pelvis":["foot","right_foot","chest","core","backpack","arm_cassette","left_arm","right_arm","left_pauldron","right_pauldron","head_baseplate","head_left","head_right","head_top","head_crown"],"left_leg_build":["pelvis"]}
	for id in at.get(stage,[]):
		var node=game.runtime.node(id)
		if node!=null:
			var box=node_box(node,node.global_transform.affine_inverse())
			if id=="arm_cassette":
				for part in game.equipment.get_equipment("arm_cassette").transport_shapes():box=box.merge(part.transform*shape_box(part.shape))
			payloads[id]=bounds(box)
func measure_rail() -> void:
	var rail=game.equipment.get_equipment("leg_rail");var saved=rail.capture()
	var loaded=game.runtime.node(rail.active_assembly)
	var local=node_box(loaded,loaded.global_transform.affine_inverse())
	for i in range(61):
		var p=float(i)/20
		var state=saved.duplicate(true);state.path=p;state.index_x=rail.spec.lanes[rail.lane];state.bolster=1.0
		var pose=rail.snapshot_pose(state)
		var box: AABB=pose.frame*local
		var geometry=game.leg_layout.cradle.geometry(pose.frame,pose.bogie_x,pose.bogie_z,pose.opening,pose.compact,pose.bolster)
		for entry in geometry:
			var e: Dictionary=entry
			var eb: AABB=e.pose*AABB(-e.size/2,e.size)
			box=box.merge(eb)
		add_equipment("rail/"+rail.lane+"/%02d"%i,box,"indexed_leg_rail.gd:snapshot_pose + leg_cradle.geometry",{"path":p,"sampling":"0.05 path; conservative union with 0.40 m interpolation inflation in collector"})
func measure_fixed() -> void:
	for id in game.leg_layout.blockout.pieces:
		var p=game.leg_layout.blockout.pieces[id]
		if not p.has("shape"):continue
		p.body.force_update_transform()
		var world: Transform3D=PhysicsServer3D.body_get_state(p.body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
		var row=stamp("workshop-layout.json:workshop.solids/"+id);row.id=id
		row.merge(bounds(world*p.shape.transform*shape_box(p.shape.shape)));row.enabled=not p.shape.disabled
		report.layout_solids.append(row)
	for side in ["left","right"]:
		var lift=game.equipment.get_equipment(side+"_lift");var saved=lift.capture()
		for height in lift.stops:
			lift.height=height;lift._pose();lift.deck.force_update_transform()
			add_equipment("lift/"+side+"/"+str(height),node_box(lift.deck),"work_access_lift.gd:_pose",{"height":height})
		var lift_shapes: Array[Dictionary]=[];Sweep.collect_shapes(lift,Transform3D.IDENTITY,lift_shapes)
		var moving_shapes: Array[Dictionary]=[];Sweep.collect_shapes(lift.deck,Transform3D.IDENTITY,moving_shapes)
		for i in lift_shapes.size():
			var e=lift_shapes[i];add_equipment("lift/"+side+"/piece/%02d"%i,e.transform*shape_box(e.shape),"work_access_lift.gd actual shapes; car at highest stop",{"moving_with_car":i<moving_shapes.size()})
		lift.apply(saved)
	var mobile=game.equipment.get_equipment("mobile_platform");var ms=mobile.capture()
	for dock in mobile.spec.docks:
		mobile.dock=dock;mobile.from_dock=dock;mobile.to_dock=dock;mobile.travel=0;mobile.mode="";mobile.height=.15;mobile._pose()
		add_equipment("mobile/"+dock,node_box(mobile),"mobile_work_platform.gd:_pose",{"dock":dock})
	mobile.apply(ms)
	# Every real collider in the door band, not the visual rectangle.
	var collisions: Array[Dictionary]=[];Sweep.collect_shapes(game,Transform3D.IDENTITY,collisions)
	for s in collisions:
		var b: AABB=s.transform*shape_box(s.shape)
		if b.end.z>=38.3 and b.position.z<=39.2 and b.end.x>2.25 and b.position.x<23.75:
			add_equipment("door/collision/"+str(report.equipment.size()),b,"runtime collision scan at door Z38.3..39.2")
func measure_backpack() -> void:
	var pack=game.equipment.get_equipment("backpack_hinge");var saved=pack.capture()
	for i in range(41):
		pack.angle=float(i)/40;pack._pose()
		add_equipment("backpack/%02d"%i,node_box(game.runtime.node("backpack")),"backpack_hinge.gd:_pose",{"angle_fraction":pack.angle,"sampling":"0.025 angle fraction; collector inflates 0.10 m"})
	pack.apply(saved)
func crane_rig(crane: Node, frame: Transform3D, index: int) -> Array:
	if crane.config.spec.has("rig_adapter"):
		return game.equipment.get_equipment(crane.config.spec.rig_adapter).rig_solids(frame,0)
	if crane.config.spec.has("spreader_points"):
		return crane.rig_solids(frame)
	# Main's legacy two-point and foot rigs have no spreader_points and cannot
	# call rig_solids(). Reconstruct their visible _configure_rig_bar/_refresh
	# geometry, with authored station beam heights for legacy route endpoints.
	var spec: Dictionary=crane.config.spec
	var head: Transform3D
	var center=Vector3.ZERO
	for point in crane.points:center+=point
	center/=crane.points.size()
	var anchors: Array=[]
	var low=Vector3(INF,INF,INF);var high=-low
	var bar_center=Vector3.ZERO
	if spec.has("rig_clearance"):
		head=crane._load_beam(frame)
		for point in crane.points:
			var world: Vector3=crane.source_pose*point;low=low.min(world);high=high.max(world)
			var offset: Vector3=frame.basis*(point-center)
			anchors.append(head.origin+Vector3(offset.x,0,offset.z))
	else:
		head=Transform3D(Basis.IDENTITY,frame.origin)
		head.origin.y=frame.origin.y+.8 if index==0 else float(spec.up_y) if index<=crane.route.size()-3 else frame.origin.y+.88
		for point in crane.points:
			var at=Vector3(point.x,0,point.y);low=low.min(at);high=high.max(at)
			anchors.append(head.origin+at)
		bar_center.z=(low.z+high.z)/2
	var bar=BoxShape3D.new();bar.size=Vector3(high.x-low.x+.28,.18,high.z-low.z+.34)
	var result: Array=[{"shape":bar,"world":head.translated(bar_center),"rig_kind":"bar"}]
	var eye: Vector3=head.origin+bar_center
	var pairs=[[eye,Vector3(eye.x,float(spec.get("overhead_y",20.6)),eye.z),.035]]
	for i in crane.points.size():
		var contact: Vector3=crane._cable_position(frame,i)
		pairs.append([anchors[i],contact,.025])
		var end=BoxShape3D.new();end.size=Vector3(.12,.09,.12)
		result.append({"shape":end,"world":crane._end_transform(frame,i),"rig_kind":"contact"})
	for pair in pairs:
		var direction: Vector3=pair[1]-pair[0]
		var line=BoxShape3D.new();line.size=Vector3(pair[2],maxf(.001,direction.length()),pair[2])
		var basis=Basis(Quaternion(Vector3.UP,direction.normalized())) if direction.length()>.0001 else Basis.IDENTITY
		result.append({"shape":line,"world":Transform3D(basis,(pair[0]+pair[1])/2),"rig_kind":"line"})
	return result
func measure_crane() -> void:
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://verification/c6/main-layout.json"))
	var crane=MainCrane.new();crane.game=game;crane.layout=game.leg_layout;crane.equipment_id="service_crane"
	var previous=game.equipment.get_equipment("service_crane");var registry_index=game.equipment._items.find(previous)
	game.equipment._items[registry_index]=crane
	for key in data.crane.tasks:
		var spec: Dictionary=data.crane.tasks[key];var source=game.leg_layout.authored_pose(spec.source_pose);var receiver=game.leg_layout.authored_pose(spec.receiver_pose)
		var route: Array[Transform3D]=[]
		for i in spec.route_positions.size():
			var basis=Basis.from_euler(AssemblyRuntime.vec(spec.route_rotations[i])*PI/180) if spec.has("route_rotations") else (source.basis if i<2 else receiver.basis)
			route.append(Transform3D(basis,AssemblyRuntime.vec(spec.route_positions[i])))
		route[0]=source;route[-1]=receiver
		crane.task=key;crane._configure_task({"spec":spec,"source_pose":source,"receiver_pose":receiver,"route":route})
		for i in crane.END_IDS.size():crane.endpoints[crane.END_IDS[i]]={"state":"attached","point":crane.POINT_IDS[i]}
		var local: AABB
		if payloads.has(spec.load_uid):
			var b=payloads[spec.load_uid];local=AABB(AssemblyRuntime.vec(b.min),AssemblyRuntime.vec(b.max)-AssemblyRuntime.vec(b.min))
		else:
			var mesh=game.source[spec.load_uid];local=mesh.mesh.get_aabb()
		if spec.has("rig_adapter") and key!="cassette":
			for part in game.equipment.get_equipment(spec.rig_adapter).transport_shapes():local=local.merge(part.transform*shape_box(part.shape))
		var row=stamp("main service_crane.gd authored route + baseline runtime payload/adapter")
		row.id=key;row.authored_positions=spec.route_positions;row.authored_rotations=spec.get("route_rotations",[])
		row.payload_local=bounds(local);row.poses=[]
		for index in range(route.size()):
			var frame=route[index];var box: AABB=frame*local;var parts: Array=[]
			for solid in crane_rig(crane,frame,index):
				var rb: AABB=solid.world*shape_box(solid.shape)
				box=box.merge(rb);parts.append({"kind":solid.get("rig_kind","adapter"),"bounds":bounds(rb)})
			row.poses.append({"index":index,"bounds":bounds(box),"rig_parts":parts})
		report.crane.append(row)
	game.equipment._items[registry_index]=previous
	crane.free()
func run() -> void:
	game=await boot_workshop()
	var stages=Stages.new(game)
	for s in Stages.ALL:
		stage=s
		var errors=stages.stage_errors(stage)
		if not errors.is_empty():push_error(str(errors));quit(1);return
		capture_payloads();record_robot()
		if stage=="left_leg_dock" or stage=="right_leg_dock":measure_rail()
		if stage=="left_arm":measure_backpack()
		if stage=="complete":measure_fixed()
		if stage=="left_leg_build":measure_crane()
		if stage in ["core","backpack"]:
			for id in game.leg_layout.blockout.pieces:
				if "core" in id or "service" in id:
					var p=game.leg_layout.blockout.pieces[id]
					if p.has("shape") and not p.shape.disabled:add_equipment("core_fixture/"+stage+"/"+id,node_box(p.body),"workshop-layout.json:workshop.solids/"+id)
		report.runs.append({"stage":stage,"outcome":"stage contract reached; supplied geometry measured","time_utc":Time.get_datetime_string_from_system(true)+"Z"})
		print("FINE PROBE STAGE ",stage," PASS")
		if stage=="complete":break
		var error=stages.complete(stage)
		if not error.is_empty():push_error(error);quit(1);return
		await process_frame
	write_evidence("res://verification/c6/runtime.json",report)
	game.free();quit(0)
