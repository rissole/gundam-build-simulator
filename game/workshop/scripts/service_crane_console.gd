extends CanvasLayer
## Modal physical console: pointer navigation never changes the player's view.
var crane: Node3D
var panel: PanelContainer
var backdrop: Control
var status: Label
var feedback: Label
var choices: VBoxContainer
var buttons: Dictionary = {}
var order: Array[String] = []
var selected = 0
var is_open = false

func setup(controller: Node3D) -> void:
	crane = controller;layer = 40
	backdrop = ColorRect.new();backdrop.color = Color("111d26")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	var center = CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.add_child(center)
	panel = PanelContainer.new();panel.custom_minimum_size = Vector2(720,0);center.add_child(panel)
	var margin = MarginContainer.new()
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,28)
	panel.add_child(margin)
	var column = VBoxContainer.new();column.add_theme_constant_override("separation",16);margin.add_child(column)
	var heading = Label.new();heading.text = "Crane control";heading.add_theme_font_size_override("font_size",30);column.add_child(heading)
	status = Label.new();status.custom_minimum_size.x = 620;status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;column.add_child(status)
	choices = VBoxContainer.new();choices.add_theme_constant_override("separation",10);column.add_child(choices)
	feedback = Label.new();feedback.custom_minimum_size.x = 620;feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;column.add_child(feedback)
	var help = Label.new();help.text = "↑ / ↓ choose · E select · Q close · Esc pause";column.add_child(help)
	var close = Button.new();close.text = "Close";close.custom_minimum_size.y = 44;column.add_child(close);close.pressed.connect(shut)
	backdrop.hide()

func open() -> String:
	var error: String = crane.console_access_error()
	if not error.is_empty():return error
	is_open = true;selected = 0;feedback.text = "";backdrop.show()
	crane.game.desktop_input.push_modal(self)
	crane.game.scripted_controls.clear();crane.game.jump_requested = false
	crane.game.player.velocity.x = 0;crane.game.player.velocity.z = 0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;refresh()
	return ""

func shut() -> void:
	is_open = false
	if is_instance_valid(crane) and is_instance_valid(crane.game):crane.game.desktop_input.pop_modal(self)
	if is_instance_valid(backdrop):backdrop.hide()
	if is_instance_valid(crane) and not crane.game.paused:Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func handle_modal_input(event: InputEvent) -> void:
	handle_input(event)

func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:shut();crane.game.set_paused(true)
			KEY_Q:shut()
			KEY_UP:selected = posmod(selected-1,maxi(1,order.size()));_focus()
			KEY_DOWN:selected = posmod(selected+1,maxi(1,order.size()));_focus()
			KEY_E, KEY_ENTER:
				if not order.is_empty():_command(order[selected])

func _focus() -> void:
	if is_open and not order.is_empty():buttons[order[selected]].grab_focus()

func _command(action: String) -> void:
	var error: String = crane.request_console(action)
	feedback.text = error if not error.is_empty() else "Command accepted."
	refresh()

func refresh() -> void:
	if not is_instance_valid(status):return
	status.text = crane.status_text()
	var options: Array[Dictionary] = crane.menu_options()
	var actions: Array[String] = []
	for option in options:actions.append(option.action)
	if actions != order:
		for child in choices.get_children():choices.remove_child(child);child.queue_free()
		buttons.clear();order = actions;selected = mini(selected,maxi(0,order.size()-1))
		for option in options:
			var button = Button.new();button.text = option.label;button.custom_minimum_size.y = 52
			choices.add_child(button);buttons[option.action] = button
			button.pressed.connect(_command.bind(option.action))
		_focus()
	for action in order:buttons[action].tooltip_text = crane.action_error(action)

func physics() -> void:
	if not is_open:return
	if crane.game.paused or not crane.console_access_error().is_empty():shut()
	else:refresh()

func _input(event: InputEvent) -> void:
	if is_open and event is InputEventKey and event.physical_keycode in [KEY_UP,KEY_DOWN,KEY_E,KEY_ENTER,KEY_Q,KEY_ESCAPE]:
		handle_input(event)
		get_viewport().set_input_as_handled()
