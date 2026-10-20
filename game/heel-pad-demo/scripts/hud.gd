extends CanvasLayer
const Diagram = preload("res://scripts/manual_diagram.gd")
const SLOT_KINDS = ["sleeve","washer","bolt","pad"]
const SLOT_IDS = ["FA-305","W-24","H-24120","FA-302"]
const SLOT_NAMES = ["Sleeve","Washer","Bolt","Heel pad"]
var game: Node
var root: Control
var manual: PanelContainer
var page_title: Label
var page_body: Label
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
var page: int = 0
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
	toast_panel = panel_at(root,Vector2(0.5,1),Rect2(-340,-234,680,0))
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
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	manual.add_child(column)
	column.add_child(label("FIELD MANUAL   /   FA-302",12,tone))
	page_title = label("",23)
	column.add_child(page_title)
	diagram = Diagram.new()
	diagram.custom_minimum_size = Vector2(290,245)
	column.add_child(diagram)
	page_body = label("",15,Color("d5dfdf"))
	page_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page_body.custom_minimum_size.y = 130
	column.add_child(page_body)
	page_count = label("",13,tone)
	column.add_child(page_count)
	column.add_child(label("← / →  pages     TAB  close",12,muted))

func _make_action_bar() -> void:
	action_bar = HBoxContainer.new()
	root.add_child(action_bar)
	action_bar.anchor_left = 0.5
	action_bar.anchor_right = 0.5
	action_bar.anchor_top = 1
	action_bar.anchor_bottom = 1
	action_bar.offset_left = -238
	action_bar.offset_right = 238
	action_bar.offset_top = -152
	action_bar.offset_bottom = -24
	action_bar.add_theme_constant_override("separation",8)
	action_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(4):
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(113,128)
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		action_bar.add_child(card)
		var content = Control.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(content)
		var texture = TextureRect.new()
		texture.position = Vector2(4,15)
		texture.size = Vector2(97,76)
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture.texture = _model_thumbnail(SLOT_KINDS[i])
		texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(texture)
		var key_label = label(str(i+1),15,tone)
		key_label.position = Vector2(7,2)
		content.add_child(key_label)
		var count = label("0",14)
		count.position = Vector2(64,2)
		count.size.x = 32
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		content.add_child(count)
		var id_label = label(SLOT_IDS[i],14)
		id_label.position = Vector2(0,89)
		id_label.size.x = 105
		id_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(id_label)
		var name_label = label(SLOT_NAMES[i],11,muted)
		name_label.position = Vector2(0,108)
		name_label.size.x = 105
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(name_label)
		action_slots.append({"card":card,"model":texture,"count":count,"id":id_label,"kind":SLOT_KINDS[i]})
	carry_label = label("",13,Color("eef2ed"))
	root.add_child(carry_label)
	carry_label.anchor_left = 0.5
	carry_label.anchor_right = 0.5
	carry_label.anchor_top = 1
	carry_label.anchor_bottom = 1
	carry_label.offset_left = -280
	carry_label.offset_right = 280
	carry_label.offset_top = -181
	carry_label.offset_bottom = -158
	carry_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carry_label.add_theme_color_override("font_shadow_color",Color("09151e"))
	carry_label.add_theme_constant_override("shadow_offset_y",2)

func _model_thumbnail(kind: String) -> Texture2D:
	# Render the actual source mesh once in an isolated world. No icon stand-ins.
	var viewport = SubViewport.new()
	viewport.size = Vector2i(240,192)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var uid: String = game.state.pad_id if kind == "pad" else game.type_sources[kind]
	var mesh = MeshInstance3D.new()
	mesh.mesh = game.source[uid].mesh
	var bounds = mesh.mesh.get_aabb()
	var model_root = Node3D.new()
	viewport.add_child(model_root)
	model_root.add_child(mesh)
	mesh.position = -bounds.get_center()
	var factor = 1.7/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
	model_root.scale = Vector3.ONE*factor
	model_root.rotation_degrees = Vector3(25,-25,-15)
	var environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d5e7ec")
	environment.environment.ambient_light_energy = 0.8
	viewport.add_child(environment)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45,-35,0)
	light.light_energy = 1.7
	viewport.add_child(light)
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(30,145,0)
	fill.light_energy = 0.75
	viewport.add_child(fill)
	var cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.5
	viewport.add_child(cam)
	cam.position = Vector3(0,2.2,3)
	cam.look_at(Vector3.ZERO)
	cam.current = true
	return viewport.get_texture()

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
	heading.add_child(label("Prepare the heel pad, then fit it to the foot. Take your time.",15,muted))
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
		["E","Pick up / take one"],["Shift + E","Take remaining bin stock"],
		["1 · 2 · 3 · 4","Select action-bar slot"],["Q","Put down selected piece"],["B","Return piece to its bin"]]))
	grid.add_child(_control_group("Build & rotate",[
		["Left click","Attach at the preview"],["Hold R + mouse","Rotate the aimed-at station"],
		["R, then R","Reset station rotation"],["Z","Undo last build action"]]))
	grid.add_child(_control_group("Manual & menu",[
		["Tab / M","Open / close manual"],["← / →","Previous / next page"],
		["Esc","Pause / resume"],["4","Select hands / carried pad"]]))
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
	var s: HeelAssemblyState = game.state
	for slot in action_slots:
		var count: int = (1 if s.pad_location == "held" else 0) if slot.kind == "pad" else s.count_at(slot.kind,"pocket")
		var selected: bool = game.selected_kind == slot.kind
		slot.card.add_theme_stylebox_override("panel",style(Color("24423eef") if selected else Color("12222bed"),tone if selected else Color("42565f"),4))
		slot.model.modulate = Color.WHITE if count>0 else Color(0.65,0.7,0.72,0.65)
		slot.count.text = ("2H" if count>0 else "—") if slot.kind == "pad" else "×%d" % count
	carry_label.text = "Pockets %d / 20   ·   %s" % [s.pocket_count(),"Both hands occupied" if s.pad_location == "held" else "Hands free"]
	var titles = ["01 / Prepare", "02 / Bring together", "03 / Secure"]
	var bodies = ["FA-302  Heel pad ×1\nFA-305  Compression sleeve ×4\n\nCarry the pad to the small station. Fit one sleeve at each opening. Any order works.","Prepared FA-302 pad ×1\nReceiving part: FA-300 sole carrier\n\nUse E to lift the pad. Select hands [4], approach the foot's open heel position, then click to seat it.","W-24  Washer ×4\nH-24120  Mounting bolt ×4\n\nAt each point, fit its washer before its bolt. Finish the points in any order. Click once per piece."]
	page_title.text = titles[page]
	page_body.text = bodies[page]
	page_count.text = ["Sleeves fitted: %d / 4" % s.installed("sleeve"),"Pad mounted" if s.pad_location == "foot" else "Prepare → carry → mount", "Mounts complete: %d / 4" % s.installed("bolt")][page]
	if s.complete():page_count.text = "Complete · 13 / 13 components fitted"
	diagram.step = page
	diagram.state = s
	diagram.queue_redraw()

func toast(text: String, success: bool = false) -> void:
	toast_label.text = text
	toast_label.add_theme_color_override("font_color",tone if success else Color("ffd2a0"))
	toast_time = 5.0

func _process(delta: float) -> void:
	if game.paused:return
	toast_time = maxf(0.0,toast_time-delta)
	toast_panel.visible = toast_time > 0.0
