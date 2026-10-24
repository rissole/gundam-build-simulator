extends "res://tests/kit/harness.gd"
func _initialize() -> void:
	var zones=preload("res://scripts/zone_register.gd").new(["limb_station"])
	expect(zones.holder("limb_station").is_empty(),"declared zone starts empty")
	expect(not zones.claim("unknown","cradle").is_empty(),"undeclared zones reject claims")
	expect(zones.claim("limb_station","cradle").is_empty(),"first holder claims the zone")
	expect(zones.claim("limb_station","cradle").is_empty(),"repeated claim is idempotent")
	expect(not zones.claim("limb_station","cassette").is_empty() and zones.holder("limb_station")=="cradle","conflicting claim preserves the holder")
	zones.release("limb_station","cassette")
	expect(zones.holder("limb_station")=="cradle","another holder cannot release the zone")
	zones.release("limb_station","cradle")
	expect(zones.claim("limb_station","cassette").is_empty(),"released zone accepts the next holder")
	print("ZONE_REGISTER PASS ",checks.size()," checks");quit()
