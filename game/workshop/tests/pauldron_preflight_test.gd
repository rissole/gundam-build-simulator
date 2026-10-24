extends "res://tests/kit/harness.gd"
## Full authored carriers and complete two-end rigs, before runtime integration.
const Sweep=preload("res://scripts/motion_sweep.gd")
const Stages=preload("res://scripts/build_stages.gd")
var game: Node
var margins: Dictionary={}
func _initialize() -> void:call_deferred("run")

func publish(body: Node3D) -> void:
	for node in [body]+body.find_children("*","CollisionObject3D",true,false):
		if node is CollisionObject3D:
			node.force_update_transform();PhysicsServer3D.body_set_state(node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,node.global_transform)

func run() -> void:
	game=await boot_workshop()
	var stages=Stages.new(game);var error: String=await stages.run_to("pauldrons")
	expect(error.is_empty(),"preflight uses the fitted torso, legs, both retained shoulders and parked equipment: "+error)
	if not error.is_empty():finish();return
	game.set_paused(true)
	var crane=game.equipment.get_equipment("service_crane")
	var access=game.equipment.get_equipment("workshop_access")
	var access_state: Dictionary=access.capture();access_state.mode="head";access_state.moving=false
	for key in access_state.channels:access_state.channels[key]={"value":0.0,"goal":0.0}
	access.apply(access_state);await frames(2)
	for side in ["left","right"]:
		var uid=side+"_pauldron";var other=("right" if side=="left" else "left")+"_pauldron"
		# Select only to configure the shared geometry; no runtime motion is run.
		game.set_paused(false);expect(crane.request("task:"+uid).is_empty(),uid+" selects its existing two-end hook");game.set_paused(true)
		var path: Array[Transform3D]=crane.route
		var body=game.runtime.node(uid);body.global_transform=path[0];publish(body)
		game.runtime.node(other).global_transform=game.leg_layout.crane_contract(other).receiver_pose;publish(game.runtime.node(other))
		await frames(2)
		var ignored: Array[RID]=game.leg_layout.blockout.rids_for_groups(["crane_bridge"])
		Sweep.collect_rids(body,ignored)
		# Only intentional source saddle contact is exempt; all other parked kit stays live.
		for id in game.leg_layout.blockout.pieces:
			if id.begins_with(uid+"_store_"):ignored.append(game.leg_layout.blockout.pieces[id].body.get_rid())
		var solids: Array[Dictionary]=[];Sweep.collect_shapes(body,body.global_transform.affine_inverse(),solids)
		var groups=[{"shapes":solids,"margin":.001,"error":"Carrier hits {collider}"},
			{"shapes_at":func(frame: Transform3D,_p: float)->Array:return crane.rig_solids(frame),"margin":.001,"error":"Complete rig hits {collider}"}]
		for n in range(path.size()-1):
			var a=path[n];var b=path[n+1]
			var result=Sweep.sweep(game.get_world_3d().direct_space_state,groups,Sweep.steps(a,b,1.2,.025),func(p: float)->Transform3D:return a.interpolate_with(b,p),15,ignored,uid+"_"+str(n))
			if not result.is_empty():
				var hit_body: CollisionObject3D=result.collider
				var frame=a.interpolate_with(b,float(result.index)/Sweep.steps(a,b,1.2,.025))
				for entry in solids:
					var hit=Sweep.overlap(game.get_world_3d().direct_space_state,entry.shape,frame*entry.transform,15,ignored,.001)
					if not hit.is_empty():
						var col=hit_body.shape_owner_get_owner(hit_body.shape_find_owner(hit.shape))
						print("PAULDRON_CONTACT ",uid," ",col.get_meta("physical_uid",col.get_meta("source_uid",""))," shape=",col.transform," moving=",entry.transform);break
			expect(result.is_empty(),uid+" payload/spreader/ends/cables clear route segment "+str(n)+": "+str(result))
		var bad=path[5];bad.origin.x=path[0].origin.x
		var bad_end=path[5]
		var rejected=Sweep.sweep(game.get_world_3d().direct_space_state,groups,Sweep.steps(bad,bad_end,1.2,.025),func(p: float)->Transform3D:return bad.interpolate_with(bad_end,p),15,ignored)
		expect(not rejected.is_empty(),uid+" rejects cross-workshop carry at final-approach height")
		# The body and its own complete rig must also clear one another.
		var layer: int=body.collision_layer;body.collision_layer=1<<17;await frames(1)
		var self_error=""
		for entry in crane.rig_solids(path[0]):
			if entry.rig_kind=="contact":continue
			if not Sweep.overlap(game.get_world_3d().direct_space_state,entry.shape,entry.world,1<<17,[],.001).is_empty():self_error=entry.rig_kind;break
		expect(self_error.is_empty(),uid+" suspension and spreader clear their own carrier: "+self_error)
		body.collision_layer=layer
		var bounds=AABB()
		var first=true
		for source in game.runtime.definition(uid).context_sources:
			var box: AABB=game.source[source].transform*game.source[source].mesh.get_aabb()
			bounds=box if first else bounds.merge(box);first=false
		var low: float=path[1].origin.y+bounds.position.y
		var top: float=path[1].origin.y+bounds.end.y
		var beam: Transform3D=crane._load_beam(path[1])
		# Expand every box in the payload and complete rig, preserving the same
		# route samples and obstacle set. This gives a measured conservative
		# clearance bound, excluding intentional source/magnet contact only.
		var safe=0.0;var blocked=.02
		for iteration in range(6):
			var expansion=(safe+blocked)/2
			var expanded: Array[Dictionary]=[]
			for entry in solids:
				var shape=BoxShape3D.new();shape.size=entry.shape.size+Vector3.ONE*2*expansion
				expanded.append({"shape":shape,"transform":entry.transform})
			var expanded_groups=[{"shapes":expanded,"error":"Expanded payload hits {collider}"},
				{"shapes_at":func(frame: Transform3D,_p: float)->Array:
					var parts: Array=crane.rig_solids(frame)
					for part in parts:
						var shape=BoxShape3D.new();shape.size=part.shape.size+Vector3.ONE*2*expansion;part.shape=shape
					return parts,"error":"Expanded rig hits {collider}"}]
			var clear=true
			for n in range(path.size()-1):
				var a=path[n];var b=path[n+1]
				if not Sweep.sweep(game.get_world_3d().direct_space_state,expanded_groups,Sweep.steps(a,b,1.2,.025),func(p: float)->Transform3D:return a.interpolate_with(b,p),15,ignored).is_empty():clear=false;break
			if clear:safe=expansion
			else:blocked=expansion
		var seated_bounds: AABB=path[-1]*bounds
		var notch_front=INF;var notch_rear=INF
		for piece in game.leg_layout.blockout.pieces.values():
			if not piece.has("body") or not piece.spec.id.ends_with("_floor"):continue
			var size=AssemblyRuntime.vec(piece.spec.size)
			var floor_bounds: AABB=piece.body.global_transform*AABB(-size/2,size)
			if not is_equal_approx(floor_bounds.end.y,16.4) or floor_bounds.end.x<seated_bounds.position.x or floor_bounds.position.x>seated_bounds.end.x:continue
			if floor_bounds.end.z<=seated_bounds.position.z:notch_front=minf(notch_front,seated_bounds.position.z-floor_bounds.end.z)
			if floor_bounds.position.z>=seated_bounds.end.z:notch_rear=minf(notch_rear,floor_bounds.position.z-seated_bounds.end.z)
		margins[uid]={"sampled_clearance_lower_bound":safe,"sampled_contact_upper_bound":blocked,"transit_guard":low-17.5,"overhead_to_spreader_top":23-(beam.origin.y+.09),"body_top":top,"hook_datum":beam.origin.y,"deck_notch_front":notch_front,"deck_notch_rear":notch_rear,"boss_to_ledge":.002,"harness_to_wall":.033}
		expect(safe>0 and blocked-safe<=.000313,uid+" measures positive full-route payload/rig clearance within .313 mm: "+str([safe,blocked]))
		expect(notch_front>=.74999 and notch_rear>=.74999,uid+" actual 16.4 m floor solids leave at least .75 m fore/aft of the seated cap")
		expect(is_equal_approx(low,18.0) and is_equal_approx(top,19.4),uid+" actual body uses the agreed 18.0..19.4 transit envelope")
		expect(is_equal_approx(beam.origin.y,20.53),uid+" actual spreader datum is world Y20.53")
		# Upper-level floor patches flank, rather than cross, the complete seated cap.
		var deck_error=""
		for entry in solids:
			for piece in game.leg_layout.blockout.pieces.values():
				if not piece.has("body") or not piece.spec.id.ends_with("_floor") or not is_equal_approx(piece.body.global_position.y,16.3):continue
				var query=PhysicsShapeQueryParameters3D.new();query.shape=entry.shape;query.transform=path[-1]*entry.transform;query.collision_mask=1
				for hit in game.get_world_3d().direct_space_state.intersect_shape(query):
					if hit.collider==piece.body:deck_error=piece.spec.id
		expect(deck_error.is_empty(),uid+" existing 16.4 m deck opening notches around the top: "+deck_error)
		body.global_transform=path[-1];publish(body)
	print("PAULDRON_MARGINS ",JSON.stringify(margins))
	finish()

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/pauldron-preflight.json",{"scope":"actual payload and complete rig along both routes; no walking/reach/rendered review","margins":margins,"checks":checks})
	print("PAULDRON_PREFLIGHT ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
