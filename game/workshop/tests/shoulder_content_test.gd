extends "res://tests/kit/harness.gd"
## Actual receiving and installed source solids; no walking or aiming sweep.
const Sweep=preload("res://scripts/motion_sweep.gd")
var game: Node
var fixture: Node3D
var bodies: Dictionary={}
func _initialize() -> void:call_deferred("run")
func source_body(uid: String,frame: Transform3D) -> StaticBody3D:
	var body=StaticBody3D.new();body.name=uid;body.collision_layer=1<<18;body.collision_mask=0;fixture.add_child(body)
	var primitives: Array=game.leg_content.sources[uid].primitives
	for n in range(primitives.size()):
		var col=CollisionShape3D.new();col.shape=LegSourceGeometry.make_mesh({"primitives":[primitives[n]]}).create_trimesh_shape();col.set_meta("primitive",n);body.add_child(col)
	body.global_transform=frame*game.source[uid].transform
	bodies[uid]=body
	return body
func run() -> void:
	game=await boot_workshop("pelvis");fixture=Node3D.new();game.add_child(fixture)
	var scene=Transform3D(Basis.IDENTITY,Vector3(70,20,0))
	for uid in game.runtime.definition("chest").context_sources:source_body(uid,scene)
	for side in ["left","right"]:
		var id=side+"_arm";var arm_frame=scene*game.runtime.local_slot_pose("chest",id)
		for uid in game.runtime.definition(id).context_sources:source_body(uid,arm_frame)
		for sid in game.runtime.definition("chest").slots:
			if not sid.begins_with(id+"/") or "pin" in sid or "keeper" in sid or "bolt" in sid or "washer" in sid or "service" in sid:continue
			source_body(game.model.slot_definition("chest",sid).pose_source,scene)
	await frames(3)
	var space=game.get_world_3d().direct_space_state
	for side in ["left","right"]:
		var sign_f=-1 if side=="left" else 1;var id=side+"_arm";var frame=scene*game.runtime.local_slot_pose("chest",id)
		for theta in [45,135,225,315]:
			var a=deg_to_rad(theta);var p=Vector3(sign_f*.405*sin(a),.405*cos(a),.12)
			var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(frame*(p-Vector3.BACK*.2),frame*(p+Vector3.BACK*.2),1<<18))
			expect(hit.is_empty(),id+" ring/cup M24 through bore "+str(theta)+": "+str(hit.get("collider","")))
		for theta in [100,180,260]:
			var a=deg_to_rad(theta);var b=deg_to_rad(theta+45)
			for entry in [["A",Vector3(sign_f*.46*sin(a),.46*cos(a),.64)],["B",Vector3(sign_f*.34*sin(b),.34*cos(b),1.5)]]:
				var shape=CylinderShape3D.new();shape.radius=.020;shape.height=.14
				var hit=Sweep.overlap(space,shape,frame*Transform3D(Basis(Vector3.BACK,-PI/2),entry[1]),1<<18,[],-.0001)
				expect(hit.is_empty(),id+" actual Ø40 drive "+str(theta)+" "+entry[0]+" pin fits arm, fixed clevis and cartridge: "+str(hit.get("collider","")))
		for key in [Vector3(sign_f*.25,.05,1.05),Vector3(-sign_f*.25,-.15,1.05)]:
			var shape=CylinderShape3D.new();shape.radius=.020;shape.height=.14
			var hit=Sweep.overlap(space,shape,frame*Transform3D(Basis(Vector3.BACK,-PI/2),key),1<<18,[],-.0001)
			expect(hit.is_empty(),id+" keyed brace has a clear Ø40 pin bore: "+str(hit.get("collider","")))
		for suffix in ["brace","drive_1","drive_2","drive_3"]:
			var uid: String=game.model.slot_definition("chest",id+"/"+suffix).pose_source
			var body: StaticBody3D=bodies[uid];var contact=""
			for primitive in game.leg_content.sources[uid].primitives:
				var shape: Shape3D;var basis=Basis.IDENTITY
				if primitive.shape=="box":shape=BoxShape3D.new();shape.size=AssemblyRuntime.vec(primitive.size)
				else:
					shape=CylinderShape3D.new();shape.radius=primitive.outer;shape.height=primitive.length
					var axis=Vector3.RIGHT if primitive.axis is String else AssemblyRuntime.vec(primitive.axis)
					basis=Basis(Quaternion(Vector3.UP,axis))
				var hit=Sweep.overlap(space,shape,body.global_transform*Transform3D(basis,AssemblyRuntime.vec(primitive.center)),1<<18,[body.get_rid()],-.0005)
				if not hit.is_empty():
					var col=hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape))
					contact=str(hit.collider.name)+" primitive "+str(col.get_meta("primitive"))+" at "+str(primitive.center);break
			expect(contact.is_empty(),id+" "+suffix+" source clears other installed solids at neutral: "+contact)
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/shoulder-content.json",{"scope":"actual assembled shoulder source bore fit; no reach, walking or rendered review","checks":checks})
	print("SHOULDER_CONTENT ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
