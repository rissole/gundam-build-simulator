extends SceneTree
## Inspect actual imported triangles at receiving bores. Slot/source agreement
## cannot detect missing holes, so these checks deliberately avoid slot poses.
var source: Dictionary = {}
var checks: Array = []
var axial = Vector3(0,520,500).normalized()
var side = Vector3(0,500,-520).normalized()
var origin = Vector3(-0.54,0.48,-0.8)

func point(p: Vector3) -> Vector3:
	return origin+(Vector3.RIGHT*p.x+side*p.y+axial*p.z)*0.001

func from_model(p: Vector3) -> Vector3:
	var relative = Vector3(p.x,p.z,-p.y)*0.001-origin
	return Vector3(relative.x,relative.dot(side),relative.dot(axial))*1000.0

func clear_bore(uid: String, begin: Vector3, end: Vector3, radius: float, label: String, witness_radius: float = -1.0, require_material: bool = true) -> void:
	var node: MeshInstance3D = source[uid]
	var inverse = node.transform.affine_inverse()
	var a = point(begin)
	var b = point(end)
	var axis = (b-a).normalized()
	var right = axis.cross(Vector3.UP if absf(axis.dot(Vector3.RIGHT)) > 0.9 else Vector3.RIGHT).normalized()
	var up = axis.cross(right).normalized()
	var faces = node.mesh.get_faces()
	# Work in millimetres: tiny metre-space triangles fall below the engine's
	# segment/triangle epsilon and can incorrectly appear empty.
	for i in range(faces.size()):faces[i] *= 1000.0
	var clear = true
	for offset in [Vector3.ZERO,right*radius*0.001,-right*radius*0.001,up*radius*0.001,-up*radius*0.001]:
		var from = (inverse*(a+offset))*1000.0
		var to = (inverse*(b+offset))*1000.0
		for i in range(0,faces.size(),3):
			if Geometry3D.segment_intersects_triangle(from,to,faces[i],faces[i+1],faces[i+2]) != null:
				clear = false
				break
	# Empty space is not a receiving hole: require surrounding receiver material.
	var witness = radius+2.5 if witness_radius < 0 else witness_radius
	var supported = false
	for offset_direction in [right,-right,up,-up,(right+up).normalized(),(right-up).normalized(),(-right+up).normalized(),(-right-up).normalized()]:
		var offset = offset_direction*witness*0.001
		var from = (inverse*(a+offset-axis*0.02))*1000.0
		var to = (inverse*(b+offset+axis*0.02))*1000.0
		for i in range(0,faces.size(),3):
			if Geometry3D.segment_intersects_triangle(from,to,faces[i],faces[i+1],faces[i+2]) != null:
				supported = true
				break
	clear = clear and (supported or not require_material)
	checks.append({"passed":clear,"check":label,"receiver":uid,"surrounding_material":supported})
	if not clear:push_error(label+" — blocked bore in "+uid)

func _initialize() -> void:
	var scene = load("res://assets/foot-fa01.glb").instantiate()
	for node in scene.get_children():
		if node is MeshInstance3D:
			var sections = String(node.name).split("__")
			source[sections[0]+"__"+sections[1]] = node
	for i in range(4):
		var x = 50*cos(PI/4+i*PI/2)
		var y = 50*sin(PI/4+i*PI/2)
		clear_bore("FA-513__001",Vector3(x,y,108),Vector3(x,y,120),5.5,"Motor flange screw %d"%i)
		clear_bore("FA-512__001",Vector3(x,y,80),Vector3(x,y,90),5.8,"Rear cap clearance for motor screw tip %d"%i)
		clear_bore("FA-513__001",Vector3(x,y,144),Vector3(x,y,160),11,"Motor screw access corridor %d"%i)
		x = 48*cos(i*PI/2); y = 48*sin(i*PI/2)
		clear_bore("FA-514__001",Vector3(x,y,156),Vector3(x,y,168),5.5,"Gearbox flange screw %d"%i)
	for z in [207,233]:clear_bore("FA-515__001",Vector3(24,-19,z),Vector3(24,19,z),5.5,"Separate coupling clamp bore %d"%z)
	for xy in [Vector2(58,0),Vector2(0,58),Vector2(-58,0),Vector2(0,-58)]:
		clear_bore("FA-513__001",Vector3(xy.x,xy.y,108),Vector3(xy.x,xy.y,120),11.8,"Motor clears housing cap boss %s"%xy)
	clear_bore("FA-510__001",Vector3(0,0,250.1),Vector3(0,0,271.9),33.8,"Thrust bearing seat clears integral retainer bosses")
	clear_bore("FA-510__001",Vector3(0,0,534.1),Vector3(0,0,549.9),49.8,"Guide bushing seat clears integral cap bosses")
	clear_bore("FA-515__001",Vector3(0,0,192),Vector3(0,0,247),11.5,"Coupling accepts both shaft journals")
	for y in [-42,42]:
		clear_bore("FA-523__001",Vector3(0,y,270),Vector3(0,y,282),5.5,"Retainer receiving hole %d"%y)
		clear_bore("FA-510__001",Vector3(0,y,238),Vector3(0,y,274),5.5,"Retainer housing boss %d"%y)
	for x in [-29,29]:
		for uid in ["FA-524__001","FA-524__002"]:clear_bore(uid,Vector3(x,-16,292),Vector3(x,16,292),5.5,"Collar joining hole %d"%x)
	var length = Vector2(500,520).length()
	var rear = length-350
	for x in [-50,50]:
		clear_bore("FA-518__001",Vector3(x,0,rear-1),Vector3(x,0,rear+11),5.5,"Rod flange hole %d"%x)
		clear_bore("FA-518__001",Vector3(x,0,rear+11),Vector3(x,0,rear+37),11,"Rod screw-head access pocket %d"%x)
	for z in [430,490]:
		clear_bore("FA-521__001",Vector3(58,43,z),Vector3(58,55,z),5.5,"Guide ear bore %d"%z)
		clear_bore("FA-510__001",Vector3(58,52,z),Vector3(58,76,z),5.5,"Guide housing bore %d"%z)
	for i in range(2):
		var z = 98 if i==0 else 490
		clear_bore("FA-528__%03d"%(i+1),Vector3(70,-28,z),Vector3(82,-28,z),5.5,"Sensor flange separate from probe %d"%i)
	clear_bore("H-12030__021",Vector3(58,0,65.5),Vector3(58,0,115.5),5.8,"Rear cap bolt clears lower sensor screw",-1,false)
	clear_bore("FA-510__001",Vector3(59,-28,83),Vector3(59,-28,89.9),5.8,"Sensor land stays above rear closure face",-1,false)
	for xy in [Vector2(58,0),Vector2(0,58),Vector2(-58,0),Vector2(0,-58)]:
		clear_bore("FA-511__001",Vector3(xy.x,xy.y,550),Vector3(xy.x,xy.y,574),5.5,"Front cap receiving hole %s"%xy)
		clear_bore("FA-512__001",Vector3(xy.x,xy.y,66),Vector3(xy.x,xy.y,90),5.5,"Rear cap receiving hole %s"%xy)
	for x in [-58,58]:
		clear_bore("FA-525__001",Vector3(x,0,59),Vector3(x,0,69),11.8,"Base eye clears installed cap washer %d"%x)
	for xy in [Vector2(-50,-25),Vector2(50,25)]:
		clear_bore("FA-525__001",Vector3(xy.x,xy.y,59),Vector3(xy.x,xy.y,69),5.5,"Base eye flange receiving hole %s"%xy)
		clear_bore("FA-529__001",Vector3(xy.x,xy.y,87),Vector3(xy.x,xy.y,91),9.8,"Rear gasket clears eye receiver boss %s"%xy,13)
	for n in [1,2]:
		var z = 0.0 if n==1 else length
		for family in ["FA-525","FA-526","FA-527"]:
			clear_bore("%s__%03d"%[family,n],Vector3(-32,0,z),Vector3(32,0,z),24,"Clear pin passage in %s eye %d"%[family,n],47 if family=="FA-525" else (36 if family=="FA-527" else 27))
	for y in [735,865]:
		clear_bore("FA-220__001",from_model(Vector3(-645,y,425)),from_model(Vector3(-573,y,425)),11.5,"Base clevis bolt clears full bracket depth %d"%y,15)
	for x in [-410,-330]:
		clear_bore("FA-220__002",from_model(Vector3(x,300,1095)),from_model(Vector3(x,300,1023)),11.5,"Ring clevis bolt clears full bracket depth %d"%x,15)
	var passed = checks.all(func(c):return c.passed)
	FileAccess.open("res://verification/pitch-interface-audit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"asset_sha256":FileAccess.get_sha256("res://assets/foot-fa01.glb")},"  "))
	print("PITCH_INTERFACE_AUDIT ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	scene.free()
	quit(0 if passed else 1)
