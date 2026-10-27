extends RefCounted
## Isolated authored crane/front sequences; production crane geometry, effects,
## labels and manual evaluator. Front state/control metadata stands in for R1.
const Objectives=preload("res://scripts/manual_objectives.gd")
const Progress=preload("res://scripts/manual_progress.gd")
const Fronts=preload("res://tests/kit/manual_fronts.gd")
const Layout=preload("res://scripts/leg_bay_layout.gd")
const CROSSINGS=["pelvis","chest","core","backpack","left_arm","right_arm","left_pauldron","right_pauldron","head_baseplate","head_left","head_right","head_top","head_crown"]
class Crane extends "res://scripts/service_crane.gd":
	func _refresh() -> void:pass
	func _guide() -> Node:return null # No live receiver motion in a manual fixture.

static func configure(crane, task: String) -> void:
	var spec: Dictionary=crane.tasks[task]
	var route: Array[Transform3D]=[]
	var source=Layout.authored_pose(spec.source_pose);var receiver=Layout.authored_pose(spec.receiver_pose)
	for index in spec.route_positions.size():
		var rotation=Basis.from_euler(AssemblyRuntime.vec(spec.route_rotations[index])*PI/180) if spec.has("route_rotations") else (source.basis if index<2 else receiver.basis)
		route.append(Transform3D(rotation,AssemblyRuntime.vec(spec.route_positions[index])))
	route[0]=source;route[-1]=receiver
	crane.task=task
	crane._configure_task({"spec":spec,"route":route,"source_pose":source,"receiver_pose":receiver})
	crane.moving=false;crane.motion="";crane.progress=0;crane.travel_from=null

static func connectors(crane, attached: bool) -> void:
	for index in crane.END_IDS.size():
		crane.endpoints[crane.END_IDS[index]]={"state":"attached" if attached else "stowed","point":crane.POINT_IDS[index] if attached else ""}

static func route_crosses(crane, station: String, raised: bool, motion: String, loaded: bool) -> bool:
	crane.station=station;crane.raised=raised;crane.motion=motion;crane.progress=0
	connectors(crane,loaded)
	return crane._upper_crossing(1.0)

static func run(h) -> void:
	var game=preload("res://tests/kit/model_workshop.gd").new();h.root.add_child(game)
	h.expect(game.setup().is_empty(),"gantry manual audit loads authored model")
	var crane=Crane.new();game.add_child(crane);crane.game=game;crane.equipment_id="service_crane";game.equipment.register(crane)
	crane.tasks=Layout.layout().crane.tasks
	var front=Fronts.new();game.add_child(front);front.equipment_id="workshop_access";game.equipment.register(front)
	# Only the shoulder adapter changes the beam pose in an inactive receiver.
	# Use its production mass/geometry calculation without building scene meshes.
	for side in ["left","right"]:
		var shoulder=preload("res://scripts/shoulder_support.gd").new();game.add_child(shoulder)
		shoulder.game=game;shoulder.equipment_id=side+"_shoulder";shoulder.spec=game.leg_content.equipment[side+"_shoulder"]
		shoulder.mass=preload("res://scripts/arm_delivery_geometry.gd").mass_properties(game.leg_content,game.runtime.definition(side+"_arm"))
		game.equipment.register(shoulder)
	for record in [["module_supports",preload("res://scripts/module_supports.gd")],["core_guide",preload("res://scripts/core_guide.gd")],["backpack_hinge",preload("res://scripts/backpack_hinge.gd")],["arm_cassette",preload("res://scripts/equipment.gd")]]:
		var adapter=record[1].new();game.add_child(adapter);adapter.game=game;adapter.equipment_id=record[0];game.equipment.register(adapter)
	for spec in crane.tasks.values():
		var id: String=spec.get("rig_adapter","")
		if id.is_empty() or game.equipment.get_equipment(id)!=null:continue
		var adapter=preload("res://scripts/equipment.gd").new();game.add_child(adapter);adapter.equipment_id=id;game.equipment.register(adapter)
	var routes: Array=[]
	for task in crane.tasks:
		configure(crane,task)
		var pickup=route_crosses(crane,"park",true,"go:source",false)
		var lift=route_crosses(crane,"source",false,"up",true)
		var transfer=route_crosses(crane,"source",true,"go:receiver",true)
		var lower=route_crosses(crane,"receiver",true,"down",true)
		var return_lift=route_crosses(crane,"receiver",false,"up",false)
		var park=route_crosses(crane,"receiver",true,"go:park",false)
		var arm=task in ["left_arm","right_arm"]
		h.expect(not pickup and not lift and transfer==((task in CROSSINGS) and not arm) and (transfer or lower)==(task in CROSSINGS) and (return_lift or park)==(task in CROSSINGS),task+" manual front plan matches production crossing projection, including empty return: "+str([pickup,lift,transfer,lower,return_lift,park]))
		routes.append({"task":task,"pickup":pickup,"loaded_lift":lift,"transfer":transfer,"loaded_lower":lower,"empty_raise":return_lift,"empty_park":park,"receiver":"inactive receiver; production route projection, no live guide motion"})
	var progress=Progress.new(game)
	var pages: Array=[]
	for chapter in progress.chapters():
		for row in chapter.steps:
			var page: Dictionary=row.definition
			if not page.get("objectives",[]).any(func(o):return o.get("machine")=="workshop_access" and str(o.get("command","")).begins_with("upper_")):continue
			var task: String=page.machine_scope.service_crane.task
			configure(crane,task)
			var commands: Array=[];var texts: Array=[];var displayed: Array=[]
			for o in page.objectives:
				commands.append(str(o.get("machine",o.get("via",{}).get("machine","")))+":"+str(o.get("command",o.get("op",""))))
				texts.append(Objectives.text(game,row.owner,o))
			var procedure=progress.procedure(row.owner,row.page)
			for index in Objectives.display_indices(page,procedure):displayed.append(texts[index])
			h.expect(texts.all(func(t):return not t.is_empty()),row.title+" renders every typed objective")
			h.expect((str(page.goal)+str(page.get("note",{}).get("text",""))).count("UPPER GANTRY panel at 20.6 m beside the left lift")==1,row.title+" locates the panel once in authored guidance")
			var delivery=commands.find("service_crane:go:receiver");var park=commands.find("service_crane:go:park")
			if delivery>=0:h.expect(commands.find("workshop_access:upper_open")==delivery+(1 if task in ["left_arm","right_arm"] else -1),row.title+" opens the upper leaves before the first crossing objective")
			if park>=0:
				h.expect(commands[park+1]=="workshop_access:upper_close" and commands.rfind("workshop_access:upper_open")<commands.rfind("service_crane:up"),row.title+" reopens before raising the empty crane and closes after parking")
			if task in ["left_arm","right_arm"]:
				if delivery>=0:h.expect(commands[commands.find("service_crane:up")-1]=="workshop_access:lower_open",row.title+" opens the lower front before the loaded lift and transfer")
				if park>=0:h.expect(commands[commands.find("service_crane:detach")+1]=="workshop_access:lower_close",row.title+" closes the lower front after releasing the arm")
			if task=="pelvis":h.expect(page.objectives[page.note.at].command=="upper_close" and commands.count("workshop_access:upper_open")==2,row.title+" closes for rope work and reopens for the empty return")
			if procedure.get("repeat",false):
				h.expect(Objectives.display_indices(page,procedure).all(func(i):return page.objectives[i].get("machine",page.objectives[i].get("via",{}).get("machine","")) not in ["service_crane","workshop_access"]),row.title+" hides repeated machine controls and retains independent work")
			pages.append({"owner":row.owner,"page_index":row.page,"title":row.title,"goal":page.goal,"note":page.get("note",{}),"slots":page.slots,"objectives":page.objectives,"rendered_objective_text":texts,"displayed_objective_text":displayed,"procedure":procedure.get("label","") if procedure.get("repeat",false) else ""})
			sequence(h,game,crane,front,row.owner,page,task)
	h.write_evidence("res://verification/r3-gantry-pages.json",{"rendered_visual_review":false,"fronts":"manual API double kept identical to workshop_access by gantry_fronts_test","routes":routes,"pages":pages})
	game.free()

static func sequence(h, game, crane, front, owner: String, authored: Dictionary, task: String) -> void:
	# Retain the authored crane guards and physical seats. Other machine controls
	# have their own tests; remove only those controls and page completion shortcuts
	# to observe every cumulative crane/front prefix rather than durable proofs.
	var page={"objectives":[],"machine_scope":{"service_crane":{"task":task}}}
	for o in authored.objectives:
		if o.get("machine",o.get("via",{}).get("machine","")) in ["service_crane","workshop_access"]:page.objectives.append(o.duplicate(true))
	var delivery=page.objectives.any(func(o):return o.get("command")=="pickup")
	var spec: Dictionary=crane.tasks[task]
	var load: Dictionary=game.model.assemblies[spec.load_uid]
	load.parent="";load.parent_slot="";load.location="support:"+str(spec.source_support if delivery else spec.get("receiver_support","crane_rigging"))
	if not str(spec.slot).is_empty():game.model.assemblies[spec.owner].slots[spec.slot]="" if delivery else spec.load_uid
	crane.station="park" if delivery else "receiver";crane.raised=delivery;crane.motion=""
	connectors(crane,not delivery)
	front.set_front("upper",0.0);front.set_front("lower",1.0 if task in ["left_arm","right_arm"] and not delivery else 0.0)
	for index in page.objectives.size():
		var o: Dictionary=page.objectives[index]
		var machine: String=o.get("machine",o.get("via",{}).get("machine",""))
		var action: String=o.get("command",o.get("via",{}).get("command",o.op))
		if machine=="workshop_access":
			var which=action.get_slice("_",0);var goal=1.0 if action.ends_with("_open") else 0.0
			front.set_front(which,0.5,goal,true)
			h.expect(not Objectives.evaluate(game,owner,page).ticked[index],authored.title+" waits for "+action+" to stop")
			front.set_front(which,goal)
		elif o.op=="connect":connectors(crane,true)
		elif o.op=="detach":
			if o.has("point"):
				for end in crane.endpoints.values():
					if end.point==o.point:end.state="stowed";end.point=""
			else:connectors(crane,false)
		elif action=="pickup":crane.station="source"
		elif action.begins_with("go:"):crane.station=action.get_slice(":",1)
		elif action in ["up","down"]:
			crane.raised=action=="up"
			if crane.station=="receiver" and action=="down":
				load.location="support:"+str(spec.get("receiver_support","crane_rigging"))
		if o.op=="seat":game.model.assemblies[owner].slots[o.slot]=spec.load_uid
		var evaluated=Objectives.evaluate(game,owner,page)
		h.expect(evaluated.ticked.slice(0,index+1).all(func(tick):return tick),authored.title+" cumulative prefix "+str(index+1)+" ticks: "+str(evaluated.ticked))
