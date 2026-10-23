extends CanvasLayer
const Diagram = preload("res://scripts/manual_diagram.gd")
const ManualBrowser = preload("res://scripts/manual_browser.gd")
var game: Node
var root: Control
var manual: PanelContainer
var page_title: Label
var page_body: Label
var body_scroll: ScrollContainer
var page_count: Label
var diagram: Control
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
var resume_button: Button
var restart_button: Button
var save_button: Button
var reload_button: Button
var quit_button: Button
var session_label: Label
var crosshair: Label
var action_bar: HBoxContainer
var action_slots: Array[Dictionary] = []
var carry_label: Label
var carry_panel: PanelContainer
var set_down_hint: HBoxContainer
var manual_id: String = "foot"
var pages: Dictionary = {}
var breadcrumb: Label
var manual_hint: VBoxContainer
var browser: Control
var browse_button: Button
var page: int:
	get:return pages.get(manual_id,0)
	set(value):pages[manual_id] = value
var toast_time: float = 0.0
var entered: bool = false
var confirm_restart: bool = false
var confirm_reload: bool = false
var discard_offered: bool = false
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
	manual_id = "pad_1" if game.profile.pads == "single" else game.config.parent.id
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
	browser = ManualBrowser.new(self)
	root.add_child(browser)

func _make_manual() -> void:
	manual = panel_at(root,Vector2(1,0),Rect2(-366,24,342,0))
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	manual.add_child(column)
	breadcrumb = label("",12,tone)
	breadcrumb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(breadcrumb)
	browse_button = shortcut_button("Browse manuals","N")
	browse_button.custom_minimum_size.y = 30
	browse_button.pressed.connect(func():browser.open_browser())
	column.add_child(browse_button)
	page_title = label("",21)
	page_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(page_title)
	diagram = Diagram.new()
	diagram.custom_minimum_size = Vector2(290,205)
	column.add_child(diagram)
	page_body = label("",15,Color("e0e7e7"))
	page_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page_body.custom_minimum_size.y = 130
	body_scroll = ScrollContainer.new()
	body_scroll.custom_minimum_size = Vector2(0,250)
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(body_scroll)
	page_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.add_child(page_body)
	page_count = label("",12,tone)
	column.add_child(page_count)
	manual_hint = VBoxContainer.new()
	manual_hint.add_theme_constant_override("separation",4)
	manual_hint.add_child(hint_row(["←","→","~Pages ·","PgUp","PgDn"],"Scroll",11))
	manual_hint.add_child(hint_row(["Enter","~Child ·","Backspace"],"Parent",11))
	manual_hint.add_child(hint_row(["C","~Builds ·","Tab"],"Close",11))
	column.add_child(manual_hint)

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
	target_panel.visible = not game.paused and (not text.is_empty() or not action_label.is_empty())
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
	heading.add_child(label(game.profile.intro,15,muted))
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
		[["Space"],"Jump"],[["~Hold","Ctrl"],"Crouch"],[["~Mouse wheel"],"Zoom in / out"]]))
	grid.add_child(_control_group("Parts & pockets",[
		[["E"],"Stock / carry / operate equipment"],[["1","~–","0"],"Select pocket"],
		[["Q"],"Set down component"],[["B"],"Clear selected pocket"]]))
	grid.add_child(_control_group("Build & rotate",[
		[["LMB"],"Attach at the preview"],[["~Hold","R","~+ mouse"],"Rotate preparation station"],
		[["R","~then","R"],"Reset preparation rotation"],[["Z"],"Undo in selected manual"]]))
	grid.add_child(_control_group("Manual & menu",[
		[["Tab","~/","M","~·","N"],"Manual · browse tree"],[["←","→"],"Previous / next page"],
		[["Enter","~/","Backspace"],"Child / parent manual"],[["C","~/","V"],"Cycle / inspect manual"],[["Esc"],"Pause / resume"]]))
	session_label = label("",13,muted)
	session_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	session_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(session_label)
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation",12)
	col.add_child(footer)
	save_button = button("Save")
	save_button.pressed.connect(_save_clicked)
	footer.add_child(save_button)
	reload_button = button("Reload save")
	reload_button.pressed.connect(_reload_clicked)
	footer.add_child(reload_button)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	restart_button = button("Restart build")
	restart_button.pressed.connect(_restart_clicked)
	footer.add_child(restart_button)
	if game.profile.session.codec == "trial":
		var choose_trial = button("Choose M2 trial")
		footer.add_child(choose_trial)
		choose_trial.pressed.connect(func():
			if game.saves.save_now():
				game.get_tree().remove_meta("m2_trial")
				game.get_tree().reload_current_scene())
	quit_button = button("Quit")
	quit_button.pressed.connect(_quit_clicked)
	footer.add_child(quit_button)
	refresh_save_status()

func _saves_enabled() -> bool:
	return game != null and game.saves != null and game.saves.enabled

func refresh_save_status() -> void:
	if session_label == null:return
	var enabled: bool = _saves_enabled()
	save_button.visible = enabled
	reload_button.visible = enabled
	save_button.disabled = not enabled or (enabled and game.saves.blocked)
	reload_button.disabled = not enabled or (enabled and (not game.saves.has_save or game.saves.blocked))
	restart_button.text = ("Confirm new workshop" if enabled else "Confirm restart") if confirm_restart else ("New workshop" if enabled else "Restart build")
	reload_button.text = "Confirm reload" if confirm_reload else "Reload save"
	quit_button.text = "Quit without saving" if discard_offered else ("Save & quit" if enabled else "Quit")
	resume_button.text = "Resume    →" if entered or (enabled and game.saves.restored) else "Start building    →"
	if confirm_restart or confirm_reload:return
	session_label.text = game.saves.status_text() if is_instance_valid(game.saves) else "Your workshop is starting."

func _clear_save_confirmations() -> void:
	confirm_restart = false
	confirm_reload = false
	discard_offered = false

func _save_clicked() -> void:
	_clear_save_confirmations()
	if _saves_enabled():game.saves.save_now()
	refresh_save_status()

func _reload_clicked() -> void:
	if not _saves_enabled() or not game.saves.has_save or game.saves.blocked:return
	if confirm_reload:
		_clear_save_confirmations()
		game.saves.reload_save()
		refresh_save_status()
	else:
		_clear_save_confirmations()
		confirm_reload = true
		refresh_save_status()
		session_label.text = "Reload the saved workshop? Changes since the last save will be lost.\nResume to keep your current progress."

func _quit_clicked() -> void:
	if _saves_enabled():game.saves.quit_game(discard_offered)
	else:get_tree().quit()

func offer_discard() -> void:
	_clear_save_confirmations()
	discard_offered = true
	refresh_save_status()

func _restart_clicked() -> void:
	if confirm_restart:
		_clear_save_confirmations()
		game.reset_demo()
		refresh_save_status()
	else:
		_clear_save_confirmations()
		confirm_restart = true
		refresh_save_status()
		session_label.text = "Start a new workshop? This replaces your current saved workshop.\nResume to keep your progress." if _saves_enabled() else "Restart this build from the beginning?\nResume to keep your progress."

func show_pause(value: bool) -> void:
	pause_panel.visible = value
	action_bar.visible = not value
	carry_panel.visible = not value and not carry_label.text.is_empty()
	_clear_save_confirmations()
	refresh_save_status()
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
	if not held.is_empty():carrying = "Carrying "+game.components.title(game.model.items[held].kind)
	elif not build.is_empty():carrying = "Carrying "+game.build_label(build)
	if game.hands.payload_holder() != null:carrying = "Holding magnetic end · aim at a marked point and click · Q stow"
	carry_label.text = carrying
	carry_panel.visible = not carrying.is_empty() and not game.paused
	_refresh_manual()
	game.components.update_service_view()

func manual_name(id: String) -> String:
	return "FA-01 · Foot" if id == "foot" else game.build_label(id)

func manual_title() -> String:
	return manual_name(manual_id)

func manual_parent(id: String) -> String:
	var instance: Dictionary = game.model.assemblies[id]
	if not instance.parent.is_empty():return instance.parent
	# Only an unambiguous receiving build supplies a suggested breadcrumb.
	# Physical ownership always wins when several identical parents are present.
	var parents: Array[String] = []
	for candidate in game.model.assemblies:
		if candidate == id:continue
		for spec in game.components.definition(candidate).slots.values():
			if spec.get("assembly","") == instance.definition and not parents.has(candidate):parents.append(candidate)
	if parents.size() == 1:return parents[0]
	return ""

func manual_path(id: String) -> Array[String]:
	var result: Array[String] = []
	while not id.is_empty() and not result.has(id):
		result.push_front(id)
		id = manual_parent(id)
	return result

func handle_manual_browser_input(event: InputEvent) -> bool:
	if browser == null:return false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_N:
			if browser.visible:browser.close_browser()
			elif not game.paused:browser.open_browser()
			return true
		if browser.visible:
			match event.physical_keycode:
				KEY_ESCAPE, KEY_TAB, KEY_M:browser.close_browser()
				KEY_BACKSPACE:browser.navigate_parent()
				KEY_C:cycle_candidate(1,browser.suggestions)
				KEY_LEFT:turn_page(-1);refresh();browser.sync_selection()
				KEY_RIGHT:turn_page(1);refresh();browser.sync_selection()
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

func turn_page(direction: int) -> void:
	page = clampi(page+direction,0,page_total()-1)
	body_scroll.scroll_vertical = 0

func cycle_build() -> void:
	cycle_candidate(1)

func candidate_manuals(context: Dictionary = {}) -> Array[Dictionary]:
	# Capture context once when browsing. Aiming and model changes can update
	# suggestions, but never open a different manual or alter remembered pages.
	if context.is_empty():context = discovery_context()
	var kind: String = context.get("kind","")
	var focused: String = context.get("owner","")
	var child_definition: String = context.get("assembly","")
	var result: Array[Dictionary] = []
	for id in game.model.assemblies:
		if not focused.is_empty() and id != focused:continue
		var a: Dictionary = game.model.assemblies[id]
		var d: Dictionary = game.components.definition(id)
		var matched: Array[int] = []
		var ready: int = 0
		for i in range(d.manual.size()):
			var step: Dictionary = d.manual[i]
			if step.get("view","") in ["overview","prepared"]:continue
			var remaining: bool = false
			for sid in step.slots:
				if not a.slots[sid].is_empty():continue
				var slot: Dictionary = game.model.slot_definition(id,sid)
				if not kind.is_empty() and slot.get("accepts","") != kind:continue
				if not child_definition.is_empty() and slot.get("assembly","") != child_definition:continue
				remaining = true
				if slot.get("requires",[]).all(func(r):return not a.slots[r].is_empty()):ready += 1
			if remaining:matched.append(i)
		# A focused finished build still offers its manual for inspection/undo.
		if matched.is_empty() and (not focused.is_empty() or (kind.is_empty() and child_definition.is_empty())):
			for i in range(d.manual.size()):matched.append(i)
		if matched.is_empty():continue
		result.append({"id":id,"pages":matched,"ready":ready,"filled":a.slots.size()-a.slots.values().count("")})
	return result

func discovery_context() -> Dictionary:
	var result: Dictionary = {}
	var held: String = game.model.held_item()
	var kind: String = game.selected_kind
	if not held.is_empty():kind = game.model.items[held].kind
	if not kind.is_empty():result.kind = kind
	var carried: String = game.held_build()
	if not carried.is_empty():
		if game.model.milestone(carried,"prepared"):
			return {"assembly":game.model.assemblies[carried].definition,"child":carried}
		return {"owner":carried}
	var aimed: Dictionary = game.target
	var owner: String = aimed.get("owner",aimed.get("build",""))
	if aimed.get("type","") == "slot" and game.model.assemblies.has(owner) and not game.model.assemblies[owner].parent.is_empty():
		owner = game.model.assemblies[owner].parent
	if not owner.is_empty() and game.model.assemblies.has(owner):result.owner = owner
	elif aimed.get("type","") == "loose":result.kind = game.model.items[aimed.uid].kind
	elif aimed.get("type","") == "bin":result.kind = aimed.kind
	return result

func candidate_summary(context: Dictionary) -> String:
	if context.has("owner"):
		var id: String = context.owner
		var a: Dictionary = game.model.assemblies[id]
		return "%s · %d fitted"%[manual_name(id),a.slots.size()-a.slots.values().count("")]
	if context.has("child"):return manual_name(context.child)+" · compatible receiving manuals"
	if context.has("kind"):return "Matching "+game.components.title(context.kind)
	return "All available builds · aim at a build or select a component to narrow"

func cycle_candidate(direction: int, suggestions: Array[Dictionary] = []) -> void:
	if suggestions.is_empty():suggestions = candidate_manuals()
	if suggestions.is_empty():return
	var ids: Array[String] = []
	for candidate in suggestions:ids.append(candidate.id)
	var current: int = ids.find(manual_id)
	var next_index: int = posmod(current+direction,ids.size()) if current >= 0 else (0 if direction >= 0 else ids.size()-1)
	open_manual(ids[next_index])
	if browser.visible:browser.sync_selection()

func open_selected_child() -> void:
	var step: Dictionary = game.components.definition(manual_id).manual[page]
	var sid: String = step.get("child_slot","")
	if sid.is_empty():
		for candidate in step.slots:
			if game.model.slot_definition(manual_id,candidate).has("assembly"):sid = candidate;break
	if sid.is_empty():return
	var child: String = game.model.assemblies[manual_id].slots[sid]
	if child.is_empty():
		for id in game.model.assemblies:
			var instance: Dictionary = game.model.assemblies[id]
			if instance.definition == game.model.slot_definition(manual_id,sid).assembly and instance.parent.is_empty():child = id;break
	if not child.is_empty():open_manual(child)

func _refresh_manual() -> void:
	page = clampi(page,0,page_total()-1)
	var path: Array[String] = []
	for id in manual_path(manual_id):path.append(manual_name(id))
	breadcrumb.text = "  ›  ".join(path)
	var entries: Array = []
	var a: Dictionary = game.model.assemblies[manual_id]
	var definition: Dictionary = game.components.definition(manual_id)
	var step: Dictionary = definition.manual[page]
	page_title.text = "%02d / %s"%[page+1,step.title]
	page_body.text = step.body
	if step.get("view","") not in ["overview","prepared"]:
		var quantities: Dictionary = {}
		for sid in step.slots:
			var spec = game.model.slot_definition(manual_id,sid)
			var label: String
			if spec.has("accepts"):label = game.components.title(spec.accepts)
			else:
				var child: Dictionary = game.model.definitions.assemblies[spec.assembly]
				var family: String = child.get("part_id","")
				if family.is_empty() and child.has("root_slot"):
					family = game.model.definitions.parts[child.slots[child.root_slot].accepts].family
				label = child.title if child.title.begins_with(family) else family+" · "+child.title
				label += " (prepared)"
			quantities[label] = quantities.get(label,0)+1
		var lines: Array[String] = []
		for label in quantities:lines.append("%s ×%d"%[label,quantities[label]])
		page_body.text += "\n\nParts for this step\n"+"\n".join(lines)
	var filled = 0
	for sid in step.slots:
		if not a.slots[sid].is_empty():filled += 1
	page_count.text = "%d / %d step components · page %d / %d"%[filled,step.slots.size(),page+1,page_total()]
	if step.get("view","") == "prepared":page_count.text = "%d / %d assembly components · page %d / %d"%[filled,step.slots.size(),page+1,page_total()]
	if step.get("view","") == "overview":
		var lines: Array[String] = [step.body,""]
		var secured = 0
		var children: Array[String] = []
		for id in game.model.assemblies:
			if manual_parent(id) == manual_id:children.append(id)
		for id in children:
			var child: Dictionary = game.model.assemblies[id]
			var progress = "%d / %d pieces"%[child.slots.size()-child.slots.values().count(""),child.slots.size()]
			if child.definition == "heel_pad":progress = "%d / 4 sleeves"%game.builds[id].installed("sleeve")
			var status: String = "seated" if child.parent == manual_id else ("prepared" if game.model.milestone(id,"prepared") else progress)
			var secured_child: bool = false
			if child.parent == manual_id:
				var mount: Dictionary = game.model.slot_definition(manual_id,child.parent_slot)
				var retention: Array = mount.get("secured_by",[])
				if retention.is_empty():
					for sid in definition.slots:
						if sid.begins_with(child.parent_slot+"/"):retention.append(sid)
				secured_child = not retention.is_empty() and retention.all(func(sid):return not a.slots[sid].is_empty())
			if secured_child:secured += 1;status = "secured"
			lines.append(manual_name(id)+": "+status)
		page_body.text = "\n".join(lines)
		page_count.text = "%d / %d builds secured"%[secured,children.size()]
		for sid in step.slots:
			var slot: Dictionary = game.model.slot_definition(manual_id,sid)
			if slot.has("assembly"):entries.append({"source":slot.pose_source,"highlight":true,"installed":not a.slots[sid].is_empty()})
	else:
		var component_view: bool = step.get("view","") == "components"
		var display_slots: Array = step.slots.duplicate() if not definition.has("root_slot") or component_view else definition.slots.keys()
		if component_view and definition.has("root_slot"):display_slots.push_front(definition.root_slot)
		for sid in display_slots:
			var d: Dictionary = definition.slots[sid]
			# Logical children have no manufactured root mesh. Authored views may
			# supply a connection-scale display source; never assume a part here.
			if d.has("assembly") and not d.has("pose_source"):continue
			entries.append({"source":d.pose_source,"highlight":step.slots.has(sid),"installed":not a.slots[sid].is_empty(),"faint":sid == definition.get("root_slot","") and component_view})
		if not a.parent.is_empty():page_body.text += "\n\nInstalled in "+manual_name(a.parent)+". Undo its mounting there before dismantling."
	var context: Array = step.get("context_sources",definition.get("context_sources",[]))
	for uid in context:entries.append({"source":uid,"highlight":false,"installed":true,"faint":true})
	diagram.show_parts(game,entries,step.get("diagram_views",[]))

func toast(text: String, success: bool = false) -> void:
	toast_label.text = text
	toast_label.add_theme_color_override("font_color",tone if success else Color("ffd2a0"))
	toast_time = 5.0

func _process(delta: float) -> void:
	if game.paused:return
	toast_time = maxf(0.0,toast_time-delta)
	toast_panel.visible = toast_time > 0.0
