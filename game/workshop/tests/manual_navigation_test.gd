extends "res://tests/kit/harness.gd"

func frames(count: int = 3, _physics: bool = false) -> void:
	await super.frames(count,false)
## Focused navigation regression: public browser input, physical-build identity,
## remembered pages, inventory isolation and the shared reader viewport.
var game: Node
var output = "res://verification/manual-navigation"

func _initialize() -> void:
	run.call_deferred()

func key(code: Key) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game.handle_desktop_input(event)

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":return
	await frames()
	RenderingServer.force_draw(false)
	await process_frame
	root.get_texture().get_image().save_png(output+"/"+name+".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1440,900)
	game = load("res://scenes/workshop.tscn").instantiate();game.profile_override = "foot"
	root.add_child(game)
	await frames(8)
	game.automated_test = true
	game.set_paused(false)
	game.model.stock_pocket("w-12")
	game.hud.open_manual("pitch",3)
	await frames()
	var viewports: int = game.hud.find_children("*","SubViewport",true,false).size()
	var reader: Control = game.hud.diagram
	var pockets: Array = game.model.pockets.duplicate()
	var selected: int = game.model.selected_pocket
	var slots: Dictionary = game.model.assemblies.duplicate(true)
	key(KEY_N)
	await frames()
	var browser: Control = game.hud.browser
	browser.set_suggested_only(false)
	expect(browser.visible and game.paused and not game.hud.pause_panel.visible,"N opens the manual browser and suspends workshop input")
	expect(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,"Browser releases the pointer for navigation")
	expect(browser.folders.size() == game.model.assemblies.size(),"Tree contains each physical build separately")
	var count = 0
	for id in game.model.assemblies:count += game.components.definition(id).manual.size()
	expect(browser.page_items.size() == count,"Tree exposes every current manual page from recipe data")
	expect(game.hud.manual_path("pitch") == ["foot","pitch"],"Unmounted actuator has its receiving foot as breadcrumb parent")
	expect(browser.folders.pitch.get_parent() == browser.folders.foot,"Child manual is nested beneath its parent")
	expect(game.hud.diagram == reader and game.hud.find_children("*","SubViewport",true,false).size() == viewports,"Large reader reuses the manual's existing 3D viewport")
	key(KEY_B)
	key(KEY_0)
	expect(game.model.pockets == pockets and game.model.selected_pocket == selected,"Browser keys cannot clear or change pockets")
	browser.select_page("pad_1",1)
	browser.select_page("pad_2",0)
	expect(game.hud.manual_id == "pad_2" and game.hud.page == 0,"Tree selects the requested physical pad")
	browser.folders.pad_1.select(0)
	expect(game.hud.manual_id == "pad_1" and game.hud.page == 1,"Selecting a manual folder restores its remembered page")
	browser.folders.pitch.select(0)
	expect(game.hud.manual_id == "pitch" and game.hud.page == 3,"Actuator page survives browsing sibling manuals")
	expect(browser.crumbs.get_child_count() == 4,"Browser header shows clickable parent and child breadcrumbs plus current step")
	await capture("browser-actuator")
	browser.crumbs.get_child(0).pressed.emit()
	expect(game.hud.manual_id == "foot","Parent breadcrumb opens the parent manual")
	browser.select_page("pitch",3)
	key(KEY_BACKSPACE)
	expect(game.hud.manual_id == "foot","Backspace navigates to the manual parent")
	browser.select_page("pitch",3)
	await frames()
	expect(root.get_visible_rect().encloses(browser.card.get_global_rect()) and root.get_visible_rect().encloses(game.hud.manual.get_global_rect()),"Large browser and reader fit the desktop viewport")
	key(KEY_ESCAPE)
	await frames()
	expect(not browser.visible and not game.paused and game.hud.manual.visible,"Escape returns to gameplay with the selected page open")
	expect(game.hud.breadcrumb.text.contains("FA-01") and game.hud.breadcrumb.text.contains("›") and game.hud.breadcrumb.text.contains(game.build_label("pitch").split(" · ")[0]),"Compact manual keeps the parent-to-child breadcrumb")
	expect(root.get_visible_rect().encloses(game.hud.manual.get_global_rect()),"Reader returns to its compact bounds")
	await capture("compact-actuator")
	key(KEY_N)
	await frames()
	expect(browser.visible and game.hud.manual_id == "pitch" and game.hud.page == 3,"Reopening browser preserves the current page")
	key(KEY_N)
	await frames()
	expect(not browser.visible and not game.paused,"N also closes the browser")
	expect(game.model.assemblies == slots and game.model.pockets == pockets and game.model.selected_pocket == selected,"Browsing leaves construction ownership and inventory unchanged")
	expect(game.model.integrity_errors().is_empty(),"Navigation preserves assembly model integrity")
	var passed: bool = checks.all(func(c):return c.passed)
	var hashes = {}
	for path in ["res://scripts/hud.gd","res://scripts/manual_browser.gd","res://tests/manual_navigation_test.gd"]:hashes[path]=FileAccess.get_sha256(path)
	write_evidence(output+("/headless-audit.json" if DisplayServer.get_name()=="headless" else "/rendered-audit.json"),{"passed":passed,"checks":checks,"rendered":DisplayServer.get_name()!="headless","input_hashes":hashes})
	print("MANUAL_NAVIGATION ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
