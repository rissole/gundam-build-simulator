extends "res://scripts/equipment.gd"
## Captive robot controls stay with their owning connection. They are operated
## through ordinary reach/visibility targeting and never become loose inventory.
const Codec = preload("res://scripts/pose_codec.gd")
var specs: Dictionary = {}
var locked: Dictionary = {}
var nodes: Dictionary = {}

func setup(workshop: Node3D, definitions: Dictionary) -> void:
	game=workshop;equipment_id="captive_controls";specs=definitions
	for id in specs:
		locked[id]=false
		var spec: Dictionary=specs[id]
		var root=Node3D.new();root.name=id;game.runtime.node(spec.owner).add_child(root)
		var visual=game.box(root,Vector3.ZERO,AssemblyRuntime.vec(spec.size),game.material(Color("e8b46b"),.35))
		nodes[id]={"root":root,"handle":visual}
	game.model.changed.connect(sync)
	sync()

func available(id: String, model: AssemblyModel = null) -> bool:
	var m: AssemblyModel=game.model if model==null else model
	var spec: Dictionary=specs[id]
	return not m.assemblies[spec.owner].slots[spec.slot].is_empty()

func sync() -> void:
	for id in specs:
		var spec: Dictionary=specs[id];var entry: Dictionary=nodes[id]
		entry.root.visible=available(id)
		entry.root.transform=game.runtime.local_slot_pose(spec.owner,spec.slot)*Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(spec.position))
		entry.handle.position=AssemblyRuntime.vec(spec.axis)*spec.stroke*(0 if locked[id] else 1)

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for id in specs:
		if not available(id):continue
		var spec: Dictionary=specs[id]
		var entry=control_entry(nodes[id].handle,id,spec.label+": "+("Pull out lock pin" if locked[id] else "Insert lock pin"),.08)
		entry["point"]=nodes[id].handle.global_position
		result.append(entry)
	return result

## Command ids are "lock:" plus each authored captive_controls key. The list is
## content, so tests build it with lock_commands() from robot-content.json.
static func lock_commands(ids) -> Array:
	var result: Array=[]
	for id in ids:result.append("lock:"+str(id))
	return result
func manual_control_actions(objective: Dictionary) -> Array:
	var id := str(objective.get("command","")).trim_prefix("lock:")
	return [id] if specs.has(id) and not locked[id] else []

func manual_commands() -> Array:return lock_commands(specs.keys())
func command_label(_action: String, _task: String="") -> String:return "Insert lock pin"
func manual_subject(objective: Dictionary) -> String:
	var id := str(objective.get("command","")).trim_prefix("lock:")
	return str(specs[id].label) if specs.has(id) else ""
func manual_state() -> Dictionary:
	var state: Dictionary={}
	for id in specs:state[id]=locked[id]
	return state
func manual_effect(objective: Dictionary) -> Dictionary:
	var id := str(objective.get("command","")).trim_prefix("lock:")
	return {id:true} if specs.has(id) else {}

func action_error(action: String) -> String:
	if not specs.has(action):return "Unknown captive control."
	if game.paused:return "Resume before operating the lock."
	if not available(action):return "Fit the hip cylinder before operating its lock pin."
	var spec: Dictionary=specs[action]
	var rail=game.equipment.get_equipment("leg_rail")
	if rail==null or rail.active_assembly!=spec.support_assembly or not rail.engaged or rail.path!=3 or rail.release!=0 or rail.moving or not rail.mode.is_empty():return "Reacquire and lock the leg rig before changing a lock pin."
	if not locked[action] and not spec.requires.all(func(sid):return not game.model.assemblies[spec.owner].slots[sid].is_empty()):return "Fit both eye pins and their captive keepers before inserting this lock pin."
	return game.hands.error(equipment_id)

func request(action: String) -> String:
	var error=action_error(action)
	if not error.is_empty():return error
	locked[action]=not locked[action];sync();return ""

func group_ready(group: String, data: Dictionary = {}) -> bool:
	var states: Dictionary=locked if data.is_empty() else data.get("locked",{})
	var found=false
	for id in specs:
		if specs[id].group!=group:continue
		found=true
		if not states.get(id,false):return false
	return found

func undo(owner: String) -> Dictionary:
	var history: Array=game.model.assemblies[owner].history
	if history.is_empty():return {"handled":false,"error":""}
	for id in specs:
		var spec: Dictionary=specs[id]
		if spec.owner==owner and locked[id] and history.back().slot in spec.protected_slots:return {"handled":true,"error":"Reacquire the leg rig and pull out the lock pin before removing its connection."}
	return {"handled":false,"error":""}

func capture() -> Dictionary:return {"version":1,"locked":locked.duplicate()}

func validate(data: Variant, candidate: AssemblyModel = null, _world: Dictionary = {}) -> Array[String]:
	if not Codec.same_keys(data,["version","locked"]) or data.version!=1 or not Codec.same_keys(data.locked,specs.keys()):return ["Invalid captive control snapshot."]
	var model: AssemblyModel=game.model if candidate==null else candidate
	for id in specs:
		if not data.locked[id] is bool:return ["Invalid captive lock state."]
		var spec: Dictionary=specs[id]
		if data.locked[id] and (not available(id,model) or not spec.requires.all(func(sid):return not model.assemblies[spec.owner].slots[sid].is_empty())):return ["A lock pin has no retained cylinder and eye pins."]
	return []

func apply(data: Dictionary) -> void:
	locked=data.locked.duplicate();sync()
