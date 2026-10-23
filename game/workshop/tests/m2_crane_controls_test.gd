extends "res://tests/m2_crane_test_base.gd"
## Actual walked desktop E/click/Q/Z route through the complete M2 crane example.
func hardware_route() -> void:
	await walk(Vector3(6.85,0,21.9),"console exit clear of pedestal")
	await walk(Vector3(6.85,0,14.0),"west source aisle to hardware")
	for kind in ["lg-w24","lg-m24-100"]:
		var bin: Node3D = game.bins[kind]
		var point: Vector3 = bin.global_position+Vector3(0,.13,.27)
		await walk(Vector3(6.85,0,point.z+.65),"open drawer front aisle")
		await walk(Vector3(point.x,0,point.z+.65),"pooled "+kind+" stock")
		look(point);await frames(2);game._update_target()
		expect(game.target.get("type","")=="bin" and game.target.get("kind","")==kind,"Ordinary aim recognizes "+kind+" stock")
		tap(KEY_E)
		expect(game.model.find_item(kind,"pocket")!="","E collects flange hardware into ordinary pocket")
	await walk(Vector3(6.85,0,19.6),"open cross aisle")
	await walk(Vector3(10.8,0,19.6),"receiver approach clear of source beam")
	await walk(Vector3(10.8,0,15.34),"west flange work face")
	for pair in range(1,5):
		if pair == 3:
			await walk(Vector3(10.8,0,20.0),"west route around beam ball")
			await walk(Vector3(13.0,0,20.0),"far cross aisle to east flange")
			await walk(Vector3(13.0,0,15.7),"east flange work face")
		for family in ["washer","bolt"]:
			var sid = "fork/%s_%d"%[family,pair]
			var kind = "lg-w24" if family == "washer" else "lg-m24-100"
			pocket(kind)
			var point: Vector3 = game.components.slot_point("left_leg",sid)
			# Walk around the flange sides; keep both the source and fixture solids.
			await walk(Vector3(point.x+(-.65 if point.x<11.9 else .65),0,point.z+.18),"flange "+sid)
			look(point);await frames(2);game._update_target()
			var aimed = game.target.get("type","")=="component" and game.target.get("owner","")=="left_leg" and game.target.get("sid","")==sid
			if not aimed:print("M2_FLANGE_TARGET ",sid," point=",point," feet=",game.player.global_position," actual=",game.target)
			expect(aimed,"Ordinary aim selects "+sid)
			if aimed:click()
			expect(not game.model.assemblies.left_leg.slots[sid].is_empty(),"Click fits actual physical "+sid)

func run() -> void:
	await boot()
	await source_route()
	await aim_action("pick:magnet_a");tap(KEY_Q)
	expect(crane.hand_payload().is_empty(),"Ordinary Q returns held end to equipment stow")
	await rig();await deliver()
	await hardware_route()
	expect(crane.secured() and crane.hardware_count()==8,"Four ordinary washer/bolt pairs secure the real beam flange")
	var last_uid: String = game.model.assemblies.left_leg.slots["fork/bolt_4"]
	tap(KEY_Z)
	expect(game.model.assemblies.left_leg.slots["fork/bolt_4"].is_empty() and game.model.items[last_uid].location == "pocket","Ordinary Z returns actual installed flange bolt identity with crane assistance")
	pocket("lg-m24-100")
	look(game.components.slot_point("left_leg","fork/bolt_4"));await frames(2);game._update_target();click()
	expect(game.model.assemblies.left_leg.slots["fork/bolt_4"]==last_uid,"Ordinary click reinstalls the same removed bolt UID")
	await walk(Vector3(13.0,0,20.0),"east receiver exit")
	await walk(Vector3(10.8,0,20.0),"far cross aisle for cable release")
	await walk(Vector3(11.0,0,16.05),"near receiver magnet")
	await aim_action("detach:magnet_a");tap(KEY_Q)
	await walk(Vector3(11.0,0,18.08),"far receiver magnet")
	await aim_action("detach:magnet_b");tap(KEY_Q)
	expect(crane.hand_payload().is_empty() and crane.attached_count()==0,"Secured beam releases and stows both cables through E/Q")
	await walk(Vector3(10.8,0,19.8),"receiver exit")
	await walk(Vector3(4.9,0,21.9),"central console for empty crane parking")
	await console_action("up")
	expect(await settle() and crane.raised,"Empty rig raises before departure")
	await console_action("go:park")
	expect(await settle() and crane.station == "park" and crane.raised and crane.secured(),"Empty crane parks while the same secured beam stays installed")
	expect(crane.validate(crane.capture()).is_empty(),"Parked empty crane and installed beam have coherent saved ownership")
	await finish("M2_CRANE_CONTROLS","/tmp/m2-crane-controls.audit.json")
