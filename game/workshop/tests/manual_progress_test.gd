extends "res://tests/kit/harness.gd"
## Chapter order, step status and the tracked step against authored manuals.
class Crane extends "res://scripts/service_crane.gd":
	func _refresh() -> void:pass
const Progress = preload("res://scripts/manual_progress.gd")
func _initialize() -> void:call_deferred("run")

func joined(lines: Array) -> String:
	var text := ""
	for line in lines:text += str(line)+" | "
	return text

func authored_entries(raw: Dictionary) -> Array:
	var entries: Array = []
	var chapters: Array = raw.get("chapters",[]) if raw.get("chapters") is Array else []
	for chapter in chapters:
		if not chapter is Dictionary:continue
		var steps: Array = chapter.get("steps",[]) if chapter.get("steps") is Array else []
		for entry in steps:entries.append(entry)
	var reference: Dictionary = raw.get("reference",{}) if raw.get("reference") is Dictionary else {}
	var reference_steps: Array = reference.get("steps",[]) if reference.get("steps") is Array else []
	for entry in reference_steps:entries.append(entry)
	return entries

func fit_slot(model, owner: String, sid: String) -> String:
	if not str(model.assemblies[owner].slots[sid]).is_empty():return ""
	var spec: Dictionary = model.slot_definition(owner,sid)
	var uid := str(spec.get("pose_source",""))
	if not model.items.has(uid) or not str(model.items[uid].owner).is_empty() or str(model.items[uid].kind) != str(spec.accepts):
		uid = ""
		for candidate in model.items:
			if str(model.items[candidate].kind) == str(spec.accepts) and str(model.items[candidate].owner).is_empty():
				uid = str(candidate)
				break
	if uid.is_empty():return "no "+str(spec.accepts)
	if str(model.definitions.parts[spec.accepts].get("carry_class","")) == "pocket":
		if str(model.items[uid].location) != "pocket":
			var moved = model.transfer(str(spec.accepts),"bin","pocket",uid)
			if str(moved).is_empty():return "pocket "+uid+" from "+str(model.items[uid].location)
	else:
		var carried := str(model.carry_item(uid))
		if not carried.is_empty():return carried
	var result: Dictionary = model.install(owner,sid,uid)
	return "" if result.ok else str(result.get("error",result))

func fit_slots(model, owner: String, slot_ids: Array) -> void:
	if str(model.assemblies[owner].location) == "loose":
		var moved := str(model.move_assembly(owner,"station:"+owner))
		expect(moved.is_empty(),"Station for "+owner+": "+moved)
	for sid in slot_ids:
		var error := fit_slot(model,owner,str(sid))
		expect(error.is_empty(),"Fill "+owner+"/"+str(sid)+": "+error)

func run() -> void:
	var game = preload("res://tests/kit/model_workshop.gd").new();root.add_child(game)
	expect(game.setup().is_empty(),"authored stock configures")
	var crane = Crane.new();game.add_child(crane);crane.game = game
	crane.equipment_id = "service_crane";game.equipment.register(crane)
	crane.tasks = preload("res://scripts/leg_bay_layout.gd").layout().crane.tasks
	crane.task = "shin";crane.uid = "LG-100__001";crane.config = {"spec":crane.tasks.shin}
	crane.END_IDS = ["a","b"]
	crane.endpoints = {"a":{"state":"stowed","point":""},"b":{"state":"stowed","point":""}}
	crane.station = "park";crane.raised = true;crane.motion = "";crane.moving = false
	var progress = Progress.new(game)
	var registry=JSON.parse_string(FileAccess.get_file_as_string("res://assets/manual-chapters.json")).procedures
	var registered: Dictionary={}
	for chapter in progress.chapters():
		for step in chapter.steps:
			var procedure=progress.procedure(step.owner,step.page)
			if procedure.is_empty():continue
			registered[procedure.id]=true
			var origin: Array=registry[procedure.id].first
			expect(procedure.repeat==(step.owner!=origin[0] or step.page!=origin[1]),str(step.title)+" repeats only after its registered first use")
			if procedure.repeat:expect(procedure.label.begins_with("Procedure: p.") and not procedure.step.is_empty(),str(step.title)+" links to its first-use page")
	expect(registered.size()==6 and registry.size()==6,"all six authored leg and gantry procedures resolve")
	# Fixture metadata only: no crane page or control changes are imported.
	var first_row: Dictionary=progress._order[0]
	var repeat_row: Dictionary=progress._order[1]
	first_row.definition["procedure"]="fixture"
	repeat_row.definition["procedure"]="fixture"
	progress._data["procedures"]={"fixture":{"title":"Operate the rig","machines":["leg_rail"],"first":[first_row.owner,first_row.page]}}
	var first=progress.procedure(first_row.owner,first_row.page)
	var repeat=progress.procedure(repeat_row.owner,repeat_row.page)
	expect(not first.repeat and repeat.repeat and repeat.number==1 and repeat.step.owner==first_row.owner and repeat.step.page==first_row.page,"repeat links to the first chapter page")
	expect(repeat.label=="Procedure: p.1 — Operate the rig","procedure label includes a stable page number and title")
	var before=progress.evaluation(repeat_row.owner,repeat_row.page).duplicate(true)
	progress.pin(repeat_row.owner,repeat_row.page)
	progress.procedure(repeat_row.owner,repeat_row.page);progress.refresh()
	expect(before==progress.evaluation(repeat_row.owner,repeat_row.page),"procedure lookup and tracking cannot complete physical work")
	progress.unpin()
	first_row.definition.erase("procedure");repeat_row.definition.erase("procedure")
	progress._data.erase("procedures")
	expect(progress.procedure(repeat_row.owner,repeat_row.page).is_empty(),"unregistered procedure leaves the full tutorial visible")
	var seen: Dictionary = {}
	var dupes: Array[String] = []
	var bad: Array[String] = []
	var listed: Array = []
	for chapter in progress.chapters():
		for step in chapter.steps:listed.append(step)
	for step in progress.reference_steps():listed.append(step)
	for step in listed:
		var owner := str(step.owner)
		var page := int(step.page)
		var key := owner+":"+str(page)
		if seen.has(key):dupes.append(key)
		seen[key] = true
		var manual: Array = game.model.definitions.assemblies[game.model.assemblies[owner].definition].get("manual",[])
		if page < 0 or page >= manual.size() or manual[page] != step.definition:bad.append(key+" "+str(step.title))
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://assets/manual-chapters.json"))
	var unresolved: Array[String] = []
	for entry in authored_entries(raw):
		var key := str(entry[0])+":"+str(int(entry[1]))
		if not seen.has(key):unresolved.append(key)
	expect(dupes.is_empty() and bad.is_empty() and unresolved.is_empty(),"every chapter step references an existing page once; dupes "+joined(dupes)+" bad "+joined(bad)+" unresolved "+joined(unresolved))
	var skip: Dictionary = {}
	var branches = game.leg_content.get("prepared_branches",{})
	if branches is Dictionary:
		for id in branches:
			skip[str(id)] = true
			var value = branches[id]
			if value is Array:
				for item in value:skip[str(item)] = true
			elif value is String:skip[value] = true
	var covered: Dictionary = {}
	for step in listed:covered[str(step.owner)+":"+str(int(step.page))] = true
	var missing: Array[String] = []
	for owner in game.model.assemblies:
		if skip.has(str(owner)):continue
		var definition: Dictionary = game.model.definitions.assemblies[game.model.assemblies[owner].definition]
		var manual: Array = definition.get("manual",[]) if definition.get("manual") is Array else []
		for index in manual.size():
			var step_page = manual[index]
			if not step_page is Dictionary:continue
			var view := str(step_page.get("view",""))
			if view != "components" and view != "prepare" and view != "install":continue
			var key := str(owner)+":"+str(index)
			if covered.has(key):continue
			missing.append("[%s,%d,%s]"%[str(owner),index,str(step_page.get("title",""))])
	expect(missing.is_empty(),"pages missing from chapters and reference: "+joined(missing))
	var pad_first := "Prepare a heel pad (1 of 2)"
	var pad_second := "Prepare a heel pad (2 of 2)"
	var tracked: Dictionary = progress.tracked()
	expect(str(tracked.get("title","")) == pad_first,"tracked starts at "+pad_first+", got "+str(tracked.get("title","")))
	expect(progress.status("pad_1",0) == "ready","the first heel-pad step is ready, got "+progress.status("pad_1",0))
	expect(progress.status("pitch",0) == "ready","pitch actuator first step is ready, got "+progress.status("pitch",0))
	var unlocked: Array[String] = []
	for chapter in progress.chapters():
		var title := str(chapter.title)
		if title != "Hip assembly delivery" and title != "Left-leg construction":continue
		for step in chapter.steps:
			var state := progress.status(str(step.owner),int(step.page))
			if state != "locked":unlocked.append(title+" / "+str(step.title)+"="+state)
	expect(unlocked.is_empty(),"Hip assembly delivery and left-leg steps are locked: "+joined(unlocked))
	expect(progress.ready_count(tracked) >= 2,"other ready steps, got "+str(progress.ready_count(tracked)))
	# The heel pads are identical: whichever is started first is the first step.
	expect(game.model.move_assembly("pad_2","station:pad_2").is_empty(),"hang the authored second pad first")
	progress.refresh()
	tracked = progress.tracked()
	expect(str(tracked.get("owner","")) == "pad_2" and str(tracked.get("title","")) == pad_first and progress.status("pad_2",0) == "in_progress","hanging either pad starts the first heel-pad step, got "+str(tracked.get("owner",""))+" "+str(tracked.get("title",""))+" "+progress.status("pad_2",0))
	expect(progress.status("pad_1",0) == "ready","the untouched pad is the second step and ready, got "+progress.status("pad_1",0))
	var titles: Array[String] = []
	for chapter in progress.chapters():
		for step in chapter.steps:
			if str(step.owner) in ["pad_1","pad_2"]:titles.append(str(step.owner)+"="+str(step.title))
	expect(titles == ["pad_2="+pad_first,"pad_1="+pad_second],"chapter order follows start order, got "+joined(titles))
	expect(game.model.move_assembly("pad_2","loose").is_empty(),"return the untouched pad")
	progress.refresh()
	expect(str(progress.tracked().get("owner","")) == "pad_1","returning an untouched pad releases its step, got "+str(progress.tracked().get("owner","")))
	fit_slots(game.model,"pad_2",["sleeve_0"])
	progress.refresh()
	tracked = progress.tracked()
	expect(str(tracked.get("owner","")) == "pad_2" and str(tracked.get("title","")) == pad_first,"a sleeve on either pad starts the first step, got "+str(tracked.get("owner",""))+" "+str(tracked.get("title","")))
	progress.pin("pad_2",0)
	fit_slots(game.model,"pad_1",["sleeve_0","sleeve_1","sleeve_2","sleeve_3"])
	progress.refresh()
	tracked = progress.tracked()
	expect(progress.status("pad_1",0) == "done" and progress.status("pad_2",0) == "in_progress","finishing the later pad completes the second step only, got "+progress.status("pad_1",0)+" "+progress.status("pad_2",0))
	expect(str(tracked.get("owner","")) == "pad_2" and str(tracked.get("title","")) == pad_first,"the first step keeps its pad and pin, got "+str(tracked.get("owner",""))+" "+str(tracked.get("title","")))
	progress.pin("pitch",0)
	progress.refresh()
	tracked = progress.tracked()
	expect(str(tracked.get("owner","")) == "pitch" and int(tracked.get("page",-1)) == 0,"pin tracks pitch page 0, got "+str(tracked.get("owner",""))+" "+str(tracked.get("page","")))
	progress.unpin()
	tracked = progress.tracked()
	expect(str(tracked.get("owner","")) == "pad_2" and int(tracked.get("page",-1)) == 0,"unpin returns to the in-progress pad, got "+str(tracked.get("title","")))
	var kind := str(game.model.slot_definition("pad_1","sleeve_0").get("accepts",""))
	var found: Dictionary = progress.step_for_part(kind)
	expect(str(found.get("owner","")) == "pad_2" and str(found.get("title","")) == pad_first,"sleeve kind finds the unfinished pad, got "+str(found.get("owner",""))+" "+str(found.get("title","")))
	expect(progress.step_for_part("not-a-part").is_empty(),"unknown kind has no step")
	# Change-driven updates: no refresh() calls from here on. Earlier fits queued
	# one update; let it run before counting.
	await process_frame
	var updates := [0]
	progress.updated.connect(func():updates[0] += 1)
	await process_frame
	await process_frame
	expect(updates[0] == 0,"quiet frames do not recompute the manual, got "+str(updates[0]))
	fit_slots(game.model,"pad_2",["sleeve_1","sleeve_2","sleeve_3"])
	await process_frame
	expect(updates[0] == 1 and progress.status("pad_2",0) == "done","fitting parts updates the manual once by the next frame, got "+str(updates[0])+" "+progress.status("pad_2",0))
	game.equipment.manual_state_changed.emit()
	await process_frame
	expect(updates[0] == 2,"a machine state change updates the manual, got "+str(updates[0]))
	var passed = checks.all(func(check):return check.passed)
	print("MANUAL_PROGRESS ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
