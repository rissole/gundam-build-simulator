extends "res://tests/kit/harness.gd"
## Exercise interchangeable stock with physical identities deliberately swapped.
const SHARED_FAMILIES = ["FA-526", "FA-527", "FA-528", "FA-221", "FA-222"]
const VARIANT_FAMILIES = ["FA-524", "FA-525", "FA-529", "FA-220"]
var model = AssemblyModel.new()
var swapped: Dictionary = {}
var tested_swaps: Array[String] = []
var rejected_variants: Array[String] = []

func collect(uid: String) -> bool:
	var item: Dictionary = model.items[uid]
	if model.definitions.parts[item.kind].carry_class == "pocket":
		if item.location == "pocket": return true
		return model.transfer(item.kind, "bin", "pocket", uid) == uid
	return model.carry_item(uid).is_empty()

func return_stock(uid: String) -> void:
	var item: Dictionary = model.items[uid]
	if item.location == "pocket": model.transfer(item.kind, "pocket", "bin", uid)
	elif item.location == "held": model.release_item("bin")

func install_slot(assembly: String, sid: String) -> void:
	var slot: Dictionary = model.slot_definition(assembly, sid)
	if not model.assemblies[assembly].slots[sid].is_empty(): return
	if slot.has("assembly"):
		expect(model.move_assembly("pitch", "held").is_empty(), "Carry prepared pitch actuator")
		expect(model.install(assembly, sid, "pitch").ok, "Mount prepared actuator through the shared model")
		return
	var source: String = slot.pose_source
	var family: String = source.split("__")[0]
	# Test real incompatible geometry at a ready slot, with the wrong variant
	# actually collected. A missing prerequisite must not masquerade as rejection.
	if family in VARIANT_FAMILIES and source.ends_with("__001"):
		var wrong = family + "__002"
		expect(slot.requires.all(func(r): return not model.assemblies[assembly].slots[r].is_empty()), "Variant test has satisfied prerequisites: " + sid)
		expect(collect(wrong), "Collect incompatible variant: " + wrong)
		var location: String = model.items[wrong].location
		var result: Dictionary = model.install(assembly, sid, wrong)
		expect(not result.ok and result.error.begins_with("Compatible next component:"), "Reject incompatible variant at ready slot: " + sid)
		expect(model.items[wrong].location == location and model.assemblies[assembly].slots[sid].is_empty(), "Rejected variant preserves stock and empty slot: " + sid)
		return_stock(wrong)
		rejected_variants.append(family)
	var uid: String = swapped.get(source, source)
	# Shared hardware may already have used the authored source identity elsewhere.
	if not swapped.has(source) and model.items[uid].location == "installed":
		uid = model.find_item(slot.accepts, "bin")
	expect(not uid.is_empty() and collect(uid), "Collect physical component: " + sid)
	var result: Dictionary = model.install(assembly, sid, uid)
	expect(result.ok, "Construct manual slot with available stock: " + sid)
	if not result.ok: return
	if swapped.has(source):
		expect(uid != source and model.assemblies[assembly].slots[sid] == uid and model.items[uid].slot == sid, "Compatible copy retains consumed identity: " + sid)
		expect(model.slot_definition(assembly, sid).pose_source == source, "Swapping stock preserves slot geometry source: " + sid)
		var undone: Dictionary = model.undo(assembly)
		var destination = "pocket" if model.definitions.parts[slot.accepts].carry_class == "pocket" else "loose"
		expect(undone.ok and undone.step.uid == uid and model.items[uid].location == destination and model.assemblies[assembly].slots[sid].is_empty(), "Undo returns exact swapped identity: " + sid)
		expect(collect(uid) and model.install(assembly, sid, uid).ok, "Reinstall recovered swapped copy: " + sid)
		tested_swaps.append(source)
	expect(model.integrity_errors().is_empty(), "Ownership and inventory remain valid after: " + sid)

func audit_geometry() -> void:
	var scene = load("res://assets/foot-fa01.glb").instantiate()
	var sources: Dictionary = {}
	for node in scene.get_children():
		if node is MeshInstance3D:
			var sections = String(node.name).split("__")
			sources[sections[0] + "__" + sections[1]] = node
	for family in SHARED_FAMILIES:
		var first: MeshInstance3D = sources[family + "__001"]
		var second: MeshInstance3D = sources[family + "__002"]
		var a: PackedVector3Array = first.mesh.get_faces()
		var b: PackedVector3Array = second.mesh.get_faces()
		var equal: bool = not a.is_empty() and a.size() == b.size()
		var max_error = 0.0
		if equal:
			# Imported nodes can bake orientation into their vertices. Compare the
			# actual transformed vertices after removing only their translation.
			var a_bounds = AABB(first.transform * a[0], Vector3.ZERO)
			var b_bounds = AABB(second.transform * b[0], Vector3.ZERO)
			for i in range(a.size()):
				a[i] = first.transform * a[i]
				b[i] = second.transform * b[i]
				a_bounds = a_bounds.expand(a[i])
				b_bounds = b_bounds.expand(b[i])
			for i in range(a.size()):
				a[i] -= a_bounds.get_center()
				b[i] -= b_bounds.get_center()
				max_error = maxf(max_error, a[i].distance_to(b[i]))
			if max_error >= 0.00001:
				# Boolean triangulation can reorder equivalent vertices. The fallback
				# compares both directions so an extra feature cannot be overlooked.
				max_error = maxf(vertex_set_distance(a, b), vertex_set_distance(b, a))
			equal = max_error < 0.00001
		expect(equal, "Shared kind has equivalent imported vertices up to translation: %s (max error %.8f m)" % [family, max_error])
	scene.free()

func vertex_set_distance(a: PackedVector3Array, b: PackedVector3Array) -> float:
	var largest = 0.0
	for vertex in a:
		var nearest = INF
		for candidate in b:
			nearest = minf(nearest, vertex.distance_squared_to(candidate))
			if nearest < 0.000000000001: break
		largest = maxf(largest, sqrt(nearest))
	return largest

func _initialize() -> void:
	var data = HeelAssemblyState.definition_data()
	var overlay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pitch-actuator-definitions.json"))
	data.parts.merge(overlay.parts, true)
	data.assemblies.merge(overlay.assemblies, true)
	var scenario: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pitch-workshop.json"))
	expect(model.configure(data, scenario).is_empty(), "Authored workshop configures")
	var identities: Array = model.items.keys().duplicate()
	for family in SHARED_FAMILIES:
		var first = family + "__001"
		var second = family + "__002"
		var kind: String = model.items[first].kind
		expect(kind == family.to_lower() + "-pitch" and model.items[second].kind == kind, "Identical copies share one stock kind: " + family)
		expect(model.count_at(kind, "bin") == 2, "Shared shelf or drawer contains both physical copies: " + family)
		if data.parts[kind].carry_class == "pocket":
			var result: Dictionary = model.stock_pocket(kind)
			expect(result.ok and result.taken == 2 and model.pocket_size(result.index) == 2 and model.items[first].pocket == model.items[second].pocket, "One drawer collects both copies into one pocket: " + family)
			model.clear_pocket(result.index)
		else:
			for uid in [second, first]:
				expect(collect(uid) and model.held_item() == uid, "Shared shelf can supply either physical copy: " + uid)
				return_stock(uid)
		swapped[first] = second
		swapped[second] = first
	for family in VARIANT_FAMILIES:
		expect(model.items[family + "__001"].kind != model.items[family + "__002"].kind, "Different geometry retains distinct compatibility: " + family)
	model.move_assembly("pitch", "station:prep3")
	for page in data.assemblies.pitch_actuator.manual:
		if page.view == "prepared": continue
		for sid in page.slots: install_slot("pitch", sid)
	expect(model.milestone("pitch", "prepared"), "Swapped copies complete the actuator")
	for page in data.assemblies.foot.manual:
		if page.get("view", "") == "overview": continue
		for sid in page.slots:
			if sid == "pitch" or sid.begins_with("pitch/"): install_slot("foot", sid)
	expect(model.milestone("foot", "pitch_secured"), "Swapped pins and keepers secure both mounting endpoints")
	expect(tested_swaps.size() == SHARED_FAMILIES.size() * 2, "Every compatible physical copy installed at the opposite endpoint and undone")
	expect(rejected_variants.size() == VARIANT_FAMILIES.size(), "Each incompatible variant family rejected at a ready connection")
	expect(model.items.keys() == identities and model.items.size() == scenario.parts.size() and model.integrity_errors().is_empty(), "Full build and undo preserve every scenario identity and inventory total")
	audit_geometry()
	var passed: bool = checks.all(func(c): return c.passed)
	print("PART_VARIANTS_AUDIT ", "PASS" if passed else "FAIL", " ", checks.size(), " checks")
	quit(0 if passed else 1)
