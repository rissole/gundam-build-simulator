class_name WorkshopEquipment
extends Node3D
## Base for workshop equipment. Defaults describe equipment that offers no
## controls, blocks nothing, holds nothing and saves nothing.
## Constants cannot be redeclared in GDScript subclasses; override save_version().
const SAVE_VERSION = 1
var game: Node
var equipment_id: String = ""
var motion_obstruction: Dictionary = {}
## Reason given to other requesters while this equipment's payload is in hand.
var hand_payload_hint: String = ""
## Reason given when this equipment needs free hands and they are occupied.
var hands_full_hint: String = "Set down the component in your hands first."
## Whether a click operates controls; E always does.
var click_operates: bool = true

func save_version() -> int:return SAVE_VERSION
func controls() -> Array[Dictionary]:return []
func action_error(_action: String) -> String:return "Unknown equipment control."
func request(action: String) -> String:return action_error(action)
func status_text() -> String:return ""
## Manual objectives: command names this machine understands, their player label,
## its live comparable state and the state a completed objective leaves.
func manual_commands() -> Array:return []
func command_label(_action: String, _task: String = "") -> String:return ""
func manual_subject(_objective: Dictionary) -> String:return ""
func manual_hint(_objective: Dictionary) -> String:return ""
func manual_state() -> Dictionary:return {}
func manual_effect(_objective: Dictionary) -> Dictionary:return {}
func manual_count(_objective: Dictionary) -> Vector2i:return Vector2i(-1,-1)
func manual_proves(_condition: Dictionary) -> bool:return false
## Physical controls for one typed manual objective. Machines map grouped or
## abstract commands to their existing local actions; English labels are never IDs.
func manual_control_actions(objective: Dictionary) -> Array:
	return [str(objective.get("command",""))]

func manual_control_entries(objective: Dictionary) -> Array[Dictionary]:
	var actions := manual_control_actions(objective)
	var result: Array[Dictionary] = []
	for entry in controls():
		if not actions.has(str(entry.get("manual_command",entry.action))):continue
		if action_error(str(entry.action)).is_empty():result.append(entry)
	return result

## Guided machines share the crane's real access console for console commands.
func manual_console_entries(command: String) -> Array[Dictionary]:
	var crane = game.equipment.get_equipment("service_crane")
	if crane==null or crane._guide()!=self:return []
	return crane.manual_control_entries({"op":"operate","command":"guide:"+command})

func physics(_delta: float) -> void:pass
func placement_error(_owner: String, _slot: String) -> String:return ""
func access_error(_owner: String) -> String:return ""
func undo(_owner: String) -> Dictionary:return {"handled":false,"error":""}
func hand_payload() -> String:return ""
func drop() -> Dictionary:return {"handled":false,"error":""}
func busy_reason(_subject: String) -> String:return ""
func travel_error(_carrier_id: String, _from: float, _to: float) -> String:return ""
func carrier_moved(_carrier_id: String) -> void:pass
func capture() -> Dictionary:return {}
## Whether a save takes this machine halted where it is instead of at its last
## stop: for machines whose motion the model and other machines follow mid-move.
func saves_in_motion() -> bool:return false
func validate(_data: Variant, _candidate: AssemblyModel = null, _world: Dictionary = {}) -> Array[String]:return []
func apply(_data: Dictionary) -> void:pass

## Whether the player standing on `body` rides this equipment. By default every
## body under this node moves with it.
func carries(body: CollisionObject3D) -> bool:return is_ancestor_of(body)

## The player while standing on, or hopping just above, a body this moves.
## The registry carries a rider and their hand load with that body.
func rider() -> CharacterBody3D:
	var floor = EquipmentRegistry.rider_floor(game)
	return game.get("player") if floor != null and carries(floor) else null

## The component or build in the player's hands.
func carried_body() -> CollisionObject3D:return EquipmentRegistry.carried_body(game)

## Walking surfaces which can support loose cargo. Bounds are in the body frame.
func cargo_decks() -> Array[Dictionary]:return []

## The rider, their hand load and resting cargo: moving parts of this equipment's envelope,
## not obstacles to it.
func passengers() -> Array[CollisionObject3D]:
	var result: Array[CollisionObject3D] = []
	if rider() != null:
		result.append(game.player)
		var carried = carried_body()
		if carried != null:result.append(carried)
	var registry = game.get("equipment") if game != null else null
	if registry != null:result.append_array(registry.loose_passengers(self))
	return result

## `excluded` plus every passenger body.
func without_passengers(excluded: Array[RID]) -> Array[RID]:
	var result = excluded.duplicate()
	for body in passengers():MotionSweep.collect_rids(body,result)
	return result

## The registry finds the controller of any targeted entry through "controller".
func control_entry(node: Node3D, action: String, label: String, radius: float, extra: Dictionary = {}) -> Dictionary:
	var entry = {"type":"equipment","controller":self,"node":node,"action":action,"label":label,"radius":radius,"control_id":action}
	entry.merge(extra,true)
	return entry
