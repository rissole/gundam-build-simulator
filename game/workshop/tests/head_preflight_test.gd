extends "res://tests/kit/harness.gd"
## Authored payloads and full spreader/end/cable rigs; no loaded runtime motion.
const Sweep=preload("res://scripts/motion_sweep.gd")
const M3Stages=preload("res://scripts/m3_stages.gd")
var game: Node
var margins: Dictionary={}
var fitted_hardware: Dictionary={}
func _initialize() -> void:call_deferred("run")

func publish(body: Node3D) -> void:
	for node in [body]+body.find_children("*","CollisionObject3D",true,false):
		if node is CollisionObject3D:
			node.force_update_transform();PhysicsServer3D.body_set_state(node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,node.global_transform)

func neighbor_hardware(uid: String, fitted: bool) -> void:
	for node in fitted_hardware.get(uid,[]):node.free()
	fitted_hardware[uid]=[]
	if not fitted:return
	var receiver=game.equipment.get_equipment(uid+"_receiver")
	for sid in receiver.spec.retention_slots:
		var source: Dictionary=game.source[game.model.slot_definition("chest",sid).pose_source]
		var body=StaticBody3D.new();game.add_child(body);body.collision_layer=2;body.collision_mask=0
		var collision=CollisionShape3D.new();collision.shape=source.mesh.create_trimesh_shape();body.add_child(collision)
		body.global_transform=game.runtime.node("chest").global_transform*source.transform;publish(body)
		fitted_hardware[uid].append(body)

func groups_for(crane: Node, solids: Array, expansion: float = 0) -> Array:
	var payload: Array=[]
	for entry in solids:
		if expansion>0 and entry.shape is BoxShape3D:
			var shape=BoxShape3D.new();shape.size=entry.shape.size+Vector3.ONE*2*expansion
			payload.append({"shape":shape,"transform":entry.transform})
		else:payload.append(entry)
	return [{"shapes":payload,"margin":maxf(.001,expansion),"error":"Payload hits {collider}"},
		{"shapes_at":func(frame: Transform3D,_p: float)->Array:return crane.rig_solids(frame),"margin":maxf(.001,expansion),"error":"Rig hits {collider}"}]

func sweep_path(path: Array[Transform3D], groups: Array, ignored: Array[RID], last: int = -1) -> Dictionary:
	for n in range(path.size()-1 if last<0 else last):
		var a=path[n];var b=path[n+1]
		var result=Sweep.sweep(game.get_world_3d().direct_space_state,groups,Sweep.steps(a,b,2.1,.025),func(p: float)->Transform3D:return a.interpolate_with(b,p),15,ignored,"head_"+str(n))
		if not result.is_empty():result.segment=n;return result
	return {}

func run() -> void:
	game=await boot_profile("leg_bay_m3")
	var stages=M3Stages.new(game);var error: String=await stages.run_to("head",func(title):print("PREFLIGHT_SETUP ",title))
	expect(error.is_empty(),"preflight uses the fitted torso, arms, closed pauldrons/backpack and parked equipment: "+error)
	if not error.is_empty():finish();return
	game.set_paused(true)
	var crane=game.equipment.get_equipment("service_crane");var fixture=game.equipment.get_equipment("module_supports")
	var access=game.equipment.get_equipment("workshop_access")
	var access_state: Dictionary=access.capture();access_state.mode="head";access_state.moving=false
	for key in access_state.channels:access_state.channels[key]={"value":0.0,"goal":0.0}
	access.apply(access_state);await frames(2)
	for uid in ["head_baseplate","head_left","head_right","head_top"]:
		neighbor_hardware(uid,false)
		game.set_paused(false);expect(fixture.request("template:"+uid).is_empty(),uid+" fits reusable upright inserts");game.set_paused(true)
		# Both handed routes are checked with the opposite side already seated.
		if uid=="head_left":
			game.runtime.node("head_right").global_transform=game.leg_layout.crane_contract("head_right").receiver_pose;publish(game.runtime.node("head_right"));neighbor_hardware("head_right",true)
		for task in [uid+"_to_fixture",uid]:
			game.set_paused(false);expect(crane.request("task:"+task).is_empty(),task+" selects existing crane contract");game.set_paused(true)
			var path: Array[Transform3D]=crane.route
			var body=game.runtime.node(uid);body.global_transform=path[0];publish(body);await frames(2)
			var ignored: Array[RID]=game.leg_layout.blockout.rids_for_groups(["crane_bridge"])
			Sweep.collect_rids(body,ignored)
			# Exempt only its source saddles and selected intentional fixture contacts.
			for id in game.leg_layout.blockout.pieces:
				var piece: Dictionary=game.leg_layout.blockout.pieces[id]
				if id.begins_with(uid+"_store_") or piece.spec.parent.begins_with("bulky_insert_"+uid) or piece.spec.parent.begins_with("bulky_jaw_"+uid):ignored.append(piece.body.get_rid())
			var solids: Array[Dictionary]=[];Sweep.collect_shapes(body,body.global_transform.affine_inverse(),solids)
			var groups=groups_for(crane,solids)
			var rig: Array=crane.rig_solids(path[0]);var bar=rig[0];var anchors_supported=true
			for anchor in crane.config.spec.spreader_points:
				var p=AssemblyRuntime.vec(anchor)
				anchors_supported=anchors_supported and absf(p.x)<=bar.shape.size.x/2 and absf(p.z)<=bar.shape.size.z/2
			expect(anchors_supported,task+" every suspension anchor lies on the actual spreader")
			var result=sweep_path(path,groups,ignored)
			if not result.is_empty():
				var hit=result.collider;var at=path[result.segment].interpolate_with(path[result.segment+1],float(result.index)/Sweep.steps(path[result.segment],path[result.segment+1],2.1,.025))
				for entry in solids:
					var contact=Sweep.overlap(game.get_world_3d().direct_space_state,entry.shape,at*entry.transform,15,ignored,.001)
					if not contact.is_empty():
						var shape=hit.shape_owner_get_owner(hit.shape_find_owner(contact.shape))
						print("HEAD_CONTACT ",task," vertices=",entry.shape.points if entry.shape is ConvexPolygonShape3D else "box"," moving=",entry.transform," target=",shape.get_meta("source_uid","")," pose=",at);break
			expect(result.is_empty(),task+" complete payload/spreader/ends/cables clear every segment: "+str(result))
			var safe=0.0;var blocked=.02
			# Free transit/approach excludes the final intentional seating contact.
			for iteration in range(6):
				var expansion=(safe+blocked)/2
				if sweep_path(path,groups_for(crane,solids,expansion),ignored,path.size()-2).is_empty():safe=expansion
				else:blocked=expansion
			margins[task]={"free_route_lower_bound_m":safe,"upper_bound_m":blocked if blocked<.02 else null,"search_cap_m":.02,"seating_contact_m":0}
			expect(safe>0,task+" has positive free-route full-payload/full-rig clearance: "+str([safe,blocked]))
			var layer: int=body.collision_layer;body.collision_layer=1<<17;await frames(1)
			var self_error=""
			for entry in crane.rig_solids(path[0]):
				if entry.rig_kind=="contact":continue
				if not Sweep.overlap(game.get_world_3d().direct_space_state,entry.shape,entry.world,1<<17,[],.001).is_empty():self_error=entry.rig_kind;break
			expect(self_error.is_empty(),task+" spreader and cables clear their own load: "+self_error)
			body.collision_layer=layer
			if task==uid:
				var bad=path[1];bad.origin.y-=3.0
				var bad_end=path[3];bad_end.origin.y-=3.0
				var rejected=sweep_path([bad,Transform3D(bad.basis,Vector3(13,bad.origin.y,13)),bad_end],groups,ignored)
				expect(not rejected.is_empty(),uid+" rejects a lower crossing through the fitted body/decks")
				if uid=="head_baseplate":
					var reversed_start=path[-2];var reversed_end=path[-1]
					reversed_start.basis=Basis(Vector3.UP,PI);reversed_end.basis=reversed_start.basis
					expect(not sweep_path([reversed_start,reversed_end],groups,ignored).is_empty(),"reversed baseplate physically collides with the unique front key")
				var lowest=INF;var highest=-INF
				for source in game.runtime.definition(uid).context_sources:
					var bounds: AABB=game.source[source].transform*game.source[source].mesh.get_aabb()
					lowest=minf(lowest,bounds.position.y);highest=maxf(highest,bounds.end.y)
				expect(is_equal_approx(path[1].origin.y+lowest,19),uid+" lowest transit load is Y19.0")
				var hook: float=crane._load_beam(path[1]).origin.y
				expect(hook<=21.58001,uid+" highest hook stays within Y21.58")
				margins[task].overhead_m=23-hook
			body.global_transform=path[-1];publish(body)
		neighbor_hardware(uid,true)
	print("HEAD_MARGINS ",JSON.stringify(margins))
	finish()

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/head-preflight.json",{"scope":"actual payload/full rig source and head routes, fitted neighbors; no walking/reach/rendered review","margins":margins,"checks":checks})
	print("HEAD_PREFLIGHT ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
