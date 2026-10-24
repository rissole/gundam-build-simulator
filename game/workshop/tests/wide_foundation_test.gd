extends "res://tests/kit/harness.gd"
## Integration of the new spatial/access foundation into the actual M3 profile.
## This is deliberately not a played journey or complete milestone acceptance.
const Store = preload("res://scripts/save_store.gd")
func _initialize() -> void:call_deferred("run")

func run() -> void:
	var game = await boot_profile("leg_bay_m3")
	expect(is_instance_valid(game.leg_layout.blockout),"M3 uses authored wider-workshop world")
	expect(game.equipment.get_equipment("hip_lift")==null,"old single-hip elevator replaced")
	for id in ["left_lift","right_lift","left_shelf","right_shelf","workshop_access"]:
		expect(game.equipment.get_equipment(id)!=null,"M3 registers "+id)
	expect(game.model.support_definitions.has("left_shelf_0") and game.model.support_definitions.has("right_shelf_0"),"both physical shelf support sets declared")
	expect(game.saves.validate(game.saves.capture()).is_empty(),"initial wider scene snapshot validates")
	var access = game.equipment.get_equipment("workshop_access")
	var error: String = access.request_mode("leg")
	expect(error.is_empty(),"actual scene can request rail access configuration: "+error)
	access.physics(2);access.request("stop")
	var snapshot: Dictionary = game.saves.capture()
	expect(game.saves.validate(snapshot).is_empty(),"actual interrupted access snapshot validates")
	var path = "/tmp/wide-foundation-test-"+str(Time.get_ticks_usec())+".json"
	var write_error: String = Store.write(path,game.saves.fingerprint,snapshot,false)
	expect(write_error.is_empty(),"atomic interrupted session write: "+write_error)
	if not write_error.is_empty():_bad_json(snapshot,"session");game.free();print("WIDE_FOUNDATION FAIL ",checks.size()," checks");quit(1);return
	var fingerprint: String = game.saves.fingerprint
	game.free();await frames(2)
	game = await boot_profile("leg_bay_m3")
	var read: Dictionary = Store.read(path,fingerprint)
	expect(read.ok and game.saves.validate(read.payload).is_empty(),"fresh M3 instance accepts saved foundation")
	expect(game.saves.apply_snapshot(read.payload),"fresh scene restores supported session")
	access = game.equipment.get_equipment("workshop_access")
	var expected: Dictionary = snapshot.world.equipment.workshop_access
	var equivalent: bool = not access.moving and access.requested_mode==expected.mode and access.arm_services_stowed==expected.arm_services_stowed
	for key in expected.channels:
		equivalent = equivalent and is_equal_approx(access.channels[key].value,expected.channels[key].value) and is_equal_approx(access.channels[key].goal,expected.channels[key].goal)
	expect(equivalent,"stopped access phase survives disk and fresh scene")
	expect(game.paused,"session restore starts paused")
	DirAccess.remove_absolute(path)
	var passed = checks.all(func(check):return check.passed)
	write_evidence("res://verification/wide-foundation.json",{"scope":"partial implementation integration; no journey acceptance","checks":checks})
	print("WIDE_FOUNDATION ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)

func _bad_json(value: Variant, path: String) -> void:
	if value is Dictionary:
		for key in value:
			if not key is String:print("BAD_JSON_KEY ",path," / ",key," type ",type_string(typeof(key)))
			_bad_json(value[key],path+"."+str(key))
	elif value is Array:
		for i in range(value.size()):_bad_json(value[i],path+"["+str(i)+"]")
	elif not WorkshopSaveStore._json_value(value):print("BAD_JSON_VALUE ",path," / ",value," type ",type_string(typeof(value)))
