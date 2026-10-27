extends "res://scripts/equipment.gd"
## Manual-API double of workshop_access for isolated manual tests, with no
## geometry or motion. gantry_fronts_test keeps it identical to the real fronts.
const MANUAL_COMMANDS = ["upper_open","upper_close","lower_open","lower_close"]
var fronts = {"upper":{"value":0.0,"goal":0.0,"moving":false},"lower":{"value":0.0,"goal":0.0,"moving":false}}
var entries: Array[Dictionary] = []

func set_front(front: String, value: float, goal: float = -1, moving: bool = false) -> void:
	fronts[front] = {"value":value,"goal":value if goal < 0 else goal,"moving":moving}
func front_open(front: String) -> bool:
	return fronts[front].value==1.0 and fronts[front].goal==1.0 and not fronts[front].moving
func front_closed(front: String) -> bool:
	return fronts[front].value==0.0 and fronts[front].goal==0.0 and not fronts[front].moving
func manual_commands() -> Array:return MANUAL_COMMANDS
func manual_state() -> Dictionary:
	var closing=func(front):return fronts[front].goal==0.0 and fronts[front].value>0.0
	return {"upper_open":front_open("upper") or closing.call("upper"),"upper_closed":front_closed("upper"),"lower_open":front_open("lower") or closing.call("lower"),"lower_closed":front_closed("lower")}
func manual_effect(objective: Dictionary) -> Dictionary:
	var command: String=objective.get("command","")
	if command not in MANUAL_COMMANDS:return {}
	var front=command.get_slice("_",0);var open=command.ends_with("_open")
	# Both keys must be overwritten so a cumulative OPEN -> CLOSE sequence
	# cannot retain an impossible requirement for simultaneous open and closed.
	return {front+"_open":open,front+"_closed":not open}
func manual_subject(objective: Dictionary) -> String:
	return "Upper gantry" if str(objective.get("command","")).begins_with("upper_") else "Lower gantry"
func command_label(command: String, _task: String = "") -> String:return "Open" if command.ends_with("_open") else "Close"
func manual_hint(objective: Dictionary) -> String:
	return ("UPPER GANTRY panel at 20.6" if str(objective.get("command","")).begins_with("upper_") else "LOWER GANTRY panel at 8.4")+" m beside the left lift"
func manual_control_actions(objective: Dictionary) -> Array:return [objective.command]
func controls() -> Array[Dictionary]:return entries
func action_error(action: String) -> String:return "" if action in MANUAL_COMMANDS else "Unknown front control."
func request(action: String) -> String:
	var error=action_error(action)
	if error.is_empty():set_front(action.get_slice("_",0),1.0 if action.ends_with("_open") else 0.0)
	return error
