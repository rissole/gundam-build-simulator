extends RefCounted
## Disclosed M1-only setup. Use the existing recipes and each physical identity;
## the runnable trial is geometry/equipment assessment, not construction evidence.
static func fill(game: Node, owner: String) -> void:
	var definition: Dictionary = game.runtime.definition(owner)
	for pass_index in range(definition.slots.size()):
		var changed = false
		for sid in definition.slots:
			if not game.model.assemblies[owner].slots[sid].is_empty():continue
			var spec: Dictionary = definition.slots[sid]
			if spec.has("assembly") or not spec.get("requires",[]).all(func(id):return not game.model.assemblies[owner].slots[id].is_empty()):continue
			var uid = ""
			for candidate in game.model.items:
				var item: Dictionary = game.model.items[candidate]
				if item.kind == spec.accepts and item.owner.is_empty() and item.location != "installed":uid = candidate;break
			if uid.is_empty():continue
			var item: Dictionary = game.model.items[uid]
			var result: Dictionary
			if item.location.begins_with("support:"):
				result = game.model.install_supported(owner,sid,uid,item.location.trim_prefix("support:"))
			else:
				if game.model.definitions.parts[item.kind].carry_class == "pocket":game.model.transfer(item.kind,"bin","pocket",uid)
				else:game.model.carry_item(uid)
				result = game.model.install(owner,sid,uid)
			assert(result.ok,"M1 staging: "+str(result))
			changed = true
		if not changed:break
	if game.builds.has(owner):
		game._activate(owner)
		game._sync_installed_visuals()
	else:game.components.sync(owner)

static func prepare(game: Node) -> void:
	for pair in [["pad_1","prep"],["pad_2","prep2"],["pitch","prep3"]]:
		assert(game.model.move_assembly(pair[0],"station:"+pair[1]).is_empty())
		game._activate(pair[0]);game._set_pad_station(pair[1])
		fill(game,pair[0])
	for child in ["pad_1","pad_2","pitch"]:
		if child == "pitch":fill(game,"foot")
		assert(game.model.move_assembly(child,"held").is_empty())
		var sid: String = {"pad_1":"heel_1","pad_2":"heel_2","pitch":"pitch"}[child]
		assert(game.model.install("foot",sid,child).ok)
		game.runtime.mount("foot",sid,child)
	fill(game,"foot")
	assert(game.model.milestone("foot","complete"))
	assert(game.model.install_supported("left_leg","foot","foot","foot_carrier").ok)
	game.runtime.mount("left_leg","foot","foot")
	fill(game,"left_leg")
	assert(game.model.milestone("left_leg","structural_ready"))
	assert(game.model.transfer_supported_assembly("left_leg","leg_fixture","m1_leg_rail").is_empty())
	game.refresh_assembly_collision("left_leg")
	game._activate("pad_1")
