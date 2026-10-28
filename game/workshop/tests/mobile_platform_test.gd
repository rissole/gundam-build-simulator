extends "res://tests/kit/harness.gd"
## Small real-physics fixture: free driving, desktop operation, nudging and saves.
## Supplied poses are mechanical checks, never walked/access acceptance.
const Fixture = preload("res://tests/kit/equipment_fixture.gd")
const Platform = preload("res://scripts/mobile_work_platform.gd")
class Hands extends RefCounted:
	var held_body: CollisionObject3D
	func title(kind):return kind
class Hud extends RefCounted:
	var target_panel = Control.new()
	var quiet_errors = false
	func handle_manual_browser_input(_event):return false
	func refresh():pass
class Game extends Fixture:
	const REACH = 2.0
	var player: CharacterBody3D
	var camera: Camera3D
	var components = Hands.new()
	var loose = {}
	var started = true
	var automated_test = true
	var scripted_controls = {}
	var jump_requested = false
	var target = {}
	var hud = Hud.new()
	var targeting = {"offered_key":"E"}
	var desktop_input = preload("res://scripts/desktop_input.gd").new(self)
	var player_controller = preload("res://scripts/player_controller.gd").new(self)
	func interact(_shift):target.controller.request(target.action)
	func _update_target():pass
	func set_paused(value):paused = value
	func _visible(point, allowed):
		var hit = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position,point,1,[player.get_rid()]))
		return hit.is_empty() or hit.collider in allowed
	func _exit_tree():hud.target_panel.free()
func _initialize():call_deferred("run")
func key(game, code, pressed):
	var event = InputEventKey.new();event.physical_keycode = code;event.pressed = pressed
	game.desktop_input.handle(event)
func shape(body, size):
	var col = CollisionShape3D.new();col.shape = BoxShape3D.new();col.shape.size = size;body.add_child(col)
func obstacle(game, at, size):
	var body = StaticBody3D.new();game.add_child(body);body.position = at;shape(body,size);return body
func part(game, id, at):
	var body = WorkshopPart.new();body.uid = id;body.kind = id;body.collision_layer = 2;body.collision_mask = 15
	game.add_child(body);shape(body,Vector3(.2,.2,.2));body.position = at
	game.loose[id] = body;game.model.items[id] = {"location":"loose"}
	return body
func tick(game, count):
	for i in count:
		game.equipment.physics(.05);await frames(1)
func run():
	var game = Game.new();root.add_child(game)
	var spec = JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop-layout.json")).workshop.mobile_platform
	spec.parking = [0,0,0]
	var platform = Platform.new();game.add_child(platform);platform.setup(game,spec);game.equipment.register(platform)
	var floor = obstacle(game,Vector3(0,-.1,0),Vector3(30,.2,30))
	game.player = CharacterBody3D.new();game.player.collision_layer = 8;game.add_child(game.player)
	var capsule = CollisionShape3D.new();capsule.shape = CapsuleShape3D.new();capsule.shape.radius = .26;capsule.shape.height = 1.7;capsule.position.y = .86;game.player.add_child(capsule)
	game.camera = Camera3D.new();game.player.add_child(game.camera);game.camera.position.y = 1.63
	game.player.position = Vector3(4,0,0);await frames(3)
	expect(not platform.request("operate").is_empty(),"onboard control refuses remote driving")
	game.player.position = Vector3(0,spec.heights[0],0);await frames(2)
	game.target = platform.controls().filter(func(entry):return entry.action=="operate")[0]
	key(game,KEY_E,true);key(game,KEY_E,false)
	expect(platform.drive_controls.is_open and game.desktop_input.modal_active(),"E on Operate enters onboard operation through the desktop adapter")
	var hand = obstacle(game,game.player.position+Vector3(0,1.2,-.45),Vector3(.2,.2,.2));game.components.held_body = hand
	var grip = hand.position-game.player.position
	var rope = preload("res://scripts/rope_access.gd").new();game.add_child(rope)
	rope.game = game;rope.equipment_id = "rope_access";rope.attachment = "supplied";rope.hanging = false;game.equipment.register(rope)
	var tethered = platform.position;platform.drive(Vector2(0,-1),.05)
	expect(platform.position.is_equal_approx(tethered) and platform.blocked_reason.contains("Unclip"),"shared rope guard blocks free driving while clipped in")
	rope.free()
	var start = platform.position
	key(game,KEY_W,true);await tick(game,1)
	var slow = platform.speed
	expect(slow>0 and slow<spec.speed*.3,"drive starts with a small acceleration step")
	await tick(game,8)
	expect(is_equal_approx(platform.speed,spec.speed) and platform.position.z<start.z-.2,"held W reaches cruising speed toward the nose")
	expect(game.player.position.distance_to(platform.position+Vector3(0,spec.heights[0],0))<.001,"shared registry carries the operator exactly once")
	expect(hand.position.is_equal_approx(game.player.position+grip),"hand load travels with the driving operator")
	key(game,KEY_W,false);var at = platform.position;await tick(game,1)
	expect(platform.speed>0 and platform.speed<spec.speed and platform.position.z<at.z,"key release decelerates instead of snapping to rest")
	await tick(game,6);at = platform.position;await tick(game,3)
	expect(platform.position.is_equal_approx(at) and not platform.moving,"short braking ramp reaches rest without lingering drift")
	var mouse = InputEventMouseMotion.new();mouse.relative = Vector2(100,10);game.desktop_input.handle(mouse)
	var relative_yaw = game.player.rotation.y-platform.rotation.y
	expect(not is_zero_approx(relative_yaw),"mouse look remains independent of steering")
	var hand_local = platform.global_transform.affine_inverse()*hand.global_transform
	key(game,KEY_D,true);await tick(game,12);key(game,KEY_D,false);await tick(game,6)
	expect(platform.rotation.y<-.3 and platform.position.is_equal_approx(at),"D physically turns the platform right in place without strafing")
	expect(is_equal_approx(game.player.rotation.y-platform.rotation.y,relative_yaw),"turning carries the rider's heading while preserving free look")
	expect(hand.global_transform.is_equal_approx(platform.global_transform*hand_local),"held load inherits the continuous turning pose")
	game.components.held_body = null;hand.free()
	var heading = -platform.global_basis.z
	key(game,KEY_W,true);await tick(game,10);key(game,KEY_W,false);await tick(game,6)
	expect((platform.position-at).normalized().dot(heading)>.999,"W follows the turned chassis, independently of the camera")
	key(game,KEY_SPACE,true);await tick(game,7);key(game,KEY_SPACE,false);await tick(game,1)
	var intermediate = platform.height;await tick(game,5)
	expect(intermediate>spec.heights[0] and platform.height==intermediate and not platform.moving,"Space raises only while held and releases at an arbitrary height")
	at = platform.position;var raised = platform.height
	key(game,KEY_W,true);await tick(game,10);key(game,KEY_W,false);await tick(game,6)
	expect(platform.position.distance_to(at)>.12 and is_equal_approx(platform.height,raised),"raised platform drives at its selected height")
	expect(platform.rider()==game.player and game.player.position.distance_to(platform.global_transform*Vector3(0,raised,0))<.001,"raised ground travel carries its operator")
	at = platform.position;key(game,KEY_D,true);await tick(game,9);key(game,KEY_D,false);await tick(game,6)
	expect(platform.rotation.y<-.4 and platform.position.is_equal_approx(at) and is_equal_approx(platform.height,raised),"raised platform steers in place without lowering")
	var high_wall = obstacle(game,platform.global_transform*Vector3(0,raised+.6,-2.1),Vector3(1.5,1.5,.15));high_wall.global_basis = platform.global_basis
	await frames(2)
	key(game,KEY_W,true);await tick(game,35);key(game,KEY_W,false)
	expect(platform.motion_obstruction.get("collider")==high_wall and platform.position.distance_to(high_wall.position)>1.1,"raised deck and rider stop before a fixed overhead-height obstacle")
	high_wall.free();await tick(game,6)
	key(game,KEY_CTRL,true);await tick(game,10);key(game,KEY_CTRL,false);await tick(game,1)
	expect(is_equal_approx(platform.height,spec.heights[0]) and not game.jump_requested,"Ctrl lowers to the limit without leaking jump or crouch input")
	key(game,KEY_E,true);key(game,KEY_E,false)
	expect(not platform.drive_controls.is_open and not game.desktop_input.modal_active(),"E releases the controls")
	game.player.rotation = Vector3.ZERO;game.camera.rotation = Vector3.ZERO
	game.target = platform.controls().filter(func(entry):return entry.action=="operate")[0]
	key(game,KEY_E,true);key(game,KEY_E,false);key(game,KEY_W,true);await tick(game,1);key(game,KEY_ESCAPE,true)
	expect(game.paused and not platform.drive_controls.is_open and not platform.moving,"Escape brakes, releases operation and pauses")
	game.paused = false;key(game,KEY_W,false)
	platform.request("operate");platform.drive_controls._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	expect(not platform.drive_controls.is_open and not platform.moving,"focus loss brakes without retained drive input")
	platform.lift(1,.05);platform.lift(0,0)
	var snapshot = JSON.parse_string(JSON.stringify(platform.capture()));var saved = platform.transform;var saved_height = platform.height
	platform.position = Vector3(7,0,7);platform.rotation.y = 1.3;platform.apply(snapshot)
	expect(platform.validate(snapshot).is_empty() and platform.transform.is_equal_approx(saved) and is_equal_approx(platform.height,saved_height) and not platform.moving,"arbitrary position, heading and held height round-trip at rest through JSON")
	snapshot.position[1] = 1
	expect(not platform.validate(snapshot).is_empty(),"snapshot rejects a floating base")
	game.player.position = Vector3(5,0,5);platform.position = Vector3.ZERO;platform.height = spec.heights[0];platform.rotation.y = -PI/2;platform.halt();await frames(2)
	# Real loose parts in front of the base. A second touching part forms a pile.
	var first = part(game,"first",Vector3(1.89,.105,0))
	var second = part(game,"second",Vector3(2.10,.105,0));await frames(12)
	var original = first.position
	for i in 18:platform.drive(Vector2(0,-1),.05);await frames(1)
	expect(first.position.x>original.x+.1 and second.position.x>2.2,"base nudges a loose pile along the driven direction")
	expect(game.model.items.first.location=="loose" and game.loose.first==first,"nudge preserves part identity and loose ownership")
	# A held identity must never become pushable merely because its collider is loose.
	first.held = true
	expect(not preload("res://scripts/loose_part_nudge.gd").pushable(game,first),"held parts cannot be nudged")
	first.held = false
	var wall = obstacle(game,Vector3(3.2,.3,0),Vector3(.2,.6,.5));await frames(2)
	for i in 20:platform.drive(Vector2(0,-1),.05);await frames(1)
	at = platform.position;var pinned = first.position
	platform.drive(Vector2(0,-1),.05)
	expect(not platform.blocked_reason.is_empty() and platform.position.is_equal_approx(at) and first.position.is_equal_approx(pinned),"pinned pile blocks transactionally without partial nudges")
	expect(second.position.x<3.01,"pushed parts stay outside the wall")
	platform.drive(Vector2(0,1),.05)
	expect(platform.position.x<at.x,"blocked platform can immediately reverse")
	wall.free();first.free();second.free();game.loose.clear()
	platform.halt();platform.position = Vector3.ZERO;platform._pose();await frames(2)
	var fixed = obstacle(game,Vector3(1.89,.2,0),Vector3(.2,.4,.3));await frames(2)
	for i in 10:platform.drive(Vector2(0,-1),.05)
	expect(platform.position.x<.1 and not platform.blocked_reason.is_empty(),"fixed equipment remains solid")
	fixed.free();platform.halt();await frames(2)
	platform.position = Vector3.ZERO;platform.rotation.y = 0;platform.halt();await frames(2)
	var corner = obstacle(game,Vector3(1.0,1.1,0),Vector3(.12,.4,2.4));await frames(2)
	for i in 60:platform.drive(Vector2.RIGHT,.05)
	expect(platform.rotation.y<-.05 and platform.rotation.y>-PI/2 and not platform.blocked_reason.is_empty(),"long deck's turning sweep stops before a fixed side obstacle")
	var stopped_yaw = platform.rotation.y;platform.drive(Vector2.LEFT,.05)
	expect(platform.rotation.y>stopped_yaw,"a blocked turn can steer back out without retained angular momentum")
	corner.free();platform.rotation.y = 0;platform.halt();await frames(2)
	var overhead = obstacle(game,Vector3(0,2,0),Vector3(.5,.2,.5));await frames(2)
	for i in 80:platform.lift(1,.05)
	expect(platform.height<=1.902 and not platform.blocked_reason.is_empty(),"overhead obstacle stops held raising")
	overhead.free();await frames(2)
	for i in 100:platform.lift(1,.05)
	expect(is_equal_approx(platform.height,spec.heights[-1]),"held height input reaches its upper limit after clearing the obstacle")
	platform.lift(0,0)
	for i in 100:platform.lift(-1,.05)
	platform.lift(0,0)
	expect(is_equal_approx(platform.height,spec.heights[0]),"lowering stops at boarding height")
	platform.position = Vector3(.19,0,.19);platform.rotation.y = 0;platform._pose()
	expect(platform.busy_reason("bulky_tilt").is_empty(),"parking mark allows a small manual positioning tolerance")
	platform.rotation.y = PI/2
	expect(not platform.busy_reason("bulky_tilt").is_empty(),"parking interlock uses the rotated footprint, not just its centre")
	expect(platform.controls().size()==1 and platform.controls()[0].label=="Operate","only the red Operate control is exposed")
	expect(platform.deck.find_children("*","Label3D",true,false).is_empty(),"platform has no physical status display")
	expect(spec.size[1]>spec.size[0]*2 and spec.deck_size[1]>spec.deck_size[0]*1.5,"chassis and deck have an elongated footprint")
	var ramp: MeshInstance3D = platform.base.get_node("BoardingRamp")
	var vertices: PackedVector3Array = ramp.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var edge_uses: Dictionary = {}
	var floor_or_chassis_face = false
	var above_floor = true
	for index in range(0,vertices.size(),3):
		var face = [vertices[index],vertices[index+1],vertices[index+2]]
		for vertex in face:
			if vertex.y<.007:above_floor = false
		if face.all(func(v):return is_zero_approx(v.y)) or face.all(func(v):return is_equal_approx(v.z,spec.deck_size[1]/2)):floor_or_chassis_face = true
		for side in 3:
			var ends = [str(face[side]),str(face[(side+1)%3])];ends.sort()
			var edge = ends[0]+"|"+ends[1]
			edge_uses[edge] = int(edge_uses.get(edge,0))+1
	expect(vertices.size()==36 and edge_uses.values().all(func(count):return count==2),"ramp visual is a closed thin plate with no open edges")
	expect(not floor_or_chassis_face and above_floor,"closed ramp has no face flush with the floor or chassis rear plane")
	expect(platform.base.get_children().any(func(child):return child is CollisionShape3D and child.shape is ConvexPolygonShape3D and child.shape.points.size()==6),"ramp keeps its full solid walking shape")
	platform.position = Vector3.ZERO;platform.rotation.y = 0;platform.height = spec.heights[-1];platform.halt()
	game.player.position = Vector3(1.4,0,1.05);await frames(2)
	var call = platform.controls().filter(func(entry):return entry.action=="call")
	expect(call.size()==1 and call[0].node.global_position.distance_to(game.camera.global_position)<game.REACH,"raised lift offers a ground-reachable call button on its chassis")
	expect(platform.request("call").is_empty() and platform.mode=="call","call starts a guarded descent")
	platform.physics(.05)
	expect(platform.height<spec.heights[-1]-.1,"call starts faster than held lowering")
	var before_pause = platform.height;game.paused = true;platform.physics(.5);game.paused = false
	expect(is_equal_approx(platform.height,before_pause),"pause holds a called descent")
	var blocker = obstacle(game,Vector3(0,1.7,0),Vector3(.6,.2,.6));await frames(2)
	for i in 100:
		platform.physics(.05)
		if not platform.blocked_reason.is_empty():break
	expect(platform.moving and platform.height>spec.heights[0] and platform.motion_obstruction.get("collider")==blocker,"called descent waits above an obstruction")
	blocker.free();await frames(2)
	var clear_seconds = 0.0
	for i in 30:
		platform.physics(.05)
		clear_seconds += .05
		if not platform.moving:break
	expect(is_equal_approx(platform.height,spec.heights[0]) and platform.mode.is_empty() and not platform.moving and clear_seconds<=Platform.CALL_DURATION,"called lift resumes and reaches boarding height within the unspent 0.9-second call")
	expect(platform.controls().all(func(entry):return entry.action!="call"),"ground call prompt disappears after arrival")
	var passed = checks.all(func(check):return check.passed)
	write_evidence("res://verification/mobile-platform.json",{"scope":"mechanical and input checks only","checks":checks})
	print("MOBILE_PLATFORM ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
