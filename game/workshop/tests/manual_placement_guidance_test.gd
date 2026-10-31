extends "res://tests/kit/harness.gd"
## Held-part destination selection against a stub manual and build. No workshop
## construction, walked acceptance or rendered review.
const Guidance = preload("res://scripts/manual_placement_guidance.gd")
class Progress extends RefCounted:
	var current=0
	var locked=false
	var definition={"objectives":[{"op":"fit","slots":["bolt_a","bolt_b","pin"]},{"op":"seat","slot":"arm"},{"op":"seat","slot":"arm","via":{"machine":"crane","command":"lower"}}]}
	func tracked() -> Dictionary:return {"owner":"frame","page":0,"definition":definition}
	func status(_owner: String,_page: int) -> String:return "locked" if locked else "ready"
	func evaluation(_owner: String,_page: int) -> Dictionary:return {"current":current}
class Model extends RefCounted:
	var assemblies={"frame":{"definition":"frame","slots":{"bolt_a":"","bolt_b":"","pin":"","arm":""}},"arm":{"definition":"arm","location":"loose","slots":{}}}
	var items={"b1":{"kind":"bolt"},"p1":{"kind":"pin"}}
	var blocked: Array=[]
	var slots={"bolt_a":{"accepts":"bolt","pose_source":"bolt"},"bolt_b":{"accepts":"bolt","pose_source":"bolt"},"pin":{"accepts":"pin","pose_source":"pin"},"arm":{"assembly":"arm"}}
	func slot_definition(_owner: String,sid: String) -> Dictionary:return slots[sid]
	func placement_error(_owner: String,sid: String,_what: String) -> String:return "Blocked" if sid in blocked else ""
class Components extends RefCounted:
	var model: Model
	var uid=""
	func selected_uid(_kind: String) -> String:return uid
	func placement_error(owner: String,sid: String,item: String) -> String:return model.placement_error(owner,sid,item)
class Runtime extends RefCounted:
	var piece: MeshInstance3D
	func descendants(_owner: String) -> Array:return []
	func visual_pieces(_owner: String) -> Array:return [{"visual":piece,"transform":Transform3D.IDENTITY}]
	func mount_pose(_owner: String,_sid: String,_child: String) -> Transform3D:return Transform3D(Basis.IDENTITY,Vector3(0,2,0))
class World extends Node3D:
	const SNAP_READY_COLOR=Color(0.35,1.0,0.73,0.40)
	const SNAP_DISTANT_COLOR=Color(1.0,0.78,0.12,0.55)
	var model=Model.new()
	var components=Components.new()
	var manual_progress=Progress.new()
	var runtime=Runtime.new()
	var source={"bolt":MeshInstance3D.new(),"pin":MeshInstance3D.new()}
	var selected_kind=""
	var held=""
	var paused=false
	var target={}
	var ghost: MeshInstance3D
	var camera: Camera3D
	var bodies={}
	var stations={}
	func held_build() -> String:return held
	func interactable_assembly(owner: String) -> bool:return owner=="frame"
	func slot_pose(_owner: String,sid: String) -> Transform3D:return Transform3D(Basis.IDENTITY,Vector3(1 if sid=="bolt_a" else 2,0,0))
	func assembly_node(_owner: String) -> Node3D:return self
var game: World
func _initialize() -> void:run.call_deferred()

func sids(cue) -> Array:return cue.placements().map(func(p):return p.sid)
func shown(cue) -> int:return cue.component_ghosts.filter(func(g):return g.visible).size()

func run() -> void:
	game=World.new();root.add_child(game)
	game.components.model=game.model
	for kind in game.source:
		game.source[kind].mesh=BoxMesh.new();game.add_child(game.source[kind])
	game.runtime.piece=MeshInstance3D.new();game.runtime.piece.mesh=BoxMesh.new();game.add_child(game.runtime.piece)
	game.ghost=MeshInstance3D.new();game.add_child(game.ghost);game.ghost.visible=false
	game.camera=Camera3D.new();game.add_child(game.camera)
	var frame=StaticBody3D.new();game.add_child(frame);game.bodies.frame=frame
	var shape=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=Vector3(.5,.5,.5);frame.add_child(shape)
	for station in ["near","far","small"]:
		var node=Node3D.new();game.add_child(node);game.stations[station]=node
		node.position=Vector3(0,0,{"near":-2,"far":-6,"small":-1}[station])
		node.set_meta("work_volume",Vector3(.2,.2,.2) if station=="small" else Vector3.ONE)
	var cue=Guidance.new();game.add_child(cue);cue.setup(game)
	cue.update();expect(shown(cue)==0 and sids(cue).is_empty(),"Empty hands show no destination")
	game.components.uid="b1";cue.update()
	expect(sids(cue)==["bolt_a","bolt_b"] and shown(cue)==2,"A held bolt glows at every empty bolt connection of the current objective")
	expect(cue.component_ghosts[0].global_position==Vector3(1,0,0) and cue.component_ghosts[0].mesh==game.source.bolt.mesh,"The glow uses the part's mesh at its seated pose")
	expect(cue.material.shader.code.contains("depth_test_disabled"),"The glow renders through intervening geometry")
	var glow: Color=cue.material.get_shader_parameter("glow_color")
	expect(glow.is_equal_approx(Color(game.SNAP_DISTANT_COLOR,1.0)) and not glow.is_equal_approx(Color(game.SNAP_READY_COLOR,1.0)),"The unchecked glow is amber; ready green is left to the aimed preview")
	game.model.assemblies.frame.slots.bolt_a="b0";cue.update()
	expect(sids(cue)==["bolt_b"],"Filled connections stop glowing")
	game.model.blocked=["bolt_b"];cue.update()
	expect(sids(cue).is_empty(),"Placements the recipe would refuse do not glow")
	game.model.blocked=[];game.components.uid="p1";cue.update()
	expect(sids(cue)==["pin"],"Each held kind glows only at connections that accept it")
	game.target={"type":"component","owner":"frame","sid":"pin"};game.ghost.visible=true;cue.update()
	expect(shown(cue)==0,"The aimed snap preview replaces the glow at that connection")
	game.ghost.visible=false;game.target={}
	game.manual_progress.locked=true;cue.update();expect(shown(cue)==0,"A locked step shows no destination")
	game.manual_progress.locked=false
	game.manual_progress.current=1;cue.update()
	expect(sids(cue).is_empty(),"A part for an earlier objective does not glow once the manual has moved on")
	game.components.uid="";game.held="arm";cue.update()
	expect(cue.placements().size()==1 and cue.assembly_ghost.visible and cue.assembly_ghost.global_position==Vector3(0,2,0),"A held assembly glows at its mount for a hand-seated objective")
	game.manual_progress.current=2;cue.update()
	expect(not cue.assembly_ghost.visible,"Machine-guided seats rely on their control cues instead")
	game.manual_progress.current=1;game.paused=true;cue.update()
	expect(not cue.assembly_ghost.visible,"Pause hides the glow")
	game.paused=false;game.held="frame";game.model.assemblies.frame.location="held";cue.update()
	expect(cue.placements()==[{"station":"near","build":"frame"}] and cue.assembly_ghost.global_position==Vector3(0,0,-2),"Holding the step's own build glows at the nearest station with room for it")
	game.model.assemblies.arm.location="station:near";cue.update()
	expect(cue.placements()==[{"station":"far","build":"frame"}],"Occupied stations are skipped")
	game.model.assemblies["spare"]={"definition":"arm","location":"station:far","slots":{}};cue.update()
	expect(cue.placements().is_empty() and not cue.assembly_ghost.visible,"No glow when no station can take the build")
	var passed=checks.all(func(check):return check.passed)
	print("MANUAL_PLACEMENT_GUIDANCE ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
