extends "res://tests/kit/harness.gd"
## Isolated contract/physics fixture, not a walked or rendered acceptance run.
const Rope = preload("res://scripts/rope_access.gd")
const Player = preload("res://scripts/player_controller.gd")
const Blockout = preload("res://scripts/workshop_blockout.gd")
const Access = preload("res://scripts/workshop_access.gd")
const Save = preload("res://scripts/workshop_save.gd")
const Guidance = preload("res://scripts/manual_control_guidance.gd")
const Codec = preload("res://scripts/pose_codec.gd")
class Hud extends RefCounted:
	var browser: Control = Control.new()
	var message=""
	var quiet_errors=false
	func toast(value: String, _success: bool=false) -> void:message=value
	func refresh() -> void:pass
	func handle_manual_browser_input(_event: InputEvent) -> bool:return false
class World extends Node3D:
	const WORLD_MASK=15
	const REACH=1.8
	const JUMP_SPEED=4.2
	var player: CharacterBody3D
	var player_collision: CollisionShape3D
	var camera: Camera3D
	var equipment=EquipmentRegistry.new()
	var model=AssemblyModel.new()
	var bodies={}
	var components: Node
	var part_defs={}
	var manual_progress=Progress.new()
	var interaction_outline: Node3D
	var hud=Hud.new()
	var hands=HandStub.new()
	var desktop_input: RefCounted
	var player_controller: RefCounted
	var targeting: RefCounted
	var scripted_controls={}
	var automated_test=true
	var paused=false
	var started=true
	var crouched=false
	var jump_requested=false
	var jump_held=false
	var target={}
	var drops=0
	func drop_selected() -> void:drops+=1
	func interact(all_stock: bool=false) -> void:components.interact(all_stock)
	func _update_target() -> void:pass
	func equipment_access_error(_owner: String) -> String:return ""
	func material(color: Color, roughness: float) -> StandardMaterial3D:
		var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=roughness;return mat
	func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
		var node=MeshInstance3D.new();node.mesh=BoxMesh.new();node.mesh.size=size;node.material_override=mat;parent.add_child(node);node.position=at;return node
class HandStub extends RefCounted:
	var full=false
	func occupied() -> bool:return full
class Progress extends RefCounted:
	signal updated
	var _queued=false
	func tracked() -> Dictionary:return {"owner":"chest","page":0,"definition":{"objectives":[{"op":"operate","machine":"work","command":"fasten"}]}}
	func evaluation(_owner: String,_page: int) -> Dictionary:return {"current":0}
	func status(_owner: String,_page: int) -> String:return "ready"
class Work extends "res://scripts/equipment.gd":
	var handle: MeshInstance3D
	var operated=0
	func controls() -> Array[Dictionary]:return [control_entry(handle,"fasten","Fasten",.12,{"point":handle.global_position})]
	func action_error(_action: String) -> String:return ""
	func request(_action: String) -> String:operated+=1;return ""
class CraneOccupancy extends "res://scripts/equipment.gd":
	var occupied=true
	var moving=false
	func upper_crossing_occupied() -> bool:return occupied
var game: World
var rope: Node
var blockout: Node
var access: Node
const FRONT="front_l_9.3"
const REAR="rear_11.0"
func _initialize() -> void:run.call_deferred()

func obstacle(at: Vector3, size: Vector3) -> StaticBody3D:
	var body=StaticBody3D.new();game.add_child(body);body.position=at
	var shape=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=size;body.add_child(shape)
	return body

func place(at: Vector3) -> void:
	game.player.position=at;game.player.velocity=Vector3.ZERO
	if rope!=null and rope.attached() and rope.ropes[rope.attachment].deployed:
		rope.reset_swing()
		rope.ropes[rope.attachment].length=clampf(rope.pose_length(rope.attachment,at),Rope.MIN_LENGTH,rope.max_length(rope.attachment))
	PhysicsServer3D.body_set_state(game.player.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,game.player.global_transform)

func key(code: Key, pressed: bool) -> void:
	var event=InputEventKey.new();event.physical_keycode=code;event.pressed=pressed
	game.desktop_input.handle(event)

## Cues name ropes that can actually serve the work, not every nearby line.
func served(id: String, point: Vector3) -> bool:
	rope._served.clear();rope._prediction_budget=1
	return rope.serves(id,{"point":point,"allowed":[],"body_hit":false,"depth":.065})

func check_service_prediction() -> void:
	var neighbour="front_l_10.8"
	# A connection on top of a flange between two front lines: hidden from below.
	var top=Vector3(10.05,13.0,26.0)
	var flange=obstacle(top-Vector3(0,.1,0),Vector3(.6,.2,.8))
	var shoulder=obstacle(Vector3(9.3,16,24.75),Vector3(.8,.2,.8))
	await frames(2)
	expect(not served(FRONT,top) and served(neighbour,top),"A descent stopped above the work is not cued; a clear neighbouring line is")
	shoulder.free();await frames(2)
	expect(served(FRONT,top),"With its line clear the same rope serves the flange connection")
	flange.free()
	var enclosed=obstacle(top,Vector3(.6,.6,.6))
	await frames(2)
	expect(not served(FRONT,top) and not served(neighbour,top),"A connection enclosed by structure is never cued")
	enclosed.free()
	# Beyond plumb reach, a capsule sweep reaches a holdable working pose.
	await frames(2)
	expect(not served(neighbour,Vector3(10.8,13.0,27.0)),"A fleeting extreme in empty air offers no brace for out-of-reach work")
	var block=obstacle(Vector3(10.8,12.5,26.9),Vector3(1,1,1.4))
	var far=Vector3(10.8,13.0,26.9)
	await frames(2)
	expect(not rope._sees(Vector3(10.8,13,24.75),{"point":far,"allowed":[],"body_hit":false,"depth":.065}) and served(neighbour,far),"Work beyond plumb reach is cued from the collision-stopped swing/brace pose")
	var barrier=obstacle(Vector3(10.8,13,25.4),Vector3(2,7,.2))
	await frames(2)
	expect(not served(neighbour,far),"A capsule sweep cannot cue work through an intervening wall")
	barrier.free()
	rope._served.clear();rope._prediction_budget=0
	expect(not rope.serves(neighbour,{"point":far,"allowed":[],"body_hit":false,"depth":.065}),"An exhausted per-frame budget defers new predictions")
	block.free();rope._served.clear();await frames(2)

func tick(count: int=1, delta: float=.1) -> void:
	for i in count:
		game.player_controller.physics(delta);rope.physics(delta)
		if i%20==0:await frames(1)

func aim(action: String) -> bool:
	for entry in rope.controls():
		if entry.action==action:
			game.camera.look_at(entry.point,Vector3.FORWARD if absf((entry.point-game.camera.global_position).normalized().y)>.99 else Vector3.UP)
			game.target=entry
			return game.targeting.aim_score(entry.point,entry.radius)!=INF and game.targeting.access([entry.node]).is_empty()
	return false

func aim_panel(action: String) -> bool:
	for entry in access.controls():
		if entry.action!=action:continue
		game.camera.look_at(entry.point);game.target=entry
		# The panel prompt offers E exactly when the action is available.
		game.targeting.offered_key="E" if access.action_error(action).is_empty() else ""
		return game.targeting.aim_score(entry.point,entry.radius)!=INF and game.targeting.access([entry.node]).is_empty()
	return false

func contract() -> Array:
	var result=[]
	for pair in [["l",[9.3,10.8,11.9,12.6],[4.3,5.8,6.9,7.6]],["r",[13.4,14.1,15.2,16.7],[7.6,6.9,5.8,4.3]]]:
		for i in 4:result.append({"id":"front_%s_%.1f"%[pair[0],pair[1][i]],"parent":"wing_%s_20.6"%("left" if pair[0]=="l" else "right"),"anchor":[pair[2][i],1.2,.75 if pair[0]=="l" else -.75],"edge":"front"})
	for x in [11.0,12.4,13.6,15.0]:result.append({"id":"rear_%.1f"%x,"parent":"","anchor":[x,21.8,28.3],"edge":"rear"})
	return result

## Use the actual authored boarding solids, rather than an unobstructed stand-in.
func boarding_solids() -> void:
	var authored: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop-layout.json")).workshop
	for id in authored.groups:
		if id.begins_with("wing_left_20.6") or id.begins_with("wing_right_20.6"):
			blockout.spec.groups[id]=authored.groups[id];blockout._group(id)
	for record in authored.solids:
		if not (record.id.begins_with("rope_davit_") or record.id.begins_with("rope_boom_") or record.id.begins_with("wing_left_20.6") or record.id.begins_with("wing_right_20.6") or record.id.begins_with("wing_hinge_left_20.6") or record.id.begins_with("lift_left_20.6_landing") or record.id.begins_with("hinge_front_guard_left_20.6") or record.id.begins_with("hinge_rear_guard_left_20.6") or record.id in ["rope_exit_floor","wing_left_8.4_floor","wing_hinge_left_8.4_floor","outer_left_8.4_floor","rope_side_left_floor"]):continue
		var body=obstacle(Codec.to_vector(record.position),Codec.to_vector(record.size))
		if not record.parent.is_empty():body.reparent(blockout.groups[record.parent],false)
		body.set_meta("blockout_id",record.id)
		blockout.pieces[record.id]={"body":body,"spec":record}
	blockout._index_pieces()

func check_panel_clearance() -> void:
	var envelopes: Array[AABB]=[]
	for bank in access.get_children():
		if not bank is StaticBody3D or bank.position.y<10:continue
		for node in bank.get_children():
			if node is CollisionShape3D:envelopes.append(node.global_transform*node.shape.get_debug_mesh().get_aabb())
	for entry in access.controls():
		if entry.point.y>10:envelopes.append(entry.node.global_transform*entry.node.mesh.get_aabb())
	for phase in [0.0,.625,1.0]:
		blockout.apply_frames(access.frames_at({"20.6":phase}))
		var collisions=[]
		for piece in blockout.pieces.values():
			if not blockout.belongs_to(piece.spec.parent,["wing_left_20.6","wing_right_20.6"]):continue
			var bounds=piece.body.global_transform*AABB(-Codec.to_vector(piece.spec.size)/2,Codec.to_vector(piece.spec.size))
			if envelopes.any(func(box):return box.intersects(bounds)):collisions.append(piece.spec.id)
		expect(collisions.is_empty(),"Fixed upper panel and button envelopes clear complete authored leaves at phase "+str(phase)+": "+str(collisions))
	blockout.apply_frames(access.frames_at(access.values()))

func run() -> void:
	game=World.new();root.add_child(game)
	game.components=preload("res://scripts/component_interaction.gd").new(game);game.add_child(game.components)
	game.player_controller=Player.new(game);game.player_controller.make()
	game.desktop_input=preload("res://scripts/desktop_input.gd").new(game)
	game.targeting=preload("res://scripts/targeting.gd").new(game)
	blockout=Blockout.new();game.add_child(blockout)
	blockout.spec={"rope_stations":contract(),"groups":{},"access":{"levels":[8.4,20.6],"duration":1.0}}
	blockout.spec.elevators=JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop-layout.json")).workshop.elevators
	for level in [8.4,20.6]:
		for side in ["left","right"]:
			var id="wing_"+side+"_"+str(level)
			var frame={"parent":"","position":[5 if side=="left" else 21,level,24],"rotation_degrees":[0,0 if side=="left" else 180,0],"joint":"wing","side":side,"level":level}
			blockout.spec.groups[id]=frame
			var group=Node3D.new();blockout.add_child(group);group.transform=Blockout.authored_pose(frame);blockout.groups[id]=group;blockout.group_pieces[id]=[]
	access=Access.new();game.add_child(access);access.setup(game,blockout);game.equipment.register(access)
	rope=Rope.new();game.add_child(rope);rope.setup(game,blockout);game.equipment.register(rope)
	obstacle(Vector3(13,-.1,27),Vector3(30,.2,20))
	boarding_solids()
	check_panel_clearance()
	obstacle(Vector3(9.3,8.3,24.75),Vector3(2,.2,1))
	await frames(2)
	expect(rope.stations.size()==12 and rope.anchor(FRONT).is_equal_approx(Vector3(9.3,21.8,24.75)) and rope.anchor("front_r_13.4").is_equal_approx(Vector3(13.4,21.8,24.75)),"All twelve contract anchors resolve both mirrored leaf frames")
	game.player_controller.update_crouch(true,1)
	for id in ["front_l_11.9","front_l_12.6","front_r_13.4","front_r_14.1"]:
		rope.attachment=id;rope.physics(0)
		for offset in [-.17,0.0,.17]:
			place(Vector3(rope.anchor(id).x+offset,20.6,24.1))
			expect(not game.player.test_move(game.player.global_transform,Vector3(0,0,.8)),"Full active gate opening clears the capsule beside overlapping neighbour: "+id+" / "+str(offset))
	rope.attachment="";rope.physics(0)
	place(Vector3(9.3,20.6,24.1));await frames(1)
	access.request("upper_open");access.physics(.2)
	expect(access.channels["20.6"].value==0 and access.blocked_reason.contains("Step off"),"Unroped upper leaf rider holds a pending swing")
	access.request("upper_open")
	access.channels["8.4"].goal=1.0;access.channels.rear.goal=1.0
	access.physics(.2)
	expect(access.channels["20.6"].value==0 and access.channels["8.4"].value>0 and access.channels.rear.value>0,"Upper rider hold does not stop accepted lower access movement")
	place(Vector3(0,0,0));access.request("upper_close");access.physics(1)
	expect(access.front_closed("upper") and access.channels["8.4"].value==1 and access.channels.rear.value==1,"Independent upper request preserves both lower access goals")
	access.request("upper_open");access.request("lower_close");access.physics(1)
	expect(access.front_open("upper") and access.front_closed("lower") and access.validate(access.capture()).is_empty(),"Lower request preserves upper crossing and its snapshot is valid independently of mode")
	var crane=CraneOccupancy.new();game.add_child(crane);crane.equipment_id="service_crane";game.equipment.register(crane)
	access.request("lower_open");access.request("upper_close");access.physics(.2)
	expect(access.channels["20.6"].value==1 and access.blocked_reason=="Wait for the crane cables to clear the upper gantry." and access.channels["8.4"].value>0,"Stopped crane occupancy holds upper closing before the crane tick while lower access moves")
	crane.occupied=false;access.physics(1)
	expect(access.front_closed("upper") and access.front_open("lower"),"Pending upper close finishes once the crane is clear")
	crane.occupied=true;access.request("upper_open");access.physics(1)
	expect(access.front_open("upper"),"Crane occupancy never prevents upper leaves opening")
	crane.free()
	access.request("upper_close");access.request("lower_close");access.physics(1)
	# Real E/targeting route at the two fixed banks; supplied poses isolate the
	# control contract rather than asserting workshop walking or readability.
	place(Vector3(3.92,8.4,24.2));game.player_controller.update_crouch(false,1);await frames(1)
	expect(access.controls().size()==4 and rope.on_floor() and aim_panel("lower_open"),"Lower Open is targetable from its supported 8.4 m landing at normal reach")
	key(KEY_E,true);key(KEY_E,false);access.physics(1)
	expect(access.front_open("lower") and access.front_closed("upper"),"E at the 8.4 m panel opens only the lower front")
	expect(aim_panel("lower_close"),"Lower Close is targetable at normal reach")
	game.paused=true;key(KEY_E,true);key(KEY_E,false);access.physics(1)
	expect(access.front_open("lower") and access.request("lower_close").contains("Resume"),"Paused E and direct requests cannot move the lower front")
	game.paused=false;key(KEY_E,true);key(KEY_E,false);access.physics(1)
	expect(access.front_closed("lower") and access.front_closed("upper"),"Lower Close preserves the upper front")
	place(Vector3(3.92,20.6,24.2));await frames(1)
	expect(rope.on_floor() and aim_panel("upper_open"),"Upper panel stands beside a supported fixed landing and is normally targetable")
	rope.ropes[FRONT].deployed=true;rope.attachment=FRONT
	key(KEY_E,true);key(KEY_E,false);access.physics(.1)
	expect(access.blocked_reason==Rope.LEAF_REASON and game.hud.message==Rope.LEAF_REASON and access.channels["20.6"].value==0 and rope.ropes[FRONT].deployed,"Physical Open reports the named clipped-rope hold through normal interaction")
	rope.attachment="";access.request("upper_close");access.physics(.1)
	rope.ropes[FRONT]={"deployed":true,"length":6.0};rope.ropes["front_l_10.8"]={"deployed":true,"length":Rope.MIN_LENGTH}
	expect(access.request("upper_open").is_empty() and not rope.ropes[FRONT].deployed and not rope.ropes["front_l_10.8"].deployed,"Moving the upper gantry stows every free front rope")
	access.physics(.1)
	expect(access.blocked_reason.is_empty() and access.channels["20.6"].value>0,"Stowed ropes no longer hold the leaves")
	access.physics(1)
	var parked_crane=CraneOccupancy.new();game.add_child(parked_crane);parked_crane.equipment_id="service_crane";game.equipment.register(parked_crane)
	expect(aim_panel("upper_close"),"Upper Close button is targetable from its fixed landing")
	key(KEY_E,true);key(KEY_E,false);access.physics(.1)
	expect(access.blocked_reason.contains("crane cables") and game.hud.message.contains("crane cables") and access.channels["20.6"].value==1,"Physical Close reports the named stopped-crane occupancy hold through normal interaction")
	parked_crane.occupied=false;access.physics(1);parked_crane.free()
	place(Vector3(5.25,20.6,23.55));await frames(1)
	# The panel now faces the fixed landing; a leaf rider sees its back.
	# Supplied requests isolate the existing rider hold from panel targeting.
	expect(access.request("upper_open").is_empty(),"Upper Open accepts a pending trip with a leaf rider")
	access.physics(.1)
	expect(access.blocked_reason.contains("Step off") and access.channels["20.6"].value==0,"Upper rider still holds the accepted trip")
	place(Vector3(3.92,20.6,24.2));await frames(1);access.physics(1)
	expect(access.front_open("upper"),"Moving onto the fixed landing releases the pending upper swing")
	aim_panel("upper_close");key(KEY_E,true);key(KEY_E,false);access.physics(1)
	place(Vector3(9.3,20.6,24.1));await frames(1)
	var work=Work.new();game.add_child(work);work.game=game;work.equipment_id="work";game.equipment.register(work)
	work.handle=MeshInstance3D.new();work.handle.mesh=BoxMesh.new();work.add_child(work.handle);work.handle.position=Vector3(9.3,15.8,25.3)
	game.interaction_outline=preload("res://scripts/interaction_outline.gd").new();game.add_child(game.interaction_outline)
	var cue=Guidance.new();game.add_child(cue);cue.setup(game)
	place(Vector3(4.1,20.6,24.1));await frames(1);access.request("upper_open");access.physics(1)
	aim_panel("upper_close");cue.update()
	expect(cue.visible_controls.has(game.target.node),"Upper work cues the physical Close prerequisite while front ropes are unavailable")
	key(KEY_E,true);key(KEY_E,false);access.physics(1)
	rope.physics(0) # The workshop ticks rope fixtures after leaf motion.
	place(Vector3(9.3,20.6,24.1));await frames(1)
	game.camera.look_at(rope.fixtures[FRONT].clip.global_position);cue.update()
	expect(cue.visible_controls.has(rope.fixtures[FRONT].clip),"An upper manual control objective cues a visible rope station through shared guidance")
	await check_service_prediction()

	expect(not rope.gate_passable(FRONT) and game.player.test_move(game.player.global_transform,Vector3(0,0,.8)),"Unclipped gate is a real collision barrier")
	expect(aim("clip:"+FRONT),"Camera aim and ordinary reach target the walkway clip control")
	game.hud.message=""
	key(KEY_E,true);key(KEY_E,false)
	expect(rope.attached(),"E clips through the normal desktop and component interaction route")
	expect(game.hud.message.is_empty() and rope.status_text().contains("Q unclip"),"Successful clip keeps permanent rope status without a duplicate temporary toast")
	key(KEY_E,true);key(KEY_E,false)
	expect(game.hud.message.contains("Already clipped"),"Quiet clip success still reports interaction errors")
	expect(game.crouched,"Top clip uses the normal crouch shape beneath the authored davit")
	expect(rope.gate_passable(FRONT) and not game.player.test_move(game.player.global_transform,Vector3(0,0,.8)),"Only the attached station opens its gate")
	expect(not rope.gate_passable("front_l_10.8") and not rope.front_ropes_clear(),"Other gates remain guarded and occupied front line interlocks leaves")
	# Supplied off-edge pose isolates the movement mode; no automated walking.
	place(Vector3(9.3,20.6,25.05));await tick()
	expect(rope.hanging and absf(game.player.position.y-20.6)<.02,"Stepping beyond support locks height without free fall")
	expect(not rope.unclip().is_empty() and rope.attached(),"Hanging player cannot unclip")
	key(KEY_Q,true);key(KEY_Q,false)
	expect(rope.attached() and game.drops==0 and game.hud.message.contains("Land on a floor"),"Q with empty hands refuses an airborne unclip")
	game.hands.full=true
	key(KEY_Q,true);key(KEY_Q,false)
	expect(rope.attached() and game.drops==1,"Hanging with something in hand, Q is the hand's drop")
	game.hands.full=false;game.drops=0
	rope.attachment=""
	expect(rope.action_error("clip:"+FRONT).contains("floor"),"Airborne player cannot clip a station")
	rope.attachment=FRONT

	key(KEY_CTRL,true);await tick(10);key(KEY_CTRL,false)
	expect(game.player.position.y<17.7 and game.player.position.y>17.3 and not game.crouched,"Held Ctrl accelerates through roughly three metres in its first second")
	await check_acceleration()
	game.paused=true;key(KEY_CTRL,true)
	var paused_at=game.player.position;await tick(5)
	expect(game.player.position.is_equal_approx(paused_at),"Paused rope movement is locked despite held input")
	key(KEY_CTRL,false);game.paused=false
	var held: float=rope.ropes[FRONT].length;await tick(5)
	expect(absf(rope.ropes[FRONT].length-held)<.002,"Released descender locks length while the pendulum remains free")
	await check_swing(work)
	place(Vector3(9.3,15,24.75));await tick()
	game.target=work.controls()[0];game.camera.look_at(game.target.point)
	key(KEY_E,true);key(KEY_E,false)
	expect(work.operated==1,"Normal E interaction reaches a nearby connection while hanging")
	work.handle.position.x+=4;game.target=work.controls()[0]
	key(KEY_E,true);key(KEY_E,false)
	expect(work.operated==1,"Hanging never bypasses the normal camera reach limit")
	work.handle.position.x-=4
	var saved: Dictionary
	key(KEY_CTRL,true);await tick(90);key(KEY_CTRL,false)
	expect(not rope.hanging and absf(game.player.position.y-8.4)<.04 and rope.attached(),"Descending lands on an 8.4 metre deck still clipped")
	var landed=game.player.position
	place(landed+Vector3.UP*.3);await tick()
	expect(EquipmentRegistry.rider_floor(game)==null,"A hanging player above a deck is never carried as its rider")
	place(landed);await tick()

	key(KEY_Q,true);key(KEY_Q,false)
	expect(not rope.attached() and rope.ropes[FRONT].deployed and not rope.front_ropes_clear() and game.drops==0,"Q unclips on a floor and leaves a deployed rope interlocking leaves")
	key(KEY_Q,true);key(KEY_Q,false)
	expect(game.drops==1,"Q retains normal set-down behavior when not clipped to a rope")
	place(game.player.position+Vector3(.2,0,0))
	expect(aim("end:"+FRONT),"Hanging end can be aimed at from below within normal reach")
	game.hud.message="";game.components.attach_target()
	expect(rope.attached() and game.hud.message.is_empty(),"Clicking a hanging end also clips without a duplicate temporary toast")
	key(KEY_SPACE,true);await tick(15);key(KEY_SPACE,false)
	expect(rope.hanging and game.player.position.y>9.8,"Space ascends from the lower deck")
	saved=JSON.parse_string(JSON.stringify(rope.capture()));rope.apply(saved)
	expect(rope.validate(saved).is_empty() and JSON.parse_string(JSON.stringify(rope.capture()))==saved,"Hanging snapshot round-trips independently of grounded state")
	check_save_path("hanging")
	key(KEY_SPACE,true);await tick(130);key(KEY_SPACE,false)
	expect(absf(game.player.position.y-20.65)<.02 and absf(rope.ropes[FRONT].length-Rope.MIN_LENGTH)<.02,"Ascent stops below the anchor at the top boarding height")
	access.request("upper_open");access.physics(.1)
	expect(rope.gate_passable(FRONT) and access.blocked_reason==Rope.LEAF_REASON,"Waiting leaf trip keeps the occupied gate open for the player's return")
	access.request("upper_close");access.request("lower_close")
	# Return pose supplied; capsule drops onto real walkway without teleport in mode.
	place(Vector3(9.3,20.6,24.2));await tick();expect(rope.unclip().is_empty(),"Top walkway supports landing and unclipping")
	expect(not rope.ropes[FRONT].deployed,"An end left within a person's height of its davit stows on unclip")
	expect(access.request("upper_open").is_empty(),"A pending leaf trip is accepted")
	access.physics(.1)
	expect(access.blocked_reason.contains("Step off") and access.channels["20.6"].value==0,"The stowed rope's leaf trip still waits for its unroped rider to leave")
	place(Vector3(0,0,0));await frames(1)
	access.physics(1)
	expect(rope.front_ropes_clear() and not access.moving and access.channels["20.6"].value==1,"Recalled ropes release the pending leaf motion")
	var closed=Vector3(9.3,21.8,24.75)
	expect(rope.anchor(FRONT).distance_to(closed)>1,"Station anchor follows a changed leaf transform")
	expect(not rope.action_error("clip:"+FRONT).is_empty(),"Open leaf never offers rappelling")
	access.request("upper_close");access.request("lower_close");access.physics(1)
	# Ground limit and rear station path are isolated from the front landing.
	place(Vector3(11,20.6,30.8));await tick()
	expect(aim("clip:"+REAR) and rope.request("clip:"+REAR).is_empty() and rope.front_ropes_clear(),"Rear boom control is within walkway reach and does not interlock leaves")
	# Direct collision-resolved transfers under the real authored boom, not a
	# workshop walking/reach campaign. The standing capsule must hit it first.
	place(Vector3(11,20.6,30.7));game.player_controller.update_crouch(false,1)
	expect(game.player.test_move(game.player.global_transform,Vector3(0,0,-2.4)),"Authored rear boom blocks a standing boarding capsule")
	await tick()
	game.player_controller._rope_move(Vector3(0,0,-2.4))
	expect(game.crouched and absf(game.player.position.z-28.3)<.01,"Normal crouch shape transfers beneath the two metre rear boom")
	key(KEY_CTRL,true);await tick(10);key(KEY_CTRL,false)
	expect(game.player.position.y<19.65 and not game.crouched,"Rear descent clears the boom and returns to ordinary standing clearance")
	key(KEY_SPACE,true);await tick(12);key(KEY_SPACE,false)
	expect(game.crouched and absf(game.player.position.y-20.65)<.02,"Rear ascent ducks before the authored boom and reaches boarding height")
	var boarding_snapshot=JSON.parse_string(JSON.stringify(rope.capture()))
	place(Vector3(0,0,0));game.player_controller.update_crouch(false,1)
	rope.apply(boarding_snapshot);place(Vector3(11,20.65,28.3))
	expect(game.crouched and not game.player.test_move(game.player.global_transform,Vector3(0,0,2.4)),"Rope restore initializes crouch before placing the player beneath the boom")
	game.player_controller._rope_move(Vector3(0,0,2.4));await tick()
	expect(rope.on_floor() and rope.unclip().is_empty(),"Rear return reaches the walkway and permits normal unclipping")
	place(Vector3(11,20.6,30.8));await tick();rope.request("clip:"+REAR)
	place(Vector3(11,19,28.3));await tick();key(KEY_CTRL,true);await tick(210);key(KEY_CTRL,false)
	expect(rope.on_floor() and absf(game.player.position.y)<.04 and rope.ropes[REAR].length<=rope.max_length(REAR),"Descent stops at the ground and maximum line length")
	var platform=obstacle(Vector3(11,.15,28.3),Vector3(1,.3,1));platform.reparent(work,true)
	place(Vector3(11,.3,28.3));await frames(2);await tick()
	expect(rope.travel_error("work",.3,.4).contains("Unclip"),"Existing travel guard pauses a grounded clipped platform rider")
	rope.unclip()
	expect(rope.travel_error("work",.3,.4).is_empty(),"Unclipping releases the platform travel guard")
	var valid: Dictionary=rope.capture()
	for corrupt in ["station","length","nan","stowed","version","identity"]:
		var invalid=valid.duplicate(true)
		match corrupt:
			"station":invalid.attachment="missing"
			"length":invalid.ropes[REAR].length=999
			"nan":invalid.ropes[REAR].length=NAN
			"stowed":invalid.attachment=FRONT
			"version":invalid.version=1
			"identity":invalid.ropes.erase(FRONT)
		expect(not rope.validate(invalid).is_empty(),"Invalid snapshot rejected: "+corrupt)
	game.hud.browser.free();game.free();await frames(1)
	var passed=checks.all(func(c):return c.passed)
	print("ROPE_ACCESS ","PASS " if passed else "FAIL ",checks.size()," checks")
	quit(0 if passed else 1)

## Real capsule dynamics in free space and against a surface, at supplied poses.
func check_swing(work: Work) -> void:
	var origin=Vector3(9.3,11.8,24.75) # nine metre harness radius
	place(origin);rope.hanging=true;rope.reset_motion()
	var initial_length: float=rope.ropes[FRONT].length
	# Holding one direction only leans the bob; range comes from pumping.
	var held_peak=0.0
	game.scripted_controls[KEY_D]=true
	for i in 360:
		await tick(1,1.0/60)
		held_peak=maxf(held_peak,rope.horizontal(game.player.position-rope.anchor(FRONT)).length())
	game.scripted_controls.clear()
	print("SWING_HOLD peak_6s=",held_peak)
	expect(held_peak>.3 and held_peak<1.2,"Holding one direction leans and sways but cannot reach the cap")
	place(origin);rope.reset_swing();rope.reset_motion();await tick(1,1.0/60)
	var peak=0.0
	var peak_two=0.0
	var max_rise=0.0
	var reached_cap=-1.0
	for i in 600:
		# Pump in the direction of motion, reversing after each turning point.
		var right: bool=rope.swing_velocity.x>=0
		game.scripted_controls[KEY_D]=right;game.scripted_controls[KEY_A]=not right
		await tick(1,1.0/60)
		var offset: float=rope.horizontal(game.player.position-rope.anchor(FRONT)).length()
		peak=maxf(peak,offset)
		max_rise=maxf(max_rise,game.player.position.y-origin.y)
		if i<120:peak_two=maxf(peak_two,offset)
		if offset>Rope.SWING_CAP-.01 and reached_cap<0:reached_cap=(i+1)/60.0
		if offset>Rope.SWING_CAP+.002:expect(false,"Swing exceeded cap at tick "+str(i))
	game.scripted_controls.clear()
	print("SWING_TUNING peak_2s=",peak_two," peak_10s=",peak," cap_seconds=",reached_cap)
	expect(peak_two<Rope.SWING_CAP-.1 and peak>Rope.SWING_CAP-.01 and reached_cap>=2.5 and reached_cap<=6,"Pumping with the swing reaches the cap in about a swing, not at once")
	expect(absf(rope.ropes[FRONT].length-initial_length)<.01 and max_rise>.08,"Swing follows an upward arc at fixed harness radius")
	var crossings=0
	var previous=game.player.position.x-origin.x
	for i in 240:
		await tick(1,1.0/60)
		var offset=game.player.position.x-origin.x
		if offset*previous<0:crossings+=1
		previous=offset
	print("SWING_SETTLE offset_4s=",rope.horizontal(game.player.position-origin).length())
	expect(rope.horizontal(game.player.position-origin).length()<.12 and rope.swing_velocity.length()<.2,"Released swing settles near plumb within four seconds")
	expect(crossings>0,"Released pendulum overshoots plumb instead of sliding to a stop")
	place(Vector3(11.8,3,24.75));await tick(240,1.0/60)
	expect(rope.horizontal(game.player.position-rope.anchor(FRONT)).length()<.12,"A long rope near the ground also settles within four seconds")
	# Mouse yaw chooses the pumping frame; camera pitch remains free.
	place(origin);game.player.rotation.y=PI/2;game.camera.rotation.x=.7
	key(KEY_W,true);await tick(30,1.0/60);key(KEY_W,false)
	expect(game.player.position.x<origin.x-.05 and absf(game.player.position.z-origin.z)<.01 and is_equal_approx(game.camera.rotation.x,.7),"W pumps along horizontal camera facing without taking over mouse look")
	game.player.rotation.y=0;game.camera.rotation=Vector3.ZERO
	# Change length at a nonzero angle from rest: a tap follows that radius.
	place(origin+Vector3(1.5,0,0));rope.reset_motion()
	for code in [KEY_SPACE,KEY_CTRL]:
		var before: Vector3=game.player.position
		var normal=(before+Vector3.UP*Rope.HARNESS-rope.anchor(FRONT)).normalized()
		var length: float=rope.ropes[FRONT].length
		key(code,true);await tick(1,.05);key(code,false)
		var after=(game.player.position+Vector3.UP*Rope.HARNESS-rope.anchor(FRONT)).normalized()
		expect(absf(absf(rope.ropes[FRONT].length-length)-.03)<.003 and after.distance_to(normal)<.01 and game.player.position.distance_to(before)<.05,"Mid-swing rappel tap changes length along the same angle without a jump: "+str(code))
	key(KEY_D,true);await tick(12,1.0/60)
	var frozen: Vector3=game.player.position
	var speed: Vector3=rope.swing_velocity
	game.paused=true;await tick(6);game.paused=false
	expect(game.player.position.is_equal_approx(frozen) and rope.swing_velocity.is_equal_approx(speed),"Pause freezes swing position and momentum")
	var modal=RefCounted.new();game.desktop_input.push_modal(modal);await tick(6);game.desktop_input.pop_modal(modal)
	expect(game.player.position.is_equal_approx(frozen),"Modal input freezes swinging")
	key(KEY_D,false)
	var saved: Dictionary=JSON.parse_string(JSON.stringify(rope.capture()))
	var world={"player":[frozen.x,frozen.y,frozen.z,0.0,0.0]}
	expect(saved.version==2 and rope.validate(saved,null,world).is_empty() and speed.length()>.1,"New snapshot validates a swing pose without serializing velocity")
	rope.apply(saved)
	expect(rope.swing_velocity.is_zero_approx() and game.player.position.is_equal_approx(frozen) and JSON.parse_string(JSON.stringify(rope.capture()))==saved,"Swing restore keeps the saved position at rest")
	check_save_path("swing")
	var invalid=world.duplicate(true);invalid.player[0]=rope.anchor(FRONT).x+Rope.SWING_CAP+.2
	expect(not rope.validate(saved,null,invalid).is_empty(),"Snapshot rejects a player outside the swing envelope")
	# First contact must stop inward velocity; holding the same direction pins
	# the capsule so normal E/placement need no timing at the swing extreme.
	place(origin);rope.reset_motion()
	# Within a held lean; a farther surface needs pumping first.
	var wall=obstacle(Vector3(10.0,12.7,24.75),Vector3(.2,6,4))
	await frames(2)
	key(KEY_D,true);await tick(120,1.0/60)
	var braced: Vector3=game.player.position
	expect(braced.x>9.6 and braced.x<9.641 and rope.swing_velocity.is_zero_approx() and not rope.brace_normal.is_zero_approx(),"Surface contact stops inward motion without penetrating and establishes a brace")
	await tick(60,1.0/60)
	expect(game.player.position.distance_to(braced)<.001,"Holding into the surface pins the working pose")
	var handle_at=work.handle.position
	work.handle.position=braced+Vector3(.15,1.2,.6)
	game.target=work.controls()[0];game.camera.look_at(game.target.point)
	key(KEY_E,true);key(KEY_E,false);await tick(20,1.0/60)
	expect(work.operated==1 and game.player.position.distance_to(braced)<.001,"Normal E interaction works from a held brace without timing the swing")
	work.handle.position=handle_at;work.operated=0
	key(KEY_D,false);await tick(60,1.0/60)
	expect(game.player.position.x<braced.x-(braced.x-origin.x)/3.0 and rope.brace_normal.is_zero_approx(),"Releasing the brace swings back toward plumb")
	key(KEY_D,true);await tick(120,1.0/60)
	var pinned: Vector3=game.player.position
	wall.free();await frames(2);await tick(60,1.0/60);key(KEY_D,false)
	expect(rope.brace_normal.is_zero_approx() and game.player.position.distance_to(pinned)>.01,"Removing a brace surface releases the player instead of pinning empty air")
	place(origin);rope.reset_motion()

func check_acceleration() -> void:
	var original: Vector3=game.player.position
	for code in [KEY_CTRL,KEY_SPACE]:
		place(Vector3(9.3,16,24.75));rope.reset_motion();await tick()
		var start=game.player.position.y
		key(code,true);await tick();key(code,false)
		var tap=absf(game.player.position.y-start)
		expect(absf(tap-.06)<.003,"A 100 ms "+str(code)+" tap moves only six centimetres")
		await tick()
		start=game.player.position.y
		key(code,true);await tick();key(code,false);await tick()
		expect(absf(absf(game.player.position.y-start)-tap)<.003,"Repeated taps restart at precision speed")
		key(code,true);await tick(7)
		start=game.player.position.y;await tick()
		expect(absf(absf(game.player.position.y-start)-.45)<.003,"Held ascent/descent reaches 4.5 m/s within 0.7 seconds")
		key(code,false);start=game.player.position.y;await tick(3)
		expect(absf(game.player.position.y-start)<.002,"Release locks height immediately without coasting")
	# Reverse a held run without an intervening idle physics tick.
	place(Vector3(9.3,16,24.75));rope.reset_motion()
	key(KEY_SPACE,true);await tick(7);key(KEY_SPACE,false)
	var start=game.player.position.y
	key(KEY_CTRL,true);await tick();key(KEY_CTRL,false);await tick()
	expect(absf(start-game.player.position.y-.06)<.003,"Direction reversal starts with a fresh slow tap")
	var travelled: Array=[]
	for hz in [30,120]:
		place(Vector3(9.3,16,24.75));rope.reset_motion()
		key(KEY_CTRL,true);await tick(int(hz*.8),1.0/hz);key(KEY_CTRL,false);await tick()
		travelled.append(16-game.player.position.y)
	expect(absf(travelled[0]-travelled[1])<.003,"Acceleration travels the same distance at 30 and 120 physics ticks per second")
	# Restore resets speed without changing the saved at-rest rope pose/schema.
	key(KEY_CTRL,true);await tick(7)
	var saved: Dictionary=rope.capture();rope.apply(saved)
	start=game.player.position.y;await tick();key(KEY_CTRL,false);await tick()
	expect(absf(start-game.player.position.y-.06)<.003,"Reloading a rope snapshot restarts at precision speed")
	place(original);rope.reset_motion();await tick()

func check_save_path(label: String) -> void:
	var save=Save.new(game,"user://rope-access-test.json")
	game.equipment.steady_player=Transform3D.IDENTITY
	var snapshot: Dictionary=JSON.parse_string(JSON.stringify(save.snapshot()))
	expect(save._check(snapshot).is_empty() and Vector3(snapshot.player[0],snapshot.player[1],snapshot.player[2]).distance_to(game.player.position)<.001,"Save uses current hanging pose instead of stale rider pose: "+label)
	var expected: Vector3=game.player.position
	place(Vector3(0,0,0));rope.attachment="";rope.hanging=false
	game.equipment.apply_saved(snapshot.equipment)
	save._player=snapshot.player;save.place_player()
	expect(rope.attached() and game.player.position.distance_to(expected)<.001,"Equipment and player restore preserve attachment: "+label)
	var invalid=snapshot.duplicate(true);invalid.equipment.rope_access.ropes[FRONT].length=999
	var before=rope.capture()
	save.write(invalid)
	expect(not save.load_saved() and not FileAccess.file_exists(save.path) and rope.capture()==before,"Invalid rope save is deleted before live state changes: "+label)
	invalid=snapshot.duplicate(true);invalid.equipment.workshop_access.channels["20.6"].value=1.0
	expect(not save._check(invalid).is_empty(),"Save rejects a deployed front line with an open leaf: "+label)
	invalid=snapshot.duplicate(true);invalid.player=[]
	expect(not save._check(invalid).is_empty(),"Attached rope save cannot omit the player pose: "+label)
	invalid=snapshot.duplicate(true);invalid.equipment.workshop_access.channels="malformed"
	expect(not save._check(invalid).is_empty(),"Malformed leaf state is rejected without dereferencing it: "+label)
	Save.delete(save.path)
