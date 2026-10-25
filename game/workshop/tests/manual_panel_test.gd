extends "res://tests/kit/harness.gd"
## Current step panel and manual view against a fresh workshop.
func _initialize() -> void:call_deferred("run")

func key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event

func run() -> void:
	var game = await boot_workshop()
	var chapter: String = game.hud.chapter_line.text
	var title: String = game.hud.page_title.text
	var row: Node = game.hud.objective_rows.get_child(0)
	var objective: String = row.get_node("text").text
	var count: String = row.get_node("count").text
	expect(chapter == "LEFT-FOOT HEEL PADS · STEP 1 OF 4" and title == "Prepare heel pad 1" and objective == "Fit 4 × FA-305" and count == "0/4","current step panel shows the first heel-pad objective, got %s | %s | %s | %s"%[chapter,title,objective,count])
	var ready_text: String = game.hud.ready_label.text
	var ready_n := int(ready_text.split(" ")[0]) if game.hud.ready_label.visible and not ready_text.is_empty() else -1
	expect(game.hud.ready_label.visible and ready_text.ends_with("more ready to start") and ready_n >= 2,"footer counts other ready steps, got "+ready_text)
	var tracked: Dictionary = game.manual_progress.tracked()
	game.hud.browser.open_browser()
	var selected: Dictionary = game.hud.browser.selected_step()
	expect(game.hud.browser.visible and game.paused and str(selected.owner) == str(tracked.owner) and int(selected.page) == int(tracked.page),"manual opens paused on the tracked step")
	game.hud.handle_manual_browser_input(key(KEY_DOWN))
	var picked: Dictionary = game.hud.browser.selected_step()
	game.hud.handle_manual_browser_input(key(KEY_ENTER))
	var after: Dictionary = game.manual_progress.tracked()
	expect((str(after.owner) != str(tracked.owner) or int(after.page) != int(tracked.page)) and str(after.owner) == str(picked.owner) and int(after.page) == int(picked.page) and game.hud.page_title.text == str(after.title),"Enter tracks the newly selected step and the panel title follows")
	game.hud.handle_manual_browser_input(key(KEY_ESCAPE))
	expect(not game.hud.browser.visible and not game.paused,"Esc closes the manual and resumes the workshop")
	var shown: bool = game.hud.diagram.visible
	game.handle_desktop_input(key(KEY_V))
	expect(game.hud.diagram.visible != shown,"V toggles the current step diagram")
	var passed: bool = checks.all(func(check):return check.passed)
	print("MANUAL_PANEL ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free()
	quit(0 if passed else 1)
