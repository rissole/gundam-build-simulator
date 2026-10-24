extends "res://scripts/equipment.gd"
## One ground-transferred, stabilized personnel platform. Dock routes, occupied
## footprint and heights are authored in the shared workshop layout. The player may ride
## height changes and ground transfers with a hand load; ground transfers require
## a lowered deck clear of loose loads.
const Sweep = preload("res://scripts/motion_sweep.gd")
const Codec = preload("res://scripts/pose_codec.gd")
var spec: Dictionary
var dock = "park"
var selected = "park"
var from_dock = "park"
var to_dock = "park"
var travel = 0.0
var height = .15
var goal_height = .15
var mode = ""
var moving = false
var blocked_reason = ""
var deck: AnimatableBody3D
var base: StaticBody3D
var gate: CollisionShape3D
var posts: Array[Dictionary] = []
var buttons: Array[Dictionary] = []
var label: Label3D
var move_menu: CanvasLayer
var move_button: MeshInstance3D

func setup(workshop: Node3D, definition: Dictionary) -> void:
	game = workshop;spec = definition;equipment_id = "mobile_platform"
	height = spec.heights[0];goal_height = height
	var steel = game.material(Color("506971"),.45)
	var yellow = game.material(Color("e8b46b"),.3)
	base = StaticBody3D.new();base.name = "MobilePlatformBase";add_child(base)
	deck = AnimatableBody3D.new();deck.name = "MobilePlatformDeck";deck.sync_to_physics = false;add_child(deck)
	var size = Vector2(spec.deck_size[0],spec.deck_size[1])
	_solid(deck,Vector3(0,-.06,0),Vector3(size.x,.12,size.y),steel)
	for x in [-size.x/2+.035,size.x/2-.035]:
		for z in [-size.y/2+.035,size.y/2-.035]:
			_solid(deck,Vector3(x,.52,z),Vector3(.07,1.04,.07),yellow)
		if x<0:_solid(deck,Vector3(x,1.05,0),Vector3(.07,.07,size.y),yellow)
		else:gate = _solid(deck,Vector3(x,.6,0),Vector3(.07,1.0,size.y-.14),yellow)
	for z in [-size.y/2+.035,size.y/2-.035]:_solid(deck,Vector3(0,1.05,z),Vector3(size.x,.07,.07),yellow)
	# Stabilizers and wheel contacts stay within the declared 2.4 x 2.0 m.
	for z in [-.85,.85]:
		_solid(base,Vector3(0,.075,z),Vector3(spec.size[0],.1,.15),steel)
		for x in [-spec.size[0]/2+.1,spec.size[0]/2-.1]:_solid(base,Vector3(x,.035,z),Vector3(.18,.07,.20),yellow)
	for x in [-.47,.47]:
		_solid(base,Vector3(x,.075,0),Vector3(.12,.1,1.7),steel)
		for z in [-.52,.52]:
			var col = _solid(base,Vector3(x,.1,z),Vector3(.08,.1,.08),steel)
			posts.append({"shape":col,"visual":col.get_meta("visual"),"x":x,"z":z})
	# Integral boarding wedge occupies the unused right half of the footprint.
	var points = PackedVector3Array()
	for z in [-.6,.6]:
		points.append(Vector3(size.x/2,0,z));points.append(Vector3(size.x/2,height,z));points.append(Vector3(spec.size[0]/2,0,z))
	var ramp = ConvexPolygonShape3D.new();ramp.points = points
	var collision = CollisionShape3D.new();collision.shape = ramp;base.add_child(collision)
	var surface = SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in [0,2,1,3,4,5,1,2,4,2,5,4,0,1,3,1,4,3,0,3,2,3,5,2]:surface.add_vertex(points[i])
	surface.generate_normals();var visual = MeshInstance3D.new();visual.mesh = surface.commit();visual.material_override = steel;base.add_child(visual)
	game.box(deck,Vector3(-.13,.90,-.64),Vector3(.84,.50,.045),steel)
	# Vertical travel has its own fixed pair. Dock selection never changes Up/Down.
	for entry in [["up",-.38,1.02,"↑ UP"],["down",-.38,.78,"↓ DOWN"],["open_move",.12,1.02,"MOVE"],["stop",.12,.78,"■ STOP"]]:
		var button = preload("res://scripts/equipment_button.gd").make(game,deck,Vector3(entry[1],entry[2],-.60),entry[3],0,entry[0] == "up")
		buttons.append(control_entry(button,entry[0],entry[0],.11,{"allowed":[deck]}))
		if entry[0] == "open_move":move_button = button
	label = game.sign_panel(deck,"",Vector3(-.13,1.34,-.62),Vector2(.84,.26),28,.0015)
	move_menu = preload("res://scripts/platform_move_menu.gd").new();add_child(move_menu);move_menu.setup(self)
	_pose()

func _solid(parent: CollisionObject3D, at: Vector3, size: Vector3, material: Material) -> CollisionShape3D:
	var visual = game.box(parent,at,size,material)
	# Butt the visible handrail members; retain the established solid envelopes.
	if size.is_equal_approx(Vector3(.07,1.04,.07)):
		visual.mesh.size.y = 1.015;visual.position.y -= .0125
	elif is_equal_approx(size.y,.07) and size.z>.3:
		visual.mesh.size.z -= .14
	elif is_equal_approx(size.y,.07) and size.x>.3:
		visual.mesh.size.x -= .14
	elif size.is_equal_approx(Vector3(.12,.1,1.7)):
		visual.mesh.size.z = 1.55;visual.mesh.size.y = .12
	elif size.is_equal_approx(Vector3(.08,.1,.08)):
		visual.mesh.size = Vector3(.07,.095,.07)
	var col = CollisionShape3D.new();col.position = at;var shape = BoxShape3D.new();shape.size = size;col.shape = shape
	parent.add_child(col);col.set_meta("visual",visual);return col

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for button in buttons:
		var entry: Dictionary = button.duplicate();entry.point = entry.node.global_position
		match entry.action:
			"up":entry.label = "Raise platform · next level"
			"down":entry.label = "Lower platform · next level"
			"open_move":entry.label = "Move platform · choose destination"
			"stop":entry.label = "Stop platform"
		result.append(entry)
	return result

func dock_title(id: String) -> String:
	if id == "park":return "Parking bay"
	return ("Module bay · " if id.begins_with("bulky_") else "Limb station · ")+id.get_slice("_",1).capitalize()

func menu_access_error() -> String:
	if game.camera.global_position.distance_to(move_button.global_position)>game.REACH:return "Move within reach of the platform controls."
	if not game._visible(move_button.global_position,[deck]):return "The platform controls are obstructed."
	return ""

func move_options() -> Array[Dictionary]:
	if mode == "travel":return [{"action":"go","label":"Resume to "+dock_title(to_dock)},{"action":"return","label":"Return to "+dock_title(from_dock)}]
	var result: Array[Dictionary] = []
	for destination in spec.docks:
		if destination != dock:result.append({"action":"dock:"+destination,"label":dock_title(destination)})
	return result

func _route(start: String = "", end: String = "") -> Array[Vector3]:
	if start.is_empty():start = from_dock
	if end.is_empty():end = to_dock
	var path: Array[Vector3] = [AssemblyRuntime.vec(spec.docks.park)]
	for point in spec.routes[start]:path.append(AssemblyRuntime.vec(point))
	path.reverse()
	for point in spec.routes[end]:
		var next = AssemblyRuntime.vec(point)
		if not next.is_equal_approx(path[-1]):path.append(next)
	return path

func position_at(value: float, path: Array[Vector3]) -> Vector3:
	if path.size()<2:return path[0]
	var index = mini(path.size()-2,floori(value))
	return path[index].lerp(path[index+1],clampf(value-index,0,1))

func hardware() -> Array[RID]:
	var result: Array[RID] = [];Sweep.collect_rids(self,result);return result

func _deck_occupied() -> bool:
	var shape = BoxShape3D.new();shape.size = Vector3(spec.deck_size[0],2.0,spec.deck_size[1])
	return not Sweep.overlap(get_world_3d().direct_space_state,shape,global_transform*Transform3D(Basis.IDENTITY,Vector3(0,height+1.01,0)),15,without_passengers(hardware()),0).is_empty()

func action_error(action: String) -> String:
	if game.paused:return "Resume the workshop before operating the work platform."
	if action=="stop":return "" if moving else "The work platform is stopped."
	if moving:return "Wait for the platform to arrive."
	if action == "open_move":return menu_access_error()
	if action in ["up","down"]:
		if mode == "travel":return "Finish the ground transfer before changing height."
		if action == "up" and height >= spec.heights[-1]-.001:return "Already at the highest level."
		if action == "down" and height <= spec.heights[0]+.001:return "Already at ground level."
		return ""
	if action == "go":
		if mode == "travel":return ""
		if mode == "height":return "Use Up or Down to finish the height adjustment."
		if selected == dock:return "Choose another dock first."
		return action_error("dock:"+selected)
	if action=="destination":return "" if mode.is_empty() or mode == "travel" else "Finish the height adjustment first."
	if action.begins_with("dock:"):
		if not spec.docks.has(action.trim_prefix("dock:")):return "Unknown work platform dock."
		if action.trim_prefix("dock:") == dock:return "The work platform is already at this dock."
		if not mode.is_empty():return "Complete or return the interrupted transfer first."
		if height>spec.heights[0]+.001:return "Lower the work platform before ground transfer."
		if _deck_occupied():return "Remove loose loads from the deck before ground transfer."
		var rail = game.equipment.get_equipment("leg_rail")
		if rail!=null:
			var reason: String = rail.busy_reason("mobile_platform")
			if not reason.is_empty():return reason
		return ""
	if action not in ["advance","return"]:return "Unknown work platform control."
	return ""

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():return error
	if action == "open_move":return move_menu.open()
	blocked_reason = ""
	if action == "go":
		if mode == "travel":moving = true;_pose();return ""
		return request("dock:"+selected)
	if action in ["up","down"]:return _request_height(action == "up")
	if action=="stop":moving = false;_pose();return ""
	if action == "destination" and mode == "travel":return request("return")
	if action=="destination":selected = spec.docks.keys()[(spec.docks.keys().find(selected)+1)%spec.docks.size()];_pose();return ""
	if action=="advance" and not mode.is_empty():moving = true;return ""
	if action=="advance" and selected!=dock:return request("dock:"+selected)
	if action.begins_with("dock:"):
		to_dock = action.trim_prefix("dock:");from_dock = dock;selected = to_dock;travel = 0
		if from_dock==to_dock:return "The work platform is already at this dock."
		mode = "travel";moving = true;_pose();return ""
	if action=="return" and mode=="travel":
		# Reverse the exact authored route from the stopped position.
		var count = _route().size()-1;var previous = from_dock;from_dock = to_dock;to_dock = previous
		travel = count-travel;selected = to_dock;moving = true;_pose();return ""
	if action=="return" and height<=spec.heights[0]+.001:return request("dock:park")
	return _request_height(action == "advance")

func _request_height(up: bool) -> String:
	goal_height = height
	if up:
		for level in spec.heights:
			if level>height+.001:goal_height = level;break
	else:
		for index in range(spec.heights.size()-1,-1,-1):
			if spec.heights[index]<height-.001:goal_height = spec.heights[index];break
	if is_equal_approx(goal_height,height):return "The work platform is already at this height."
	mode = "height";moving = true;_pose();return ""

func physics(delta: float) -> void:
	if not moving or game.paused:return
	if mode=="travel":
		if _deck_occupied():blocked_reason = "Remove loose loads from the deck before ground transfer.";moving = false;_pose();return
		var path = _route();var index = mini(path.size()-2,floori(travel+.00001))
		var next = minf(index+1,travel+spec.speed*delta/maxf(.01,path[index].distance_to(path[index+1])))
		var destination = Transform3D(Basis.IDENTITY,position_at(next,path))
		blocked_reason = _travel_error(destination)
		if not blocked_reason.is_empty():moving = false;_pose();return
		travel = next;_pose()
		if travel>=path.size()-1-.00001:dock = to_dock;from_dock = dock;travel = 0;mode = "";moving = false;_pose()
	else:
		var next = move_toward(height,goal_height,spec.lift_speed*delta)
		blocked_reason = _height_error(next)
		if not blocked_reason.is_empty():moving = false;_pose();return
		height = next;_pose()
		if is_equal_approx(height,goal_height):mode = "";moving = false;_pose()

func _travel_error(destination: Transform3D) -> String:
	var shapes: Array[Dictionary] = [];var inverse = global_transform.affine_inverse()
	Sweep.collect_shapes(self,inverse,shapes)
	for body in passengers():Sweep.collect_shapes(body,inverse,shapes)
	var count = Sweep.steps(global_transform,destination,2,.025)
	var hit = Sweep.sweep(get_world_3d().direct_space_state,[{"shapes":shapes,"margin":-.002,"error":"Clear the work platform ground route ({collider}).","cast":true}],count,func(p):return global_transform.interpolate_with(destination,p),15,without_passengers(hardware()),equipment_id)
	return hit.get("error","")

func _height_error(next: float) -> String:
	var excluded = without_passengers(hardware());var riders = passengers()
	var clearance = 1.12 if riders.is_empty() else 1.76
	var low = minf(height,next)-.115;var high = maxf(height,next)+clearance
	var shape = BoxShape3D.new();shape.size = Vector3(spec.deck_size[0],high-low,spec.deck_size[1])
	var hit = Sweep.overlap(get_world_3d().direct_space_state,shape,global_transform*Transform3D(Basis.IDENTITY,Vector3(0,(high+low)/2,0)),15,excluded,0)
	if not hit.is_empty():return "Clear the work platform height adjustment."
	# A hand load can overhang the deck; reserve its own vertical route.
	var shapes: Array[Dictionary] = []
	for body in riders.slice(1):Sweep.collect_shapes(body,global_transform.affine_inverse(),shapes)
	if shapes.is_empty():return ""
	return Sweep.sweep(get_world_3d().direct_space_state,[{"shapes":shapes,"margin":.001,"error":"Clear the carried component's platform route ({collider})."}],Sweep.steps(global_transform,global_transform.translated(Vector3.UP*(next-height)),0,.025),func(p):return global_transform.translated(Vector3.UP*(next-height)*p),15,excluded,equipment_id).get("error","")

func _pose() -> void:
	position = position_at(travel,_route()) if mode=="travel" else AssemblyRuntime.vec(spec.docks[dock])
	deck.position.y = height
	gate.disabled = not moving and is_equal_approx(height,spec.heights[0]);gate.get_meta("visual").visible = not gate.disabled
	for post in posts:
		var length = maxf(.01,height-.12)
		post.shape.position.y = length/2+.025;post.visual.position.y = post.shape.position.y
		post.shape.shape.size.y = length;post.visual.scale.y = length/.1
	base.force_update_transform();PhysicsServer3D.body_set_state(base.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,base.global_transform)
	label.text = status_text()

func status_text() -> String:
	if not blocked_reason.is_empty():return "Platform blocked\nClear the route, then retry"
	if moving:return ("Travelling to "+to_dock.replace("_"," ") if mode == "travel" else "Moving to %.2f m"%goal_height)+"\nStops automatically"
	if mode == "travel":return "Platform stopped\nMOVE to resume or return"
	if mode == "height":return "Platform stopped · %.2f m"%height+"\nUP or DOWN to continue"
	return "Platform · %.2f m"%height+"\n"+dock_title(dock)

func busy_reason(subject: String) -> String:
	if subject in ["source_roll","arm_upend","bulky_tilt"] and (dock!="park" or not mode.is_empty()):return "Return the movable work platform to parking first."
	return ""

func capture() -> Dictionary:
	return {"version":1,"dock":dock,"selected":selected,"from":from_dock,"to":to_dock,"travel":travel,"height":height,"goal_height":goal_height,"mode":mode,"moving":moving}

func validate(data: Variant, _candidate: AssemblyModel = null, _world: Dictionary = {}) -> Array[String]:
	if not Codec.same_keys(data,["version","dock","selected","from","to","travel","height","goal_height","mode","moving"]) or data.version!=1:return ["Invalid mobile platform snapshot."]
	for key in ["dock","selected","from","to"]:
		if not data[key] is String or not spec.docks.has(data[key]):return ["Invalid work platform dock."]
	if not data.mode is String or data.mode not in ["","travel","height"] or not data.moving is bool:return ["Invalid work platform motion."]
	for key in ["travel","height","goal_height"]:
		if not Codec.number(data[key]):return ["Invalid work platform progress."]
	if data.height<spec.heights[0] or data.height>spec.heights[-1] or not data.goal_height in spec.heights:return ["Work platform height exceeds its stops."]
	if data.mode=="travel":
		if data.from==data.to or data.dock not in [data.from,data.to] or data.travel<0 or data.travel>_route(data.from,data.to).size()-1:return ["Invalid ground transfer phase."]
		if not is_equal_approx(data.height,spec.heights[0]) or not is_equal_approx(data.goal_height,data.height):return ["Raised work platform cannot travel."]
	else:
		if data.travel!=0 or data.from!=data.dock or data.to!=data.dock:return ["Stationary work platform has a transfer route."]
		if data.mode.is_empty() and (data.moving or not is_equal_approx(data.height,data.goal_height)):return ["Unlocked work platform at rest."]
	return []

func apply(data: Dictionary) -> void:
	if not validate(data).is_empty():return
	dock = data.dock;selected = data.selected;from_dock = data.from;to_dock = data.to;travel = data.travel
	height = data.height;goal_height = data.goal_height;mode = data.mode;moving = data.moving;blocked_reason = "";_pose()
