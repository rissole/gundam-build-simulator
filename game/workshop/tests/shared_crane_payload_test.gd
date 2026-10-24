extends "res://tests/kit/harness.gd"
## M2 preservation through model-supplied rig states and actual crane movement.
var game: Node
var crane: Node
func _initialize() -> void:call_deferred("run")

func command(action: String) -> bool:
	var error: String=crane.request(action)
	expect(error.is_empty(),"M2 crane accepts "+action+": "+error)
	if not error.is_empty():return false
	for tick in range(300):
		if not crane.moving:break
		crane.physics(.1)
		if not crane.blocked_reason.is_empty():break
	var okay: bool=not crane.moving and crane.blocked_reason.is_empty()
	expect(okay,"M2 crane completes "+action+": "+crane.blocked_reason)
	return okay

func run() -> void:
	game=await boot_profile("leg_bay_crane");crane=game.equipment.get_equipment("service_crane")
	if not command("go:source") or not command("down"):finish();return
	var state: Dictionary=crane.capture()
	for i in range(crane.END_IDS.size()):state.endpoints[crane.END_IDS[i]]={"state":"attached","point":crane.POINT_IDS[i]}
	expect(crane.required_ends==2 and crane.validate(state,game.model).is_empty(),"M2 preserves two-end source rigging")
	crane.apply(state)
	if not command("up") or not command("go:receiver") or not command("down"):finish();return
	expect(game.model.assemblies.left_leg.slots.spar==crane.uid and not crane.secured(),"M2 seats its physical beam without automatic fastening")
	expect(not crane.request("detach:magnet_a").is_empty(),"M2 still blocks premature release")
	Staging.fill(game,"left_leg",crane.fastener_slots)
	expect(crane.secured() and crane.hardware_count()==8,"ordinary model washer/bolt slots establish M2 retention")
	state=crane.capture()
	for id in crane.END_IDS:state.endpoints[id]={"state":"stowed","point":""}
	expect(crane.validate(state,game.model).is_empty(),"retained M2 beam can release both crane ends")
	crane.apply(state)
	if not command("up") or not command("go:park"):finish();return
	var snapshot: Dictionary=game.saves.capture()
	expect(game.saves.validate(snapshot).is_empty(),"shared crane changes preserve valid M2 session")
	game.free();await frames(2)
	game=await boot_profile("leg_bay_crane");crane=game.equipment.get_equipment("service_crane")
	expect(game.saves.apply_snapshot(snapshot) and crane.secured(),"M2 beam identity and retention restore in a fresh scene")
	finish()

func finish() -> void:
	var passing=checks.all(func(check):return check.passed)
	write_evidence("res://verification/shared-crane-payload.json",{"scope":"M2 mechanical preservation; no walking or access checks","checks":checks})
	print("SHARED_CRANE_PAYLOAD ","PASS " if passing else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passing else 1)
