extends "res://tests/kit/harness.gd"
## Source solids and complete rig against the selected route, before expanding
## the installation controller. Staged receiving construction is not gameplay.
const Sweep=preload("res://scripts/motion_sweep.gd")
const Layout=preload("res://scripts/leg_bay_layout.gd")
const Solid=preload("res://scripts/solid_handling.gd")
var game: Node
var crane: Node
var body: Node3D
var descriptor: Dictionary
var ignored: Array[RID]=[]
func _initialize() -> void:call_deferred("run")

func run() -> void:
	game=await boot_workshop("pelvis");crane=game.equipment.get_equipment("service_crane")
	body=game.runtime.node("backpack");descriptor=game.runtime.definition("backpack")
	expect(crane.request("task:backpack_store").is_empty(),"same shared crane selects backpack source task")
	var low=Vector3(INF,INF,INF);var high=-low
	for uid in descriptor.context_sources:
		for vertex in game.source[uid].mesh.get_faces():
			var p: Vector3=game.source[uid].transform*vertex;low=low.min(p);high=high.max(p)
	expect(low.x>=-1.20001 and high.x<=1.20001 and low.y>=-.06501 and high.y<=1.00001 and low.z>=-.06501 and high.z<=2.80001,"actual open pack includes hinge eyes and stays within reserved physical envelope: "+str([low,high]))
	for x in [-1.18,1.18]:
		for z in [.5,2.4]:
			var pad=game.leg_layout.blockout.pieces["backpack_store_pad_"+str(x)+"_"+str(z)].visual
			var pad_top: Vector3=pad.global_transform*(pad.mesh.get_aabb().get_center()+Vector3.UP*pad.mesh.get_aabb().size.y/2)
			var query=PhysicsRayQueryParameters3D.create(pad_top-Vector3.UP*.015,pad_top+Vector3.UP*.08,body.collision_layer)
			var hit=game.get_world_3d().direct_space_state.intersect_ray(query)
			expect(not hit.is_empty() and hit.collider==body and absf(hit.position.y-pad_top.y)<.001,"actual storage saddle contacts the downward-facing structural frame")
	var source_error: String=crane._route_error(0,3)
	expect(source_error.is_empty(),"complete pack and rig travel from storage above the still-stored chest: "+source_error)
	# Receiving torso is staged with real model ownership and real source meshes.
	var fixture=game.equipment.get_equipment("module_supports")
	expect(game.model.transfer_supported_assembly("pelvis","bulky_fixture","pelvis_gantry").is_empty(),"stage pelvis on declared receiving bearings")
	game.runtime.node("pelvis").global_transform=Layout.authored_pose(fixture.spec.receiver_pose)
	var state: Dictionary=fixture.capture();state.jaws=[0,0,0,0];state.jaw_goals=[0,0,0,0];state.locks={"yaw":true,"lean":true};state.source_release=1;state.template="backpack";fixture.apply(state)
	expect(game.model.transfer_supported_assembly("chest","chest_store","crane_rigging").is_empty(),"stage chest through declared crane support")
	expect(game.model.install_supported("pelvis","chest","chest","crane_rigging").ok,"stage actual chest on waist")
	game.runtime.mount("pelvis","chest","chest");Staging.fill(game,"pelvis",game.runtime.definition("pelvis").milestones.chest_connected)
	expect(game.model.transfer_supported_assembly("core","core_store","core_guide").is_empty(),"stage core on captured guide")
	expect(game.model.install_supported("chest","core","core","core_guide").ok,"stage actual seated core behind the backpack")
	game.runtime.mount("chest","core","core");game.refresh_assembly_collision("chest");game.refresh_assembly_collision("pelvis")
	await frames(3)
	ignored=game.leg_layout.blockout.rids_for_groups(["crane_bridge","bulky_fixture"]);Sweep.collect_rids(body,ignored)
	var groups=[{"shapes":load_shapes(false),"margin":.0001,"error":"Pack body hits {collider}"},
		{"shapes_at":func(frame: Transform3D,_p: float)->Array:return crane.rig_solids(frame),"margin":.001,"error":"Pack rig hits {collider}"}]
	var positions: Array=Layout.layout().workshop.backpack.route_positions
	for i in range(positions.size()-1):
		var a=Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(positions[i]));var b=Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(positions[i+1]))
		var result=Sweep.sweep(game.get_world_3d().direct_space_state,groups,Sweep.steps(a,b,3,.04),func(p: float)->Transform3D:return a.interpolate_with(b,p),15,ignored,"backpack_route_"+str(i))
		expect(result.is_empty(),"full backpack body, spreader, ends and every cable clear planned route segment "+str(i)+": "+str(result))
	var shortcut_a=Transform3D(Basis.IDENTITY,Vector3(24,5.5,31.8));var shortcut_b=Transform3D(Basis.IDENTITY,Vector3(13,5.5,31.8))
	var shortcut=Sweep.sweep(game.get_world_3d().direct_space_state,groups,275,func(p: float)->Transform3D:return shortcut_a.interpolate_with(shortcut_b,p),15,ignored)
	expect(not shortcut.is_empty(),"complete rig rejects an inward low shortcut through the fixed walkways")
	# Inspect pin bores with actual source triangles, not their motion hulls.
	for side in [-1,1]:
		var center=Vector3(13+side*.9,15.5,27.2)
		var query=PhysicsRayQueryParameters3D.create(center-Vector3.RIGHT*.16,center+Vector3.RIGHT*.16,15,ignored)
		expect(game.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"fixed hinge fork retains an actual clear pin bore")
	# Closure uses deployed three-stage struts between the actual A/B pivots.
	# Their outer/middle/inner source geometry follows the same articulated frame.
	var closed_groups=[{"shapes":load_shapes(true),"margin":.0001,"error":"Rotating backpack hits {collider}"},
		{"shapes_at":func(frame: Transform3D,_p: float)->Array:return deployed_struts(frame),"margin":.0001,"error":"Telescopic strut hits {collider}"},
		{"shapes_at":func(frame: Transform3D,_p: float)->Array:return crane.rig_solids(frame),"margin":.001,"error":"Closing rig hits {collider}"}]
	var pivot=AssemblyRuntime.vec(Layout.layout().workshop.backpack.hinge_seat)
	var closure=Sweep.sweep(game.get_world_3d().direct_space_state,closed_groups,315,func(p: float)->Transform3D:return Transform3D(Basis(Vector3.RIGHT,PI/2*p),pivot),15,ignored,"backpack_closure")
	expect(closure.is_empty(),"full opening/closure sweep includes moving pack, telescopic struts and attached crane rig: "+str(closure))
	var self_error=await rig_self_error(pivot)
	expect(self_error.is_empty(),"spreader and suspension lines clear their own rotating payload: "+self_error)
	var min_height: float=crane.config.spec.rig_min_height;crane.config.spec.erase("rig_min_height")
	var bad_self=await rig_self_error(pivot)
	expect(not bad_self.is_empty(),"self-clearance check catches a spreader lowered into the closing cover")
	crane.config.spec.rig_min_height=min_height
	var services=await service_self_error(pivot)
	expect(services.is_empty(),"protected service routes clear their own rotating cover and retained front crossmember: "+services)
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/backpack-preflight.json",{"scope":"actual source and full-rig preflight against existing route; staged torso; no installation gameplay or access acceptance","checks":checks})
	print("BACKPACK_PREFLIGHT ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)

func load_shapes(omit_struts: bool) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for uid in descriptor.context_sources:
		if omit_struts and uid.begins_with("BP-STRUT-"):continue
		var entries=Solid.authored_shapes(game.leg_content.sources[uid].motion_shapes,AABB())
		for entry in entries:result.append({"shape":entry.shape,"transform":game.source[uid].transform*entry.transform})
	return result

func deployed_struts(frame: Transform3D) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for n in range(2):
		var side=-1 if n==0 else 1
		var b: Vector3=frame*Vector3(side*1.08,.75,1.15)
		var a=game.runtime.node("chest").global_transform*Vector3(side*1.08,2.15,1.27)
		var direction: Vector3=(a-b).normalized()
		var basis=Basis(Vector3.RIGHT,atan2(-direction.y,direction.z))
		var frames={"B":Transform3D(basis,b),"MID":Transform3D(basis,(a+b)/2),"A":Transform3D(basis,a)}
		for key in frames:
			var uid="BP-STRUT-"+key+"__%03d"%(n+1)
			var entries=Solid.authored_shapes(game.leg_content.sources[uid].motion_shapes,AABB())
			for entry in entries:result.append({"shape":entry.shape,"world":frames[key]*entry.transform})
	return result

func rig_self_error(pivot: Vector3) -> String:
	var layer: int=body.collision_layer;var original: Transform3D=body.global_transform
	body.collision_layer=1<<17
	var error=""
	for i in range(181):
		var pose=Transform3D(Basis(Vector3.RIGHT,PI/2*i/180),pivot)
		body.global_transform=pose;body.force_update_transform();PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,pose)
		await frames(1)
		for entry in crane.rig_solids(pose):
			if entry.rig_kind=="contact":continue # magnetic shoes intentionally contact their pads
			var shape: Shape3D=entry.shape;var at: Transform3D=entry.world
			if not Sweep.overlap(game.get_world_3d().direct_space_state,shape,at,1<<17,[],.0001).is_empty():
				error=entry.rig_kind+" intersects payload at "+str(float(i)/2)+" degrees";break
		if not error.is_empty():break
	body.global_transform=original;body.force_update_transform();PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,original);body.collision_layer=layer
	return error

func service_self_error(pivot: Vector3) -> String:
	var layer: int=body.collision_layer;var original: Transform3D=body.global_transform
	body.collision_layer=1<<17
	var controller=game.equipment.get_equipment("backpack_hinge");var error=""
	for i in range(181):
		var amount=float(i)/180;var pose=Transform3D(Basis(Vector3.RIGHT,PI/2*amount),pivot)
		body.global_transform=pose;body.force_update_transform();PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,pose)
		await frames(1)
		for n in range(2):
			var path: Array=controller.service_path(pose,n,amount)
			for j in range(path.size()-1):
				var d: Vector3=path[j+1]-path[j]
				var shape=BoxShape3D.new();shape.size=Vector3(.024,d.length(),.024)
				var at=Transform3D(Basis(Quaternion(Vector3.UP,d.normalized())),(path[j+1]+path[j])/2)
				var hit=Sweep.overlap(game.get_world_3d().direct_space_state,shape,at,1<<17,[],.0001)
				if not hit.is_empty():
					var col=hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape))
					error="service intersects "+str(col.get_meta("source_uid",""))+" at "+str(amount*90)+" degrees / segment "+str(j);break
			if not error.is_empty():break
		if not error.is_empty():break
	body.global_transform=original;body.force_update_transform();PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,original);body.collision_layer=layer
	return error
