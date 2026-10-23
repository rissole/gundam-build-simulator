extends RefCounted
const Legacy = preload("res://scripts/m1_staging.gd")
static func prepare(game: Node) -> void:
	for pair in [["pad_1","prep"],["pad_2","prep2"],["pitch","prep3"]]:
		assert(game.model.move_assembly(pair[0],"station:"+pair[1]).is_empty())
		game._activate(pair[0]);game._set_pad_station(pair[1]);Legacy.fill(game,pair[0])
	for child in ["pad_1","pad_2","pitch"]:
		if child == "pitch":Legacy.fill(game,"foot")
		assert(game.model.move_assembly(child,"held").is_empty())
		var sid: String = {"pad_1":"heel_1","pad_2":"heel_2","pitch":"pitch"}[child]
		assert(game.model.install("foot",sid,child).ok)
		game.runtime.mount("foot",sid,child)
	Legacy.fill(game,"foot")
	assert(game.model.install_supported("left_leg","foot","foot","foot_carrier").ok)
	game.runtime.mount("left_leg","foot","foot")
	var permitted: Array = game.leg_content.m2.staged_slots.left_leg
	for pass_index in range(60):
		var changed = false
		for sid in game.runtime.definition("left_leg").slots:
			if not sid in permitted or not game.model.assemblies.left_leg.slots[sid].is_empty():continue
			var spec: Dictionary = game.model.slot_definition("left_leg",sid)
			if spec.has("assembly") or not spec.get("requires",[]).all(func(id):return not game.model.assemblies.left_leg.slots[id].is_empty()):continue
			for uid in game.model.items:
				var item: Dictionary = game.model.items[uid]
				if item.kind != spec.accepts or not item.owner.is_empty():continue
				var result: Dictionary
				if spec.get("support_required",false):
					var from: String = item.location.trim_prefix("support:")
					var support: String = spec.source_supports[0]
					if from != support:assert(game.model.transfer_supported_item(uid,from,support).is_empty())
					result = game.model.install_supported("left_leg",sid,uid,support)
				else:
					if game.model.definitions.parts[item.kind].carry_class == "pocket":
						if item.location != "pocket":
							game.model.transfer(item.kind,"bin","pocket",uid)
					else:assert(game.model.carry_item(uid).is_empty())
					result = game.model.install("left_leg",sid,uid)
				assert(result.ok,str(result));changed = true;break
		if not changed:break
	game.components.sync("left_leg")
	game.refresh_assembly_collision("left_leg")
	game._activate("pad_1")
