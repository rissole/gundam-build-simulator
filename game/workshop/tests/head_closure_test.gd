extends "res://tests/kit/m3_section.gd"
## Actual shelf identities, receivers, captive bolts, optical voids and crown rig.
## Earlier construction is supplied; no walking/reach/visibility/rendered review.
const Sweep=preload("res://scripts/motion_sweep.gd")
var envelopes: Dictionary={}

func run() -> void:
	if not await start("head_sensors"):finish();return
	var sensors=game.equipment.get_equipment("head_sensors_receiver")
	var face=game.equipment.get_equipment("head_faceplate_receiver")
	var mask=game.equipment.get_equipment("head_mask_receiver")
	var crown=game.equipment.get_equipment("head_crown_receiver")
	expect(not face.receiving_error().is_empty() and not game.equipment.placement_error("chest","head_faceplate").is_empty(),"faceplate before sensor connection is rejected")
	expect(not mask.receiving_error().is_empty(),"mask before retained faceplate is rejected")
	expect(not crown.receiving_error().is_empty(),"crown before retained mask is rejected")
	audit_manual()
	if not await shelf_piece("head_sensors","left"):finish();return
	expect(sensors.state=="seated" and not game.model.hands_occupied(),"captured sensor rails support the seated carrier hands-free")
	expect(not face.receiving_error().is_empty(),"seating the carrier alone cannot permit the faceplate")
	var captive: Array=sensors.spec.captive_slots
	for i in range(captive.size()):
		var sid: String=captive[i];var slot=game.model.slot_definition("chest",sid)
		expect(game.model.items[slot.pose_source].location=="support:"+slot.source_supports[0] and sensors.captive_nodes[sid].visible,"carrier bolt stays captive at its front head before tightening")
		expect(sensors.controls().any(func(entry):return entry.action=="fasten:"+sid),"unfinished captive bolt has a local action")
		expect(sensors.request("fasten:"+sid).is_empty(),"tighten the actual captive carrier bolt "+sid)
		expect(not sensors.captive_nodes[sid].visible and game.model.assemblies.chest.slots[sid]==slot.pose_source,"fastening consumes only its captive physical identity")
		if i<3:expect(not game.model.milestone("chest","head_sensors_retained"),"partial carrier fastening cannot establish retention")
	expect(game.model.milestone("chest","head_sensors_retained") and not game.model.milestone("chest","head_sensors_connected"),"four M8 bolts retain the carrier without claiming a power/data connection")
	expect(not face.receiving_error().is_empty(),"all carrier bolts still leave faceplate blocked while power/data is open")
	var service: String=sensors.spec.retention_slots[-1]
	Staging.fill(game,"chest",[service])
	expect(game.model.milestone("chest","head_sensors_connected") and face.receiving_error().is_empty(),"plugging and clipping the sensor power/data permits the faceplate")
	if not await shelf_piece("head_faceplate","right"):finish();return
	expect(face.state=="seated" and not game.model.hands_occupied(),"faceplate ledges support it while fastening")
	Staging.fill(game,"chest",face.spec.retention_slots.slice(0,3))
	expect(not mask.receiving_error().is_empty(),"three of four faceplate bolts cannot permit the mask")
	var wrong="HD-M10160__001";expect(game.model.transfer("hd-m10-160","bin","pocket",wrong)==wrong,"collect a longer incompatible M10 counterexample")
	expect(not game.model.install("chest",face.spec.retention_slots[-1],wrong).ok,"mask M10 × 160 cannot replace a faceplate M10 × 80")
	Staging.fill(game,"chest",[face.spec.retention_slots[-1]])
	expect(face.retained() and mask.receiving_error().is_empty(),"all four faceplate bolts permit the mask")
	if not await shelf_piece("head_mask","left"):finish();return
	expect(mask.state=="hooked" and not mask.retained() and game.model.held_item().is_empty(),"hooked unbolted mask frees both hands without claiming retention")
	expect(game.hands.error().is_empty(),"mask hooks permit pocket tools and other hands-free work")
	expect(not crown.receiving_error().is_empty(),"hooks alone cannot permit the crown")
	Staging.fill(game,"chest",[mask.spec.retention_slots[0]])
	expect(not crown.receiving_error().is_empty(),"one mask uplift bolt cannot permit the crown")
	Staging.fill(game,"chest",mask.spec.retention_slots)
	expect(mask.retained() and crown.receiving_error().is_empty(),"both mask uplift bolts permit the final crown")
	await optical_checks("before crown")
	# Correct this one mask locally, before the final crown closes its removal path.
	var old_bolts: Array=[]
	for sid in mask.spec.retention_slots:old_bolts.append(game.model.assemblies.chest.slots[sid])
	for n in range(2):
		expect(not game.equipment.undo("chest").handled and game.model.undo("chest").ok,"local mask correction removes an uplift bolt while its hooks support it")
		game.components.sync("chest")
	expect(mask.state=="hooked" and not game.model.hands_occupied(),"mask remains hands-free after both bolts are removed")
	var result: Dictionary=game.model.undo_to_hands("chest")
	expect(result.ok and game.model.held_item()=="HD-MASK__001" and mask.state=="idle","lift the same hooked mask clear into both hands")
	game.components.sync("chest")
	expect(not crown.receiving_error().is_empty(),"removing the mask reinstates the crown dependency")
	expect(game.components.placement_error("chest","head_mask","HD-MASK__001").is_empty() and game.model.install("chest","head_mask","HD-MASK__001").ok,"refit the same physical mask onto its hooks")
	game.components.sync("chest");Staging.fill(game,"chest",mask.spec.retention_slots)
	for n in range(2):expect(game.model.assemblies.chest.slots[mask.spec.retention_slots[n]]==old_bolts[n],"mask correction preserves its original bolt identity")
	var crane=game.equipment.get_equipment("service_crane");var fixture=game.equipment.get_equipment("module_supports")
	if not command(fixture,"template:head_crown") or not transfer("head_crown_to_fixture"):finish();return
	expect(game.model.assemblies.head_crown.location=="support:bulky_fixture","crown uses the shared upright saddles")
	supply_rig(crane,false)
	if not command(crane,"up") or not command(crane,"go:park") or not transfer("head_crown"):finish();return
	expect(crown.state=="seated" and crane.required_ends==2,"final crown seats on its two unequal keys under both crane ends")
	expect(not crane.action_error("detach:"+crane.END_IDS[0]).is_empty(),"crown cannot release rig before retention")
	Staging.fill(game,"chest",[crown.spec.retention_slots[0]])
	expect(not crown.rig_error("detach","").is_empty(),"one crown bolt cannot release either end")
	Staging.fill(game,"chest",crown.spec.retention_slots)
	expect(crown.retained() and crown.rig_error("detach","").is_empty(),"both front M12 bolts retain the crown")
	supply_rig(crane,false)
	if not command(crane,"up") or not command(crane,"go:park"):finish();return
	await optical_checks("complete head")
	expect(stages.stage_errors("complete").is_empty(),"complete begins with the whole head retained/connected, ends stowed and crane parked")
	expect(game.model.integrity_errors().is_empty(),"head closure and local correction conserve every physical identity")
	finish()

func shelf_piece(sid: String, side: String) -> bool:
	var uid: String=game.model.slot_definition("chest",sid).pose_source
	var bounds: AABB=game.source[uid].mesh.get_aabb();envelopes[sid]=[bounds.size.x,bounds.size.z,bounds.size.y]
	expect(bounds.size.x<=1.45001 and bounds.size.z<=.35001 and bounds.size.y<=1.20001,sid+" actual authored geometry fits the enlarged shelf: "+str(bounds.size))
	await frames(2)
	var receiver=game.equipment.get_equipment(sid+"_receiver")
	var solids: Array[Dictionary]=SolidHandling.authored_shapes(game.model.definitions.parts[game.model.items[uid].kind].collision_shapes,game.source[uid].mesh.get_aabb())
	var groups=[{"shapes":solids,"margin":.001,"error":"Seating path hits {collider}"}]
	var path: Array[Transform3D]=[]
	for offset in receiver.spec.approach_offsets:path.append(receiver.load_pose().translated(AssemblyRuntime.vec(offset)+Vector3.UP*.002))
	var blocked={}
	for n in range(path.size()-1):
		var a=path[n];var b=path[n+1]
		blocked=Sweep.sweep(game.get_world_3d().direct_space_state,groups,Sweep.steps(a,b,1.5,.025),func(p: float)->Transform3D:return a.interpolate_with(b,p),15,[],sid)
		if not blocked.is_empty():break
	expect(blocked.is_empty(),sid+" actual prepared geometry clears its specified approach, allowing only the 2 mm bearing-contact tolerance: "+str(blocked))
	var error: String=stages._shelf_item(sid,side)
	expect(error.is_empty(),sid+" makes its real shelf/elevator/hand/seat transfer: "+error)
	if not error.is_empty():return false
	expect(game.model.items[uid].location=="installed" and game.model.items[uid].owner=="chest" and game.model.assemblies.chest.slots[sid]==uid,sid+" retains its physical identity and single chest owner")
	return true

func transfer(task: String) -> bool:
	var crane=game.equipment.get_equipment("service_crane")
	if not command(crane,"task:"+task) or not command(crane,"go:source") or not command(crane,"down"):return false
	supply_rig(crane,true)
	return command(crane,"up") and command(crane,"go:receiver") and command(crane,"down")

func corridor(x: float, z: float, widths: Vector2, heights: Vector2) -> ConvexPolygonShape3D:
	var points=PackedVector3Array()
	for n in range(2):
		var y=.502 if n==0 else .90
		for dx in [-1,1]:
			for dz in [-1,1]:points.append(Vector3(13+x+dx*widths[n]/2,1.4+z+dz*heights[n]/2,26-y))
	var shape=ConvexPolygonShape3D.new();shape.points=points;return shape

func optical_checks(label: String) -> void:
	await frames(2)
	for spec in [[-.27,16.66,Vector2(.26,.34),Vector2(.10,.14)],[.27,16.66,Vector2(.26,.34),Vector2(.10,.14)],[0,17.02,Vector2(.18,.22),Vector2(.10,.15)]]:
		var query=PhysicsShapeQueryParameters3D.new();query.shape=corridor(spec[0],spec[1],spec[2],spec[3]);query.collision_mask=15;query.margin=.0001
		expect(game.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),label+" keeps the full optical corridor clear at "+str(spec.slice(0,2)))
		if label=="complete head":
			var block=StaticBody3D.new();block.collision_layer=8;game.add_child(block)
			var col=CollisionShape3D.new();var solid=BoxShape3D.new();solid.size=Vector3(.02,.02,.02);col.shape=solid;block.add_child(col)
			block.global_position=Vector3(13+spec[0],1.4+spec[1],25.20);block.force_update_transform()
			PhysicsServer3D.body_set_state(block.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,block.global_transform)
			expect(not game.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"optical check detects a solid intruding into this corridor")
			block.free()

func audit_manual() -> void:
	var scope: Array=[]
	for id in ["head_sensors","head_faceplate","head_mask","head_crown"]:
		scope.append(id);scope.append_array(game.equipment.get_equipment(id+"_receiver").spec.retention_slots)
	var counts={};var pages=0;var manual: Array=game.runtime.definition("chest").manual
	for i in range(manual.size()):
		var page: Dictionary=manual[i]
		if page.slots.is_empty() or not page.slots.all(func(sid):return sid in scope):continue
		game.hud.open_manual("chest",i)
		var supplies: String=game.hud.page_body.text.get_slice("Parts for this step\n",1)
		expect(not supplies.is_empty(),page.title+" has runtime HUD component supplies")
		for sid in page.slots:counts[sid]=counts.get(sid,0)+1
		if page.slots==["head_sensors"]:expect(supplies.count("×1")==1 and "HD-SENSORS" in supplies,"sensor installation lists one prepared carrier, with no duplicate camera/range stock")
		if page.slots==game.equipment.get_equipment("head_sensors_receiver").spec.captive_slots:expect(supplies.count("×4")==1 and "HD-M8" in supplies,"carrier retention lists four captive M8 fasteners")
		pages+=1
	expect(pages==9 and counts.size()==17 and counts.values().all(func(n):return n==1),"nine closure/crown pages cover all 17 new physical slots once")

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/head-closure.json",{"scope":"shelf/elevator handling, head order, captive fasteners, hook support, optical clearances, local correction and crown; no walking/reach/rendered review","envelopes_w_d_h":envelopes,"checks":checks})
	print("HEAD_CLOSURE ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
