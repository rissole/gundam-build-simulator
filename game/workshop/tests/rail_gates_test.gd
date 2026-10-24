extends "res://tests/kit/harness.gd"
## Supplied collision blockers test machinery, not a walked access journey.
const Fixture = preload("res://tests/wide_access_test.gd").Fixture
const Blockout = preload("res://scripts/workshop_blockout.gd")
const Gates = preload("res://scripts/rail_crossing_gates.gd")
func _initialize() -> void:call_deferred("run")

func blocker(game: Node3D, at: Vector3, layer: int) -> StaticBody3D:
	var body=StaticBody3D.new();game.add_child(body);body.collision_layer=layer
	var collision=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(.4,1.7,.4)
	collision.shape=shape;body.add_child(collision);body.position=at
	return body

func settle(gates: Node) -> void:
	for i in range(30):gates.physics(.1)

func run() -> void:
	var game=Fixture.new();root.add_child(game)
	var layout: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop-layout.json"))
	var world=Blockout.new();game.add_child(world);world.setup(game,layout.workshop)
	var gates=Gates.new();game.add_child(gates);gates.setup(game,world)
	await frames(2)
	expect(gates.value==0 and not gates.moving,"ground crossing starts open")
	var actor=blocker(game,Vector3(13,.95,21),8);await frames(2)
	expect(not gates.request_closed(true).is_empty(),"occupied floor corridor rejects closing request")
	expect(gates.validate(gates.capture()).is_empty(),"blocked closing request remains resumable and serializable")
	actor.free();await frames(2)
	var cargo=blocker(game,Vector3(7.6,.95,21.0),2);await frames(2)
	expect(not gates.request_closed(true).is_empty(),"solid cargo blocks the full gate sweep")
	cargo.free();await frames(2)
	expect(gates.request_closed(true).is_empty(),"clear corridor and gate arcs permit closing")
	gates.physics(.5);gates.request("stop")
	var state: Dictionary=JSON.parse_string(JSON.stringify(gates.capture()))
	expect(gates.value>0 and gates.value<1 and not gates.moving,"Stop holds an intermediate gate angle")
	expect(gates.validate(state).is_empty(),"intermediate gate JSON validates")
	gates.apply(state)
	expect(gates.request("resume").is_empty(),"local resume preserves the requested closing direction")
	settle(gates)
	expect(gates.closed(),"both ground gates finish closing")
	actor=blocker(game,Vector3(13,.95,25),8);await frames(2)
	expect(not gates.occupancy_error().is_empty(),"corridor occupancy remains detectable after gates close")
	actor.free();await frames(2)
	expect(gates.request("open").is_empty(),"stopped station permits local opening")
	settle(gates)
	expect(gates.value==0 and gates.blocked_reason.is_empty(),"both gates reopen without sweeping fixed structure")
	for invalid in [-.1,1.1,"half",null]:
		var corrupt=state.duplicate(true);corrupt.value=invalid
		expect(not gates.validate(corrupt).is_empty(),"invalid gate progress rejected: "+str(invalid))
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/rail-gates.json",{"scope":"mechanical blockers and phases; no walking/access acceptance","checks":checks})
	print("RAIL_GATES ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
