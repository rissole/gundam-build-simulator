extends CanvasLayer
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var root = ColorRect.new();root.color = Color("111d26");root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(root)
	var center = CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(center)
	var column = VBoxContainer.new();column.custom_minimum_size = Vector2(760,0);column.add_theme_constant_override("separation",20);center.add_child(column)
	var title = Label.new();title.text = "M2 / Hands-on equipment";title.add_theme_font_size_override("font_size",36);column.add_child(title)
	var introduction = Label.new();introduction.text = "Two independent saved examples. Choose a trial to resume, or reset only that trial.";column.add_child(introduction)
	for trial in ["retention","crane"]:
		var description = Label.new();description.text = "Hip retainer — complete leg supplied on its home rail. Dock it, then fit and remove one half." if trial == "retention" else "Crane delivery — completed foot and pre-beam leg supplied. Rig the real beam, deliver and bolt it.";column.add_child(description)
		var row = HBoxContainer.new();column.add_child(row)
		for reset in [false,true]:
			var button = Button.new();button.text = ("Reset " if reset else "Resume / start ")+("Hip retainer" if trial == "retention" else "Crane delivery");button.custom_minimum_size = Vector2(300,52);row.add_child(button)
			button.pressed.connect(func():get_tree().set_meta("m2_trial",trial);get_tree().set_meta("m2_reset",reset);get_tree().reload_current_scene())
