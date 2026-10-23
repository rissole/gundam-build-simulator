class_name HandSlot
extends RefCounted
## The single answer to "what is in the player's hands": a model item or
## assembly, or an equipment payload such as a magnetic cable end.
const HANDS_FULL = "Set down the component in your hands first."
var game: Node

func _init(workshop: Node) -> void:
	game = workshop

func occupant() -> String:
	var held: String = game.model.held_item()
	if not held.is_empty():return held
	for id in game.model.assemblies:
		if game.model.assemblies[id].location == "held":return id
	var holder = payload_holder()
	return holder.hand_payload() if holder != null else ""

func occupied() -> bool:
	return not occupant().is_empty()

func payload_holder() -> Node:
	return game.equipment.payload_holder()

## Why `requester_id` cannot take something into hand now, or "".
func error(requester_id: String = "") -> String:
	var holder = payload_holder()
	if holder != null and holder.equipment_id != requester_id:return holder.hand_payload_hint
	if game.model.hands_occupied():
		var requester = game.equipment.get_equipment(requester_id)
		return requester.hands_full_hint if requester != null else HANDS_FULL
	return ""
