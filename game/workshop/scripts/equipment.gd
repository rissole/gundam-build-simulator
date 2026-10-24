class_name WorkshopEquipment
extends Node3D
## Base for workshop equipment. Defaults describe equipment that offers no
## controls, blocks nothing, holds nothing and saves nothing.
## Constants cannot be redeclared in GDScript subclasses; override save_version().
const SAVE_VERSION = 1
var game: Node
var equipment_id: String = ""
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
func validate(_data: Variant, _candidate: AssemblyModel = null, _world: Dictionary = {}) -> Array[String]:return []
func apply(_data: Dictionary) -> void:pass

## The registry finds the controller of any targeted entry through "controller".
func control_entry(node: Node3D, action: String, label: String, radius: float, extra: Dictionary = {}) -> Dictionary:
	var entry = {"type":"equipment","controller":self,"node":node,"action":action,"label":label,"radius":radius}
	entry.merge(extra,true)
	return entry
