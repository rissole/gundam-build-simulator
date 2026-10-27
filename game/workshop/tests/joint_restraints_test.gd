extends "res://tests/kit/harness.gd"
## Isolated real brace geometry, control requests, support gates and snapshots.
const Braces = preload("res://scripts/passive_joint_restraints.gd")
const Layout = preload("res://scripts/leg_bay_layout.gd")
class Game extends "res://tests/kit/model_workshop.gd":
	var primitives=preload("res://scripts/primitives.gd").new()
	var hands=HandSlot.new(self)
	var player: CharacterBody3D
	func material(color: Color,metal: float=0.0):return primitives.material(color,metal)
	func box(parent: Node3D,at: Vector3,size: Vector3,mat: Material,solid: bool=false):return primitives.box(parent,at,size,mat,solid)
class Rail extends "res://scripts/indexed_leg_rail.gd":
	func _refresh() -> void:pass
class ProductionCrane extends "res://scripts/service_crane.gd":
	func _interaction_error(_point: Vector3,_allowed: Array=[]) -> String:return ""
class Crane extends WorkshopEquipment:
	var stock_bodies: Dictionary={}
	var moving=false
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var game=Game.new();root.add_child(game)
	var definitions={"version":1,"parts":{"member":{"family":"member","carry_class":"hand"}},"assemblies":{}}
	var scenario={"version":1,"parts":[],"builds":[],"parents":[],"supports":{"leg_holder":{"assemblies":["left_leg","right_leg"]},"queue":{"assemblies":["left_leg","right_leg"]}}}
	for owner in ["left_leg","right_leg"]:
		var slots: Dictionary={}
		var milestones: Dictionary={}
		for part in ["shin","fork","spar"]:
			var uid=owner+"_"+part
			slots[part]={"accepts":"member","pose_source":uid,"snap_position":[0,{"shin":1.395,"fork":5.1,"spar":5.94}[part],0]}
			milestones[part+"_secured"]=[part]
			scenario.parts.append({"instance_id":uid,"kind":"member"})
		definitions.assemblies[owner]={"slots":slots,"milestones":milestones,"work_locations":["support:leg_holder","support:queue"]}
		scenario.parents.append({"id":owner,"definition":owner,"location":"support:leg_holder" if owner=="left_leg" else "support:queue"})
	var errors=game.model.configure(definitions,scenario)
	expect(errors.is_empty(),"isolated mirrored stock configures: "+str(errors))
	game.runtime=AssemblyRuntime.new(game.model,{})
	for owner in ["left_leg","right_leg"]:
		var body=Node3D.new();game.add_child(body);body.position.x=-5 if owner=="left_leg" else 5;game.runtime.register_node(owner,body)
	var rail=Rail.new();game.add_child(rail);rail.game=game;rail.equipment_id="leg_rail";rail.spec=Layout.layout().workshop.rail;rail.index_x=rail.spec.station_x;game.equipment.register(rail)
	var crane=Crane.new();game.add_child(crane);crane.equipment_id="service_crane";game.equipment.register(crane)
	for uid in game.model.items:
		var body=AnimatableBody3D.new();game.add_child(body);body.position=Vector3(30,10,0);crane.stock_bodies[uid]=body
		var task=uid.trim_prefix("left_leg_") if uid.begins_with("left_leg_") else "right_"+uid.trim_prefix("right_leg_")
		body.global_transform=Layout.authored_pose(Layout.layout().crane.tasks[task].source_pose)
	var braces=Braces.new();game.add_child(braces);braces.setup(game);game.equipment.register(braces)
	expect(braces.fixtures.size()==12 and braces.controls().size()==12,"both legs have three pairs of persistent physical handles")
	for fixture in braces.fixtures:
		var uid=fixture.owner+"_"+fixture.spec.attachment
		expect(fixture.node.get_parent()==crane.stock_bodies[uid] and fixture.node.visible and not fixture.locked,"parked "+fixture.id+" attaches to real source stock")
		expect(fixture.node.global_transform.is_equal_approx(crane.stock_bodies[uid].global_transform*game.runtime.local_slot_pose(fixture.owner,fixture.spec.attachment).affine_inverse()),fixture.id+" preserves the physical attachment frame at source pickup")
		expect(not braces.request("engage:"+fixture.id).is_empty(),fixture.id+" cannot engage before joint retention")
	var source_shapes: Array[Dictionary]=[]
	MotionSweep.collect_shapes(crane.stock_bodies.left_leg_shin,crane.stock_bodies.left_leg_shin.global_transform.affine_inverse(),source_shapes)
	expect(source_shapes.size()==28,"source shin sweep includes both captive ankle and knee bridge pairs")
	# Fit each physical member. Retention must never operate the captive braces.
	for owner in ["left_leg","right_leg"]:
		for sid in ["shin","fork","spar"]:
			game.model.items[owner+"_"+sid].owner=owner;game.model.items[owner+"_"+sid].slot=sid;game.model.items[owner+"_"+sid].location="installed";game.model.assemblies[owner].slots[sid]=owner+"_"+sid
	game.model.changed.emit()
	for fixture in braces.fixtures:
		expect(fixture.node.get_parent()==game.runtime.node(fixture.owner) and not fixture.locked and fixture.progress==0,"retaining "+fixture.id+" preserves its visible parked state")
		expect(not braces.required_error(fixture.owner,fixture.spec.milestone).is_empty(),fixture.id+" prevents unsupported release")
		for piece in fixture.pieces:
			var start=braces._piece_pose(fixture,piece.spec,0);var finish=braces._piece_pose(fixture,piece.spec,1)
			for pose in [start,finish]:expect(absf(pose.point.x)+pose.size.x*.5<=.8 and absf(pose.point.z)+pose.size.z*.5<=.75,fixture.id+" stays inside measured transport cross-section")
	var release_crane=ProductionCrane.new();game.add_child(release_crane);release_crane.game=game;release_crane.equipment_id="test_crane"
	release_crane.config={"spec":{}};release_crane.load_owner="left_leg";release_crane.slot="shin";release_crane.uid="left_leg_shin";release_crane.secured_milestone="shin_secured"
	release_crane.END_IDS=["a","b"];release_crane.endpoints={"a":{"state":"attached","point":"near"},"b":{"state":"attached","point":"far"}}
	var end=Node3D.new();game.add_child(end);release_crane.end_nodes={"a":end,"b":end};release_crane.station="receiver";release_crane.raised=false
	expect(release_crane.action_error("detach:a").contains("brace"),"retained shin keeps crane support until its braces lock")
	for action in ["lift+","bolster+","index-","travel+"]:expect(rail.action_error(action).contains("brace"),"loaded "+action+" requires the retained joint braces")
	for owner in ["left_leg","right_leg"]:
		rail.active_assembly=owner
		game.model.assemblies.left_leg.location="support:leg_holder" if owner=="left_leg" else "support:queue"
		game.model.assemblies.right_leg.location="support:leg_holder" if owner=="right_leg" else "support:queue"
		for fixture in braces.fixtures:
			if fixture.owner!=owner:continue
			var command="engage:"+fixture.id
			expect(braces.request(command).is_empty() and braces.moving and not fixture.locked,fixture.id+" starts only through its local command")
			braces.physics(.1)
			expect(fixture.progress>0 and fixture.progress<1 and not braces.manual_state()[fixture.id],fixture.id+" partial travel never ticks the lock objective")
			for tick in range(20):braces.physics(.1)
			expect(not braces.moving and fixture.locked and braces.manual_state()[fixture.id],fixture.id+" arrival locks and ticks")
		expect(braces.required_error(owner).is_empty(),owner+" all independent locks release transport gates")
	expect(release_crane.action_error("detach:a").is_empty(),"locked ankle braces permit the ordinary crane connector release")
	rail.engaged=false
	expect(rail.action_error("index+").is_empty(),"brace gates keep empty-rig indexing available")
	rail.engaged=true
	# Direct-space obstacle catches an intermediate slider pose and resumes safely.
	rail.active_assembly="left_leg"
	game.model.assemblies.left_leg.location="support:leg_holder"
	game.model.assemblies.right_leg.location="support:queue"
	var fixture=braces.fixtures[0]
	var saved_spar: String=game.model.assemblies.left_leg.slots.spar
	game.model.assemblies.left_leg.slots.spar=""
	expect(braces.action_error("stow:left_leg:knee:outboard").contains("magnetic connectors"),"bare fork needs reacquired crane support before knee-brace correction")
	game.model.assemblies.left_leg.slots.spar=saved_spar
	game.equipment._remember_rest(game.equipment.all())
	expect(braces.request("stow:"+fixture.id).is_empty(),"stationary fully supported leg permits local correction")
	braces.physics(.1);game.equipment._remember_rest(game.equipment.all())
	expect(not fixture.locked and game.equipment.save_capture().joint_restraints.locked[fixture.id],"mid-withdrawal snapshot uses the last locked stop while live lock evidence stays false")
	for tick in range(20):braces.physics(.1)
	expect(not fixture.locked and fixture.progress==0,"correction leaves the brace attached and parked")
	var blocker=StaticBody3D.new();game.add_child(blocker);blocker.name="Brace obstruction"
	var shape=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=Vector3(.16,.12,.16);blocker.add_child(shape)
	blocker.global_position=fixture.node.global_transform*Vector3(-.615,1.0,.5)
	await frames(2)
	expect(braces.request("engage:"+fixture.id).is_empty(),"an obstructed brace accepts its request")
	for tick in range(20):braces.physics(.1)
	expect(braces.moving and not fixture.locked and not braces.blocked_reason.is_empty() and fixture.progress<1,"guarded slider holds before an actual collider")
	expect(braces.controls()[0].action=="stow:"+fixture.id and braces.request("stow:"+fixture.id).is_empty(),"waiting handle can reverse its partial engagement to a supported parked stop")
	for tick in range(20):braces.physics(.1)
	expect(not braces.moving and fixture.progress==0 and not fixture.locked,"reverse motion reaches the parked stop without releasing the physical attachment")
	blocker.free();await frames(2)
	expect(braces.request("engage:"+fixture.id).is_empty(),"the cleared bridge accepts its engagement again")
	for tick in range(20):braces.physics(.1)
	expect(fixture.locked and not braces.moving,"clear travel reaches a real locked stop")
	expect(braces.request("stow:"+fixture.id).is_empty(),"automatic resume fixture starts stowing")
	for tick in range(20):braces.physics(.1)
	var auto_blocker=StaticBody3D.new();game.add_child(auto_blocker);auto_blocker.name="Temporary loose blocker"
	var auto_shape=CollisionShape3D.new();auto_shape.shape=BoxShape3D.new();auto_shape.shape.size=Vector3(.16,.12,.16);auto_blocker.add_child(auto_shape)
	auto_blocker.global_position=fixture.node.global_transform*Vector3(-.615,1.0,.5)
	await frames(2)
	expect(braces.request("engage:"+fixture.id).is_empty(),"automatic resume fixture starts engagement")
	for tick in range(20):braces.physics(.1)
	var held_at: float=fixture.progress
	auto_blocker.free();await frames(2)
	for tick in range(20):braces.physics(.1)
	expect(held_at<1 and fixture.locked and not braces.moving,"removing a blocker resumes the same request automatically")
	var saved=braces.capture()
	expect(braces.validate(saved).is_empty(),"at-rest lock snapshot validates")
	fixture.locked=false;fixture.progress=0;braces.apply(saved)
	expect(fixture.locked and fixture.progress==1,"snapshot restore preserves engagement without inferring retention")
	rail.bolster=1
	expect(not braces.request("stow:"+fixture.id).is_empty(),"stowed foot bolster prevents brace correction")
	rail.bolster=0;rail.engaged=false
	expect(not braces.request("stow:"+fixture.id).is_empty(),"released rig cannot remove mounted joint support")
	rail.engaged=true;rail.moving=true
	expect(not braces.request("stow:"+fixture.id).is_empty(),"moving rig cannot disengage braces")
	rail.moving=false
	game.model.assemblies.left_leg.history.append({"slot":"shin"})
	expect(braces.undo("left_leg").handled,"locked braces protect their physical attachment from undo")
	var parent=Node3D.new();game.add_child(parent);game.runtime.node("left_leg").reparent(parent)
	for angle in [.2,.6,1.1]:
		parent.rotation=Vector3(angle,angle*.7,angle*.4);braces.sync_pose()
		var body=fixture.pieces[0].body
		expect(PhysicsServer3D.body_get_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM).is_equal_approx(body.global_transform),"mounted brace physics follows intermediate multi-axis rotation "+str(angle))
	var before_mount=fixture.node
	rail.engaged=false;braces.sync()
	expect(fixture.node==before_mount and fixture.node.get_parent()==game.runtime.node("left_leg"),"leg rig release preserves the attached brace identity on the mounted leg")
	var metadata=braces.controls()[0]
	expect(metadata.manual_command=="engage:"+fixture.id and metadata.control_id==fixture.id,"manual guidance resolves the exact persistent handle identity")
	# Production stationary support geometry must leave the full slide corridor
	# clear; no broad fixture exclusion can hide an equipment clash.
	parent.rotation=Vector3.ZERO
	var leg=game.runtime.node("left_leg")
	leg.global_transform=Transform3D(Basis(Vector3.RIGHT,PI/2),Vector3(14,1.85,9.4))
	var cradle=preload("res://scripts/leg_cradle.gd").new();game.add_child(cradle);cradle.setup(game,rail.spec)
	await frames(2)
	braces.sync_pose()
	for bridge in braces.fixtures:
		if bridge.owner=="left_leg":expect(braces.motion_error(bridge,0,1).is_empty(),bridge.id+" full slider sweep clears the actual engaged stationary leg rig")
	var passed=checks.all(func(c):return c.passed)
	print("JOINT_RESTRAINTS ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
