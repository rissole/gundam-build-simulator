extends "res://tests/save_resume_test.gd"
## Adversarial equipment snapshots and mesh/physics review.
## Controller pose sampling is geometry evidence; The walked suites prove input journeys.
var attacks = 0
var rejected = 0
var defects: Array[Dictionary] = []

func cloned(value: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(value))

func branch(data: Dictionary, path: Array) -> Dictionary:
	var target = data
	for key in path:target = target[key]
	return target

func attack(snapshot: Dictionary, path: Array, key: String, replacement: Variant, erase: bool) -> void:
	var forged = cloned(snapshot)
	var target = branch(forged,path)
	if erase:target.erase(key)
	else:target[key] = replacement
	var before = JSON.stringify(game.saves.capture())
	var errors: Array[String] = game.saves.validate(forged)
	attacks += 1
	if not errors.is_empty():rejected += 1
	else:defects.append({"trial":game.profile.trial,"path":str(path)+"/"+key,"attack":"missing" if erase else "mistyped","accepted":true})
	if not errors.is_empty() and game.saves.apply_snapshot(forged):defects.append({"path":str(path)+"/"+key,"invalid_applied":true})
	if before != JSON.stringify(game.saves.capture()):defects.append({"path":str(path)+"/"+key,"mutation":true})

func fuzz(snapshot: Dictionary, path: Array) -> void:
	var data = branch(snapshot,path)
	for key in data:
		attack(snapshot,path,key,null,true)
		var value = data[key]
		attack(snapshot,path,key,[] if value is String or value is Dictionary else "mistyped",false)
		if value is Dictionary and not value.is_empty():fuzz(snapshot,path+[key])

func collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and node.mesh != null:output.append(node)
	for child in node.get_children():collect_meshes(child,output)

func reject_semantic(snapshot: Dictionary, label: String) -> void:
	var before = JSON.stringify(game.saves.capture())
	var errors: Array[String] = game.saves.validate(snapshot)
	expect(not errors.is_empty() and not game.saves.apply_snapshot(snapshot) and before == JSON.stringify(game.saves.capture()),label+" rejects transactionally")

func semantic_attacks(snapshot: Dictionary) -> void:
	var forged = cloned(snapshot);forged.world.m2.rail.parent = "pelvis"
	reject_semantic(forged,"Forged rail parent")
	forged = cloned(snapshot);forged.world.m2.rail.support = "leg_hoist"
	reject_semantic(forged,"Legacy support alias")
	forged = cloned(snapshot);forged.world.m2.rail.goal = 3;forged.world.m2.rail.moving = true
	reject_semantic(forged,"Invented multi-stage rail motion")
	forged = cloned(snapshot);forged.world.fixtures.foot[9] += .20
	reject_semantic(forged,"Mounted foot world-pose contradiction")
	forged = cloned(snapshot);forged.world.fixtures.pelvis[10] += .20
	reject_semantic(forged,"Moved gantry parent")
	if game.profile.trial == "retention":
		forged = cloned(snapshot);forged.world.m2.shelf.occupants = ["PV-120__001","PV-120__001"]
		reject_semantic(forged,"Duplicate shelf occupant")
		forged = cloned(snapshot);forged.world.m2.shelf.occupants = ["PV-120__invented",""]
		reject_semantic(forged,"Invented shelf identity")
	else:
		forged = cloned(snapshot);forged.world.m2.crane.route_profile = "invented_path"
		reject_semantic(forged,"Invented crane motion profile")
		forged = cloned(snapshot);forged.world.m2.crane.endpoints.magnet_a = {"state":"attached","point":"invented_point"}
		reject_semantic(forged,"Invented magnetic attachment point")

func immediate_physics(label: String) -> void:
	var matches = true
	for id in game.runtime.descendants("left_leg"):
		var body: CollisionObject3D = game.runtime.node(id)
		var physics_pose: Transform3D = PhysicsServer3D.body_get_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
		matches = matches and physics_pose.is_equal_approx(body.global_transform)
		if not physics_pose.is_equal_approx(body.global_transform):print("IMMEDIATE_RESTORE_MISMATCH ",label," ",id," scene=",body.global_transform," physics=",physics_pose)
	expect(matches,label+" descendant physics matches immediately before any awaited tick")

func file_persistence() -> void:
	var prefix = "/tmp/m2-independent-"+str(Time.get_ticks_usec())
	var records: Dictionary = {}
	for trial_name in ["retention","crane"]:
		game = load("res://scenes/workshop.tscn").instantiate();game.profile_override = "leg_bay_"+trial_name;game.automated_test = true;root.add_child(game)
		await frames(3);game.set_paused(false)
		var path = prefix+"-"+trial_name+".json"
		game.saves.setup(game,path,false)
		if trial_name == "retention":game.m2.rail.request("advance");game.m2.rail.physics(.3)
		else:game.m2_crane.request("go:source");game.m2_crane.physics(.3)
		var snapshot = cloned(game.saves.capture())
		var saved: bool = game.saves.save_now()
		if not saved:
			print("INDEPENDENT_FILE_SAVE_ERROR ",trial_name," ",game.saves.message," validation=",game.saves.validate(snapshot)," path=",path)
			diagnose_json(game.saves.capture())
		expect(saved,trial_name+" actual save_now writes unique temporary file during motion")
		records[trial_name] = {"path":path,"snapshot":snapshot,"fingerprint":game.saves.fingerprint}
		game.free();await process_frame
		expect(Store.read(path,records[trial_name].fingerprint).ok,trial_name+" file envelope checksum and fingerprint verify")
		game = load("res://scenes/workshop.tscn").instantiate();game.profile_override = "leg_bay_"+trial_name;game.automated_test = true;root.add_child(game)
		game.saves.setup(game,path,false)
		expect(game.saves.restored and game.paused,trial_name+" fresh scene reloads actual file paused")
		immediate_physics(trial_name+" file restore")
		# JSON converts integral metadata to floats; compare the same persisted
		# representation on both sides rather than native int/float Variant tags.
		var resumed: Dictionary = cloned(game.saves.capture())
		var equipment_match: bool = resumed.world.m2==snapshot.world.m2
		var model_match: bool = resumed.model==snapshot.model
		if not equipment_match:print("INDEPENDENT_DISK_EQUIPMENT_MISMATCH ",trial_name," before=",snapshot.world.m2," after=",game.m2.capture())
		if not model_match:print("INDEPENDENT_DISK_MODEL_MISMATCH ",trial_name)
		expect(equipment_match and model_match,trial_name+" disk resume preserves exact equipment progress and physical ownership")
		game.free();await process_frame
	expect(records.retention.fingerprint != records.crane.fingerprint,"Examples use distinct content/equipment fingerprints")
	var crane_hash = FileAccess.get_sha256(records.crane.path)
	set_meta("m2_reset",true)
	game = load("res://scenes/workshop.tscn").instantiate();game.profile_override = "leg_bay_retention";game.automated_test = true;root.add_child(game)
	game.saves.setup(game,records.retention.path,false)
	expect(game.m2.rail.path == 0 and not game.m2.rail.moving and game.saves.has_save and not game.saves.restored,"Selector reset metadata writes a fresh retention trial to only its own slot")
	expect(FileAccess.get_sha256(records.crane.path)==crane_hash,"Resetting retention leaves crane file bytes unchanged")
	game.free();await process_frame
	var crane_saved: Dictionary = Store.read(records.crane.path,records.crane.fingerprint)
	expect(crane_saved.ok and crane_saved.payload.world.m2.crane.motion == "go:source" and crane_saved.payload.world.m2.crane.progress>0,"Crane progress remains resumable after retention reset")
	for record in records.values():
		for suffix in ["",".bak"]:
			if FileAccess.file_exists(record.path+suffix):DirAccess.remove_absolute(record.path+suffix)

func sample_descendants() -> void:
	var rail = game.m2.rail
	var body: Node3D = game.runtime.node("left_leg")
	var meshes: Array[MeshInstance3D] = [];collect_meshes(body,meshes)
	var locals: Array[Transform3D] = []
	for mesh in meshes:locals.append(body.global_transform.affine_inverse()*mesh.global_transform)
	var good = true
	var physics_good = true
	var physics_failures: Array[Dictionary] = []
	var least_y = INF
	for index in range(41):
		rail.path = 3.0*index/40;rail.goal = rail.path;rail._pose()
		for i in range(meshes.size()):
			good = good and meshes[i].global_transform.is_equal_approx(body.global_transform*locals[i])
			var bounds = meshes[i].mesh.get_aabb()
			for corner in range(8):least_y = minf(least_y,(meshes[i].global_transform*bounds.get_endpoint(corner)).y)
		for id in game.runtime.descendants("left_leg"):
			var child: CollisionObject3D = game.runtime.node(id)
			var physics_pose: Transform3D = PhysicsServer3D.body_get_state(child.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
			if not physics_pose.is_equal_approx(child.global_transform):
				physics_good = false
				if physics_failures.size()<12:physics_failures.append({"id":id,"path":rail.path,"scene":str(child.global_transform),"physics":str(physics_pose)})
		await frames(1)
		for i in range(meshes.size()):good = good and meshes[i].global_transform.is_equal_approx(body.global_transform*locals[i])
	expect(good,"All "+str(meshes.size())+" actual descendant meshes inherit rail pose before/after physics over 41 samples")
	expect(physics_good,"Foot, pitch and pad descendant physics poses agree immediately after rail writes")
	if not physics_good:print("INDEPENDENT_DESCENDANT_PHYSICS ",physics_failures)
	expect(least_y>.49,"Actual loaded descendant bounds preserve at least .49 m floor clearance")
	var parent: Node3D = game.runtime.node("pelvis")
	var before_mount = body.global_transform
	var result: Dictionary = game.model.install_supported("pelvis","left_leg","left_leg","m2_leg_rail")
	expect(result.ok,"Geometry review mounts through the real supported model seam")
	if result.ok:
		game.runtime.mount("pelvis","left_leg","left_leg")
		expect(before_mount.is_equal_approx(body.global_transform),"Real pelvis mounting preserves the docked world pose")
		var initial_parent = parent.global_transform
		var local_leg = body.transform
		var sole_authority = true
		for index in range(12):
			parent.global_transform = initial_parent*Transform3D(Basis.from_euler(Vector3(.01*index,.02*index,-.01*index)),Vector3.ZERO)
			rail._pose()
			sole_authority = sole_authority and body.global_transform.is_equal_approx(parent.global_transform*local_leg)
			for i in range(meshes.size()):sole_authority = sole_authority and meshes[i].global_transform.is_equal_approx(body.global_transform*locals[i])
			await frames(1)
			sole_authority = sole_authority and body.global_transform.is_equal_approx(parent.global_transform*local_leg)
		expect(sole_authority,"Mounted pelvis alone controls the complete leg through continuous multi-axis transforms")
		parent.global_transform = initial_parent;rail._pose()
	rail.path = 0;rail.goal = 0;rail._pose()

func obb(visual: MeshInstance3D) -> Dictionary:
	var bound = visual.mesh.get_aabb()
	var pose = visual.global_transform
	var axes = [pose.basis.x.normalized(),pose.basis.y.normalized(),pose.basis.z.normalized()]
	var half = bound.size*.5*Vector3(pose.basis.x.length(),pose.basis.y.length(),pose.basis.z.length())
	return {"center":pose*bound.get_center(),"axes":axes,"half":half,"aabb":pose*bound}

func intersects(a: Dictionary, b: Dictionary, tolerance: float = .002) -> bool:
	if not a.aabb.grow(tolerance).intersects(b.aabb):return false
	var axes: Array = a.axes.duplicate()
	axes.append_array(b.axes)
	for aa in a.axes:
		for bb in b.axes:axes.append(aa.cross(bb))
	for axis in axes:
		if axis.length_squared()<.00000001:continue
		axis = axis.normalized()
		var ar = 0.0
		var br = 0.0
		for index in range(3):
			ar += a.half[index]*absf(axis.dot(a.axes[index]))
			br += b.half[index]*absf(axis.dot(b.axes[index]))
		if absf(axis.dot(a.center-b.center))>ar+br+tolerance:return false
	return true

func connected(records: Array, source_id: String, target_id: String) -> bool:
	var bounds: Array[Dictionary] = []
	var reached: Array[int] = []
	var targets: Array[int] = []
	for index in range(records.size()):
		bounds.append(obb(records[index].visual))
		if records[index].id == source_id:reached.append(index)
		if records[index].id == target_id:targets.append(index)
	var cursor = 0
	while cursor<reached.size():
		var current = reached[cursor]
		cursor += 1
		for index in range(records.size()):
			if not reached.has(index) and intersects(bounds[current],bounds[index]):reached.append(index)
	return not targets.is_empty() and targets.all(func(index):return reached.has(index))

func jaw_touches_load(rail: Node3D, contact: Dictionary) -> bool:
	var uid: String = game.model.assemblies.left_leg.slots["shin" if contact.local_y<4 else "spar"]
	var target_mesh: MeshInstance3D
	for child in rail.load_body.get_children():
		if child is MeshInstance3D and child.get_meta("component_uid","") == uid:target_mesh = child;break
	if target_mesh == null:return false
	var side_axis: Vector3 = rail.load_body.global_basis.x*contact.side
	var center: Vector3 = contact.visual.global_position
	var start = target_mesh.to_local(center+side_axis*.20)
	var end = target_mesh.to_local(center-side_axis*.40)
	var nearest = INF
	var hit_world = Vector3.ZERO
	var vertices = target_mesh.mesh.get_faces()
	for index in range(0,vertices.size(),3):
		var hit = Geometry3D.segment_intersects_triangle(start,end,vertices[index],vertices[index+1],vertices[index+2])
		if hit != null and start.distance_to(hit)<nearest:nearest = start.distance_to(hit);hit_world = target_mesh.to_global(hit)
	return nearest<INF and hit_world.distance_to(center-side_axis*.06)<.002

func rail_geometry() -> void:
	var rail = game.m2.rail
	var layout = game.leg_layout
	var spar: Dictionary = game.leg_content.sources["LG-120__001"]
	var socket: Dictionary = game.leg_content.sources["PV-110__001"]
	var ball_center = AssemblyRuntime.vec(spar.position)+AssemblyRuntime.vec(spar.primitives[3].center)
	var radius: float = spar.primitives[3].radius
	var skirt_y: float = game.runtime.node("pelvis").global_position.y+socket.primitives[2].center[1]-socket.primitives[2].length/2
	var crown_clearance = INF
	for index in range(201):crown_clearance = minf(crown_clearance,skirt_y-(rail.rail_pose(1.0+float(index)/200).load*ball_center).y-radius)
	expect(crown_clearance > .060,"Integral ball clears socket skirt throughout the populated tilt")
	var socket_center: Vector3 = game.runtime.node("pelvis").global_transform*AssemblyRuntime.vec(socket.position)
	expect((rail.rail_pose(3).load*ball_center).distance_to(socket_center)<.0001 and radius < socket.primitives[0].inner and radius < socket.primitives[1].inner and radius < socket.primitives[2].inner,"Upward docking is coaxial and clears the authored rim, skirt and bowl")
	var axle_shape = BoxShape3D.new();axle_shape.size = Vector3(1.2,.4,.5)
	var axle_query = PhysicsShapeQueryParameters3D.new();axle_query.shape = axle_shape
	axle_query.transform = Transform3D(Basis.IDENTITY,Vector3(10.76,1.35,14.5));axle_query.collision_mask = 1;axle_query.margin = .001
	expect(game.get_world_3d().direct_space_state.intersect_shape(axle_query,1).is_empty(),"Full 1.2 m knee extraction volume clears machinery at the working axle height")
	var preview = true
	var fixture_floor = INF
	var failures: Array[String] = []
	var pieces: Array = layout.moving_pieces+layout.static_pieces.filter(func(piece):return piece.id == "Rail")
	for index in range(61):
		rail.path = float(index)/20;rail.goal = rail.path;rail._pose()
		var sample = rail.rail_pose(rail.path)
		for piece in layout.motion_geometry(sample.load,sample.z,sample.x):
			var visual: MeshInstance3D = piece.visual
			preview = preview and piece.pose.origin.distance_to(visual.global_position)<.0002 and piece.pose.basis.is_equal_approx(visual.global_basis.orthonormalized()) and piece.shape.size.distance_to(visual.mesh.size*visual.scale)<.0002
			fixture_floor = minf(fixture_floor,(visual.global_transform*visual.mesh.get_aabb()).position.y)
		if not connected(pieces,"Rail","LocatedJaw") and failures.size()<4:failures.append("rail_support path="+str(rail.path))
		for contact in layout.contacts:
			if not jaw_touches_load(rail,contact) and failures.size()<4:failures.append("load_contact path="+str(rail.path)+" Y="+str(contact.local_y)+" side="+str(contact.side))
	rail.path = 0;rail.goal = 0;rail._pose()
	expect(preview,"Rail safety preview matches every moving visible support pose and size")
	expect(fixture_floor >= -.002,"Visible rail machinery clears the floor along the route")
	expect(failures.is_empty(),"Rail-to-jaw support chain and every jaw/load contact hold along the route "+str(failures))

func rail_motion() -> void:
	var rail = game.m2.rail
	var blocker = StaticBody3D.new();blocker.name = "ThinRouteObstruction";game.add_child(blocker)
	var collision = CollisionShape3D.new();var box = BoxShape3D.new()
	box.size = Vector3(.20,.8,.012);collision.shape = box;blocker.add_child(collision)
	blocker.position = Vector3(11.9,1.35,19.3)
	await frames(2)
	rail.request("advance")
	for tick in range(100):
		if not rail.moving:break
		rail.physics(.08);await physics_frame
	expect(not rail.moving and not rail.blocked_reason.is_empty() and rail.path < .1,"Thin real obstacle stops the rail before the populated load reaches it")
	expect(game.model.support_occupant("m2_leg_rail") == "left_leg","Blocked motion keeps rail support and identity")
	var error: String = rail.request("return")
	for tick in range(100):
		if not rail.moving:break
		rail.physics(.08);await physics_frame
	expect(error.is_empty() and rail.blocked_reason.is_empty() and is_zero_approx(rail.path),"Return recovers the blocked load while the obstacle remains")
	blocker.free();await frames(2)
	rail.request("advance");rail.physics(.25)
	var moving_path: float = rail.path
	var moving_goal: float = rail.goal
	expect(not rail.request("return").is_empty() and rail.moving and is_equal_approx(rail.path,moving_path) and is_equal_approx(rail.goal,moving_goal) and rail.status_text().begins_with("MOVING"),"Rejected direction change preserves active motion and its status")
	game.set_paused(true)
	var held: float = rail.path
	rail.physics(10)
	expect(is_equal_approx(held,rail.path) and game.model.support_occupant("m2_leg_rail") == "left_leg","Pause freezes supported rail motion")
	game.set_paused(false);rail.request("stop");rail.request("return")
	for tick in range(100):
		if not rail.moving:break
		rail.physics(.08);await physics_frame
	expect(is_zero_approx(rail.path) and not rail.moving and rail.load_body.global_transform.is_equal_approx(rail.rail_pose(0).load),"Stopped partial trip returns the same supported leg home")

func geometry_contacts() -> void:
	var crane = game.m2_crane
	var mesh: MeshInstance3D = crane.load_body.get_child(0)
	var vertices: PackedVector3Array = mesh.mesh.get_faces()
	# Stem faces span the saddle rather than necessarily carrying a vertex over it.
	for receiver in [false,true]:
		for i in range(2):
			var pose: Transform3D = crane.receiver_pose if receiver else crane.source_pose
			var source = pose.affine_inverse()*Vector3(pose.origin.x,1.25,[16.0,17.6][i])
			# Ray/triangle point-on-face check, independent of collision proxy bounds.
			var found = false
			for j in range(0,vertices.size(),3):
				var hit = Geometry3D.segment_intersects_triangle(source+Vector3(0,0,.02),source-Vector3(0,0,.02),vertices[j],vertices[j+1],vertices[j+2])
				if hit != null and hit.distance_to(source)<.001:found = true;break
			expect(found,"Actual beam mesh underside contacts "+("receiver cradle" if receiver else "source saddle")+" at Z"+str([16.0,17.6][i]))
	for id in crane.POINT_IDS:
		var point: Vector3 = crane.point_position(id)
		var local = crane.source_pose.affine_inverse()*point
		var found = false
		for j in range(0,vertices.size(),3):
			var hit = Geometry3D.segment_intersects_triangle(local-Vector3(0,0,.02),local+Vector3(0,0,.02),vertices[j],vertices[j+1],vertices[j+2])
			if hit != null and hit.distance_to(local)<.001:found = true;break
		expect(found,"Marked magnetic point "+id+" lies on actual load mesh")
	var axial: Vector3 = crane.route[4].origin-crane.route[3].origin
	expect(axial.is_equal_approx(Vector3(0,0,-.20)),"Final flange approach is exactly .20 m along world -Z")
	var excluded: Array[RID] = [crane.load_body.get_rid(),game.player.get_rid()]
	excluded.append_array(game.leg_layout.rack_hardware);excluded.append_array(game.leg_layout.cradle_hardware)
	for id in game.runtime.descendants("left_leg"):excluded.append(game.runtime.node(id).get_rid())
	var contacts: Array[Dictionary] = []
	for index in range(101):
		var at = 4.0*index/100
		for shape in SolidHandling.shapes(crane.load_body):
			var query = PhysicsShapeQueryParameters3D.new();query.shape = shape.shape;query.exclude = excluded;query.collision_mask = 15;query.margin = 0
			query.transform = crane.load_pose(at)*shape.transform
			for hit in game.get_world_3d().direct_space_state.intersect_shape(query,8):contacts.append({"path":at,"collider":str(hit.collider.get_path())})
	expect(contacts.is_empty(),"101 loaded route samples clear rail hardware and scenery beyond declared rack/receiver contact")
	if not contacts.is_empty():print("INDEPENDENT_CRANE_SWEEP_CONTACTS ",contacts)

func run() -> void:
	for trial in ["retention","crane"]:
		game = load("res://scenes/workshop.tscn").instantiate();game.profile_override = "leg_bay_"+trial;game.automated_test = true
		root.add_child(game);await frames(8);game.set_paused(false)
		expect(not game.saves.enabled,"Headless "+trial+" does not enable automatic save writes")
		var snapshot = cloned(game.saves.capture())
		expect(game.saves.validate(snapshot).is_empty(),"Initial "+trial+" snapshot validates")
		fuzz(snapshot,["world","m2"])
		fuzz(snapshot,["world","access_lifts"])
		semantic_attacks(snapshot)
		if trial == "retention":
			rail_geometry()
			await rail_motion()
			await sample_descendants()
		else:geometry_contacts()
		game.free();await process_frame
	await file_persistence()
	expect(defects.is_empty(),str(attacks)+" missing/mistyped nested field attacks reject without mutation")
	var passed = checks.all(func(c):return c.passed)
	var hashes = {}
	for file in ["m2_session.gd","m2_workshop.gd","leg_rail.gd","leg_bay_layout.gd","m2_lift_shelf.gd","service_crane.gd","assembly_runtime.gd","workshop.gd"]:hashes[file] = FileAccess.get_sha256("res://scripts/"+file)
	var output = {"passed":passed,"checks":checks,"attacks":attacks,"rejected":rejected,"defects":defects,"rendered":false,"script_hashes":hashes}
	DirAccess.make_dir_recursive_absolute("res://verification")
	FileAccess.open("res://verification/m2-independent-acceptance.json",FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	print("M2_ACCEPTANCE ","PASS" if passed else "FAIL"," ",checks.size()," checks; ",attacks," attacks; defects ",defects)
	quit(0 if passed else 1)
