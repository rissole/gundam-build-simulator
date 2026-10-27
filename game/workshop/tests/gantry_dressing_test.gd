extends "res://tests/kit/harness.gd"
## Isolated actual blockout/art integration, no robot stages or renderer.
const Fixture = preload("res://tests/kit/equipment_fixture.gd")
const Dressing = preload("res://scripts/gantry_dressing.gd")
const Access = preload("res://scripts/workshop_access.gd")
const Lift = preload("res://scripts/work_access_lift.gd")

class TrackedBlockout extends "res://scripts/workshop_blockout.gd":
	var publications: Array = []
	func publish(ids: Array = []) -> void:
		publications.append(ids.duplicate())
		super.publish(ids)

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var game = Fixture.new();root.add_child(game)
	var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop-layout.json")).workshop
	var world = TrackedBlockout.new();game.add_child(world);world.setup(game,spec)
	var access = Access.new();game.add_child(access);access.setup(game,world)
	var lifts: Array = []
	for side in spec.elevators:
		var data: Dictionary=spec.elevators[side]
		var lift=Lift.new();game.add_child(lift)
		var stops: Array[float]=[];stops.assign(data.levels)
		lift.setup(game,side,AssemblyRuntime.vec(data.origin),Vector2(data.size[0],data.size[1]),stops,data)
		lifts.append(lift)
	_check_landing_fills(world,lifts,access)
	_check_mirrored_access(world,access)
	var before = _collision_state(game)
	var original: Dictionary = {}
	for id in world.pieces:
		var visual: MeshInstance3D=world.pieces[id].visual
		original[id]={"mesh":visual.mesh,"transform":visual.transform,"parent":visual.get_parent(),"visible":visual.visible,"material":visual.material_override}
	var states: Array=[]
	for lift in lifts:states.append(lift.capture())
	var dressing = Dressing.new();dressing.build(world,lifts)
	expect(_collision_state(game)==before,"visual detailing changes no collision nodes, shapes, transforms, layers or masks")
	expect(world.spec==spec,"authored layout data remains identical")
	var changed: Array=[];var untouched: Array=[]
	for id in world.pieces:
		var visual: MeshInstance3D=world.pieces[id].visual
		var prior: Dictionary=original[id]
		if Dressing.selected(id):
			if visual.mesh==prior.mesh or visual.transform!=prior.transform or visual.get_parent()!=prior.parent or visual.visible!=prior.visible:changed.append(id)
		else:
			if visual.mesh!=prior.mesh or visual.material_override!=prior.material or visual.transform!=prior.transform:untouched.append(id)
	expect(changed.is_empty(),"all selected members receive detail while retaining their nodes, poses and visibility: "+str(changed))
	expect(untouched.is_empty(),"unselected room, stock, rigs and crane remain untouched: "+str(untouched))
	var outline = preload("res://scripts/interaction_outline.gd").new();game.add_child(outline)
	for id in world.pieces:
		if not id.begins_with("gantry_jaw_") or not id.ends_with("_handle"):continue
		var handle: MeshInstance3D=world.pieces[id].visual
		outline.focus(handle)
		var copy: Dictionary=outline.copies.get(handle.get_instance_id(),{})
		expect(not copy.is_empty() and copy.outline.mesh==handle.mesh and copy.outline.get_parent()==handle and handle.material_override is ShaderMaterial,"jaw control retains its outline on the detailed opaque mesh: "+id)
	outline.free()
	var outside: Array=[];var bad_faces: Array=[];var triangles=0
	for record in dressing.records:
		var mesh: ArrayMesh=record.visual.mesh
		if not _within(mesh,record.original_bounds):outside.append(record.id)
		if not mesh.get_aabb().is_equal_approx(record.original_bounds):outside.append(record.id+" changed extents")
		if not _outward(mesh):bad_faces.append(record.id)
		triangles+=_triangles(mesh)
	for node in dressing.additions:
		if not _within(node.mesh,node.get_parent().mesh.get_aabb()):outside.append(String(node.name))
		triangles+=_triangles(node.mesh)
	expect(outside.is_empty(),"every replacement vertex and recessed fastener stays inside its original visual envelope: "+str(outside))
	expect(bad_faces.is_empty(),"all generated faces have clockwise front winding, nonzero area and outward normals: "+str(bad_faces))
	expect(triangles<30000,"complete gantry/access/lift treatment stays below 30000 triangles: "+str(triangles))
	expect(dressing.materials.size()==6 and dressing.additions.size()==4 and dressing.labels.size()==7,"six shared finishes, four combined fastener meshes and seven stencils; no per-fastener nodes")
	for node in dressing.labels:
		var h: Vector3=node.get_parent().mesh.get_aabb().size/2
		expect(is_equal_approx(absf(node.position.z),h.z+.001) and not node.no_depth_test and node.shaded,"stencil remains 1 mm off its existing face and receives lighting")
	for x in ["8.8","17.2"]:
		var base: MeshInstance3D=world.pieces["gantry_foot_"+x].visual
		for px in [-.5,.5]:
			for pz in [-.6,.55]:
				var hit: Variant=_hit(base.mesh,Vector3(px,1,pz),Vector3(px,-1,pz))
				expect(hit is Vector3 and is_equal_approx(hit.y,.12),"foundation pocket has a real 30 mm recess at "+x+" / "+str(Vector2(px,pz)))
		var top: Variant=_hit(base.mesh,Vector3(.4,1,0),Vector3(.4,-1,0))
		expect(top is Vector3 and is_equal_approx(top.y,.15),"foundation walking face keeps its original height")
		var column: MeshInstance3D=world.pieces["gantry_column_"+x].visual
		var cover: Variant=_hit(column.mesh,Vector3(0,1.90-column.position.y,-1),Vector3(0,1.90-column.position.y,1))
		expect(cover is Vector3 and is_equal_approx(cover.z,-.297),"inspection cover is a real 3 mm inset, not a coplanar overlay")
	# Verify the actual dressed vertices against the original moving envelope at
	# multiple continuous poses, including finger retraction and folded guards.
	for phase in [0.0,.07,.22,.37,.63,.89,1.0]:
		var values: Dictionary={}
		for key in access.channels:values[key]=phase
		world.apply_frames(access.frames_at(values))
		var escaped: Array=[]
		for record in dressing.records:
			var visual: MeshInstance3D=record.visual
			if visual.get_parent()!=record.parent or visual.transform!=record.transform:escaped.append(record.id)
			var prior: AABB=visual.global_transform*record.original_bounds
			var now: AABB=visual.global_transform*visual.mesh.get_aabb()
			if not prior.grow(.00001).encloses(now):escaped.append(record.id+" world envelope")
		expect(escaped.is_empty(),"detail remains inside moving wings/fingers/bridges/guards at phase "+str(phase)+": "+str(escaped))
	for i in lifts.size():
		var lift: Node3D=lifts[i]
		expect(lift.capture()==states[i],"art pass leaves lift state and stops unchanged")
		for level in [8.4,20.6]:
			lift.height=level;lift._pose()
			var escaped: Array=[]
			for record in dressing.records:
				if not lift.is_ancestor_of(record.visual):continue
				if record.visual.transform!=record.transform or record.visual.get_parent()!=record.parent:escaped.append(record.id)
			expect(escaped.is_empty(),"lift detailing follows original carriage and guides at "+str(level))
	_check_selective_motion(world)
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/gantry-dressing.json",{"scope":"actual authored blockout; visual envelopes, recess geometry, collision identity and supplied intermediate equipment poses; no rendered or player acceptance","records":dressing.records.size(),"triangles":triangles,"unique_meshes":dressing.meshes.size(),"materials":dressing.materials.size(),"checks":checks})
	print("GANTRY_DRESSING ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)

func _check_selective_motion(world) -> void:
	# Compare the index with the original ancestry walk for every authored group.
	var mismatches: Array = []
	for id in world.groups:
		var expected: Array[RID] = []
		for piece in world.pieces.values():
			if piece.has("body") and world.belongs_to(piece.spec.parent,[id]):expected.append(piece.body.get_rid())
		if world.rids_for_groups([id]) != expected:mismatches.append(id)
	expect(mismatches.is_empty(),"indexed collision membership matches authored ancestry for every group: "+str(mismatches))
	var jaw = "gantry_jaw_11.6_26.55"
	var at: Transform3D = world.groups[jaw].transform
	at.origin.y += .125
	world.publications.clear()
	world.apply_frames({jaw:at})
	expect(world.publications == [[jaw]] and world.rids_for_groups([jaw]).size()==3,"one jaw publishes only its three colliders")
	for piece in world.group_pieces[jaw]:
		var actual: Transform3D = PhysicsServer3D.body_get_state(piece.body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
		expect(actual.is_equal_approx(piece.body.global_transform),"jaw physics transform is current before the next physics tick: "+piece.spec.id)
	world.publications.clear()
	world.apply_frames({jaw:at})
	expect(world.publications.is_empty(),"unchanged jaw poses do not publish any colliders")
	# A parent move must include its descendants, even with an unchanged child override.
	var parent_pose: Transform3D = world.groups.crane_bridge.transform
	parent_pose.origin.z += .25
	world.apply_frames({"crane_bridge":parent_pose,"crane_trolley":world.groups.crane_trolley.transform})
	var parent_rids: Array = world.rids_for_groups(["crane_bridge"])
	var union_rids: Array = world.rids_for_groups(["crane_bridge","crane_trolley"])
	expect(parent_rids == union_rids,"overlapping parent and child selections do not duplicate colliders")
	var stale: Array = []
	for piece in world.group_pieces.crane_bridge:
		var actual: Transform3D = PhysicsServer3D.body_get_state(piece.body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
		if not actual.is_equal_approx(piece.body.global_transform):stale.append(piece.spec.id)
	expect(stale.is_empty(),"moving a parent publishes all descendant colliders in the same tick: "+str(stale))
	var insert = "bulky_insert_chest"
	world.enable_group(insert,false)
	expect(world.shapes_at([insert],{}).is_empty(),"indexed sweeps omit disabled inserts")
	world.enable_group(insert,true)
	var enabled: Array = world.shapes_at([insert],{})
	expect(enabled.size()==world.group_pieces[insert].size(),"indexed sweeps see re-enabled inserts without rebuilding membership")
	world.enable_group(insert,true)
	expect(world.shapes_at([insert],{}).size()==enabled.size(),"repeated insert selection preserves enabled collision shapes")

func _piece_bounds(piece: Dictionary) -> AABB:
	var shape: CollisionShape3D = piece.shape
	return shape.global_transform*AABB(-shape.shape.size/2,shape.shape.size)

func _check_landing_fills(world, lifts: Array, access) -> void:
	var expected: Dictionary = {}
	for entry in [["left",8.4,3.22,3.5,23.30],["left",20.6,3.22,3.5,23.30],["right",8.4,20.92,21.0,30.25],["right",20.6,18.0,18.28,30.25]]:
		var id = "lift_"+entry[0]+"_"+str(entry[1])+"_landing_floor"
		expected[id]=AABB(Vector3(entry[2],entry[1]-.2,entry[4]),Vector3(entry[3]-entry[2],.2,1.5))
	var actual: Array = world.pieces.keys().filter(func(id):return id.begins_with("lift_") and id.ends_with("_landing_floor"))
	expect(actual.size()==4,"four fixed thresholds connect only the new raised landings")
	for id in expected:
		expect(world.pieces.has(id),"landing plate exists: "+id)
		if not world.pieces.has(id):continue
		var piece: Dictionary = world.pieces[id]
		var bounds: AABB = _piece_bounds(piece)
		expect(piece.body.get_parent()==world and bounds.is_equal_approx(expected[id]),"plate has fixed parent, flush top and doorway bounds: "+id)
		var left: bool = "_left_" in id
		var lift = lifts[0] if left else lifts[1]
		var deck_shape: CollisionShape3D = null
		for child in lift.deck.get_children():
			if child is CollisionShape3D and child.shape is BoxShape3D and child.shape.size.is_equal_approx(Vector3(2.6,.12,2.6)):deck_shape=child
		expect(deck_shape!=null,"real lift deck collision is available: "+id)
		if deck_shape==null:continue
		var car: AABB = deck_shape.global_transform*AABB(-deck_shape.shape.size/2,deck_shape.shape.size)
		var gap: float = maxf(car.position.x-bounds.end.x,bounds.position.x-car.end.x)
		expect(absf(gap-.02)<.00002,"plate reduces landing slot to 20 mm without touching car: "+id)
		# Include closed doors and guide shoes; test their complete vertical
		# travel envelopes, not just a parked empty car or JSON dimensions.
		var collisions: Array = []
		for child in lift.deck.get_children():
			if not child is CollisionShape3D or not child.shape is BoxShape3D:continue
			var swept: AABB = child.global_transform*AABB(-child.shape.size/2,child.shape.size)
			swept.position.y += lift.stops[0]-lift.height
			swept.size.y += lift.stops[-1]-lift.stops[0]
			if bounds.grow(.001).intersects(swept):collisions.append(str(child.name))
		expect(collisions.is_empty(),"plate clears all car hardware for full lift travel: "+id+" "+str(collisions))
	for mode in access.spec.modes:
		world.apply_frames(access.frames_at(access._goals(mode)))
		var moved: Array = []
		for id in expected:
			if world.pieces.has(id) and not _piece_bounds(world.pieces[id]).is_equal_approx(expected[id]):moved.append(id)
		expect(moved.is_empty(),"landing plates stay fixed in access mode "+mode+": "+str(moved))
	world.apply_frames(access.frames_at(access.values()))

# Compare actual box corners, not just AABBs: intermediate rotated leaves must
# be reflections too. Names of local front/rear rails swap on the 180-degree copy.
func _mirrored_box(left_at: Transform3D, left_box: AABB, right_at: Transform3D, right_box: AABB) -> bool:
	for i in 8:
		var point: Vector3 = left_at*left_box.get_endpoint(i)
		point.x = 26-point.x
		var matched = false
		for j in 8:
			if point.distance_to(right_at*right_box.get_endpoint(j))<.00002:matched = true;break
		if not matched:return false
	return true

func _check_mirrored_access(world, access) -> void:
	var pairs: Dictionary = {}
	for id in world.pieces:
		if not "left" in id or ("right" in id and id.find("right")<id.find("left")):continue
		if not ["wing_left_","finger_","rear_outer_","rear_inner_","hip_apron_","access_gate_"].any(func(prefix):return id.begins_with(prefix)):continue
		var other: String = id.replace("left","SIDE").replace("right","left").replace("SIDE","right")
		if id.begins_with("wing_left_"):
			other = other.replace("_front_","_rear_") if "_front_" in other else other.replace("_rear_","_front_")
		# Fixed fore/aft posts are numbered by increasing world X.
		if world.pieces[id].spec.parent.is_empty() and ("_front_post" in id or "_rear_post" in id):
			other = other.left(-1)+("1" if id.ends_with("0") else "0")
		pairs[id] = other
	var states: Dictionary = {}
	for mode in access.spec.modes:states[mode] = access._goals(mode)
	# Boundaries and partial poses cover guard collapse, inner fold, outer rise,
	# finger retraction and wing swing, independently and together.
	for phase in [.0,.07,.15,.22,.25,.37,.6,.63,.89,1.0]:
		for channel in ["8.4","rear","all"]:
			var values: Dictionary = access._goals("work")
			for key in values:
				if channel=="all" or key==channel:values[key] = phase
			states[channel+"/"+str(phase)] = values
	for label in states:
		world.apply_frames(access.frames_at(states[label]))
		var bad: Array = []
		for id in pairs:
			if not world.pieces.has(pairs[id]):bad.append(id+" missing partner");continue
			var a: Dictionary = world.pieces[id]
			var b: Dictionary = world.pieces[pairs[id]]
			if a.has("shape")!=b.has("shape") or a.visual.visible!=b.visual.visible:
				bad.append(id+" collision/visibility");continue
			if not _mirrored_box(a.visual.global_transform,a.visual.mesh.get_aabb(),b.visual.global_transform,b.visual.mesh.get_aabb()):bad.append(id+" visual")
			if not a.has("shape"):continue
			var at: Transform3D = PhysicsServer3D.body_get_state(a.body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
			var bt: Transform3D = PhysicsServer3D.body_get_state(b.body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
			if a.shape.disabled!=b.shape.disabled or a.body.collision_layer!=b.body.collision_layer or not _mirrored_box(at*a.shape.transform,AABB(-a.shape.shape.size/2,a.shape.shape.size),bt*b.shape.transform,AABB(-b.shape.shape.size/2,b.shape.shape.size)):bad.append(id+" physics")
		expect(bad.is_empty(),"access decks and guards mirror about X13 at "+label+": "+str(bad))
	world.apply_frames(access.frames_at(access._goals("work")))
	for side in ["left","right"]:
		# Existing hip work patch stays 1.2 m long and flush to the wing. The
		# standing-height entrance band must have no rail across it on either side.
		var x: float = 9.6 if side=="left" else 15.2
		var finger: AABB = _piece_bounds(world.pieces["finger_"+side+"_8.4_floor"])
		expect(finger.is_equal_approx(AABB(Vector3(x,8.2,24.6),Vector3(1.2,.2,1.2))),"hip finger keeps its existing work patch: "+side)
		var entrance = AABB(Vector3(x,8.41,24.35),Vector3(1.2,1.7,.5))
		var blockers: Array = []
		for id in world.pieces:
			var piece: Dictionary = world.pieces[id]
			if piece.has("shape") and not piece.shape.disabled and piece.body.collision_layer!=0 and _piece_bounds(piece).intersects(entrance):blockers.append(id)
		expect(blockers.is_empty(),"hip finger entrance is open from the wing: "+side+" "+str(blockers))
		for leaf in ["outer","inner"]:
			var guard: AABB = _piece_bounds(world.pieces["rear_"+leaf+"_"+side+"_guard"])
			expect(absf(guard.position.z-28.55)<.00002 and absf(guard.end.z-28.63)<.00002,"rear leaf guard faces away from hip work: "+leaf+" "+side)
	world.apply_frames(access.frames_at(access.values()))

func _collision_state(root_node: Node) -> Dictionary:
	var result={};var pending: Array[Node]=[root_node]
	while not pending.is_empty():
		var node: Node=pending.pop_back()
		for child in node.get_children():pending.append(child)
		if node is CollisionObject3D:result[str(node.get_instance_id())]=[node.transform,node.collision_layer,node.collision_mask,node.get_parent().get_instance_id()]
		if node is CollisionShape3D:result[str(node.get_instance_id())]=[node.transform,node.shape.get_rid(),node.shape.get_debug_mesh().get_aabb(),node.disabled,node.get_parent().get_instance_id()]
	return result

func _within(mesh: Mesh, bounds: AABB) -> bool:
	for surface in mesh.get_surface_count():
		for vertex in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
			if not bounds.grow(.00001).has_point(vertex):return false
	return true

func _triangles(mesh: Mesh) -> int:
	var count=0
	for surface in mesh.get_surface_count():
		var arrays: Array=mesh.surface_get_arrays(surface)
		count+=(arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null else arrays[Mesh.ARRAY_VERTEX].size())/3
	return count

func _outward(mesh: Mesh) -> bool:
	for surface in mesh.get_surface_count():
		var a: Array=mesh.surface_get_arrays(surface);var vertices: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array=a[Mesh.ARRAY_INDEX];var normals: PackedVector3Array=a[Mesh.ARRAY_NORMAL]
		for i in range(0,indices.size(),3):
			var x=indices[i];var y=indices[i+1];var z=indices[i+2]
			var cross=(vertices[y]-vertices[x]).cross(vertices[z]-vertices[x])
			if cross.length()<.00000001 or cross.dot(normals[x])>=0:return false
	return true

func _hit(mesh: Mesh, from: Vector3, to: Vector3) -> Variant:
	var result: Variant=null
	for surface in mesh.get_surface_count():
		var a: Array=mesh.surface_get_arrays(surface);var v: PackedVector3Array=a[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array=a[Mesh.ARRAY_INDEX]
		for i in range(0,indices.size(),3):
			var hit: Variant=Geometry3D.segment_intersects_triangle(from,to,v[indices[i]],v[indices[i+1]],v[indices[i+2]])
			if hit is Vector3 and (result==null or from.distance_squared_to(hit)<from.distance_squared_to(result)):result=hit
	return result
