extends "res://tests/kit/harness.gd"
## Expensive audit, for after major changes: runs the shared stage sequence from
## a fresh workshop and, just before each staged control use and each connection
## fill, samples clear viewpoints within reach of its aim point through the real
## sight check. An aim point buried in its own model or a neighbour is seen from
## almost nowhere (backpack strut handles 3 of 600, hinge pins 40 of 1,100).
## Geometric sight from free space only: it does not judge whether the player can
## walk, ride or hang at those viewpoints. Foot chapters (supplied in one step),
## magnetic connectors (supplied rig state) and controls staging never operates
## are outside its scope.
const Stages=preload("res://scripts/build_stages.gd")
## Below this fraction of clear viewpoints, the aim point fails as buried.
const BURIED=.05
## Below this it is listed as narrow for review, without failing.
const NARROW=.15
const DIRECTIONS=160
const RADII=[.5,1.0,1.6,2.2]
## A viewpoint needs this much clearance, roughly a head's.
const EYE_CLEARANCE=.15
var game: Node
var stages: RefCounted
var stage:=""
var results: Array[Dictionary]=[]
var unmatched: Dictionary={}
var audited: Dictionary={}
var directions: Array[Vector3]=[]
var eye_probe:=PhysicsShapeQueryParameters3D.new()

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var started:=Time.get_ticks_msec()
	for i in DIRECTIONS:
		# Fibonacci sphere: even, deterministic coverage.
		var y:=1.0-2.0*(i+.5)/DIRECTIONS;var r:=sqrt(1.0-y*y);var a:=PI*(3.0-sqrt(5.0))*i
		directions.append(Vector3(cos(a)*r,y,sin(a)*r))
	var sphere:=SphereShape3D.new();sphere.radius=EYE_CLEARANCE
	eye_probe.shape=sphere
	game=await boot_workshop()
	eye_probe.collision_mask=game.WORLD_MASK;eye_probe.exclude=[game.player.get_rid()]
	stages=Stages.new(game);stages.observer=self
	var error: String=await stages.run_to("complete",func(title: String):stage=title)
	expect(error.is_empty(),"shared sequence completes the robot: "+error)
	finish(Time.get_ticks_msec()-started)

func before_control(controller: Node, action: String) -> void:
	var entries: Array=controller.controls().filter(func(entry):return entry.action==action)
	# Crane moves and guided crane operations are console commands; the player
	# aims at the console.
	var crane: Node=game.equipment.get_equipment("service_crane")
	var guided: bool=controller.has_method("crane_options") and controller.crane_options().any(func(option):return option.action=="guide:"+action)
	if entries.is_empty() and (controller==crane or guided):entries=crane.controls().filter(func(entry):return entry.action=="open_console")
	if entries.is_empty():
		var key: String=controller.equipment_id+" "+action
		unmatched[key]=unmatched.get(key,0)+1
		return
	for entry in entries:
		var node: Node3D=entry.node
		var point: Vector3=entry.get("point",node.global_position)
		audit("control",controller.equipment_id+" "+action+" ("+str(entry.label)+")",point,entry.get("allowed",[]),entry.get("allow_body_hit",false),.065)

## Fills one connection at a time in authored order, auditing each just before
## it is fitted, in the state the player fits it.
func fill(owner: String, permitted: Array) -> void:
	var skipped: Dictionary={}
	while true:
		var next:=""
		for sid in game.runtime.definition(owner).slots:
			if skipped.has(sid) or (not permitted.is_empty() and sid not in permitted):continue
			if not game.model.assemblies[owner].slots[sid].is_empty():continue
			var spec: Dictionary=game.model.slot_definition(owner,sid)
			if spec.has("assembly") or not spec.get("requires",[]).all(func(id):return not game.model.assemblies[owner].slots[id].is_empty()):continue
			next=sid;break
		if next.is_empty():return
		var child_target: String=game.model.slot_definition(owner,next).get("target_child",game.components.slot_presentation(owner,next).get("target_child",""))
		if child_target.is_empty() or not game.model.assemblies[owner].slots.get(child_target,"").is_empty():
			audit("connection",owner+" "+next,game.components.slot_point(owner,next),game.components.receiving_bodies(owner,next),game.components.service_access(owner,next),game.components.sight_depth(owner,next))
		if Staging.fill(game,owner,[next],1)==0:skipped[next]=true

func audit(kind: String, label: String, point: Vector3, allowed: Array, body_hit: bool, depth: float) -> void:
	var key:=label+" @"+str(point.snapped(Vector3.ONE*.01))
	if audited.has(key):return
	audited[key]=true
	var space: PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
	var clear:=0;var seen:=0;var blockers: Dictionary={}
	for direction in directions:
		for radius in RADII:
			var eye: Vector3=point+direction*radius
			eye_probe.transform=Transform3D(Basis.IDENTITY,eye)
			if not space.intersect_shape(eye_probe,1).is_empty():continue
			clear+=1
			if game.targeting.can_see(point,allowed,body_hit,depth,eye):seen+=1
			else:
				var name:=blocker(space,eye,point,allowed if body_hit else [])
				blockers[name]=blockers.get(name,0)+1
	var fraction:=float(seen)/clear if clear>0 else 0.0
	# Solids enclosing the aim point itself: the direct sign of a buried target.
	var inside: Array=[]
	var at:=PhysicsPointQueryParameters3D.new();at.position=point;at.collision_mask=game.WORLD_MASK
	for hit in space.intersect_point(at,8):inside.append(part_name(hit.collider,hit.shape))
	var top: Array=blockers.keys();top.sort_custom(func(a,b):return blockers[a]>blockers[b])
	var record:={"stage":stage,"kind":kind,"label":label,"point":[snappedf(point.x,.001),snappedf(point.y,.001),snappedf(point.z,.001)],"seen":seen,"clear":clear,"fraction":snappedf(fraction,.001),"blockers":top.slice(0,3).map(func(k):return k+" x"+str(blockers[k])),"inside":inside}
	results.append(record)
	var enclosed: String="; aim point inside "+", ".join(inside) if not inside.is_empty() else ""
	expect(fraction>=BURIED,"%s: %s %s seen from %d of %d clear viewpoints%s; blocked by %s"%[stage,kind,label,seen,clear,enclosed,", ".join(record.blockers)])
	if fraction>=BURIED and fraction<NARROW:print("AIM NARROW %s: %s %s %d/%d; %s"%[stage,kind,label,seen,clear,", ".join(record.blockers)])

## The first solid between eye and point, with the sight check's exclusions,
## named by its authored source part where it has one.
func blocker(space: PhysicsDirectSpaceState3D, eye: Vector3, point: Vector3, see_through: Array) -> String:
	var query:=PhysicsRayQueryParameters3D.create(eye,point,game.WORLD_MASK)
	var excluded: Array[RID]=[game.player.get_rid()]
	for body in see_through:
		if body is CollisionObject3D:excluded.append(body.get_rid())
	query.exclude=excluded
	var hit:=space.intersect_ray(query)
	if hit.is_empty():return "pickup surface"
	return part_name(hit.collider,hit.shape)+" %.2fm short"%hit.position.distance_to(point)

## The authored part behind one collision shape. Assembly solids live on the
## root carrier and name their part by physical_uid.
func part_name(collider: Object, shape: int) -> String:
	if not collider is CollisionObject3D:return str(collider)
	var owner: Node=collider.shape_owner_get_owner(collider.shape_find_owner(shape))
	for key in ["source_uid","physical_uid"]:
		if owner.has_meta(key) and not str(owner.get_meta(key)).is_empty():return str(owner.get_meta(key))
	return str(owner.name)

func finish(elapsed: int) -> void:
	var passed=checks.all(func(check):return check.passed)
	var buried:=results.filter(func(r):return r.fraction<BURIED)
	var narrow:=results.filter(func(r):return r.fraction>=BURIED and r.fraction<NARROW)
	write_evidence("res://verification/aim-point-audit.json",{"scope":"geometric sight from clear viewpoints within reach of every staged control and connection fill, pelvis to complete; not reachability, foot chapters or magnetic connectors","thresholds":{"buried":BURIED,"narrow":NARROW},"buried":buried,"narrow":narrow,"unmatched_controls":unmatched,"targets":results,"checks":checks})
	for key in unmatched:print("AIM UNMATCHED ",key," x",unmatched[key])
	print("AIM SUMMARY %d targets, %d buried, %d narrow, %d unmatched control actions, %.1f s"%[results.size(),buried.size(),narrow.size(),unmatched.size(),elapsed/1000.0])
	print("AIM_POINT_AUDIT ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
