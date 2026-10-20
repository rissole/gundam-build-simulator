extends Node
## Drives public input handlers and actual world-space targeting/collision.
## Camera positions are scripted; placement and inventory are never bypassed.
var game: Node
var checks: Array[Dictionary] = []
var rendered: bool = false

func expect(condition: bool, name: String) -> void:
	checks.append({"check":name,"passed":condition})
	print("CHECK ","PASS " if condition else "FAIL ",name)
	if not condition:
		push_error(name)

func frames(n: int = 4) -> void:
	for i in range(n):await get_tree().physics_frame

func key(code: Key, shift: bool = false) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	event.shift_pressed = shift
	game._unhandled_input(event)

func click() -> void:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	game._unhandled_input(event)

func release(code: Key) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = false
	game._unhandled_input(event)

func hold(code: Key, pressed: bool) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func aim(point: Vector3, distance: float = 1.35) -> void:
	game.player.global_position = Vector3(point.x,0.025,point.z+distance)
	game.player.velocity = Vector3.ZERO
	var direction: Vector3 = point-game.camera.global_position
	game.player.rotation = Vector3(0,atan2(-direction.x,-direction.z),0)
	game.camera.rotation = Vector3(atan2(direction.y,Vector2(direction.x,direction.z).length()),0,0)
	await frames(5)
	game._update_target()
	game._update_ghost()

func capture(name: String) -> void:
	if not rendered:return
	await get_tree().process_frame
	# Fullscreen macOS windows may stop automatic draws when another app is
	# focused. Explicitly render this inspection frame rather than wait forever.
	RenderingServer.force_draw(false)
	game.get_viewport().get_texture().get_image().save_png("res://verification/"+name+".png")

func run(workshop: Node) -> void:
	game = workshop
	rendered = DisplayServer.get_name() != "headless"
	expect(game.source.size()==745,"Full source inventory imported at separate part identities")
	expect(game.active_ids.size()==13,"Exactly thirteen active source objects removed from context")
	expect(game.hud.pause_panel.visible,"Welcome/help interface available on launch")
	await frames(10)
	if rendered:
		expect(DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN,"Launch uses non-exclusive fullscreen")
		expect(game.get_viewport().get_visible_rect().encloses(game.hud.pause_card.get_global_rect()),"Pause card fits the display")
	await capture("05-controls")
	expect(game.hud.action_slots.size()==4,"Four numbered action-bar slots replace text inventory")
	for slot in game.hud.action_slots:
		expect(slot.model.texture is ViewportTexture and not slot.id.text.is_empty(),"Action slot renders source mesh and part ID: "+slot.kind)
	game.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	key(KEY_TAB)
	expect(not game.hud.manual.visible,"HUD manual toggles closed")
	key(KEY_TAB)
	expect(game.hud.manual.visible,"HUD manual toggles open")
	await frames(25)
	await capture("01-workshop")
	var start_z: float = game.player.position.z
	var move_event = InputEventKey.new()
	move_event.physical_keycode = KEY_W
	move_event.pressed = true
	Input.parse_input_event(move_event)
	await frames(25)
	move_event.pressed = false
	Input.parse_input_event(move_event)
	expect(game.player.position.z < start_z-0.3,"W input moves the first-person collision body")
	hold(KEY_CTRL,true)
	await frames(18)
	expect(game.crouched and game.camera.position.y<1.0 and game.player_collision.shape.height==1.0,"Hold Ctrl lowers camera and collision capsule")
	# A real overhead collider must prevent standing, without moving the feet.
	var ceiling = StaticBody3D.new()
	game.add_child(ceiling)
	ceiling.position = game.player.position+Vector3(0,1.3,0)
	var ceiling_col = CollisionShape3D.new()
	var ceiling_shape = BoxShape3D.new()
	ceiling_shape.size = Vector3(1.5,0.2,1.5)
	ceiling_col.shape = ceiling_shape
	ceiling.add_child(ceiling_col)
	await frames(3)
	hold(KEY_CTRL,false)
	await frames(18)
	expect(game.crouched and game.camera.position.y<1.0,"Cannot stand through an overhead obstacle")
	ceiling.queue_free()
	await frames(20)
	expect(not game.crouched and is_equal_approx(game.camera.position.y,1.63),"Release Ctrl restores standing when clearance allows")
	for kind in HeelAssemblyState.KINDS:
		await aim(game.bins[kind].global_position+Vector3(0,0.13,0.27))
		expect(game.target.get("type")=="bin" and game.target.get("kind")==kind,"Actual aim identifies "+kind+" bin")
		key(KEY_E,true)
		expect(game.state.count_at(kind,"pocket")==4,"Collect four "+kind+" from finite physical bin")
	expect(game.state.pocket_count()==12,"Pockets hold all twelve demo hardware pieces")
	expect(game.hud.action_slots[0].count.text=="×4" and game.hud.action_slots[2].count.text=="×4","Action-bar counts track collected stock")
	# Physically put down and recollect a washer on the preparation tray.
	await aim(Vector3(-0.4,1.0,0.6),0.7)
	key(KEY_2)
	key(KEY_Q)
	await frames(60)
	var loose_uid: String = game.state.find_item("washer","loose")
	expect(not loose_uid.is_empty(),"Q creates a real loose washer without duplication")
	if not loose_uid.is_empty():
		await aim(game.loose[loose_uid].global_position,0.75)
		key(KEY_E)
		expect(game.state.items[loose_uid].location=="pocket","Loose washer can be recollected from tray")
	await aim(game.pad.global_position)
	key(KEY_E)
	expect(game.state.pad_location=="held","E picks up the two-handed heel pad")
	game.player.global_position = Vector3(0,0.025,5.8)
	game.player.rotation = Vector3.ZERO
	game.camera.rotation = Vector3.ZERO
	await frames(35)
	hold(KEY_D,true)
	hold(KEY_SHIFT,true)
	var max_grip_error = 0.0
	for i in range(30):
		await frames(1)
		max_grip_error = maxf(max_grip_error,game.pad.global_position.distance_to(game.pad.carry_target))
	hold(KEY_D,false)
	hold(KEY_SHIFT,false)
	expect(max_grip_error<0.02,"Firm grip stays within 2 cm of its target while moving fast")
	for i in range(12):
		game.player.rotate_y(0.06)
		game.camera.rotation.x += 0.02
		await frames(2)
	expect(game.pad.global_basis.is_equal_approx(game.pad.carry_basis),"Held orientation follows view without spring lag")
	expect(game.pad.freeze and game.hud.action_slots[3].count.text=="2H","Two-hand slot shows occupied hands during firm carry")
	await aim(game.prep.global_position)
	await frames(35)
	game._update_target()
	game._update_ghost()
	expect(game.target.get("type")=="prep" and game.ghost.visible,"Small station previews held pad placement")
	click()
	expect(game.state.pad_location=="prep","Click suspends pad in preparation station")
	key(KEY_3)
	await aim(game.connection(0))
	click()
	expect(game.state.installed("bolt")==0 and game.hud.toast_label.text.contains("carrier"),"Premature bolt placement explains missing receiving assembly")
	key(KEY_1)
	for i in [2,0,3,1]:
		await aim(game.connection(i)+Vector3(0.065,0,0))
		expect(game.target.get("index",-1)==i,"Generous targeting selects sleeve socket %d"%i)
		expect(game.ghost.visible,"Valid sleeve socket %d displays actual mesh ghost"%i)
		if i==0:await capture("02-pad-preparation")
		click()
		expect(game.state.slots.sleeve[i]!="","Click installs sleeve %d"%i)
	expect(game.state.prepared(),"Prepared subassembly reaches four sleeves")
	key(KEY_Z)
	expect(game.state.installed("sleeve")==3 and game.state.pocket_count()==9,"Undo removes exactly one sleeve and returns it")
	await aim(game.connection(1))
	click()
	expect(game.state.prepared(),"Undo can be followed by valid reconstruction")
	await aim(game.prep.global_position)
	game._rotate_station(Vector2(30,15))
	expect(not game.prep.basis.is_equal_approx(game.PREP_BASIS),"Station rotation changes the real assembly orientation")
	await frames(2)
	expect(game.hud.rotation_hint.visible,"Looking at a nearby station shows the contextual rotation tutorial")
	key(KEY_R)
	release(KEY_R)
	expect(not game.prep.basis.is_equal_approx(game.PREP_BASIS),"Single R tap does not reset the assembly")
	key(KEY_R)
	release(KEY_R)
	expect(game.prep.basis.is_equal_approx(game.PREP_BASIS),"Double-tap R restores station working orientation")
	key(KEY_R)
	var rotate_motion = InputEventMouseMotion.new()
	rotate_motion.relative = Vector2(22,12)
	game._unhandled_input(rotate_motion)
	release(KEY_R)
	key(KEY_R)
	release(KEY_R)
	expect(not game.prep.basis.is_equal_approx(game.PREP_BASIS),"Rotation drag followed by a tap is not mistaken for a double tap")
	game.reset_station()
	await aim(game.connection(1))
	key(KEY_E)
	expect(game.state.pad_location=="held","Prepared pad picked up with all its child components")
	# Scripted transit advances the collision-aware grip to the receiving station.
	await aim(game.mount_point())
	await frames(110)
	game._update_target()
	game._update_ghost()
	expect(game.target.get("type")=="mount","Aim selects the rear sole carrier")
	expect(game.ghost.visible,"Ready pad previews at the actual receiving transform")
	key(KEY_3)
	click()
	expect(game.state.pad_location=="held","Selecting pocket hardware cannot accidentally mount the carried pad")
	key(KEY_4)
	game._update_ghost()
	await capture("03-mount-preview")
	click()
	expect(game.state.pad_location=="foot","Prepared assembly mounts to full-size foot")
	key(KEY_3)
	await aim(game.connection(0))
	click()
	expect(game.state.installed("bolt")==0 and game.hud.toast_label.text.contains("W-24"),"Missing washer produces descriptive compatible-part error")
	for i in [3,1,0,2]:
		key(KEY_2)
		await aim(game.connection(i))
		expect(game.target.get("index",-1)==i,"Foot targeting selects mount %d"%i)
		click()
		key(KEY_3)
		await aim(game.connection(i))
		expect(game.ghost.visible,"Bolt ghost available after local washer %d"%i)
		click()
		expect(game.state.slots.bolt[i]!="","Independent fastening order accepted at %d"%i)
	expect(game.state.complete(),"Complete build achieved through public interaction handlers")
	expect(game.state.pocket_count()==0,"Exactly the original twelve pocket items consumed")
	expect(game.state.integrity_errors().is_empty(),"No missing/duplicate pieces or invalid ownership after complete run")
	expect(game.completed_before and game.hud.toast_label.text.contains("COMPLETE"),"Completion feedback and manual state agree")
	await capture("04-complete")
	key(KEY_Z)
	expect(not game.state.complete() and game.state.count_at("bolt","pocket")==1,"Undo after completion clears completion and returns exact bolt")
	# Real target reach must prevent a click from across the workshop.
	await aim(game.connection(2),4.0)
	click()
	expect(game.state.slots.bolt[2]=="" and game.hud.toast_label.text.contains("reach"),"Attachment is blocked outside character reach")
	await aim(game.connection(2))
	click()
	expect(game.state.complete(),"Close-range replacement completes build again")
	var before_pause = game.state.history.size()
	key(KEY_ESCAPE)
	expect(game.paused and game.hud.pause_panel.visible,"Escape opens pause/help")
	expect(not game.hud.rotation_hint.visible,"Pause hides contextual rotation hints")
	await capture("06-paused")
	game.hud.restart_button.pressed.emit()
	expect(game.hud.confirm_restart and game.state.complete(),"Restart requires confirmation without losing current build")
	key(KEY_Z)
	expect(game.state.history.size()==before_pause,"Paused input cannot change the build")
	key(KEY_ESCAPE)
	expect(not game.paused,"Escape resumes workshop")
	expect(not game.hud.confirm_restart,"Resuming cancels pending restart")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Rotate the fixture to expose its back; hidden connections are ineligible.
	game.foot.basis = Basis(Vector3.UP,PI)*game.FOOT_BASIS
	await aim(game.connection(2),1.4)
	game._update_ghost()
	expect(not game._visible(game.connection(2),[game.pad,game.foot]),"Back-facing connection is occluded by solid workpiece")
	game.foot.basis = game.FOOT_BASIS
	# Undo the parent before child state; identity survives the station transfer.
	for i in range(9):key(KEY_Z)
	expect(game.state.pad_location=="prep" and game.state.prepared(),"Undo hardware then parent mount returns prepared pad to station")
	expect(game.state.integrity_errors().is_empty(),"Parent undo preserves child build and counts")
	# Collision stress: firm grip targets beyond the rear wall.
	await aim(game.pad.global_position)
	key(KEY_E)
	game.pad.global_transform = Transform3D(game.PREP_BASIS,Vector3(-6,1.4,-5.6))
	game.pad.linear_velocity = Vector3.ZERO
	game.player.global_position = Vector3(-6,0.02,-6.0)
	game.player.rotation = Vector3.ZERO
	game.camera.rotation = Vector3.ZERO
	await frames(190)
	expect(game.pad.global_position.z > -6.95 and game.pad.global_position.z < -6.5,"Firm grip reaches the wall and solid pad cannot pass through it")
	expect(not game._carry_placement_error(Transform3D(game.PREP_BASIS,Vector3(-5.37,1.4,-7.8))).is_empty(),"Snap approach cannot teleport a carried pad through scenery")
	key(KEY_Q)
	expect(game.state.pad_location=="loose","Prepared pad can be set down without losing build state")
	expect(not game.pad.freeze,"Putting the pad down restores ordinary rigid-body physics")
	expect(game.state.prepared(),"Unfinished/resumable assembly state follows physical pad")
	var passed = checks.all(func(c):return c.passed)
	var report = {"passed":passed,"checks":checks,"engine":Engine.get_version_info().string,"rendered":rendered,"renderer":RenderingServer.get_current_rendering_method(),"inventory_errors":game.state.integrity_errors()}
	FileAccess.open("res://verification/demo-audit.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("DEMO_AUDIT ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	get_tree().quit(0 if passed else 1)
