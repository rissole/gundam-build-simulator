extends "res://tests/kit/harness.gd"
## Real bulky part geometry and production shelf transfers on both authored lifts.
const Fixture = preload("res://tests/kit/equipment_fixture.gd")
class Hud extends Node:
	func refresh():pass
class Hands extends RefCounted:
	var game: Node
	func error(_id):return "Hands occupied" if game.model.hands_occupied() else ""
class Components extends Node:
	var game: Node
	var held_body: WorkshopPart
	func title(kind):return game.model.definitions.parts[kind].title
	func hold_at(uid,pose):
		held_body = WorkshopPart.new();held_body.uid=uid;held_body.kind=game.model.items[uid].kind
		held_body.freeze=true;held_body.held=true;held_body.collision_layer=2;held_body.collision_mask=3
		game.add_child(held_body);held_body.add_child(game._mesh(uid))
		for record in SolidHandling.authored_shapes(game.model.definitions.parts[held_body.kind].get("collision_shapes",[]),game.source[uid].mesh.get_aabb()):
			var col=CollisionShape3D.new();col.shape=record.shape;col.transform=record.transform;held_body.add_child(col)
		held_body.global_transform=pose
class Game extends Fixture:
	const WORLD_MASK=3
	var player=CharacterBody3D.new()
	var hud=Hud.new()
	var hands=Hands.new()
	var components=Components.new()
func _initialize():run.call_deferred()
func run():
	var definitions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/robot-definitions.json"))
	definitions.parts.merge(JSON.parse_string(FileAccess.get_file_as_string("res://assets/leg-prototype-definitions.json")).parts)
	var descriptors=JSON.parse_string(FileAccess.get_file_as_string("res://assets/leg-prototype-content.json")).sources
	descriptors.merge(JSON.parse_string(FileAccess.get_file_as_string("res://assets/robot-content.json")).sources)
	var layout=JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop-layout.json"))
	var uids: Array[String]=[]
	for uid in descriptors:
		if uid.begins_with("PV-120__") or uid.begins_with("PV-200__"):uids.append(uid)
	for side in ["left","right"]:
		var game=Game.new();root.add_child(game);game.add_child(game.player);game.player.position=Vector3(20,0,0)
		game.add_child(game.hud);game.add_child(game.components);game.components.game=game;game.hands.game=game
		var stock=[]
		var selected={}
		for uid in uids:
			var kind="pv-ring-half" if uid.begins_with("PV-120") else "pv-cylinder"
			stock.append({"instance_id":uid,"kind":kind});selected[uid]=descriptors[uid]
		for n in 3:
			var uid="PV-P60220__%03d"%(n+1)
			stock.append({"instance_id":uid,"kind":"pv-eye-pin"});selected[uid]=descriptors[uid]
		LegSourceGeometry.add_sources(game.source,{"sources":selected})
		var options: Dictionary=layout.workshop.elevators[side]
		var shelf_options: Dictionary=options.shelf
		var supports={}
		for id in shelf_options.supports:supports[id]={"parts":["pv-ring-half","pv-cylinder","pv-eye-pin"]}
		var data={"version":1,"parts":{"pv-ring-half":definitions.parts["pv-ring-half"],"pv-cylinder":definitions.parts["pv-cylinder"],"pv-eye-pin":definitions.parts["pv-eye-pin"]},"assemblies":{}}
		expect(game.model.configure(data,{"version":1,"parts":stock,"builds":[],"parents":[],"supports":supports}).is_empty(),side+" shelf fixture configures")
		var lift=WorkAccessLift.new();game.add_child(lift)
		lift.setup(game,side,Vector3.ZERO,Vector2(2.6,2.6),[.15,2.4] as Array[float],{"side_doors":true});game.equipment.register(lift)
		var shelf=preload("res://scripts/lift_shelf.gd").new();game.add_child(shelf);shelf.setup(game,lift,shelf_options);game.equipment.register(shelf)
		await frames(2)
		for uid in uids:
			expect(game.model.carry_item(uid).is_empty(),uid+" enters hands")
			game.components.hold_at(uid,shelf._pose(uid,0).translated(Vector3.UP*.15))
			var bound: AABB=shelf.stow_bounds(uid)
			expect(bound.size.x<=1.45 and bound.size.y<=1.2 and bound.size.z<=.35,uid+" visual and collision bounds fit the unchanged shelf volume: "+str(bound.size))
			expect(shelf.capacity_error(uid).is_empty(),uid+" accepts authored stow orientation")
			var error: String=shelf.request("store")
			expect(error.is_empty(),uid+" stores through production transfer: "+error)
			if not error.is_empty():continue
			expect(game.model.items[uid].location.begins_with("support:") and shelf.occupants().has(uid) and game.components.held_body==null,uid+" has exactly one shelf owner")
			var other= uids[1] if uid==uids[0] else uids[0]
			expect(game.model.carry_item(other).is_empty(),"Hold a second bulky copy for capacity check")
			game.components.hold_at(other,Transform3D(Basis.IDENTITY,Vector3(10,4,0)))
			expect(shelf.request("store").begins_with("Shelf full") and game.model.held_item()==other and shelf.occupants().has(uid),"Full shelf rejects another two-hand part without losing either copy")
			game.components.held_body.free();game.components.held_body=null;game.model.items[other].location="bin"
			await frames(2)
			expect(shelf.travel_error(lift.equipment_id,lift.height,lift.height+.2).is_empty(),uid+" cargo and captive clamps do not obstruct their own lift")
			var destination=2.4 if lift.height<1 else .15
			expect(lift.request("up" if lift.height<1 else "down").is_empty(),uid+" starts a real supported trip")
			for tick in 100:
				game.equipment.physics(.05)
				if tick%10==0:await frames(1)
				if not lift.moving:break
			expect(is_equal_approx(lift.height,destination) and not lift.moving,uid+" rides to the requested stop: "+lift.blocked_reason)
			expect(shelf.cargo[uid].global_transform.is_equal_approx(shelf._pose(uid,0)),uid+" keeps its supported orientation at the other stop")
			error=shelf.request("take:0")
			expect(error.is_empty() and game.model.held_item()==uid and game.components.held_body.uid==uid,uid+" retrieval retains exact identity: "+error)
			game.components.held_body.free();game.components.held_body=null
			game.model.items[uid].location="bin"
		for n in 3:
			var uid="PV-P60220__%03d"%(n+1)
			expect(game.model.carry_item(uid).is_empty(),"One-hand pin enters hands")
			game.components.hold_at(uid,shelf._pose(uid,mini(n,1)).translated(Vector3.UP*.15))
			var error: String=shelf.request("store")
			if n<2:expect(error.is_empty(),"Two one-hand pins still fit the shelf independently: "+error)
			else:
				expect(error.begins_with("Shelf full") and game.model.held_item()==uid,"Third one-hand part is rejected without release")
				game.components.held_body.free();game.components.held_body=null;game.model.items[uid].location="bin"
		for n in 2:
			var uid="PV-P60220__%03d"%(n+1)
			expect(shelf.request("take:"+str(n)).is_empty() and game.model.held_item()==uid,"Each occupied one-hand position retrieves its own UID")
			game.components.held_body.free();game.components.held_body=null;game.model.items[uid].location="bin"
		expect(game.model.integrity_errors().is_empty(),side+" transfers conserve inventory")
		game.free();await frames(1)
	var passed=checks.all(func(c):return c.passed)
	print("SHELF_STORAGE ","PASS " if passed else "FAIL ",checks.size()," checks")
	quit(0 if passed else 1)
