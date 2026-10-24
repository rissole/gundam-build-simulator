extends "res://tests/kit/workshop_suite.gd"
## Independent M3 desktop journey. No stage_pose, install, request or teleport is
## used here: equipment and parts are operated through their actual input targets.
var driver: RefCounted
var checkpoints: Array[Dictionary] = []
var travelled: Array[Dictionary] = []
var installed: Dictionary = {}
var checkpoint_serial = 0
var debug_fixture: Dictionary = {}
const STOCK = Vector3(3.2,0,22.5)
const CONSOLE_WEST = Vector3(6.85,0,22.5)
const JUNCTION = Vector3(6.85,0,20.5)
const FIXTURE_WEST = Vector3(10.5,0,20.5)
const FIXTURE_EAST = Vector3(13.2,0,20.5)
const RAMP_FRONT = Vector3(9.6,0,21.7)
const BAY_PANEL = Vector3(4.3,0,24.2)

func boot_m3() -> void:
	game = await boot_profile("leg_bay_m3")
	driver = PlayerDriver.new(game)

func lift_center() -> Vector3:
	return game.equipment.get_equipment("hip_lift").deck.global_position

func restore_played_debug(path: String, allow_fixture: bool) -> bool:
	var load_path = path
	if allow_fixture:
		# Explicit diagnostic-only compatibility fixture. Preserve original file
		# and unchanged actual-play payload; production still rejects old content.
		var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var record: Dictionary = Store.read(path,envelope.fingerprint)
		expect(record.ok,"Diagnostic fixture verifies original played checksum")
		if not record.ok:return false
		var errors: Array[String] = game.saves.validate(record.payload)
		expect(errors.is_empty(),"Unchanged played payload validates against current diagnostic layout: "+str(errors))
		if not errors.is_empty():return false
		load_path="/tmp/m3-diagnostic-played-"+str(Time.get_ticks_usec())+".json"
		var error: String = Store.write(load_path,game.saves.fingerprint,record.payload,false)
		expect(error.is_empty(),"Write isolated diagnostic fixture without altering original played save")
		if not error.is_empty():return false
		debug_fixture={"source":path,"source_fingerprint":envelope.fingerprint,"current_fingerprint":game.saves.fingerprint,"payload_unchanged":true,"temporary_copy":load_path}
	else:
		load_path="/tmp/m3-native-played-"+str(Time.get_ticks_usec())+".json"
		var copied: int = DirAccess.copy_absolute(ProjectSettings.globalize_path(path),load_path)
		expect(copied==OK,"Resume a temporary native copy, preserving retained played evidence")
		if copied!=OK:return false
	game.saves.setup(game,load_path,false)
	var restored: bool = game.saves.restored and game.paused
	expect(restored,"Debug continuation restores its disclosed played checkpoint")
	if not restored:return false
	game.set_paused(false);driver=PlayerDriver.new(game);await frames(3)
	return true

func walk(point: Vector3, label: String) -> bool:
	var arrived: bool = await driver.walk(point,1800,.10,8)
	if not arrived:
		var blockers: Array[String] = []
		for index in range(game.player.get_slide_collision_count()):
			var collider = game.player.get_slide_collision(index).get_collider()
			if collider != null:blockers.append(str(collider.get_path()))
		print("M3_WALK_BLOCKERS ",label," ",blockers)
	expect(arrived,"Walked route: "+label)
	travelled.append({"label":label,"feet":str(game.player.global_position),"arrived":arrived})
	return arrived

func tap(code: Key) -> void:driver.tap(code)
func look(point: Vector3) -> void:driver.look(point)

func route(points: Array, label: String) -> bool:
	for index in range(points.size()):
		if not await walk(points[index],label+" / "+str(index+1)):return false
	return true

func stock_to_fixture(east: bool = false) -> bool:
	# Measured bidirectional zone contract: stock -> behind console -> junction
	# -> west fixture -> east fixture. Never cut through stock rows or ramp sides.
	if not await walk(Vector3(STOCK.x,0,game.player.global_position.z),"drawer open-front exit"):return false
	if not await route([STOCK,CONSOLE_WEST,JUNCTION,FIXTURE_WEST],"stock to fixture zones"):return false
	return await walk(FIXTURE_EAST,"fixture east receiving aisle") if east else true

func fixture_to_stock() -> bool:
	var exit = FIXTURE_EAST if game.player.global_position.x>11.9 else FIXTURE_WEST
	return await route([exit,JUNCTION,CONSOLE_WEST,STOCK],"fixture to stock zones")

func to_ramp_front() -> bool:
	if game.player.global_position.x<0:
		if not await walk(Vector3(STOCK.x,0,game.player.global_position.z),"carried half clears drawer row"):return false
	if not await route([STOCK,CONSOLE_WEST,Vector3(6.85,0,21.7),RAMP_FRONT],"ordinary open-front lift route"):return false
	return true

func to_bay_panel() -> bool:
	if game.player.global_position.x>6:
		if not await route([RAMP_FRONT,Vector3(6.85,0,21.7),CONSOLE_WEST,STOCK],"lift front to bay west approach"):return false
	else:
		if not await walk(STOCK,"bay controls approach via west aisle"):return false
	return await walk(BAY_PANEL,"bay panel west working face")

func control(controller: Node, action: String, click: bool = false, expect_blocked: bool = false) -> bool:
	var entries: Array = controller.controls().filter(func(entry):return entry.action == action)
	if entries.is_empty():expect(false,"Equipment offers "+controller.equipment_id+"/"+action);return false
	# Rail duplicates local controls; prefer the closest physical panel.
	entries.sort_custom(func(a,b):return game.player.global_position.distance_squared_to(a.point)<game.player.global_position.distance_squared_to(b.point))
	look(entries[0].point);await frames(80 if controller.equipment_id=="lift_shelf" and action=="store" else 2);game.automation.refresh_target()
	var access: String = game.automation.access_error()
	var access_expected: bool = not access.is_empty() if expect_blocked else access.is_empty()
	var reached: bool = game.target.get("controller") == controller and game.target.get("action","") == action and access_expected
	if not reached:print("M3_CONTROL_TARGET ",controller.equipment_id,"/",action," feet=",game.player.global_position," target=",game.target," access=",game.automation.access_error())
	expect(reached,("Ordinary blocked control aim: " if expect_blocked else "Ordinary aim: ")+controller.equipment_id+"/"+action)
	if reached:
		if click:driver.click()
		else:tap(KEY_E)
	return reached

func settle(controller: Node) -> bool:
	var stationary: Dictionary = {}
	if controller.equipment_id=="leg_rail" and game.model.assemblies.left_leg.parent=="pelvis":
		for id in game.runtime.descendants("left_leg"):
			stationary[id] = game.runtime.node(id).global_transform
	var stayed = true
	for tick in range(1800):
		for id in stationary:
			stayed = stayed and game.runtime.node(id).global_transform.is_equal_approx(stationary[id])
		if not controller.moving:
			var clear: bool = controller.get("blocked_reason") == null or controller.blocked_reason.is_empty()
			if not clear:print("M3_BLOCKED ",controller.equipment_id," ",controller.capture())
			if not stationary.is_empty():expect(stayed,"Mounted leg and all descendants remain stationary at every physics tick during holder motion")
			return clear and stayed
		await frames(1)
	print("M3_SETTLE_TIMEOUT ",controller.equipment_id," ",controller.capture())
	return false

func console_action(action: String) -> bool:
	var crane = game.equipment.get_equipment("service_crane")
	if not crane.console.is_open:
		if not await control(crane,"open_console"):return false
	await process_frame
	if not crane.console.buttons.has(action):expect(false,"Console offers "+action);return false
	var position: Vector2 = crane.console.buttons[action].get_global_rect().get_center()
	for down in [true,false]:
		var event = InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=position;event.global_position=position;event.pressed=down
		game.get_viewport().push_input(event,true);await process_frame
	await frames(2)
	var accepted: bool = crane.console.feedback.text == "Command accepted."
	if not accepted:print("M3_CONSOLE_REJECT ",action," ",crane.console.feedback.text," ",crane.capture())
	expect(accepted,"Physical console: "+action)
	return accepted

func command(action: String) -> bool:
	if not await console_action(action):return false
	var crane = game.equipment.get_equipment("service_crane")
	var stopped = await settle(crane)
	expect(stopped,"Crane completes "+action)
	if not stopped:
		print("M3_CRANE_COMMAND_FAILURE action=",action," capture=",crane.capture()," console=",crane.console.feedback.text," toast=",game.hud.toast_label.text)
		await checkpoint("blocked-crane-"+crane.task+"-"+action.replace(":","-"))
	return stopped

func to_console() -> bool:
	if game.player.global_position.x>11.9 and game.player.global_position.z<20:
		if not await walk(Vector3(13.3,0,20.5),"east work face exit before console"):return false
	elif game.player.global_position.x>9.5 and game.player.global_position.z<20:
		if not await walk(Vector3(10.5,0,20.5),"west work face exit before console"):return false
	elif game.player.global_position.x>8 and game.player.global_position.z<10.5:
		if not await walk(Vector3(8.65,0,20.5),"dispatch aisle between source racks and rail controls"):return false
	return await walk(Vector3(4.9,0,21.9),"central crane console")

func checkpoint(label: String) -> bool:
	# Save a real file, destroy the scene, reload a fresh scene, then continue the
	# same route. This is persistence evidence, never a supplied-construction seam.
	var data: Dictionary = JSON.parse_string(JSON.stringify(game.saves.capture()))
	var errors: Array[String] = game.saves.validate(data)
	if not errors.is_empty():print("M3_INVALID_CHECKPOINT ",label," errors=",errors," equipment=",data.world.equipment," foot=",data.model.assemblies.foot)
	expect(errors.is_empty(),"Checkpoint validates: "+label+" "+str(errors))
	if not errors.is_empty():return false
	checkpoint_serial += 1
	var path = "/tmp/m3-journey-"+str(OS.get_process_id())+"-"+str(Time.get_ticks_usec())+"-"+str(checkpoint_serial)+".json"
	game.saves.setup(game,path,false)
	var saved: bool = game.saves.save_now()
	if not saved:
		print("M3_SAVE_FAILED ",label," ",game.saves.message," validation=",game.saves.validate(game.saves.capture()))
		diagnose_json(game.saves.capture())
	expect(saved,"Checkpoint writes real save: "+label)
	if not saved:return false
	DirAccess.make_dir_recursive_absolute("res://verification")
	var played_path = "res://verification/m3-played-"+label+".json"
	var retained: int = DirAccess.copy_absolute(path,ProjectSettings.globalize_path(played_path))
	expect(retained==OK,"Retain actually played checkpoint artifact: "+label)
	game.free();await process_frame
	game = instantiate_profile(self,"leg_bay_m3")
	game.saves.setup(game,path,false)
	driver = PlayerDriver.new(game)
	var resumed: Dictionary = JSON.parse_string(JSON.stringify(game.saves.capture()))
	var same: bool = game.saves.restored and game.paused and resumed.model == data.model and resumed.world.equipment == data.world.equipment and resumed.world.player == data.world.player and resumed.world.reader == data.world.reader
	if not same:print("M3_RESTORE_MISMATCH ",label," original=",data.world.equipment," restored=",resumed.world.equipment," error=",game.saves.message)
	expect(same,"Fresh scene preserves physical ownership and equipment: "+label)
	checkpoints.append({"label":label,"saved":saved,"restored":same,"file":path,"played_file":played_path})
	game.set_paused(false);Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	await frames(3)
	for suffix in ["",".bak"]:
		if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
	return same

func collect(kind: String, count: int) -> bool:
	if not game.bins.has(kind):expect(false,"Collectible stock exists: "+kind);return false
	if game.model.count_at(kind,"pocket")>=count:
		expect(true,"Persistent pocket already holds required "+kind+" quantity")
		return true
	if game.player.global_position.x<0:
		if not await walk(Vector3(STOCK.x,0,game.player.global_position.z),"leave drawer row along its open front"):return false
	elif game.player.global_position.x>9.5 and game.player.global_position.z<20:
		if not await fixture_to_stock():return false
	elif game.player.global_position.x>6 and game.player.global_position.z>=20:
		if not await route([RAMP_FRONT,Vector3(6.85,0,21.7),CONSOLE_WEST,STOCK],"lift front to stock zones"):return false
	elif game.player.global_position.z>20:
		if not await walk(STOCK,"console or bay to stock west aisle"):return false
	var bin: Node3D = game.bins[kind]
	var point: Vector3 = bin.global_transform*Vector3(0,.13,.27)
	if not await walk(Vector3(STOCK.x,0,point.z+.75),"stock west aisle "+kind):return false
	if not await walk(Vector3(point.x,0,point.z+.75),"stock front "+kind):return false
	for index in range(count):
		if game.model.count_at(kind,"pocket") >= count:break
		look(point);await frames(2);game.automation.refresh_target()
		var aimed: bool = game.target.get("type","") == "bin" and game.target.get("kind","") == kind
		expect(aimed,"Normal stock target: "+kind)
		if not aimed:return false
		tap(KEY_E)
	return true

func slot_ray_diagnostic(point: Vector3) -> void:
	var query = PhysicsRayQueryParameters3D.create(game.camera.global_position,point,game.WORLD_MASK)
	var excluded: Array[RID] = [game.player.get_rid()]
	for body in game.bodies.values():
		if body.held:excluded.append(body.get_rid())
	if is_instance_valid(game.components.held_body):excluded.append(game.components.held_body.get_rid())
	query.exclude = excluded
	var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var shape_node: Object = hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape))
		print("M3_SLOT_RAY collider=",hit.collider.get_path()," point=",hit.position," normal=",hit.normal," shape=",shape_node," metadata=",shape_node.get_meta_list())
		for key in shape_node.get_meta_list():print("M3_SLOT_RAY_META ",key,"=",shape_node.get_meta(key))

func install_slot(owner: String, sid: String) -> bool:
	var kind: String = game.model.slot_definition(owner,sid).get("accepts","")
	if not kind.is_empty() and game.model.definitions.parts[kind].carry_class == "pocket":
		if not driver.select_kind(kind):expect(false,"Pocket has "+kind);return false
	var point: Vector3 = game.components.slot_point(owner,sid)
	look(point);await frames(80 if not game.model.held_item().is_empty() else 3);game.automation.refresh_target()
	var aimed: bool = game.target.get("type","") == "component" and game.target.get("owner","") == owner and game.target.get("sid","") == sid
	if not aimed:
		print("M3_SLOT_TARGET ",owner,"/",sid," point=",point," feet=",game.player.global_position," target=",game.target)
		slot_ray_diagnostic(point)
	expect(aimed,"Ordinary connection aim: "+owner+"/"+sid)
	if not aimed:
		await checkpoint("failed-aim-"+owner+"-"+sid.replace("/","-"))
		return false
	var access: String = game.automation.access_error()
	if not access.is_empty():
		print("M3_SLOT_ACCESS ",owner,"/",sid," feet=",game.player.global_position," point=",point," access=",access)
		if is_instance_valid(game.components.held_body):print("M3_HELD_TRANSFORMS held=",game.components.held_body.global_transform," destination=",game.components.slot_pose(owner,sid))
		slot_ray_diagnostic(point)
	driver.click()
	var uid: String = game.model.assemblies[owner].slots[sid]
	expect(not uid.is_empty(),"Ordinary click installs "+owner+"/"+sid+": "+game.hud.toast_label.text)
	if uid.is_empty() and not game.model.held_item().is_empty():await checkpoint("failed-held-"+owner+"-"+sid.replace("/","-"))
	if not uid.is_empty():installed[owner+"/"+sid] = uid
	return not uid.is_empty()

func audit_manuals() -> void:
	# Inspection-only seam; the walked route uses V/C and ordinary page keys.
	var total = 0
	for owner in ["left_leg","pelvis"]:
		var definition: Dictionary = game.components.definition(owner)
		var coverage: Dictionary = {}
		for index in range(definition.manual.size()):
			var step: Dictionary = definition.manual[index]
			game.hud.open_manual(owner,index)
			if step.get("view","") != "components":
				expect(step.slots.is_empty() and not "Parts for this step" in game.hud.page_body.text,"Runtime status page has no supplies: "+owner+"/"+str(index))
				if step.get("view","")=="prepared":
					var filled: int = game.model.assemblies[owner].slots.size()-game.model.assemblies[owner].slots.values().count("")
					expect(game.hud.page_count.text.begins_with(str(filled)+" / "+str(definition.slots.size())+" assembly components"),"Runtime readiness footer counts actual assembly progress: "+owner)
				continue
			var quantities: Dictionary = {}
			for sid in step.slots:
				coverage[sid] = coverage.get(sid,0)+1
				var spec: Dictionary = definition.slots[sid]
				if spec.has("accepts"):
					var title: String = game.components.title(spec.accepts)
					quantities[title] = quantities.get(title,0)+1
				else:
					expect("(prepared) ×1" in game.hud.page_body.text,"Runtime page includes prepared child supply: "+owner+"/"+sid)
			for title in quantities:expect((title+" ×"+str(quantities[title])) in game.hud.page_body.text,"Runtime page quantities: "+owner+"/"+str(index)+" "+title)
			total += step.slots.size()
		expect(coverage.size()==definition.slots.size() and coverage.values().all(func(n):return n==1),"Every runtime installation slot appears exactly once: "+owner)
	expect(total == 42,"M3 runtime manuals cover all 42 installation slots")

func audit_readiness(owner: String) -> void:
	# Direct reader inspection is separate from the ordinary player journey;
	# restore its page and verify no pocket or construction state was altered.
	var previous_owner: String = game.hud.manual_id
	var previous_page: int = game.hud.page
	var previous_pages: Dictionary = game.hud.pages.duplicate(true)
	var previous_visible: bool = game.hud.manual.visible
	var previous_scroll: int = game.hud.body_scroll.scroll_vertical
	var previous_reader: String = JSON.stringify(game.saves.capture().world.reader)
	var before: String = JSON.stringify(game.saves.capture().model)
	var definition: Dictionary = game.components.definition(owner)
	for index in range(definition.manual.size()):
		if definition.manual[index].get("view","")!="prepared":continue
		game.hud.open_manual(owner,index)
		var filled: int = game.model.assemblies[owner].slots.size()-game.model.assemblies[owner].slots.values().count("")
		expect(game.hud.page_count.text.begins_with(str(filled)+" / "+str(definition.slots.size())+" assembly components"),"Runtime readiness reflects actual "+owner+" progress "+str(filled)+"/"+str(definition.slots.size()))
		expect(not "Parts for this step" in game.hud.page_body.text,"Readiness inspection adds no supply list: "+owner)
	game.hud.open_manual(previous_owner,previous_page)
	game.hud.pages=previous_pages
	game.hud.manual.visible=previous_visible
	game.hud.refresh()
	game.hud.body_scroll.scroll_vertical=previous_scroll
	expect(JSON.stringify(game.saves.capture().world.reader)==previous_reader,"Readiness inspection restores all remembered reader pages and visibility")
	expect(JSON.stringify(game.saves.capture().model)==before,"Readiness inspection preserves every pocket, physical identity and build")

func select_build(owner: String) -> bool:
	if game.hud.manual_id==owner:return true
	var before: String = JSON.stringify(game.saves.capture().model)
	# V selects the actual aimed construction. C also handles a carried half
	# whose receiving manual is suggested before the half has been installed.
	var points: Array = []
	for sid in game.model.assemblies[owner].slots:
		points.append(game.components.slot_point(owner,sid))
	points.sort_custom(func(a,b):return game.camera.global_position.distance_squared_to(a)<game.camera.global_position.distance_squared_to(b))
	for point in points:
		look(point);await frames(1);game.automation.refresh_target()
		if game.target.get("owner",game.target.get("build","")) == owner:
			tap(KEY_V)
			if game.hud.manual_id==owner:
				expect(JSON.stringify(game.saves.capture().model)==before,"V manual selection preserves pockets, identities and every build")
				return true
	for index in range(game.model.assemblies.size()+1):
		if game.hud.manual_id == owner:
			expect(JSON.stringify(game.saves.capture().model)==before,"C manual selection preserves pockets, identities and every build")
			return true
		tap(KEY_C)
	# Completed equipment builds need the all-build browser when the selected
	# pocket narrows C to unfinished compatible work. Use the real GUI controls.
	tap(KEY_N);await process_frame
	var browser = game.hud.browser
	expect(browser.visible,"N opens the actual manual browser")
	if not browser.visible:return false
	if browser.filter_button.button_pressed:
		await gui_click(browser.filter_button.get_global_rect().get_center())
	expect(not browser.suggested_only,"Actual filter control reveals all build manuals")
	if not browser.folders.has(owner):expect(false,"All-build tree contains "+owner);return false
	var item: TreeItem = browser.folders[owner]
	var area: Rect2 = browser.tree.get_item_area_rect(item,0)
	var point: Vector2 = browser.tree.global_position+area.get_center()
	for attempt in range(16):
		if browser.tree.get_global_rect().has_point(point):break
		var wheel = InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_DOWN;wheel.position=browser.tree.get_global_rect().get_center();wheel.pressed=true
		game.get_viewport().push_input(wheel,true);await process_frame
		area=browser.tree.get_item_area_rect(item,0);point=browser.tree.global_position+area.get_center()
	await gui_click(point)
	var selected: bool = game.hud.manual_id==owner
	expect(selected,"Actual all-build tree click selects completed "+owner+" manual")
	tap(KEY_N);await frames(2)
	expect(not browser.visible and not game.paused,"N closes manual browser and resumes ordinary workshop controls")
	expect(JSON.stringify(game.saves.capture().model)==before,"GUI manual selection preserves pockets, identities and every build")
	return selected

func gui_click(point: Vector2) -> void:
	for pressed in [true,false]:
		var event = InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=point;event.global_position=point;event.pressed=pressed
		game.get_viewport().push_input(event,true);await process_frame
	await frames(2)
