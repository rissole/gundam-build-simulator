extends RefCounted
## Checklist text, live ticking and load-time checks for manual objectives.
const OPS = ["fit","seat","operate","connect","detach"]
const MACHINE_OPS = ["operate","connect","detach"]

static func text(game, owner: String, objective: Dictionary) -> String:
	var op := str(objective.get("op",""))
	if op == "fit":
		var kinds: Array = []
		for sid in objective.get("slots",[]):
			kinds.append(str(game.model.slot_definition(owner,str(sid)).get("accepts","")))
		return fit_text(game.model.definitions.parts,kinds,str(objective.get("where","")))
	if op == "seat":
		var named: Dictionary = _seat_label(game,owner,objective)
		var label := str(named.label)
		var from_slot := bool(named.slot)
		if objective.has("via"):
			var via: Dictionary = objective.via if objective.via is Dictionary else {}
			var machine = game.equipment.get_equipment(str(via.get("machine","")))
			if machine == null:return ""
			return machine.command_label(str(via.get("command","")))+(" to seat the " if from_slot else " to seat ")+label
		if from_slot:return "Seat the "+label
		if game.model.slot_definition(owner,str(objective.get("slot",""))).has("assembly"):return "Seat the prepared "+label
		return "Seat "+label
	if op == "operate" or op == "connect" or op == "detach":
		var machine = game.equipment.get_equipment(str(objective.get("machine","")))
		if machine == null:return ""
		return machine.command_label(str(objective.get("command","")) if op == "operate" else op)
	return ""

## `kinds` lists accepted part kinds in slot order, including repeats.
static func fit_text(parts: Dictionary, kinds: Array, where: String = "") -> String:
	var order: Array[String] = []
	var counts: Dictionary = {}
	for kind in kinds:
		var key := str(kind)
		if not counts.has(key):
			order.append(key)
			counts[key] = 0
		counts[key] += 1
	var result := ""
	if order.size() == 1:
		var kind := order[0]
		var n := int(counts[kind])
		result = ("Fit "+str(parts[kind].title)) if n == 1 else ("Fit %d × %s"%[n,parts[kind].family])
	elif order.size() == 2 and counts[order[0]] == counts[order[1]]:
		var n := int(counts[order[0]])
		var a := str(parts[order[0]].family)
		var b := str(parts[order[1]].family)
		result = ("Fasten %s + %s"%[a,b]) if n == 1 else ("Fasten %d × %s + %s"%[n,a,b])
	else:
		var bits: PackedStringArray = []
		for kind in order:
			var n := int(counts[kind])
			bits.append(str(parts[kind].family) if n == 1 else "%d × %s"%[n,parts[kind].family])
		result = "Fit "+", ".join(bits)
	if not where.is_empty():result += " · "+where
	return result

static func evaluate(game, owner: String, page: Dictionary) -> Dictionary:
	var objectives: Array = page.get("objectives",[]) if page.get("objectives") is Array else []
	var ticked: Array[bool] = []
	var counts: Array[String] = []
	for i in objectives.size():
		ticked.append(false)
		counts.append("")
		if not objectives[i] is Dictionary:continue
		var objective: Dictionary = objectives[i]
		var op := str(objective.get("op",""))
		if op == "fit":
			var slots: Array = objective.get("slots",[]) if objective.get("slots") is Array else []
			var filled := 0
			for sid in slots:
				if _filled(game,owner,str(sid)):filled += 1
			ticked[i] = filled == slots.size()
			if slots.size() > 1:counts[i] = "%d/%d"%[filled,slots.size()]
		elif op == "seat":
			ticked[i] = _filled(game,owner,str(objective.get("slot","")))
		elif MACHINE_OPS.has(op):
			var machine = game.equipment.get_equipment(str(objective.get("machine","")))
			if machine != null:
				var count: Vector2i = machine.manual_count(objective)
				if count.y >= 0:counts[i] = "%d/%d"%[count.x,count.y]
	# Machine objectives tick through the latest cumulative state that still matches.
	var sequence: Array[int] = []
	for i in objectives.size():
		if not objectives[i] is Dictionary:continue
		var op := str(objectives[i].get("op",""))
		if MACHINE_OPS.has(op) or (op == "seat" and objectives[i].has("via")):sequence.append(i)
	var cumulative: Dictionary = {}
	var blind: Dictionary = {}
	var latest := -1
	for k in sequence.size():
		var objective: Dictionary = objectives[sequence[k]]
		var op := str(objective.get("op",""))
		var machine_id := ""
		var effect_objective := objective
		if op == "seat":
			var via: Dictionary = objective.via if objective.get("via") is Dictionary else {}
			machine_id = str(via.get("machine",""))
			effect_objective = {"op":"operate","command":str(via.get("command",""))}
		else:machine_id = str(objective.get("machine",""))
		if blind.get(machine_id,false):continue
		var machine = game.equipment.get_equipment(machine_id)
		if machine == null:
			blind[machine_id] = true
			continue
		var expected: Dictionary = cumulative.get(machine_id,{}).duplicate()
		expected.merge(machine.manual_effect(effect_objective),true)
		cumulative[machine_id] = expected
		var state: Dictionary = machine.manual_state()
		var matches := true
		for key in expected:
			if state.get(key) != expected[key]:
				matches = false
				break
		if matches:latest = k
	for k in sequence.size():
		if k > latest:break
		var index := sequence[k]
		var objective: Dictionary = objectives[index]
		var op := str(objective.get("op",""))
		var machine_id := str(objective.get("machine",""))
		if op == "seat":
			var via: Dictionary = objective.via if objective.get("via") is Dictionary else {}
			machine_id = str(via.get("machine",""))
		if blind.get(machine_id,false):continue
		ticked[index] = true
	var fits_complete := true
	var started := false
	var current := -1
	for i in objectives.size():
		if ticked[i]:started = true
		elif current < 0:current = i
		if objectives[i] is Dictionary:
			var op := str(objectives[i].get("op",""))
			if (op == "fit" or op == "seat") and not ticked[i]:fits_complete = false
	return {"ticked":ticked,"counts":counts,"current":current,"fits_complete":fits_complete,"machine_complete":sequence.is_empty() or latest == sequence.size()-1,"started":started}

static func done_states(game, steps: Array) -> Array[bool]:
	var evals: Array = []
	for step in steps:evals.append(evaluate(game,str(step.owner),step.page))
	var done: Array[bool] = []
	done.resize(steps.size())
	for i in range(steps.size()-1,-1,-1):
		var page: Dictionary = steps[i].page
		var started_next := false
		if i+1 < steps.size():
			var next: Dictionary = steps[i+1].page
			if next.has("objectives"):started_next = bool(evals[i+1].started) or done[i+1]
			else:
				var began := false
				for sid in next.get("slots",[]):
					if _filled(game,str(steps[i+1].owner),str(sid)):began = true
				started_next = began or done[i+1]
		if page.has("objectives"):done[i] = bool(evals[i].fits_complete) and (bool(evals[i].machine_complete) or started_next)
		else:
			var slots: Array = page.get("slots",[]) if page.get("slots") is Array else []
			if slots.is_empty():done[i] = started_next
			else:
				var filled := true
				for sid in slots:
					if not _filled(game,str(steps[i].owner),str(sid)):filled = false
				done[i] = filled
	return done

static func errors(definitions: Dictionary, machines: Dictionary) -> Array[String]:
	var found: Array[String] = []
	var assemblies: Dictionary = definitions.get("assemblies",{})
	for def_id in assemblies:
		var definition: Dictionary = assemblies[def_id]
		if not definition is Dictionary:continue
		var slots: Dictionary = definition.get("slots",{}) if definition.get("slots") is Dictionary else {}
		var manual: Array = definition.get("manual",[]) if definition.get("manual") is Array else []
		var used: Dictionary = {}
		for index in manual.size():
			var page = manual[index]
			if not page is Dictionary or not page.has("objectives"):continue
			_check_page(str(def_id),index,page,slots,machines,used,found)
	return found

static func _seat_label(game, owner: String, objective: Dictionary) -> Dictionary:
	var spec: Dictionary = game.model.slot_definition(owner,str(objective.get("slot","")))
	if spec.has("assembly"):
		var child: Dictionary = game.model.definitions.assemblies[str(spec.assembly)]
		var part_id := str(child.get("part_id",""))
		if not part_id.is_empty():return {"label":part_id,"slot":false}
		var slot_label := str(spec.get("label",""))
		if not slot_label.is_empty():return {"label":slot_label.substr(0,1).to_lower()+slot_label.substr(1),"slot":true}
		return {"label":str(child.get("title","")),"slot":false}
	if spec.has("accepts"):return {"label":str(game.model.definitions.parts[str(spec.accepts)].get("family","")),"slot":false}
	return {"label":"","slot":false}

static func _filled(game, owner: String, sid: String) -> bool:
	return not str(game.model.assemblies[owner].slots.get(sid,"")).is_empty()

static func _command_known(machines: Dictionary, machine_id: String, command: String) -> bool:
	return not machine_id.is_empty() and machines.has(machine_id) and command in machines[machine_id]

static func _check_page(def_id: String, index: int, page: Dictionary, slots: Dictionary, machines: Dictionary, used: Dictionary, found: Array[String]) -> void:
	var prefix := "%s page %d %s: "%[def_id,index+1,str(page.get("title",""))]
	if str(page.get("view","")) in ["overview","prepared"]:found.append(prefix+"summary pages carry no objectives")
	if str(page.get("goal","")).is_empty():found.append(prefix+"missing goal")
	var objectives: Array = page.get("objectives",[]) if page.get("objectives") is Array else []
	if not page.get("objectives") is Array:found.append(prefix+"objectives are not a list")
	var seen_page: Dictionary = {}
	var page_slots: Array = page.get("slots",[]) if page.get("slots") is Array else []
	for sid in page_slots:
		var key := str(sid)
		if seen_page.has(key):found.append(prefix+"slot listed twice: "+key)
		seen_page[key] = true
	var seen_obj: Dictionary = {}
	var positions: Dictionary = {}
	for i in objectives.size():
		if not objectives[i] is Dictionary:
			found.append(prefix+"objective %d is not an object"%i)
			continue
		var objective: Dictionary = objectives[i]
		var op := str(objective.get("op",""))
		if not OPS.has(op):
			found.append(prefix+"unknown op "+op)
			continue
		if op == "fit" and not (objective.get("slots") is Array and not objective.slots.is_empty()):found.append(prefix+"fit needs slots")
		elif op == "seat" and str(objective.get("slot","")).is_empty():found.append(prefix+"seat needs a slot")
		elif op == "operate" and (str(objective.get("machine","")).is_empty() or str(objective.get("command","")).is_empty()):found.append(prefix+"operate needs a machine and command")
		elif (op == "connect" or op == "detach") and str(objective.get("machine","")).is_empty():found.append(prefix+"%s needs a machine"%op)
		if op == "operate" and not str(objective.get("machine","")).is_empty() and not str(objective.get("command","")).is_empty():
			var machine_id := str(objective.machine)
			var command := str(objective.command)
			if not _command_known(machines,machine_id,command):found.append(prefix+"unknown command %s on %s"%[command,machine_id])
			elif command == "pickup" and str(objective.get("task","")).is_empty():found.append(prefix+"pickup needs a task")
		elif (op == "connect" or op == "detach") and not str(objective.get("machine","")).is_empty():
			var machine_id := str(objective.machine)
			if not _command_known(machines,machine_id,op):found.append(prefix+"unknown command %s on %s"%[op,machine_id])
		if op == "seat" and objective.has("via"):
			var via = objective.via
			var machine_id := ""
			var command := ""
			if via is Dictionary:
				machine_id = str(via.get("machine",""))
				command = str(via.get("command",""))
			if not _command_known(machines,machine_id,command):found.append(prefix+"unknown command %s on %s"%[command,machine_id])
		if op == "seat" and not str(objective.get("slot","")).is_empty() and not slots.has(str(objective.slot)):found.append(prefix+"seat slot is not in the definition")
		for sid in _objective_slots(objective):
			var key := str(sid)
			if seen_obj.has(key):found.append(prefix+"slot listed twice: "+key)
			seen_obj[key] = true
			if not positions.has(key):positions[key] = []
			positions[key].append(i)
	var same := seen_page.size() == seen_obj.size()
	if same:
		for sid in seen_page:
			if not seen_obj.has(sid):same = false
	if not same:found.append(prefix+"objective slots do not match the page")
	for sid in seen_obj:
		if used.has(sid):found.append(prefix+"slot %s is covered on another page"%sid)
		else:used[sid] = true
		var spec: Dictionary = slots.get(sid,{}) if slots.get(sid) is Dictionary else {}
		var requires: Array = spec.get("requires",[]) if spec.get("requires") is Array else []
		for required in requires:
			for at in positions.get(str(required),[]):
				if int(at) > int(positions[sid][0]):
					found.append(prefix+"%s is before its prerequisite %s"%[sid,str(required)])
					break
	if page.has("note") and not _note_ok(page.note,objectives.size()):found.append(prefix+"note is outside its objective or empty")

static func _objective_slots(objective: Dictionary) -> Array:
	var op := str(objective.get("op",""))
	if op == "fit" and objective.get("slots") is Array:return objective.slots
	if op == "seat" and not str(objective.get("slot","")).is_empty():return [str(objective.slot)]
	return []

static func _note_ok(note, count: int) -> bool:
	if not note is Dictionary:return false
	var at = note.get("at",null)
	if not (at is int or (at is float and float(int(at)) == at)):return false
	if int(at) < 0 or int(at) >= count:return false
	return not str(note.get("text","")).is_empty()
