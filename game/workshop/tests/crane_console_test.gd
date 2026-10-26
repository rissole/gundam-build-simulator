extends "res://tests/kit/harness.gd"
## Isolated production console layout; no workshop or rendered review.
class Crane extends Node3D:
	var game: Dictionary
	var blocked_reason = ""
	var motion = ""
	var station = "park"
	var options: Array[Dictionary] = [{"action":"pickup","label":"Move to Heavy Module Bay"}]
	var status_line := "Parking bay · Up"
	var blocked := ""
	func status_text() -> String:return status_line
	func load_text() -> String:return "Next pickup: Hip assembly"
	func menu_options() -> Array[Dictionary]:return options
	func action_error(_action: String) -> String:return blocked
	func request_console(action: String) -> String:return action_error(action)
	func next_hint() -> String:return ""

func _initialize() -> void:call_deferred("run")

func run() -> void:
	root.size = Vector2i(1440,900)
	var hud = preload("res://scripts/hud.gd").new()
	var crane = Crane.new();crane.game = {"hud":hud};root.add_child(crane)
	var console = preload("res://scripts/service_crane_console.gd").new();crane.add_child(console)
	console.crane = crane;console._make_panel()
	console.is_open = true;console.backdrop.show();console.refresh()
	await frames(8,false)
	expect(console.panel.size.y < 400,"one command has a compact console: "+str(console.panel.size))
	expect(console.scroll.size.y < 80,"one command does not expand its scroll area: "+str(console.scroll.size))
	var compact_height: float = console.panel.size.y
	console.hint.add_theme_font_size_override("font_size",28)
	await frames(8,false)
	expect(console.panel.size.y > compact_height,"console refits when text metrics settle without a content change")
	console.hint.add_theme_font_size_override("font_size",14)
	await frames(8,false)
	expect(absf(console.panel.size.y-compact_height)<2,"console shrinks after text reflows")
	for index in range(12):crane.options.append({"action":"move%d"%index,"label":"Move to destination %d"%index})
	console.refresh();await frames(8,false)
	expect(console.scroll.size.y <= 300 and console.panel.size.y < 900,"long command list is bounded")
	crane.options.resize(1);console.refresh();await frames(8,false)
	expect(absf(console.panel.size.y-compact_height)<2,"console shrinks when only one command remains")
	crane.status_line="Limb Bay · Down\nMagnetic connectors attached: 2/2\nWaiting for the loose washer."
	crane.blocked="Finish retaining the structural shin in the manual (M) before detaching a magnetic connector."
	crane.options.clear();crane.options.append({"action":"up","label":"Raise crane"})
	console.refresh();await frames(2,false)
	expect(console.status.text==crane.status_line and not console.status.text.contains("Connection retention"),"console shows the shared status without a retention count")
	expect(console.hint.text==crane.blocked,"selecting a blocked command explains what to finish")
	console._command("up");await frames(2,false)
	expect(console.feedback.text==crane.blocked and not console.feedback.text.contains("Connection retention"),"trying the blocked command repeats that explanation")
	var passed = checks.all(func(check):return check.passed)
	print("CRANE_CONSOLE ","PASS " if passed else "FAIL ",checks.size()," checks")
	crane.free();hud.free();quit(0 if passed else 1)
