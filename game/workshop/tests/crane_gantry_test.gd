extends "res://tests/kit/harness.gd"
## Coarse source envelopes and isolated crane/access behavior; no workshop walk.
const Production = preload("res://scripts/service_crane.gd")
const Layout = preload("res://scripts/leg_bay_layout.gd")
class World extends "res://tests/kit/model_workshop.gd":
	var player: CharacterBody3D
class Crane extends "res://scripts/service_crane.gd":
	func _refresh() -> void:pass
	func _route_error(_from: float,_to: float) -> String:return ""
class Console extends CanvasLayer:
	func physics() -> void:pass
class Access extends "res://scripts/workshop_access.gd":
	func _pose() -> void:pass
class Ropes extends WorkshopEquipment:
	const LEAF_REASON="Recall the front rope before opening the leaves."
	var clear=true
	var hanging=false
	func front_ropes_clear() -> bool:return clear
	func attached() -> bool:return false
var game: World
var crane: Crane
var access: Access
var ropes: Ropes
var authored: Dictionary
var content: Dictionary
var perimeter: Array[AABB]=[]
func _initialize() -> void:run.call_deferred()
func select(key: String, loaded: bool=true) -> void:
	var spec: Dictionary=authored.crane.tasks[key]
	var route: Array[Transform3D]=[]
	for index in spec.route_positions.size():
		var rotation=spec.route_rotations[index] if spec.has("route_rotations") else spec.source_pose.rotation_degrees if index<2 else spec.receiver_pose.rotation_degrees
		route.append(Transform3D(Basis.from_euler(AssemblyRuntime.vec(rotation)*PI/180),AssemblyRuntime.vec(spec.route_positions[index])))
	crane.task=key;crane._configure_task({"spec":spec,"source_pose":route[0],"receiver_pose":route.back(),"route":route})
	for index in crane.END_IDS.size():crane.endpoints[crane.END_IDS[index]]={"state":"attached" if loaded else "stowed","point":crane.POINT_IDS[index] if loaded else ""}
	crane.station="source";crane.raised=true;crane.motion="go:receiver";crane.moving=true;crane.progress=0;crane.travel_from=null

func source_bounds(uid: String) -> AABB:
	var first=true;var result: AABB
	for id in game.runtime.definition(uid).context_sources:
		var source: Dictionary=content.sources[id]
		var frame=Transform3D(Basis.from_euler(AssemblyRuntime.vec(source.rotation_degrees)*PI/180),AssemblyRuntime.vec(source.position))
		var bounds=frame*LegSourceGeometry.make_mesh(source).get_aabb()
		result=bounds if first else result.merge(bounds);first=false
	return result

func geometry() -> void:
	var chest=source_bounds("chest")
	var chest_top=12.7+chest.end.y
	expect(is_equal_approx(chest_top,16.98),"source chest plus neck is Y16.98, not the old18.7 assumption")
	var walkway=AABB(Vector3(5,20.3,30.3),Vector3(13,1.5,1.4))
	var fixed: Array[AABB]=[walkway]
	for x in [11.0,12.4,13.6,15.0]:fixed.append(AABB(Vector3(x-.075,21.725,28.3),Vector3(.15,.15,2)))
	for key in ["core","backpack"]:
		select(key)
		var payload=source_bounds(key)
		if key=="core":
			for piece in content.equipment.core_guide.bridge.shapes:
				payload=payload.merge(AABB(AssemblyRuntime.vec(piece.at)-AssemblyRuntime.vec(piece.size)/2,AssemblyRuntime.vec(piece.size)))
		var over: Transform3D=crane.route[2]
		expect((over*payload).position.y>=chest_top+.5,key+" overflight includes half-metre chest clearance")
		expect((over*payload).end.y<20.3 and crane._load_beam(over).origin.y+.09<20.3,key+" payload, adapter and spreader stay below closed structure")
		expect(crane.route.back()==Layout.authored_pose(authored.crane.tasks[key].receiver_pose),key+" existing receiver pose is unchanged")
		var previous: AABB
		var previous_rig: Array[AABB]=[]
		var rig_clear=true
		for i in crane.route.size():
			var frame: Transform3D=crane.route[i]
			var box=frame*payload
			var swept=box if i==0 else previous.merge(box)
			expect(not swept.intersects(walkway),key+" payload avoids fixed exit walkway segment"+str(i))
			var beam=crane._load_beam(frame).origin
			if beam.z>=28.3:
				expect(absf(beam.x-13)<.4 and beam.y+.09<21.6,key+" rear mast is central and lower rig stays under booms")
			var rig: Array=game.equipment.get_equipment("core_guide").rig_solids(frame,0) if key=="core" else crane.rig_solids(frame)
			var next_rig: Array[AABB]=[]
			for n in rig.size():
				var entry: Dictionary=rig[n]
				var bounds: AABB=entry.world*AABB(-entry.shape.size/2,entry.shape.size)
				next_rig.append(bounds)
				var travel=bounds if previous_rig.is_empty() else previous_rig[n].merge(bounds)
				for obstacle in fixed:rig_clear=rig_clear and not travel.intersects(obstacle)
			previous_rig=next_rig
			previous=box
		expect(rig_clear,key+" every spreader, connector and cable segment clears rear walkway/booms")
	# Every existing front delivery retains a central corridor, clear of the
	# open leaves; no high rear excursion remains in any robot delivery.
	for key in ["pelvis","chest","core","backpack","left_arm","right_arm","left_pauldron","right_pauldron","head_baseplate","head_left","head_right","head_top","head_crown"]:
		select(key)
		var crossed=false;var clear=true
		var side_clear=true
		for i in range(crane.route.size()-1):
			var a: Transform3D=crane.route[i];var b: Transform3D=crane.route[i+1]
			var box=crane._upper_envelope(a,crane._load_beam(a),true).merge(crane._upper_envelope(b,crane._load_beam(b),true))
			if perimeter.any(func(solid):return box.intersects(solid)):side_clear=false
			if box.intersects(Production.UPPER_LEAF_BAND):
				crossed=true
				# Outboard source moves at Z13 may span X5; only the fore/aft
				# crossing enters the parked-leaf depth (Z16..24).
				clear=clear and box.position.x>5.6 and box.end.x<20.4
			expect(maxf(a.origin.z,b.origin.z)<=28.61,key+" has no rear-walkway route excursion")
		var frame: Transform3D=crane.route.back()
		expect(crossed and clear,key+" crosses front inside open-leaf corridor")
		expect(side_clear,key+" loaded cable envelope clears the new fixed side walks and elevator bypass")
		expect(not crane._upper_envelope(frame,crane._load_beam(frame),true).intersects(Production.UPPER_LEAF_BAND),key+" seated rig lets upper leaves close")

func interlocks() -> void:
	select("pelvis")
	crane.progress=.4 # travel segment is still entirely workshop-side
	expect(crane._access_error(.41).is_empty() and access.front_closed("upper"),"non-crossing loaded segment leaves upper access closed")
	crane.progress=.83
	var before=crane.progress
	crane.physics(.2)
	expect(crane.progress==before and crane.moving and crane.blocked_reason==Production.UPPER_WAIT,"crossing pauses with a named reason and keeps trip pending")
	access.request("upper_open");access.physics(7)
	crane.physics(.2)
	expect(crane.progress>before and crane.blocked_reason.is_empty(),"open leaves automatically resume the same trip")
	# At Z26 the lowering segment does not reserve the upper leaves.
	crane.station="receiver";crane.motion="down";crane.progress=0
	access.request("upper_close");access.physics(7)
	expect(access.front_closed("upper") and crane._access_error(.1).is_empty(),"upper leaves close while pelvis is still held at Z26")
	# Reverse route reopens only at the crossing; deployed ropes hold it.
	crane.motion="go:source";crane.progress=.12;ropes.clear=false
	before=crane.progress;crane.physics(.2)
	expect(crane.progress==before and crane.moving and crane.blocked_reason==Production.UPPER_WAIT,"return crossing asks the player to open the upper leaves")
	access.request("upper_open");access.physics(7)
	expect(access.blocked_reason==ropes.LEAF_REASON,"player opening still waits for the deployed rope")
	ropes.clear=true;access.physics(7);crane.physics(.2)
	expect(crane.progress>before,"recalling front rope resumes the pending crossing")
	select("left_arm")
	access.request("upper_close");access.request("lower_close");access.physics(7)
	expect(not crane._access_error(.01).is_empty(),"arm waits for the player to open the lower front")
	access.request("lower_open");access.physics(7)
	expect(access.front_open("lower") and access.front_closed("upper"),"lower arm configuration preserves closed upper leaves away from crossing")
	# Access ticks first: closing must not get a one-frame head start into a
	# currently occupied band, including when the operator stopped the crane.
	for loaded in [true,false]:
		select("pelvis",loaded)
		if loaded:crane.progress=.9
		else:crane.station="receiver";crane.motion="go:park";crane.progress=.23
		crane.moving=false
		access.request("upper_open");access.physics(7)
		expect(crane.upper_crossing_occupied(),"current "+str(loaded)+" loaded/empty cable envelope occupies crossing")
		var refusal: String=access.request("upper_close");access.physics(.1)
		expect(is_equal_approx(access.channels["20.6"].value,1) and refusal.begins_with("Move the ") and refusal.ends_with("before closing the upper leaves."),"Close refuses before any leaf movement into stopped crane cables")
		crane.station="receiver";crane.motion="down";crane.progress=0
		expect(not crane.upper_crossing_occupied(),"current rig at Z26 releases upper close hold")
		access.request("upper_close");access.physics(7)
		expect(access.front_closed("upper"),"player Close succeeds after crane clears the band")

func empty_journeys() -> void:
	var lift=AABB(Vector3(.3,0,22.45),Vector3(3.2,22,3.2))
	for key in ["core_store","backpack_store","head_crown","left_arm","core","backpack"]:
		select(key,false)
		var pickup=crane._station_beam("source",true)
		var receiver=crane._station_beam("receiver",true)
		var park=crane._station_beam("park",true)
		for pair in [[park,pickup],[receiver,park],[receiver,pickup],[park,receiver]]:
			var route=Production.empty_route(pair[0],pair[1])
			var reverse=Production.empty_route(pair[1],pair[0]);reverse.reverse()
			expect(route==reverse,key+" pickup/park/return/reacquire share a symmetric route")
			var clear=true
			var side_clear=true
			for i in range(route.size()-1):
				var a: Vector3=route[i].origin;var b: Vector3=route[i+1].origin
				var low=a.min(b);var high=a.max(b);low.y=0;high.y=23
				var mast=AABB(low,high-low).grow(.2)
				clear=clear and not mast.intersects(lift)
				if perimeter.any(func(solid):return mast.intersects(solid)):side_clear=false
			expect(clear,key+" empty mast avoids relocated left lift")
			expect(side_clear,key+" empty mast avoids the fixed upper perimeter")
	select("pelvis",false)
	crane.station="receiver";crane.motion="go:park";crane.progress=.12
	access.request("upper_close");access.request("lower_close");access.physics(7)
	expect(not crane._access_error(.3).is_empty(),"empty parking trip also waits before crossing upper leaves")
	# Existing serialized start pose deterministically restores task-switch path.
	crane.travel_from=Transform3D(Basis.IDENTITY,Vector3(13,17,28.6))
	crane.station="park";crane.motion="go:source";crane.progress=.27
	var saved=crane.capture();var expected=crane._beam_pose()
	var start=preload("res://scripts/pose_codec.gd").to_pose(saved.travel_from)
	var restored=Production.route_pose(Production.empty_route(start,crane._station_beam("source",true)),saved.progress)
	expect(expected.is_equal_approx(restored),"saved task-switch start/progress reconstruct exact empty route pose")

func run() -> void:
	authored=Layout.layout();content=JSON.parse_string(FileAccess.get_file_as_string("res://assets/robot-content.json"))
	for solid in authored.workshop.solids:
		if not solid.solid or not ["rope_side_","rope_corner_","rope_link_"].any(func(prefix):return solid.id.begins_with(prefix)):continue
		perimeter.append(AABB(AssemblyRuntime.vec(solid.position)-AssemblyRuntime.vec(solid.size)/2,AssemblyRuntime.vec(solid.size)))
	game=World.new();root.add_child(game);expect(game.setup().is_empty(),"real content configures")
	crane=Crane.new();game.add_child(crane);crane.game=game;crane.tasks=authored.crane.tasks;crane.equipment_id="service_crane";game.equipment.register(crane);crane.console=Console.new();crane.add_child(crane.console)
	access=Access.new();game.add_child(access);access.game=game;access.equipment_id="workshop_access";access.spec=authored.workshop.access
	access.channels={"8.4":{"value":0.,"goal":0.},"20.6":{"value":0.,"goal":0.},"rear":{"value":0.,"goal":0.}}
	game.equipment.register(access)
	ropes=Ropes.new();game.add_child(ropes);ropes.equipment_id="rope_access";game.equipment.register(ropes)
	var core=preload("res://scripts/core_guide.gd").new();game.add_child(core);core.game=game;core.equipment_id="core_guide";core.spec=content.equipment.core_guide;game.equipment.register(core)
	for side in ["left","right"]:
		var shoulder=preload("res://scripts/shoulder_support.gd").new();game.add_child(shoulder);shoulder.game=game;shoulder.equipment_id=side+"_shoulder"
		shoulder.mass=preload("res://scripts/arm_delivery_geometry.gd").mass_properties(content,game.runtime.definition(side+"_arm"));game.equipment.register(shoulder)
	geometry();interlocks();empty_journeys()
	var passed=checks.all(func(c):return c.passed)
	print("CRANE_GANTRY ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
