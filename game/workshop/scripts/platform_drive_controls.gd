extends CanvasLayer
## One onboard operating mode: vehicle steering, free look and held height keys.
var platform: Node3D
var is_open = false
var panel: PanelContainer
var hint: Label

func setup(controller: Node3D) -> void:
	platform = controller;layer = 40
	panel = PanelContainer.new();add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -270;panel.offset_right = 270;panel.offset_top = -100;panel.offset_bottom = -24
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint = Label.new();panel.add_child(hint);hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size",18)
	panel.hide()

func open() -> String:
	var error: String = platform.operate_access_error()
	if not error.is_empty():return error
	is_open = true;panel.show()
	platform.game.desktop_input.push_modal(self)
	platform.game.scripted_controls.clear();platform.game.jump_requested = false
	platform.game.player.velocity.x = 0;platform.game.player.velocity.z = 0
	platform.game.player.global_rotation.y = platform.global_rotation.y
	platform.game.camera.rotation.x = 0
	platform.halt()
	platform.game.hud.target_panel.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_refresh()
	return ""

func shut() -> void:
	if not is_open:return
	is_open = false;panel.hide()
	platform.game.desktop_input.pop_modal(self)
	platform.game.scripted_controls.clear()
	platform.halt()

func physics(delta: float) -> void:
	if platform.game.paused or platform.rider()==null:
		shut();return
	var input = platform.game.player_controller
	var direction = Vector2(float(input.movement_pressed(KEY_D))-float(input.movement_pressed(KEY_A)),float(input.movement_pressed(KEY_S))-float(input.movement_pressed(KEY_W)))
	var vertical = float(input.movement_pressed(KEY_SPACE))-float(input.movement_pressed(KEY_CTRL))
	if not is_zero_approx(vertical):platform.lift(vertical,delta)
	else:
		if platform.mode=="height":platform.lift(0,0)
		platform.drive(direction,delta)
	_refresh()

func _refresh() -> void:
	hint.text = "W/S drive · A/D steer · Space ↑ · Ctrl ↓\nMouse to look · Release keys to brake · E leave"
	if not platform.blocked_reason.is_empty():hint.text = platform.blocked_reason+"\nW/S drive · A/D steer · Space ↑ · Ctrl ↓ · E leave"

func handle_modal_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		platform.game.player_controller.look(event.relative)
	if not event is InputEventKey:return
	if platform.game.automated_test:platform.game.scripted_controls[event.physical_keycode] = event.pressed
	if not event.pressed or event.echo:return
	if event.physical_keycode in [KEY_E,KEY_Q,KEY_ESCAPE]:
		shut()
		if event.physical_keycode==KEY_ESCAPE:platform.game.set_paused(true)

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_open:shut()
