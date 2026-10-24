extends "res://tests/kit/harness.gd"
## Actual carriage/cargo movement against the whole blockout. No walking,
## targetability, connection access or visibility acceptance is automated.
const Fixture = preload("res://tests/wide_access_test.gd").Fixture
const Blockout = preload("res://scripts/workshop_blockout.gd")
const Lift = preload("res://scripts/work_access_lift.gd")
const Shelf = preload("res://scripts/lift_shelf.gd")
func _initialize() -> void:call_deferred("run")

func run() -> void:
	var game = Fixture.new();root.add_child(game)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/workshop-layout.json"))
	var world = Blockout.new();game.add_child(world);world.setup(game,layout.workshop)
	var model_data = {"version":1,"parts":{"panel":{"family":"TEST","carry_class":"two_hand"}},"assemblies":{}}
	var supports = {};var stock = []
	for side in layout.workshop.elevators:
		for id in layout.workshop.elevators[side].shelf.supports:supports[id] = {"parts":["panel"]}
		var uid: String = side+"_panel"
		stock.append({"instance_id":uid,"kind":"panel","location":"bin"})
		var mesh = BoxMesh.new();mesh.size=Vector3(1.45,1.20,.35);game.source[uid] = {"mesh":mesh}
	expect(game.model.configure(model_data,{"version":1,"parts":stock,"parents":[],"builds":[],"supports":supports}).is_empty(),"independent shelf supports configure")
	var lifts = {};var shelves = {}
	for side in layout.workshop.elevators:
		var spec: Dictionary = layout.workshop.elevators[side]
		var lift = Lift.new();game.add_child(lift)
		var stops: Array[float] = [];stops.assign(spec.levels)
		lift.setup(game,spec.name,AssemblyRuntime.vec(spec.origin),Vector2(spec.size[0],spec.size[1]),stops,spec)
		game.equipment.register(lift);lifts[side] = lift
		var shelf = Shelf.new();game.add_child(shelf);shelf.setup(game,lift,spec.shelf)
		game.equipment.register(shelf);shelves[side] = shelf
		expect(game.model.carry_item(side+"_panel").is_empty(),side+" supplied test panel held")
		expect(shelf.capacity_error(side+"_panel").is_empty(),side+" accepts the full enlarged panel envelope")
		var mesh: BoxMesh=game.source[side+"_panel"].mesh
		for too_large in [Vector3(1.46,1.20,.35),Vector3(1.45,1.21,.35),Vector3(1.45,1.20,.36)]:
			mesh.size=too_large
			expect(not shelf.capacity_error(side+"_panel").is_empty(),side+" rejects oversized panel "+str(too_large))
		mesh.size=Vector3(1.45,1.20,.35)
		expect(game.model.store_carried_item(side+"_panel",spec.shelf.supports[0]).is_empty(),side+" supplied test panel takes declared support")
		shelf.sync()
		var surface: AABB=shelf.global_transform*AABB(-AssemblyRuntime.vec(spec.shelf.size)/2,AssemblyRuntime.vec(spec.shelf.size))
		var limits: Array=[5.60,7.10] if side=="left" else [18.90,20.40]
		expect(is_equal_approx(surface.position.x,limits[0]) and is_equal_approx(surface.end.x,limits[1]) and is_equal_approx(surface.position.z,27.8) and is_equal_approx(surface.end.z,28.2),side+" shelf occupies the selected wall band")
		var cargo: AABB=shelf.cargo[side+"_panel"].global_transform*mesh.get_aabb()
		expect(is_equal_approx(cargo.end.y-lift.height,1.85) and cargo.end.y-lift.height<2.10,side+" panel stays inside the roof and gear budget")
		expect(cargo.position.x>spec.origin[0]-1.26 and cargo.end.x<spec.origin[0]+1.26 and cargo.position.z>27.74 and cargo.end.z<28.2,side+" loaded shelf clears car walls and leaves the rear turning area")
		expect(surface.end.z<29-.5 and mesh.size.x<1.5,side+" shelf clears both 1.5 m side doors; upright panel width fits their opening")
	await frames(3)
	for side in lifts:
		var lift: Node3D = lifts[side]
		var other: Node3D = lifts["right" if side=="left" else "left"]
		var other_state: Dictionary = other.capture()
		for stop in [1,2,3,4,0]:
			var error: String = lift.request("stop"+str(stop))
			expect(error.is_empty(),side+" lift route to stop "+str(stop)+": "+error)
			if not error.is_empty():continue
			lift.physics(.5)
			var snapshot: Dictionary = JSON.parse_string(JSON.stringify(game.equipment.capture()))
			expect(game.equipment.validate(snapshot,game.model,{}).is_empty(),side+" interrupted carriage and cargo snapshot validates")
			game.equipment.apply(snapshot)
			for tick in range(230):
				if not lift.moving:break
				lift.physics(.1)
			expect(not lift.moving and is_equal_approx(lift.height,lift.stops[stop]),side+" restored lift reaches stop "+str(stop)+": "+lift.blocked_reason)
			expect(other.capture()==other_state,side+" movement leaves other elevator independent")
			expect(lift.side_gates.all(func(gate):return gate.disabled),side+" both doors open at stopped landing")
			var shelf: Node3D = shelves[side]
			var body: Node3D = shelf.cargo[side+"_panel"]
			expect(absf(body.global_position.y-(lift.height+.65+.60))<.0001,side+" cargo remains seated on shelf")
			var query=PhysicsShapeQueryParameters3D.new();var full=BoxShape3D.new();full.size=Vector3(1.45,1.20,.35)
			query.shape=full;query.transform=body.global_transform;query.collision_mask=15;query.margin=.001
			var excluded: Array[RID]=[body.get_rid(),lift.deck.get_rid()]
			preload("res://scripts/motion_sweep.gd").collect_rids(shelf,excluded);query.exclude=excluded
			expect(game.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),side+" full panel clears shaft guides and landings at stop "+str(stop))
	var bad: Dictionary = game.equipment.capture();bad.left_shelf.occupants=["right_panel",""]
	expect(not game.equipment.validate(bad,game.model,{}).is_empty(),"cross-elevator cargo substitution rejected")
	expect(game.model.integrity_errors().is_empty(),"all physical cargo identities conserved")
	var passed = checks.all(func(check):return check.passed)
	write_evidence("res://verification/wide-elevators.json",{"scope":"equipment-only; supplied test cargo","checks":checks})
	print("WIDE_ELEVATORS ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
