extends CanvasLayer
const Diagram = preload("res://scripts/manual_diagram.gd")
const ManualBrowser = preload("res://scripts/manual_browser.gd")
const ManualObjectives = preload("res://scripts/manual_objectives.gd")
var game: Node
var root: Control
var manual: PanelContainer
var page_title: Label
var page_body: Label
var body_scroll: ScrollContainer
var chapter_line: Label
var goal_label: Label
var goal_rule: ColorRect
var objective_rows: VBoxContainer
var note_row: HBoxContainer
var note_label: Label
var diagram_rule: ColorRect
var ready_label: Label
var diagram: Control
var _panel_signature: String = ""
var target_label: Label
var target_panel: PanelContainer
var target_action: HBoxContainer
var target_key: PanelContainer
var target_action_label: Label
var target_anchor: Vector2
var target_layout_queued: bool = false
var toast_label: Label
var toast_panel: PanelContainer
var pause_panel: Control
var pause_card: PanelContainer
var pause_title: Label
var pause_intro: Label
var resume_button: Button
var restart_button: Button
var save_button: Button
var save_quit_button: Button
var quit_button: Button
var session_label: Label
var crosshair: Label
var fps_label: Label
var fps_estimate: float = 0.0
var fps_refresh: float = 0.0
var action_bar: HBoxContainer
var action_slots: Array[Dictionary] = []
var rope_label: Label
var carry_label: Label
var carry_panel: PanelContainer
var set_down_hint: HBoxContainer
var manual_id: String = "foot"
var pages: Dictionary = {}
var browser: Control
var page: int:
	get:return pages.get(manual_id,0)
	set(value):pages[manual_id] = value
var toast_time: float = 0.0
var entered: bool = false
var confirm_restart: bool = false
var confirm_quit: bool = false
## Result of the last Save press or refused save, shown until the menu closes.
var save_message: String = ""
var tone = Color("80dfbd")
var muted = Color("a8b9be")

func style(bg: Color = Color("101b2399"), border: Color = Color("a6bac322"), padding: int = 12) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(3)
	s.set_border_width_all(1)
	s.border_color = border
	s.content_margin_left = padding
	s.content_margin_right = padding
	s.content_margin_top = padding
	s.content_margin_bottom = padding
	return s

func label(text: String, font_size: int, color: Color = Color("eef2ed")) -> Label:
	var node = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	node.add_theme_color_override("font_shadow_color",Color("050b10b3"))
	node.add_theme_constant_override("shadow_offset_y",1)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func panel_at(parent: Control, anchor: Vector2, rect: Rect2) -> PanelContainer:
	var panel = PanelContainer.new()
	parent.add_child(panel)
	panel.anchor_left = anchor.x
	panel.anchor_right = anchor.x
	panel.anchor_top = anchor.y
	panel.anchor_bottom = anchor.y
	panel.offset_left = rect.position.x
	panel.offset_top = rect.position.y
	panel.offset_right = rect.end.x
	panel.offset_bottom = rect.end.y
	panel.add_theme_stylebox_override("panel",style())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

func keycap(key: String, font_size: int = 12) -> PanelContainer:
	var cap = PanelContainer.new()
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.custom_minimum_size = Vector2(20,21)
	var surface = style(Color("e4eaeae0"),Color("60767d99"),3)
	surface.border_width_bottom = 2
	surface.content_margin_left = 5
	surface.content_margin_right = 5
	surface.content_margin_top = 1
	surface.content_margin_bottom = 2
	cap.add_theme_stylebox_override("panel",surface)
	var glyph = label(key,font_size,Color("14232c"))
	glyph.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_child(glyph)
	return cap

func hint_row(keys: Array, caption: String, font_size: int = 12) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",4)
	for key in keys:
		# A prefixed token is connective prose, never part of the key icon.
		row.add_child(label(key.substr(1),font_size,muted) if key.begins_with("~") else keycap(key,font_size))
	if not caption.is_empty():
		var description = label(caption,font_size,muted)
		description.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(description)
	return row

func shortcut_button(caption: String, key: String, primary: bool = false) -> Button:
	var node = button("",primary)
	var row = hint_row([key],caption,13)
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(row)
	var content_size = row.get_combined_minimum_size()
	row.position = -content_size*0.5
	row.size = content_size
	node.custom_minimum_size.x = content_size.x+22
	return node

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	manual_id = game.config.parent.id
	_make_manual()
	_make_action_bar()
	target_panel = panel_at(root,Vector2.ZERO,Rect2(0,0,260,0))
	target_panel.add_theme_stylebox_override("panel",style(Color("101b2399"),Color("a6bac322"),10))
	var target_content = VBoxContainer.new()
	target_content.add_theme_constant_override("separation",5)
	target_panel.add_child(target_content)
	target_label = label("",14)
	target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_content.add_child(target_label)
	target_action = HBoxContainer.new()
	target_action.add_theme_constant_override("separation",7)
	target_content.add_child(target_action)
	target_key = keycap("E")
	target_action.add_child(target_key)
	target_action_label = label("",13,tone)
	target_action_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_action.add_child(target_action_label)
	target_panel.hide()
	crosshair = label("+",17,Color("dcebe7a6"))
	root.add_child(crosshair)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position -= Vector2(5,11)
	toast_panel = panel_at(root,Vector2(0.5,1),Rect2(-250,-180,500,0))
	toast_panel.add_theme_stylebox_override("panel",style(Color("101b2399"),Color("a6bac322"),8))
	toast_label = label("",14,tone)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_panel.add_child(toast_label)
	toast_panel.hide()
	_make_pause()
	_make_fps_counter()
	browser = ManualBrowser.new(self)
	root.add_child(browser)
	if game.manual_progress != null:game.manual_progress.updated.connect(_on_progress_updated)

func _make_fps_counter() -> void:
	fps_label = label("— FPS",10,Color.WHITE)
	fps_label.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
	fps_label.add_theme_constant_override("shadow_offset_y",0)
	fps_label.add_theme_color_override("font_outline_color",Color.BLACK)
	fps_label.add_theme_constant_override("outline_size",4)
	fps_label.position = Vector2(4,1)
	fps_label.z_index = 10
	root.add_child(fps_label)

func _make_manual() -> void:
	manual = panel_at(root,Vector2(1,0),Rect2(-366,24,342,0))
	manual.add_theme_stylebox_override("panel",style(Color("101b2399"),Color("a6bac344"),12))
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	manual.add_child(column)
	chapter_line = label("",12,tone)
	chapter_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(chapter_line)
	page_title = label("",20)
	page_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(page_title)
	goal_label = label("",14,muted)
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(goal_label)
	goal_rule = _rule()
	column.add_child(goal_rule)
	objective_rows = VBoxContainer.new()
	objective_rows.add_theme_constant_override("separation",6)
	column.add_child(objective_rows)
	page_body = label("",14,Color("e0e7e7"))
	page_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page_body.custom_minimum_size.x = 300
	page_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll = ScrollContainer.new()
	body_scroll.custom_minimum_size = Vector2(0,0)
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_scroll.add_child(page_body)
	column.add_child(body_scroll)
	body_scroll.hide()
	note_row = HBoxContainer.new()
	note_row.add_theme_constant_override("separation",6)
	note_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var warning = label("⚠",13,Color("e8b46b"))
	warning.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
	note_row.add_child(warning)
	note_label = label("",13,Color("ffd2a0"))
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note_row.add_child(note_label)
	column.add_child(note_row)
	note_row.hide()
	diagram_rule = _rule()
	column.add_child(diagram_rule)
	diagram = Diagram.new()
	diagram.custom_minimum_size = Vector2(300,205)
	diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(diagram)
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation",8)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ready_label = label("",12,muted)
	footer.add_child(ready_label)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(spacer)
	footer.add_child(hint_row(["M"],"Manual",12))
	footer.add_child(hint_row(["Tab"],"Hide panel",12))
	column.add_child(footer)

func _make_action_bar() -> void:
	action_bar = HBoxContainer.new()
	root.add_child(action_bar)
	action_bar.anchor_left = 0.5
	action_bar.anchor_right = 0.5
	action_bar.anchor_top = 1
	action_bar.anchor_bottom = 1
	action_bar.offset_left = -373.5
	action_bar.offset_right = 373.5
	action_bar.offset_top = -90
	action_bar.offset_bottom = -18
	action_bar.add_theme_constant_override("separation",3)
	action_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(10):
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(72,72)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action_bar.add_child(card)
		var content = Control.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(content)
		var texture = TextureRect.new()
		texture.position = Vector2(0,0)
		texture.size = Vector2(66,49)
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(texture)
		var key_icon = keycap(str((i+1)%10),11)
		key_icon.position = Vector2(-1,-1)
		content.add_child(key_icon)
		var count = label("",13)
		count.position = Vector2(33,-1)
		count.size = Vector2(33,19)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		content.add_child(count)
		var id_label = label("Empty",12,muted)
		id_label.position = Vector2(0,49)
		id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(id_label)
		id_label.size = Vector2(66,0)
		var variant_label = label("",11,tone)
		variant_label.position = Vector2(0,50)
		variant_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(variant_label)
		variant_label.size = Vector2(66,0)
		action_slots.append({"card":card,"model":texture,"count":count,"id":id_label,"variant":variant_label,"kind":""})
	rope_label = label("",16,tone)
	root.add_child(rope_label)
	rope_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	rope_label.offset_left = -260
	rope_label.offset_right = 260
	rope_label.offset_top = -190
	rope_label.offset_bottom = -140
	rope_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carry_panel = panel_at(root,Vector2(0.5,1),Rect2(-240,-125,480,0))
	carry_panel.add_theme_stylebox_override("panel",style(Color("101b2380"),Color("a6bac318"),6))
	var carry_row = HBoxContainer.new()
	carry_row.add_theme_constant_override("separation",10)
	carry_panel.add_child(carry_row)
	carry_label = label("",12)
	carry_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	carry_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	carry_label.clip_text = true
	carry_row.add_child(carry_label)
	set_down_hint = hint_row(["Q"],"Set down",11)
	carry_row.add_child(set_down_hint)
	carry_panel.hide()

func present_target(text: String, action_key: String = "", action_label: String = "", screen_point: Vector2 = Vector2(-1,-1), valid: bool = false) -> void:
	target_label.text = text
	target_action_label.text = action_label
	target_panel.visible = not game.paused and not game.desktop_input.modal_active() and (not text.is_empty() or not action_label.is_empty())
	if not target_panel.visible:return
	target_label.visible = not text.is_empty()
	target_action.visible = not action_label.is_empty()
	target_key.visible = not action_key.is_empty()
	target_key.get_child(0).text = action_key
	target_action_label.add_theme_color_override("font_color",tone if valid else Color("e0e7e7"))
	var width: float = 0.0
	for line in text.split("\n"):
		width = maxf(width,target_label.get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x)
	if not action_label.is_empty():
		width = maxf(width,target_action_label.get_theme_font("font").get_string_size(action_label,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x+target_key.get_combined_minimum_size().x+7)
	var content_width = clampf(width,110,240)
	target_label.custom_minimum_size.x = content_width
	target_label.size = Vector2(content_width,0)
	target_action_label.size = Vector2(content_width-target_key.get_combined_minimum_size().x-7,0)
	target_panel.custom_minimum_size.x = content_width+20
	target_panel.size = Vector2(content_width+20,0)
	target_anchor = screen_point
	# Wrapped labels update container minima during layout. Fit after that update
	# so a new, longer prompt never keeps the previous text's height or bounds.
	if not target_layout_queued:
		target_layout_queued = true
		_fit_target.call_deferred()

func _fit_target() -> void:
	target_layout_queued = false
	if not target_panel.visible:return
	target_panel.reset_size()
	var bounds = root.get_rect().size
	var anchor = target_anchor if target_anchor.x >= 0 and target_anchor.y >= 0 else bounds*0.5
	var point = anchor+Vector2(24,18)
	var panel_size = target_panel.get_combined_minimum_size()
	point.y = clampf(point.y,16.0,maxf(16.0,bounds.y-150.0-panel_size.y))
	var right_edge = bounds.x-16.0
	# Keep the object prompt out of the reader, even when the object is near it.
	if manual.visible and manual.get_parent() == root and point.y < manual.get_global_rect().end.y and point.y+panel_size.y > manual.global_position.y:
		right_edge = minf(right_edge,manual.global_position.x-12.0)
	# Labelled equipment keys need their neighbours visible while one is aimed.
	var target_node: Node = game.target.get("node")
	if is_instance_valid(target_node) and target_node.has_meta("control_bank"):
		var bank: Node = target_node.get_meta("control_bank")
		var left = anchor.x;var right = anchor.x
		for face in bank.get_meta("button_faces",[]):
			if not is_instance_valid(face) or face.global_position.distance_to(target_node.global_position)>1.8:continue
			var box: AABB = face.get_aabb()
			for index in range(8):
				var corner: Vector3 = face.global_transform*box.get_endpoint(index)
				if game.camera.is_position_behind(corner):continue
				var projected: Vector2 = game.camera.unproject_position(corner)
				left = minf(left,projected.x);right = maxf(right,projected.x)
		point.x = left-panel_size.x-24
		if point.x<16 and right+24+panel_size.x<=right_edge:point.x = right+24
	if point.x+panel_size.x > right_edge:point.x = anchor.x-panel_size.x-24.0
	point.x = clampf(point.x,16.0,maxf(16.0,right_edge-panel_size.x))
	target_panel.position = point

func button(text: String, primary: bool = false) -> Button:
	var node = Button.new()
	node.text = text
	node.custom_minimum_size.y = 42
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size",15)
	node.add_theme_color_override("font_color",Color("e5edee"))
	node.add_theme_color_override("font_hover_color",Color("e5edee"))
	node.add_theme_color_override("font_focus_color",Color("e5edee"))
	node.add_theme_color_override("font_pressed_color",Color("e5edee"))
	node.add_theme_stylebox_override("normal",style(Color("36564db3") if primary else Color("17283280"),Color("80dfbd80") if primary else Color("a6bac338"),11))
	node.add_theme_stylebox_override("hover",style(Color("365b50cc") if primary else Color("334c55b3"),Color("80dfbd99"),11))
	node.add_theme_stylebox_override("pressed",style(Color("24463ccc") if primary else Color("12232b99"),tone,11))
	node.add_theme_stylebox_override("focus",style(Color(0,0,0,0),Color("eef9e9"),11))
	return node

func _control_group(title: String, rows: Array) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel",style(Color("15242c"),Color("a6bac322"),14))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation",8)
	panel.add_child(col)
	col.add_child(label(title,15,tone))
	for row in rows:
		var line = HBoxContainer.new()
		line.add_theme_constant_override("separation",10)
		col.add_child(line)
		var keys = hint_row(row[0],"",12)
		keys.custom_minimum_size.x = 158
		line.add_child(keys)
		var desc = label(row[1],13)
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(desc)
	return panel

func _make_pause() -> void:
	pause_panel = Control.new()
	root.add_child(pause_panel)
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(center)
	pause_card = PanelContainer.new()
	pause_card.custom_minimum_size.x = 1000
	pause_card.add_theme_stylebox_override("panel",style(Color("101b23"),Color("a6bac344"),24))
	center.add_child(pause_card)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation",18)
	pause_card.add_child(col)
	var header = HBoxContainer.new()
	col.add_child(header)
	var heading = VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	pause_title = label("Your workshop",30)
	heading.add_child(pause_title)
	pause_intro = label(game.INTRO,15,muted)
	pause_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(pause_intro)
	resume_button = button("Start building    →",true)
	resume_button.custom_minimum_size.x = 200
	resume_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	resume_button.pressed.connect(func(): game.set_paused(false))
	header.add_child(resume_button)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",14)
	grid.add_theme_constant_override("v_separation",14)
	col.add_child(grid)
	grid.add_child(_control_group("Move & inspect",[
		[["W","A","S","D"],"Walk"],[["~Mouse"],"Look around"],[["~Hold","Shift"],"Walk faster"],
		[["Space"],"Jump / rope up"],[["~Hold","Ctrl"],"Crouch / rope down"],[["~Mouse wheel"],"Zoom in / out"]]))
	grid.add_child(_control_group("Parts & pockets",[
		[["E"],"Stock / carry / operate equipment"],[["1","~–","0"],"Select pocket"],
		[["Q"],"Unclip rope / set down component"],[["B"],"Clear selected pocket"]]))
	grid.add_child(_control_group("Build & rotate",[
		[["LMB"],"Attach at the preview"],[["~Hold","R","~+ mouse"],"Rotate preparation station"],
		[["R","~then","R"],"Reset preparation rotation"],		[["Z"],"Undo (aimed build, else the current step's)"]]))
	grid.add_child(_control_group("Manual & menu",[
		[["G"],"Rope pull-in lanyard"],[["M","~Manual ·","Tab"],"Hide panel"],[["Esc"],"Pause / resume"]]))
	session_label = label("",13,muted)
	session_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	session_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(session_label)
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation",12)
	col.add_child(footer)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	restart_button = button("Restart build")
	restart_button.pressed.connect(_restart_clicked)
	footer.add_child(restart_button)
	save_button = button("Save")
	save_button.pressed.connect(_save_clicked)
	footer.add_child(save_button)
	save_quit_button = button("Save & quit")
	save_quit_button.pressed.connect(func(): game.save_and_quit())
	footer.add_child(save_quit_button)
	quit_button = button("Quit")
	quit_button.pressed.connect(_quit_clicked)
	footer.add_child(quit_button)
	refresh_session_status()

## Whether this launch keeps the workshop save (never in tests or tools).
func _saving() -> bool:
	var slot = game.get("save")
	return slot != null and slot.enabled()

## Whether Restart deletes the save for a fresh workshop. A --stage launch
## restarts from its stage and keeps the save.
func _restart_is_new_workshop() -> bool:
	return _saving() and String(game.get("start_stage")).is_empty()

## Player launches save from this menu or on closing the window; --stage launches
## restart from their stage.
func refresh_session_status() -> void:
	if session_label == null:return
	var saving: bool = _saving()
	var fresh: bool = _restart_is_new_workshop()
	if confirm_restart:restart_button.text = "Confirm new workshop" if fresh else "Confirm restart"
	else:restart_button.text = "New workshop" if fresh else "Restart build"
	save_button.visible = saving
	save_quit_button.visible = saving
	quit_button.text = ("Confirm quit" if confirm_quit else "Quit without saving") if saving else "Quit"
	resume_button.text = "Resume    →" if entered else "Start building    →"
	if confirm_restart or confirm_quit:return
	var status: String = "Robot workshop · this launch is not saved.\nRestart begins again from this launch's starting point."
	if saving and not fresh:status = "Robot workshop · stage launch: "+("unsaved changes since the stage started or your last save." if game.save.unsaved() else "no build changes since the stage started or your last save.")+" Save overwrites your saved workshop; closing the window saves only if you changed the build. Restart begins again from this stage."
	elif saving:status = "Robot workshop · "+("unsaved changes since your last save." if game.save.unsaved() else "no build changes since your last save.")+" Closing the window saves."
	var notice: String = game.Save.notice if saving else ""
	var lines: Array = [status]
	for line in [save_message,notice,game.stage_notice]:
		if not line.is_empty():lines.append(line)
	session_label.text = "\n".join(lines)

func _save_clicked() -> void:
	var error: String = game.save.save_now()
	confirm_quit = false
	save_message = "Saved, with your position." if error.is_empty() else "Not saved: "+error
	refresh_session_status()

## A refused Save & quit or window close keeps the game paused here with the reason.
func show_save_error(error: String) -> void:
	save_message = "Not saved: "+error+" Quit without saving leaves anyway."
	refresh_session_status()

func _quit_clicked() -> void:
	if not _saving() or confirm_quit or not game.save.unsaved():
		game.get_tree().quit()
		return
	confirm_quit = true
	confirm_restart = false
	refresh_session_status()
	session_label.text = "Quit without saving? Build changes since your last save are lost.\nResume to keep playing."

func _restart_clicked() -> void:
	var fresh: bool = _restart_is_new_workshop()
	if confirm_restart:
		confirm_restart = false
		if fresh:game.new_workshop()
		else:game.reset_demo()
		refresh_session_status()
	else:
		confirm_restart = true
		confirm_quit = false
		refresh_session_status()
		session_label.text = "Start a new workshop? This deletes your saved build.\nResume to keep it." if fresh else "Restart this build from the beginning?\nResume to keep your progress."

func show_pause(value: bool) -> void:
	pause_panel.visible = value
	action_bar.visible = not value
	carry_panel.visible = not value and not carry_label.text.is_empty()
	confirm_restart = false
	confirm_quit = false
	if not value:save_message = ""
	refresh_session_status()
	pause_title.text = "Paused" if entered else "Your workshop"
	if value:
		target_panel.hide()
		toast_panel.hide()
		resume_button.grab_focus()
	else:
		entered = true
		resume_button.release_focus()

func refresh() -> void:
	if game == null:return
	if game.manual_progress != null:_follow_tracked_step()
	for i in range(action_slots.size()):
		var slot = action_slots[i]
		var kind: String = game.model.pockets[i]
		if slot.kind != kind:
			slot.kind = kind
			slot.model.texture = game.storage.picture(kind)
		slot.id.text = "Empty" if kind.is_empty() else game.model.definitions.parts[kind].family
		slot.variant.text = "" if kind.is_empty() else game.model.definitions.parts[kind].get("variant_label","")
		var has_variant: bool = not slot.variant.text.is_empty()
		slot.variant.visible = has_variant
		slot.id.position.y = 33 if has_variant else 49
		slot.model.size = Vector2(66,33 if has_variant else 49)
		var count: int = game.model.pocket_size(i)
		slot.count.text = "×%d"%count if count>0 else ""
		var selected: bool = game.model.selected_pocket == i
		slot.card.add_theme_stylebox_override("panel",style(Color("24423ea6") if selected else Color("101b237a"),Color("80dfbdb3") if selected else Color("a6bac330"),3))
	var held: String = game.model.held_item()
	var build: String = game.held_build()
	var carrying: String = ""
	if not held.is_empty():
		carrying = "Carrying "+game.components.title(game.model.items[held].kind)
	elif not build.is_empty():carrying = "Carrying "+game.build_label(build)
	if game.hands.payload_holder() != null:carrying = "Holding magnetic connector · aim at a marked point and click · Q stow"
	carry_label.text = carrying
	carry_panel.visible = not carrying.is_empty() and not game.paused
	_refresh_step_panel()
	game.components.update_service_view()

func manual_name(id: String) -> String:
	return "FA-01 · Foot" if id == "foot" else game.build_label(id)

func manual_title() -> String:
	return manual_name(manual_id)

func handle_manual_browser_input(event: InputEvent) -> bool:
	if browser == null:return false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M:
			if browser.visible:browser.close_browser()
			elif not game.paused:browser.open_browser()
			return true
		if browser.visible:
			match event.physical_keycode:
				KEY_ESCAPE, KEY_TAB:browser.close_browser()
				KEY_UP:browser.move_selection(-1)
				KEY_DOWN:browser.move_selection(1)
				KEY_ENTER, KEY_KP_ENTER:browser.track_selected()
			return true
	return browser.visible

func page_total() -> int:
	return game.model.definitions.assemblies[game.model.assemblies[manual_id].definition].manual.size()

func open_manual(id: String, at_page: int = -1) -> void:
	if not game.model.assemblies.has(id):return
	manual_id = id
	body_scroll.scroll_vertical = 0
	if at_page >= 0:page = at_page
	page = clampi(page,0,page_total()-1)
	manual.visible = true
	refresh()

func _on_progress_updated() -> void:
	_follow_tracked_step()
	_refresh_step_panel()
	if browser.visible:browser._rebuild_keep_scroll()

func _tracked_step() -> Dictionary:
	if game == null or game.manual_progress == null:return {}
	var step = game.manual_progress.tracked()
	return step if step is Dictionary else {}

func _follow_tracked_step() -> void:
	var step := _tracked_step()
	if step.is_empty():return
	manual_id = str(step.owner)
	page = int(step.page)

func _rule() -> ColorRect:
	var line = ColorRect.new()
	line.color = Color("a6bac333")
	line.custom_minimum_size = Vector2(0,1)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

func _free_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.free()

func _tick_box(state: String) -> Control:
	var holder = CenterContainer.new()
	holder.custom_minimum_size = Vector2(16,16)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box = PanelContainer.new()
	box.custom_minimum_size = Vector2(16,16)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var surface = StyleBoxFlat.new()
	surface.set_corner_radius_all(2)
	surface.set_border_width_all(1)
	if state == "current":
		surface.bg_color = tone
		surface.border_color = tone
	elif state == "done":
		surface.bg_color = Color(0,0,0,0)
		surface.border_color = muted
	else:
		surface.bg_color = Color(0,0,0,0)
		surface.border_color = muted
	box.add_theme_stylebox_override("panel",surface)
	holder.add_child(box)
	if state == "done":
		var mark = label("✓",11,muted)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
		box.add_child(mark)
	elif state == "current":
		var dot_holder = CenterContainer.new()
		dot_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dot_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(dot_holder)
		var dot = PanelContainer.new()
		dot.custom_minimum_size = Vector2(6,6)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dot_style = StyleBoxFlat.new()
		dot_style.bg_color = Color("10241f")
		dot_style.set_corner_radius_all(3)
		dot.add_theme_stylebox_override("panel",dot_style)
		dot_holder.add_child(dot)
	return holder

func diagram_entries(owner: String, page_index: int) -> Array:
	var entries: Array = []
	var views: Array = []
	if game == null or not game.model.assemblies.has(owner):return [entries,views]
	var definition: Dictionary = game.components.definition(owner)
	var manual = definition.get("manual",[])
	if not manual is Array or page_index < 0 or page_index >= manual.size() or not manual[page_index] is Dictionary:return [entries,views]
	var step: Dictionary = manual[page_index]
	var assembly: Dictionary = game.model.assemblies[owner]
	views = step.get("diagram_views",[]) if step.get("diagram_views") is Array else []
	var slots: Array = step.get("slots",[]) if step.get("slots") is Array else []
	if step.get("view","") == "overview":
		for sid in slots:
			if not assembly.slots.has(sid):continue
			var slot: Dictionary = game.model.slot_definition(owner,sid)
			if slot.has("assembly"):entries.append({"source":slot.pose_source,"highlight":true,"installed":not assembly.slots[sid].is_empty()})
	else:
		var component_view: bool = step.get("view","") == "components"
		var display_slots: Array = slots.duplicate() if not definition.has("root_slot") or component_view else definition.slots.keys()
		if component_view and definition.has("root_slot"):display_slots.push_front(definition.root_slot)
		for sid in display_slots:
			if not definition.slots.has(sid) or not assembly.slots.has(sid):continue
			var spec: Dictionary = definition.slots[sid]
			# Logical children have no manufactured root mesh. Authored views may
			# supply a connection-scale display source; never assume a part here.
			if spec.has("assembly") and not spec.has("pose_source"):continue
			entries.append({"source":spec.pose_source,"highlight":slots.has(sid),"installed":not assembly.slots[sid].is_empty(),"faint":sid == definition.get("root_slot","") and component_view})
	var context: Array = step.get("context_sources",definition.get("context_sources",[]))
	if not context is Array:context = []
	for uid in context:entries.append({"source":uid,"highlight":false,"installed":true,"faint":true})
	return [entries,views]

func _step_signature(step: Dictionary) -> String:
	if step.is_empty():return "complete" if game.manual_progress.complete() else "blocked"
	var owner := str(step.owner)
	var page_index := int(step.page)
	var definition: Dictionary = step.definition if step.get("definition") is Dictionary else {}
	var parts: PackedStringArray = []
	parts.append(owner)
	parts.append(str(page_index))
	parts.append(str(step.get("title","")))
	var chapter = step.get("chapter",{})
	parts.append(str(chapter.get("title","")) if chapter is Dictionary else "")
	parts.append(str(step.get("index",0)))
	parts.append(str(step.get("count",0)))
	parts.append(str(definition.get("goal","")))
	parts.append(str(definition.get("body","")))
	var state: Dictionary = game.manual_progress.evaluation(owner,page_index)
	var objectives: Array = definition.get("objectives",[]) if definition.get("objectives") is Array else []
	parts.append(str(objectives.size()))
	for i in objectives.size():
		var objective = objectives[i]
		parts.append(ManualObjectives.text(game,owner,objective) if objective is Dictionary else "")
		var ticked := false
		if state.get("ticked") is Array and i < state.ticked.size():ticked = bool(state.ticked[i])
		var count := ""
		if state.get("counts") is Array and i < state.counts.size():count = str(state.counts[i])
		parts.append("1" if ticked else "0")
		parts.append(count)
		parts.append(str(state.get("current",-1)))
	var note = definition.get("note",null)
	if note is Dictionary:
		parts.append(str(note.get("at",-1)))
		parts.append(str(note.get("text","")))
	parts.append(str(game.manual_progress.ready_count(step)))
	parts.append(str(diagram_entries(owner,page_index)))
	return "|".join(parts)

func _refresh_step_panel() -> void:
	if diagram == null:return
	var step := _tracked_step()
	var show_figure := not step.is_empty()
	diagram.visible = show_figure
	if diagram_rule != null:diagram_rule.visible = show_figure
	var signature := _step_signature(step)
	if signature == _panel_signature:return
	_panel_signature = signature
	_fill_step_panel(step)

func _fill_step_panel(step: Dictionary) -> void:
	_free_children(objective_rows)
	if step.is_empty():
		chapter_line.visible = false
		chapter_line.text = ""
		var complete: bool = game.manual_progress.complete()
		page_title.text = "Robot structure complete" if complete else "Assembly work remains"
		goal_label.visible = not complete
		goal_label.text = "Open the manual (M) to review unfinished steps." if not complete else ""
		goal_rule.visible = false
		objective_rows.visible = false
		body_scroll.visible = false
		note_row.visible = false
		ready_label.visible = false
		return
	var definition: Dictionary = step.definition if step.get("definition") is Dictionary else {}
	var objectives: Array = definition.get("objectives",[]) if definition.get("objectives") is Array else []
	var has_objectives := not objectives.is_empty()
	var chapter = step.get("chapter",{})
	var chapter_title := str(chapter.get("title","")) if chapter is Dictionary else ""
	chapter_line.visible = true
	chapter_line.text = "%s · STEP %d OF %d"%[chapter_title.to_upper(),int(step.get("index",1)),int(step.get("count",1))]
	page_title.text = str(step.get("title",""))
	goal_rule.visible = true
	var goal := str(definition.get("goal","")) if has_objectives else ""
	goal_label.visible = not goal.is_empty()
	goal_label.text = goal
	var owner := str(step.owner)
	var page_index := int(step.page)
	var state: Dictionary = game.manual_progress.evaluation(owner,page_index)
	var current := int(state.get("current",-1))
	if has_objectives:
		objective_rows.visible = true
		body_scroll.visible = false
		for i in ManualObjectives.display_indices(definition,game.manual_progress.procedure(owner,page_index)):
			var objective = objectives[i]
			if not objective is Dictionary:continue
			var ticked := false
			if state.get("ticked") is Array and i < state.ticked.size():ticked = bool(state.ticked[i])
			var count := ""
			if state.get("counts") is Array and i < state.counts.size():count = str(state.counts[i])
			var kind := "done" if ticked else ("current" if i == current else "pending")
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation",8)
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(_tick_box(kind))
			var text := ManualObjectives.text(game,owner,objective)
			var color: Color = muted if ticked else (tone if kind == "current" else Color("e0e7e7"))
			var text_label = label(text,14,color)
			text_label.name = "text"
			text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text_label.custom_minimum_size.x = 160
			text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(text_label)
			row.set_meta("objective_text",text)
			row.set_meta("objective_count",count)
			if not count.is_empty():
				var count_label = label(count,13,tone if kind == "current" else muted)
				count_label.name = "count"
				count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				row.add_child(count_label)
			objective_rows.add_child(row)
	else:
		objective_rows.visible = false
		body_scroll.visible = true
		page_body.text = str(definition.get("body",""))
		var height := page_body.get_combined_minimum_size().y
		body_scroll.custom_minimum_size.y = minf(maxf(height,1.0),260.0)
	var procedure: Dictionary=game.manual_progress.procedure(owner,page_index)
	if procedure.get("repeat",false):
		var link=button(procedure.label)
		link.pressed.connect(func():browser.open_procedure(procedure.step))
		objective_rows.add_child(link)
	var control_note := ManualObjectives.note(definition,current)
	note_row.visible = not control_note.is_empty()
	if note_row.visible:note_label.text = control_note
	var ready: int = game.manual_progress.ready_count(step)
	ready_label.visible = ready > 0
	ready_label.text = "%d more ready to start"%ready
	var packed: Array = diagram_entries(owner,page_index)
	diagram.show_parts(game,packed[0],packed[1])

func toast(text: String, success: bool = false) -> void:
	toast_label.text = text
	toast_label.add_theme_color_override("font_color",tone if success else Color("ffd2a0"))
	toast_time = 5.0

func _process(delta: float) -> void:
	if is_instance_valid(rope_label):
		var rope = game.equipment.get_equipment("rope_access")
		rope_label.text = rope.status_text() if rope!=null else ""
		rope_label.visible = not game.paused and not rope_label.text.is_empty()
	# Frame-time average with a short memory, redrawn ten times a second.
	# Engine.get_frames_per_second() only publishes once per second.
	if delta > 0.0:
		var instant: float = 1.0/delta
		var weight: float = clampf(delta/0.12,0.0,1.0)
		fps_estimate = instant if fps_estimate <= 0.0 else lerpf(fps_estimate,instant,weight)
		fps_refresh += delta
		if fps_refresh >= 0.1:
			fps_refresh = 0.0
			fps_label.text = "%.1f FPS" % fps_estimate
	if game.paused:return
	toast_time = maxf(0.0,toast_time-delta)
	toast_panel.visible = toast_time > 0.0
