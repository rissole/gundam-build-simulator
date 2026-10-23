extends Node3D
var game: Node3D
var rail: Node3D
var shelf: Node3D
var crane: Node3D
func setup(workshop: Node3D) -> void:
	game = workshop
	if game.profile.staging == "leg_bay":preload("res://scripts/scenario_staging.gd").prepare(game)
	rail = preload("res://scripts/leg_rail.gd").new();add_child(rail);rail.setup(game,game.leg_layout)
	var lift: Node3D
	if game.has_equipment("hip_lift"):
		lift = preload("res://scripts/m2_access_lift.gd").new();game.add_child(lift)
		var levels: Array[float] = [.15,8.4]
		lift.setup(game,"hip",preload("res://scripts/leg_bay_layout.gd").LIFT_ORIGIN,Vector2(2.6,2.6),levels)
		lift.rotation.y = PI;game.access_lifts["hip"] = lift
	if game.has_equipment("lift_shelf"):
		shelf = preload("res://scripts/m2_lift_shelf.gd").new();add_child(shelf);shelf.setup(game,lift)
	if game.has_equipment("service_crane"):
		crane = preload("res://scripts/service_crane.gd").new();add_child(crane);game.m2_crane = crane;crane.setup(game,game.leg_layout,game.leg_layout.crane_contract())

func position_stock() -> void:
	# Ground stock feeds pockets and the lift's finite component shelf.
	var index = 0
	for kind in game.bins:
		if game.model.count_at(kind,"bin") == 0:
			game.bins[kind].hide()
			continue
		var node: Node3D = game.bins[kind]
		if node.get_parent() != game:node.reparent(game)
		node.global_position = Vector3(6.4+index*1.15,.7,20.7) if game.profile.trial == "retention" else Vector3(8.3+index*.9,.7,14.2)
		node.rotation = Vector3.ZERO
		game.box(game.leg_layout,Vector3(node.global_position.x,.245,node.global_position.z),Vector3(.8,.49,.55),game.material(Color("506971")),true)
		index += 1

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = rail.controls()
	if is_instance_valid(shelf):result.append_array(shelf.controls())
	if is_instance_valid(crane):result.append_array(crane.controls());result.append_array(crane.candidates())
	return result

func hand_error() -> String:
	if is_instance_valid(crane) and not crane.hand_payload().is_empty():return "Attach or Q-stow the held magnetic end first."
	return ""

func physics(delta: float) -> void:
	rail.physics(delta)
	if is_instance_valid(crane):crane.physics(delta)

func drop() -> bool:
	if is_instance_valid(crane) and (not crane.hand_payload().is_empty() or crane.console.is_open):
		var error: String = crane.cancel_hand();game.hud.toast(error if not error.is_empty() else crane.status_text(),error.is_empty());return true
	return false

func undo(owner: String) -> Dictionary:
	if is_instance_valid(crane) and owner == "left_leg":return crane.undo(owner)
	if is_instance_valid(shelf) and owner == "pelvis":
		var history: Array = game.model.assemblies.pelvis.history
		if history.is_empty():return {"handled":true,"error":"There is no retaining hardware to undo."}
		var sid: String = history.back().slot
		if sid.begins_with("ring/"):return {"handled":false}
		if sid == "ring_1":
			var error = equipment_access_error(owner)
			if error.is_empty() and game.model.hands_occupied():error = "Set down the component in your hands first."
			var point: Vector3 = game.components.slot_point(owner,sid)
			if error.is_empty() and game.camera.global_position.distance_to(point)>game.REACH:error = "Move within reach of the retaining half."
			if error.is_empty() and not game._visible(point,[game.runtime.node("pelvis")],true):error = "The retaining connection is obstructed."
			if not error.is_empty():return {"handled":true,"error":error}
			var uid: String = game.model.assemblies.pelvis.slots[sid]
			var pose: Transform3D = game.components.slot_pose(owner,sid)
			var result: Dictionary = game.model.undo(owner)
			if not result.ok:return {"handled":true,"error":result.error}
			game.components.sync(owner)
			error = game.model.carry_item(uid)
			assert(error.is_empty(),error)
			shelf._hold(uid,pose);game.hud.refresh()
			return {"handled":true,"error":""}
	return {"handled":true,"error":"The supplied construction stays assembled in this M2 example. Use rail Return after removing retention."}

func equipment_access_error(owner: String) -> String:
	if rail.moving and owner in ["left_leg","pelvis"]:return "Wait for the supported rail motion to stop."
	if is_instance_valid(shelf) and owner == "pelvis" and game.access_lifts.hip.moving:return "Wait for the lift to stop."
	if is_instance_valid(crane):return crane.equipment_access_error(owner)
	return ""

func capture() -> Dictionary:
	return {"version":2,"trial":game.profile.trial,"rail":rail.capture(),"shelf":shelf.capture() if is_instance_valid(shelf) else {},"crane":crane.capture() if is_instance_valid(crane) else {}}

func validate(data: Variant, candidate: AssemblyModel, _lifts: Dictionary) -> Array[String]:
	if not data is Dictionary or data.size()!=5:return ["Missing M2 example snapshot."]
	if not (data.get("version") is int or data.get("version") is float) or not data.get("trial") is String:return ["Invalid M2 example metadata."]
	if data.version != 2 or data.trial != game.profile.trial:return ["Unsupported M2 example snapshot."]
	for field in ["rail","shelf","crane"]:
		if not data.get(field) is Dictionary:return ["Missing M2 equipment snapshot."]
	var errors: Array[String] = rail.validate(data.rail,candidate)
	if not errors.is_empty():return errors
	if is_instance_valid(shelf):
		errors = shelf.validate(data.shelf,candidate)
		if not errors.is_empty():return errors
		if not data.crane.is_empty():return ["Unexpected crane in retainer example."]
	if is_instance_valid(crane):
		errors = crane.validate(data.crane,candidate)
		if not errors.is_empty():return errors
		if not data.shelf.is_empty() or not candidate.support_occupant("m2_lift_shelf_0").is_empty() or not candidate.support_occupant("m2_lift_shelf_1").is_empty():return ["Unexpected shelf cargo in crane example."]
	return []

func apply(data: Dictionary) -> void:
	rail.apply(data.rail)
	if is_instance_valid(shelf):shelf.apply(data.shelf)
	if is_instance_valid(crane):crane.apply(data.crane)
