extends "res://scripts/guided_receiver.gd"
## Seat -> retain -> release. Physical ownership and filled slots are authoritative;
## this controller deliberately inherits the equipment's empty save contract.
var released_operations: Dictionary = {}
var operation_nodes: Dictionary = {}
var state: String:
	get:
		if not active:return "idle"
		if not retained():return "seated"
		return "retained" if _attached() else "released"

func setup(workshop: Node, id: String, definition: Dictionary) -> void:
	game=workshop;equipment_id=id;spec=definition
	game.model.changed.connect(_sync)
	for operation in spec.get("operations",[]):
		var body=game.runtime.node(operation.owner)
		var visual: MeshInstance3D
		var collision: CollisionShape3D
		for node in body.get_node("PreparedStructure").get_children():
			if node.get_meta("source_uid","")==operation.source:visual=node
		for node in body.get_children():
			if node is CollisionShape3D and node.get_meta("source_uid","")==operation.source:collision=node
		var handle=game.box(body,AssemblyRuntime.vec(operation.point),Vector3(.10,.08,.08),game.material(Color("e8b46b"),.3))
		operation_nodes[operation.id]={"visual":visual,"collision":collision,"handle":handle,"owner":body}
		released_operations[operation.id]=false
	_sync()

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for operation in spec.get("operations",[]):
		var nodes: Dictionary=operation_nodes[operation.id]
		result.append(control_entry(nodes.handle,("engage:" if released_operations[operation.id] else "release:")+operation.id,("Re-engage " if released_operations[operation.id] else "Release ")+operation.label,.12,{"point":nodes.handle.global_position,"allowed":[nodes.owner],"allow_body_hit":true}))
	return result

func action_error(action: String) -> String:
	if game.paused:return "Resume before operating the local restraint."
	var operation=action.get_slice(":",1)
	if action.get_slice(":",0) not in ["release","engage"] or not released_operations.has(operation):return "Unknown receiver operation."
	if action.begins_with("release:") and (not retained() or not _has(spec.closure_slots) or _attached()):return "Retain the carrier, release its rig and close both panels before releasing restraints."
	return game.hands.error(equipment_id)

func request(action: String) -> String:
	var error=action_error(action)
	if not error.is_empty():return error
	var operation=action.get_slice(":",1);var released=action.begins_with("release:")
	released_operations[operation]=released
	operation_nodes[operation].visual.visible=not released
	operation_nodes[operation].collision.disabled=released
	return ""

func operations_released() -> bool:return released_operations.values().all(func(value):return value)

func _sync() -> void:
	active=game.model.assemblies[spec.uid].parent==spec.owner and game.model.assemblies[spec.uid].parent_slot==spec.slot

func _crane() -> Node:return game.equipment.get_equipment("service_crane")
func _attached() -> bool:
	var crane=_crane()
	return crane!=null and crane.task==spec.crane_task and crane.attached_count()>0

func rigged() -> bool:
	var crane=_crane()
	return crane!=null and crane.task==spec.crane_task and crane.station=="receiver" and not crane.raised and crane.motion.is_empty() and crane.attached_count()==crane.required_ends

func _has(slots: Array, model: AssemblyModel = null) -> bool:
	var candidate=game.model if model==null else model
	return slots.all(func(sid):return not candidate.assemblies[spec.owner].slots[sid].is_empty())

func retained(_state: Dictionary = {}, model: AssemblyModel = null) -> bool:
	var candidate=game.model if model==null else model
	return candidate.assemblies[spec.uid].parent==spec.owner and _has(spec.retention_slots,candidate)

func secured(data: Dictionary = {}, model: AssemblyModel = null) -> bool:return retained(data,model)

func receiving_error(_uid: String = "") -> String:
	for requirement in spec.get("requires",[]):
		if not game.model.milestone(requirement.get_slice(":",0),requirement.get_slice(":",1)):
			return "Complete "+requirement.replace(":"," · ").replace("_"," ")+" before delivery."
	return ""

func load_pose() -> Transform3D:
	return game.runtime.node(spec.owner).global_transform*Transform3D(Basis.from_euler(AssemblyRuntime.vec(spec.seat.get("rotation_degrees",[0,0,0]))*PI/180),AssemblyRuntime.vec(spec.seat.position))

func beam_pose() -> Transform3D:return _crane()._load_beam(load_pose())

func end_transform(frame: Transform3D, index: int) -> Transform3D:
	var normal=AssemblyRuntime.vec(spec.rig.normals[index])
	return Transform3D(Basis(Quaternion(Vector3.UP,normal)),frame*(_crane().points[index]+normal*.045))

func cable_position(frame: Transform3D, index: int) -> Vector3:
	return frame*(_crane().points[index]+AssemblyRuntime.vec(spec.rig.normals[index])*.09)

func accept() -> String:
	var error=receiving_error()
	if not error.is_empty():return error
	var result: Dictionary=game.model.install_supported(spec.owner,spec.slot,spec.uid,_crane().support)
	if not result.ok:return result.error
	game.runtime.mount(spec.owner,spec.slot,spec.uid);game.refresh_assembly_collision(spec.owner)
	_sync();return ""

func rig_error(action: String, _point: String) -> String:
	if action=="detach" and not retained():return "Fit all receiver retention before releasing a crane end."
	if action=="attach" and spec.closure_slots.any(func(sid):return _has([sid])):return "Remove the closure panels before refitting the crane ends."
	return ""

func departure_error() -> String:
	if not _attached() and retained():return ""
	if rigged() and not spec.retention_slots.any(func(sid):return _has([sid])) and not spec.closure_slots.any(func(sid):return _has([sid])):return ""
	return "Release the retained load's crane ends, or remove its closures and retention under full crane support before lifting."

func placement_error(owner: String, sid: String) -> String:
	if owner!=spec.owner:return ""
	if sid in spec.closure_slots:
		return "Retain the carrier and release every crane end before fitting closure panels." if not retained() or _attached() else ""
	if sid in spec.retention_slots:return "Keep the matching crane down with all ends attached while fitting retention." if not active or not rigged() else ""
	return ""

func access_error(owner: String) -> String:
	return "Seat the payload before working on it." if owner==spec.uid and not active else ""

func undo(owner: String) -> Dictionary:
	if owner!=spec.owner or game.model.assemblies[owner].history.is_empty():return {"handled":false,"error":""}
	var sid: String=game.model.assemblies[owner].history.back().slot
	if sid in spec.closure_slots and released_operations.values().any(func(value):return value):return {"handled":true,"error":"Re-engage the local restraints before opening closure panels for correction."}
	if sid in spec.retention_slots and not rigged():return {"handled":true,"error":"Lower the matching crane and attach every end before removing retention."}
	return {"handled":false,"error":""}
