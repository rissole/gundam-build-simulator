extends "res://tests/kit/harness.gd"
var model = AssemblyModel.new()
func _initialize() -> void:
	var data = HeelAssemblyState.definition_data()
	var overlay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pitch-actuator-definitions.json"))
	data.parts.merge(overlay.parts,true)
	data.assemblies.merge(overlay.assemblies,true)
	var scenario: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pitch-workshop.json"))
	expect(model.configure(data,scenario).is_empty(),"Expanded authored graph validates")
	var original = JSON.parse_string(FileAccess.get_file_as_string("res://assets/heel-pads.json"))
	expect(original.parts.all(func(p):return model.items.has(p.instance_id)),"All 26 existing pad identities remain active")
	expect(model.items.size()==135,"Exactly 135 source identities, no extra logical-module objects")
	var recipe: Dictionary = data.assemblies.pitch_actuator
	var sources: Array = []
	for slot in recipe.slots.values():sources.append(slot.pose_source)
	expect(sources.size()==91 and sources.all(func(uid):return model.items.has(uid)),"Every actuator slot resolves to a physical scenario piece")
	var internals = sources.filter(func(uid):return uid.begins_with("FA-"))
	expect(internals.size()==27,"All 27 non-fastener actuator components retained")
	expect(sources.filter(func(uid):return uid.begins_with("H-")).size()==32,"All 32 internal screws retained")
	expect(sources.filter(func(uid):return uid.begins_with("W-")).size()==32,"All 32 internal washers retained")
	model.move_assembly("pitch","station:prep3")
	expect(model.assemblies.pitch.slots.base=="FA-513__001" and model.items["FA-510__001"].location=="bin","Motor starts the assembly; housing remains available stock")
	model.carry_item("FA-510__001")
	expect(not model.install("pitch","FA-510__001","FA-510__001").ok,"Housing waits for the exposed drive assembly")
	model.release_item("bin")
	model.move_assembly("pad_1","held")
	expect(not model.carry_item("FA-516__001").is_empty(),"Carried assembly prevents acquiring a long loose part")
	model.move_assembly("pad_1","loose")
	expect(model.carry_item("FA-516__001").is_empty(),"Long screw can occupy both hands")
	expect(not model.move_assembly("pad_1","held").is_empty(),"Carried loose part prevents acquiring an assembly")
	expect(not model.carry_item("FA-518__001").is_empty(),"Cannot hold two long components")
	expect(model.pocket_count()==0,"Large carried pieces do not consume pocket capacity")
	model.release_item("bin")
	expect(model.transfer(model.items["FA-516__001"].kind,"bin","pocket").is_empty(),"Long components cannot enter pockets")
	var order: Array = []
	for page in recipe.manual:
		for sid in page.slots:
			if sid == "base" or order.has(sid):continue
			order.append(sid)
	# A manual read from beginning to end must be a valid construction path.
	for sid in order:
		var d: Dictionary = recipe.slots[sid]
		var uid: String = model.find_item(d.accepts,"bin")
		if data.parts[d.accepts].carry_class == "pocket":model.transfer(d.accepts,"bin","pocket",uid)
		else:model.carry_item(uid)
		expect(model.install("pitch",sid,uid).ok,"Manual order is constructible: "+sid)
		if sid == recipe.manual[0].slots[-1]:
			expect(model.assemblies.pitch.slots["FA-510__001"].is_empty(),"Manual step one completes without the casing")
		if sid == "FA-516__001":
			var result = model.undo("pitch")
			expect(result.ok and model.items[uid].location=="loose","Undo returns a long component to the output instead of pockets")
			model.carry_item(uid)
			expect(model.install("pitch",sid,uid).ok,"Recovered long component retains its identity")
	expect(model.milestone("pitch","prepared"),"Prepared milestone covers the complete actuator")
	expect(model.integrity_errors().is_empty(),"Complete child preserves ownership, hand and pocket invariants")
	# Pitch variants are individually keyed even when their family is shared.
	expect(recipe.slots["FA-525__001"].accepts != recipe.slots["FA-525__002"].accepts,"Base and rod eye variants cannot be silently interchanged")
	expect(data.assemblies.foot.slots.pitch.connections.size()==2,"One parent ownership with two receiving clevis connections")
	var parent: Dictionary = data.assemblies.foot
	expect(parent.milestones.pitch_secured.size()==19,"Pitch installation requires its child mount and all 18 mounting pieces")
	var covered: Array = []
	for step in parent.manual:
		if step.get("view","") == "overview":continue
		for sid in step.slots:
			if not covered.has(sid):covered.append(sid)
	expect(covered.size()==parent.slots.size(),"Foot manual covers every child mount and physical fastening slot")
	# Complete the combined scenario using the same slot graph, including shared W-24 stock.
	for id in ["pad_1","pad_2"]:
		model.move_assembly(id,"station:"+id)
		for sid in model.assemblies[id].slots:
			if not model.assemblies[id].slots[sid].is_empty():continue
			var d = model.slot_definition(id,sid)
			var uid = model.transfer(d.accepts,"bin","pocket")
			model.install(id,sid,uid)
	for pass_index in range(parent.slots.size()):
		for sid in parent.slots:
			if not model.assemblies.foot.slots[sid].is_empty():continue
			var d: Dictionary = parent.slots[sid]
			if not d.requires.all(func(r):return not model.assemblies.foot.slots[r].is_empty()):continue
			if d.has("assembly"):
				for id in model.assemblies:
					if model.assemblies[id].definition != d.assembly or not model.assemblies[id].parent.is_empty():continue
					model.move_assembly(id,"held")
					model.install("foot",sid,id)
					break
			else:
				var uid: String = model.find_item(d.accepts,"bin")
				if data.parts[d.accepts].carry_class == "pocket":model.transfer(d.accepts,"bin","pocket",uid)
				else:model.carry_item(uid)
				model.install("foot",sid,uid)
	expect(model.milestone("foot","complete"),"All three secured branches complete the combined workshop")
	expect(model.items.values().all(func(i):return i.location=="installed"),"Combined completion installs exactly all 135 identities")
	expect(model.integrity_errors().is_empty(),"Shared fasteners and combined completion preserve all invariants")
	var passed: bool = checks.all(func(c):return c.passed)
	write_evidence("res://verification/pitch-model-audit.json",{"passed":passed,"checks":checks})
	print("PITCH_MODEL_AUDIT ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
