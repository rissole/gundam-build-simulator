extends RefCounted
## Transient occupancy; claim/release are idempotent for the same holder.
signal changed(zone: String)
var _holders: Dictionary = {}

func _init(zones: Array = []) -> void:
	for zone in zones:_holders[zone]=""

func claim(zone: String, claimant: String) -> String:
	if not _holders.has(zone):return "Unknown workshop zone: "+zone
	if claimant.is_empty():return "A zone claim needs a holder."
	if holder(zone)==claimant:return ""
	if not holder(zone).is_empty():return zone+" is occupied by "+holder(zone)+"."
	_holders[zone]=claimant;changed.emit(zone);return ""

func release(zone: String, claimant: String) -> void:
	if holder(zone)!=claimant or claimant.is_empty():return
	_holders[zone]="";changed.emit(zone)

func holder(zone: String) -> String:return _holders.get(zone,"")
