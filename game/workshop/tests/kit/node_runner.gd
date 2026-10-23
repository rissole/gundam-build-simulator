extends Node
## In-scene adapter for suites that share an already-booted workshop.
const Harness = preload("res://tests/kit/harness.gd")
const PlayerDriver = preload("res://tests/kit/player_driver.gd")
var game: Node
var checks: Array[Dictionary] = []
var rendered: bool = false
var _driver: RefCounted

func expect(ok: bool, label: String) -> void:
	Harness.record(checks,ok,label)

func frames(count: int = 4) -> void:
	await Harness.wait_frames(get_tree(),count)

func write_evidence(path: String, report: Dictionary) -> void:
	Harness.write_evidence(path,report)

func build_state(owner: String) -> HeelAssemblyState:
	return Harness.build_state(game,owner)

func player_driver():
	if _driver == null or _driver.game != game:_driver = PlayerDriver.new(game)
	return _driver

func key(code: Key, shift: bool = false) -> void:
	player_driver().key(code,true,shift)

func release(code: Key) -> void:
	player_driver().key(code,false)

func hold(code: Key, pressed: bool) -> void:
	player_driver().key(code,pressed)

func click(button: MouseButton = MOUSE_BUTTON_LEFT, ctrl: bool = false, pressed: bool = true) -> void:
	player_driver().click(button,ctrl,pressed)

func select_kind(kind: String) -> void:
	player_driver().select_kind(kind)

func aim(point: Vector3, distance: float = 1.35) -> void:
	# This historical suite deliberately stages each connection; walked equipment
	# acceptance suites use PlayerDriver.walk and never call stage_aim.
	await player_driver().stage_aim("isolated connection",point,Vector3(point.x,.025,point.z+distance))

func crouched_click(point: Vector3) -> void:
	hold(KEY_CTRL,true)
	await frames(18)
	await aim(point)
	expect(game.crouched and game.ghost.visible,"Crouched placement has a reachable, visible preview")
	# Godot's macOS backend reports Control + left click as right + Control.
	click(MOUSE_BUTTON_RIGHT if OS.has_feature("macos") else MOUSE_BUTTON_LEFT,true)
	hold(KEY_CTRL,false)
	await frames(18)


func capture(name: String) -> void:
	if not rendered:return
	await get_tree().process_frame
	game.automation.refresh_target()
	game.automation.refresh_presentation()
	game.hud.refresh()
	await frames(4)
	# Fullscreen macOS windows may stop automatic draws when another app is
	# focused. Explicitly render this inspection frame rather than wait forever.
	RenderingServer.force_draw(false)
	game.get_viewport().get_texture().get_image().save_png("res://verification/"+name+".png")


func finish(passed: bool) -> void:
	# Let the audio mixer release the last completion chord before shutdown.
	game.chime.stop()
	game.chime.stream = null
	await frames(4)
	get_tree().quit(0 if passed else 1)
