extends RefCounted
## Desktop key and mouse dispatch. While a modal handler is open it receives
## every event, and movement, look, targeting and world actions are suppressed.
var game: Node
var _modals: Array[Object] = []
const EquipmentButton = preload("res://scripts/equipment_button.gd")
var _held_control: Dictionary = {}
var _interact_held = false

func _init(workshop: Node) -> void:
	game = workshop

## A modal handler implements `handle_modal_input(event: InputEvent)`.
func push_modal(handler: Object) -> void:
	release_control()
	if not _modals.has(handler):_modals.append(handler)

func pop_modal(handler: Object) -> void:
	_modals.erase(handler)

func modal_active() -> bool:
	for handler in _modals.duplicate():
		if not is_instance_valid(handler):_modals.erase(handler)
	return not _modals.is_empty()

## Called before equipment physics so releasing never leaves one extra jog tick.
func physics(delta: float) -> void:
	# GUI controls may consume key-up before _unhandled_input sees it.
	if not game.automated_test and _interact_held and not Input.is_physical_key_pressed(KEY_E):
		_interact_held = false
		release_control()
	if not game.started or game.paused or modal_active():
		release_control()
		return
	if _held_control.is_empty():return
	if not is_instance_valid(_held_control.node) or not _held_control.handler.is_valid():
		release_control()
		return
	_held_control.handler.call(true,delta)

func release_control() -> void:
	var previous = _held_control
	_held_control = {}
	if not previous.is_empty() and previous.handler.is_valid():previous.handler.call(false,0.0)

func handle(event: InputEvent) -> void:
	# Track E before any menu consumes it. Closing a menu while E is still down
	# must not reacquire a control; only release followed by a fresh press can.
	var fresh_interact = false
	if event is InputEventKey and event.physical_keycode == KEY_E:
		fresh_interact = event.pressed and not event.echo and not _interact_held
		_interact_held = event.pressed
		if not event.pressed:release_control()
	if game.started and modal_active():
		_modals.back().handle_modal_input(event)
		return
	if game.automated_test and event is InputEventKey:game.scripted_controls[event.physical_keycode] = event.pressed
	# Track releases even when a menu consumes input. Only a fresh press can
	# request a jump, so holding Space through landing or a menu cannot repeat it.
	if event is InputEventKey and event.physical_keycode == KEY_SPACE:
		var fresh_press = event.pressed and not event.echo and not game.jump_held
		game.jump_held = event.pressed
		if not game.started:return
		if game.hud.handle_manual_browser_input(event):
			game.jump_requested = false
			return
		if fresh_press and not game.paused:game.jump_requested = true
		return
	if not game.started: return
	if game.hud.handle_manual_browser_input(event):
		game.jump_requested = false
		return
	if event is InputEventKey and event.physical_keycode == KEY_R and not event.echo:
		if not game.paused: rotation_key(event.pressed)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			game.set_paused(not game.paused)
			game.get_viewport().set_input_as_handled()
			return
		if game.paused: return
		match event.physical_keycode:
			KEY_1: game.model.select_pocket(0)
			KEY_2: game.model.select_pocket(1)
			KEY_3: game.model.select_pocket(2)
			KEY_4: game.model.select_pocket(3)
			KEY_5: game.model.select_pocket(4)
			KEY_6: game.model.select_pocket(5)
			KEY_7: game.model.select_pocket(6)
			KEY_8: game.model.select_pocket(7)
			KEY_9: game.model.select_pocket(8)
			KEY_0: game.model.select_pocket(9)
			KEY_E:
				if fresh_interact:
					if EquipmentButton.hold_handler(game.target).is_valid():
						_held_control = game.targeting.latch_control()
					else:game.interact(event.shift_pressed)
			KEY_Q:
				var rope = game.equipment.get_equipment("rope_access")
				if rope!=null and rope.attached():
					var error: String=rope.unclip()
					if not error.is_empty():game.hud.toast(error)
				else:game.drop_selected()
			KEY_B: game.deposit()
			KEY_Z: game.undo_build()
			KEY_TAB: game.hud.manual.visible = not game.hud.manual.visible
			KEY_PAGEUP: game.hud.body_scroll.scroll_vertical -= 140
			KEY_PAGEDOWN: game.hud.body_scroll.scroll_vertical += 140
			KEY_F: reset_station()
			KEY_G:
				var rope = game.equipment.get_equipment("rope_access")
				if rope!=null:
					var error: String=rope.rope_key()
					if not error.is_empty():game.hud.toast(error)
		game.hud.refresh()
		# Pocket changes can switch between pickup and placement intent. Resolve
		# that immediately so selecting a part and clicking in one frame works.
		game._update_target()
	if game.paused: return
	if event is InputEventMouseMotion:
		if game.rotate_held:
			if event.relative.length() > 0.5: game.rotate_dragged = true
			rotate_station(event.relative)
		else:
			game.player_controller.look(event.relative)
	if event is InputEventMouseButton and event.pressed:
		# macOS reports Control + left click as right + Control. Control is
		# also our crouch key, so accept that event as a placement click.
		var control_click = OS.has_feature("macos") and event.button_index == MOUSE_BUTTON_RIGHT and event.ctrl_pressed
		if event.button_index == MOUSE_BUTTON_LEFT or control_click: game.attach()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP: game.camera.fov = maxf(42,game.camera.fov-5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: game.camera.fov = minf(85,game.camera.fov+5)

func station_in_view() -> String:
	var selected = "foot"
	var best = game._aim_score(game.foot.global_position,1.9)
	for id in game.stations:
		var score = game._aim_score(game.stations[id].global_position,0.9)
		if score < best:best = score;selected = id
	return "" if best == INF else selected

func rotate_station(relative: Vector2) -> void:
	var station = game.rotation_station if game.rotate_held else station_in_view()
	if station.is_empty():return
	if station == "foot" and game.equipment.get_equipment("foot_fixture") != null:return
	var node: Node3D = game.stations.get(station,game.foot)
	if game.camera.global_position.distance_to(node.global_position)>5.0:return
	node.basis = (Basis(game.camera.global_basis.y,-relative.x*0.006)*Basis(game.camera.global_basis.x,-relative.y*0.006)*node.basis).orthonormalized()

func rotation_key(pressed: bool) -> void:
	if pressed:
		game.rotate_held = true
		game.rotate_dragged = false
		game.rotate_press_time = Time.get_ticks_msec()
		game.rotation_station = station_in_view()
		if game.rotation_station == "foot" and game.equipment.get_equipment("foot_fixture") != null:
			game.rotate_held = false
			game.rotation_station = ""
			game.hud.toast("Use the Foot Bay controls to choose a supported work position.")
	else:
		var now = Time.get_ticks_msec()
		if game.rotate_held and not game.rotate_dragged and now-game.rotate_press_time <= 250 and not game.rotation_station.is_empty():
			if now-game.last_rotate_tap <= 350 and game.last_rotate_station == game.rotation_station:
				reset_station(game.rotation_station)
				game.last_rotate_tap = -1000
			else:
				game.last_rotate_tap = now
				game.last_rotate_station = game.rotation_station
		else:game.last_rotate_tap = -1000
		game.rotate_held = false
		game.rotation_station = ""

func reset_station(station: String = "") -> void:
	if station.is_empty():station = station_in_view()
	if station.is_empty():return
	if station == "foot" and game.equipment.get_equipment("foot_fixture") != null:
		game.hud.toast("Choose Upright at the Foot Bay controls.")
		return
	var node: Node3D = game.stations.get(station,game.foot)
	if game.camera.global_position.distance_to(node.global_position)>5.0:return
	if game.stations.has(station):game.stations[station].basis = game.PREP_BASIS
	elif station == "foot":game.foot.basis = game.FOOT_BASIS
	game.hud.toast("Station returned to its working orientation.",true)

