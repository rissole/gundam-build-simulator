extends "res://tests/kit/harness.gd"
const Sweep=preload("res://scripts/motion_sweep.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=await boot_profile("leg_bay_m3")
	var guide=game.equipment.get_equipment("core_guide")
	var body=game.runtime.node("core")
	var descriptor=game.runtime.definition("core")
	var low=Vector3(INF,INF,INF);var high=-low
	for uid in descriptor.context_sources:
		var source: Dictionary=game.source[uid]
		for vertex in source.mesh.get_faces():
			var at: Vector3=source.transform*vertex;low=low.min(at);high=high.max(at)
	expect(low.x>=-.47001 and high.x<=.47001 and low.y>=-.47001 and high.y<=.47001,"actual core source vertices retain the flange envelope")
	expect(low.z>=-.65001 and high.z<=1.16001,"actual nose and rear face retain the declared axial bounds")
	var shapes: Array[Dictionary]=[];Sweep.collect_shapes(body,body.global_transform.affine_inverse(),shapes)
	var ignored: Array[RID]=[];Sweep.collect_rids(body,ignored)
	var fit=Sweep.sweep(game.get_world_3d().direct_space_state,[{"shapes":shapes,"margin":.0001,"error":"Core mating obstruction"}],220,func(p: float)->Transform3D:return guide.load_pose(2.2*p),15,ignored)
	expect(fit.is_empty(),"full actual core compound fits the captured guides and receiving ring: "+str(fit))
	var compact=Sweep.sweep(game.get_world_3d().direct_space_state,[{"shapes_at":func(frame: Transform3D,_p: float)->Array:return guide.rig_solids(frame,1),"margin":.001,"error":"Compact rig obstruction"}],1,func(_p: float)->Transform3D:return guide.load_pose(2.2),15,ignored)
	expect(compact.is_empty(),"folded aft rig, stowed bridge and crane lines clear the fitted chest")
	var unfolded=Sweep.sweep(game.get_world_3d().direct_space_state,[{"shapes_at":func(frame: Transform3D,_p: float)->Array:return guide.rig_solids(frame,0),"margin":.001,"error":"Unfolded rig obstruction"}],1,func(_p: float)->Transform3D:return guide.load_pose(2.2),15,ignored)
	expect(not unfolded.is_empty(),"unfolded equalizer cannot enter the cockpit envelope")
	var wrong=guide.load_pose(2.2)*Transform3D(Basis(Vector3.BACK,PI),Vector3.ZERO)
	var collision=Sweep.sweep(game.get_world_3d().direct_space_state,[{"shapes":shapes,"margin":.0001,"error":"Misclocked core"}],1,func(_p: float)->Transform3D:return wrong,15,ignored)
	expect(not collision.is_empty(),"actual forward nose key rejects a 180-degree rolled core")
	var core_col_count=0
	for child in body.get_children():
		if child is CollisionShape3D:
			core_col_count+=1
			expect(child.has_meta("motion_shapes"),"each moving source has a compound preserving the cylindrical/guide profile")
	expect(core_col_count==descriptor.context_sources.size(),"every prepared core source participates in physical motion")
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/core-content.json",{"scope":"actual source envelopes and guide/key mating solids; no walking/access review","checks":checks})
	print("CORE_CONTENT ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
