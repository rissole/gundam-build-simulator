extends CanvasLayer
const Diagram = preload("res://scripts/manual_diagram.gd")
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
var toast_label: Label
var toast_panel: PanelContainer
var pause_panel: Control
var pause_card: PanelContainer
var pause_title: Label
var resume_button: Button
var restart_button: Button
var session_label: Label
var crosshair: Label
var action_bar: HBoxContainer
var action_slots: Array[Dictionary] = []
var carry_label: Label
var rotation_hint: PanelContainer
var rotation_label: Label
var manual_id: String = "foot"
var pages: Dictionary = {}
var breadcrumb: Label
var manual_hint: Label
var page: int:
	get:return pages.get(manual_id,0)
	set(value):pages[manual_id] = value
var toast_time: float = 0.0
var entered: bool = false
var confirm_restart: bool = false
var tone = Color("80dfbd")
var muted = Color("a8b9be")

func style(bg: Color = Color("14232cf0"), border: Color = Color("3b5059"), padding: int = 16) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(6)
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

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	if game.single_pad:manual_id = "pad_1"
	_make_manual()
	_make_action_bar()
	target_panel = panel_at(root,Vector2(0.5,0.64),Rect2(-280,0,560,0))
	target_label = label("",16)
	target_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_panel.add_child(target_label)
	crosshair = label("+",23,tone)
	root.add_child(crosshair)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position -= Vector2(7,15)
	toast_panel = panel_at(root,Vector2(0.5,1),Rect2(-340,-196,680,0))
	toast_label = label("",15,tone)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_panel.add_child(toast_label)
	rotation_hint = panel_at(root,Vector2(0,0.5),Rect2(24,-50,290,0))
	var hint_col = VBoxContainer.new()
	hint_col.add_theme_constant_override("separation",8)
	rotation_hint.add_child(hint_col)
	hint_col.add_child(label("INSPECT THE ASSEMBLY",12,tone))
	rotation_label = label("Hold R + move mouse to rotate\nDouble-tap R to reset",15)
	hint_col.add_child(rotation_label)
	rotation_hint.visible = false
	_make_pause()

func _make_manual() -> void:
	manual = panel_at(root,Vector2(1,0),Rect2(-366,24,342,0))
	manual.add_theme_stylebox_override("panel",style(Color("14232c")))
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	manual.add_child(column)
	breadcrumb = label("",12,tone)
	breadcrumb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(breadcrumb)
	page_title = label("",23)
	column.add_child(page_title)
	diagram = Diagram.new()
	diagram.custom_minimum_size = Vector2(290,205)
	column.add_child(diagram)
	page_body = label("",15,Color("d5dfdf"))
	page_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page_body.custom_minimum_size.y = 130
	body_scroll = ScrollContainer.new()
	body_scroll.custom_minimum_size = Vector2(0,250)
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(body_scroll)
	page_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.add_child(page_body)
	page_count = label("",13,tone)
	column.add_child(page_count)
	manual_hint = label("",12,muted)
	column.add_child(manual_hint)

func _make_action_bar() -> void:
	action_bar = HBoxContainer.new()
	root.add_child(action_bar)
	action_bar.anchor_left = 0.5
	action_bar.anchor_right = 0.5
	action_bar.anchor_top = 1
	action_bar.anchor_bottom = 1
	action_bar.offset_left = -398
	action_bar.offset_right = 398
	action_bar.offset_top = -108
	action_bar.offset_bottom = -24
	action_bar.add_theme_constant_override("separation",4)
	action_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(10):
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(76,84)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action_bar.add_child(card)
		var content = Control.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(content)
		var texture = TextureRect.new()
		texture.position = Vector2(13,20)
		texture.size = Vector2(42,42)
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(texture)
		var key_label = label(str((i+1)%10),13,tone)
		key_label.position = Vector2(3,0)
		content.add_child(key_label)
		var count = label("",13)
		count.position = Vector2(27,0)
		count.size.x = 40
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		content.add_child(count)
		var id_label = label("Empty",11,muted)
		id_label.position = Vector2(0,63)
		id_label.size.x = 68
		id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(id_label)
		action_slots.append({"card":card,"model":texture,"count":count,"id":id_label,"kind":""})
	carry_label = label("",13)
	root.add_child(carry_label)
	carry_label.anchor_left = 0.5
	carry_label.anchor_right = 0.5
	carry_label.anchor_top = 1
	carry_label.anchor_bottom = 1
	carry_label.offset_left = -440
	carry_label.offset_right = 440
	carry_label.offset_top = -136
	carry_label.offset_bottom = -112
	carry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carry_label.add_theme_color_override("font_shadow_color",Color("09151e"))
	carry_label.add_theme_constant_override("shadow_offset_y",2)

func button(text: String, primary: bool = false) -> Button:
	var node = Button.new()
	node.text = text
	node.custom_minimum_size.y = 42
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size",15)
	node.add_theme_color_override("font_color",Color("102a29") if primary else Color("e5edee"))
	node.add_theme_color_override("font_hover_color",Color("102a29") if primary else Color("e5edee"))
	node.add_theme_color_override("font_focus_color",Color("102a29") if primary else Color("e5edee"))
	node.add_theme_color_override("font_pressed_color",Color("102a29") if primary else Color("e5edee"))
	node.add_theme_stylebox_override("normal",style(tone if primary else Color("233640"),tone if primary else Color("52636a"),11))
	node.add_theme_stylebox_override("hover",style(Color("abeed5") if primary else Color("334c55"),tone,11))
	node.add_theme_stylebox_override("pressed",style(Color("65bc9f") if primary else Color("12232b"),tone,11))
	node.add_theme_stylebox_override("focus",style(Color(0,0,0,0),Color("eef9e9"),11))
	return node

func _control_group(title: String, rows: Array) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel",style(Color("1b2c35"),Color("31454e"),14))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation",8)
	panel.add_child(col)
	col.add_child(label(title,16,tone))
	for row in rows:
		var line = HBoxContainer.new()
		line.add_theme_constant_override("separation",12)
		col.add_child(line)
		var cap = PanelContainer.new()
		cap.custom_minimum_size.x = 133
		cap.add_theme_stylebox_override("panel",style(Color("102029"),Color("3d525c"),3))
		line.add_child(cap)
		var keys = label(row[0],13,Color("e6eeee"))
		keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.add_child(keys)
		var desc = label(row[1],14)
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(desc)
	return panel

func _make_pause() -> void:
	pause_panel = Control.new()
	root.add_child(pause_panel)
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade = ColorRect.new()
	shade.color = Color(0.025,0.045,0.060,0.91)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(shade)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(center)
	pause_card = PanelContainer.new()
	pause_card.custom_minimum_size.x = 1000
	pause_card.add_theme_stylebox_override("panel",style(Color("14232c"),Color("506570"),26))
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
	heading.add_child(label("Prepare the heel pads and pitch actuator, then secure them to the foot.",15,muted))
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
		["W A S D","Walk"],["Mouse","Look around"],["Hold Shift","Walk faster"],
		["Hold Ctrl","Crouch"],["Mouse wheel","Zoom in / out"]]))
	grid.add_child(_control_group("Parts & pockets",[
		["E","Stock pocket / carry component"],["1 2 3 4 5 6 7 8 9 0","Select pocket"],
		["Q","Set down carried component"],["B","Clear selected pocket anywhere"]]))
	grid.add_child(_control_group("Build & rotate",[
		["Left click","Attach at the preview"],["Hold R + mouse","Rotate the aimed-at station"],
		["R, then R","Reset station rotation"],["Z","Undo in selected manual"]]))
	grid.add_child(_control_group("Manual & menu",[
		["Tab / M","Open / close manual"],["← / →","Previous / next page"],
		["Enter / Backspace","Open child / parent manual"],["C / V","Cycle builds / inspect manual"],["Esc","Pause / resume"]]))
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation",12)
	col.add_child(footer)
	session_label = label("Progress lasts for this session.\nRestarting or quitting clears this build.",13,muted)
	session_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(session_label)
	restart_button = button("Restart build")
	restart_button.pressed.connect(_restart_clicked)
	footer.add_child(restart_button)
	var quit_button = button("Quit")
	quit_button.pressed.connect(func():get_tree().quit())
	footer.add_child(quit_button)

func _restart_clicked() -> void:
	if confirm_restart:
		game.reset_demo()
	else:
		confirm_restart = true
		restart_button.text = "Confirm restart"
		session_label.text = "Restart this build from the beginning?\nResume or press Esc to keep your progress."

func show_pause(value: bool) -> void:
	pause_panel.visible = value
	confirm_restart = false
	restart_button.text = "Restart build"
	session_label.text = "Progress lasts for this session.\nRestarting or quitting clears this build."
	pause_title.text = "Paused" if entered else "Your workshop"
	resume_button.text = "Resume    →" if entered else "Start building    →"
	if value:
		rotation_hint.hide()
		resume_button.grab_focus()
	else:
		entered = true
		resume_button.release_focus()

func set_rotation_hint(visible_now: bool, rotating: bool) -> void:
	rotation_hint.visible = visible_now and not game.paused
	rotation_label.text = "Move mouse to rotate\nRelease R to look around" if rotating else "Hold R + move mouse to rotate\nDouble-tap R to reset"

func refresh() -> void:
	if game == null:return
	for i in range(action_slots.size()):
		var slot = action_slots[i]
		var kind: String = game.model.pockets[i]
		if slot.kind != kind:
			slot.kind = kind
			slot.model.texture = game.storage.picture(kind)
		slot.id.text = "Empty" if kind.is_empty() else game.model.definitions.parts[kind].family
		var count: int = game.model.pocket_size(i)
		slot.count.text = "×%d"%count if count>0 else ""
		var selected: bool = game.model.selected_pocket == i
		slot.card.add_theme_stylebox_override("panel",style(Color("24423eef") if selected else Color("12222bed"),tone if selected else Color("42565f"),4))
	var held: String = game.model.held_item()
	var build: String = game.held_build()
	var carrying: String = "Hands free"
	if not held.is_empty():carrying = "Carrying "+game.components.title(game.model.items[held].kind)+" · Q set down"
	elif not build.is_empty():carrying = "Carrying "+game.build_label(build)+" · Q set down"
	var selected: String = game.selected_kind
	carry_label.text = (game.components.title(selected) if not selected.is_empty() else "Empty pocket")+" · B clear   |   "+carrying
	_refresh_manual()
	game.components.update_service_view()

func manual_title() -> String:
	return "FA-01 · Foot" if manual_id == "foot" else game.build_label(manual_id)

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
	var ids: Array = ["foot"]+game.builds.keys()
	open_manual(ids[(ids.find(manual_id)+1)%ids.size()])

func open_selected_child() -> void:
	if manual_id != "foot":return
	var step: Dictionary = game.components.definition("foot").manual[page]
	var sid: String = step.get("child_slot",game.config.mounts[0].id)
	var child: String = game.model.assemblies.foot.slots[sid]
	if child.is_empty():
		for id in game.builds:
			if game.model.assemblies[id].definition == game.model.slot_definition("foot",sid).assembly and game.builds[id].mount_slot.is_empty():child = id;break
	if not child.is_empty():open_manual(child)

func _refresh_manual() -> void:
	page = clampi(page,0,page_total()-1)
	breadcrumb.text = "FA-01 / FOOT"+(" / "+game.build_label(manual_id).to_upper() if manual_id != "foot" else "")
	manual_hint.text = "← / → pages · PgUp / PgDn scroll\nEnter child · Backspace parent · C builds · Tab close"
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
				var family: String = child.get("part_id",game.model.definitions.parts[child.slots[child.root_slot].accepts].family)
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
		for id in game.builds:
			var view: HeelAssemblyState = game.builds[id]
			var progress = "%d / %d pieces"%[game.model.assemblies[id].slots.size()-game.model.assemblies[id].slots.values().count(""),game.model.assemblies[id].slots.size()]
			if not game.components.is_component_build(id):progress = "%d / 4 sleeves"%view.installed("sleeve")
			lines.append(game.build_label(id)+": "+("secured" if view.complete() else ("seated" if view.pad_location == "foot" else ("prepared" if view.prepared() else progress))))
			if view.complete():secured += 1
		page_body.text = "\n".join(lines)
		page_count.text = "%d / %d builds secured"%[secured,game.builds.size()]
		for mount in game.config.mounts:entries.append({"source":mount.source,"highlight":true,"installed":not a.slots[mount.id].is_empty()})
	else:
		var component_view: bool = step.get("view","") == "components"
		var display_slots: Array = step.slots.duplicate() if manual_id == "foot" or component_view else definition.slots.keys()
		if component_view and definition.has("root_slot"):display_slots.push_front(definition.root_slot)
		for sid in display_slots:
			var d: Dictionary = definition.slots[sid]
			entries.append({"source":d.pose_source,"highlight":step.slots.has(sid),"installed":not a.slots[sid].is_empty(),"faint":sid == definition.get("root_slot","") and component_view})
		if manual_id != "foot" and not a.parent.is_empty():page_body.text += "\n\nInstalled. Fastening and undo belong to the foot manual."
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
