extends "res://tests/kit/harness.gd"

func frames(count: int = 3, _physics: bool = false) -> void:
	await super.frames(count,false)
## Suggestions follow physical context and remaining work, without moving the reader.
var game: Node
var output = "res://verification/manual-candidates"

func _initialize() -> void:
	run.call_deferred()

func ids(suggestions: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for suggestion in suggestions:result.append(suggestion.id)
	return result

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":return
	await frames()
	RenderingServer.force_draw(false)
	await process_frame
	root.get_texture().get_image().save_png(output+"/"+name+".png")

func run() -> void:
	if DisplayServer.get_name() != "headless":output += "/run-"+str(int(Time.get_unix_time_from_system()))
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1440,900)
	game = load("res://scenes/workshop.tscn").instantiate()
	root.add_child(game)
	await frames(10)
	game.automated_test = true
	game.set_paused(false)
	game.hud.open_manual("pitch",3)
	game.hud.open_manual("pad_1",1)
	game.hud.open_manual("pad_2",0)
	game.hud.open_manual("pitch")
	game.model.stock_pocket("sleeve")
	game.target = {}
	var pockets: Array = game.model.pockets.duplicate()
	var selected: int = game.model.selected_pocket
	var suggestions: Array[Dictionary] = game.hud.candidate_manuals()
	expect(ids(suggestions) == ["pad_1","pad_2"],"A selected sleeve suggests both compatible physical pads")
	expect(suggestions.all(func(s):return s.pages == [0]),"Suggestions include the remaining installation page, without a summary shopping list")
	game.hud.cycle_candidate(1,suggestions)
	expect(game.hud.manual_id == "pad_1" and game.hud.page == 1,"Explicit candidate cycling restores the first pad's remembered page")
	game.hud.cycle_candidate(1,suggestions)
	expect(game.hud.manual_id == "pad_2" and game.hud.page == 0,"Candidate cycling reaches the second physical pad")
	game.hud.cycle_candidate(-1,suggestions)
	expect(game.hud.manual_id == "pad_1" and game.hud.page == 1,"Reverse cycling preserves separate manual pages")
	game.hud.browser.open_browser()
	game.hud.browser.set_suggested_only(true)
	expect(game.hud.browser.folders.has("pad_1") and game.hud.browser.folders.has("pad_2") and not game.hud.browser.folders.has("pitch"),"Suggested browser narrows compatible builds while preserving receiving breadcrumbs")
	expect(not game.hud.browser.page_items.has("pad_1:1") and game.hud.browser.page_items.has("pad_1:0"),"Suggested browser filters pages by the selected part and unfinished slots")
	await capture("two-compatible-pads")
	game.hud.browser.close_browser()
	game.model.move_assembly("pad_1","station:prep")
	for sid in ["sleeve_3","sleeve_1","sleeve_0","sleeve_2"]:
		var uid: String = game.model.find_item("sleeve","pocket")
		expect(game.model.install("pad_1",sid,uid).ok,"Fit a valid independent sleeve in chosen order: "+sid)
	game.model.select_pocket(game.model.pocket_for("sleeve"))
	game.target = {}
	expect(ids(game.hud.candidate_manuals()) == ["pad_2"],"Fitting the first pad removes it from outstanding sleeve candidates")
	game.target = {"type":"component","owner":"pad_1","sid":"sleeve_0"}
	var focused: Array[Dictionary] = game.hud.candidate_manuals()
	expect(ids(focused) == ["pad_1"],"Aiming identifies the actual prepared build even with an unrelated pocket selected")
	expect(game.hud.manual_id == "pad_1" and game.hud.page == 1,"Progress and aim never jump the current reader")
	game.hud.browser.open_browser()
	expect(game.hud.browser.suggestion_label.text.contains("5 fitted"),"Browser explains how installed pieces identify the aimed build")
	await capture("identified-prepared-pad")
	game.hud.browser.set_suggested_only(false)
	expect(game.hud.browser.folders.size() == game.model.assemblies.size(),"All manuals remains available from a narrowed search")
	game.hud.browser.close_browser()
	var receivers: Array[Dictionary] = game.hud.candidate_manuals({"assembly":"heel_pad","child":"pad_1"})
	expect(ids(receivers) == ["foot"] and receivers[0].pages == [1,2],"Prepared compatible assemblies suggest their receiving manuals and mounting pages")
	# A matching definition is not a physical parent when several receivers exist.
	game.model.assemblies["other_foot"] = game.model.assemblies.foot.duplicate(true)
	expect(game.hud.manual_parent("pad_2").is_empty(),"Several compatible receivers leave an unmounted manual at the root")
	game.model.assemblies.pad_2.parent = "other_foot"
	expect(game.hud.manual_parent("pad_2") == "other_foot","Actual mounted ownership wins over compatible parent inference")
	game.model.assemblies.pad_2.parent = ""
	game.model.assemblies.erase("other_foot")
	expect(game.model.pockets == pockets and game.model.selected_pocket == selected,"Manual filtering and cycling preserve pocket kinds and selection")
	expect(game.hud.pages.pitch == 3 and game.hud.pages.pad_1 == 1 and game.hud.pages.pad_2 == 0,"Every physical manual retains its own remembered page")
	expect(game.model.integrity_errors().is_empty(),"Suggestion browsing and independent placement retain valid physical ownership")
	var passed: bool = checks.all(func(c):return c.passed)
	var hashes: Dictionary = {}
	for path in ["res://scripts/hud.gd","res://scripts/manual_browser.gd","res://scripts/component_interaction.gd","res://scripts/manual_diagram.gd","res://assets/assembly-definitions.json","res://assets/pitch-actuator-definitions.json","res://assets/foot-fa01.glb","res://tests/manual_candidates_test.gd"]:hashes[path] = FileAccess.get_sha256(path)
	write_evidence(output+("/headless-audit.json" if DisplayServer.get_name()=="headless" else "/rendered-audit.json"),{"passed":passed,"checks":checks,"rendered":DisplayServer.get_name()!="headless","engine":Engine.get_version_info(),"input_hashes":hashes})
	print("REVIEW_OUTPUT ",ProjectSettings.globalize_path(output))
	print("MANUAL_CANDIDATES ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
