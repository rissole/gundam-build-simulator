extends "res://tests/kit/harness.gd"
## Exercise Space through the desktop adapter and real character collisions.
var game: Node
var driver: Node

func _initialize() -> void:
	run.call_deferred()

func settle_at(feet: Vector3) -> void:
	driver.release(KEY_SPACE)
	driver.release(KEY_CTRL)
	driver.release(KEY_W)
	game.player.global_position = feet
	game.player.rotation = Vector3.ZERO
	game.player.velocity = Vector3.ZERO
	await driver.frames(15)

func observe_jump(frames: int = 90) -> float:
	var highest: float = game.player.global_position.y
	for tick in frames:
		await driver.frames(1)
		highest = maxf(highest,game.player.global_position.y)
	return highest

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate()
	root.add_child(game)
	driver = load("res://tests/kit/node_runner.gd").new()
	root.add_child(driver)
	driver.game = game
	game.automated_test = true
	game.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await settle_at(Vector3(0,0.025,6.4))
	var floor_y: float = game.player.global_position.y
	expect(game.player.is_on_floor(),"Character starts grounded on the workshop floor")
	driver.key(KEY_SPACE)
	await driver.frames(5)
	expect(game.player.global_position.y > floor_y+0.2 and game.player.velocity.y > 0,"Space lifts the grounded character")
	# A release/repress in flight must not add another upward impulse.
	driver.release(KEY_SPACE)
	var rising_speed: float = game.player.velocity.y
	driver.key(KEY_SPACE)
	await driver.frames(3)
	expect(game.player.velocity.y < rising_speed,"A fresh airborne Space press cannot double jump")
	var peak: float = await observe_jump()
	expect(peak > floor_y+0.8 and peak < floor_y+1.1,"Jump reaches a comfortable bounded height")
	expect(game.player.is_on_floor() and absf(game.player.global_position.y-floor_y)<0.02,"Character lands back on the solid floor")
	var held_peak: float = await observe_jump(65)
	expect(held_peak < floor_y+0.02,"Holding Space through landing does not trigger another jump")
	driver.release(KEY_SPACE)
	driver.key(KEY_SPACE)
	await driver.frames(4)
	expect(game.player.velocity.y > 0,"Releasing Space rearms the next grounded jump")
	await observe_jump()
	# Queued requests must not survive a pause entered before the physics tick.
	driver.release(KEY_SPACE)
	driver.key(KEY_SPACE)
	game.set_paused(true)
	await driver.frames(4)
	game.set_paused(false)
	expect(await observe_jump(8) < floor_y+0.02,"Pausing discards an unconsumed jump request")
	game.set_paused(true)
	driver.release(KEY_SPACE)
	driver.key(KEY_SPACE)
	game.set_paused(false)
	expect(await observe_jump(8) < floor_y+0.02,"Space pressed in the pause menu cannot jump after resume")
	# Browser input consumes press and release, but cannot leave Space latched.
	game.hud.browser.open_browser()
	driver.release(KEY_SPACE)
	driver.key(KEY_SPACE)
	driver.release(KEY_SPACE)
	game.hud.browser.close_browser()
	expect(await observe_jump(8) < floor_y+0.02,"Space in the manual browser does not queue a jump")
	driver.key(KEY_SPACE)
	await driver.frames(4)
	expect(game.player.velocity.y > 0,"A Space release inside the browser rearms jumping")
	await observe_jump()
	# Live desktop events are ignored while the scripted driver owns input.
	driver.release(KEY_SPACE)
	var live_press = InputEventKey.new()
	live_press.physical_keycode = KEY_SPACE
	live_press.pressed = true
	game.get_viewport().push_input(live_press,true)
	expect(await observe_jump(8) < floor_y+0.02,"Automated input remains isolated from live Space events")
	# Hop sideways onto the actual access platform's 0.55 m deck.
	await settle_at(Vector3(3.22,0.025,-0.4))
	driver.key(KEY_SPACE)
	await driver.frames(10)
	driver.hold(KEY_D,true)
	await driver.frames(21)
	driver.hold(KEY_D,false)
	await driver.frames(50)
	expect(game.player.is_on_floor() and game.player.global_position.y>0.53 and game.player.global_position.y<0.60,"Jump and ordinary walking land on the actual raised access deck")
	var deck_y: float = game.player.global_position.y
	driver.release(KEY_SPACE)
	driver.key(KEY_SPACE)
	expect(await observe_jump() > deck_y+0.8 and game.player.is_on_floor(),"The access deck supports takeoff and a second solid landing")
	# A temporary low ceiling exercises capsule collision and crouch clearance.
	await settle_at(Vector3(0,0.025,6.4))
	driver.hold(KEY_CTRL,true)
	await driver.frames(16)
	var ceiling = StaticBody3D.new()
	ceiling.collision_layer = 1
	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(2,0.2,2)
	ceiling.add_child(collision)
	game.add_child(ceiling)
	ceiling.position = Vector3(0,1.35,6.4)
	await driver.frames(4)
	driver.release(KEY_CTRL)
	await driver.frames(4)
	expect(game.crouched,"Low ceiling prevents expanding the standing capsule")
	driver.key(KEY_SPACE)
	var ceiling_peak: float = await observe_jump()
	expect(ceiling_peak>floor_y+0.05 and ceiling_peak<floor_y+0.27 and game.player.is_on_floor(),"Crouched jump collides with the ceiling and lands without passing through it")
	ceiling.queue_free()
	await driver.frames(20)
	expect(not game.crouched,"Character can stand again after leaving ceiling obstruction")
	# Carry through the existing solid grip, without bypassing pickup ownership.
	await driver.aim(game.bodies.pad_1.global_position)
	driver.key(KEY_E)
	await driver.frames(12)
	expect(not game.held_build().is_empty(),"Ordinary input picks up a build for the carrying jump check")
	await settle_at(Vector3(0,0.025,6.4))
	await driver.frames(30)
	var body: RigidBody3D = game.bodies[game.held_build()] if not game.held_build().is_empty() else game.bodies.pad_1
	var carry_start: float = body.global_position.y
	driver.key(KEY_SPACE)
	await driver.frames(20)
	expect(body.held and body.global_position.y>carry_start+0.5 and body.freeze,"A carried build follows the rising character with its solid grip intact")
	await observe_jump()
	expect(body.held and game.player.is_on_floor() and game.model.integrity_errors().is_empty(),"Landing preserves carried ownership and inventory integrity")
	var passed: bool = checks.all(func(check):return check.passed)
	DirAccess.make_dir_recursive_absolute("res://verification/jump")
	write_evidence("res://verification/jump/audit.json",{"passed":passed,"checks":checks,"engine":Engine.get_version_info().string,"rendered":false})
	print("JUMP ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	game.queue_free()
	driver.queue_free()
	await process_frame
	quit(0 if passed else 1)
