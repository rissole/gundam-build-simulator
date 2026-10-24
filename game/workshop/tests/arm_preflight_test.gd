extends "res://tests/kit/harness.gd"
## Actual prepared sources and full rig on the measured paths. Receiving solids
## and support poses are supplied test setup, never player/access acceptance.
const Sweep=preload("res://scripts/motion_sweep.gd")
const Layout=preload("res://scripts/leg_bay_layout.gd")
const Geometry=preload("res://scripts/arm_delivery_geometry.gd")
var game: Node
var arm: Node3D
var mass: Dictionary
var ignored: Array[RID]=[]

func _initialize() -> void:call_deferred("run")

func run() -> void:
	game=await boot_profile("leg_bay_m3")
	var rail=game.equipment.get_equipment("leg_rail")
	expect(rail.request("park").is_empty(),"park the actual leg cradle before using the common limb station")
	for tick in range(1000):
		if not rail.moving:break
		rail.physics(.1)
	expect(is_equal_approx(rail.index_x,22) and not rail.moving,"parked leg cradle remains a live obstacle at X22: "+str(rail.capture()))
	game.set_paused(true) # Geometry staging below deliberately supplies poses.
	await cassette_preflight()
	stage_torso()
	stage_legs()
	var access=game.equipment.get_equipment("workshop_access")
	access.arm_services_stowed=true
	var state: Dictionary=access.capture();state.mode="arm";state.moving=false
	for key in state.channels:state.channels[key]={"value":0.0 if key=="rear" else 1.0,"goal":0.0 if key=="rear" else 1.0}
	access.apply(state)
	await frames(3)
	for side in [-1,1]:
		var id="left_arm" if side<0 else "right_arm"
		var other="right_arm" if side<0 else "left_arm"
		arm=game.runtime.node(id);var definition: Dictionary=game.runtime.definition(id)
		mass=Geometry.mass_properties(game.leg_content,definition)
		expect(mass.center.z>.75 and mass.center.z<4.40 and absf(mass.center.x)<.05 and absf(mass.center.y)<.05,id+" authored source mass is balanced between both rigging pairs: "+str(mass))
		var low=Vector3(INF,INF,INF);var high=-low
		for uid in definition.context_sources:
			for vertex in game.source[uid].mesh.get_faces():
				var p: Vector3=game.source[uid].transform*vertex;low=low.min(p);high=high.max(p)
		expect(low.x>=-.75001 and high.x<=.75001 and low.y>=-.55001 and high.y<=.55001 and low.z>=-.43001 and high.z<=7.45001,id+" actual source includes the restrained hand and all pads inside the selected transport envelope: "+str([low,high]))
		var path: Array[Transform3D]=Geometry.route(side)
		game.runtime.node(other).global_transform=Geometry.route(-side)[-1]
		set_arm(path[0]);await frames(2)
		for theta in [100,180,260]:
			var a=deg_to_rad(theta);var b=deg_to_rad(theta+45)
			var moving=path[0]*Vector3(side*.34*sin(b),.34*cos(b),1.5)
			var fixed=path[-1]*Vector3(side*.46*sin(a),.46*cos(a),.64)
			var moving_ray=PhysicsRayQueryParameters3D.create(moving-path[0].basis.x*.08,moving+path[0].basis.x*.08,15)
			var fixed_ray=PhysicsRayQueryParameters3D.create(fixed-path[-1].basis.x*.13,fixed+path[-1].basis.x*.13,15)
			expect(game.get_world_3d().direct_space_state.intersect_ray(moving_ray).is_empty(),id+" B "+str(theta)+" source lug preserves an actual through pin bore")
			expect(game.get_world_3d().direct_space_state.intersect_ray(fixed_ray).is_empty(),id+" A "+str(theta)+" source clevis and bridge preserve the pin bore")
		ignored=game.leg_layout.blockout.rids_for_groups(["crane_bridge"]);Sweep.collect_rids(arm,ignored)
		var solids: Array[Dictionary]=[];Sweep.collect_shapes(arm,arm.global_transform.affine_inverse(),solids)
		var groups=[{"shapes":solids,"margin":.0001,"error":"Arm source hits {collider}"},
			{"shapes_at":func(pose: Transform3D,_p: float)->Array:return Geometry.rig(pose,mass.center),"margin":.001,"error":"Arm rig hits {collider}"}]
		var original=Geometry.route(side,.65)
		var original_result=Sweep.sweep(game.get_world_3d().direct_space_state,groups,163,func(p: float)->Transform3D:return original[7].interpolate_with(original[8],p),15,ignored)
		expect(not original_result.is_empty(),id+" reproduces planned 0.65 m approach crossing fixed front A clevis")
		for i in range(path.size()-1):
			var a=path[i];var b=path[i+1]
			var excludes: Array[RID]=ignored.duplicate()
			if i==0:excludes.append(game.runtime.node("arm_cassette").get_rid()) # deliberate source-pad contact
			var result=Sweep.sweep(game.get_world_3d().direct_space_state,groups,Sweep.steps(a,b,7.6,.04),func(p: float)->Transform3D:return a.interpolate_with(b,p),15,excludes,id+"_route_"+str(i))
			expect(result.is_empty(),id+" body, four ends, all six tensioned lines and spreader clear segment "+str(i)+": "+str(result))
		var self_error=await rig_self_error(path)
		expect(self_error.is_empty(),id+" continuous upend/yaw/splay rig clears its own arm and temporary restraints: "+self_error)
		var bad_rig=[{"shapes_at":func(pose: Transform3D,_p: float)->Array:return Geometry.rig(pose,mass.center,23,-.24),"margin":.001,"error":"Inboard upper rig hits {collider}"}]
		var bad_result=Sweep.sweep(game.get_world_3d().direct_space_state,bad_rig,60,func(p: float)->Transform3D:return path[8].interpolate_with(path[9],p),15,ignored)
		expect(not bad_result.is_empty(),id+" negative check catches upper suspension anchors routed inward through the fixed cup")
		set_arm(path[-1]);await frames(2)
		# An unopened front level must actually obstruct the measured approach.
		var closed: Dictionary=access.capture();closed.mode="work"
		for key in closed.channels:closed.channels[key]={"value":0.0,"goal":0.0}
		access.apply(closed);await frames(2)
		var obstructed=Sweep.sweep(game.get_world_3d().direct_space_state,groups,163,func(p: float)->Transform3D:return path[7].interpolate_with(path[8],p),15,ignored)
		expect(not obstructed.is_empty(),id+" preflight detects closed front decks in the delivery corridor")
		access.apply(state);await frames(2)
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/arm-preflight.json",{"scope":"source/full-rig geometry preflight; staged torso, both legs and opposite arm; no walking, reach or installation gameplay","checks":checks})
	print("ARM_PREFLIGHT ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)

func cassette_preflight() -> void:
	var blockout=game.leg_layout.blockout;var cassette=game.runtime.node("arm_cassette")
	var controller=game.equipment.get_equipment("arm_cassette")
	arm=game.runtime.node("left_arm")
	for n in range(3):
		var t: float=[1.35,4.05,6.05][n]
		var point=Vector3(14,.99,-6.3+t)
		var ray=PhysicsRayQueryParameters3D.create(point,point+Vector3.UP*.10,arm.collision_layer)
		var hit=game.get_world_3d().direct_space_state.intersect_ray(ray)
		var source=""
		if not hit.is_empty():source=hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape)).get_meta("source_uid","")
		expect(not hit.is_empty() and hit.collider==arm and source=="AL-SUPPORT-"+str(n+1)+"__001" and is_equal_approx(hit.position.y,1.0),"cassette saddle "+str(n+1)+" contacts a structural pad through the actual armor port")
	var layer: int=arm.collision_layer;arm.collision_layer=1<<17;await frames(2)
	var clamp_error=""
	for entry in cassette_shapes():
		if not Sweep.overlap(game.get_world_3d().direct_space_state,entry.shape,cassette.global_transform*entry.transform,1<<17,[],-.0005).is_empty():clamp_error=str(entry.transform);break
	expect(clamp_error.is_empty(),"cassette saddles and six closed clamps meet structural pads without penetrating the prepared arm: "+clamp_error)
	arm.collision_layer=layer
	var supplied: Dictionary=controller.capture();supplied.floor_release=1;controller.apply(supplied)
	var compound: Array[Dictionary]=cassette_shapes()
	Sweep.collect_shapes(arm,cassette.global_transform.affine_inverse(),compound)
	var foot=game.runtime.node("foot");var foot_pose: Transform3D=foot.global_transform
	foot.global_transform=game.equipment.get_equipment("foot_carrier").pose_at(3)
	for id in game.runtime.descendants("foot"):
		var node=game.runtime.node(id);node.force_update_transform();PhysicsServer3D.body_set_state(node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,node.global_transform)
	await frames(3)
	var excludes: Array[RID]=blockout.rids_for_groups(["crane_bridge","arm_cassette"]);Sweep.collect_rids(arm,excludes)
	Sweep.collect_rids(cassette,excludes)
	for key in blockout.pieces:
		if key.begins_with("arm_cassette_floor_pad_") or key.begins_with("arm_park_pedestal_"):excludes.append(blockout.pieces[key].body.get_rid())
	var groups=[{"shapes":compound,"margin":.0001,"error":"Retained cassette hits {collider}"},
		{"shapes_at":func(pose: Transform3D,_p: float)->Array:return controller.rig_solids(pose),"margin":.001,"error":"Cassette rig hits {collider}"}]
	var path=[Vector3(14,0,-6.3),Vector3(14,4.80,-6.3),Vector3(14,4.80,9.9),Vector3(14,0,9.9)]
	for i in range(3):
		var a=Transform3D(Basis.IDENTITY,path[i]);var b=Transform3D(Basis.IDENTITY,path[i+1])
		# Endpoint feet deliberately bear on the flush floor. Sweep the suspended
		# travel from/to 2 mm above contact, preserving floor collision elsewhere.
		if i==0:a.origin.y+=.002
		if i==2:b.origin.y+=.002
		# The low end of the receiving descent is tested after the foot vacates
		# the station. The high crossing must clear that actual horizontal foot.
		if i==2:
			foot.global_transform=foot_pose
			for id in game.runtime.descendants("foot"):
				var node=game.runtime.node(id);node.force_update_transform();PhysicsServer3D.body_set_state(node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,node.global_transform)
			await frames(2)
		var result=Sweep.sweep(game.get_world_3d().direct_space_state,groups,Sweep.steps(a,b,9,.04),func(p: float)->Transform3D:return a.interpolate_with(b,p),15,excludes,"cassette_"+str(i))
		expect(result.is_empty(),"retained arm, whole cassette and four-end rig clear parking transfer segment "+str(i)+": "+str(result))
		if i==1:
			var low=Sweep.sweep(game.get_world_3d().direct_space_state,groups,405,func(p: float)->Transform3D:return Transform3D(Basis.IDENTITY,Vector3(14,1.5,lerpf(-6.3,9.9,p))),15,excludes)
			expect(not low.is_empty(),"too-low cassette transfer collides with the horizontal prepared foot")
	var rig_error=""
	var cassette_layer: int=cassette.collision_layer;cassette.collision_layer=1<<17
	arm.collision_layer=1<<17;await frames(1)
	for entry in controller.rig_solids(cassette.global_transform):
		if entry.rig_kind=="end":continue
		if not Sweep.overlap(game.get_world_3d().direct_space_state,entry.shape,entry.world,1<<17,[],.0001).is_empty():rig_error=entry.rig_kind;break
	expect(rig_error.is_empty(),"four cassette suspension cables and spreader clear their retained arm, frame and clamps: "+rig_error)
	arm.collision_layer=layer
	cassette.collision_layer=cassette_layer
	# Leave the real cassette at the shared station, clamps folded. It remains
	# a swept obstacle during both arms' upending; no source fixture disappears.
	expect(game.model.transfer_supported_assembly("arm_cassette","cassette_park","cassette_station").is_empty(),"stage the same physical cassette on the cleared shared station")
	supplied.floor_release=0;supplied.clamps=[1,1,1,1,1,1];controller.apply(supplied)
	var highest=0.0
	for entry in cassette_shapes():highest=maxf(highest,(cassette.global_transform*entry.transform*entry.shape.get_debug_mesh().get_aabb()).end.y)
	expect(highest<=1.70001,"all released cassette clamps fold below Y1.70: "+str(highest))
	await frames(2)

func cassette_shapes() -> Array[Dictionary]:
	var cassette=game.runtime.node("arm_cassette");var result: Array[Dictionary]=[]
	Sweep.collect_shapes(cassette,cassette.global_transform.affine_inverse(),result)
	return result

func set_arm(pose: Transform3D) -> void:
	arm.global_transform=pose;arm.force_update_transform()
	PhysicsServer3D.body_set_state(arm.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,pose)

func rig_self_error(path: Array[Transform3D]) -> String:
	var layer: int=arm.collision_layer;arm.collision_layer=1<<17
	var error=""
	for segment in range(1,4):
		var a=path[segment];var b=path[segment+1]
		var count=Sweep.steps(a,b,7.6,.06)
		for i in range(count+1):
			var pose=a.interpolate_with(b,float(i)/count)
			set_arm(pose);await frames(1)
			for entry in Geometry.rig(pose,mass.center):
				if entry.rig_kind=="end":continue # deliberate clevis/pad contact
				if not Sweep.overlap(game.get_world_3d().direct_space_state,entry.shape,entry.world,1<<17,[],.0001).is_empty():
					error=entry.rig_kind+" crosses its payload at segment "+str(segment)+" fraction "+str(float(i)/count);break
			if not error.is_empty():break
		if not error.is_empty():break
	arm.collision_layer=layer
	return error

func stage_torso() -> void:
	var fixture=game.equipment.get_equipment("module_supports")
	expect(game.model.transfer_supported_assembly("pelvis","bulky_fixture","pelvis_gantry").is_empty(),"stage pelvis on actual gantry bearings")
	game.runtime.node("pelvis").global_transform=Layout.authored_pose(fixture.spec.receiver_pose)
	var state: Dictionary=fixture.capture();state.jaws=[0,0,0,0];state.jaw_goals=[0,0,0,0];state.locks={"yaw":true,"lean":true};state.source_release=1;fixture.apply(state)
	expect(game.model.transfer_supported_assembly("chest","chest_store","m2_service_crane").is_empty(),"stage chest with declared crane ownership")
	expect(game.model.install_supported("pelvis","chest","chest","m2_service_crane").ok,"stage chest on the actual waist")
	game.runtime.mount("pelvis","chest","chest");Staging.fill(game,"pelvis",game.runtime.definition("pelvis").milestones.chest_connected)
	expect(game.model.transfer_supported_assembly("core","core_store","core_guide").is_empty(),"stage core on declared guide")
	expect(game.model.install_supported("chest","core","core","core_guide").ok,"stage core in the actual chest")
	game.runtime.mount("chest","core","core")
	expect(game.model.transfer_supported_assembly("backpack","backpack_store","m2_service_crane").is_empty(),"stage backpack with crane support")
	expect(game.model.install_supported("chest","backpack","backpack","m2_service_crane").ok,"stage backpack on the actual chest hinge")
	var hinge=game.equipment.get_equipment("backpack_hinge");var hs: Dictionary=hinge.capture()
	hs.active=true;hs.angle=1.0;hs.goal=1.0;hs.struts=[1.0,1.0];hs.strut_goals=[1.0,1.0];hs.latches=[true,true];hs.covers=[true,true];hinge.apply(hs)
	game.runtime.mount("chest","backpack","backpack")
	game.refresh_assembly_collision("chest");game.refresh_assembly_collision("pelvis")

func stage_legs() -> void:
	for side in ["left","right"]:
		var id=side+"_leg";var foot="foot" if side=="left" else "right_foot"
		var foot_record: Dictionary=game.model.assemblies[foot]
		var support: String=game.model.slot_definition(id,"foot").source_supports[0]
		expect(game.model.transfer_supported_assembly(foot,foot_record.location.trim_prefix("support:"),support).is_empty(),"stage "+side+" prepared foot on declared support")
		expect(game.model.install_supported(id,"foot",foot,support).ok,"stage "+side+" foot into structural leg")
		game.runtime.mount(id,"foot",foot);Staging.fill(game,id)
		var from: String=game.model.assemblies[id].location.trim_prefix("support:")
		if from!="m2_leg_rail":expect(game.model.transfer_supported_assembly(id,from,"m2_leg_rail").is_empty(),"stage second leg through shared holder")
		expect(game.model.install_supported("pelvis",id,id,"m2_leg_rail").ok,"stage actual "+side+" leg on its hip")
		game.runtime.mount("pelvis",id,id)
	Staging.fill(game,"pelvis")
	game.refresh_assembly_collision("pelvis")
