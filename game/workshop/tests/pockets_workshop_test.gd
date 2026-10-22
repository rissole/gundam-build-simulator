extends "res://tests/demo_test.gd"
var review_dir = ""

func review_labels(name: String) -> void:
	if review_dir.is_empty():return
	game.hud.refresh()
	await frames(3)
	RenderingServer.force_draw(false)
	RenderingServer.force_draw(false)
	game.get_viewport().get_texture().get_image().save_png(review_dir.path_join(name+".png"))

func drawer(kind: String) -> void:
	await aim(game.bins[kind].global_position+Vector3(0,0.13,0.27),1.25)
	expect(game.target.get("kind","")==kind,"Reach labelled storage for "+kind)
	key(KEY_E)

func run(workshop: Node) -> void:
	game = workshop
	rendered = DisplayServer.get_name() != "headless"
	if "--pockets-review" in OS.get_cmdline_user_args():
		if not rendered:
			push_error("Pocket label review requires a real renderer")
			get_tree().quit(2)
			return
		review_dir = "res://verification/part-labels-%s-%s"%[Time.get_datetime_string_from_system().replace(":","-"),Time.get_ticks_usec()]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(review_dir))
		print("LABEL_REVIEW_OUTPUT ",ProjectSettings.globalize_path(review_dir))
	await frames(10)
	game.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	expect(game.hud.action_slots.size()==10 and game.model.pockets.count("")==10,"Ten visible empty pockets on launch")
	var storage_matches = true
	for kind in game.storage.drawer_kinds:storage_matches = storage_matches and game.model.definitions.parts[kind].carry_class == "pocket"
	for kind in game.storage.shelf_kinds:storage_matches = storage_matches and game.model.definitions.parts[kind].carry_class != "pocket"
	expect(storage_matches,"Small parts use drawers; hand-sized components use shelves")
	for family in ["FA-526","FA-527","FA-528","FA-221","FA-222"]:
		var kind: String = game.model.items[family+"__001"].kind
		expect(game.bins.has(kind) and game.bin_labels[kind].text=="2 available","Identical pair has one labelled storage location with two copies: "+family)
	var labels_ok = true
	var heights: Array = []
	var no_small_props = true
	for kind in game.bins:
		var bin: Node3D = game.bins[kind]
		labels_ok = labels_ok and bin.get_node("PartID").text==game.model.definitions.parts[kind].family and bin.get_node("PartImage").texture is ImageTexture
		if not heights.has(bin.position.y):heights.append(bin.position.y)
		if bin.get_meta("drawer"):no_small_props = no_small_props and bin.get_node_or_null("ShelfPart")==null
	expect(labels_ok,"Every drawer and shelf has matching part ID and a cached image")
	expect(heights.size()==2 and heights.max()<1.6,"Storage uses only two low rows")
	expect(no_small_props,"Drawers contain no rendered source-part props")
	expect(game.hud.find_children("*","SubViewport",true,false).size()==1,"Only the manual uses a live 3D viewport; hotbar images are static")
	await drawer("w-12")
	expect(game.model.selected_pocket==0 and game.hud.action_slots[0].kind=="w-12" and game.hud.action_slots[0].count.text=="×20","E fills, focuses and displays the first stack immediately")
	await drawer("h-12040")
	expect(game.model.pocket_count()==36 and game.hud.action_slots[1].count.text=="×16","A second pocket works beyond the former shared limit")
	var contents: Array = game.model.pockets.duplicate()
	game.hud.open_manual("pitch",4)
	key(KEY_RIGHT)
	key(KEY_BACKSPACE)
	key(KEY_C)
	expect(game.model.pockets==contents and game.hud.action_slots[0].kind=="w-12" and game.hud.action_slots[1].kind=="h-12040","Changing manuals and pages never changes the action bar's contents")
	await drawer("fa-527-pitch")
	var ring_pocket: int = game.model.pocket_for("fa-527-pitch")
	expect(game.hud.action_slots[ring_pocket].count.text=="×2","Both retaining rings share one displayed pocket stack")
	game.hud.open_manual("pitch",11)
	await review_labels("shared-rings")
	for family in ["FA-524","FA-529"]:
		for number in ["001","002"]:
			var kind: String = game.model.items[family+"__"+number].kind
			await drawer(kind)
			var index: int = game.model.pocket_for(kind)
			expect(not game.hud.action_slots[index].variant.text.is_empty() and game.hud.action_slots[index].variant.text==game.model.definitions.parts[kind].variant_label,"Pocket distinguishes real variant: "+kind)
			game.hud.open_manual("pitch",3 if family=="FA-524" else 9)
			await review_labels(kind)
	for kind in game.storage.drawer_kinds:
		if game.model.pockets.has(kind):continue
		if not game.model.pockets.has(""):break
		await drawer(kind)
	expect(game.model.pockets.count("")==0,"Ten distinct drawer types occupy ten pockets")
	var codes = [KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8,KEY_9,KEY_0]
	for i in range(10):
		key(codes[i])
		expect(game.model.selected_pocket==i and game.selected_kind==game.model.pockets[i],"Number key selects pocket "+str((i+1)%10))
	var old_kind: String = game.model.pockets[9]
	var old_count: int = game.model.pocket_size(9)
	var bin_count: int = game.model.count_at(old_kind,"bin")
	var new_kind = ""
	for kind in game.storage.drawer_kinds:
		if not game.model.pockets.has(kind):new_kind=kind;break
	await drawer(new_kind)
	expect(game.model.pockets[9]==new_kind and game.model.count_at(old_kind,"bin")==bin_count+old_count,"E replaces selected pocket 0 when full and returns old stack")
	await aim(Vector3(0,1,4))
	key(KEY_B)
	expect(game.model.pockets[9].is_empty() and game.hud.action_slots[9].id.text=="Empty" and game.loose.is_empty(),"B clears a pocket away from storage without world objects")
	key(KEY_2)
	await drawer(old_kind)
	expect(game.model.selected_pocket==9 and game.model.pockets[1]=="h-12040","E uses and focuses an empty slot before replacing selected stock")
	var before: Array = game.model.pockets.duplicate()
	key(KEY_Q)
	expect(game.model.pockets==before and game.loose.is_empty(),"Q cannot spawn pocket-sized physics objects")
	await drawer("fa-510__001")
	expect(game.model.held_item()=="FA-510__001" and game.model.pockets==before,"Shelf pickup carries barrel separately from pockets")
	key(KEY_B)
	expect(game.model.held_item()=="FA-510__001" and game.model.pockets[9].is_empty(),"B clears selected pocket while preserving the carried component")
	key(KEY_Q)
	expect(game.model.held_item().is_empty() and game.loose.has("FA-510__001"),"Q sets down a carried component")
	game.hud.open_manual("pitch",6)
	await frames(3)
	expect(game.hud.page_body.text.contains("FA-523") and game.hud.page_body.text.contains("W-12") and game.hud.page_body.text.contains("H-12040"),"Manual uses the same IDs as storage labels")
	key(KEY_PAGEDOWN)
	await frames(2)
	expect(game.hud.body_scroll.scroll_vertical>0,"Long parts lists can be scrolled with the captured mouse")
	expect(game.get_viewport().get_visible_rect().encloses(game.hud.action_bar.get_global_rect()) and game.get_viewport().get_visible_rect().encloses(game.hud.manual.get_global_rect()),"Ten-slot bar and manual fit the viewport")
	expect(game.model.integrity_errors().is_empty(),"Drawer, pocket and carried-part interactions preserve source identities")
	var passed: bool = checks.all(func(c):return c.passed)
	FileAccess.open("res://verification/pockets-workshop-audit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"rendered":rendered},"  "))
	print("POCKETS_WORKSHOP_AUDIT ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	await finish(passed)
