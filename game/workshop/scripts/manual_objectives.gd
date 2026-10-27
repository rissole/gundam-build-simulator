extends RefCounted
## Checklist text, live ticking and load-time checks for manual objectives.
const OPS = ["fit","seat","operate","connect","detach"]
const MACHINE_OPS = ["operate","connect","detach"]

## Presentation only: completion, control cues and slot coverage always use the
## complete typed objectives. Repeated procedures hide only their machine work;
## independent hardware and other equipment instructions remain explicit.
static func display_indices(page: Dictionary, procedure: Dictionary) -> Array[int]:
	var result: Array[int]=[]
	var objectives: Array=page.get("objectives",[])
	for index in objectives.size():
		var objective: Dictionary=objectives[index]
		var machine: String=objective.get("machine",objective.get("via",{}).get("machine",""))
		if procedure.get("repeat",false) and machine in procedure.get("machines",[]):continue
		result.append(index)
	return result

static func machine_text(machine, objective: Dictionary, action: String) -> String:
	var subject: String = machine.manual_subject(objective)
	var hint: String = machine.manual_hint(objective)
	return (subject+": " if not subject.is_empty() else "")+machine.command_label(action,str(objective.get("task","")))+(" — "+hint if not hint.is_empty() else "")

## Notes show authored assembly details for the current objective, in both
## manual views.
static func note(page: Dictionary, current: int) -> String:
	var authored = page.get("note",{})
	if authored is Dictionary and int(authored.get("at",-1))==current:return str(authored.get("text",""))
	return ""

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
			var via_objective := {"op":"operate","command":via.command,"task":objective.get("task","")}
			return machine_text(machine,via_objective,via.command)+(" to seat the " if from_slot else " to seat ")+label
		if from_slot:return "Seat the "+label
		if game.model.slot_definition(owner,str(objective.get("slot",""))).has("assembly"):return "Seat the prepared "+label
		return "Seat "+label
	if op == "operate" or op == "connect" or op == "detach":
		var machine = game.equipment.get_equipment(str(objective.get("machine","")))
		if machine == null:return ""
		var command := str(objective.get("command",""))
		if op == "detach" and not str(objective.get("point","")).is_empty():command = "detach:"+str(objective.point)
		elif op != "operate":command = op
		return machine_text(machine,objective,command)
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
		# An operate objective may name the slots its control fills (captive bolts).
		if op == "fit" or (op == "operate" and objective.get("slots") is Array):
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
	var cumulative: Dictionary = page.get("machine_scope",{}).duplicate(true)
	var blind: Dictionary = {}
	var latest := -1
	var guards: Array = []
	if page.has("requires_state"):guards.append(page.requires_state)
	for k in sequence.size():
		var objective: Dictionary = objectives[sequence[k]]
		if objective.has("requires_state"):guards.append(objective.requires_state)
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
		# A later physical state can retire a temporary requirement (for example
		# latched backpack hinges no longer need crane tension).
		if not proves(game,objective.get("completed_by",{})):
			expected.merge(machine.manual_effect(effect_objective),true)
		cumulative[machine_id] = expected
		if blind.is_empty() and _machines_match(game,cumulative) and guards.all(func(guard):return proves(game,guard)):latest = k
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
		# A matching rig stop never substitutes for the physical installation.
		if op != "seat" and not objective.get("slots") is Array:ticked[index] = true
	var physical_complete := true
	for i in objectives.size():
		if objectives[i] is Dictionary and not _objective_slots(objectives[i]).is_empty() and not ticked[i]:physical_complete = false
	if physical_complete and proves(game,page.get("completed_by",{})):
		# Use the same resolved ticks in the sidebar and both objective panels.
		ticked.fill(true)
		for index in sequence:
			if _objective_slots(objectives[index]).is_empty():counts[index] = ""
		latest = sequence.size()-1
	var fits_complete := true
	var started := false
	var current := -1
	for i in objectives.size():
		if ticked[i]:started = true
		elif current < 0:current = i
		if objectives[i] is Dictionary:
			var op := str(objectives[i].get("op",""))
			if (op == "fit" or op == "seat" or (op == "operate" and objectives[i].get("slots") is Array)) and not ticked[i]:fits_complete = false
	return {"ticked":ticked,"counts":counts,"current":current,"fits_complete":fits_complete,"machine_complete":sequence.is_empty() or latest == sequence.size()-1,"started":started}

## `evals` may carry evaluate() results already computed for `steps`.
static func done_states(game, steps: Array, evals: Array = []) -> Array[bool]:
	if evals.size() != steps.size():
		evals = []
		for step in steps:evals.append(evaluate(game,str(step.owner),step.page))
	var done: Array[bool] = []
	done.resize(steps.size())
	for i in steps.size():
		var page: Dictionary = steps[i].page
		if page.has("objectives"):done[i] = int(evals[i].current) == -1 and not page.objectives.is_empty()
		else:
			var slots: Array = page.get("slots",[]) if page.get("slots") is Array else []
			if slots.is_empty():done[i] = false
			else:
				var filled := true
				for sid in slots:
					if not _filled(game,str(steps[i].owner),str(sid)):filled = false
				done[i] = filled
	return done

## Declarative physical evidence, never page order or remembered UI progress.
static func proves(game, condition: Dictionary) -> bool:
	if condition.is_empty():return false
	if condition.has("all"):
		return not condition.all.is_empty() and condition.all.all(func(item):return proves(game,item))
	if condition.has("any"):
		return condition.any.any(func(item):return proves(game,item))
	if condition.has("slot"):
		return game.model.assemblies.has(str(condition.owner)) and _filled(game,str(condition.owner),str(condition.slot))
	var machine = game.equipment.get_equipment(str(condition.get("machine","")))
	if machine == null:return false
	if condition.has("state"):return _state_matches(condition.state,machine.manual_state())
	return machine.manual_proves(condition)

static func _machines_match(game, expected: Dictionary) -> bool:
	for id in expected:
		var machine = game.equipment.get_equipment(str(id))
		if machine == null or not _state_matches(expected[id],machine.manual_state()):return false
	return true

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
			var prefix := "%s page %d: "%[def_id,index+1]
			for field in ["completed_by","requires_state"]:
				if page.has(field):_check_proof(page[field],definitions,machines,prefix,found)
			for objective in page.get("objectives",[]):
				if not objective is Dictionary:continue
				for field in ["completed_by","requires_state"]:
					if objective.has(field):_check_proof(objective[field],definitions,machines,prefix,found)
			if page.has("machine_scope"):
				if not page.machine_scope is Dictionary:found.append(prefix+"invalid machine scope")
				else:
					for id in page.machine_scope:
						if not machines.has(id) or not page.machine_scope[id] is Dictionary or page.machine_scope[id].is_empty():found.append(prefix+"invalid machine scope for "+str(id))
	return found

static func _check_proof(value, definitions: Dictionary, machines: Dictionary, prefix: String, found: Array[String]) -> void:
	if not value is Dictionary or value.is_empty():
		found.append(prefix+"empty or invalid completion evidence")
		return
	for key in ["all","any"]:
		if not value.has(key):continue
		if value.size()!=1 or not value[key] is Array or value[key].is_empty():found.append(prefix+"invalid completion evidence group")
		else:
			for child in value[key]:_check_proof(child,definitions,machines,prefix,found)
		return
	if value.has("slot"):
		var owner := str(value.get("owner",""))
		if value.size()!=2 or not definitions.assemblies.has(owner) or not definitions.assemblies.get(owner,{}).get("slots",{}).has(str(value.slot)):found.append(prefix+"unknown completion slot "+owner+"/"+str(value.slot))
		return
	if not machines.has(str(value.get("machine",""))):found.append(prefix+"unknown completion machine")
	if value.has("state"):
		if value.size()!=2 or not value.state is Dictionary or value.state.is_empty():found.append(prefix+"invalid completion state")
	elif value.size()!=3 or value.get("machine")!="service_crane" or str(value.get("task","")).is_empty() or value.get("phase") not in ["arrived","delivered","released","parked"]:found.append(prefix+"invalid transport evidence")

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
			elif command in ["pickup","go:receiver","go:source"] and str(objective.get("task","")).is_empty():found.append(prefix+command+" needs a task")
		elif (op == "connect" or op == "detach") and not str(objective.get("machine","")).is_empty():
			var machine_id := str(objective.machine)
			if not _command_known(machines,machine_id,op):found.append(prefix+"unknown command %s on %s"%[op,machine_id])
			# A detach may name one connector. Connect stays whole-rig.
			if op == "detach" and objective.has("point") and (not objective.point is String or str(objective.point).is_empty()):found.append(prefix+"detach point must name a connector")
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

static func _state_matches(expected: Dictionary, state: Dictionary) -> bool:
	for key in expected:
		if state.get(key) != expected[key]:return false
	return true

static func _objective_slots(objective: Dictionary) -> Array:
	var op := str(objective.get("op",""))
	if op in ["fit","operate"] and objective.get("slots") is Array:return objective.slots
	if op == "seat" and not str(objective.get("slot","")).is_empty():return [str(objective.slot)]
	return []

static func _note_ok(note, count: int) -> bool:
	if not note is Dictionary:return false
	var at = note.get("at",null)
	if not (at is int or (at is float and float(int(at)) == at)):return false
	if int(at) < 0 or int(at) >= count:return false
	return not str(note.get("text","")).is_empty()
