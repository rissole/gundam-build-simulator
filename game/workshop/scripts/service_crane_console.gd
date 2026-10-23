extends CanvasLayer
## Modal physical console: pointer navigation never changes the player's view.
var crane: Node3D
var panel: PanelContainer
var backdrop: Control
var status: Label
var load_label: Label
var feedback: Label
var help: Label
var choices: VBoxContainer
var scroll: ScrollContainer
var buttons: Dictionary = {}
var order: Array[String] = []
var selected = 0
var is_open = false
var layout_queued = false
var layout_key: Array = []
const PANEL_WIDTH = 340.0
const EDGE_MARGIN = 16.0

func setup(controller: Node3D) -> void:
	crane = controller;layer = 40
	# Equipment is created before the HUD. Build once its shared styling exists.
	crane.game.ready.connect(_make_panel,CONNECT_ONE_SHOT)

func _make_panel() -> void:
	# Transparent input shield: the workshop stays visible, while clicks cannot
	# reach its HUD or physical interactions behind the console.
	backdrop = Control.new();backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	panel = PanelContainer.new();panel.custom_minimum_size.x = PANEL_WIDTH;backdrop.add_child(panel)
	panel.add_theme_stylebox_override("panel",crane.game.hud.style(Color("101b23ed"),Color("a6bac344"),16))
	var column = VBoxContainer.new();column.add_theme_constant_override("separation",8);panel.add_child(column)
	var heading = crane.game.hud.label("Crane control",20);column.add_child(heading)
	load_label = _label(column,15)
	load_label.add_theme_color_override("font_color",crane.game.hud.tone)
	status = _label(column,14)
	scroll = ScrollContainer.new();scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL;column.add_child(scroll)
	choices = VBoxContainer.new();choices.add_theme_constant_override("separation",6)
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL;scroll.add_child(choices)
	feedback = _label(column,14)
	help = _label(column,12);help.text = "↑ / ↓ choose · E select\nQ close · Esc pause"
	help.add_theme_color_override("font_color",crane.game.hud.muted)
	var close = crane.game.hud.button("Close");column.add_child(close);close.pressed.connect(shut)
	backdrop.hide()
	refresh()

func _label(parent: Control, font_size: int) -> Label:
	var label: Label = crane.game.hud.label("",font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label)
	return label

func open() -> String:
	var error: String = crane.console_access_error()
	if not error.is_empty():return error
	is_open = true;selected = 0;feedback.text = "";backdrop.show();layout_key.clear()
	crane.game.hud.target_panel.hide()
	crane.game.desktop_input.push_modal(self)
	crane.game.scripted_controls.clear();crane.game.jump_requested = false
	crane.game.player.velocity.x = 0;crane.game.player.velocity.z = 0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;refresh();_focus()
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
	if is_open and not order.is_empty():
		buttons[order[selected]].grab_focus()
		scroll.ensure_control_visible.call_deferred(buttons[order[selected]])

func _select(action: String) -> void:
	selected = order.find(action)

func _command(action: String) -> void:
	var error: String = crane.request_console(action)
	feedback.text = error if not error.is_empty() else "Command accepted."
	refresh()

func refresh() -> void:
	if not is_instance_valid(status):return
	status.text = crane.status_text()
	load_label.text = crane.config.get("spec",{}).get("title","Upper-leg beam")
	var options: Array[Dictionary] = crane.menu_options()
	var actions: Array[String] = []
	for option in options:actions.append(option.action)
	if actions != order:
		for child in choices.get_children():choices.remove_child(child);child.queue_free()
		buttons.clear();order = actions;selected = mini(selected,maxi(0,order.size()-1))
		for option in options:
			var button: Button = crane.game.hud.button(option.label)
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			choices.add_child(button);buttons[option.action] = button
			button.focus_entered.connect(_select.bind(option.action))
			button.pressed.connect(_command.bind(option.action))
		_focus()
	for action in order:buttons[action].tooltip_text = crane.action_error(action)
	if is_open:
		var key: Array = [backdrop.size,status.text,load_label.text,feedback.text,order.duplicate()]
		if key != layout_key:
			layout_key = key
			if not layout_queued:
				layout_queued = true;_fit_panel.call_deferred()

func _fit_panel() -> void:
	layout_queued = false
	if not is_open:return
	var bounds = backdrop.size
	var width = minf(PANEL_WIDTH,bounds.x-EDGE_MARGIN*2)
	panel.custom_minimum_size.x = width
	# Supply the wrapping width before measuring the fixed header/footer. Only
	# the commands scroll; status, feedback and Close remain accessible.
	for label in [load_label,status,feedback,help]:
		label.custom_minimum_size.x = width-32
		label.size = Vector2(width-32,0)
	feedback.visible = not feedback.text.is_empty()
	scroll.custom_minimum_size.y = 0
	var fixed_height = panel.get_combined_minimum_size().y
	var commands_height = choices.get_combined_minimum_size().y
	scroll.custom_minimum_size.y = minf(commands_height,maxf(42,bounds.y-EDGE_MARGIN*2-fixed_height))
	panel.size = Vector2(width,0);panel.reset_size()
	panel.position = (bounds-panel.size)*.5
	if not order.is_empty():scroll.ensure_control_visible.call_deferred(buttons[order[selected]])

func physics() -> void:
	if not is_open:return
	if crane.game.paused or not crane.console_access_error().is_empty():shut()
	else:refresh()

func _input(event: InputEvent) -> void:
	if is_open and event is InputEventKey and event.physical_keycode in [KEY_UP,KEY_DOWN,KEY_E,KEY_ENTER,KEY_Q,KEY_ESCAPE]:
		handle_input(event)
		get_viewport().set_input_as_handled()
