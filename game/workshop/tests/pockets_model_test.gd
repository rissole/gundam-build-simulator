extends "res://tests/kit/harness.gd"
func _initialize() -> void:
	var data = {"version":1,"parts":{"body":{"family":"BODY","title":"BODY","carry_class":"hand"}},"assemblies":{
		"unit":{"root_slot":"base","slots":{"base":{"accepts":"body"},"screw":{"accepts":"kind0","requires":["base"]}},"milestones":{"ready":["base","screw"]},"work_locations":["station"]},
		"fixture":{"slots":{"unit":{"assembly":"unit","milestone":"ready"}},"milestones":{"done":["unit"]}}}}
	var scenario = {"version":1,"parts":[{"instance_id":"root","kind":"body"}],"builds":[{"id":"unit","definition":"unit","base":"root"}],"parent":{"id":"fixture","definition":"fixture"}}
	for i in range(12):
		var kind = "kind%d"%i
		data.parts[kind] = {"family":"PART-%d"%i,"title":"PART-%d"%i,"carry_class":"pocket"}
		for j in range(25):scenario.parts.append({"instance_id":"%s_%d"%[kind,j],"kind":kind})
	data.parts.empty = {"family":"EMPTY","title":"EMPTY","carry_class":"pocket"}
	var model = AssemblyModel.new()
	expect(model.configure(data,scenario).is_empty(),"Ten-pocket fixture loads")
	for i in range(10):
		var result: Dictionary = model.stock_pocket("kind%d"%i)
		expect(result.ok and result.index==i and model.selected_pocket==i and model.pocket_size(i)==20,"Drawer fills and selects empty pocket %d"%i)
	expect(model.pocket_count()==200,"Ten separate stacks hold 200 pieces without a shared 20-item limit")
	var original: Array = model.pockets.duplicate()
	var full = model.stock_pocket("kind0")
	expect(full.ok and full.taken==0 and model.selected_pocket==0 and model.pockets==original,"Repeated E focuses a full matching stack without creating another pocket")
	model.select_pocket(9)
	var replacement = model.stock_pocket("kind10")
	expect(replacement.ok and replacement.index==9 and replacement.returned==20 and model.pockets[9]=="kind10","Full bar replaces only the selected pocket")
	expect(model.count_at("kind9","bin")==25 and model.count_at("kind10","bin")==5,"Replacement returns exact displaced identities to their drawer")
	expect(model.clear_pocket()==20 and model.pockets[9].is_empty(),"Clear returns the whole selected stack")
	model.select_pocket(2)
	expect(model.stock_pocket("kind11").index==9 and model.pockets[2]=="kind2","An empty pocket takes priority over replacing selected stock")
	model.move_assembly("unit","station:prep")
	var uid = model.find_item("kind0","pocket")
	expect(model.install("unit","screw",uid).ok and model.pocket_size(0)==19,"Installing consumes one copy from its actual pocket")
	expect(model.stock_pocket("kind0").taken==1 and model.pocket_size(0)==20,"E tops up a partial stack to 20")
	expect(model.undo("unit").ok and model.items[uid].location=="bin","Undo returns small hardware to its drawer when matching stack is full")
	expect(model.pocket_size(0)==20 and model.integrity_errors().is_empty(),"Undo never overfills or evicts a pocket")
	uid = model.find_item("kind0","pocket")
	model.install("unit","screw",uid)
	model.clear_pocket(0)
	model.stock_pocket("kind9")
	expect(model.undo("unit").ok and model.items[uid].location=="bin" and not model.pockets.has("kind0"),"Undo with ten different occupied pockets preserves their contents")
	model.clear_pocket(0)
	model.stock_pocket("kind0")
	uid = model.find_item("kind0","pocket")
	model.install("unit","screw",uid)
	expect(model.undo("unit").ok and model.items[uid].location=="pocket" and model.pocket_size(0)==20,"Undo returns the exact identity to a matching partial pocket")
	model.clear_pocket(0)
	# A known drawer with no remaining stock must leave selection and contents intact.
	var before = model.pockets.duplicate()
	var selected: int = model.selected_pocket
	expect(not model.stock_pocket("empty").ok and model.pockets==before and model.selected_pocket==selected,"Empty drawer does not evict or change selection")
	expect(not model.stock_pocket("body").ok,"Hand-sized components cannot occupy action-bar pockets")
	expect(model.integrity_errors().is_empty() and model.items.size()==301,"All physical identities survive refill, replacement, installation, clearing and undo")
	var passed: bool = checks.all(func(c):return c.passed)
	write_evidence("res://verification/pockets-model-audit.json",{"passed":passed,"checks":checks})
	print("POCKETS_MODEL_AUDIT ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
