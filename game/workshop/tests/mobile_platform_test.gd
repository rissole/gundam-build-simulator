extends "res://tests/kit/harness.gd"
## Mechanical equipment harness; supplied blockers are not a walked/access test.
const Fixture = preload("res://tests/kit/equipment_fixture.gd")
const Platform = preload("res://scripts/mobile_work_platform.gd")
const Blockout = preload("res://scripts/workshop_blockout.gd")
class Hands extends RefCounted:
	var held_body: CollisionObject3D
class RiderFixture extends Fixture:
	var player: CharacterBody3D
	var components = Hands.new()
func _initialize() -> void:call_deferred("run")

func settle(platform: Node) -> void:
	for tick in range(1000):
		if not platform.moving:return
		platform.physics(.25)

## Ridden motion runs one registry tick per frame, as in play: the registry
## carries the rider and physics queries see poses only after a step.
func ride(platform: Node) -> void:
	for tick in range(1000):
		if not platform.moving:return
		platform.game.equipment.physics(.1);await frames(1)

func obstacle(parent: Node3D, at: Vector3, size: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new();parent.add_child(body);body.name="SuppliedBlocker";body.position=at
	var col = CollisionShape3D.new();var shape = BoxShape3D.new();shape.size=size;col.shape=shape;body.add_child(col)
	return body

func run() -> void:
	var game = RiderFixture.new();root.add_child(game)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop-layout.json"))
	var world = Blockout.new();game.add_child(world);world.setup(game,layout.workshop)
	var platform = Platform.new();game.add_child(platform);platform.setup(game,layout.workshop.mobile_platform);game.equipment.register(platform)
	await frames(3)
	for dock in platform.spec.docks:
		if dock=="park":continue
		expect(platform.request("dock:"+dock).is_empty(),"request "+dock+" transfer")
		platform.physics(.2);platform.request("stop")
		var snapshot: Dictionary = JSON.parse_string(JSON.stringify(platform.capture()))
		expect(platform.validate(snapshot).is_empty(),"interrupted "+dock+" transfer validates")
		platform.apply(snapshot);platform.request("advance");settle(platform)
		expect(platform.dock==dock and not platform.moving and platform.mode.is_empty(),"continuous transfer reaches "+dock+": "+platform.blocked_reason)
		if platform.dock!=dock:break
		expect(platform.position.is_equal_approx(AssemblyRuntime.vec(platform.spec.docks[dock])),"authored "+dock+" pose")
		for height in platform.spec.heights.slice(1):
			expect(platform.request("advance").is_empty(),"raise at "+dock)
			platform.physics(.2);snapshot=JSON.parse_string(JSON.stringify(platform.capture()))
			expect(platform.validate(snapshot).is_empty(),"height transfer snapshot validates")
			platform.apply(snapshot);settle(platform)
			expect(is_equal_approx(platform.height,height) and not platform.moving,"platform reaches %.2f at %s: %s"%[height,dock,platform.blocked_reason])
		expect(not platform.request("dock:park").is_empty(),"raised platform rejects ground transfer")
		for index in range(3):platform.request("return");settle(platform)
		expect(is_equal_approx(platform.height,platform.spec.heights[0]),"platform returns to ground")
		platform.request("return");settle(platform)
		expect(platform.dock=="park" and platform.mode.is_empty(),"reverse route returns to parking: "+platform.blocked_reason)
		if platform.dock!="park":break
	var cargo = obstacle(game,platform.global_position+Vector3(0,.5,0),Vector3(.3,.3,.3));await frames(2)
	expect(not platform.request("dock:bulky_right").is_empty(),"occupied deck rejects repositioning")
	cargo.free();await frames(2)
	platform.request("dock:bulky_rear");platform.physics(1);platform.request("stop")
	var before: Vector3 = platform.position
	expect(platform.request("return").is_empty(),"interrupted transfer can reverse")
	expect(platform.position.is_equal_approx(before),"reversing preserves current physical position")
	settle(platform)
	expect(platform.dock=="park","reversed partial route reaches its original dock")
	var obstruction = obstacle(game,platform.global_position+Vector3(0,2,0),Vector3(.5,.2,.5));await frames(2)
	platform.request("advance");settle(platform)
	expect(not platform.blocked_reason.is_empty() and platform.height<1.6,"overhead solid stops raising without penetration")
	obstruction.free();await frames(2)
	platform.request("advance");settle(platform)
	expect(is_equal_approx(platform.height,1.6),"cleared overhead route resumes raising")
	platform.request("return");settle(platform)
	game.player = CharacterBody3D.new();game.player.collision_layer = 8;game.add_child(game.player)
	var capsule = CapsuleShape3D.new();capsule.radius = .26;capsule.height = 1.7
	var body = CollisionShape3D.new();body.shape = capsule;body.position.y = .86;game.player.add_child(body)
	game.player.global_position = platform.global_position+Vector3(0,platform.height,0);await frames(2)
	var load = obstacle(game,game.player.global_position+Vector3(0,1.2,-.35),Vector3(.3,.3,.3));game.components.held_body = load;await frames(2)
	var grip: Vector3 = load.global_position-game.player.global_position
	expect(platform.rider()==game.player,"player on the lowered deck rides")
	expect(platform.request("dock:bulky_right").is_empty(),"ridden platform accepts ground transfer")
	await ride(platform)
	expect(platform.dock=="bulky_right","ridden transfer reaches bulky right: "+platform.blocked_reason)
	expect(game.player.global_position.is_equal_approx(platform.global_position+Vector3(0,platform.height,0)),"rider travels with the deck")
	expect(load.global_position.is_equal_approx(game.player.global_position+grip),"hand load travels with the rider")
	platform.request("advance");await ride(platform)
	expect(is_equal_approx(platform.height,1.6),"rider can raise the platform holding a load: "+platform.blocked_reason)
	expect(load.global_position.is_equal_approx(game.player.global_position+grip) and absf(game.player.global_position.y-1.6)<.001,"rider and load rise with the deck")
	platform.request("return");await ride(platform)
	game.components.held_body = null;load.free()
	game.player.global_position = platform.global_position+Vector3(-2.5,0,0);await frames(2)
	var walker: Vector3 = game.player.global_position
	expect(platform.rider()==null,"player beside the platform is not a rider")
	expect(platform.request("dock:park").is_empty(),"empty transfer back to parking")
	await ride(platform)
	expect(platform.dock=="park" and game.player.global_position.is_equal_approx(walker),"empty transfer leaves the walker behind: "+platform.blocked_reason)
	platform.request("advance");await ride(platform)
	var invalid: Dictionary = platform.capture();invalid.mode="travel";invalid.from="park";invalid.to="bulky_right"
	expect(not platform.validate(invalid).is_empty(),"save rejects raised ground transfer")
	var passed = checks.all(func(check):return check.passed)
	write_evidence("res://verification/mobile-platform.json",{"scope":"equipment and collision checks only","checks":checks})
	print("MOBILE_PLATFORM ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
