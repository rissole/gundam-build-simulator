extends "res://tests/kit/harness.gd"
## Isolated contract/physics fixture, not a walked or rendered acceptance run.
const Rope = preload("res://scripts/rope_access.gd")
const Player = preload("res://scripts/player_controller.gd")
const Blockout = preload("res://scripts/workshop_blockout.gd")
const Access = preload("res://scripts/workshop_access.gd")
const Codec = preload("res://scripts/pose_codec.gd")
class Components extends RefCounted:
	var held_body: Node3D
class Hud extends RefCounted:
	var browser: Control = Control.new()
	var message=""
	func toast(value: String) -> void:message=value
	func refresh() -> void:pass
	func handle_manual_browser_input(_event: InputEvent) -> bool:return false
class World extends Node3D:
	const WORLD_MASK=15
	const REACH=1.8
	const JUMP_SPEED=4.2
	var player: CharacterBody3D
	var player_collision: CollisionShape3D
	var camera: Camera3D
	var equipment=EquipmentRegistry.new()
	var model=AssemblyModel.new()
	var bodies={}
	var components=Components.new()
	var hud=Hud.new()
	var desktop_input: RefCounted
	var player_controller: RefCounted
	var targeting: RefCounted
	var scripted_controls={}
	var automated_test=true
	var paused=false
	var started=true
	var crouched=false
	var jump_requested=false
	var jump_held=false
	var target={}
	func _update_target() -> void:pass
	func equipment_access_error(_owner: String) -> String:return ""
var game: World
var rope: Node
var blockout: Node
var access: Node
const FRONT="front_l_9.3"
const REAR="rear_11.0"
func _initialize() -> void:run.call_deferred()

func obstacle(at: Vector3, size: Vector3) -> StaticBody3D:
	var body=StaticBody3D.new();game.add_child(body);body.position=at
	var shape=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=size;body.add_child(shape)
	return body

func place(at: Vector3) -> void:
	game.player.position=at;game.player.velocity=Vector3.ZERO
	PhysicsServer3D.body_set_state(game.player.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,game.player.global_transform)

func key(code: Key, pressed: bool) -> void:
	var event=InputEventKey.new();event.physical_keycode=code;event.pressed=pressed
	game.desktop_input.handle(event)

func tick(count: int=1, delta: float=.1) -> void:
	for i in count:
		game.player_controller.physics(delta);rope.physics(delta)
		if i%20==0:await frames(1)

func aim(action: String) -> bool:
	for entry in rope.controls():
		if entry.action==action:
			game.camera.look_at(entry.point)
			game.target=entry
			return game.targeting.aim_score(entry.point,entry.radius)!=INF and game.targeting.access([entry.node]).is_empty()
	return false

func contract() -> Array:
	var result=[]
	for pair in [["l",[9.3,10.8,11.9,12.6],[4.3,5.8,6.9,7.6]],["r",[13.4,14.1,15.2,16.7],[7.6,6.9,5.8,4.3]]]:
		for i in 4:result.append({"id":"front_%s_%.1f"%[pair[0],pair[1][i]],"parent":"wing_%s_20.6"%("left" if pair[0]=="l" else "right"),"anchor":[pair[2][i],1.2,.75 if pair[0]=="l" else -.75],"edge":"front"})
	for x in [11.0,12.4,13.6,15.0]:result.append({"id":"rear_%.1f"%x,"parent":"","anchor":[x,21.8,28.3],"edge":"rear"})
	return result

func run() -> void:
	game=World.new();root.add_child(game)
	game.player_controller=Player.new(game);game.player_controller.make()
	game.desktop_input=preload("res://scripts/desktop_input.gd").new(game)
	game.targeting=preload("res://scripts/targeting.gd").new(game)
	blockout=Blockout.new();game.add_child(blockout)
	blockout.spec={"rope_stations":contract(),"groups":{},"access":{"levels":[20.6],"duration":1.0,"modes":{"work":[],"delivery":[20.6]}}}
	for side in ["left","right"]:
		var id="wing_"+side+"_20.6"
		var frame={"parent":"","position":[5 if side=="left" else 21,20.6,24],"rotation_degrees":[0,0 if side=="left" else 180,0],"joint":"wing","side":side,"level":20.6}
		blockout.spec.groups[id]=frame
		var group=Node3D.new();blockout.add_child(group);group.transform=Blockout.authored_pose(frame);blockout.groups[id]=group;blockout.group_pieces[id]=[]
	access=Access.new();game.add_child(access);access.setup(game,blockout);game.equipment.register(access)
	rope=Rope.new();game.add_child(rope);rope.setup(game,blockout);game.equipment.register(rope)
	obstacle(Vector3(13,-.1,27),Vector3(30,.2,20))
	obstacle(Vector3(9.3,20.5,24),Vector3(2,.2,1.2))
	obstacle(Vector3(11,20.5,31),Vector3(2,.2,1.4))
	var deck=obstacle(Vector3(9.3,8.3,24.75),Vector3(2,.2,1))
	await frames(2)
	expect(rope.stations.size()==12 and rope.anchor(FRONT).is_equal_approx(Vector3(9.3,21.8,24.75)) and rope.anchor("front_r_13.4").is_equal_approx(Vector3(13.4,21.8,24.75)),"All twelve contract anchors resolve both mirrored leaf frames")
	place(Vector3(9.3,20.6,24.1));await frames(1)
	expect(not rope.gate_passable(FRONT) and game.player.test_move(game.player.global_transform,Vector3(0,0,.8)),"Unclipped gate is a real collision barrier")
	expect(aim("clip:"+FRONT) and rope.request("clip:"+FRONT).is_empty(),"Camera aim and ordinary reach allow clipping from the walkway")
	expect(rope.gate_passable(FRONT) and not game.player.test_move(game.player.global_transform,Vector3(0,0,.8)),"Only the attached station opens its gate")
	expect(not rope.gate_passable("front_l_10.8") and not rope.front_ropes_clear(),"Other gates remain guarded and occupied front line interlocks leaves")
	# Supplied off-edge pose isolates the movement mode; no automated walking.
	place(Vector3(9.3,20.6,25.05));await tick()
	expect(rope.hanging and absf(game.player.position.y-20.6)<.02,"Stepping beyond support locks height without free fall")
	expect(not rope.unclip().is_empty() and rope.attached(),"Hanging player cannot unclip")
	key(KEY_CTRL,true);await tick(10);key(KEY_CTRL,false)
	expect(absf(game.player.position.y-19.6)<.03 and not game.crouched,"Ctrl pays out at one metre per second without crouching")
	var held=game.player.position;await tick(5)
	expect(game.player.position.distance_to(held)<.02,"Released descender stays locked")
	key(KEY_D,true);await tick(20);key(KEY_D,false)
	expect(rope.slack.length()<=Rope.SLACK+.001 and rope.horizontal(game.player.position-rope.anchor(FRONT)).length()<=Rope.SLACK+.01,"WASD slack remains inside the 0.35 metre circle")
	# Pull-in ray hits supported robot structure, with actual normal collision.
	place(Vector3(9.3,15,24.75));rope.slack=Vector3.ZERO;await tick()
	var robot=obstacle(Vector3(9.3,15.8,26.15),Vector3(1,2,.3));robot.set_meta("assembly_id","chest")
	game.model.assemblies={"chest":{"parent":"","location":"support:gantry"}}
	await frames(2)
	expect(not rope.attach_lanyard(Vector3(9.3,16,26.5),robot).is_empty(),"Pull-in beyond 1.6 metres horizontally is refused")
	game.camera.look_at(Vector3(9.3,16.4,26));key(KEY_G,true);key(KEY_G,false)
	expect(rope.pull_in!=null,"Dedicated G key ray clips a supported robot surface")
	await tick(20)
	expect(absf(game.player.position.z-25.55)<.03 and game.player.position.y>14.99,"Pull-in holds about 0.45 metres from structure at the working height")
	var saved: Dictionary=JSON.parse_string(JSON.stringify(rope.capture()))
	var world={"player":[game.player.position.x,game.player.position.y,game.player.position.z,0.0,0.0]}
	expect(rope.validate(saved,null,world).is_empty(),"Pulled-in snapshot is valid at rest")
	rope.apply(saved)
	expect(JSON.parse_string(JSON.stringify(rope.capture()))==saved,"Pulled-in rope save round-trips")
	key(KEY_G,true);key(KEY_G,false);await tick(20)
	expect(rope.pull_in==null and rope.horizontal(game.player.position-rope.anchor(FRONT)).length()<.02,"G releases the lanyard and returns toward plumb")
	var wall=obstacle(Vector3(9.65,15.8,24.75),Vector3(.1,2,1));await frames(2)
	key(KEY_D,true);await tick(10);key(KEY_D,false)
	expect(game.player.position.x<9.4,"Slack movement never crosses a solid")
	wall.free();robot.free();rope.slack=Vector3.ZERO
	key(KEY_CTRL,true);await tick(90);key(KEY_CTRL,false)
	expect(not rope.hanging and absf(game.player.position.y-8.4)<.04 and rope.attached(),"Descending lands on an 8.4 metre deck still clipped")
	key(KEY_G,true);key(KEY_G,false)
	expect(not rope.attached() and rope.ropes[FRONT].deployed and not rope.front_ropes_clear(),"G unclips on a floor and leaves a deployed rope interlocking leaves")
	expect(aim("end:"+FRONT) and rope.request("end:"+FRONT).is_empty(),"Hanging end can be aimed at and clipped from below within normal reach")
	key(KEY_SPACE,true);await tick(15);key(KEY_SPACE,false)
	expect(rope.hanging and game.player.position.y>9.8,"Space ascends from the lower deck")
	saved=JSON.parse_string(JSON.stringify(rope.capture()));rope.apply(saved)
	expect(rope.validate(saved).is_empty() and JSON.parse_string(JSON.stringify(rope.capture()))==saved,"Hanging snapshot round-trips independently of grounded state")
	key(KEY_SPACE,true);await tick(130);key(KEY_SPACE,false)
	expect(absf(game.player.position.y-20.65)<.02 and absf(rope.ropes[FRONT].length-Rope.MIN_LENGTH)<.02,"Ascent stops below the anchor at the top boarding height")
	# Return pose supplied; capsule drops onto real walkway without teleport in mode.
	place(Vector3(9.3,20.6,24.2));await tick();expect(rope.unclip().is_empty(),"Top walkway supports landing and unclipping")
	expect(access.request_mode("delivery").is_empty(),"A pending leaf trip is accepted")
	access.physics(.1)
	expect(access.moving and access.channels["20.6"].value==0 and access.blocked_reason==Rope.LEAF_REASON,"Leaf motion pauses with the named recall reason")
	# Free ropes must remain recallable while the access trip is waiting.
	expect(aim("recall:"+FRONT) and rope.request("recall:"+FRONT).is_empty(),"Station reel recalls a free line while leaves wait")
	access.physics(1)
	expect(rope.front_ropes_clear() and not access.moving and access.channels["20.6"].value==1,"Recalled ropes release the pending leaf motion")
	var closed=Vector3(9.3,21.8,24.75)
	expect(rope.anchor(FRONT).distance_to(closed)>1,"Station anchor follows a changed leaf transform")
	expect(not rope.action_error("clip:"+FRONT).is_empty(),"Open leaf never offers rappelling")
	access.request_mode("work");access.physics(1)
	# Ground limit and rear station path are isolated from the front landing.
	place(Vector3(11,20.6,30.8));await tick()
	expect(aim("clip:"+REAR) and rope.request("clip:"+REAR).is_empty() and rope.front_ropes_clear(),"Rear boom control is within walkway reach and does not interlock leaves")
	place(Vector3(11,19,28.3));await tick();key(KEY_CTRL,true);await tick(210);key(KEY_CTRL,false)
	expect(rope.on_floor() and absf(game.player.position.y)<.04 and rope.ropes[REAR].length<=rope.max_length(REAR),"Descent stops at the ground and maximum line length")
	rope.unclip()
	var valid: Dictionary=rope.capture()
	for corrupt in ["station","length","nan","stowed","pull","slack","identity"]:
		var invalid=valid.duplicate(true)
		match corrupt:
			"station":invalid.attachment="missing"
			"length":invalid.ropes[REAR].length=999
			"nan":invalid.ropes[REAR].length=NAN
			"stowed":invalid.attachment=FRONT
			"pull":invalid.pull_in=[1,2,3]
			"slack":invalid.slack=[2,0,0]
			"identity":invalid.ropes.erase(FRONT)
		expect(not rope.validate(invalid).is_empty(),"Invalid snapshot rejected: "+corrupt)
	game.hud.browser.free();game.free();await frames(1)
	var passed=checks.all(func(c):return c.passed)
	print("ROPE_ACCESS ","PASS " if passed else "FAIL ",checks.size()," checks")
	quit(0 if passed else 1)
