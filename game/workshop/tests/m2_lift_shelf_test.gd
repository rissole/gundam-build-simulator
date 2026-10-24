extends "res://tests/kit/workshop_suite.gd"
## Bounded shelf fixture uses real unused foot components to exercise both capacities.
## The retention controls suite separately walks the actual ring/lift/hip journey.
var shelf: Node3D
var lift: Node3D
func carry(uid: String) -> void:
	expect(game.model.carry_item(uid).is_empty(),"Pick up actual component "+uid)
	game.components.hold_at(uid,shelf.global_transform*Transform3D(Basis.IDENTITY,Vector3(0,.5,.15)))
	await frames(1)
	# This fixture isolates placement sweeps from view-dependent carrying.
	game.components.held_body.global_transform = shelf._pose(uid,maxi(0,shelf.occupants().find("")))
	game.components.held_body.global_position.y += .25

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate();game.profile_override = "foot";game.automated_test=true;root.add_child(game);await frames(3);game.set_paused(false)
	var kinds: Array = []
	for kind in game.model.definitions.parts:
		if game.model.definitions.parts[kind].carry_class in ["hand","two_hand"]:kinds.append(kind)
	for support in ["m2_lift_shelf_0","m2_lift_shelf_1"]:game.model.support_definitions[support]={"parts":kinds}
	lift = preload("res://scripts/work_access_lift.gd").new();game.add_child(lift)
	var levels: Array[float]=[.15,3]
	lift.setup(game,"shelf_fixture",Vector3(8,0,4),Vector2(2.6,2.6),levels)
	shelf = preload("res://scripts/lift_shelf.gd").new();game.add_child(shelf);shelf.setup(game,lift)
	var smalls: Array[String]=[]
	var large = ""
	for uid in game.model.items:
		var item: Dictionary=game.model.items[uid]
		if item.location!="bin":continue
		var size: String=game.model.definitions.parts[item.kind].carry_class
		if size=="hand" and smalls.size()<3:smalls.append(uid)
		if size=="two_hand" and large.is_empty():large=uid
	expect(smalls.size()==3 and not large.is_empty(),"Fixture has real one-hand and two-hand stock")
	for uid in smalls.slice(0,2):
		await carry(uid)
		expect(shelf.capacity_error(uid).is_empty(),"Shelf accepts one-hand component within capacity")
		var error: String=shelf.request("store")
		expect(error.is_empty(),"Store one-hand component through swept placement: "+error)
		await frames(2)
	expect(shelf.occupants()==smalls.slice(0,2),"Two distinct one-hand identities occupy shelf")
	await carry(smalls[2])
	var before=JSON.stringify(game.model.items)
	expect(not shelf.request("store").is_empty() and before==JSON.stringify(game.model.items),"Third one-hand item rejects atomically")
	game.components.drop(true);await frames(2)
	for index in range(2):
		expect(shelf.request("take:"+str(index)).is_empty() and game.model.held_item()==smalls[index],"Shelf returns selected physical component")
		game.components.drop(true);await frames(2)
	await carry(large)
	expect(shelf.request("store").is_empty(),"One two-hand component stores through swept placement")
	await frames(2)
	await carry(smalls[0]);before=JSON.stringify(game.model.items)
	expect(not shelf.request("store").is_empty() and before==JSON.stringify(game.model.items),"Two-hand cargo consumes whole shelf capacity")
	game.components.drop(true);await frames(2)
	var invalid=shelf.capture();invalid.occupants=[large,large]
	expect(not shelf.validate(invalid,game.model).is_empty(),"Save rejects duplicated shelf identity")
	var stored: Node3D=shelf.cargo[large]
	var bound: AABB=game.source[game.source_uid(large)].mesh.get_aabb()
	var local: AABB=shelf.global_transform.affine_inverse()*stored.global_transform*bound
	expect(absf(local.position.y-.04)<.0001,"Cargo rests on shelf top with no gap or penetration")
	var obstruction=StaticBody3D.new();obstruction.collision_layer=8;game.add_child(obstruction)
	var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(.3,.2,.3);shape.shape=box;obstruction.add_child(shape)
	obstruction.global_position=stored.global_transform*bound.get_center()+Vector3(0,1,0)
	await frames(2)
	expect(not shelf.travel_error(lift.equipment_id,lift.height,3).is_empty(),"Stored component's physical sweep detects overhead obstruction")
	obstruction.free();await frames(2)
	expect(shelf.travel_error(lift.equipment_id,lift.height,3).is_empty(),"Cleared stored-cargo route permits lift travel")
	lift.height=3;lift.destination=3;lift._pose();shelf.sync()
	var physics_pose: Transform3D=PhysicsServer3D.body_get_state(stored.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
	expect(stored.global_transform.is_equal_approx(physics_pose),"Shelf cargo physics follows deck immediately")
	expect(game.model.integrity_errors().is_empty(),"Shelf storage preserves inventory integrity")
	var passed=checks.all(func(check):return check.passed)
	write_evidence("/tmp/m2-lift-shelf.audit.json",{"passed":passed,"checks":checks,"rendered":false})
	game.free();await process_frame
	print("M2_LIFT_SHELF ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
