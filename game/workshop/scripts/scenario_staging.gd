extends RefCounted
## Disclosed scenario setup. Fills authored recipes with their real physical
## identities through the model APIs; it is never construction evidence.
## Every model call runs unconditionally; failures are reported, not asserted.

## Returns the number of installed identities. A negative limit fills everything.
static func fill(game: Node, owner: String, permitted: Array = [], limit: int = -1) -> int:
	var installed = 0
	var definition: Dictionary = game.runtime.definition(owner)
	for pass_index in range(definition.slots.size()):
		var changed = false
		for sid in definition.slots:
			if limit >= 0 and installed >= limit:break
			if not permitted.is_empty() and not sid in permitted:continue
			if not game.model.assemblies[owner].slots[sid].is_empty():continue
			var spec: Dictionary = game.model.slot_definition(owner,sid)
			if spec.has("assembly") or not spec.get("requires",[]).all(func(id):return not game.model.assemblies[owner].slots[id].is_empty()):continue
			var uid = ""
			for candidate in game.model.items:
				var item: Dictionary = game.model.items[candidate]
				if item.kind == spec.accepts and item.owner.is_empty() and item.location != "installed":uid = candidate;break
			if uid.is_empty():continue
			var item: Dictionary = game.model.items[uid]
			var result: Dictionary
			if spec.get("support_required",false) or item.location.begins_with("support:"):
				var from: String = item.location.trim_prefix("support:")
				var support: String = spec.get("source_supports",[from])[0]
				if from != support:_check(game.model.transfer_supported_item(uid,from,support),"transfer "+uid)
				result = game.model.install_supported(owner,sid,uid,support)
			else:
				if game.model.definitions.parts[item.kind].carry_class == "pocket":
					if item.location != "pocket":game.model.transfer(item.kind,"bin","pocket",uid)
				else:_check(game.model.carry_item(uid),"carry "+uid)
				result = game.model.install(owner,sid,uid)
			if not result.ok:
				push_error("Scenario staging: "+str(result))
				continue
			installed += 1
			changed = true
		if not changed or (limit >= 0 and installed >= limit):break
	game.components.sync(owner)
	return installed

## Completed foot on the leg, with the trial's permitted leg slots fitted.
static func prepare(game: Node) -> void:
	for pair in [["pad_1","prep"],["pad_2","prep2"],["pitch","prep3"]]:
		_check(game.automation.suspend_at_station(pair[0],pair[1]),"suspend "+pair[0])
		fill(game,pair[0])
	for child in ["pad_1","pad_2","pitch"]:
		if child == "pitch":fill(game,"foot")
		_check(game.model.move_assembly(child,"held"),"carry "+child)
		var sid: String = {"pad_1":"heel_1","pad_2":"heel_2","pitch":"pitch"}[child]
		_check_result(game.model.install("foot",sid,child),"mount "+child)
		game.runtime.mount("foot",sid,child)
	fill(game,"foot")
	if game.profile.trial == "m3":
		for owner in game.leg_content.get("prepared_branches",{}):
			var children: Array=game.leg_content.prepared_branches[owner]
			for index in range(children.size()):
				_check(game.automation.suspend_at_station(children[index],["prep","prep2","prep3"][index]),"suspend "+children[index])
				fill(game,children[index])
			for index in range(children.size()):
				if index==2:fill(game,owner)
				_check(game.model.move_assembly(children[index],"held"),"carry "+children[index])
				var sid: String=["heel_1","heel_2","pitch"][index]
				_check_result(game.model.install(owner,sid,children[index]),"mount "+children[index])
				game.runtime.mount(owner,sid,children[index])
			fill(game,owner)
			game.refresh_assembly_collision(owner)
		game.active_build = "pad_1"
		return
	_check_result(game.model.install_supported("left_leg","foot","foot","foot_carrier"),"seat foot on leg")
	game.runtime.mount("left_leg","foot","foot")
	fill(game,"left_leg",game.leg_content.m2.staged_slots.left_leg)
	game.refresh_assembly_collision("left_leg")
	game.active_build = "pad_1"

static func _check(error: String, label: String) -> void:
	if not error.is_empty():push_error("Scenario staging could not "+label+": "+error)

static func _check_result(result: Dictionary, label: String) -> void:
	if not result.get("ok",false):push_error("Scenario staging could not "+label+": "+str(result))
