extends "res://tests/kit/harness.gd"
const Geometry = preload("res://scripts/leg_source_geometry.gd")
const Content = preload("res://scripts/workshop_content.gd")
var sources: Dictionary = {}
var model = AssemblyModel.new()
var data: Dictionary
var scenario: Dictionary

func document(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://assets/" + path))

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	data = HeelAssemblyState.definition_data()
	for path in ["pitch-actuator-definitions.json", "leg-prototype-definitions.json"]:
		var overlay = document(path)
		Content.apply_definitions(data,overlay)
	var content = document("leg-prototype-content.json")
	scenario = document("pitch-workshop.json")
	scenario.parent.location = "support:foot_carrier"
	scenario.parts.append_array(content.parts)
	scenario.parents = content.parents
	scenario.supports = content.supports
	var errors = model.configure(data, scenario)
	expect(errors.is_empty(), "Leg extension configures with original foot stock: " + str(errors))
	if not errors.is_empty():
		quit(1)
		return
	expect(model.items.size() == 175, "135 original + 40 new physical identities; no logical assembly inventory")
	expect(model.assemblies.size() == 6, "Two pads, actuator, foot, left leg and pelvis have distinct state")
	for definition_id in ["left_leg", "pelvis"]:
		var recipe: Dictionary = data.assemblies[definition_id]
		var counts: Dictionary = {}
		for page in recipe.manual:
			if page.view != "components": continue
			for sid in page.slots: counts[sid] = counts.get(sid, 0) + 1
		expect(counts.size() == recipe.slots.size() and counts.values().all(func(n): return n == 1), definition_id + " manual covers each unique installation once")
	expect(data.assemblies.left_leg.slots.bearing_1.accepts == data.assemblies.left_leg.slots.bearing_2.accepts, "Identical knee bearings share compatibility")
	expect(data.assemblies.pelvis.slots.ring_1.accepts == data.assemblies.pelvis.slots.ring_2.accepts, "Rotated ring halves share compatibility")
	expect(data.assemblies.pelvis.slots["ring/washer_1"].accepts == data.assemblies.left_leg.slots["fork/washer_1"].accepts, "Identical fork and ring washers share stock")
	for key in content.sources:
		expect(not model.items.has(key) or not content.context_sources.has(key), "Context is outside inventory: " + key)
	for owner in ["pad_1", "pad_2", "pitch"]:
		expect(model.move_assembly(owner, "station:" + owner).is_empty(), "Preparation station accepts " + owner)
		complete(owner)
	complete("foot")
	expect(model.milestone("foot", "complete"), "Existing complete foot is prerequisite for leg docking")
	expect(not model.install("left_leg", "foot", "foot").ok, "Foot cannot bypass carrier with ordinary mount")
	expect(model.install_supported("left_leg", "foot", "foot", "foot_carrier").ok, "Complete foot docks as the same nested physical branch")
	complete("left_leg")
	expect(model.milestone("left_leg", "structural_ready"), "Manual order produces structural readiness")
	expect(not model.milestone("left_leg", "operational"), "Prototype does not claim powered operational readiness")
	expect(model.assemblies.foot.parent == "left_leg" and model.assemblies.pitch.parent == "foot", "Deep child ownership is retained")
	expect(model.assemblies.left_leg.location == "support:leg_holder", "Complete leg remains on its construction rail")
	expect(model.install_supported("pelvis", "left_leg", "left_leg", "leg_holder").ok, "Rail seats ball in pelvis before ring retention")
	expect(not model.milestone("pelvis", "left_leg_secured"), "Seated ball is distinct from retained leg")
	complete("pelvis")
	expect(model.milestone("pelvis", "left_leg_secured"), "Both ring halves and all bolts retain the leg")
	expect(model.items.values().all(func(item): return item.location == "installed"), "Every one of 175 physical identities is installed exactly once")
	expect(model.integrity_errors().is_empty(), "Completed ownership tree has no inventory or support leaks")
	# Reverse real parent history; hardware can return to pockets, large halves
	# return through ordinary component ownership. Finally the rail receives the same complete leg.
	while model.assemblies.pelvis.history.size() > 1:
		var sid: String = model.assemblies.pelvis.history.back().slot
		var result = model.undo("pelvis")
		expect(result.ok, "Parent retention reverses: " + sid)
	expect(not model.undo("pelvis").ok, "Bare ball removal still requires rail support")
	expect(model.undo_supported("pelvis", "leg_holder").ok, "Rail recovers the same complete leg")
	expect(model.milestone("left_leg", "structural_ready") and model.assemblies.foot.parent == "left_leg", "Removal preserves nested structural work")
	expect(model.install_supported("pelvis", "left_leg", "left_leg", "leg_holder").ok, "Same leg identity reseats")
	complete("pelvis")
	expect(model.integrity_errors().is_empty(), "Undo and reinstallation preserve all physical identities")
	Geometry.add_sources(sources, content)
	geometry_checks()
	var passed = checks.all(func(check): return check.passed)
	DirAccess.make_dir_recursive_absolute("res://verification")
	write_evidence("res://verification/leg-content-audit.json",{"passed": passed, "checks": checks})
	print("LEG_CONTENT_AUDIT ", "PASS" if passed else "FAIL", " ", checks.size(), " checks")
	quit(0 if passed else 1)

func complete(owner: String) -> void:
	var recipe: Dictionary = data.assemblies[model.assemblies[owner].definition]
	for page in recipe.manual:
		if page.get("view", "") in ["overview", "prepared"]: continue
		for sid in page.slots:
			if not model.assemblies[owner].slots[sid].is_empty(): continue
			var definition = model.slot_definition(owner, sid)
			var uid = ""
			var support = ""
			if definition.has("assembly"):
				for candidate in model.assemblies:
					if model.assemblies[candidate].definition == definition.assembly and model.assemblies[candidate].parent.is_empty():
						uid = candidate
						break
				model.move_assembly(uid, "held")
			else:
				# Reverse selection intentionally swaps identical copies and sources.
				for candidate in model.items:
					if model.items[candidate].kind == definition.accepts and model.items[candidate].owner.is_empty() and model.items[candidate].location != "installed": uid = candidate
				if uid.is_empty():
					expect(false, "Available stock for " + owner + "/" + sid)
					continue
				var carry: String = data.parts[definition.accepts].carry_class
				if carry == "equipment":
					support = String(model.items[uid].location).trim_prefix("support:")
					var receiving: String = definition.get("source_supports",[support])[0]
					if support != receiving:
						expect(model.transfer_supported_item(uid,support,receiving).is_empty(),"Transfer supported component to "+receiving)
						support = receiving
				elif carry == "pocket":
					if model.items[uid].location != "pocket": model.transfer(definition.accepts, "bin", "pocket", uid)
				else:
					model.carry_item(uid)
			var result = model.install_supported(owner, sid, uid, support) if not support.is_empty() else model.install(owner, sid, uid)
			expect(result.ok, "Manual installs " + owner + "/" + sid + ": " + str(result.get("error", "")))

func hits(uid: String, a: Vector3, b: Vector3) -> bool:
	var inverse: Transform3D = sources[uid].transform.affine_inverse()
	var begin = (inverse * a) * 1000.0
	var end = (inverse * b) * 1000.0
	var faces: PackedVector3Array = sources[uid].mesh.get_faces()
	for i in range(0, faces.size(), 3):
		if Geometry3D.segment_intersects_triangle(begin, end, faces[i] * 1000.0, faces[i + 1] * 1000.0, faces[i + 2] * 1000.0) != null: return true
	return false

func geometry_checks() -> void:
	for uid in sources:
		expect(sources[uid].mesh.get_faces().size() > 0, "Independent nonempty mesh: " + uid)
	for x in [-.2, .2]:
		for z in [-.15, .15]:
			expect(not hits("LG-100__001", Vector3(x, 1.37, z), Vector3(x, 1.43, z)), "Shin flange has real M36 bore")
			expect(hits("LG-100__001", Vector3(x + .025, 1.37, z), Vector3(x + .025, 1.43, z)), "Shin bolt bore has supporting material")
	expect(not hits("LG-100__001", Vector3(0, 1.379, 0), Vector3(0, 1.405, 0)), "Adapter key enters real 182×102 recess")
	expect(hits("LG-100__001", Vector3(0, 1.405, 0), Vector3(0, 1.43, 0)), "Key recess has closed roof above the tongue")
	expect(not hits("LG-100__001", Vector3(-.31, 5.1, 0), Vector3(.31, 5.1, 0)), "Shin knee boss has an open bearing bore")
	expect(hits("LG-100__001", Vector3(-.31, 5.29, 0), Vector3(.31, 5.29, 0)), "Shin bearing bore is surrounded by load-bearing boss")
	for x in [-.43, .43]:
		expect(not hits("LG-110__001", Vector3(x - .09, 5.1, 0), Vector3(x + .09, 5.1, 0)), "Fork cheek has an open axle bore")
	for x in [-.25, .25]:
		for z in [-.2, .2]:
			for uid in ["LG-110__001", "LG-120__001"]:
				expect(not hits(uid, Vector3(x, 5.87, z), Vector3(x, 5.99, z)), "Matching accessible fork flange bore in " + uid)
			expect(hits("LG-110__001", Vector3(x + .0115, 5.875, z), Vector3(x + .0115, 5.925, z)), "Fork receiver retains tap-drill material for M24 threads")
			expect(not hits("LG-120__001", Vector3(x + .0115, 5.915, z), Vector3(x + .0115, 5.965, z)), "Spar flange clears M24 shank above tapped fork")
	for uid in ["LG-130__001", "LG-130__002"]:
		expect(not hits(uid, Vector3(-.30, 5.1, 0), Vector3(.30, 5.1, 0)), "Bearing has clear journal: " + uid)
	var plug = Vector3(.250, 1.400, -.100)
	var plug_axis = Vector3(.080, .160, -.050).normalized()
	var side = plug_axis.cross(Vector3.BACK).normalized()
	for offset in [Vector3.ZERO, side * .016, -side * .016]:
		expect(not hits("LG-100__001", plug + plug_axis * .016 + offset, plug + plug_axis * .049 + offset), "Shin electrical sleeve clears actual source plug collar")
	expect(hits("LG-100__001", plug + plug_axis * .016 + side * .022, plug + plug_axis * .049 + side * .022), "Electrical sleeve has surrounding receiver material")
	var main_recipe: Dictionary = data.assemblies.left_leg.slots.main_input
	expect(main_recipe.pose_source == "FA-605__001" and model.items.has("FA-605__001"), "Main harness is one original physical identity including both plugs")
	for view in data.assemblies.left_leg.manual.filter(func(p): return p.title == "Secure the ankle flange")[0].diagram_views:
		expect(view.offsets.size() == 8 and view.offsets.values().all(func(offset): return Geometry.vec(offset) == Vector3(0, .03, 0)), "Ankle diagrams apply the same 30mm hardware pose correction")
	for x in [-1.1 - .449, -1.1, -1.1 + .449]:
		expect(not hits("PV-110__001", Vector3(x, -.8, 0), Vector3(x, .02, 0)), "Socket mouth clears vertical ball insertion")
	expect(not hits("PV-110__001", Vector3(-1.1, 0, 0), Vector3(-1.1, .455, 0)), "Socket seat preserves six millimetre radial ball clearance")
	expect(hits("PV-110__001", Vector3(-1.1, .455, 0), Vector3(-1.1, .55, 0)), "Socket has a physical spherical bowl above the ball")
	for uid in ["PV-120__001", "PV-120__002"]:
		expect(not hits(uid, Vector3(-1.1, -.45, 0), Vector3(-1.1, -.33, 0)), "Ring half leaves a real open neck passage")
	for i in range(4):
		var angle = PI / 4 + i * PI / 2
		var x = -1.1 + .575 * cos(angle)
		var z = .575 * sin(angle)
		var uid = "PV-120__001" if z < 0 else "PV-120__002"
		expect(not hits(uid, Vector3(x, -.44, z), Vector3(x, -.34, z)), "Ring half has real M24 clearance bore")
		expect(not hits("PV-110__001", Vector3(x, -.36, z), Vector3(x, -.27, z)), "Socket flange has aligned receiver tap bore")
		expect(hits("PV-110__001", Vector3(x + .0115, -.36, z), Vector3(x + .0115, -.27, z)), "Socket receiver retains tap-drill material for M24 threads")
	expect(sources["PV-120__001"].mesh.get_faces() == sources["PV-120__002"].mesh.get_faces(), "Ring halves are geometrically identical manufactured copies")
	var scene = load("res://assets/foot-fa01.glb").instantiate()
	for node in scene.get_children():
		if not node is MeshInstance3D: continue
		var sections = String(node.name).split("__")
		var uid = sections[0] + "__" + sections[1]
		if uid.begins_with("H-36090") or uid in ["W-36__021", "W-36__022", "W-36__023", "W-36__024"]:
			var definition = data.assemblies.left_leg.slots["ankle/" + uid]
			var position = Geometry.vec(definition.snap_position)
			expect(position.is_equal_approx(node.position + Vector3(0, .03, 0)), "Reused source origin is corrected only for shin plate thickness: " + uid)
	scene.free()
