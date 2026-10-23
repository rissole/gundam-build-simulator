extends RefCounted
## Real desktop input driver. Movement never sets player transforms. Tests that
## isolate a connection may declare an explicit staging pose instead of a route.
var game: Node
var staging_poses: Array[Dictionary] = []
const LOOK_SENSITIVITY = 0.0022

func _init(workshop: Node) -> void:
	game = workshop

func frames(count: int = 3) -> void:
	for tick in range(count):await game.get_tree().physics_frame

func key(code: Key, pressed: bool = true, shift: bool = false) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code;event.pressed = pressed;event.shift_pressed = shift
	game.automation.send(event)

func tap(code: Key, shift: bool = false) -> void:
	key(code,true,shift);key(code,false,shift)

func click(button: MouseButton = MOUSE_BUTTON_LEFT, ctrl: bool = false, pressed: bool = true) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = button;event.ctrl_pressed = ctrl;event.pressed = pressed
	game.automation.send(event)

func look(point: Vector3) -> void:
	var direction = point-game.camera.global_position
	var yaw = atan2(-direction.x,-direction.z)
	var pitch = atan2(direction.y,Vector2(direction.x,direction.z).length())
	look_angles(yaw,pitch)
	game.automation.refresh_target()

func look_angles(yaw: float, pitch: float = 0.0) -> void:
	# Some geometry fixtures rotate the camera locally. Aim from its actual world
	# direction so later ordinary mouse motion accounts for that existing pose.
	for correction in range(3):
		var forward: Vector3 = -game.camera.global_basis.z
		var current_yaw = atan2(-forward.x,-forward.z)
		var current_pitch = atan2(forward.y,Vector2(forward.x,forward.z).length())
		var delta_yaw = wrapf(yaw-current_yaw,-PI,PI)
		var delta_pitch = current_pitch-clampf(pitch,-1.35,1.35)
		if absf(delta_yaw)+absf(delta_pitch)<0.000001:break
		var event = InputEventMouseMotion.new()
		event.relative = Vector2(-delta_yaw,delta_pitch)/LOOK_SENSITIVITY
		game.automation.send(event)

func walk(point: Vector3, max_ticks: int = 1600, tolerance: float = .09, settle_frames: int = 10) -> bool:
	var arrived = false
	for tick in range(max_ticks):
		var offset = point-game.player.global_position;offset.y = 0
		if offset.length() < tolerance:arrived = true;break
		look_angles(atan2(-offset.x,-offset.z))
		key(KEY_W);await frames(1)
	key(KEY_W,false);await frames(settle_frames)
	if not arrived:print("PLAYER_ROUTE feet=",game.player.global_position," destination=",point)
	return arrived and game.player.is_on_floor()

func stage_pose(label: String, feet: Vector3, yaw: float = NAN) -> void:
	if label.is_empty():
		push_error("A player teleport needs an explicit staging label.")
		return
	staging_poses.append({"label":label,"feet":[feet.x,feet.y,feet.z]})
	game.automation.place_player(feet,yaw)

func stage_aim(label: String, point: Vector3, feet: Vector3, settle_frames: int = 5) -> void:
	stage_pose(label,feet)
	look(point)
	await frames(settle_frames)
	game.automation.refresh_target()

func select_kind(kind: String) -> bool:
	var index: int = game.model.pocket_for(kind)
	if index < 0:return false
	tap([KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8,KEY_9,KEY_0][index])
	return true
