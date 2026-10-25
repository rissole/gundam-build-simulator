extends Control
## Full manual: chapters and steps on the left, the selected step on the right.
const Diagram = preload("res://scripts/manual_diagram.gd")
const Objectives = preload("res://scripts/manual_objectives.gd")
var hud: CanvasLayer
var card: PanelContainer
var chapters_scroll: ScrollContainer
var chapter_list: VBoxContainer
var detail_title: Label
var detail_goal: Label
var detail_heading: Label
var detail_box: VBoxContainer
var note_row: HBoxContainer
var note_label: Label
var track_button: Button
var detail_diagram: Control
var return_to_pause: bool = false
var _expanded: Dictionary = {}
var _visible: Array = []
var _selected: Dictionary = {}
var _selected_panel: Control
var _restore_scroll: int = 0
var _lock_texture: Texture2D
var _italic: Font

func _init(owner_hud: CanvasLayer) -> void:
	hud = owner_hud

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02,0.05,0.08,0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,48)
	add_child(margin)
	card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",hud.style(Color("101b23"),Color("a6bac344"),20))
	margin.add_child(card)
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation",14)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(layout)
	var heading = HBoxContainer.new()
	heading.add_theme_constant_override("separation",12)
	layout.add_child(heading)
	var title = hud.label("Manual",27)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var close_button = hud.shortcut_button("Return to workshop","Esc")
	close_button.pressed.connect(close_browser)
	heading.add_child(close_button)
	var split = HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation",16)
	layout.add_child(split)
	var navigation = VBoxContainer.new()
	navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.size_flags_vertical = Control.SIZE_EXPAND_FILL
	navigation.size_flags_stretch_ratio = 2.0
	navigation.add_theme_constant_override("separation",8)
	split.add_child(navigation)
	navigation.add_child(hud.label("CHAPTERS",12,hud.tone))
	chapters_scroll = ScrollContainer.new()
	chapters_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chapters_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chapters_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	navigation.add_child(chapters_scroll)
	chapter_list = VBoxContainer.new()
	chapter_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chapter_list.add_theme_constant_override("separation",4)
	chapters_scroll.add_child(chapter_list)
	var divider = ColorRect.new()
	divider.color = Color("a6bac333")
	divider.custom_minimum_size = Vector2(1,0)
	divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	split.add_child(divider)
	var detail = VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.size_flags_stretch_ratio = 3.0
	detail.add_theme_constant_override("separation",8)
	split.add_child(detail)
	detail_title = hud.label("",26)
	detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(detail_title)
	detail_goal = hud.label("",15,hud.muted)
	detail_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_italic = SystemFont.new()
	_italic.font_italic = true
	detail_goal.add_theme_font_override("font",_italic)
	detail.add_child(detail_goal)
	detail_heading = hud.label("",12,hud.tone)
	detail.add_child(detail_heading)
	var detail_scroll = ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.custom_minimum_size.y = 80
	detail.add_child(detail_scroll)
	detail_box = VBoxContainer.new()
	detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_box.add_theme_constant_override("separation",4)
	detail_scroll.add_child(detail_box)
	note_row = HBoxContainer.new()
	note_row.add_theme_constant_override("separation",6)
	var warning = hud.label("⚠",14,Color("e8b46b"))
	warning.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
	note_row.add_child(warning)
	note_label = hud.label("",13,Color("ffd2a0"))
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note_row.add_child(note_label)
	detail.add_child(note_row)
	note_row.hide()
	var track_row = HBoxContainer.new()
	var track_spacer = Control.new()
	track_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track_row.add_child(track_spacer)
	track_button = hud.button("Track this step",true)
	track_button.custom_minimum_size = Vector2(168,36)
	track_button.add_theme_stylebox_override("disabled",hud.style(Color("17283280"),Color("a6bac338"),11))
	track_button.add_theme_color_override("font_disabled_color",hud.muted)
	track_button.pressed.connect(track_selected)
	track_row.add_child(track_button)
	detail.add_child(track_row)
	var frame = PanelContainer.new()
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.custom_minimum_size.y = 200
	frame.add_theme_stylebox_override("panel",hud.style(Color("0c161d"),Color("a6bac344"),8))
	detail.add_child(frame)
	detail_diagram = Diagram.new()
	detail_diagram.custom_minimum_size = Vector2(0,180)
	detail_diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(detail_diagram)
	var footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation",18)
	footer.add_child(hud.hint_row(["↑","↓"],"Steps",12))
	footer.add_child(hud.hint_row(["Enter"],"Track",12))
	footer.add_child(hud.hint_row(["Esc"],"Close",12))
	layout.add_child(footer)
	focus_mode = Control.FOCUS_ALL
	hide()

func _input(event: InputEvent) -> void:
	if not visible or hud.game.automated_test:return
	if event is InputEventKey and event.pressed and not event.echo:
		if hud.handle_manual_browser_input(event):get_viewport().set_input_as_handled()

func open_browser() -> void:
	if visible:return
	return_to_pause = hud.game.paused
	hud.game.set_paused(true)
	hud.pause_panel.hide()
	var progress = hud.game.manual_progress
	progress.refresh()
	var step: Dictionary = progress.tracked()
	_expanded.clear()
	if step.is_empty():_selected = {}
	else:
		_expanded[str(step.chapter.id)] = true
		_remember(step)
	_rebuild()
	_show_detail()
	show()
	grab_focus()

func close_browser() -> void:
	if not visible:return
	hide()
	hud.game.set_paused(return_to_pause)
	hud.root.move_child(hud.pause_panel,-1)
	hud.root.move_child(self,-1)

func selected_step() -> Dictionary:
	return {"owner":str(_selected.get("owner","")),"page":int(_selected.get("page",-1)),"reference":bool(_selected.get("reference",false))}

func move_selection(direction: int) -> void:
	if _visible.is_empty():return
	var index := -1
	for i in _visible.size():
		if _same(_visible[i],_selected):
			index = i
			break
	if index < 0:index = 0 if direction >= 0 else _visible.size()-1
	else:index = clampi(index+direction,0,_visible.size()-1)
	_remember(_visible[index])
	_restyle()
	_show_detail()

func track_selected() -> void:
	if _selected.is_empty() or bool(_selected.get("reference",false)):return
	var owner := str(_selected.owner)
	var at := int(_selected.page)
	var state: String = hud.game.manual_progress.status(owner,at)
	if state == "done" or state.is_empty():return
	var current: Dictionary = hud.game.manual_progress.tracked()
	if not current.is_empty() and str(current.owner) == owner and int(current.page) == at:return
	hud.game.manual_progress.pin(owner,at)
	hud.refresh()
	_rebuild()
	_show_detail()

func _remember(row: Dictionary) -> void:
	_selected = {"owner":str(row.get("owner","")),"page":int(row.get("page",-1)),"reference":bool(row.get("reference",false)),"title":str(row.get("title","")),"definition":row.get("definition",{})}

func _same(a: Dictionary, b: Dictionary) -> bool:
	return str(a.get("owner","")) == str(b.get("owner","")) and int(a.get("page",-1)) == int(b.get("page",-2)) and bool(a.get("reference",false)) == bool(b.get("reference",false))

func _is_tracked(row: Dictionary) -> bool:
	if bool(row.get("reference",false)):return false
	var step: Dictionary = hud.game.manual_progress.tracked()
	return not step.is_empty() and str(step.get("owner","")) == str(row.get("owner","")) and int(step.get("page",-1)) == int(row.get("page",-2))

func _rebuild() -> void:
	_visible.clear()
	_selected_panel = null
	for child in chapter_list.get_children():
		chapter_list.remove_child(child)
		child.free()
	var progress = hud.game.manual_progress
	for chapter in progress.chapters():
		if not chapter is Dictionary:continue
		var steps: Array = chapter.get("steps",[]) if chapter.get("steps") is Array else []
		if steps.is_empty():continue
		var id := str(chapter.get("id",""))
		_add_chapter(id,str(chapter.get("title","")),_chapter_pill(chapter),bool(_expanded.get(id,false)))
		if bool(_expanded.get(id,false)):
			for step in steps:_add_step(step,false)
	var reference: Array = progress.reference_steps()
	if not reference.is_empty():
		var open: bool = bool(_expanded.get("reference",false))
		_add_chapter("reference",progress.reference_title(),null,open)
		if open:
			for step in reference:_add_step(step,true)
	_restyle()

func _rebuild_keep_scroll() -> void:
	var scroll := _restore_scroll
	_rebuild()
	chapters_scroll.scroll_vertical = scroll

func _chapter_pill(chapter: Dictionary):
	var progress = hud.game.manual_progress
	var counts: Vector2i = progress.chapter_progress(chapter)
	var steps: Array = chapter.get("steps",[]) if chapter.get("steps") is Array else []
	var first_locked := false
	if not steps.is_empty() and steps[0] is Dictionary:
		first_locked = progress.status(str(steps[0].get("owner","")),int(steps[0].get("page",-1))) == "locked"
	if counts.y > 0 and counts.x == counts.y:return "%d/%d ✓"%[counts.x,counts.y]
	if first_locked and counts.x == 0:return "lock"
	return "%d/%d"%[counts.x,counts.y]

func _add_chapter(id: String, title: String, pill, open: bool) -> void:
	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	row.add_theme_stylebox_override("panel",hud.style(Color("101b2300"),Color("a6bac300"),8))
	var line = HBoxContainer.new()
	line.add_theme_constant_override("separation",8)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	var chevron = hud.label("▾" if open else "▸",14,hud.tone)
	line.add_child(chevron)
	var name = hud.label(title,16)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name)
	if pill != null:line.add_child(_pill(str(pill)))
	row.gui_input.connect(_chapter_clicked.bind(id,row))
	chapter_list.add_child(row)

func _add_step(step: Dictionary, reference: bool) -> void:
	var data := {"owner":str(step.get("owner","")),"page":int(step.get("page",-1)),"reference":reference,"title":str(step.get("title","")),"definition":step.get("definition",{})}
	var line = HBoxContainer.new()
	line.add_theme_constant_override("separation",8)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var indent = Control.new()
	indent.custom_minimum_size = Vector2(14,0)
	indent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(indent)
	var guide = ColorRect.new()
	guide.color = Color("80dfbd55")
	guide.custom_minimum_size = Vector2(2,0)
	guide.size_flags_vertical = Control.SIZE_EXPAND_FILL
	guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(guide)
	var row = PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var content = HBoxContainer.new()
	content.add_theme_constant_override("separation",8)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(content)
	if not reference:
		var state: String = hud.game.manual_progress.status(data.owner,data.page)
		content.add_child(_circle(state))
		var words = VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_child(hud.label(data.title,14))
		words.add_child(hud.label(_status_word(state),12,hud.muted))
		content.add_child(words)
		if _is_tracked(data):
			var here = hud.label("▸ You are here",12,hud.tone)
			here.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			content.add_child(here)
	else:
		var name = hud.label(data.title,14)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(name)
	var index := _visible.size()
	data.panel = row
	_visible.append(data)
	row.gui_input.connect(_step_clicked.bind(index,row))
	line.add_child(row)
	chapter_list.add_child(line)

func _chapter_clicked(event: InputEvent, id: String, row: Control) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):return
	row.accept_event()
	_expanded[id] = not bool(_expanded.get(id,false))
	_restore_scroll = chapters_scroll.scroll_vertical
	call_deferred("_rebuild_keep_scroll")

func _step_clicked(event: InputEvent, index: int, row: Control) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):return
	if index < 0 or index >= _visible.size():return
	_remember(_visible[index])
	_restyle()
	_show_detail()
	row.accept_event()

func _restyle() -> void:
	_selected_panel = null
	for row in _visible:
		var panel: PanelContainer = row.panel
		var tracked := _is_tracked(row)
		var selected := _same(row,_selected)
		panel.add_theme_stylebox_override("panel",_step_style(selected,tracked))
		if selected:_selected_panel = panel
	if _selected_panel != null and is_instance_valid(_selected_panel):chapters_scroll.ensure_control_visible.call_deferred(_selected_panel)

func _step_style(selected: bool, tracked: bool) -> StyleBoxFlat:
	var bg := Color("101b2300")
	var border := Color("a6bac300")
	if selected:bg = Color("1b343c")
	if tracked:bg = Color("14342f") if selected else Color("102824")
	var box: StyleBoxFlat = hud.style(bg,border if not tracked else hud.tone,8)
	if tracked:box.border_width_left = 3
	elif selected:box.border_color = Color("a6bac344")
	return box

func _show_detail() -> void:
	for child in detail_box.get_children():
		detail_box.remove_child(child)
		child.free()
	if _selected.is_empty():
		detail_title.text = ""
		detail_goal.visible = false
		detail_heading.visible = false
		note_row.visible = false
		track_button.visible = false
		return
	var definition: Dictionary = _selected.definition if _selected.get("definition") is Dictionary else {}
	detail_title.text = str(_selected.get("title",""))
	var goal := str(definition.get("goal",""))
	detail_goal.visible = not goal.is_empty()
	detail_goal.text = goal
	var objectives: Array = definition.get("objectives",[]) if definition.get("objectives") is Array else []
	var owner := str(_selected.owner)
	var at := int(_selected.page)
	var state: Dictionary = {} if bool(_selected.get("reference",false)) else hud.game.manual_progress.evaluation(owner,at)
	var current := int(state.get("current",-1))
	if objectives.is_empty():
		detail_heading.visible = false
		var body = hud.label(str(definition.get("body","")),14,Color("e0e7e7"))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size.x = 360
		body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail_box.add_child(body)
	else:
		detail_heading.visible = true
		detail_heading.text = "OBJECTIVES (%d)"%objectives.size()
		for i in objectives.size():
			var objective = objectives[i]
			if not objective is Dictionary:continue
			var ticked := false
			if state.get("ticked") is Array and i < state.ticked.size():ticked = bool(state.ticked[i])
			var kind := "done" if ticked else ("current" if i == current else "ready")
			var word := "Done" if ticked else ("In progress" if i == current else "Pending")
			var row = PanelContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_theme_stylebox_override("panel",hud.style(Color("14342f") if kind == "current" else Color("101b2300"),hud.tone if kind == "current" else Color("a6bac300"),6))
			var line = HBoxContainer.new()
			line.add_theme_constant_override("separation",8)
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(line)
			var number = hud.label("%d."%(i+1),14,hud.muted if ticked else Color("e0e7e7"))
			number.custom_minimum_size.x = 22
			line.add_child(number)
			line.add_child(_circle(kind))
			var text = hud.label(Objectives.text(hud.game,owner,objective),14,hud.muted if ticked else (hud.tone if kind == "current" else Color("e0e7e7")))
			text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text.custom_minimum_size.x = 180
			text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(text)
			var status = hud.label(word,13,hud.tone if kind == "current" else hud.muted)
			line.add_child(status)
			detail_box.add_child(row)
	var note = definition.get("note",null)
	var show_note: bool = note is Dictionary and int(note.get("at",-1)) == current
	note_row.visible = show_note
	if show_note:note_label.text = str(note.get("text",""))
	var reference := bool(_selected.get("reference",false))
	var step_state: String = "" if reference else hud.game.manual_progress.status(owner,at)
	var tracking := _is_tracked(_selected)
	track_button.visible = not reference and step_state != "done" and not step_state.is_empty()
	track_button.disabled = tracking
	track_button.text = "Tracking" if tracking else "Track this step"
	var packed: Array = hud.diagram_entries(owner,at)
	detail_diagram.show_parts(hud.game,packed[0],packed[1])

func _status_word(state: String) -> String:
	match state:
		"done":return "Done"
		"in_progress":return "In progress"
		"ready":return "Ready to start"
		"locked":return "Locked"
		_:return ""

func _pill(text: String) -> Control:
	var pill = PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var locked := text == "lock"
	var surface: StyleBoxFlat = hud.style(Color("14302c") if not locked else Color("1c2c33"),Color("80dfbd66") if not locked else Color("a6bac355"),6)
	surface.set_corner_radius_all(10)
	surface.content_margin_top = 1
	surface.content_margin_bottom = 1
	pill.add_theme_stylebox_override("panel",surface)
	if locked:
		var icon = _lock_icon()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.add_child(icon)
	else:pill.add_child(hud.label(text,12,hud.tone))
	return pill

func _circle(kind: String) -> Control:
	var holder = CenterContainer.new()
	holder.custom_minimum_size = Vector2(18,18)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box = PanelContainer.new()
	box.custom_minimum_size = Vector2(16,16)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var surface = StyleBoxFlat.new()
	surface.set_corner_radius_all(8)
	surface.set_border_width_all(1)
	match kind:
		"done":
			surface.bg_color = hud.muted
			surface.border_color = hud.muted
		"current","in_progress":
			surface.bg_color = Color(0,0,0,0)
			surface.border_color = hud.tone
			surface.set_border_width_all(2)
		"locked":
			surface.bg_color = Color("24343c")
			surface.border_color = hud.muted
		_:
			surface.bg_color = Color(0,0,0,0)
			surface.border_color = hud.muted
	box.add_theme_stylebox_override("panel",surface)
	holder.add_child(box)
	if kind == "done":
		var mark = hud.label("✓",10,Color("14232c"))
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.add_theme_color_override("font_shadow_color",Color.TRANSPARENT)
		box.add_child(mark)
	elif kind == "current" or kind == "in_progress":
		var center = CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(center)
		var dot = PanelContainer.new()
		dot.custom_minimum_size = Vector2(6,6)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dot_style = StyleBoxFlat.new()
		dot_style.bg_color = hud.tone
		dot_style.set_corner_radius_all(3)
		dot.add_theme_stylebox_override("panel",dot_style)
		center.add_child(dot)
	elif kind == "locked":
		var center = CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(center)
		var icon = _lock_icon()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(icon)
	return holder

func _lock_icon() -> TextureRect:
	var rect = TextureRect.new()
	rect.custom_minimum_size = Vector2(12,12)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _lock_texture == null:
		var image = Image.new()
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"><rect x="3.2" y="7.2" width="9.6" height="6.4" rx="1" fill="none" stroke="#a8b9be" stroke-width="1.4"/><path d="M5.4 7.2V5.1a2.6 2.6 0 0 1 5.2 0v2.1" fill="none" stroke="#a8b9be" stroke-width="1.4"/></svg>'
		if image.load_svg_from_string(svg) == OK:_lock_texture = ImageTexture.create_from_image(image)
	if _lock_texture != null:rect.texture = _lock_texture
	return rect
