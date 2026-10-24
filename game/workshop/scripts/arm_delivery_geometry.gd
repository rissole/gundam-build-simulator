extends RefCounted
## Measured delivery and complete adjustable four-end rig. The same geometry
## is consumed by source preflight and the cassette/crane controller.
const PAD_STATIONS=[.75,4.40]
const HEAD_HEIGHT=1.35
const Layout=preload("res://scripts/leg_bay_layout.gd")

static func route(side: int, approach_distance: float=-1) -> Array[Transform3D]:
	var spec: Dictionary=Layout.layout().workshop.arm_delivery
	if approach_distance<0:approach_distance=spec.approach_distance
	var source=AssemblyRuntime.vec(spec.source_shoulder)
	var up=Basis(Vector3.RIGHT,PI/2)
	var yaw=Basis(Vector3.UP,side*PI/2)*up
	var final=Basis(Vector3.BACK,side*PI/12)*yaw
	var center=AssemblyRuntime.vec(Layout.layout().workshop.robot.shoulders[0 if side<0 else 1])
	var before=center+final.z*approach_distance
	var lifted=Vector3(source.x,spec.upend_y,source.z)
	return [Transform3D(Basis.IDENTITY,source),
		Transform3D(Basis.IDENTITY,lifted),Transform3D(up,lifted),Transform3D(yaw,lifted),Transform3D(final,lifted),
		Transform3D(final,Vector3(source.x,before.y,source.z)),
		Transform3D(final,Vector3(source.x,before.y,spec.forward_z)),
		Transform3D(final,Vector3(before.x,before.y,spec.forward_z)),
		Transform3D(final,before),Transform3D(final,center)]

static func cassette_rig(frame: Transform3D,center: Vector3=Vector3(0,0,3.70)) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var head=frame*Vector3(center.x,3.10,center.z)
	var anchors: Array[Vector3]=[]
	for t in [1.35,6.05]:
		for x in [-.9,.9]:
			var pad=frame*Vector3(x,.935,t)
			var anchor=frame*Vector3(signf(x)*1.10,3.10,t);anchors.append(anchor)
			box(result,"end",Transform3D(Basis.IDENTITY,pad),Vector3(.12,.09,.12))
			line(result,"suspension",anchor,pad+Vector3.UP*.045,.025)
	for pair in [[0,1],[2,3],[0,2],[1,3]]:line(result,"spreader",anchors[pair[0]],anchors[pair[1]],.10)
	line(result,"equalizer",(anchors[0]+anchors[1])/2,(anchors[2]+anchors[3])/2,.10)
	box(result,"hook",Transform3D(Basis.IDENTITY,head+Vector3.UP*.12),Vector3(.16,.24,.16))
	line(result,"hoist",head+Vector3.UP*.24,Vector3(head.x,23,head.z),.035)
	return result

static func rig(frame: Transform3D, mass_center: Vector3, overhead: float=23.0, proximal_offset: float=.24, head_raise: float=0.0) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var outward=frame.basis.y;outward.y=0
	if outward.length()<.001:outward=frame.basis.z;outward.y=0
	outward=outward.normalized()
	var head_y=frame.origin.y+HEAD_HEIGHT+head_raise
	var anchors: Array[Vector3]=[]
	var pads: Array[Vector3]=[]
	for t in PAD_STATIONS:
		for sign_f in [-1,1]:
			var pad=frame*Vector3(sign_f*.72,.10,t)
			pads.append(pad)
			var anchor=pad+outward*(proximal_offset if t==PAD_STATIONS[0] else -.24)
			anchor.y=head_y;anchors.append(anchor)
			box(result,"end",Transform3D(frame.basis,pad),Vector3(.08,.10,.10))
			line(result,"suspension",anchor,pad,.025)
	# Two independent tensioned taglines share the lower structural clevises.
	# Separate winch fairleads create a triangle on each side of the load; their
	# payout follows the restrained rotation, never a free suspended yaw.
	for i in [2,3]:
		var fairlead=anchors[i]-outward*.80
		line(result,"tagline",fairlead,pads[i],.018)
		line(result,"spreader",fairlead,anchors[i],.10)
	for pair in [[0,1],[2,3],[0,2],[1,3]]:line(result,"spreader",anchors[pair[0]],anchors[pair[1]],.10)
	var head=frame*mass_center;head.y=head_y
	for i in [0,2]:line(result,"equalizer",head,(anchors[i]+anchors[i+1])/2,.10)
	box(result,"hook",Transform3D(Basis.IDENTITY,head+Vector3.UP*.16),Vector3(.16,.32,.16))
	line(result,"hoist",head+Vector3.UP*.32,Vector3(head.x,overhead,head.z),.035)
	return result

static func box(result: Array[Dictionary], kind: String, pose: Transform3D, size: Vector3) -> void:
	var shape=BoxShape3D.new();shape.size=size
	result.append({"shape":shape,"world":pose,"rig_kind":kind})

static func line(result: Array[Dictionary], kind: String, a: Vector3, b: Vector3, width: float) -> void:
	var d=b-a
	box(result,kind,Transform3D(Basis(Quaternion(Vector3.UP,d.normalized())) if d.length()>.0001 else Basis.IDENTITY,(a+b)/2),Vector3(width,maxf(.001,d.length()),width))
	result[-1].from=a;result[-1].to=b

static func mass_properties(content: Dictionary, definition: Dictionary) -> Dictionary:
	var mass=0.0;var moment=Vector3.ZERO
	for uid in definition.context_sources:
		var source: Dictionary=content.sources[uid]
		mass+=float(source.mass_kg);moment+=AssemblyRuntime.vec(source.mass_center)*float(source.mass_kg)
	return {"mass":mass,"center":moment/mass}
