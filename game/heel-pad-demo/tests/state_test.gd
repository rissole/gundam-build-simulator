extends SceneTree
var checks: Array[Dictionary] = []

func expect(condition: bool, name: String) -> void:
	checks.append({"check":name,"passed":condition})
	if not condition:push_error(name)

func _initialize() -> void:
	var config = JSON.parse_string(FileAccess.get_file_as_string("res://assets/heel-pad.json"))
	var s = HeelAssemblyState.new()
	s.configure(config)
	expect(s.items.size()==13,"13 physical source identities")
	for kind in HeelAssemblyState.KINDS:
		for i in range(4):s.take(kind)
	expect(s.pocket_count()==12,"Finite bins transfer all twelve hardware pieces")
	expect(s.take("bolt").is_empty(),"Empty bin cannot create extra inventory")
	s.move_pad("held")
	expect(not s.mount().ok,"Incomplete pad cannot mount")
	s.move_pad("prep")
	expect(not s.install("bolt",0).ok,"Bolts cannot attach on an unsupported pad")
	for i in [3,0,2,1]:expect(s.install("sleeve",i).ok,"Sleeve %d can install in independent order"%i)
	expect(s.prepared(),"Four sleeves complete the prepared pad")
	expect(not s.install("sleeve",0).ok,"Occupied socket rejects duplicate placement")
	s.move_pad("held")
	expect(s.mount().ok,"Prepared carried pad mounts")
	expect(not s.install("bolt",1).ok,"Each bolt requires its own washer")
	for i in [1,3,0,2]:
		expect(s.install("washer",i).ok,"Washer %d installs"%i)
		expect(s.install("bolt",i).ok,"Bolt %d follows its local washer"%i)
	expect(s.complete(),"Four valid mounts complete the heel pad")
	expect(s.integrity_errors().is_empty(),"Completed inventory has no duplicates or invalid dependencies")
	expect(s.pocket_count()==0,"Completion consumes exactly twelve hardware pieces")
	for i in range(13):
		var result = s.undo()
		expect(result.ok,"Build history undo %d"%i)
		expect(s.integrity_errors().is_empty(),"Undo %d preserves identities and dependencies"%i)
	expect(not s.complete() and not s.prepared(),"Undo restores unfinished build")
	expect(s.pocket_count()==12 and s.pad_location=="prep","Undo returns hardware without rewinding walking or storage")
	expect(not s.undo().ok,"Empty history is harmless")
	var uid = s.drop("washer")
	expect(s.items[uid].location=="loose","Dropping changes ownership without creating an item")
	expect(s.take("washer","loose",uid)==uid,"Recollecting preserves physical identity")
	s.capacity = s.pocket_count()
	var return_uid = s.return_to_bin("bolt")
	expect(not return_uid.is_empty(),"Storage return supported")
	s.capacity = s.pocket_count()
	expect(s.take("bolt").is_empty(),"Pocket capacity is enforced")
	var passed = checks.all(func(c):return c.passed)
	var output = {"passed":passed,"checks":checks,"engine":Engine.get_version_info().string}
	FileAccess.open("res://verification/state-audit.json",FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	print("STATE_AUDIT ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
