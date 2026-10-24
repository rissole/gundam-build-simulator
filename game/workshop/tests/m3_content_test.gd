extends "res://tests/m2_content_test.gd"
## M3 authored graph and physical ownership contract. Equipment controls, contact,
## continuous play and real support gates are verified by the M3 journey tests.

func m3_trial() -> Dictionary:
	var data = HeelAssemblyState.definition_data()
	for path in ["pitch-actuator-definitions.json", "leg-prototype-definitions.json", "m3-definitions.json"]:
		Content.apply_definitions(data, document(path))
	var content = document("m3-content.json")
	var scenario = document("pitch-workshop.json")
	scenario.parent.location = "support:foot_store"
	scenario.parts.append_array(content.parts)
	scenario.builds.append_array(content.builds)
	scenario.parents = content.parents
	scenario.supports = document("leg-prototype-content.json").supports.duplicate(true)
	scenario.supports.merge(content.supports, true)
	var model = AssemblyModel.new()
	var errors = model.configure(data, scenario)
	expect(errors.is_empty(), "M3 configures all real supports: " + str(errors))
	return {"model": model, "data": data, "content": content, "scenario": scenario}

func stage_slot(model: AssemblyModel, owner: String, sid: String) -> bool:
	if owner=="right_foot" and model.slot_definition(owner,sid).has("assembly"):
		if not model.assemblies[owner].slots[sid].is_empty():return true
		var child: String={"heel_1":"right_pad_1","heel_2":"right_pad_2","pitch":"right_pitch"}[sid]
		return model.move_assembly(child,"held").is_empty() and model.install(owner,sid,child).ok
	return super.stage_slot(model,owner,sid)

func prepared_foot(t: Dictionary) -> void:
	var model: AssemblyModel = t.model
	for foot in ["foot","right_foot"]:
		for owner in ["pad_1","pad_2","pitch"] if foot=="foot" else t.content.prepared_branches[foot]:
			model.move_assembly(owner, "station:" + owner)
			expect(fill(model, owner, model.definitions.assemblies[model.assemblies[owner].definition].slots.keys()), "Prepare existing child " + owner)
		expect(fill(model, foot, model.definitions.assemblies[model.assemblies[foot].definition].slots.keys()), foot+" includes all its child assemblies")
	var installed = model.items.values().filter(func(record): return not record.owner.is_empty()).size()
	expect(installed == 270, "Prepared boundary installs exactly 135 identities in each foot")
	expect(model.assemblies.foot.location == "support:foot_store" and model.assemblies.right_foot.location == "support:right_foot_store", "Prepared feet remain on their separate source supports")
	for owner in ["left_leg", "right_leg", "pelvis", "chest"]:
		expect(model.assemblies[owner].slots.values().all(func(uid): return uid == ""), "Prepared boundary leaves every " + owner + " connection empty")

func coverage(t: Dictionary) -> void:
	var layout = document("leg-bay-m3-layout.json")
	for task in layout.crane.tasks.values():
		if task.get("payload","")=="assembly":
			expect(t.model.assemblies.has(task.load_uid) and t.model.support_error(task.load_uid,task.source_support).is_empty() and t.model.support_error(task.load_uid,task.support).is_empty(), "Assembly load has its own identity and compatible source/crane supports: "+task.load_uid)
			continue
		var info: Dictionary = t.content.equipment.parts[task.load_uid]
		expect(info.stock_position == task.source_pose.position and info.support == task.source_support and info.delivery_support == task.support, "Source inventory position and support follow authoritative M3 task " + task.slot)
	var total = 0
	var pages: Array = []
	for owner in t.content.m3.playable_slots:
		var counts: Dictionary = {}
		for step in t.data.assemblies[owner].manual:
			if step.view != "components":
				expect(step.slots.is_empty(), owner + " status/recovery page requests no supplies")
				continue
			var supplies: Dictionary = {}
			for sid in step.slots:
				counts[sid] = counts.get(sid, 0) + 1
				var spec: Dictionary = t.data.assemblies[owner].slots[sid]
				var kind: String = spec.get("accepts", spec.get("assembly", ""))
				supplies[kind] = supplies.get(kind, 0) + 1
			pages.append({"owner": owner, "title": step.title, "slots": step.slots, "supplies": supplies})
		expect(counts.size() == t.data.assemblies[owner].slots.size() and counts.values().all(func(n): return n == 1), owner + " manual owns each installation slot exactly once")
		total += counts.size()
	expect(total == 223, "Both legs, pelvis and chest manuals cover exactly the 223 audited installation connections")
	manifests.m3 = {"pages": pages, "stock_count": t.model.items.size(), "staged_slots": t.content.m3.staged_slots}

func reject_variant(model: AssemblyModel, owner: String, sid: String, uid: String) -> void:
	var record: Dictionary = model.items[uid]
	if record.location == "bin": model.transfer(record.kind, "bin", "pocket", uid)
	var before = Save.capture(model)
	expect(not model.install(owner, sid, uid).ok and Save.capture(model) == before, "Wrong variant rejected atomically at ready " + sid)

func complete_leg(t: Dictionary, harness_first: bool) -> void:
	var model: AssemblyModel = t.model
	expect(model.transfer_supported_assembly("foot","foot_store","m2_service_crane").is_empty() and model.transfer_supported_assembly("foot","m2_service_crane","foot_carrier").is_empty(), "Same prepared foot transfers from storage through the crane to its carrier")
	expect(stage_slot(model, "left_leg", "foot"), "Guided foot mounts only from real carrier")
	var spec: Dictionary = model.slot_definition("left_leg", "shin")
	expect(spec.source_supports == ["m2_service_crane"], "Shin installation uses crane rather than direct rack")
	var before = Save.capture(model)
	expect(not model.install_supported("left_leg", "shin", "LG-100__001", "leg_shin_rack").ok and Save.capture(model) == before, "Direct shin-rack seating is rejected")
	expect(stage_slot(model, "left_leg", "shin"), "Crane seats shin")
	var remaining: Array = t.content.m3.playable_slots.left_leg.duplicate()
	remaining.erase("main_input")
	if harness_first:
		var ankle = remaining.filter(func(sid): return sid.begins_with("ankle/"))
		expect(fill(model, "left_leg", ankle), "Ankle hardware fitted")
		expect(stage_slot(model, "left_leg", "main_input"), "Harness may precede independent knee branch")
	# A fork washer consumes a physical copy canonically associated with pelvis.
	var fork_ready: Array = remaining.filter(func(sid): return not sid.begins_with("fork/") and sid != "spar")
	expect(fill(model, "left_leg", fork_ready), "Knee branch builds independently of harness page order")
	expect(stage_slot(model, "left_leg", "spar"), "Crane seats Upper-leg beam")
	reject_variant(model, "left_leg", "fork/washer_1", "PV-H24140__001")
	model.transfer("lg-w24", "bin", "pocket", "LG-W24__008")
	expect(model.install("left_leg", "fork/washer_1", "LG-W24__008").ok, "Pooled pelvis-numbered washer fits fork")
	expect(model.slot_definition("left_leg", "fork/washer_1").pose_source == "LG-W24__001" and model.assemblies.left_leg.slots["fork/washer_1"] == "LG-W24__008", "Consumed washer UID differs from canonical geometry source")
	reject_variant(model, "left_leg", "fork/bolt_1", "PV-H24140__001")
	expect(fill(model, "left_leg", remaining), "All remaining fork hardware fits")
	if not harness_first:
		expect(not model.milestone("left_leg", "structural_ready"), "Complete knee and beam do not conceal missing harness")
		expect(stage_slot(model, "left_leg", "main_input"), "Harness also fits after complete knee branch")
	expect(model.milestone("left_leg", "structural_ready"), "All 31 leg connections establish structural readiness")
	for task in ["shin", "fork", "spar"]:
		expect(model.milestone("left_leg", task + "_secured"), task + " explicit secured milestone is complete")
		for sid in t.content.m3.security_slots[task]:
			expect(model.slot_definition("left_leg", sid).undo_requires_support == "m2_service_crane", "Recovery declares real crane assistance: " + sid)

func complete_retention(t: Dictionary) -> void:
	var model: AssemblyModel = t.model
	expect(model.install_supported("pelvis", "left_leg", "left_leg", "m2_leg_rail").ok, "Rail seats completed child through parent connection")
	for pair in [["ring_1", "PV-120__002", [3,4]], ["ring_2", "PV-120__001", [1,2]]]:
		var sid: String = pair[0]
		var uid: String = pair[1]
		expect(model.carry_item(uid).is_empty(), "Collect interchangeable half " + uid)
		expect(model.store_carried_item(uid, "left_shelf_0").is_empty(), "Store two-hand half on finite shelf")
		expect(model.carry_supported_item(uid, "left_shelf_0").is_empty(), "Reacquire same half from shelf")
		expect(model.install("pelvis", sid, uid).ok, "Opposite physical half fits " + sid)
		expect(model.slot_definition("pelvis", sid).pose_source != uid, "Half identity is independent from destination pose")
		for n in pair[2]:
			for prefix in ["washer_", "bolt_"]:
				var fastener: String = "ring/" + prefix + str(n)
				expect(not model.milestone("pelvis", "left_ring_secured"), "Every individual retention fastener is mandatory before " + fastener)
				expect(stage_slot(model, "pelvis", fastener), "Own half permits pair without cross-half dependency: " + fastener)
	expect(model.milestone("pelvis", "left_ring_secured") and not model.milestone("pelvis", "left_leg_secured"), "Both halves and every pair secure the ring; stop cage and cylinders remain necessary")
	expect(fill(model,"pelvis",t.data.assemblies.pelvis.milestones.left_leg_secured), "Remaining left hip cage and pinned cylinders fit")
	expect(model.milestone("pelvis", "left_leg_secured"), "Complete left hip retention establishes structural security")
	expect(model.items.values().filter(func(record):return not record.owner.is_empty()).size()==329, "Both prepared feet and completed left leg/hip own 329 physical identities; wider stock remains available")
	expect(model.integrity_errors().is_empty(), "Complete mounted child graph preserves physical ownership")
	for sid in t.data.assemblies.pelvis.milestones.left_leg_secured:
		if sid != "left_leg": expect(model.slot_definition("pelvis", sid).undo_requires_support == "m2_leg_rail", "Retention recovery declares reacquired rail support: " + sid)

func recover(t: Dictionary) -> void:
	var model: AssemblyModel = t.model
	while model.assemblies.pelvis.history.size() > 1:
		var step: Dictionary = model.assemblies.pelvis.history.back()
		var sid: String = step.slot
		if sid in ["ring_1", "ring_2"]:
			var uid: String = model.assemblies.pelvis.slots[sid]
			expect(model.undo_to_hands("pelvis").ok and model.held_item() == uid, "Half recovery preserves actual interchangeable UID " + uid)
			expect(model.store_carried_item(uid, "left_shelf_0").is_empty(), "Recovered half returns through lift shelf")
			expect(model.carry_supported_item(uid, "left_shelf_0").is_empty(), "Recovered half can be unloaded at ground level")
			model.release_item("loose")
		else:
			expect(model.undo("pelvis").ok, "Reverse retention hardware " + sid)
	expect(model.undo_supported("pelvis", "m2_leg_rail").ok and model.assemblies.left_leg.location == "support:m2_leg_rail", "Empty retention permits supported seat recovery to real rail")
	expect(model.integrity_errors().is_empty(), "Supported parent recovery preserves ownership")
	while not model.assemblies.left_leg.history.is_empty():
		var previous_count: int = model.assemblies.left_leg.history.size()
		var step: Dictionary = model.assemblies.left_leg.history.back()
		var spec: Dictionary = model.slot_definition("left_leg",step.slot)
		var uid: String = step.uid
		if spec.get("support_required",false):
			var support: String = spec.source_supports[0]
			expect(model.undo_supported("left_leg",support).ok,"Reverse supported connection " + step.slot)
			if model.items.has(uid):
				var rack: String = t.content.equipment.parts[uid].support
				expect(model.transfer_supported_item(uid,support,rack).is_empty(),"Recovered original component returns to its rack " + uid)
		elif model.definitions.parts[spec.accepts].carry_class in ["hand","two_hand"]:
			expect(spec.get("undo_to","") == "hands","Hand component declares removal at its actual connection " + step.slot)
			expect(model.undo_to_hands("left_leg").ok and model.held_item() == uid,"Structural recovery returns the exact consumed hand identity " + uid)
			model.release_item("loose")
		else:
			expect(model.undo("left_leg").ok,"Reverse structural hardware " + step.slot)
		if model.assemblies.left_leg.history.size() == previous_count:
			expect(false,"Structural recovery must make progress at " + step.slot)
			break
	expect(model.assemblies.foot.location == "support:foot_carrier" and model.assemblies.foot.parent.is_empty(),"Full reverse returns the same prepared foot to its carrier")
	expect(model.items.values().filter(func(record):return not record.owner.is_empty()).size() == 270,"Local left-leg recovery preserves both supplied feet's 270 identities")
	expect(model.integrity_errors().is_empty(),"Full structural reverse preserves physical inventory ownership")

func run() -> void:
	for harness_first in [false, true]:
		var t = m3_trial()
		expect(t.model.items.size() == 482 and t.content.parts.size() == 347, "M3 supplies 135 base foot identities and the audited 347 wider-workshop identities")
		expect(t.model.items.values().filter(func(record): return record.kind == "lg-w24").size() == 16, "Sixteen M24 washers share one stock type across both legs and hips")
		if not harness_first: coverage(t)
		prepared_foot(t)
		complete_leg(t, harness_first)
		complete_retention(t)
		recover(t)
	var passed = checks.all(func(check): return check.passed)
	write_evidence("res://verification/m3-content-audit.json", {"passed": passed, "checks": checks, "manuals": manifests, "asset_hashes": {"definitions": FileAccess.get_sha256("res://assets/m3-definitions.json"), "content": FileAccess.get_sha256("res://assets/m3-content.json")}})
	print("M3_CONTENT_AUDIT ", "PASS" if passed else "FAIL", " ", checks.size(), " checks")
	quit(0 if passed else 1)
