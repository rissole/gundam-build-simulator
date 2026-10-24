extends "res://tests/m2_acceptance_test.gd"
## Independent headless mechanical review. Uses M2's accepted OBB helpers only;
## staged construction here is expressly not ordinary-player journey evidence.
const Bay = preload("res://scripts/leg_bay_layout.gd")
var findings: Array[Dictionary] = []
var measurements: Dictionary = {}
var faces_cache: Dictionary = {}
var physics_failures: Array = []

func actual_faces(mesh: Mesh) -> PackedVector3Array:
	var key = mesh.get_rid()
	if not faces_cache.has(key):faces_cache[key]=mesh.get_faces()
	return faces_cache[key]

func note(ok: bool, label: String, detail: Dictionary = {}) -> void:
	expect(ok,label)
	if not ok:findings.append({"check":label,"detail":detail})
	if not detail.is_empty():print("M3_GEOMETRY_DETAIL ",label," ",detail)

func source_visual(owner: String, source_id: String) -> MeshInstance3D:
	var meshes: Array[MeshInstance3D] = [];collect_meshes(game.runtime.node(owner),meshes)
	for mesh in meshes:
		if mesh.get_meta("source_uid","") == source_id or str(mesh.name).begins_with(source_id+"__") or str(mesh.name)==source_id:return mesh
	return null

func hit_distance(mesh: Mesh, pose: Transform3D, point: Vector3, direction: Vector3, length: float = .04) -> float:
	var inverse = pose.affine_inverse()
	var start = inverse*(point-direction*length)
	var end = inverse*(point+direction*length)
	var distance = INF
	var faces = actual_faces(mesh)
	for index in range(0,faces.size(),3):
		var hit = Geometry3D.segment_intersects_triangle(start,end,faces[index],faces[index+1],faces[index+2])
		if hit != null:distance = minf(distance,point.distance_to(pose*hit))
	return distance

func box_face_contacts(visual: MeshInstance3D, mesh: Mesh, pose: Transform3D, upward_only: bool = false) -> Array:
	# Probe centers of each actual pad face. A proximity hit alone does not prove
	# weight support; upward_only demands an upward normal in world coordinates.
	var bound = visual.mesh.get_aabb()
	var hits: Array = []
	for axis in range(3):
		for sign_value in [-1.0,1.0]:
			var normal = visual.global_basis[axis].normalized()*sign_value
			if upward_only and normal.dot(Vector3.UP)<.05:continue
			# Narrow flanges and open-section ends can lie between face-grid probes.
			# Their actual boundary vertices still establish real bearing contact.
			var relative = visual.global_transform.affine_inverse()*pose
			var face_coordinate: float=bound.get_center()[axis]+bound.size[axis]*.5*sign_value
			var found_vertex=false
			for vertex in actual_faces(mesh):
				var p: Vector3=relative*vertex
				if absf(p[axis]-face_coordinate)>.003:continue
				var uaxis=(axis+1)%3;var vaxis=(axis+2)%3
				if p[uaxis]<bound.position[uaxis]-.001 or p[uaxis]>bound.end[uaxis]+.001 or p[vaxis]<bound.position[vaxis]-.001 or p[vaxis]>bound.end[vaxis]+.001:continue
				hits.append({"point":visual.to_global(p),"normal":normal,"distance":absf(p[axis]-face_coordinate)});found_vertex=true;break
			if found_vertex:continue
			for u in [-.48,0.0,.48]:
				for v in [-.48,0.0,.48]:
					var local = bound.get_center();local[axis] += bound.size[axis]*.5*sign_value
					local[(axis+1)%3] += u*bound.size[(axis+1)%3]
					local[(axis+2)%3] += v*bound.size[(axis+2)%3]
					var point = visual.to_global(local)
					var distance = hit_distance(mesh,pose,point,normal)
					if distance < .003:hits.append({"point":point,"normal":normal,"distance":distance})
	return hits

func records_below(node: Node) -> Array:
	var meshes: Array[MeshInstance3D] = [];collect_meshes(node,meshes)
	var records: Array = []
	for mesh in meshes:
		if mesh.mesh is BoxMesh:records.append({"id":str(mesh.name),"visual":mesh})
	return records

func bodies_below(node: Node, result: Array[CollisionObject3D]) -> void:
	if node is CollisionObject3D:result.append(node)
	for child in node.get_children():bodies_below(child,result)

func physics_matches(nodes: Array[CollisionObject3D]) -> bool:
	for body in nodes:
		var physics: Transform3D=PhysicsServer3D.body_get_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
		if not body.global_transform.is_equal_approx(physics):
			if physics_failures.size()<6:physics_failures.append({"body":str(body.get_path()),"scene":str(body.global_transform),"physics":str(physics)})
			return false
	return true

func shape_physics_matches(body: CollisionObject3D, collision: CollisionShape3D, visual: MeshInstance3D, body_local: bool = false) -> bool:
	var index=-1
	for owner_id in body.get_shape_owners():
		if body.shape_owner_get_owner(owner_id)==collision:index=body.shape_owner_get_shape_index(owner_id,0);break
	if index<0:return false
	var physical: Transform3D=PhysicsServer3D.body_get_shape_transform(body.get_rid(),index)
	if not body_local:physical=PhysicsServer3D.body_get_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)*physical
	var physical_size: Vector3=PhysicsServer3D.shape_get_data(collision.shape.get_rid())*2
	var expected_size: Vector3=visual.mesh.get_aabb().size*Vector3(visual.global_basis.x.length(),visual.global_basis.y.length(),visual.global_basis.z.length())
	var expected=Transform3D(visual.global_basis.orthonormalized(),visual.global_position)
	if body_local:expected=body.global_transform.affine_inverse()*expected
	return physical.is_equal_approx(expected) and physical_size.is_equal_approx(expected_size)

func lift_support_geometry() -> void:
	var lift=game.equipment.get_equipment("hip_lift")
	var records: Array=[];var beams: Array=[];var collars: Array=[];var guides: Array=[];var slab: Dictionary={}
	for body in lift.get_children():
		if not body is CollisionObject3D:continue
		for collision in body.get_children():
			if not collision is CollisionShape3D or not collision.shape is BoxShape3D or not collision.has_meta("visual"):continue
			var record={"id":str(collision.name),"visual":collision.get_meta("visual"),"body":body,"collision":collision}
			records.append(record)
			if str(collision.name).begins_with("CantileverDeckBeam"):beams.append(record)
			if str(collision.name).begins_with("GuideCarriage_"):collars.append(record)
			if str(body.name)=="FloorAnchoredLiftGuides" and collision.shape.size.y>5:guides.append(record)
			if body==lift.deck and collision.shape.size.x>2 and collision.shape.size.z>2:slab=record
	note(beams.size()==2 and collars.size()==2 and guides.size()==2 and not slab.is_empty(),"Integrated lift exposes two real cantilever beams, collars and floor-anchored guides")
	if slab.is_empty():return
	var was_paused: bool=game.paused;game.set_paused(true)
	var heights=[lift.stops[0],(lift.stops[0]+lift.stops[-1])/2,lift.stops[-1]]
	var mismatches: Array=[];var kinematic_evidence: Array=[]
	for height in heights:
		# Exercise the actual equipment restore seam. Jolt stores a kinematic
		# motion target here; its current simulated world pose changes next tick.
		var destination: float=lift.stops[-1] if height!=lift.stops[0] else height
		lift.apply({"height":height,"destination":destination,"moving":height!=destination})
		var current: Transform3D=PhysicsServer3D.body_get_state(lift.deck.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
		var target_consistent: bool=lift.deck.global_transform.is_equal_approx(lift.global_transform*Transform3D(Basis.IDENTITY,Vector3(0,height,0)))
		var links=grounded(records,slab.visual)
		for beam in beams:
			links=links and grounded(records,beam.visual) and intersects(obb(beam.visual),obb(slab.visual)) and collars.any(func(collar):return intersects(obb(beam.visual),obb(collar.visual)))
		for collar in collars:
			links=links and grounded(records,collar.visual) and guides.any(func(guide):return intersects(obb(collar.visual),obb(guide.visual)))
		note(links,"Actual lift deck beams and collars maintain a floor-to-deck support chain at height "+str(height))
		var immediate=target_consistent
		for record in records:
			if record.collision.disabled:continue
			if not shape_physics_matches(record.body,record.collision,record.visual,true):
				immediate=false
				if mismatches.size()<8:mismatches.append({"height":height,"shape":str(record.collision.get_path()),"phase":"before_tick"})
		await frames(1)
		var after=true
		for record in records:
			if not record.collision.disabled:after=after and shape_physics_matches(record.body,record.collision,record.visual)
		note(immediate and after,"Restored lift arm collar deck and guide PhysicsServer shapes match immediately in body space and in world space after a tick at height "+str(height),{"immediate_body_local":immediate,"after_tick_world":after,"mismatches":mismatches.duplicate()})
		kinematic_evidence.append({"height":height,"mode":PhysicsServer3D.body_get_mode(lift.deck.get_rid()),"target_consistent":target_consistent,"pre_tick_target_current_distance":current.origin.distance_to(lift.deck.global_position),"next_tick_world_shapes_match":after})
	lift.height=lift.stops[0];lift.destination=lift.height;lift.moving=false;lift._pose();game.set_paused(was_paused);await frames(2)
	measurements.lift_support_heights=heights
	measurements.lift_kinematic_restore=kinematic_evidence

func holder_support_check(rail: Node, phase: String, progress: float, failures: Array) -> void:
	var layout=game.leg_layout
	var records: Array=layout.moving_pieces.filter(func(piece):return piece.visual.is_visible_in_tree())
	records.append_array(layout.static_pieces.filter(func(piece):return piece.id=="Rail"))
	var targets=["BogieLiftPost","TelescopingCrossSlide","CrossSlideRiser","CrossSlideUpper","TelescopingPivotMast","MastCrosshead","WithdrawalBearingLink","PivotBearing","LadderSpine"]
	for piece in layout.moving_pieces:
		if piece.id in targets and piece.visual.is_visible_in_tree() and not grounded(records,piece.visual) and failures.size()<12:failures.append({"phase":phase,"progress":progress,"kind":"floor_support_chain","piece":piece.id})
		var bounds: AABB=piece.visual.global_transform*piece.visual.mesh.get_aabb()
		if bounds.position.y < -.002 and failures.size()<12:failures.append({"phase":phase,"progress":progress,"kind":"floor_penetration","piece":piece.id,"minimum_y":bounds.position.y})
		var boundary: float=(Bay.layout().rail.x+Bay.layout().rail.reserved_x)/2
		if bounds.end.x>boundary and failures.size()<12:failures.append({"phase":phase,"progress":progress,"kind":"reserved_lane","piece":piece.id,"maximum_x":bounds.end.x})
		if piece.has("body") and not shape_physics_matches(piece.body,piece.body.get_child(0),piece.visual) and failures.size()<12:failures.append({"phase":phase,"progress":progress,"kind":"physics_shape_pose","piece":piece.id})
	var frame: Dictionary=rail.holder_pose(rail.path)
	for piece in layout.motion_geometry(frame.load,frame.z,frame.x):
		var visual: MeshInstance3D=piece.visual
		if (not piece.pose.is_equal_approx(Transform3D(visual.global_basis.orthonormalized(),visual.global_position)) or not piece.shape.size.is_equal_approx(visual.mesh.get_aabb().size*visual.scale)) and failures.size()<12:failures.append({"phase":phase,"progress":progress,"kind":"preview_pose_or_size","piece":piece.id})

func grounded(records: Array, target: MeshInstance3D) -> bool:
	var bounds: Array = []
	var reached: Array[int] = []
	var target_index = -1
	for index in range(records.size()):
		bounds.append(obb(records[index].visual))
		var floor_y: float = bounds[-1].aabb.position.y
		if floor_y <= .003 and floor_y >= -.003:reached.append(index)
		if records[index].visual == target:target_index = index
	var cursor = 0
	while cursor<reached.size():
		var current = reached[cursor];cursor += 1
		for index in range(records.size()):
			if not reached.has(index) and intersects(bounds[current],bounds[index],.003):reached.append(index)
	return target_index >= 0 and reached.has(target_index)

func carrier_support() -> void:
	var carrier = game.equipment.get_equipment("foot_carrier")
	var rails: Array = []
	for uid in ["FA-302__001","FA-302__002"]:
		var visual = source_visual("foot",uid)
		if visual != null:rails.append(visual)
	note(rails.size()==2,"Carrier review resolves both actual mounted heel-pad source meshes")
	if rails.size()!=2:return
	var support_failures: Array = []
	var contact_failures: Array = []
	var upward_failures: Array = []
	var below_floor = INF
	var contact_cache: Dictionary = {}
	var hardware_physics = true
	var hardware_bodies: Array[CollisionObject3D]=[];bodies_below(carrier,hardware_bodies)
	for sample in range(81):
		carrier.path = float(sample)/40;carrier.goal=carrier.path;carrier._pose()
		hardware_physics=hardware_physics and physics_matches(hardware_bodies)
		var pieces = records_below(carrier)
		var pads: Array = []
		for piece in pieces:
			if piece.visual.get_parent() == carrier.cradle:pads.append(piece.visual)
			below_floor=minf(below_floor,obb(piece.visual).aabb.position.y)
		for rail_mesh in rails:
			var contacts: Array = [];var weight: Array = []
			for pad in pads:
				var key = str(pad.get_instance_id())+"/"+str(rail_mesh.get_instance_id())
				if not contact_cache.has(key):
					var hits = box_face_contacts(pad,rail_mesh.mesh,rail_mesh.global_transform)
					var directions: Array=[]
					for hit in hits:directions.append(pad.global_basis.inverse()*hit.normal)
					contact_cache[key]={"directions":directions,"relative":rail_mesh.global_transform.affine_inverse()*pad.global_transform}
				var record: Dictionary=contact_cache[key]
				var contact_valid: bool=record.relative.is_equal_approx(rail_mesh.global_transform.affine_inverse()*pad.global_transform)
				if not record.directions.is_empty() and contact_valid:
					contacts.append(pad)
					if not grounded(pieces,pad) and support_failures.size()<6:support_failures.append({"path":carrier.path,"pad":str(pad.name)})
					for direction in record.directions:
						if (pad.global_basis*direction).dot(Vector3.UP)>.001:weight.append(direction)
			if contacts.is_empty() and contact_failures.size()<6:contact_failures.append({"path":carrier.path,"rail":str(rail_mesh.name)})
			if weight.is_empty() and upward_failures.size()<6:upward_failures.append({"path":carrier.path,"rail":str(rail_mesh.name)})
	note(contact_failures.is_empty(),"Each heel pad has actual cradle surface contact throughout 81 transfer/turn poses",{"failures":contact_failures})
	note(support_failures.is_empty(),"Every cradle contact has a continuous real box support chain to the floor",{"failures":support_failures})
	note(upward_failures.is_empty(),"Carrier supplies positive upward support through the complete indexed turnover",{"failures":upward_failures})
	note(below_floor >= -.003,"Guided carrier support machinery stays above the floor",{"minimum_y":below_floor})
	note(hardware_physics,"All guided carrier hardware physics matches visible support poses immediately between ticks",{"mismatches":physics_failures.duplicate()})
	physics_failures.clear()
	carrier.path=2;carrier.goal=2;carrier._pose()
	var result: Dictionary = game.model.install_supported("left_leg","foot","foot","foot_carrier")
	note(result.ok,"Geometry fixture seats supplied foot through real support seam")
	if result.ok:game.runtime.mount("left_leg","foot","foot");game.refresh_assembly_collision("left_leg")
	var receivers: Array = game.leg_layout.moving_pieces.filter(func(piece):return str(piece.id).begins_with("FootReceiver"))
	var receiver_ok = true;var receiver_grounded = true
	for rail_mesh in rails:
		var upward = false
		for receiver in receivers:
			if not box_face_contacts(receiver.visual,rail_mesh.mesh,rail_mesh.global_transform,true).is_empty():
				upward=true
				receiver_grounded=receiver_grounded and connected(game.leg_layout.moving_pieces+game.leg_layout.static_pieces.filter(func(p):return p.id=="Rail"),"Rail",receiver.id)
		receiver_ok=receiver_ok and upward
	note(receiver_ok,"Receiving fixture positively supports each actual heel pad before shin exists")
	note(receiver_grounded and not receivers.is_empty(),"Receiving foot contacts connect through holder structure to floor rail")
	var before: Transform3D=game.foot.global_transform
	var meshes: Array[MeshInstance3D]=[];collect_meshes(game.foot,meshes)
	var withdrawals: Array=[];var stationary=true
	for index in range(21):
		carrier.withdrawal=float(index)/20;carrier._pose()
		stationary=stationary and before.is_equal_approx(game.foot.global_transform)
		for piece in carrier.moving_pieces:
			for mesh in meshes:
				if mesh_penetrates_box(mesh,piece.visual) and withdrawals.size()<8:withdrawals.append({"withdrawal":carrier.withdrawal,"piece":piece.id,"mesh":str(mesh.name)})
	note(stationary,"Empty carrier withdrawal leaves the receiving-supported foot stationary before shin exists")
	note(withdrawals.is_empty(),"Empty carrier hardware clears actual mounted foot geometry throughout withdrawal",{"collisions":withdrawals})
	measurements.carrier_samples=81

func crane_sources() -> void:
	var layout = game.leg_layout
	var runway_records: Array=layout.static_pieces.filter(func(piece):return piece.id in ["CraneFloorFoot","CraneColumn","CraneRunway","CraneBridge"])
	var bridge: MeshInstance3D=runway_records.filter(func(piece):return piece.id=="CraneBridge")[0].visual
	for task in ["shin","fork","spar"]:
		var spec: Dictionary = Bay.layout().crane.tasks[task]
		var frame = Bay.authored_pose(spec.source_pose)
		var receiving = Bay.authored_pose(spec.receiver_pose)
		var mesh: Mesh = game.source[spec.load_uid].mesh
		note(receiving.is_equal_approx(game.runtime.slot_pose("left_leg",spec.slot)),"Crane "+task+" receiving support places actual source geometry at canonical slot pose")
		var records = layout.static_pieces.filter(func(piece):return piece.id=="M3Rack_"+task)
		var contacts_ok = records.size()>=2
		for record in records:
			var top = record.visual.global_transform*Vector3(0,record.visual.mesh.get_aabb().size.y/2,0)
			var distance = hit_distance(mesh,frame,top,Vector3.UP)
			contacts_ok=contacts_ok and distance<.003
			note(distance<.003,"Actual "+task+" mesh rests on source rack top "+str(top),{"distance":distance})
		note(contacts_ok,"Two grounded separated source contacts support "+task)
		# Magnetic markers must meet the source surface, rather than a convenient
		# proxy or the aggregate part AABB.
		for point in spec.magnetic_points:
			var p = frame*AssemblyRuntime.vec(spec.magnetic_points[point])
			note(hit_distance(mesh,frame,p,Vector3.UP)<.003,"Actual "+task+" magnetic point meets source mesh: "+point)
		var supported=true;var unsupported: Array=[]
		for point in spec.route_positions:
			# The actual suspended spreader carries its bridge hook 1.7m behind
			# the load frame; inspect the visible bridge against grounded runways.
			layout.set_crane_anchor(AssemblyRuntime.vec(point)+Vector3(0,19.25,1.7))
			if not grounded(runway_records,bridge):supported=false;unsupported.append(str(bridge.global_position))
		note(supported,"Shared crane bridge has a real grounded runway support chain along every "+task+" source and receiving leg",{"unsupported_bridge_positions":unsupported})
	game.equipment.get_equipment("service_crane")._refresh()

func stage_complete_leg() -> void:
	var first: Array=game.runtime.definition("left_leg").slots.keys().filter(func(sid):return sid not in ["bearing_1","bearing_2","thrust_1","thrust_2"])
	Staging.fill(game,"left_leg",first)
	for pair in [["bearing_1","LG-130__002"],["bearing_2","LG-130__001"],["thrust_1","LG-135__002"],["thrust_2","LG-135__001"]]:
		game.model.carry_item(pair[1])
		var result: Dictionary=game.model.install("left_leg",pair[0],pair[1])
		note(result.ok,"Geometry fixture installs interchangeable opposite identity "+pair[0]+"/"+pair[1])
	game.components.sync("left_leg")
	Staging.fill(game,"left_leg")
	game.refresh_assembly_collision("left_leg")
	note(game.model.milestone("left_leg","structural_ready"),"Disclosed geometry fixture supplies complete structural leg")
	# Staging is intentionally outside crane interaction; refresh its projection.
	game.equipment.get_equipment("service_crane")._refresh()
	canonical_geometry("left_leg")

func canonical_geometry(owner: String) -> void:
	var proper=true;var swapped=0;var checked=0
	for visual in game.runtime.node(owner).get_children():
		if not visual is MeshInstance3D or not visual.has_meta("slot_id"):continue
		var sid: String=visual.get_meta("slot_id")
		var spec: Dictionary=game.model.slot_definition(owner,sid)
		if not spec.has("pose_source"):continue
		var uid: String=game.model.assemblies[owner].slots[sid]
		if uid!=spec.pose_source:swapped+=1
		proper=proper and visual.get_meta("component_uid","")==uid and visual.get_meta("source_uid","")==spec.pose_source and visual.mesh==game.source[spec.pose_source].mesh and visual.global_transform.is_equal_approx(game.runtime.slot_pose(owner,sid))
		checked+=1
	note(proper and checked>0 and swapped>=2,"Actual "+owner+" meshes retain canonical source geometry and destination pose separately from swapped consumed identities",{"physical_meshes":checked,"opposite_identities":swapped})

func mounted_motion() -> void:
	var rail = game.equipment.get_equipment("leg_rail")
	var body: Node3D = game.runtime.node("left_leg")
	var actual_meshes: Array[MeshInstance3D] = [];collect_meshes(body,actual_meshes)
	var pieces: Array = [];for visual in actual_meshes:pieces.append({"visual":visual})
	var locals: Array = [];for piece in pieces:locals.append(body.global_transform.affine_inverse()*piece.visual.global_transform)
	var rigid = true;var physics = true;var floor_y = INF
	var equipment_physics=true
	var all_bodies: Array[CollisionObject3D]=[];bodies_below(body,all_bodies)
	for piece in game.leg_layout.moving_pieces:
		if piece.has("body"):all_bodies.append(piece.body)
	for index in range(121):
		rail.path=float(index)/40;rail.goal=rail.path;rail._pose()
		equipment_physics=equipment_physics and physics_matches(all_bodies)
		for mesh_index in range(pieces.size()):
			var visual: MeshInstance3D = pieces[mesh_index].visual
			rigid=rigid and visual.global_transform.is_equal_approx(body.global_transform*locals[mesh_index])
			floor_y=minf(floor_y,(visual.global_transform*visual.mesh.get_aabb()).position.y)
		for owner in game.runtime.descendants("left_leg"):
			var child: CollisionObject3D = game.runtime.node(owner)
			physics=physics and child.global_transform.is_equal_approx(PhysicsServer3D.body_get_state(child.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM))
		await frames(1)
		for mesh_index in range(pieces.size()):rigid=rigid and pieces[mesh_index].visual.global_transform.is_equal_approx(body.global_transform*locals[mesh_index])
	note(rigid,"Every actual mounted foot/pad/pitch/leg mesh follows 121 continuous rail poses before and after ticks")
	note(physics,"Nested body physics agrees immediately with all rail pose writes between ticks")
	note(equipment_physics,"Passive brace and moving holder hardware scene and physics agree immediately between ticks",{"mismatches":physics_failures.duplicate()})
	physics_failures.clear()
	note(is_finite(floor_y) and floor_y>.49,"Loaded toe, foot and knee geometry clears floor during full travel tilt dock",{"minimum_y":floor_y})
	measurements.loaded_samples=121;measurements.loaded_meshes=pieces.size();measurements.minimum_loaded_y=floor_y
	# Reuse accepted mechanical ball/socket and jaw triangle checks, with current
	# fully staged M3 geometry. Its 61 samples also verify visible sweep proxies.
	rail_geometry()

func jaw_touches_load(rail: Node3D, contact: Dictionary) -> bool:
	# Foot contacts have their separate actual-source support audit above.
	if not contact.has("local_y"):return true
	return super.jaw_touches_load(rail,contact)

func triangle_in_box(a: Vector3, b: Vector3, c: Vector3, half: Vector3) -> bool:
	# Triangle/box SAT in the actual equipment box frame; require 3 mm
	# penetration to distinguish deliberate bearing-face contact from collision.
	var edge = [b-a,c-b,a-c]
	var axes = [Vector3.RIGHT,Vector3.UP,Vector3.BACK,(b-a).cross(c-a)]
	for e in edge:
		for axis in [Vector3.RIGHT,Vector3.UP,Vector3.BACK]:axes.append(e.cross(axis))
	for axis in axes:
		if axis.length_squared()<.0000000001:continue
		var radius: float = absf(axis.x)*half.x+absf(axis.y)*half.y+absf(axis.z)*half.z
		var minimum: float = minf(a.dot(axis),minf(b.dot(axis),c.dot(axis)))
		var maximum: float = maxf(a.dot(axis),maxf(b.dot(axis),c.dot(axis)))
		if minimum>radius or maximum < -radius:return false
	return true

func mesh_penetrates_box(visual: MeshInstance3D, target: MeshInstance3D) -> bool:
	if not (visual.global_transform*visual.mesh.get_aabb()).intersects(target.global_transform*target.mesh.get_aabb()):return false
	var bound = target.mesh.get_aabb()
	var half = bound.size*.5-Vector3.ONE*.003
	if half.x<=0 or half.y<=0 or half.z<=0:return false
	var relative = target.global_transform.affine_inverse()*visual.global_transform
	var faces = actual_faces(visual.mesh)
	for index in range(0,faces.size(),3):
		if triangle_in_box(relative*faces[index]-bound.get_center(),relative*faces[index+1]-bound.get_center(),relative*faces[index+2]-bound.get_center(),half):return true
	return false

func collision_record(records: Dictionary, phase: String, progress: float, mesh: MeshInstance3D, holder: String) -> void:
	var key=phase+"/"+holder
	if not records.has(key):records[key]={"phase":phase,"holder":holder,"first":progress,"last":progress,"source_families":[],"sample_hits":0}
	var family: String=mesh.get_meta("source_uid",str(mesh.name))
	family=family.split("__")[0]
	if not records[key].source_families.has(family):records[key].source_families.append(family)
	records[key].last=progress;records[key].sample_hits+=1

func set_lift_geometry(height: float) -> void:
	var lift=game.equipment.get_equipment("hip_lift")
	lift.height=height;lift.destination=height;lift.moving=false;lift._pose()
	# The lift is a separate equipment subtree, outside leg_layout's piece list.
	# Publish its current compound collision body before querying the full world.
	await frames(2)

func world_sweep(rail: Node, phase: String, from: float, to: float, failures: Array) -> void:
	var error: String=rail.holder_contact_error(from,to) if phase in ["release","reacquire"] else rail.motion_error(from,to)
	if not error.is_empty():failures.append({"phase":phase,"from":from,"to":to,"error":error})

func world_failure_summary(failures: Array) -> Array:
	var summary: Dictionary={}
	for failure in failures:
		var key: String=failure.phase+"/"+failure.error
		if not summary.has(key):summary[key]={"phase":failure.phase,"error":failure.error,"first_from":failure.from,"last_to":failure.to,"intervals":0}
		summary[key].last_to=failure.to;summary[key].intervals+=1
	return summary.values()

func route_geometry() -> void:
	var rail = game.equipment.get_equipment("leg_rail")
	var lift=game.equipment.get_equipment("hip_lift")
	await set_lift_geometry(lift.stops[0])
	var meshes: Array[MeshInstance3D] = [];collect_meshes(rail.load_body,meshes)
	var receiver_meshes: Array[MeshInstance3D]=[];collect_meshes(game.runtime.node("pelvis"),receiver_meshes)
	var static_geometry: Array = game.leg_layout.static_pieces.filter(func(piece):return piece.has("body") and piece.id != "Floor")
	static_geometry.append_array(game.equipment.get_equipment("foot_carrier").moving_pieces)
	var collisions: Array = [];var holder_collisions: Dictionary={};var receiver_collisions: Dictionary={};var world_failures: Array=[];var support_failures: Array=[]
	var previous=0.0
	for index in range(61):
		var next=float(index)/20
		world_sweep(rail,"loaded",previous,next,world_failures)
		rail.path=next;rail.goal=rail.path;rail._pose();previous=next
		holder_support_check(rail,"loaded",next,support_failures)
		for mesh in meshes:
			for piece in static_geometry:
				if mesh_penetrates_box(mesh,piece.visual) and collisions.size()<12:collisions.append({"path":rail.path,"mesh":str(mesh.name),"equipment":piece.id})
			for piece in game.leg_layout.moving_pieces:
				if mesh_penetrates_box(mesh,piece.visual):collision_record(holder_collisions,"loaded",rail.path,mesh,piece.id)
		for mesh in receiver_meshes:
			for piece in game.leg_layout.moving_pieces:
				if mesh_penetrates_box(mesh,piece.visual):collision_record(receiver_collisions,"loaded_receiver",rail.path,mesh,piece.id)
	note(collisions.is_empty(),"Actual foot toe knee and all loaded source triangles clear racks, crane and pelvis gantry through travel tilt dock",{"collisions":collisions})
	note(holder_collisions.is_empty(),"Loaded source triangles clear holder machinery apart from intended bearing-face contact throughout travel tilt dock",{"collisions":holder_collisions.values()})
	note(receiver_collisions.is_empty(),"Loaded holder machinery clears the actual static pelvis and socket source triangles",{"collisions":receiver_collisions.values()})
	note(world_failures.is_empty(),"Loaded rail payload and holder sweep the full physics world including the grounded hip lift",{"lift_height":lift.height,"failures":world_failure_summary(world_failures)})
	measurements.loaded_world_intervals=61
	measurements.loaded_world_failures=world_failures
	note(support_failures.is_empty(),"Loaded holder stepped supports and bearing link remain grounded with matching scene preview and physics geometry",{"failures":support_failures})
	# Both knee directions have the complete 1.2 m aisle, measured from the
	# actual axle mesh end rather than a hardcoded floor marking.
	rail.path=0;rail.goal=0;rail._pose()
	var axle=source_visual("left_leg","LG-140__001")
	note(axle!=null,"Knee aisle resolves the actual installed axle geometry")
	if axle!=null:
		var bounds = axle.global_transform*axle.mesh.get_aabb()
		for side in [-1.0,1.0]:
			var start = bounds.get_center();start.x = bounds.position.x if side<0 else bounds.end.x
			var shape = BoxShape3D.new();shape.size=Vector3(1.2,.4,.5)
			var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform=Transform3D(Basis.IDENTITY,start+Vector3(side*.6,0,0));query.collision_mask=1;query.margin=.001
			var hits=game.get_world_3d().direct_space_state.intersect_shape(query,8)
			note(hits.is_empty(),"Full 1.2 m extraction aisle clears solid machinery on knee side "+str(side),{"origin":str(query.transform.origin),"hits":str(hits)})

func empty_holder_geometry() -> void:
	var rail=game.equipment.get_equipment("leg_rail")
	var lift=game.equipment.get_equipment("hip_lift")
	await set_lift_geometry(lift.stops[0])
	note(is_equal_approx(lift.height,.15) and not lift.moving and game.equipment.get_equipment("lift_shelf").capture().occupants==["",""],"Empty-holder world fixture matches the played ground lift and empty shelf state")
	rail.path=3;rail.goal=3;rail._pose()
	var result: Dictionary=game.model.install_supported("pelvis","left_leg","left_leg","m2_leg_rail")
	note(result.ok,"Geometry fixture mounts complete leg in pelvis with its canonical source pose")
	if not result.ok:return
	game.runtime.mount("pelvis","left_leg","left_leg")
	for pair in [["ring_1","PV-120__002"],["ring_2","PV-120__001"]]:
		var error: String=game.model.carry_item(pair[1])
		var installed: Dictionary=game.model.install("pelvis",pair[0],pair[1])
		note(error.is_empty() and installed.ok,"Geometry fixture fits opposite physical retaining half "+pair[0])
	game.components.sync("pelvis")
	Staging.fill(game,"pelvis")
	canonical_geometry("pelvis")
	var original: Transform3D=rail.load_body.global_transform
	# Production sweeps exclude runtime bodies to allow intended assembly contacts;
	# independently compare the holder against the entire fixed robot hierarchy.
	var meshes: Array[MeshInstance3D]=[];collect_meshes(game.runtime.node("pelvis"),meshes)
	var collisions: Dictionary={};var stationary=true;var world_failures: Array=[];var support_failures: Array=[]
	var previous_open=0.0
	# The opening phase includes the initial intended side contacts. Actual
	# penetrating triangles are forbidden even before the first movement tick.
	for index in range(21):
		var next_open=float(index)/20
		world_sweep(rail,"release",previous_open,next_open,world_failures)
		rail.jaw_open=next_open;rail._pose();previous_open=next_open
		holder_support_check(rail,"release",next_open,support_failures)
		for piece in game.leg_layout.moving_pieces:
			for mesh in meshes:
				if mesh_penetrates_box(mesh,piece.visual):collision_record(collisions,"release",rail.jaw_open,mesh,piece.id)
		stationary=stationary and rail.load_body.global_transform.is_equal_approx(original)
	rail.engaged=false
	var previous_path=3.0
	for index in range(121):
		var next_path=3.0-float(index)/40
		world_sweep(rail,"empty_return",previous_path,next_path,world_failures)
		rail.path=next_path;rail.goal=rail.path;rail._pose();previous_path=next_path
		holder_support_check(rail,"empty_return",next_path,support_failures)
		for piece in game.leg_layout.moving_pieces:
			for mesh in meshes:
				if mesh_penetrates_box(mesh,piece.visual):collision_record(collisions,"empty_return",rail.path,mesh,piece.id)
		stationary=stationary and rail.load_body.global_transform.is_equal_approx(original)
	# The reverse occupies the same poses, but still run the directional world
	# sweep: safety margins and intervening world equipment are runtime behavior.
	for index in range(121):
		var next_path=float(index)/40
		world_sweep(rail,"empty_advance",previous_path,next_path,world_failures)
		rail.path=next_path;rail.goal=rail.path;rail._pose();previous_path=next_path
		holder_support_check(rail,"empty_advance",next_path,support_failures)
	rail.path=3;rail.goal=3;rail._pose()
	previous_open=1.0
	for index in range(21):
		var next_open=1.0-float(index)/20
		world_sweep(rail,"reacquire",previous_open,next_open,world_failures)
		rail.jaw_open=next_open;rail._pose();previous_open=next_open
		holder_support_check(rail,"reacquire",next_open,support_failures)
		stationary=stationary and rail.load_body.global_transform.is_equal_approx(original)
	note(stationary,"Pelvis alone keeps complete leg stationary through release empty reverse and reacquisition")
	note(collisions.is_empty(),"Actual empty holder machinery clears pelvis retention hardware and stationary mounted leg throughout release and reverse",{"collisions":collisions.values()})
	note(world_failures.is_empty(),"Empty holder release return advance and reacquisition sweep the full world including every hip-lift collision shape",{"lift_height":lift.height,"failures":world_failure_summary(world_failures)})
	measurements.empty_samples=163
	measurements.empty_world_intervals=284
	measurements.empty_world_failures=world_failures
	note(support_failures.is_empty(),"Empty stepped holder and withdrawal link maintain actual grounded support physics and reserved-lane clearance through both directions",{"failures":support_failures})
	measurements.holder_support_samples=345
	# Pin the played failure window explicitly; this assertion must fail against
	# the old cross-slide route even when all leg-only triangle checks pass.
	rail.jaw_open=1;rail.path=1.95;rail.goal=1.95;rail._pose()
	var played_error: String=rail.motion_error(1.95,1.85)
	note(played_error.is_empty(),"Played empty-holder 1.95 to 1.85 window clears the grounded hipDeck collider",{"error":played_error,"lift_height":lift.height})
	await raised_lift_safety(original)

func raised_lift_safety(stationary_leg: Transform3D) -> void:
	var rail=game.equipment.get_equipment("leg_rail")
	var lift=game.equipment.get_equipment("hip_lift")
	rail.path=3;rail.goal=3;rail.jaw_open=1;rail.engaged=false;rail.moving=false;rail.holder_motion="";rail.blocked_reason="";rail._pose()
	await set_lift_geometry(lift.stops[-1])
	var stopped_safely=true;var request_errors: Array=[];var blocked="";var stayed=true
	for stage_index in range(3):
		var error: String=rail.request("return")
		if not error.is_empty():request_errors.append(error);break
		for tick in range(1800):
			if not rail.moving:break
			var before: float=rail.path
			rail.physics(.05)
			stayed=stayed and rail.load_body.global_transform.is_equal_approx(stationary_leg)
			if not rail.blocked_reason.is_empty():
				blocked=rail.blocked_reason
				stopped_safely=not rail.moving and is_equal_approx(rail.path,before) and blocked.begins_with("Clear the fixture route")
				break
		if not blocked.is_empty():break
	var traversed=is_zero_approx(rail.path) and not rail.moving
	note(request_errors.is_empty() and stayed and ((not blocked.is_empty() and stopped_safely) or traversed),"Raised hip lift permits the empty route or stops the holder safely before a world collision",{"lift_height":lift.height,"traversed":traversed,"blocked_reason":blocked,"path":rail.path,"request_errors":request_errors})
	measurements.raised_lift={"height":lift.height,"traversed":traversed,"blocked_reason":blocked,"path":rail.path}
	await set_lift_geometry(lift.stops[0])
	rail.path=3;rail.goal=3;rail.moving=false;rail.blocked_reason="";rail.jaw_open=0;rail._pose()

func obstruction_at(controller: Node, position: Vector3, from: float, to: float, label: String) -> void:
	var blocker=StaticBody3D.new();blocker.name="M3GeometryObstruction";game.add_child(blocker);blocker.position=position
	var collision=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(.04,.04,.04);collision.shape=shape;blocker.add_child(collision)
	await frames(2)
	var error: String=controller.motion_error(from,to)
	note(not error.is_empty(),label,{"position":str(position),"error":error})
	blocker.free();await frames(2)

func obstructed_sweeps() -> void:
	var carrier=game.equipment.get_equipment("foot_carrier")
	# The low traveling bogie is separated from payload geometry by >.2m.
	var preview: Array=carrier.motion_geometry(1.5,0)
	for piece in preview:
		if piece.id=="FootCarrierBogie":await obstruction_at(carrier,piece.world.origin,1.45,1.55,"Carrier motion sweep detects a real obstruction against equipment bogie below payload")
	var rail=game.equipment.get_equipment("leg_rail")
	rail.path=0;rail.goal=0;rail._pose()
	await obstruction_at(rail,game.leg_layout.carrier.global_position+Vector3(0,.3,0),0,.05,"Loaded rail motion sweep detects real obstruction against grounded equipment below payload")
	var foot_rail=source_visual("foot","FA-100__001")
	if foot_rail!=null:
		var faces=actual_faces(foot_rail.mesh)
		await obstruction_at(rail,foot_rail.to_global((faces[0]+faces[1]+faces[2])/3),0,.05,"Loaded rail motion sweep detects real obstruction against actual foot payload")

func passive_restraints() -> void:
	var restraint=game.equipment.get_equipment("joint_restraints")
	note(restraint!=null,"M3 provides actual passive joint restraint equipment")
	if restraint==null:return
	var definitions: Array=Bay.layout().restraints
	for fixture in restraint.fixtures:
		var spec: Dictionary=definitions.filter(func(value):return value.id==fixture.id)[0]
		var contacts: Array=[];var records=records_below(fixture.node)
		for piece_index in range(spec.pieces.size()):
			var authored: Dictionary=spec.pieces[piece_index]
			if not authored.get("contact",false):continue
			var visual: MeshInstance3D=records[piece_index].visual
			var hit=false;var source_id=""
			# Actual intended receiving geometry, including the imported foot rails,
			# must meet a brace pad. Never count a brace touching its own strut.
			var targets: Array[MeshInstance3D]=[];collect_meshes(game.runtime.node("left_leg"),targets)
			for target in targets:
				if not target.has_meta("source_uid") and not target.has_meta("component_uid") and not "__" in str(target.name):continue
				if not (visual.global_transform*visual.mesh.get_aabb()).grow(.01).intersects(target.global_transform*target.mesh.get_aabb()):continue
				if not box_face_contacts(visual,target.mesh,target.global_transform).is_empty():hit=true;source_id=target.get_meta("source_uid",str(target.name));break
			contacts.append({"pad":str(visual.name),"contact":hit,"source":source_id})
		var chain=not records.is_empty()
		for contact in contacts:
			chain=chain and contacts.any(func(other):return other.pad!=contact.pad and other.source!=contact.source and connected(records,contact.pad,other.pad))
		note(fixture.node.visible and contacts.size()>=4 and contacts.all(func(contact):return contact.contact),"Passive "+fixture.id+" has positive actual component pad contact after holder leaves",{"contacts":contacts})
		note(chain,"Passive "+fixture.id+" joins different joint members through each rigid physical side brace")

func run() -> void:
	game=await boot_profile("leg_bay_m3")
	game.player.global_position=Vector3(2,0,3)
	await lift_support_geometry()
	carrier_support()
	crane_sources()
	stage_complete_leg()
	await obstructed_sweeps()
	await mounted_motion()
	await route_geometry()
	await empty_holder_geometry()
	passive_restraints()
	var passed=checks.all(func(check):return check.passed)
	var hashes: Dictionary={}
	for path in ["assets/leg-bay-m3-layout.json","assets/foot-fa01.glb","scripts/foot_carrier.gd","scripts/leg_bay_layout.gd","scripts/leg_rail.gd","scripts/passive_joint_restraints.gd","scripts/work_access_lift.gd","scripts/lift_shelf.gd","scripts/motion_sweep.gd","tests/m3_geometry_test.gd"]:hashes[path]=FileAccess.get_sha256("res://"+path)
	write_evidence("res://verification/m3-geometry-review.json",{"passed":passed,"checks":checks,"findings":findings,"measurements":measurements,"rendered":false,"ordinary_journey":false,"input_hashes":hashes,"engine":Engine.get_version_info().string,"created_utc":Time.get_datetime_string_from_system(true)})
	print("M3_GEOMETRY ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
