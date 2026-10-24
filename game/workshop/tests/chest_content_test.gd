extends "res://tests/kit/harness.gd"
func _initialize() -> void:call_deferred("run")

func run() -> void:
	var game=preload("res://tests/kit/source_fixture.gd").new();root.add_child(game)
	expect(game.prepare_sources(["chest"]).is_empty(),"chest-only production source fixture configures")
	await frames(2)
	var chest=game.runtime.node("chest")
	var definition=game.runtime.definition("chest")
	var low=Vector3(INF,INF,INF);var high=-low
	for uid in definition.context_sources:
		var source: Dictionary=game.source[uid]
		for vertex in source.mesh.get_faces():
			var at: Vector3=source.transform*vertex;low=low.min(at);high=high.max(at)
	expect(low.x>=-2.74001 and high.x<=2.74001 and low.z>=-1.20001 and high.z<=1.35001,"actual prepared chest vertices fit the reserved horizontal envelope: "+str(low)+" / "+str(high))
	expect(low.y>=-.00001 and high.y<=4.28001,"prepared tails stow above the flange and neck pilot fits the height budget")
	expect(game.model.milestone("chest","prepared") and not game.model.milestone("chest","unknown"),"only explicitly supplied preparation milestones are complete")
	var invalid=game.model.definitions.duplicate(true)
	invalid.assemblies.chest.context_sources=[]
	expect(not AssemblyModel.validate_definitions(invalid).is_empty(),"slotless prepared assemblies require physical source context")
	var space=game.get_world_3d().direct_space_state
	for x in [-.84,.84]:
		for z in [-.58,.58]:
			var query=PhysicsRayQueryParameters3D.create(chest.global_transform*Vector3(x,.30,z),chest.global_transform*Vector3(x,-.10,z),4)
			expect(space.intersect_ray(query).is_empty(),"actual waist bolt bore remains open at "+str(Vector2(x,z)))
	for x in [-.92,.92]:
		for z in [-.25,.25]:
			var query=PhysicsRayQueryParameters3D.create(chest.global_transform*Vector3(x,-.03,z),chest.global_transform*Vector3(x,.125,z),4)
			expect(space.intersect_ray(query).is_empty(),"actual waist key pocket clears the 120 mm entering key")
	for y in [.25,.65,1.05]:
		var query=PhysicsRayQueryParameters3D.create(chest.global_transform*Vector3(0,y,2),chest.global_transform*Vector3(0,y,.8),4)
		expect(space.intersect_ray(query).is_empty(),"prepared rear spine preserves the core corridor at "+str(y))
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/chest-content.json",{"scope":"actual source bounds and interface bore rays; no visibility/reach acceptance","checks":checks})
	print("CHEST_CONTENT ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
