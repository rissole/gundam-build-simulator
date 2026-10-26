extends "res://tests/kit/harness.gd"
## Production desktop adapter + targeting access in a tiny real physics scene.
const EquipmentButton = preload("res://scripts/equipment_button.gd")
class Hud extends RefCounted:
	var messages: Array[String] = []
	var consume = false
	func handle_manual_browser_input(_event):return consume
	func refresh():pass
	func toast(message):messages.append(message)
class Look extends RefCounted:
	var total = Vector2.ZERO
	func look(relative):total += relative
class Controller extends Node:
	var events: Array = []
	var refusal = ""
	func action_error(_action):return refusal
	func held(down, delta, action):events.append([down,delta,action])
class Modal extends RefCounted:
	var count = 0
	func handle_modal_input(_event):count += 1
class Fixture extends Node3D:
	const REACH = 2.0
	const WORLD_MASK = 1
	var started = true
	var paused = false
	var automated_test = true
	var scripted_controls = {}
	var target = {}
	var hud = Hud.new()
	var player_controller = Look.new()
	var rotate_held = false
	var jump_requested = false
	var camera = Camera3D.new()
	var player = CharacterBody3D.new()
	var bodies = {}
	var components = {"held_body":null}
	var targeting: RefCounted
	var taps: Array = []
	func interact(shift):taps.append(shift)
	func _update_target():pass
	func set_paused(value):paused = value
func key(input, down: bool, echo: bool = false, shift: bool = false):
	var event = InputEventKey.new();event.physical_keycode = KEY_E
	event.pressed = down;event.echo = echo;event.shift_pressed = shift;input.handle(event)
func _initialize():call_deferred("run")
func run():
	var game = Fixture.new();root.add_child(game)
	game.add_child(game.camera);game.add_child(game.player)
	game.targeting = preload("res://scripts/targeting.gd").new(game)
	var input = preload("res://scripts/desktop_input.gd").new(game)
	var controller = Controller.new();game.add_child(controller)
	var button = MeshInstance3D.new();game.add_child(button);button.position = Vector3(0,0,-1)
	EquipmentButton.set_hold_handler(button,controller.held.bind("index+"))
	var target = {"type":"equipment","controller":controller,"node":button,"action":"index+","point":button.global_position}
	game.target = target
	key(input,true);input.physics(.02);input.physics(.03)
	expect(controller.events==[[true,.02,"index+"],[true,.03,"index+"]],"one held callback per physics tick with delta")
	expect(game.taps.is_empty(),"holdable press does not invoke tap action")
	game.target = {};game.camera.rotation.y = PI
	var mouse = InputEventMouseMotion.new();mouse.relative = Vector2(20,-8);input.handle(mouse)
	input.physics(.01)
	expect(game.player_controller.total==mouse.relative,"mouselook continues while E is held")
	expect(controller.events.size()==3,"aiming away leaves original button latched")
	key(input,true,true);key(input,true);input.physics(.01)
	expect(controller.events.size()==4,"echo and repeated press cannot replace latch")
	key(input,false);input.physics(.01);key(input,false)
	expect(controller.events.size()==5 and controller.events.back()==[false,0.0,"index+"],"key up releases once with no later held ticks")
	game.camera.rotation = Vector3.ZERO;game.target = target
	key(input,true);input.physics(.01);game.paused = true;input.physics(.01)
	expect(controller.events.back()[0]==false,"programmatic pause releases on next physics tick")
	var count = controller.events.size();game.paused = false;key(input,true,true);input.physics(.01)
	expect(controller.events.size()==count,"unpause while E down cannot relatch")
	key(input,false);key(input,true);input.physics(.01)
	var modal = Modal.new();input.push_modal(modal)
	expect(controller.events.back()[0]==false,"opening a modal releases immediately")
	count = controller.events.size();key(input,false);input.pop_modal(modal);input.physics(.01)
	expect(controller.events.size()==count and modal.count==1,"release consumed by modal still clears key state")
	key(input,true);input.physics(.01)
	expect(controller.events.back()[0]==true,"fresh press after modal can latch")
	game.hud.consume = true;key(input,false);game.hud.consume = false
	expect(controller.events.back()[0]==false,"release survives manual input consumption")
	controller.refusal = "Close the rail gates."
	count = controller.events.size();key(input,true);input.physics(.01);key(input,false)
	expect(controller.events.size()==count and game.hud.messages.back()==controller.refusal,"initial machine refusal prevents latch and is shown")
	controller.refusal = "";game.target = target.duplicate();game.target.point = Vector3(0,0,-3)
	key(input,true);input.physics(.01);key(input,false)
	expect(controller.events.size()==count and game.hud.messages.back().begins_with("Out of reach"),"initial reach check prevents remote latch")
	game.target = target
	var wall = StaticBody3D.new();game.add_child(wall);wall.position = Vector3(0,0,-.5)
	var shape = CollisionShape3D.new();shape.shape = BoxShape3D.new();shape.shape.size = Vector3(.4,.4,.1);wall.add_child(shape)
	await frames(2)
	key(input,true);input.physics(.01);key(input,false)
	expect(controller.events.size()==count and game.hud.messages.back().contains("obstructed"),"real physics sightline prevents latch through a wall")
	wall.free()
	game.target = target.duplicate();game.target.erase("node")
	key(input,true,false,true);key(input,true,true);input.physics(.01);key(input,false)
	expect(game.taps==[true],"ordinary tap still fires once and preserves Shift-E")
	game.target = target;key(input,true);input.physics(.01);button.free();input.physics(.01)
	expect(controller.events.back()[0]==false,"removed button releases its surviving controller safely")
	count = controller.events.size();input.physics(.01)
	expect(controller.events.size()==count,"removed button cannot keep jogging")
	key(input,false)
	var replacement = MeshInstance3D.new();game.add_child(replacement)
	EquipmentButton.set_hold_handler(replacement,controller.held.bind("rise+"))
	game.target = target.duplicate();game.target.node = replacement
	key(input,true);input.physics(.01)
	game.automated_test = false;input.physics(.01)
	expect(controller.events.back()[0]==false,"physical key-up fallback releases even if GUI consumed the event")
	game.automated_test = true;key(input,true);input.physics(.01)
	expect(controller.events.back()[0]==true,"physical release also permits the next fresh press")
	controller.free();input.physics(.01);input.release_control()
	expect(input._held_control.is_empty(),"freed callback receiver cancels without calling a dead object")
	var passed = checks.all(func(c):return c.passed)
	print("HELD_CONTROL ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
