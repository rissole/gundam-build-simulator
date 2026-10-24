extends CanvasLayer
## Local destination picker. Choosing a destination starts the existing route.
var platform: Node3D
var backdrop: Control
var panel: PanelContainer
var status: Label
var hint: Label
var help: Label
var scroll: ScrollContainer
var choices: VBoxContainer
var buttons: Array[Button] = []
var actions: Array[String] = []
var selected = 0
var is_open = false
var hud_was_visible = true
var feedback = ""
var layout_key: Array = []

func setup(controller: Node3D) -> void:
	platform = controller;layer = 40;set_process(false)
	platform.game.ready.connect(_make_panel,CONNECT_ONE_SHOT)

func _make_panel() -> void:
	var hud = platform.game.hud
	backdrop = Control.new();add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	panel = PanelContainer.new();backdrop.add_child(panel)
	panel.add_theme_stylebox_override("panel",hud.style(Color("101b23"),Color("a6bac344"),16))
	var column = VBoxContainer.new();column.add_theme_constant_override("separation",8);panel.add_child(column)
	column.add_child(hud.label("Move platform",20))
	status = hud.label("",15,hud.tone);column.add_child(status)
	scroll = ScrollContainer.new();column.add_child(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	choices = VBoxContainer.new();choices.add_theme_constant_override("separation",6)
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL;scroll.add_child(choices)
	hint = hud.label("",14,hud.muted);hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;column.add_child(hint)
	help = hud.label("↑ ↓ choose · E select · Q close",12,hud.muted);column.add_child(help)
	var close: Button = hud.button("Close");column.add_child(close);close.pressed.connect(shut)
	backdrop.hide()

func open() -> String:
	var error: String = platform.menu_access_error()
	if not error.is_empty():return error
	if not is_instance_valid(panel):return "Platform controls are not ready yet."
	if is_open:return ""
	for child in choices.get_children():choices.remove_child(child);child.queue_free()
	buttons.clear();actions.clear();selected = 0;feedback = ""
	for option in platform.move_options():
		var button: Button = platform.game.hud.button(option.label)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choices.add_child(button);buttons.append(button);actions.append(option.action)
		button.focus_entered.connect(_select.bind(buttons.size()-1))
		button.pressed.connect(_command.bind(option.action))
	is_open = true;backdrop.show();set_process(true);layout_key.clear()
	hud_was_visible = platform.game.hud.visible;platform.game.hud.hide()
	platform.game.desktop_input.push_modal(self)
	platform.game.scripted_controls.clear();platform.game.jump_requested = false
	platform.game.player.velocity.x = 0;platform.game.player.velocity.z = 0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh();_focus()
	return ""

func shut() -> void:
	if not is_open:return
	is_open = false;backdrop.hide();set_process(false)
	platform.game.desktop_input.pop_modal(self);platform.game.hud.visible = hud_was_visible
	if not platform.game.paused:Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _select(index: int) -> void:
	selected = index;feedback = "";refresh()

func _focus() -> void:
	if buttons.is_empty():return
	buttons[selected].grab_focus();scroll.ensure_control_visible.call_deferred(buttons[selected])

func _command(action: String) -> void:
	feedback = platform.menu_access_error()
	if feedback.is_empty():feedback = platform.request(action)
	if feedback.is_empty():shut()
	else:refresh()

func refresh() -> void:
	status.text = "From "+platform.dock_title(platform.from_dock) if platform.mode == "travel" else "At "+platform.dock_title(platform.dock)
	for index in range(actions.size()):
		var error: String = platform.action_error(actions[index])
		buttons[index].tooltip_text = error
		buttons[index].modulate = Color.WHITE if error.is_empty() else Color("8c989e")
	hint.text = "Choose where to go. The platform stops automatically."
	if platform.mode == "travel":hint.text = "Resume the interrupted trip or return to its starting dock."
	if not feedback.is_empty():hint.text = feedback
	elif not buttons.is_empty() and not buttons[selected].tooltip_text.is_empty():hint.text = buttons[selected].tooltip_text
	var key: Array = [backdrop.size,status.text,hint.text]
	if key != layout_key:layout_key = key;_fit.call_deferred()

func _fit() -> void:
	if not is_open:return
	var width = minf(340,backdrop.size.x-32)
	panel.custom_minimum_size.x = width
	for label in [status,hint,help]:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = width-32;label.size = Vector2(width-32,0)
	scroll.custom_minimum_size.y = 0
	var fixed_height = panel.get_combined_minimum_size().y
	scroll.custom_minimum_size.y = minf(choices.get_combined_minimum_size().y,minf(300,maxf(42,backdrop.size.y-32-fixed_height)))
	panel.size = Vector2(width,0);panel.reset_size();panel.position = (backdrop.size-panel.size)*.5

func _process(_delta: float) -> void:
	if platform.game.paused or platform.moving or not platform.menu_access_error().is_empty():shut()
	else:refresh()

func handle_modal_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.physical_keycode:
		KEY_Q:shut()
		KEY_ESCAPE:shut();platform.game.set_paused(true)
		KEY_UP:selected = posmod(selected-1,maxi(1,buttons.size()));_focus()
		KEY_DOWN:selected = posmod(selected+1,maxi(1,buttons.size()));_focus()
		KEY_E,KEY_ENTER:
			var focused = get_viewport().gui_get_focus_owner()
			if focused is Button:focused.pressed.emit()

func _input(event: InputEvent) -> void:
	if is_open and event is InputEventKey and event.physical_keycode in [KEY_UP,KEY_DOWN,KEY_E,KEY_ENTER,KEY_Q,KEY_ESCAPE]:
		handle_modal_input(event);get_viewport().set_input_as_handled()
