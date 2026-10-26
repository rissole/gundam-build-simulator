extends "res://tests/kit/harness.gd"
const Components = preload("res://scripts/component_interaction.gd")
class CountingComponents extends Components:
	var point_calls = 0
	func slot_point(owner: String, sid: String) -> Vector3:
		point_calls += 1
		return super.slot_point(owner,sid)
class Fixture extends Node3D:
	const SNAP_DISCOVERY_RANGE = 4.0
	var model = AssemblyModel.new()
	var runtime: AssemblyRuntime
	var source: Dictionary = {}
	var camera = Camera3D.new()
	var selected_kind = "bolt"
	func assembly_node(owner: String) -> Node3D:return runtime.node(owner)
	func source_uid(uid: String) -> String:return uid
	func slot_pose(owner: String, sid: String) -> Transform3D:return runtime.slot_pose(owner,sid)
	func interactable_assembly(owner: String) -> bool:
		return model.assemblies[model.top_level(owner)].location == "fixture"
func _initialize():call_deferred("run")
# Independent reference: exhaustive live slot discovery, before spatial filtering.
func exhaustive(game: Fixture, components: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for owner in game.model.assemblies:
		if not game.interactable_assembly(owner):continue
		var a: Dictionary = game.model.assemblies[owner]
		for sid in a.slots:
			var d: Dictionary = game.model.slot_definition(owner,sid)
			if d.has("assembly") or sid == components.definition(owner).get("root_slot","") or not a.slots[sid].is_empty():continue
			if d.has("target_child") and a.slots.get(d.target_child,"").is_empty():continue
			var point: Vector3 = components.slot_point(owner,sid)
			if game.camera.global_position.distance_to(point)>game.SNAP_DISCOVERY_RANGE:continue
			result.append({"type":"component","owner":owner,"sid":String(sid),"point":point,"radius":components.slot_presentation(owner,sid).get("target_radius",0.24),"compatible":d.accepts==game.selected_kind})
	return result
func compare(game: Fixture, components: Node, label: String) -> void:
	var actual: Array = components.candidates()
	var expected = exhaustive(game,components)
	expect(actual==expected,label)
func run():
	var game=Fixture.new();root.add_child(game);game.add_child(game.camera)
	var slots={"first":{"accepts":"bolt","target":[0,0,0]},"next":{"accepts":"bolt","requires":["first"],"target":[1,0,0]},"outside":{"accepts":"bolt","target":[12,0,0]},"moving":{"accepts":"bolt","pose_source":"source","snap_position":[0,0,0]}}
	var data={"version":1,"parts":{"bolt":{"family":"bolt","carry_class":"pocket"}},"assemblies":{"frame":{"slots":slots}}}
	data.parts.base={"family":"base","carry_class":"two_hand"}
	data.assemblies.leaf={"root_slot":"root","slots":{"root":{"accepts":"base"},"surface":{"accepts":"bolt","target":[0,0,0]}},"milestones":{"ready":["root"]}}
	slots.child={"assembly":"leaf","milestone":"ready","snap_position":[0,0,0]}
	slots.forwarded={"accepts":"bolt","requires":["child"],"target_child":"child","target_slot":"surface"}
	var parents: Array=[]
	for i in 65:parents.append({"id":"frame"+str(i),"definition":"frame"})
	var scenario={"version":1,"builds":[{"id":"leaf","definition":"leaf","base":"base0","location":"station:test"}],"parents":parents,"parts":[{"instance_id":"base0","kind":"base"},{"instance_id":"bolt0","kind":"bolt"},{"instance_id":"bolt1","kind":"bolt"}]}
	expect(game.model.configure(data,scenario).is_empty(),"isolated target fixture configures")
	var mesh=BoxMesh.new();game.source.source={"mesh":mesh,"transform":Transform3D.IDENTITY}
	game.runtime=AssemblyRuntime.new(game.model,game.source)
	for i in 65:
		var body=Node3D.new();game.add_child(body);body.position=Vector3(i*100,0,0);game.runtime.register_node("frame"+str(i),body)
	var leaf=Node3D.new();game.add_child(leaf);game.runtime.register_node("leaf",leaf)
	var moving_pose=Node3D.new();game.add_child(moving_pose);moving_pose.position=Vector3(2,0,0)
	game.runtime.mounted_poses["frame0.moving"]=func():return moving_pose.transform
	var components=CountingComponents.new(game);game.add_child(components);components.setup()
	compare(game,components,"nearby and distant owners match exhaustive discovery in original order")
	components.point_calls=0;components.candidates()
	expect(components.point_calls==1,"warm discovery evaluates only the articulated point, not distant static slots")
	game.camera.position=Vector3(12,0,0)
	compare(game,components,"authored target outside physical assembly bounds remains discoverable")
	game.camera.position=Vector3(16,0,0)
	compare(game,components,"exact discovery-range boundary remains inclusive")
	game.assembly_node("frame0").position=Vector3(9,0,0);game.assembly_node("frame0").rotation.y=PI/2
	compare(game,components,"translation and rotation update targets without rebuilding local geometry")
	moving_pose.position=Vector3(0,0,-3)
	compare(game,components,"articulated target changes are read live without a model event")
	game.selected_kind="wrong_variant"
	compare(game,components,"wrong variant retains inspection candidates")
	game.selected_kind="bolt";game.camera.position=Vector3(9,0,0)
	expect(game.model.stock_pocket("bolt").ok,"stock actual model pocket")
	expect(game.model.install("frame0","first","bolt0").ok,"install through actual model")
	compare(game,components,"installation removes occupied slot and exposes dependent target")
	expect(game.model.undo("frame0").ok,"undo through actual model")
	compare(game,components,"undo restores prerequisite target while keeping blocked dependent context")
	game.model.assemblies.frame0.location="held"
	compare(game,components,"live ownership access hides unavailable assembly")
	game.model.assemblies.frame0.location="fixture"
	expect(game.model.move_assembly("leaf","held").is_empty(),"pick up child through model")
	expect(game.model.install("frame0","child","leaf").ok,"mount child through model")
	game.runtime.mount("frame0","child","leaf")
	compare(game,components,"forwarded child connection resolves after mounting")
	leaf.position=Vector3(3,0,0)
	compare(game,components,"forwarded child target follows relative motion without a model event")
	var policy=preload("res://scripts/leg_journey_policy.gd").new(game)
	var candidates: Array[Dictionary]=[{"type":"bin","kind":"bolt"},{"type":"bin","kind":"missing"},{"type":"mount"}]
	expect(policy.filter_candidates(candidates)==[candidates[2]],"empty stock is filtered after pocket collection")
	game.model.items.bolt1.location="bin"
	expect(policy.filter_candidates(candidates)==[candidates[0],candidates[2]],"stock returns are visible immediately without cached counts")
	var passed=checks.all(func(c):return c.passed)
	print("TARGETING_CANDIDATES ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
