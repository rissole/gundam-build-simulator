extends RefCounted
## Chapter order, live step status and the tracked step.
const Objectives = preload("res://scripts/manual_objectives.gd")

var game: Node
var pinned: Dictionary = {}
var _data: Dictionary = {}
var _status: Dictionary = {}
var _evaluation: Dictionary = {}
var _order: Array[Dictionary] = []

func _init(workshop: Node) -> void:
	game = workshop
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/manual-chapters.json"))
	if parsed is Dictionary:_data = parsed
	refresh()

func chapters() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var authored: Array = _data.get("chapters",[]) if _data.get("chapters") is Array else []
	for chapter in authored:
		if not chapter is Dictionary:continue
		var entries: Array = chapter.get("steps",[]) if chapter.get("steps") is Array else []
		if not _owners_present(entries):continue
		var steps: Array = []
		for entry in entries:
			var step := _make_step(entry)
			if step.is_empty():continue
			steps.append(step)
		var after: Array = chapter.get("after",[]) if chapter.get("after") is Array else []
		result.append({"id":str(chapter.get("id","")),"title":str(chapter.get("title","")),"after":after.duplicate(),"steps":steps})
	return result

func reference_steps() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var reference: Dictionary = _data.get("reference",{}) if _data.get("reference") is Dictionary else {}
	var entries: Array = reference.get("steps",[]) if reference.get("steps") is Array else []
	for entry in entries:
		var step := _make_step(entry)
		if step.is_empty():continue
		result.append(step)
	return result

func reference_title() -> String:
	var reference: Dictionary = _data.get("reference",{}) if _data.get("reference") is Dictionary else {}
	return str(reference.get("title","Recovery and undo"))

func refresh() -> void:
	var built := chapters()
	var flat: Array = []
	var rows: Array[Dictionary] = []
	var total_for: Dictionary = {}
	var done_for: Dictionary = {}
	for chapter in built:
		var steps: Array = chapter.steps
		var count := steps.size()
		total_for[str(chapter.id)] = count
		done_for[str(chapter.id)] = 0
		for index in count:
			var step: Dictionary = steps[index]
			flat.append({"owner":step.owner,"page":step.definition})
			rows.append({"owner":step.owner,"page":int(step.page),"title":str(step.title),"definition":step.definition,"chapter":chapter,"index":index+1,"count":count})
	var evaluations: Array = []
	for step in flat:evaluations.append(Objectives.evaluate(game,str(step.owner),step.page))
	var done: Array = Objectives.done_states(game,flat,evaluations)
	for i in rows.size():
		if done[i]:done_for[str(rows[i].chapter.id)] = int(done_for[str(rows[i].chapter.id)])+1
	var finished: Dictionary = {}
	for id in total_for:finished[id] = int(done_for[id]) == int(total_for[id])
	_status.clear()
	_evaluation.clear()
	_order = rows
	for i in rows.size():
		var row: Dictionary = rows[i]
		var evaluation: Dictionary = evaluations[i]
		var state := "ready"
		if done[i]:state = "done"
		elif _locked(row,i,done,finished):state = "locked"
		elif _started(row,evaluation):state = "in_progress"
		_status[_key(str(row.owner),int(row.page))] = state
		_evaluation[_key(str(row.owner),int(row.page))] = evaluation

func status(owner: String, page: int) -> String:
	return str(_status.get(_key(owner,page),""))

func evaluation(owner: String, page: int) -> Dictionary:
	var found = _evaluation.get(_key(owner,page),{})
	return found if found is Dictionary else {}

func tracked() -> Dictionary:
	if not pinned.is_empty():
		var row := _find(str(pinned.get("owner","")),int(pinned.get("page",-1)))
		if not row.is_empty() and status(str(row.owner),int(row.page)) != "done":return _public(row)
	for want in ["in_progress","ready"]:
		for row in _order:
			if status(str(row.owner),int(row.page)) == want:return _public(row)
	return {}

func pin(owner: String, page: int) -> void:
	pinned = {"owner":owner,"page":page}

func unpin() -> void:
	pinned = {}

func ready_count(except: Dictionary) -> int:
	var n := 0
	var skip := except.has("owner") and except.has("page")
	var owner := str(except.get("owner",""))
	var page := int(except.get("page",-1))
	for row in _order:
		var state := status(str(row.owner),int(row.page))
		if state != "ready" and state != "in_progress":continue
		if skip and str(row.owner) == owner and int(row.page) == page:continue
		n += 1
	return n

func chapter_progress(chapter: Dictionary) -> Vector2i:
	var id := str(chapter.get("id",""))
	var done_n := 0
	var total := 0
	for row in _order:
		if str(row.chapter.id) != id:continue
		total += 1
		if status(str(row.owner),int(row.page)) == "done":done_n += 1
	return Vector2i(done_n,total)

func step_for_part(kind: String) -> Dictionary:
	for row in _order:
		if status(str(row.owner),int(row.page)) == "done":continue
		if _empty_accepts(row,kind):
			return {"owner":row.owner,"page":int(row.page),"title":str(row.title),"definition":row.definition,"chapter":row.chapter}
	return {}

func _owners_present(entries: Array) -> bool:
	for entry in entries:
		if not entry is Array or entry.is_empty():return false
		if not game.model.assemblies.has(str(entry[0])):return false
	return true

func _make_step(entry) -> Dictionary:
	if not entry is Array or entry.size() < 2:return {}
	var owner := str(entry[0])
	if not game.model.assemblies.has(owner):return {}
	var page := int(entry[1])
	var manual := _manual(owner)
	if page < 0 or page >= manual.size() or not manual[page] is Dictionary:return {}
	var definition: Dictionary = manual[page]
	var title := str(definition.get("title",""))
	if entry.size() >= 3:title = str(entry[2])
	return {"owner":owner,"page":page,"title":title,"definition":definition}

func _manual(owner: String) -> Array:
	if not game.model.assemblies.has(owner):return []
	var definition := str(game.model.assemblies[owner].get("definition",""))
	var assemblies: Dictionary = game.model.definitions.assemblies
	if not assemblies.has(definition):return []
	var manual = assemblies[definition].get("manual",[])
	return manual if manual is Array else []

func _locked(row: Dictionary, index: int, done: Array, finished: Dictionary) -> bool:
	var after: Array = row.chapter.get("after",[]) if row.chapter.get("after") is Array else []
	for id in after:
		if not bool(finished.get(str(id),false)):return true
	var slots := _tracked_slots(row.definition)
	if slots.is_empty():
		if int(row.index) > 1 and not bool(done[index-1]):return true
		return false
	var mine: Dictionary = {}
	for sid in slots:mine[str(sid)] = true
	var owner := str(row.owner)
	var filled: Dictionary = game.model.assemblies[owner].slots
	for sid in slots:
		var requires = game.model.slot_definition(owner,str(sid)).get("requires",[])
		if not requires is Array:continue
		for required in requires:
			var rid := str(required)
			if mine.has(rid):continue
			if str(filled.get(rid,"")).is_empty():return true
	return false

func _started(row: Dictionary, evaluation: Dictionary) -> bool:
	if bool(evaluation.get("started",false)):return true
	var filled: Dictionary = game.model.assemblies[str(row.owner)].slots
	for sid in _tracked_slots(row.definition):
		if not str(filled.get(str(sid),"")).is_empty():return true
	return false

func _tracked_slots(page: Dictionary) -> Array:
	var result: Array = []
	if page.has("objectives"):
		var objectives: Array = page.get("objectives",[]) if page.get("objectives") is Array else []
		for objective in objectives:
			if not objective is Dictionary:continue
			var op := str(objective.get("op",""))
			if op == "fit":
				var listed: Array = objective.get("slots",[]) if objective.get("slots") is Array else []
				for sid in listed:result.append(str(sid))
			elif op == "seat" and not str(objective.get("slot","")).is_empty():result.append(str(objective.get("slot","")))
	else:
		var listed: Array = page.get("slots",[]) if page.get("slots") is Array else []
		for sid in listed:result.append(str(sid))
	return result

func _empty_accepts(row: Dictionary, kind: String) -> bool:
	var page: Dictionary = row.definition
	var owner := str(row.owner)
	var filled: Dictionary = game.model.assemblies[owner].slots
	var slots: Array = []
	if page.has("objectives"):
		var objectives: Array = page.get("objectives",[]) if page.get("objectives") is Array else []
		for objective in objectives:
			if not objective is Dictionary or str(objective.get("op","")) != "fit":continue
			var listed: Array = objective.get("slots",[]) if objective.get("slots") is Array else []
			for sid in listed:slots.append(str(sid))
	else:
		var listed: Array = page.get("slots",[]) if page.get("slots") is Array else []
		for sid in listed:slots.append(str(sid))
	for sid in slots:
		if not str(filled.get(sid,"")).is_empty():continue
		if str(game.model.slot_definition(owner,sid).get("accepts","")) == kind:return true
	return false

func _find(owner: String, page: int) -> Dictionary:
	for row in _order:
		if str(row.owner) == owner and int(row.page) == page:return row
	return {}

func _public(row: Dictionary) -> Dictionary:
	return {"owner":row.owner,"page":int(row.page),"title":str(row.title),"definition":row.definition,"chapter":row.chapter,"index":int(row.index),"count":int(row.count)}

func _key(owner: String, page: int) -> String:
	return owner+"#"+str(page)
