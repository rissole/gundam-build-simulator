extends "res://tests/kit/harness.gd"
## Equipment-only harness. Does not walk, aim, fasten, evaluate reach or render.
const Blockout = preload("res://scripts/workshop_blockout.gd")
const Access = preload("res://scripts/workshop_access.gd")
class Fixture extends Node3D:
	var paused = false
	var equipment = EquipmentRegistry.new()
	var model = AssemblyModel.new()
	var source: Dictionary = {}
	var primitives = preload("res://scripts/primitives.gd").new()
	func material(color: Color, metal: float = 0.0) -> Material:return primitives.material(color,metal)
	func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:return primitives.box(parent,at,size,mat,solid)
	func sign_panel(parent: Node3D, text: String, at: Vector3, size: Vector2, font: int, pixel: float) -> Label3D:return primitives.sign_panel(parent,text,at,size,font,pixel)
	func source_uid(uid: String) -> String:return model.source_uid(uid)
	func _mesh(uid: String) -> MeshInstance3D:
		var result = MeshInstance3D.new();result.mesh = source[source_uid(uid)].mesh;return result

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var game = Fixture.new();root.add_child(game)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/leg-bay-m3-layout.json"))
	var world = Blockout.new();game.add_child(world);world.setup(game,layout.workshop)
	var access = Access.new();game.add_child(access);access.setup(game,world)
	await frames(3)
	expect(access.ready_for("work"),"work platforms initially locked")
	for mode in ["leg","work","pelvis","work","chest","work","arm","work"]:
		var error: String = access.request_mode(mode)
		expect(error.is_empty(),mode+" configuration accepted: "+error)
		if not error.is_empty():continue
		for step in range(13):access.physics(.5)
		expect(access.ready_for(mode),mode+" completes and locks: "+access.blocked_reason)
		var saved: Dictionary = JSON.parse_string(JSON.stringify(access.capture()))
		expect(access.validate(saved).is_empty(),mode+" save validates")
		access.apply(saved)
		expect(access.ready_for(mode),mode+" restore preserves locked pose")
	# Supplied blocker checks actual solid interlocks, without a player journey.
	var blocker = StaticBody3D.new();game.add_child(blocker);blocker.name = "SuppliedCargo"
	var collision = CollisionShape3D.new();var shape = BoxShape3D.new();shape.size=Vector3(.5,1,.5)
	collision.shape=shape;blocker.add_child(collision);blocker.position=Vector3(9,8.8,24)
	await frames(3)
	expect(not access.request_mode("leg").is_empty(),"occupied wing blocks delivery configuration")
	blocker.free();await frames(2)
	expect(access.request_mode("leg").is_empty(),"clearing cargo permits motion")
	access.physics(1.5);access.request("stop")
	var interrupted: Dictionary = JSON.parse_string(JSON.stringify(access.capture()))
	expect(not access.moving and not access.ready_for("leg"),"Stop holds intermediate configuration")
	expect(access.validate(interrupted).is_empty(),"stopped intermediate snapshot accepted")
	access.apply(interrupted);access.request("advance")
	for step in range(12):access.physics(.5)
	expect(access.ready_for("leg"),"restored partial configuration resumes to delivery lock")
	for value in [-.01,1.01,"0.5",null]:
		var corrupt = interrupted.duplicate(true);corrupt.channels.rear.value=value
		expect(not access.validate(corrupt).is_empty(),"malformed platform phase rejected: "+str(value))
	var bad = interrupted.duplicate(true);bad.channels.rear.goal=0
	expect(not access.validate(bad).is_empty(),"configuration/goal mismatch rejected")
	var passed = checks.all(func(check):return check.passed)
	write_evidence("res://verification/wide-access.json",{"scope":"equipment-only; no access acceptance","checks":checks})
	print("WIDE_ACCESS ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
