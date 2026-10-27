extends "res://tests/kit/harness.gd"
## Coarse A1 geometry/controller contract. No walking, reach, visibility or
## delivered-load route campaign; crane integration belongs to A3.
const Fixture = preload("res://tests/kit/equipment_fixture.gd")
const Blockout = preload("res://scripts/workshop_blockout.gd")
const Access = preload("res://scripts/workshop_access.gd")
const Lift = preload("res://scripts/work_access_lift.gd")
const Dressing = preload("res://scripts/gantry_dressing.gd")
var game: Node3D
var world: Node3D
var access: Node3D
var spec: Dictionary

func _initialize() -> void:run.call_deferred()
func run() -> void:
	game=Fixture.new();root.add_child(game)
	spec=JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop-layout.json")).workshop
	world=Blockout.new();game.add_child(world);world.setup(game,spec)
	access=Access.new();game.add_child(access);access.setup(game,world)
	_check_contract()
	_check_panels()
	_check_walkways()
	_check_upper_loop()
	_check_hinges()
	_check_coarse_clearance()
	_check_lifts()
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/gantry-layout.json",{"scope":"authored solids and actual access/lift transforms; coarse component envelopes; no player or rendered acceptance","checks":checks})
	print("GANTRY_LAYOUT ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)

func bounds(id: String) -> AABB:
	var piece: Dictionary=world.pieces[id]
	return piece.shape.global_transform*AABB(-piece.shape.shape.size/2,piece.shape.shape.size)

func _check_contract() -> void:
	expect(spec.access.levels==[8.4,20.6],"only hip and rope-access levels remain")
	expect(not spec.access.has("modes"),"machine-request configurations are removed")
	var stale: Array=[]
	for id in spec.groups:
		if spec.groups[id].has("level") and not spec.groups[id].level in [8.4,20.6]:stale.append(id)
	for id in world.pieces:
		if id.begins_with("rear_crossover_") or id.ends_with("_landing_fill") or id.begins_with("aft_finger_") or id.begins_with("rear_branch_") or id.begins_with("rear_flank_"):stale.append(id)
	expect(stale.is_empty(),"removed levels, rear crossover and old landing fills are absent: "+str(stale))
	var fingers: Array=spec.groups.keys().filter(func(id):return spec.groups[id].get("joint")=="finger")
	expect(fingers.size()==2 and fingers.all(func(id):return spec.groups[id].level==8.4),"only the retained hip fingers remain")
	for action in ["upper_open","upper_close","lower_open","lower_close"]:
		expect(access.request(action).is_empty(),action+" is a supported player action")
		access.physics(spec.access.duration)
		var saved: Dictionary=access.capture()
		expect(access.validate(saved).is_empty(),action+" at-rest state validates")
		access.apply(saved)
		expect(access.manual_state()[action+"d" if action.ends_with("close") else action],action+" round-trips its locked pose")
	var old: Dictionary=access.capture();old.arm_services_stowed=false
	expect(not access.validate(old).is_empty(),"obsolete service-stow snapshot is rejected, never migrated")
	access.request("upper_close");access.request("lower_close");access.physics(spec.access.duration)
	var anchors=[
		["front_l_9.3","wing_left_20.6",Vector3(4.3,1.2,.75),Vector3(9.3,21.8,24.75)],
		["front_l_10.8","wing_left_20.6",Vector3(5.8,1.2,.75),Vector3(10.8,21.8,24.75)],
		["front_l_11.9","wing_left_20.6",Vector3(6.9,1.2,.75),Vector3(11.9,21.8,24.75)],
		["front_l_12.6","wing_left_20.6",Vector3(7.6,1.2,.75),Vector3(12.6,21.8,24.75)],
		["front_r_13.4","wing_right_20.6",Vector3(7.6,1.2,-.75),Vector3(13.4,21.8,24.75)],
		["front_r_14.1","wing_right_20.6",Vector3(6.9,1.2,-.75),Vector3(14.1,21.8,24.75)],
		["front_r_15.2","wing_right_20.6",Vector3(5.8,1.2,-.75),Vector3(15.2,21.8,24.75)],
		["front_r_16.7","wing_right_20.6",Vector3(4.3,1.2,-.75),Vector3(16.7,21.8,24.75)],
		["rear_11.0","",Vector3(11,21.8,28.3),Vector3(11,21.8,28.3)],
		["rear_12.4","",Vector3(12.4,21.8,28.3),Vector3(12.4,21.8,28.3)],
		["rear_13.6","",Vector3(13.6,21.8,28.3),Vector3(13.6,21.8,28.3)],
		["rear_15.0","",Vector3(15,21.8,28.3),Vector3(15,21.8,28.3)]]
	expect(spec.rope_stations.size()==anchors.size(),"exactly twelve rope stations")
	for i in anchors.size():
		var record: Dictionary=spec.rope_stations[i];var wanted: Array=anchors[i]
		var edge="front" if i<8 else "rear"
		expect(record.id==wanted[0] and record.parent==wanted[1] and record.edge==edge and AssemblyRuntime.vec(record.anchor).is_equal_approx(wanted[2]),"fixed station contract: "+wanted[0])
		var point: Vector3=world.frame_at(record.parent,{})*AssemblyRuntime.vec(record.anchor)
		expect(point.is_equal_approx(wanted[3]),"closed world anchor: "+wanted[0])
		# Check an entire 0.9 m opening through the guard, below its overhead
		# davit. Adjacent openings can share a gap; gate barriers belong to A2.
		var gap=AABB(Vector3(point.x-.449,20.61,24.5 if i<8 else 30.20),Vector3(.898,1.08,.20))
		var blocked: Array=[]
		for id in world.pieces:
			var piece: Dictionary=world.pieces[id]
			if not piece.has("shape") or not Dressing.selected(id):continue
			if bounds(id).intersects(gap):blocked.append(id)
		expect(blocked.is_empty(),"station has a full guard opening: "+wanted[0]+" "+str(blocked))

func panel_bounds(bank: Node3D) -> Array[AABB]:
	var result: Array[AABB]=[]
	for node in bank.get_children():
		if node is CollisionShape3D:result.append(node.global_transform*node.shape.get_debug_mesh().get_aabb())
	for entry in access.controls():
		if bank.is_ancestor_of(entry.node):result.append(entry.node.global_transform*entry.node.mesh.get_aabb())
	return result

func _check_panels() -> void:
	expect(access.get_child_count()==2 and access.controls().size()==4,"two fixed banks with one Open/Close pair each")
	for bank in access.get_children():
		var lower=is_equal_approx(bank.position.y,8.4)
		var tag="8.4" if lower else "20.6"
		var front="lower" if lower else "upper"
		var apron=bounds("wing_hinge_left_"+tag+"_floor")
		var foot=bank.global_transform*AABB(Vector3(-.04,0,-.04),Vector3(.08,.01,.08))
		expect(is_equal_approx(bank.position.y,float(tag)) and apron.grow(.011).encloses(foot) and bank.get_parent()==access,"bank stands on its fixed left lift hinge apron at "+tag)
		var entries=access.controls().filter(func(entry):return bank.is_ancestor_of(entry.node))
		expect(entries.map(func(entry):return entry.action)==[front+"_open",front+"_close"],"bank row matches its level at "+tag)
		var envelopes=panel_bounds(bank)
		var collisions=[]
		for step in 21:
			var phase=step/20.0
			world.apply_frames(access.frames_at({"8.4":phase,"20.6":phase,"rear":phase}))
			for id in world.pieces:
				var piece: Dictionary=world.pieces[id]
				if not piece.has("shape") or piece.spec.parent.is_empty():continue
				var box=bounds(id)
				# Deck tops meet the pedestal base plane; only above-deck solids
				# can obstruct it (rotated floor AABBs overstate the corner sweep).
				if box.end.y<=bank.position.y+.001:continue
				if envelopes.any(func(panel):return panel.grow(.005).intersects(box)) and id not in collisions:collisions.append(id)
		expect(collisions.is_empty(),"bank and buttons clear wings, fingers, gates and rear leaves throughout motion at "+tag+": "+str(collisions))
	world.apply_frames(access.frames_at({}))

func _check_walkways() -> void:
	var rear: AABB=bounds("rope_exit_floor").merge(bounds("rope_exit_landing_floor"))
	expect(rear.is_equal_approx(AABB(Vector3(5,20.4,30.25),Vector3(13,.2,1.5))),"exit deck and widened east landing span X5..18 at 20.6")
	expect(bounds("rope_exit_landing_floor").size.is_equal_approx(Vector3(1.5,.2,1.5)),"east lift has a 1.5 m square landing")
	for station in spec.rope_stations:
		if station.edge!="rear":continue
		var boom: AABB=bounds("rope_boom_"+station.id)
		expect(is_equal_approx(boom.position.z,28.3) and is_equal_approx(boom.end.z,30.3) and boom.size.x<=.15 and boom.size.y<=.15 and is_equal_approx(boom.get_center().y,21.8),"fixed two-metre boom at "+station.id)
	var west: AABB=bounds("rope_exit_west_post")
	expect(west.position.y==0 and is_equal_approx(west.end.y,20.4) and not west.intersects(bounds("outer_left_8.4_floor")) and not west.intersects(bounds("outer_inner_left_8.4_1")),"floor-supported west post clears retained lower walk and guard")
	for id in ["rope_exit_lift_post_29.55","rope_exit_lift_post_32.45","rope_exit_lift_header"]:
		expect(bounds(id).end.y<=20.201,"east support structure stays below 20.2: "+id)
	for side in ["left","right"]:
		var link: AABB=bounds("hip_link_"+side+"_floor")
		var apron: AABB=bounds("hip_apron_"+side+"_floor")
		var outer: AABB=bounds("outer_"+side+"_8.4_floor")
		expect(link.grow(.001).intersects(apron) and link.grow(.001).intersects(outer) and is_equal_approx(link.size.z,1.5),"retained hip apron has a continuous fixed 1.5 m connection: "+side)
	# These are solid apertures at the retained landing, not walked acceptance.
	for opening in [AABB(Vector3(3.21,8.41,23.301),Vector3(.4,1.09,1.498)),AABB(Vector3(3.6,8.41,24.70),Vector3(1.1,1.7,.4))]:
		var blocked: Array=[]
		for id in world.pieces:
			if world.pieces[id].has("shape") and bounds(id).intersects(opening):blocked.append(id)
		expect(blocked.is_empty(),"left 8.4 landing has no fixed rail across the lift doorway or outer-walk connection: "+str(blocked))

func _check_upper_loop() -> void:
	# Surface adjacency and fixed joint apertures, not a simulated player walk.
	var perimeter=["wing_hinge_left_20.6_floor","wing_left_20.6_floor","wing_right_20.6_floor",
		"wing_hinge_right_20.6_floor","rope_side_right_floor","rope_corner_right_floor",
		"rope_link_right_floor","rope_exit_landing_floor","rope_exit_floor","rope_side_left_floor"]
	for i in perimeter.size():
		var a: AABB=bounds(perimeter[i]);var b: AABB=bounds(perimeter[(i+1)%perimeter.size()])
		expect(is_equal_approx(a.end.y,20.6) and a.grow(.025).intersects(b.grow(.025)),"upper perimeter has a flush connection: "+perimeter[i]+" to "+perimeter[(i+1)%perimeter.size()])
	for opening in [
		AABB(Vector3(3.6,20.61,24.65),Vector3(1.3,1.7,.2)),
		AABB(Vector3(21.1,20.61,24.65),Vector3(1.3,1.7,.2)),
		AABB(Vector3(4.9,20.61,30.45),Vector3(.2,1.7,1.1)),
		AABB(Vector3(20.9,20.61,27.85),Vector3(.2,1.7,1.2)),
		AABB(Vector3(16.6,20.61,29.1),Vector3(1.2,1.7,.2)),
		AABB(Vector3(16.6,20.61,30.2),Vector3(1.2,1.7,.2)),
		AABB(Vector3(16.4,20.61,30.4),Vector3(.2,1.7,1.2))]:
		var blocked: Array=[]
		for id in world.pieces:
			if world.pieces[id].has("shape") and bounds(id).intersects(opening):blocked.append(id)
		expect(blocked.is_empty(),"fixed upper join has no obsolete end guard or support across it: "+str(blocked))
	for id in perimeter:
		if not id.begins_with("rope_"):continue
		var fixed: AABB=bounds(id)
		world.apply_frames(access.frames_at({"8.4":1.0,"20.6":1.0,"rear":1.0}))
		expect(bounds(id).is_equal_approx(fixed),"side/rear loop remains fixed when the front crane opening opens: "+id)
		world.apply_frames(access.frames_at({}))

func _check_hinges() -> void:
	expect(not world.pieces.has("wing_axle_left") and not world.pieces.has("wing_axle_right"),"neither front hinge retains a through-post in the walking surface")
	var corner: AABB=bounds("wing_corner_right")
	expect(corner.position.y==0 and is_equal_approx(corner.end.y,20.4) and corner.position.x>22.5 and corner.end.z<23.4,"opposite column stands beyond the far outer apron corner")
	for side in ["left","right"]:
		var hx: float=5 if side=="left" else 21
		for level in [8.4,20.6]:
			var id="wing_"+side+"_"+str(level)
			var apron: AABB=bounds("wing_hinge_"+side+"_"+str(level)+"_floor")
			var leaf: AABB=bounds(id+"_floor")
			expect(apron.size.is_equal_approx(Vector3(1.5,.2,1.3)) and leaf.size.is_equal_approx(Vector3(7.96,.2,1.2)) and apron.grow(.021).intersects(leaf),side+" plain landing meets a single rectangular leaf with a 20 mm seam")
			var obsolete=["wing_bearing_"+side+"_"+str(level),id+"_root_front_floor",id+"_root_rear_floor","wing_hinge_"+side+"_"+str(level)+"_front_floor","wing_hinge_"+side+"_"+str(level)+"_rear_floor"]
			expect(obsolete.all(func(piece_id):return not world.pieces.has(piece_id)),side+" pole cap and four isolated notch fillers are removed at "+str(level))
			var former_post=AABB(Vector3(hx-.13,level+.001,23.87),Vector3(.26,2,.26))
			var blockers: Array=[]
			for piece_id in world.pieces:
				if world.pieces[piece_id].has("shape") and bounds(piece_id).intersects(former_post):blockers.append(piece_id)
			expect(blockers.is_empty(),side+" former through-post position is unobstructed above the deck: "+str(blockers))
			var arm: AABB=bounds("wing_support_"+side+"_"+str(level)+"_arm")
			var mount: AABB=bounds("wing_support_"+side+"_"+str(level)+("_shaft" if side=="left" else "_corner"))
			expect(arm.grow(.001).intersects(apron) and arm.grow(.001).intersects(leaf) and arm.intersects(mount) and is_equal_approx(arm.end.y,level-.2) and is_equal_approx(mount.end.y,level-.2),side+" connected bracket supports the landing and leaf from beneath at "+str(level))
			if side=="right":expect(mount.intersects(corner),"right bracket connects to the relocated corner column at "+str(level))
			var root_node: Node3D=world.groups[id]
			expect(root_node.position.is_equal_approx(Vector3(hx,level,24)),id+" shares the unchanged axle")
	for phase in [0.0,.25,.50,.75,1.0]:
		world.apply_frames(access.frames_at({"8.4":phase,"20.6":phase,"rear":0.0}))
		for side in ["left","right"]:
			var lower: Transform3D=world.groups["wing_"+side+"_8.4"].global_transform
			var upper: Transform3D=world.groups["wing_"+side+"_20.6"].global_transform
			expect(lower.basis.is_equal_approx(upper.basis) and (upper.origin-lower.origin).is_equal_approx(Vector3(0,12.2,0)),side+" both levels share the swing at "+str(phase))
			if phase==1.0:
				var tip: Vector3=upper*Vector3(8,0,0)
				expect(tip.is_equal_approx(Vector3(5 if side=="left" else 21,20.6,16)),side+" fully open upper leaf points toward the workshop")
	world.apply_frames(access.frames_at({}))

func _check_coarse_clearance() -> void:
	# Own-mesh unions from the approved concept mock, grown .5 m (head .75).
	var robot=[
		AABB(Vector3(10.96,8.67,25.18),Vector3(4.08,4.18,1.64)).grow(.5),
		AABB(Vector3(10.05,12.23,24.87),Vector3(5.90,6.47,3.04)).grow(.5),
		AABB(Vector3(11.80,12.70,27.13),Vector3(2.40,2.87,1.07)).grow(.5),
		AABB(Vector3(8.66,8.52,25.25),Vector3(2.73,7.94,1.44)).grow(.5),
		AABB(Vector3(14.61,8.52,25.25),Vector3(2.73,7.94,1.44)).grow(.5),
		AABB(Vector3(11.69,16.80,25.21),Vector3(2.62,2.61,1.69)).grow(.75)]
	var collisions: Array=[];var high: Array=[]
	for id in world.pieces:
		var piece: Dictionary=world.pieces[id]
		if not piece.has("shape") or not Dressing.selected(id):continue
		var box: AABB=bounds(id)
		if box.end.y>22.401:high.append(id)
		if not world.belongs_to(piece.spec.parent,["wing_left_20.6","wing_right_20.6"]) and not id.begins_with("rope_"):continue
		if robot.any(func(body):return body.intersects(box)):collisions.append(id)
	expect(high.is_empty(),"all gantry/access members stay at or below Y22.4 under the travelling bridge: "+str(high))
	expect(collisions.is_empty(),"closed upper access clears coarse grown robot envelopes, including head top Y20.16: "+str(collisions))
	# Parked open leaves are above the floor-equipment envelope. Compare full
	# boxes, not plan alone: these lanes intentionally pass beneath the leaves.
	world.apply_frames(access.frames_at({"8.4":1.0,"20.6":1.0,"rear":1.0}))
	var equipment=[AABB(Vector3(7.3,0,22.3),Vector3(1,2,1)),AABB(Vector3(7.9,0,20),Vector3(1,2,1)),AABB(Vector3(17.1,0,20),Vector3(1,2,1)),AABB(Vector3(-2.25,0,6),Vector3(11,6.5,12))]
	var mobile: Dictionary=spec.mobile_platform
	for route in mobile.routes.values():
		var previous=AssemblyRuntime.vec(mobile.docks.park)
		for point in route:
			var next=AssemblyRuntime.vec(point)
			equipment.append(AABB(previous-Vector3(1.2,0,1),Vector3(2.4,4.5,2)).merge(AABB(next-Vector3(1.2,0,1),Vector3(2.4,4.5,2))))
			previous=next
	var blocked: Array=[]
	for side in ["left","right"]:
		for level in [8.4,20.6]:
			for piece in world.group_pieces["wing_"+side+"_"+str(level)]:
				var box: AABB=bounds(piece.spec.id)
				if equipment.any(func(other):return other.intersects(box)):blocked.append(piece.spec.id)
	expect(blocked.is_empty(),"open leaf solids clear console, rail gates, bulky bay and mobile route envelopes: "+str(blocked))
	world.apply_frames(access.frames_at({}))

func _check_lifts() -> void:
	for side in ["left","right"]:
		var data: Dictionary=spec.elevators[side]
		var lift=Lift.new();game.add_child(lift)
		var stops: Array[float]=[];stops.assign(data.levels)
		lift.setup(game,side,AssemblyRuntime.vec(data.origin),Vector2(data.size[0],data.size[1]),stops,data)
		var origin=Vector3(1.9,0,24.05) if side=="left" else Vector3(19.6,0,31)
		expect(lift.position.is_equal_approx(origin) and lift.deck_size==Vector2(2.6,2.6) and stops==[.15,8.4,20.6],side+" actual lift position, car size and three stops")
		var fixed: Node3D=lift.get_node("FloorAnchoredLiftGuides")
		if side=="left":
			for level in [8.4,20.6]:
				var bracket: AABB=bounds("wing_support_left_"+str(level)+"_shaft")
				var contacts=0
				for node in fixed.get_children():
					if node is CollisionShape3D and bracket.intersects(node.global_transform*node.shape.get_debug_mesh().get_aabb()):contacts+=1
				expect(contacts==1,"left hinge bracket transfers to the fixed lift shaft at "+str(level))
		var guide_top=0.0
		for node in fixed.get_children():
			if node is CollisionShape3D:guide_top=maxf(guide_top,(node.global_transform*node.shape.get_debug_mesh().get_aabb()).end.y)
		expect(is_equal_approx(guide_top,20.2),side+" fixed guides end at 20.2")
		for index in stops.size():
			lift.apply({"height":stops[index],"destination":stops[index],"moving":false})
			var open_side: int=1 if side=="left" or index<2 else -1
			expect(lift.door_open(open_side) and not lift.door_open(-open_side),side+" opens only its landing side at "+str(stops[index]))
			var calls: Array=lift.controls().filter(func(entry):return entry.action=="stop"+str(index))
			expect(calls.size()==1 and signf(calls[0].point.x-origin.x)==open_side and is_equal_approx(calls[0].point.y,stops[index]+1),side+" exactly one physical call at the correct side/height")
			var contacts=0;var low=INF;var high=-INF
			for carriage in lift._guide_carriages:
				for node in carriage.get_children():
					if not node is CollisionShape3D:continue
					var box: AABB=node.global_transform*node.shape.get_debug_mesh().get_aabb()
					low=minf(low,box.position.y);high=maxf(high,box.end.y)
					if not node.name.begins_with("GuideCarriage_"):continue
					for column in fixed.get_children():
						if not column is CollisionShape3D or column.shape.get_debug_mesh().get_aabb().size.y<2:continue
						if box.intersects(column.global_transform*column.shape.get_debug_mesh().get_aabb()):contacts+=1
			expect(contacts==2 and low>=0 and high<=22.4,side+" both sliding carriages engage guides above the floor and below the bridge at "+str(stops[index]))
			var ceiling: Array=[]
			for node in lift.deck.get_children():
				if not node is CollisionShape3D:continue
				var box: AABB=node.global_transform*node.shape.get_debug_mesh().get_aabb()
				if box.end.y>22.4:ceiling.append(str(node.name))
				if box.size.x>2 and box.size.z>2 and box.position.y>stops[index]:ceiling.append("roof")
			expect(ceiling.is_empty(),side+" car stays open-topped below the crane: "+str(ceiling))
		lift.request("stop1")
		expect(lift.side_gates.all(func(door):return not door.disabled and door.get_meta("visual").visible),side+" both physical doors close during travel")
		# Check the hardware outside the rider/deck box too. Only authored
		# scenery is compared here; intentional contact with this lift's own
		# guides and sliding sleeve is not an obstruction.
		lift.apply({"height":stops[0],"destination":stops[0],"moving":false})
		var overlaps: Array=[]
		var moving_bodies: Array=[lift.deck]+lift._guide_carriages
		for body in moving_bodies:
			var travel: float=stops[-1]-stops[0] if body==lift.deck else data.guide_top-.2-body.position.y
			for node in body.get_children():
				if not node is CollisionShape3D:continue
				var swept: AABB=node.global_transform*node.shape.get_debug_mesh().get_aabb()
				swept.size.y+=travel
				for bank in access.get_children():
					if panel_bounds(bank).any(func(panel):return panel.intersects(swept)):overlaps.append("gantry panel / "+str(body.name))
				for id in world.pieces:
					if not world.pieces[id].has("shape"):continue
					if swept.grow(-.001).intersects(bounds(id)):overlaps.append(id+" / "+str(body.name)+" / "+str(node.name))
		expect(overlaps.is_empty(),side+" complete car and guide-carriage travel clears fixed authored scenery: "+str(overlaps))
