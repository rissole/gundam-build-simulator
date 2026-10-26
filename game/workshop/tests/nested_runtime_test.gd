extends "res://tests/kit/harness.gd"
## Four assembly levels, shared source geometry, real compound carrying physics.
class FixtureWorkshop:
	extends "res://scripts/workshop.gd"
	func _ready() -> void:pass

class FixtureHUD:
	extends CanvasLayer
	var manual_id: String = "bay_b"
	var target_panel = Panel.new()
	var target_label = Label.new()
	var last_toast: String = ""
	func refresh() -> void:pass
	func toast(message: String, _positive: bool = false) -> void:last_toast = message
	func manual_title() -> String:return manual_id
	func present_target(text: String, _key: String = "", _action: String = "", _point: Vector2 = Vector2(-1,-1), _valid: bool = false) -> void:
		target_label.text = text
		target_panel.visible = not text.is_empty()

var game: Node3D
var scene: Node3D
var capture: bool = false
var image_paths: Array[String] = []

func mesh_box(size: Vector3) -> BoxMesh:
	var mesh = BoxMesh.new()
	mesh.size = size
	return mesh

func compound_mesh(profile: Array) -> ArrayMesh:
	var surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for entry in profile:
		surface.append_from(mesh_box(AssemblyRuntime.vec(entry.size)),0,Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(entry.position)))
	return surface.commit()

func fixture_definitions() -> Dictionary:
	var frame_shapes = [
		{"type":"box","size":[3.6,0.18,0.18],"position":[0,0,-0.85]},
		{"type":"box","size":[3.6,0.18,0.18],"position":[0,0,0.85]},
		{"type":"box","size":[0.18,0.18,1.52],"position":[-1.71,0,0]}]
	return {"version":1,"parts":{
		"core":{"family":"CORE","title":"Core","carry_class":"two_hand"},
		"frame":{"family":"FRAME","title":"Open 3.6 m frame","carry_class":"two_hand","collision_shapes":frame_shapes,"handling":{"distance":2.0}},
		"carrier":{"family":"CARRIER","title":"Carrier","carry_class":"two_hand"},
		"bay":{"family":"BAY","title":"Bay base","carry_class":"two_hand"},
		"probe":{"family":"PROBE","title":"Slot proxy probe","carry_class":"pocket"}},
		"assemblies":{
			"core":{"root_slot":"root","slots":{"root":{"accepts":"core","pose_source":"core"},"probe":{"accepts":"probe","pose_source":"probe","requires":["root"],"collision_shapes":[{"type":"sphere","radius":0.05,"position":[0,0,0]}]}},"milestones":{"ready":["root"]},"work_locations":["station"]},
			"frame":{"root_slot":"root","handling":{"distance":2.2},"slots":{
				"root":{"accepts":"frame","pose_source":"frame"},
				"left":{"assembly":"core","milestone":"ready","pose_source":"core","snap_position":[-1.0,0.3,-0.85]},
				"right":{"assembly":"core","milestone":"ready","pose_source":"core","snap_position":[1.0,0.3,0.85]}},"milestones":{"ready":["root","left","right"]},"work_locations":["station"]},
			"carrier":{"root_slot":"root","frame_source":"carrier_frame","slots":{
				"root":{"accepts":"carrier","pose_source":"carrier"},
				"frame":{"assembly":"frame","milestone":"ready","pose_source":"frame","snap_position":[0,0.5,0],"snap_rotation_degrees":[0,15,0]}},"milestones":{"ready":["root","frame"]},"work_locations":["station"]},
			"bay":{"root_slot":"root","slots":{
				"root":{"accepts":"bay","pose_source":"bay"},
				"carrier":{"assembly":"carrier","milestone":"ready","pose_source":"carrier_frame","snap_position":[0,0.8,0],"snap_rotation_degrees":[0,0,25],"target_position":[1.2,1.1,0],"service_access":"assisted"}},"milestones":{"ready":["root","carrier"]},"work_locations":["fixture"]}}}

func fixture_scenario() -> Dictionary:
	return {"version":1,"parts":[
		{"instance_id":"copy_a/core","kind":"core","source_id":"core"},
		{"instance_id":"shared/probe","kind":"probe","source_id":"probe"},
		{"instance_id":"copy_b/core","kind":"core","source_id":"core"},
		{"instance_id":"copy_a/frame","kind":"frame","source_id":"frame"},
		{"instance_id":"copy_b/frame","kind":"frame","source_id":"frame"},
		{"instance_id":"copy_a/carrier","kind":"carrier","source_id":"carrier"},
		{"instance_id":"bay_a/base","kind":"bay","source_id":"bay"},
		{"instance_id":"bay_b/base","kind":"bay","source_id":"bay"}],
		"builds":[
			{"id":"core_a","definition":"core","base":"copy_a/core","location":"station:core_a"},
			{"id":"core_b","definition":"core","base":"copy_b/core","location":"station:core_b"},
			{"id":"frame_a","definition":"frame","base":"copy_a/frame","location":"station:frame_a"},
			{"id":"frame_b","definition":"frame","base":"copy_b/frame","location":"station:frame_b"},
			{"id":"carrier_a","definition":"carrier","base":"copy_a/carrier","location":"station:carrier_a"}],
		"parents":[{"id":"bay_a","definition":"bay","base":"bay_a/base"},{"id":"bay_b","definition":"bay","base":"bay_b/base"}]}

func mount(owner: String, sid: String, child: String) -> bool:
	if not game.model.move_assembly(child,"held").is_empty():return false
	var result: Dictionary = game.model.install(owner,sid,child)
	if not result.ok:return false
	game.runtime.mount(owner,sid,child)
	game.refresh_assembly_collision(owner)
	return true

func detach(owner: String, destination: String) -> Dictionary:
	var result: Dictionary = game.model.undo(owner,"station:"+destination)
	if result.ok:
		var body: Node3D = game.assembly_node(result.step.uid)
		body.reparent(game)
		body.position = Vector3(7,3,0)
		game.refresh_assembly_collision(owner)
		game.refresh_assembly_collision(result.step.uid)
	return result

func create_body(owner: String, index: int) -> void:
	var a: Dictionary = game.model.assemblies[owner]
	var d: Dictionary = game.model.definitions.assemblies[a.definition]
	var uid: String = a.slots[d.root_slot]
	var body = WorkshopPart.new()
	body.uid = uid
	body.kind = game.model.items[uid].kind
	body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	body.freeze = true
	body.can_sleep = false
	game.add_child(body)
	body.position = Vector3(index*5,3,0)
	game.runtime.register_node(owner,body)
	var visual = MeshInstance3D.new()
	visual.mesh = game.source[game.source_uid(uid)].mesh
	visual.set_meta("source_uid",game.source_uid(uid))
	visual.transform = game.runtime.local_slot_pose(owner,d.root_slot)
	visual.set_meta("component_uid",uid)
	visual.set_meta("slot_id",d.root_slot)
	body.add_child(visual)
	var material = StandardMaterial3D.new()
	material.albedo_color = [Color.CORNFLOWER_BLUE,Color.ORANGE,Color.MEDIUM_SEA_GREEN][index%3]
	visual.material_override = material
	game.bodies[owner] = body
	game.refresh_assembly_collision(owner)

func scenery(position: Vector3, dimensions: Vector3) -> StaticBody3D:
	var body = StaticBody3D.new()
	scene.add_child(body)
	body.position = position
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = dimensions
	col.shape = box
	body.add_child(col)
	var visual = MeshInstance3D.new()
	visual.mesh = mesh_box(dimensions)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.CRIMSON
	visual.material_override = material
	body.add_child(visual)
	return body

func capture_view(name: String, camera_position: Vector3, target: Vector3, focus_owner: String = "bay_a") -> void:
	if not capture:return
	game.ghost.visible = false
	for owner in game.model.assemblies:game.assembly_node(owner).visible = game.model.top_level(owner) == focus_owner
	game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	game.camera.size = 6.0
	game.camera.global_position = camera_position
	game.camera.look_at(target)
	await process_frame
	await RenderingServer.frame_post_draw
	var path = "res://verification/nested-runtime/"+name+".png"
	game.get_viewport().get_texture().get_image().save_png(path)
	image_paths.append(path)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	capture = OS.get_cmdline_user_args().has("--nested-capture") and DisplayServer.get_name() != "headless"
	scene = Node3D.new()
	root.add_child(scene)
	game = FixtureWorkshop.new()
	scene.add_child(game)
	var definitions = fixture_definitions()
	var scenario = fixture_scenario()
	for d in definitions.assemblies.values():d["interaction"] = "components"
	game.config = scenario
	game.components = load("res://scripts/component_interaction.gd").new(game)
	game.add_child(game.components)
	game.hud = FixtureHUD.new()
	game.add_child(game.hud)
	game.bind_build_views(scenario)
	expect(game.model.configure(definitions,scenario).is_empty(),"Multiple root-bearing parent fixtures validate without a literal foot ID")
	var bad_anchor: Dictionary = definitions.duplicate(true)
	bad_anchor.assemblies.bay.slots.carrier.child_anchor_slot = "missing"
	expect(not AssemblyModel.validate_definitions(bad_anchor).is_empty(),"Unknown authored child anchors are rejected before runtime placement")
	var broken: Dictionary = scenario.duplicate(true)
	broken.builds[0].id = "copy_a/core"
	expect(not AssemblyModel.new().configure(definitions,broken).is_empty(),"Assembly IDs cannot collide with physical item identities")
	game.source = {
		"core":{"mesh":mesh_box(Vector3(0.35,0.35,0.35)),"transform":Transform3D.IDENTITY},
		"probe":{"mesh":mesh_box(Vector3.ONE*0.08),"transform":Transform3D(Basis.IDENTITY,Vector3(0,0.25,0))},
		"frame":{"mesh":compound_mesh(definitions.parts.frame.collision_shapes),"transform":Transform3D.IDENTITY},
		"carrier":{"mesh":mesh_box(Vector3(0.5,0.35,0.5)),"transform":Transform3D.IDENTITY},
		"carrier_frame":{"mesh":mesh_box(Vector3.ONE*0.1),"transform":Transform3D(Basis.IDENTITY,Vector3(0.2,0.3,0))},
		"bay":{"mesh":mesh_box(Vector3(0.8,0.18,0.8)),"transform":Transform3D.IDENTITY}}
	game.runtime = AssemblyRuntime.new(game.model,game.source)
	for owner in game.model.assemblies:create_body(owner,game.bodies.size())
	expect(game.source_uid("copy_a/frame") == "frame" and game.source_uid("copy_b/frame") == "frame","Namespaced physical copies share one mesh source")
	expect(game.model.items.size() == 8,"Logical assemblies add no duplicate inventory objects")
	expect(SolidHandling.shapes(game.assembly_node("frame_b")).size() == 3,"Authored 3.6 m open frame uses three primitive solids")
	expect(SolidHandling.bounds(game.assembly_node("frame_b")).size.x > 3.5,"Physical fixture retains its full design scale")
	game.model.transfer("probe","bin","pocket")
	game.model.install("core_a","probe","shared/probe")
	game.components.sync("core_a")
	expect(SolidHandling.shapes(game.assembly_node("core_a")).size() == 2,"A pocket-sized slot can explicitly author a solid collision proxy")
	expect(mount("frame_a","left","core_b") and mount("frame_a","right","core_a"),"Interchangeable namespaced child copies retain swapped identities")
	expect(mount("carrier_a","frame","frame_a") and mount("bay_a","carrier","carrier_a"),"Three successive mounts form core → frame → carrier → bay")
	var authored_carrier_pose: Transform3D = game.assembly_node("bay_a").global_transform*Transform3D(Basis(Vector3.BACK,deg_to_rad(25)),Vector3(0,0.8,0))
	var authored_motor_pose = authored_carrier_pose*Transform3D(Basis.IDENTITY,Vector3(-0.2,-0.3,0))
	expect(game.assembly_node("carrier_a").global_transform.is_equal_approx(authored_carrier_pose) and game.assembly_node("carrier_a").get_child(0).global_transform.is_equal_approx(authored_motor_pose),"Authored child frame and offset starter mesh match independent expected poses after mounting")

	expect(not game.model.undo("frame_a").ok,"Deep child undo cannot silently invalidate mounted ancestors")
	expect(game.model.assembly_access_error("frame_a","left").contains("installed"),"Mounted internal work is locked by the explicit default access policy")
	game.model.definitions.assemblies.frame.access_policy = "mounted"
	game.model.definitions.assemblies.frame.work_locations.append("fixture")
	expect(game.model.assembly_access_error("frame_a","left").is_empty(),"Authored mounted access traverses to the stationary outer owner")
	game.model.definitions.assemblies.frame.erase("access_policy")
	var bay: WorkshopPart = game.assembly_node("bay_a")
	bay.position = Vector3(0,3,0)
	var other_pose: Transform3D = game.assembly_node("bay_b").global_transform
	var meshes_follow = true
	var physics_follow = true
	for tick in 30:
		await process_frame
		bay.basis = (Basis(Vector3.UP,0.027)*Basis(Vector3.RIGHT,0.019)*bay.basis).orthonormalized()
		for child in ["carrier_a","frame_a","core_a","core_b"]:
			var a: Dictionary = game.model.assemblies[child]
			var expected: Transform3D = game.runtime.mount_pose(a.parent,a.parent_slot,child)
			meshes_follow = meshes_follow and game.assembly_node(child).global_transform.is_equal_approx(expected)
			var visual: MeshInstance3D = game.assembly_node(child).get_child(0)
			meshes_follow = meshes_follow and visual.global_transform.is_equal_approx(expected*visual.transform)
		await frames()
		for child in ["carrier_a","frame_a","core_a","core_b"]:
			var body: WorkshopPart = game.assembly_node(child)
			var actual: Transform3D = PhysicsServer3D.body_get_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
			physics_follow = physics_follow and actual.is_equal_approx(body.global_transform)
	expect(meshes_follow and physics_follow,"All four scene and physics levels inherit continuous multi-axis rotation between input and physics ticks")
	expect(game.assembly_node("bay_b").global_transform.is_equal_approx(other_pose),"Rotating one receiving parent preserves the other parent")
	expect(SolidHandling.shapes(bay).size() == 8 and SolidHandling.shapes(game.assembly_node("core_a")).is_empty(),"Top owner carries nested compound; mounted children have no competing solids")
	game.active_build = "carrier_a"
	game.ghost_material = StandardMaterial3D.new()
	game.ghost = MeshInstance3D.new()
	game.add_child(game.ghost)
	game.automation.show_assembly_ghost("carrier_a")
	expect(game.ghost.get_child_count() == 5,"Carry preview includes every physical mesh through all nested levels")
	game.camera = Camera3D.new()
	game.add_child(game.camera)
	game.camera.current = true
	game.player = CharacterBody3D.new()
	game.add_child(game.player)
	var light = DirectionalLight3D.new()
	scene.add_child(light)
	light.rotation_degrees = Vector3(-55,-30,0)
	light.light_energy = 1.4
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://verification/nested-runtime"))
	await capture_view("01-nested-front",Vector3(5,7,8),Vector3(0,3.8,0))
	await capture_view("02-nested-rear",Vector3(-5,6,-6),Vector3(0,3.8,0))
	expect(detach("bay_a","out").ok and game.model.milestone("carrier_a","ready"),"Undo detaches the same complete nested assembly to an output station")
	expect(game.model.move_assembly("carrier_a","held").is_empty(),"Detached complete tree can be picked up without losing children")
	expect(game.model.install("bay_b","carrier","carrier_a").ok,"The same prepared tree installs into a different receiving parent")
	game.runtime.mount("bay_b","carrier","carrier_a")
	game.refresh_assembly_collision("bay_a")
	game.refresh_assembly_collision("bay_b")
	expect(SolidHandling.shapes(bay).size() == 1 and game.model.assemblies.core_b.parent == "frame_a","Reinstallation transfers all solids and preserves deep single ownership")
	expect(game.model.integrity_errors().is_empty(),"Nested mount, undo, pickup and reinstallation conserve every identity")
	# Exercise the actual workshop adapter against non-foot owners as well as the
	# shared runtime: undo selects an available station, targeting discovers the
	# real destination owner, and attach routes that owner through the tree.
	var output = Node3D.new()
	game.add_child(output)
	output.position = Vector3(-3,12,0)
	output.set_meta("work_volume",Vector3(10,10,10))
	game.stations["out_adapter"] = output
	game.hud.manual_id = "bay_b"
	game.active_build = "carrier_a"
	game.automation.select_build("carrier_a")
	game.undo_build()
	expect(SolidHandling.shapes(game.assembly_node("bay_b")).size() == 1,"Workshop mount undo removes detached descendant solids from the old owner")
	expect(game.model.assemblies.carrier_a.location == "station:out_adapter","Workshop undo resolves a non-foot parent history and returns its nested child")
	var carried: WorkshopPart = game.assembly_node("carrier_a")
	game.camera.global_position = carried.global_position+Vector3(0,0,1.5)
	game.camera.look_at(carried.global_position)
	game.target = {"type":"assembly","build":"carrier_a","point":carried.global_position}
	game.interact()
	expect(game.model.assemblies.carrier_a.location == "held" and carried.held,"Workshop pickup retains the entire three-level prepared child tree")
	var retained_tree = game.model.assemblies.duplicate(true)
	carried.carry_target = Vector3(0,30,0)
	carried.carry_basis = Basis.from_euler(Vector3(.2,.4,.1))
	carried.update_grip(1.0/60)
	var recovered_tree = carried.global_position.is_equal_approx(carried.carry_target)
	for member in ["carrier_a","frame_a","core_a","core_b"]:
		var member_body: CollisionObject3D = game.assembly_node(member)
		var physics_pose: Transform3D = PhysicsServer3D.body_get_state(member_body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
		recovered_tree = recovered_tree and physics_pose.is_equal_approx(member_body.global_transform)
	expect(recovered_tree and game.model.assemblies==retained_tree,"Carry recovery synchronizes all mounted descendants between physics ticks without changing ownership")
	bay.global_transform = Transform3D(Basis.IDENTITY,Vector3(0,12,0))
	game.assembly_node("bay_b").position = Vector3(12,12,0)
	var point: Vector3 = game.mount_point("carrier","bay_a","carrier_a")
	expect(point.is_equal_approx(bay.global_transform*Vector3(1.2,1.1,0)),"Mount reach uses the authored connector away from the assembly origin")
	game.camera.global_position = point+Vector3(0,0,2)
	game.camera.look_at(point)
	carried.global_transform = game.runtime.mount_pose("bay_a","carrier","carrier_a")
	await frames(2)
	game.automation.refresh_target()
	expect(game.target.get("type","") == "mount" and game.target.get("owner","") == "bay_a","Workshop targeting finds a compatible non-foot receiving owner independently of selected manual")
	game.attach()
	expect(game.model.assemblies.carrier_a.parent == "bay_a" and game.model.assemblies.core_a.parent == "frame_a","Workshop attach installs the deep child tree into the actual targeted parent")
	# Isolate the irregular large frame for actual Jolt carrying/obstruction tests.
	var frame: WorkshopPart = game.assembly_node("frame_b")
	frame.global_transform = Transform3D(Basis.IDENTITY,Vector3(0,8,0))
	frame.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	frame.freeze = true
	var pole = scenery(Vector3(0,8,0),Vector3(0.24,2,0.24))
	await frames(3)
	var excluded: Array[RID] = [frame.get_rid()]
	expect(SolidHandling.sweep_error(frame,frame.global_transform,excluded,1).is_empty(),"Real scenery fits inside the open frame; no full-envelope box fills the hollow")
	var hit = frame.move_and_collide(Vector3(3,0,0))
	expect(hit != null and frame.position.x < 2.0,"Kinematic compound translation stops its back rail against solid scenery")
	frame.global_transform = Transform3D(Basis.IDENTITY,Vector3(0,8,0))
	pole.position = Vector3(0,8,4)
	var wall = scenery(Vector3(1.78,8,0.0),Vector3(0.012,2,0.3))
	await frames(3)
	frame.held = true
	frame.carry_target = frame.global_position
	frame.carry_basis = Basis(Vector3.UP,PI/2)
	frame.update_grip(1.0/60)
	expect(not frame.global_basis.is_equal_approx(frame.carry_basis),"Radius-aware grip rotation stops a far arm against a 12 mm scenery panel")
	expect(frame.global_basis.get_euler().length() < 1.5,"The thin panel is found along the rotational path before the endpoint")
	var clear_pose = Transform3D(Basis(Vector3.UP,PI/2),frame.global_position)
	expect(not SolidHandling.sweep_error(frame,clear_pose,excluded,1).is_empty(),"Assisted snap sweep also rejects the thin blocker along its rotating approach")
	var big_offset = SolidHandling.carry_offset(frame,Basis.IDENTITY,{})
	var small_offset = SolidHandling.carry_offset(game.assembly_node("bay_b"),Basis.IDENTITY,{})
	expect(absf(big_offset.z) > absf(small_offset.z)+1.0,"Handling distance adapts to a large irregular assembly")
	expect(SolidHandling.sweep_steps(Transform3D.IDENTITY,Transform3D(Basis(Vector3.UP,PI/2),Vector3.ZERO),4) > SolidHandling.sweep_steps(Transform3D.IDENTITY,Transform3D(Basis(Vector3.UP,PI/2),Vector3.ZERO),0.3)*5,"Angular sweep resolution scales with furthest solid travel")
	await capture_view("03-solid-clearance",Vector3(5,11,6),Vector3(0,8,0),"frame_b")
	wall.queue_free()
	pole.queue_free()
	await frames(2)
	var passed = checks.all(func(check):return check.passed)
	write_evidence("res://verification/nested-runtime/audit.json",{"passed":passed,"checks":checks,"rendered":capture,"images":image_paths,"engine":Engine.get_version_info().string})
	print("NESTED_RUNTIME_AUDIT ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	game.hud.target_panel.free()
	game.hud.target_label.free()
	scene.queue_free()
	await process_frame
	quit(0 if passed else 1)
