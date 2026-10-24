extends Node3D
## Reusable rail holder geometry in canonical leg axes (X lateral/Y above
## sole/Z rear). Motion records are shared by rendering and collision sweeps.
var game: Node3D
var spec: Dictionary
var pieces: Dictionary = {}
var hardware: Array[RID] = []

func setup(workshop: Node3D, definition: Dictionary) -> void:
	game = workshop;spec = definition
	var initial = geometry(Transform3D(Basis(Vector3.RIGHT,PI/2),Vector3(spec.station_x,spec.base_y+spec.lying_lift,spec.home_z-spec.pivot)),spec.station_x,spec.home_z,0,0,0)
	for record in initial:
		var body = StaticBody3D.new();body.name = record.id;add_child(body);body.collision_layer=1
		var shape = CollisionShape3D.new();shape.shape = BoxShape3D.new();body.add_child(shape)
		var visual = game.box(body,Vector3.ZERO,Vector3.ONE,game.material(Color("e8b46b") if record.contact else Color("506971"),.4))
		pieces[record.id] = {"body":body,"shape":shape,"visual":visual};hardware.append(body.get_rid())
	apply_geometry(initial)

func geometry(frame: Transform3D, bogie_x: float, bogie_z: float, opening: float, compact: float, bolster: float) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	var add = func(id: String, parent: Transform3D, at: Vector3, size: Vector3, contact: bool = false):
		records.append({"id":id,"pose":parent*Transform3D(Basis.IDENTITY,at),"size":size,"contact":contact})
	var fixed = Transform3D.IDENTITY
	var h: Dictionary=spec.holder
	add.call("CradleBogie",fixed,Vector3(bogie_x,h.bogie.y,bogie_z),AssemblyRuntime.vec(h.bogie.size))
	for side in [-1,1]:
		for fore in [-1,1]:add.call("CradleWheel_%s_%s"%[side,fore],fixed,Vector3(bogie_x+side*spec.gauge/2,h.wheel.y,bogie_z+fore*h.wheel.z),AssemblyRuntime.vec(h.wheel.size),true)
	add.call("CradleSpine",frame,AssemblyRuntime.vec(h.spine),AssemblyRuntime.vec(h.spine_size))
	for index in range(h.contacts_y.size()):
		var y: float = h.contacts_y[index]
		add.call("CradleCrossbar_"+str(index),frame,Vector3(0,y,h.crossbar.z),AssemblyRuntime.vec(h.crossbar.size))
		for side in [-1,1]:
			# Released yokes retract into the rear side bands, keeping the empty
			# fixture inside the selected 2 m width and off the stationary calf.
			var x = side*lerpf(h.yoke.x[0],h.yoke.x[1],compact)
			var length = lerpf(h.yoke.length[0],h.yoke.length[1],compact)
			add.call("CradleSide_%s_%s"%[index,side],frame,Vector3(x,y,h.yoke.rear-length/2),Vector3(h.yoke.section[0],h.yoke.section[1],length))
			var finger_x = side*(lerpf(h.finger.x[0],h.finger.x[1],compact)+opening*h.jaw_stroke*(1-compact))
			add.call("CradleContact_%s_%s"%[index,side],frame,Vector3(finger_x,y,lerpf(h.finger.z[0],h.finger.z[1],compact)),AssemblyRuntime.vec(h.finger.size),true)
	# The foot bolster telescopes along the side bands after the shin has its
	# own retained frame contacts. It remains part of the same physical holder.
	var b: Dictionary=h.bolster
	var spread = clampf(bolster/b.spread_fraction,0,1)
	var rise = clampf((bolster-b.spread_fraction)/(1-b.spread_fraction),0,1)*b.lift
	for side in [-1,1]:
		var x = side*lerpf(b.x[0],b.x[1],spread)
		add.call("BolsterPad_"+str(side),frame,Vector3(x,b.pad[0]+rise,b.pad[1]),AssemblyRuntime.vec(b.pad_size),true)
		add.call("BolsterStop_"+str(side),frame,Vector3(x,b.stop[0]+rise,b.stop[1]),AssemblyRuntime.vec(b.stop_size),true)
		add.call("BolsterOutrigger_"+str(side),frame,Vector3(side*b.outrigger_x,(b.lift+rise)/2,b.outrigger_z),Vector3(b.section,maxf(b.section,b.lift-rise),b.section))
		add.call("BolsterCrossarm_"+str(side),frame,Vector3(side*(b.outrigger_x+absf(x))/2,b.crossarm[0]+rise,b.crossarm[1]),Vector3(absf(b.outrigger_x-absf(x))+b.section,b.section,b.crossarm[2]))
		add.call("BolsterLink_"+str(side),frame,Vector3(x,b.link[0]+rise,b.link[1]),Vector3(b.section,b.section,b.link[2]))
	var bearing: Vector3 = frame*Vector3(0,spec.pivot,h.bearing.z)
	# Orthogonal low slides retain a grounded load path through withdrawal and
	# outboard return. They remain below the raised soles, not through the leg.
	add.call("CradleLowCrossSlide",fixed,Vector3((bogie_x+bearing.x)/2,h.slides.y,bogie_z),Vector3(absf(bearing.x-bogie_x)+h.slides.width,h.slides.height,h.slides.width))
	add.call("CradleLowLongSlide",fixed,Vector3(bearing.x,h.slides.y,(bogie_z+bearing.z)/2),Vector3(h.slides.width,h.slides.height,absf(bearing.z-bogie_z)+h.slides.width))
	add.call("CradleMast",fixed,Vector3(bearing.x,(bearing.y+h.slides.y)/2,bearing.z),Vector3(h.mast.width,maxf(h.mast.min_height,bearing.y-h.slides.y),h.mast.width))
	add.call("CradlePivotBearing",frame,Vector3(0,spec.pivot,h.bearing.z),AssemblyRuntime.vec(h.bearing.size),true)
	return records

func apply_geometry(records: Array[Dictionary]) -> void:
	for record in records:
		var piece: Dictionary = pieces[record.id]
		piece.body.global_transform = record.pose;piece.shape.shape.size = record.size;piece.visual.scale = record.size
		piece.body.force_update_transform();PhysicsServer3D.body_set_state(piece.body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,piece.body.global_transform)
