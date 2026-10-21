extends Control
## A navigation overlay that reuses the current reader and its existing diagram viewports.
var hud: CanvasLayer
var card: PanelContainer
var tree: Tree
var reader: VBoxContainer
var crumbs: HBoxContainer
var folders: Dictionary = {}
var page_items: Dictionary = {}
var syncing: bool = false
var return_to_pause: bool = false
var folder_icon: Texture2D
var page_icon: Texture2D
var suggestion_label: Label
var filter_button: CheckButton
var suggestions: Array[Dictionary] = []
var discovery: Dictionary = {}
var suggested_only: bool = true

func _init(owner_hud: CanvasLayer) -> void:
	hud = owner_hud

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade = ColorRect.new()
	shade.color = Color(0.025,0.045,0.060,0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+edge,32)
	add_child(margin)
	card = PanelContainer.new()
	card.add_theme_stylebox_override("panel",hud.style(Color("14232c"),Color("506570"),22))
	margin.add_child(card)
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation",16)
	card.add_child(layout)
	var heading = HBoxContainer.new()
	heading.add_theme_constant_override("separation",20)
	layout.add_child(heading)
	var titles = VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(titles)
	titles.add_child(hud.label("Assembly manuals",27))
	titles.add_child(hud.label("Choose a build or step. Each build remembers your place.",14,hud.muted))
	var close_button = hud.button("Return to workshop   Esc",true)
	close_button.pressed.connect(close_browser)
	heading.add_child(close_button)
	crumbs = HBoxContainer.new()
	crumbs.add_theme_constant_override("separation",8)
	layout.add_child(crumbs)
	var split = HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation",20)
	layout.add_child(split)
	var navigation = VBoxContainer.new()
	navigation.custom_minimum_size.x = 410
	navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.size_flags_stretch_ratio = 0.8
	navigation.add_theme_constant_override("separation",10)
	split.add_child(navigation)
	navigation.add_child(hud.label("FIND A MANUAL",12,hud.tone))
	suggestion_label = hud.label("",13,hud.muted)
	suggestion_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	navigation.add_child(suggestion_label)
	var discovery_controls = HBoxContainer.new()
	discovery_controls.add_theme_constant_override("separation",8)
	navigation.add_child(discovery_controls)
	filter_button = CheckButton.new()
	filter_button.text = "Suggested only"
	filter_button.button_pressed = suggested_only
	filter_button.toggled.connect(set_suggested_only)
	discovery_controls.add_child(filter_button)
	for direction in [-1,1]:
		var cycle_button = hud.button("‹ Build" if direction < 0 else "Build ›")
		cycle_button.custom_minimum_size.y = 32
		cycle_button.pressed.connect(func():hud.cycle_candidate(direction,suggestions))
		discovery_controls.add_child(cycle_button)
	tree = Tree.new()
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.columns = 2
	tree.column_titles_visible = true
	tree.set_column_title(0,"Manual / step")
	tree.set_column_title(1,"Progress")
	tree.set_column_expand(1,false)
	tree.set_column_custom_minimum_width(1,94)
	tree.hide_root = true
	tree.select_mode = Tree.SELECT_ROW
	tree.add_theme_font_size_override("font_size",14)
	tree.add_theme_constant_override("v_separation",9)
	tree.add_theme_constant_override("h_separation",7)
	tree.add_theme_constant_override("item_margin",18)
	tree.add_theme_stylebox_override("panel",hud.style(Color("101e26"),Color("31454e"),10))
	tree.add_theme_stylebox_override("selected",hud.style(Color("294c48"),Color("4b8d7a"),3))
	tree.add_theme_stylebox_override("selected_focus",hud.style(Color("294c48"),hud.tone,3))
	tree.item_selected.connect(_selected)
	navigation.add_child(tree)
	navigation.add_child(hud.label("↑ / ↓ select · ← / → pages · C next suggested build",12,hud.muted))
	reader = VBoxContainer.new()
	reader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reader.size_flags_stretch_ratio = 1.0
	reader.custom_minimum_size.x = 520
	split.add_child(reader)
	folder_icon = _icon('<path d="M2 5h6l2 2h12v13H2z" fill="#80dfbd"/><path d="M2 5h6l2 2H2z" fill="#b4f2d9"/>')
	page_icon = _icon('<path d="M6 2h9l4 4v16H6z" fill="none" stroke="#a8b9be" stroke-width="1.5"/><path d="M14 2v5h5M9 11h7M9 15h7" fill="none" stroke="#a8b9be" stroke-width="1.5"/>')
	hide()

func _input(event: InputEvent) -> void:
	if not visible or hud.game.automated_test:return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_N,KEY_ESCAPE,KEY_TAB,KEY_M,KEY_BACKSPACE,KEY_C,KEY_LEFT,KEY_RIGHT]:
		hud.handle_manual_browser_input(event)
		get_viewport().set_input_as_handled()

func _icon(paths: String) -> Texture2D:
	var image = Image.new()
	image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24">'+paths+'</svg>')
	return ImageTexture.create_from_image(image)

func open_browser() -> void:
	if visible:return
	return_to_pause = hud.game.paused
	hud.game.set_paused(true)
	hud.pause_panel.hide()
	hud.manual.reparent(reader)
	hud.manual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hud.body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hud.body_scroll.custom_minimum_size.y = 100
	hud.body_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.diagram.custom_minimum_size.y = 245
	hud.manual_hint.hide()
	hud.breadcrumb.hide()
	hud.browse_button.hide()
	hud.manual.show()
	show()
	discovery = hud.discovery_context()
	suggestions = hud.candidate_manuals(discovery)
	_refresh_suggestion_label()
	_rebuild_tree()
	select_page(hud.manual_id,hud.page)
	_refresh_crumbs()
	tree.grab_focus()

func close_browser() -> void:
	if not visible:return
	hud.manual.reparent(hud.root)
	hud.manual.anchor_left = 1
	hud.manual.anchor_right = 1
	hud.manual.anchor_top = 0
	hud.manual.anchor_bottom = 0
	hud.manual.offset_left = -366
	hud.manual.offset_right = -24
	hud.manual.offset_top = 24
	hud.manual.offset_bottom = 24
	hud.manual.size_flags_vertical = Control.SIZE_FILL
	hud.body_scroll.size_flags_vertical = Control.SIZE_FILL
	hud.body_scroll.custom_minimum_size.y = 250
	hud.body_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.diagram.custom_minimum_size.y = 205
	hud.manual_hint.show()
	hud.breadcrumb.show()
	hud.browse_button.show()
	hide()
	hud.game.set_paused(return_to_pause)
	# Keep the pause card and this overlay above the compact manual after reparenting.
	hud.root.move_child(hud.pause_panel,-1)
	hud.root.move_child(self,-1)

func _rebuild_tree() -> void:
	syncing = true
	tree.clear()
	folders.clear()
	page_items.clear()
	var root_item = tree.create_item()
	for id in hud.game.model.assemblies:
		if not suggested_only or _suggestion(id) != null:_add_manual(id,root_item)
	syncing = false

func _add_manual(id: String, root_item: TreeItem) -> TreeItem:
	if folders.has(id):return folders[id]
	var parent: String = hud.manual_parent(id)
	var parent_item = root_item if parent.is_empty() else _add_manual(parent,root_item)
	var folder = tree.create_item(parent_item)
	folders[id] = folder
	folder.set_text(0,hud.manual_name(id))
	folder.set_icon(0,folder_icon)
	folder.set_icon_max_width(0,20)
	folder.set_custom_color(0,hud.tone)
	folder.set_metadata(0,{"manual":id,"page":-1})
	folder.set_text(1,_build_status(id))
	folder.set_tooltip_text(0,hud.manual_name(id))
	folder.collapsed = not hud.manual_parent(id).is_empty() and id != hud.manual_id
	var definition: Dictionary = hud.game.components.definition(id)
	var suggestion = _suggestion(id)
	for i in range(definition.manual.size()):
		if suggested_only and (suggestion == null or not suggestion.pages.has(i)):continue
		var step: Dictionary = definition.manual[i]
		var item = tree.create_item(folder)
		item.set_text(0,"%02d  %s"%[i+1,step.title])
		item.set_icon(0,page_icon)
		item.set_icon_max_width(0,17)
		item.set_metadata(0,{"manual":id,"page":i})
		item.set_text(1,_step_status(id,step))
		item.set_tooltip_text(0,step.title)
		page_items[id+":"+str(i)] = item
	return folder

func _build_status(id: String) -> String:
	if hud.game.model.milestone(id,"complete"):return "Secured"
	if hud.game.model.milestone(id,"prepared"):return "Prepared"
	var slots: Dictionary = hud.game.model.assemblies[id].slots
	var filled: int = slots.size()-slots.values().count("")
	return "%d / %d"%[filled,slots.size()]

func _step_status(id: String, step: Dictionary) -> String:
	if step.get("view","") == "overview":return "Overview"
	if step.get("view","") == "prepared":return "Ready" if hud.game.model.milestone(id,"prepared") else "Summary"
	var filled = 0
	for sid in step.slots:
		if not hud.game.model.assemblies[id].slots[sid].is_empty():filled += 1
	return "Done" if filled == step.slots.size() else "%d / %d"%[filled,step.slots.size()]

func select_page(id: String, at_page: int) -> void:
	var item: TreeItem = page_items.get(id+":"+str(at_page))
	if item == null:
		if folders.has(id):select_manual(id)
		return
	var parent = item.get_parent()
	while parent != null:
		parent.collapsed = false
		parent = parent.get_parent()
	item.select(0)
	tree.scroll_to_item(item)

func _selected() -> void:
	if syncing:return
	var item = tree.get_selected()
	if item == null:return
	var data: Dictionary = item.get_metadata(0)
	hud.open_manual(data.manual,data.page)
	_refresh_crumbs()

func _refresh_crumbs() -> void:
	for child in crumbs.get_children():
		crumbs.remove_child(child)
		child.queue_free()
	var path: Array[String] = hud.manual_path(hud.manual_id)
	for i in range(path.size()):
		if i > 0:crumbs.add_child(hud.label("›",20,hud.muted))
		var id = path[i]
		var crumb = hud.button(hud.manual_name(id))
		crumb.custom_minimum_size.y = 34
		crumb.add_theme_font_size_override("font_size",14)
		crumb.pressed.connect(func():select_manual(id))
		crumbs.add_child(crumb)
	crumbs.add_child(hud.label("›  Step %02d"%[hud.page+1],14,hud.muted))

func select_manual(id: String) -> void:
	if not folders.has(id):return
	var item: TreeItem = folders[id]
	var parent = item.get_parent()
	while parent != null:
		parent.collapsed = false
		parent = parent.get_parent()
	item.select(0)
	tree.scroll_to_item(item)

func navigate_parent() -> void:
	var parent: String = hud.manual_parent(hud.manual_id)
	if not parent.is_empty():select_manual(parent)

func sync_selection() -> void:
	if visible:select_page(hud.manual_id,hud.page)

func _suggestion(id: String):
	for suggestion in suggestions:
		if suggestion.id == id:return suggestion
	return null

func _refresh_suggestion_label() -> void:
	var pages = 0
	for suggestion in suggestions:pages += suggestion.pages.size()
	suggestion_label.text = hud.candidate_summary(discovery)+"\n%d matching builds · %d matching steps"%[suggestions.size(),pages]
	if suggestions.is_empty():suggestion_label.text += "\nNo unfinished match. Turn off Suggested only to browse all manuals."

func set_suggested_only(value: bool) -> void:
	suggested_only = value
	if filter_button.button_pressed != value:filter_button.set_pressed_no_signal(value)
	_rebuild_tree()
	select_page(hud.manual_id,hud.page)
	_refresh_crumbs()
