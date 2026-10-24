class_name EquipmentRegistry
extends RefCounted
## Workshop equipment in interaction order. Every aggregate visits that order,
## so the first registered answer wins.
const Codec = preload("res://scripts/pose_codec.gd")
var _items: Array = []

func register(equipment: Node) -> void:
	if get_equipment(equipment.equipment_id) != null:
		push_error("Duplicate equipment: "+equipment.equipment_id)
		return
	_items.append(equipment)

func get_equipment(id: String) -> Node:
	for equipment in all():
		if equipment.equipment_id == id:return equipment
	return null

func all() -> Array:
	_items = _items.filter(func(equipment):return is_instance_valid(equipment))
	return _items.duplicate()

func ids() -> Array:
	return all().map(func(equipment):return equipment.equipment_id)

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for equipment in all():result.append_array(equipment.controls())
	return result

func physics(delta: float) -> void:
	for equipment in all():equipment.physics(delta)

func access_error(owner: String) -> String:
	for equipment in all():
		var error: String = equipment.access_error(owner)
		if not error.is_empty():return error
	return ""

func placement_error(owner: String, sid: String) -> String:
	for equipment in all():
		var error: String=equipment.placement_error(owner,sid)
		if not error.is_empty():return error
	return ""

func undo(owner: String) -> Dictionary:
	for equipment in all():
		var result: Dictionary = equipment.undo(owner)
		if result.get("handled",false):return result
	return {"handled":false,"error":""}

## The handling equipment's status is included for confirmation feedback.
func drop() -> Dictionary:
	for equipment in all():
		var result: Dictionary = equipment.drop()
		if result.get("handled",false):
			result["status"] = equipment.status_text()
			return result
	return {"handled":false,"error":""}

func busy_reason(subject: String, except_id: String = "") -> String:
	for equipment in all():
		if equipment.equipment_id == except_id:continue
		var reason: String = equipment.busy_reason(subject)
		if not reason.is_empty():return reason
	return ""

func travel_error(carrier_id: String, from: float, to: float) -> String:
	for equipment in all():
		if equipment.equipment_id == carrier_id:continue
		var error: String = equipment.travel_error(carrier_id,from,to)
		if not error.is_empty():return error
	return ""

func carrier_moved(carrier_id: String) -> void:
	for equipment in all():
		if equipment.equipment_id != carrier_id:equipment.carrier_moved(carrier_id)

func payload_holder() -> Node:
	for equipment in all():
		if not equipment.hand_payload().is_empty():return equipment
	return null

func capture() -> Dictionary:
	var result = {}
	for equipment in all():result[equipment.equipment_id] = equipment.capture()
	return result

func validate(data: Variant, candidate: AssemblyModel, world: Dictionary) -> Array[String]:
	if not Codec.same_keys(data,ids()):return ["Equipment identities changed."]
	for equipment in all():
		if not data[equipment.equipment_id] is Dictionary:return ["Invalid "+equipment.equipment_id+" snapshot."]
		var errors: Array[String] = equipment.validate(data[equipment.equipment_id],candidate,world)
		if not errors.is_empty():return errors
	return []

func apply(data: Dictionary) -> void:
	for equipment in all():equipment.apply(data[equipment.equipment_id])
