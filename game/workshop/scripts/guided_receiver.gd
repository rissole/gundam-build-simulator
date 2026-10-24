extends "res://scripts/equipment.gd"
## Protocol already consumed by service_crane; existing receivers remain unchanged.
## True while the receiver owns the seated load.
var active: bool = false
## Authored receiver/rig configuration, read by the crane's rig hook.
var spec: Dictionary = {}
## Optional deployed-rig fraction used by existing adjustable adapters.
var rig: float = 0.0
## Take ownership at the exact receiving contact pose, or return an error.
func accept() -> String:return "This receiver cannot accept a load."
## True when the crane may release its ends.
func secured(_state: Dictionary = {}, _model: AssemblyModel = null) -> bool:return false
## True when independent structural retention is complete.
func retained(_state: Dictionary = {}, _model: AssemblyModel = null) -> bool:return false
## Reject lowering/travel before receiver prerequisites are satisfied.
func receiving_error(_uid: String = "") -> String:return "This receiver is unavailable."
## Reject attaching/detaching one crane end when support would be unsafe.
func rig_error(_action: String, _point: String) -> String:return "This receiver cannot release rigging."
## Reject raising the crane at this connection.
func departure_error() -> String:return "This receiver cannot release the crane."
## Called before an allowed receiver departure.
func depart() -> void:pass
## Extra console commands, using the existing guide: action prefix.
func crane_options() -> Array[Dictionary]:return []
## Seated load pose while active, independent of the travelling crane.
func load_pose() -> Transform3D:return Transform3D.IDENTITY
## Crane beam pose at the receiving connection.
func beam_pose() -> Transform3D:return Transform3D.IDENTITY
## Observe end changes after the crane refreshes its rig.
func rig_changed() -> void:pass
## Check a crane snapshot against this receiver's support requirements.
func validate_crane(_crane: Dictionary, _model: AssemblyModel, _state: Dictionary = {}) -> Array[String]:return []
## request/action_error and capture/validate/apply inherit equipment's safe defaults.
