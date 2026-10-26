extends "res://tests/pickup_surfaces_test.gd"
## Isolated actual aim/prompt/click cases. No player walking or access sweep.
class ConnectionEquipment extends Equipment:
	func placement_error(_owner,_sid):return ""
class ConnectionFixture extends Fixture:
	var foot: Node3D
	var prepared_flags = {}
	var completed_flags = {}
	func equipment_access_error(_owner):return ""
	func interactable_assembly(_owner):return true
	func assembly_node(owner):return runtime.node(owner)
	func slot_pose(owner,sid):return runtime.slot_pose(owner,sid)
	func _visible(point,allowed = [],assisted = false,depth = .065):return targeting.can_see(point,allowed,assisted,depth)
	func _snap_guidance_message():return targeting.snap_guidance_message()
	func attach():components.attach_target()
	func _mesh(uid):
		var visual = MeshInstance3D.new();visual.mesh = source[uid].mesh;return visual
	func refresh_assembly_collision(_owner):pass
	func _carry_placement_error(destination,carried,receiver):
		var excluded: Array[RID] = [carried.get_rid(),player.get_rid(),receiver.get_rid()]
		return SolidHandling.sweep_error(carried,destination,excluded,WORLD_MASK)
func _initialize():run.call_deferred()
func click(game: ConnectionFixture):
	var event = InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_LEFT;event.pressed = true;game.input.handle(event)
func run():
	var game = ConnectionFixture.new();root.add_child(game);game.equipment = ConnectionEquipment.new()
	var slots = {"first":{"accepts":"bolt","pose_source":"bolt","target":[-.25,0,0],"snap_position":[-.25,0,0]},"next":{"accepts":"bolt","pose_source":"bolt","requires":["first"],"target":[.25,0,0],"snap_position":[.25,0,0]}}
	slots.bar = {"accepts":"bar","pose_source":"bar","target":[0,0,0],"snap_position":[0,0,0]}
	var definitions = {"version":1,"parts":{"bar":{"family":"bar","title":"Bar","carry_class":"hand"},"bolt":{"family":"bolt","title":"Bolt","carry_class":"pocket"},"wrong":{"family":"wrong","title":"Wrong bolt","carry_class":"pocket"}},"assemblies":{"frame":{"slots":slots}}}
	var scenario = {"version":1,"parts":[{"instance_id":"bar","kind":"bar"},{"instance_id":"b0","kind":"bolt"},{"instance_id":"b1","kind":"bolt"},{"instance_id":"w0","kind":"wrong"}],"parents":[{"id":"frame","definition":"frame"}],"builds":[]}
	expect(game.model.configure(definitions,scenario).is_empty(),"Connection fixture configures real prerequisites and part compatibility")
	var frame = WorkshopPart.new();frame.freeze = true;frame.collision_layer = 2;game.add_child(frame);game.bodies.frame = frame;game.foot = frame
	var receiver_mesh = BoxMesh.new();receiver_mesh.size = Vector3(.9,.25,.10)
	var visual = MeshInstance3D.new();visual.mesh = receiver_mesh;frame.add_child(visual)
	var proxy = CollisionShape3D.new();var proxy_box = BoxShape3D.new();proxy_box.size = Vector3(.9,.25,.16);proxy.shape = proxy_box;frame.add_child(proxy)
	var bolt_mesh = BoxMesh.new();bolt_mesh.size = Vector3(.025,.025,.025);game.source.bolt = {"mesh":bolt_mesh,"transform":Transform3D.IDENTITY}
	game.runtime = AssemblyRuntime.new(game.model,game.source);game.runtime.register_node("frame",frame)
	game.components.setup()
	# A small authored hotspot makes its slight-offset assistance explicit.
	game.components.presentation = {"frame":{"slots":{"first":{"target_radius":.04},"next":{"target_radius":.04},"bar":{"target_radius":.04}}}}
	game.components.invalidate_candidate_geometry()
	game.model.stock_pocket("bolt");game.selected_kind = "bolt"
	await frames(2)
	aim(game,Vector3(.25,0,1),Vector3(.25,0,0))
	expect(game.target.get("sid","") == "next" and game.hud.caption.contains("Missing prerequisite") and not game.ghost.visible,"Unmet prerequisite remains discoverable with a reason and no placement preview")
	click(game)
	expect(game.model.assemblies.frame.slots.next.is_empty() and game.hud.message.contains("Missing prerequisite"),"Real click repeats prerequisite refusal without changing ownership")
	game.model.stock_pocket("wrong");game.selected_kind = "wrong"
	aim(game,Vector3(-.25,0,1),Vector3(-.25,0,0))
	expect(game.target.get("sid","") == "first" and game.hud.caption.contains("Compatible next component") and not game.ghost.visible,"Wrong selected part still reveals the exposed connection and required component")
	click(game)
	expect(game.model.assemblies.frame.slots.first.is_empty() and game.hud.message.contains("Compatible next component"),"Wrong-part click preserves the real model's compatibility gate")
	# Aim at workpiece material beyond the small point radius. This used to be
	# discarded because the selected part did not have placement permission.
	aim(game,Vector3(-.37,0,1),Vector3(-.37,0,0))
	expect(game.target.get("discovery_only",false) and game.hud.caption.contains("Compatible next component") and not game.ghost.visible,"Visible-workpiece discovery explains a wrong part beyond the precise hotspot")
	game.selected_kind = "bolt";game.model.stock_pocket("bolt")
	aim(game,Vector3(-.299,0,1),Vector3(-.299,0,0))
	expect(game.target.get("sid","") == "first" and not game.target.get("discovery_only",false) and game.ghost.visible,"A 9 mm aim offset beyond the small hotspot is assisted at an exposed connection")
	expect(game.targeting.access(game.targeting.target_receivers()).is_empty(),"A 15 mm shallow proxy excess is accepted only after checking actual receiver material")
	# Move the same fixture beyond reach; the normal point remains discoverable.
	aim(game,Vector3(-.25,0,2.5),Vector3(-.25,0,0))
	expect(game.target.get("sid","") == "first" and game.hud.caption.contains("Move closer"),"Out-of-reach exposed connection gives a useful approach instruction")
	click(game)
	expect(game.model.assemblies.frame.slots.first.is_empty(),"Out-of-reach click cannot fit the component")
	# Proxy leniency cannot look through actual thick receiver material.
	receiver_mesh.size.z = .16
	aim(game,Vector3(-.25,0,1),Vector3(-.25,0,0))
	expect(game.target.get("discovery_only",false) and game.hud.caption.contains("obstructed") and not game.ghost.visible,"Actual receiver material blocks the same shallow route and leaves only surface context")
	click(game)
	expect(game.model.assemblies.frame.slots.first.is_empty() and game.hud.message.contains("obstructed"),"Click agrees that the actual receiver obstruction still prevents fitting")
	receiver_mesh.size.z = .10
	var wall = StaticBody3D.new();wall.collision_layer = 1;game.add_child(wall)
	var wall_shape = CollisionShape3D.new();var wall_box = BoxShape3D.new();wall_box.size = Vector3(2,2,.1);wall_shape.shape = wall_box;wall.add_child(wall_shape);wall.position.z = .5
	await frames(2)
	aim(game,Vector3(-.25,0,1),Vector3(-.25,0,0))
	expect(game.target.is_empty() and game.hud.caption.is_empty() and not game.ghost.visible,"True scenery occlusion hides connection context and every preview")
	click(game)
	expect(game.model.assemblies.frame.slots.first.is_empty(),"Click cannot install through a wall")
	wall.free()
	await frames(2)
	# The normal input finally succeeds at the very same exposed physical site.
	aim(game,Vector3(-.25,0,1),Vector3(-.25,0,0));click(game)
	expect(not game.model.assemblies.frame.slots.first.is_empty(),"Exposed in-reach assisted connection installs through actual mouse input")
	frame.rotation = Vector3(.1,.6,.2)
	var next = game.components.slot_point("frame","next")
	await frames(2)
	aim(game,next+frame.global_basis.z,next)
	expect(game.target.get("sid","") == "next" and game.ghost.visible,"Prerequisite completion and rotated receiver targets update without stale discovery geometry")
	var stable = true
	for offset in [-.006,-.003,0.0,.003,.006]:
		var at: Vector3 = next+frame.global_basis.x*offset
		aim(game,at+frame.global_basis.z,at)
		stable = stable and game.target.get("sid","") == "next"
	expect(stable,"Small aim jitter keeps the exposed compatible neighbour selected on the rotated workpiece")
	# A visible point does not bypass the hand load's real insertion sweep.
	game.model.carry_item("bar");game.selected_kind = "bar"
	var bar_mesh = BoxMesh.new();bar_mesh.size = Vector3(.12,.12,.12);game.source.bar = {"mesh":bar_mesh,"transform":Transform3D.IDENTITY}
	game._spawn_loose("bar");var carried: WorkshopPart = game.loose.bar;game.loose.erase("bar")
	carried.held = true;carried.position = Vector3(.6,0,1)
	var carried_shape = CollisionShape3D.new();var carried_box = BoxShape3D.new();carried_box.size = bar_mesh.size;carried_shape.shape = carried_box;carried.add_child(carried_shape)
	game.components.held_body = carried
	var obstruction = StaticBody3D.new();obstruction.collision_layer = 1;game.add_child(obstruction);obstruction.position = Vector3(.3,0,.5)
	var obstacle_shape = CollisionShape3D.new();var obstacle_box = BoxShape3D.new();obstacle_box.size = Vector3(.16,.3,.16);obstacle_shape.shape = obstacle_box;obstruction.add_child(obstacle_shape)
	# Reset the receiver rotation to keep the clear view and obstructed load
	# approach separate in this small, independently understandable fixture.
	frame.rotation = Vector3.ZERO
	await frames(2)
	aim(game,Vector3(0,0,1),Vector3.ZERO)
	expect(game.target.get("sid","") == "bar" and game.hud.caption.contains("approach is blocked") and not game.ghost.visible,"Clear visible target still explains a real blocked insertion sweep without a placement preview")
	click(game)
	expect(game.model.assemblies.frame.slots.bar.is_empty() and game.hud.message.contains("approach is blocked"),"Click preserves insertion-path collision after forgiving connection discovery")
	obstruction.free()
	var passed = checks.all(func(c):return c.passed)
	print("CONNECTION_DISCOVERY ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
