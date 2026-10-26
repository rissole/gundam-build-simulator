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
	expect(game.hud.diagram.visible,"the current step diagram is always shown")
	game.hud.handle_manual_browser_input(key(KEY_M))
	expect(game.hud.browser.visible,"M opens the manual")
	game.hud.handle_manual_browser_input(key(KEY_M))
	expect(not game.hud.browser.visible and not game.paused,"M closes the manual again")
	var guidance_objective: Dictionary = game.manual_control_guidance.objective.duplicate(true)
	var guidance_tracked: Dictionary = game.manual_progress.tracked()
	var panel_shown: bool = game.hud.manual.visible
	game.handle_desktop_input(key(KEY_TAB))
	expect(game.hud.manual.visible != panel_shown,"Tab toggles the current step panel")
	expect(game.manual_progress.tracked()==guidance_tracked and game.manual_control_guidance.objective==guidance_objective,"Hiding the panel preserves manual tracking and its physical-control objective")
	game.manual_progress.unpin()
	game.manual_progress._data={"chapters":[{"id":"blocked","title":"Blocked","after":["unfinished"],"steps":[["pelvis",8]]}]}
	game.manual_progress.refresh();game.hud._refresh_step_panel()
	expect(game.hud.page_title.text == "Assembly work remains" and game.hud.goal_label.visible,"blocked tracking explains unfinished work instead of robot completion")
	var passed: bool = checks.all(func(check):return check.passed)
	print("MANUAL_PANEL ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free()
	quit(0 if passed else 1)
