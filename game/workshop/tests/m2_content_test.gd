extends SceneTree
## Authored-data/model seam only. Actual shelf/crane input and assistance are
## separately exercised by the equipment integration suites.
const Save = preload("res://scripts/save_model.gd")
var checks: Array = []
var manifests: Dictionary = {}

func document(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://assets/" + path))

func expect(value: bool, label: String) -> void:
	checks.append({"check": label, "passed": value})
	if not value: push_error(label)

func _initialize() -> void:
	call_deferred("run")

func trial(example: String, alternate_half: bool = false) -> Dictionary:
	var data = HeelAssemblyState.definition_data()
	for path in ["pitch-actuator-definitions.json", "leg-prototype-definitions.json", "m2-" + example + "-definitions.json"]:
		var overlay = document(path)
		data.parts.merge(overlay.parts, true)
		data.assemblies.merge(overlay.assemblies, true)
	var base = document("leg-prototype-content.json")
	var content = document("m2-" + example + "-content.json")
	var scenario = document("pitch-workshop.json")
	scenario.parent.location = "support:foot_carrier"
	scenario.parts.append_array(content.parts)
	scenario.parents = content.parents
	scenario.supports = base.supports.duplicate(true)
	for id in content.m2.remove_supports: scenario.supports.erase(id)
	scenario.supports.merge(content.supports, true)
	if alternate_half:
		for record in scenario.parts:
			if record.instance_id == "PV-120__001":
				record.instance_id = "PV-120__002"
				record.source_id = "PV-120__002"
	var model = AssemblyModel.new()
	var errors = model.configure(data, scenario)
	expect(errors.is_empty(), example + " overlay configures with real supports: " + str(errors))
	return {"model": model, "data": data, "content": content, "scenario": scenario}

func stage_slot(model: AssemblyModel, owner: String, sid: String) -> bool:
	if not model.assemblies[owner].slots[sid].is_empty(): return true
	var spec: Dictionary = model.slot_definition(owner, sid)
	if spec.has("assembly"):
		var child: String = {"heel_1": "pad_1", "heel_2": "pad_2", "pitch": "pitch", "foot": "foot"}.get(sid, "")
		if child.is_empty(): return false
		if spec.get("support_required", false):
			return model.install_supported(owner, sid, child, "foot_carrier").ok
		model.move_assembly(child, "held")
		return model.install(owner, sid, child).ok
	var uid: String = spec.get("pose_source", "")
	if not model.items.has(uid) or not model.items[uid].owner.is_empty():
		uid = ""
		for candidate in model.items:
			if model.items[candidate].kind == spec.accepts and model.items[candidate].owner.is_empty():
				uid = candidate
				break
	if uid.is_empty(): return false
	if spec.get("support_required", false):
		var from: String = model.items[uid].location.trim_prefix("support:")
		var target: String = spec.source_supports[0]
		if from != target:
			if not model.transfer_supported_item(uid, from, target).is_empty(): return false
		return model.install_supported(owner, sid, uid, target).ok
	if model.definitions.parts[spec.accepts].carry_class == "pocket":
		if model.items[uid].location != "pocket": model.transfer(spec.accepts, "bin", "pocket", uid)
	else: model.carry_item(uid)
	return model.install(owner, sid, uid).ok

func fill(model: AssemblyModel, owner: String, slot_ids: Array) -> bool:
	for pass_index in range(slot_ids.size()):
		var progress = false
		for sid in slot_ids:
			if not model.assemblies[owner].slots[sid].is_empty(): continue
			var spec = model.slot_definition(owner, sid)
			if not spec.requires.all(func(id): return not model.assemblies[owner].slots[id].is_empty()): continue
			if stage_slot(model, owner, sid): progress = true
		if not progress: break
	return slot_ids.all(func(sid): return not model.assemblies[owner].slots[sid].is_empty())

func stage(t: Dictionary) -> void:
	var model: AssemblyModel = t.model
	for owner in ["pad_1", "pad_2", "pitch"]:
		model.move_assembly(owner, "station:" + owner)
		expect(fill(model, owner, model.definitions.assemblies[model.assemblies[owner].definition].slots.keys()), "Supply existing construction: " + owner)
	expect(fill(model, "foot", model.definitions.assemblies.foot.slots.keys()), "Supply existing complete foot")
	expect(fill(model, "left_leg", t.content.m2.staged_slots.left_leg), "Stage authored left-leg graph boundary")

func manual_audit(t: Dictionary, example: String) -> void:
	var pages: Array = []
	for owner in ["left_leg", "pelvis"]:
		var counts: Dictionary = {}
		var recipe: Dictionary = t.data.assemblies[owner]
		for step in recipe.manual:
			var kinds: Dictionary = {}
			if step.view != "components":
				expect(step.slots.is_empty(), example + "/" + owner + " status page has no supplies")
				continue
			for sid in step.slots:
				counts[sid] = counts.get(sid, 0) + 1
				var spec: Dictionary = recipe.slots[sid]
				kinds[spec.accepts] = kinds.get(spec.accepts, 0) + 1
			pages.append({"owner": owner, "title": step.title, "slots": step.slots, "components": kinds})
		expect(counts.keys().size() == t.content.m2.playable_slots[owner].size() and counts.values().all(func(n): return n == 1) and t.content.m2.playable_slots[owner].all(func(sid): return counts.has(sid)), example + "/" + owner + " unique playable installation coverage")
	manifests[example] = {"pages": pages, "stock_count": t.model.items.size(), "staged_slots": t.content.m2.staged_slots, "playable_slots": t.content.m2.playable_slots}

func retention(alternate: bool) -> void:
	var t = trial("retention", alternate)
	var model: AssemblyModel = t.model
	var uid = "PV-120__002" if alternate else "PV-120__001"
	if not alternate: manual_audit(t, "retention")
	expect(model.items.size() == 170 and not model.items.has("PV-120__001" if alternate else "PV-120__002"), "Retention supplies exactly one compatible half; unused half is outside stock")
	stage(t)
	expect(model.milestone("left_leg", "structural_ready") and model.assemblies.left_leg.location == "support:m2_leg_rail", "Complete leg starts supported at its home rail")
	expect(model.assemblies.pelvis.slots.values().all(func(id): return id == ""), "No pelvis mounting or retention is secretly supplied")
	expect(model.install_supported("pelvis", "left_leg", "left_leg", "m2_leg_rail").ok, "Real rail is the supported pelvis source")
	expect(model.definitions.parts["pv-ring-half"].carry_class=="two_hand","Ring is an ordinary two-hand component")
	expect(model.carry_item(uid).is_empty(),"Ring collected from ground stock")
	expect(model.store_carried_item(uid,"m2_lift_shelf_0").is_empty(),"Same ring can be stored on real shelf")
	expect(model.carry_supported_item(uid,"m2_lift_shelf_0").is_empty(),"Stored ring returns to ordinary hands")
	expect(model.install("pelvis","ring_1",uid).ok,"Either equivalent held half fits representative ring_1")
	expect(model.assemblies.pelvis.slots.ring_1 == uid and model.slot_definition("pelvis", "ring_1").pose_source == "PV-120__001", "Consumed UID stays separate from destination pose source")
	var before: Dictionary = Save.capture(model)
	expect(not model.install("pelvis", "ring_2", "LG-120__001").ok and Save.capture(model) == before, "Wrong component rejection is atomic")
	for sid in t.content.m2.playable_slots.pelvis:
		if sid == "ring_1": continue
		expect(stage_slot(model, "pelvis", sid), "Own half hardware is available: " + sid)
	expect(not model.milestone("pelvis", "left_leg_secured") and not model.milestone("pelvis", "structural_ready"), "One fastened half never establishes a secured hip")
	while model.assemblies.pelvis.history.size() > 2:
		expect(model.undo("pelvis").ok, "Normal hardware undo returns the consumed identities")
	expect(model.undo("pelvis").ok and model.items[uid].location=="loose","Half undo returns the actual component")
	expect(model.carry_item(uid).is_empty(),"Undone half can be carried")
	expect(model.store_carried_item(uid,"m2_lift_shelf_0").is_empty(),"Same undone half returns to shelf")
	expect(model.undo_supported("pelvis", "m2_leg_rail").ok, "Pelvis seat recovery outputs to the real rail")
	expect(model.integrity_errors().is_empty(), "Retention profile preserves ownership and physical stock")

func crane() -> void:
	var t = trial("crane")
	var model: AssemblyModel = t.model
	manual_audit(t, "crane")
	expect(model.items.size() == 165 and not model.items.has("PV-120__001") and not model.items.has("PV-120__002"), "Crane supplies only existing foot/leg stock")
	stage(t)
	expect(t.content.m2.staged_slots.left_leg.size() == 22 and model.assemblies.left_leg.slots.spar.is_empty(), "Crane staging stops at the 22-slot authored pre-beam graph")
	expect(model.items["LG-120__001"].location == "support:leg_spar_rack" and model.support_occupant("m2_service_crane").is_empty(), "Sole real beam remains on its rack")
	for sid in t.content.m2.playable_slots.left_leg:
		if sid == "spar": continue
		expect(model.assemblies.left_leg.slots[sid].is_empty() and model.items[model.slot_definition("left_leg", sid).pose_source].location == "bin", "Flange stock remains loose and collectable: " + sid)
	var before: Dictionary = Save.capture(model)
	expect(not model.install_supported("left_leg", "spar", "LG-120__001", "leg_spar_rack").ok and Save.capture(model) == before, "M2 rejects old direct rack-to-beam installation atomically")
	expect(model.transfer_supported_item("LG-120__001", "leg_spar_rack", "m2_service_crane").is_empty(), "Beam ownership moves to real crane support")
	expect(model.install_supported("left_leg", "spar", "LG-120__001", "m2_service_crane").ok, "Only real crane support authorizes beam seating")
	expect(not model.undo("left_leg").ok and not model.undo_supported("left_leg", "leg_spar_rack").ok, "Beam undo requires real crane output")
	expect(model.undo_supported("left_leg", "m2_service_crane").ok and model.items["LG-120__001"].location == "support:m2_service_crane", "Supported beam undo outputs real crane")
	expect(model.install_supported("left_leg", "spar", "LG-120__001", "m2_service_crane").ok, "Same beam reinstalls")
	for sid in t.content.m2.playable_slots.left_leg:
		if sid == "spar": continue
		expect(stage_slot(model, "left_leg", sid), "Ordinary flange hardware can install: " + sid)
	expect(model.milestone("left_leg", "structural_ready") and model.integrity_errors().is_empty(), "Crane profile retains original structural readiness and ownership")
	expect(model.definitions.parts["lg-thigh-spar"].short_title == "Upper-leg beam", "M2 catalogue presents Upper-leg beam without changing kind")
	expect(t.content.m2.crane.approach.axis == [0.0, 0.0, -1.0] and is_equal_approx(t.content.m2.crane.approach.distance, .20), "Horizontal flange approach is the final 0.20 m toward -Z")

func run() -> void:
	retention(false)
	retention(true)
	crane()
	var passed = checks.all(func(check): return check.passed)
	var hashes: Dictionary = {}
	for path in ["leg-prototype-definitions.json", "leg-prototype-content.json", "m2-retention-definitions.json", "m2-retention-content.json", "m2-crane-definitions.json", "m2-crane-content.json"]:
		hashes[path] = FileAccess.get_sha256("res://assets/" + path)
	DirAccess.make_dir_recursive_absolute("res://verification")
	FileAccess.open("res://verification/m2-content-audit.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": passed, "checks": checks, "manuals": manifests, "asset_hashes": hashes}, "  "))
	print("M2_CONTENT_AUDIT ", "PASS" if passed else "FAIL", " ", checks.size(), " checks")
	quit(0 if passed else 1)
