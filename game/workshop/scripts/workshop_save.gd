extends RefCounted
## One local save slot, written only when the player saves (pause menu Save,
## Save & quit, or closing the window). It holds the assembly model, each
## machine's last stop (the crane is halted where it is, as its Stop leaves it)
## and where the player stands and looks. Anything invalid is deleted: there are
## no migrations. Hands, pockets, loose parts and the manual are not saved.
const PATH = "user://workshop-save.json"
## Bump to discard every existing save after an incompatible change.
const FORMAT = 1
## Survives reload_current_scene, so the pause menu can explain a discarded save.
static var notice: String = ""
var game: Node
var path: String = ""
## Build and machine state as last saved or loaded; position alone is not a change.
var _last: int = 0
## Saved [x, y, z, yaw, pitch], placed once the player exists; empty keeps the spawn.
var _player: Array = []

func _init(workshop: Node, save_path: String) -> void:
	game = workshop
	path = save_path

func enabled() -> bool:return not path.is_empty()

## Model state with hands, pockets and loose parts returned to their sources.
func normalised_model() -> Dictionary:
	var data: Dictionary = game.model.capture()
	for uid in data.items:
		var item: Dictionary = data.items[uid]
		if item.owner.is_empty() and item.location in ["held","loose","pocket"]:
			item.location = game.part_defs.get(uid,{}).get("location","bin")
			item.pocket = -1
	for id in data.assemblies:
		if data.assemblies[id].location == "held":data.assemblies[id].location = "loose"
	data.pockets = []
	for index in range(AssemblyModel.POCKET_SLOTS):data.pockets.append("")
	data.selected_pocket = 0
	return data

func snapshot() -> Dictionary:
	# Mid-ride, the player goes back to the stop the machine reloads at.
	var steady: Variant = game.equipment.steady_player
	var player: Transform3D = steady if steady is Transform3D else game.player.global_transform
	var rope = game.equipment.get_equipment("rope_access")
	if rope!=null and rope.attached():player = game.player.global_transform
	return {"format":FORMAT,"model":normalised_model(),"equipment":game.equipment.save_capture(),
		"player":[player.origin.x,player.origin.y,player.origin.z,player.basis.get_euler().y,game.camera.rotation.x]}

func _signature() -> int:
	return JSON.stringify([normalised_model(),game.equipment.save_capture()]).hash()

## Whether the build or a machine changed since the last save or load.
func unsaved() -> bool:return enabled() and _signature() != _last

## Treats the current build as saved, e.g. once a --stage launch is prepared.
func settle() -> void:_last = _signature()

## Writes the workshop now. Returns why it could not, or empty.
func save_now() -> String:
	if not enabled():return "This launch is not saved."
	if game.get("staging") == true:return "the stage is still being prepared."
	var error: String = write(snapshot())
	if error.is_empty():_last = _signature()
	return error

## Writes beside the slot, then renames over it, so a crash never leaves half a file.
func write(data: Dictionary) -> String:
	var temporary: String = path+".tmp"
	var file = FileAccess.open(temporary,FileAccess.WRITE)
	if file == null:return "cannot write "+temporary+" ("+str(FileAccess.get_open_error())+")"
	file.store_string(JSON.stringify(data,"",false,true))
	file.close()
	var error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(path))
	return "" if error == OK else "cannot replace "+path+" ("+str(error)+")"

static func delete(save_path: String) -> void:
	if save_path.is_empty():return
	for file in [save_path,save_path+".tmp"]:
		if FileAccess.file_exists(file):DirAccess.remove_absolute(ProjectSettings.globalize_path(file))

func discard(reason: String) -> void:
	notice = "Your saved workshop did not match this version and was discarded ("+reason+")."
	push_warning("Workshop save discarded: "+reason)
	delete(path)

## Restores the saved workshop before stock and drawers are laid out. All checks
## run before anything live changes. Returns true when a save was restored.
func load_saved() -> bool:
	var restored = false
	if enabled() and FileAccess.file_exists(path):
		# JSON.new().parse reports failure without printing an engine error.
		var json = JSON.new()
		var data: Variant = json.data if json.parse(FileAccess.get_file_as_string(path)) == OK else null
		var error: String = _check(data)
		if error.is_empty():error = "; ".join(game.model.restore(data.model))
		if error.is_empty():
			_rebuild(data.equipment)
			_player = data.get("player",[])
			notice = "Restored your saved workshop. Loose parts went back to their drawers; a crane that was moving is stopped where it was."
			restored = true
		else:discard(error)
	_last = _signature()
	return restored

## After the player is spawned: stand them where they saved, if they did.
func place_player() -> void:
	if _player.is_empty():return
	game.player.global_position = Vector3(_player[0],_player[1],_player[2])
	game.player.rotation.y = _player[3]
	game.camera.rotation.x = _player[4]
	_player = []

func _check(data: Variant) -> String:
	if not data is Dictionary:return "unreadable file"
	if data.get("format") != FORMAT:return "format "+str(data.get("format"))
	if not data.get("model") is Dictionary or not data.get("equipment") is Dictionary:return "missing sections"
	# Saves from before position was kept have no player; they start at the spawn.
	var player: Variant = data.get("player",[])
	if not player is Array or not (player.is_empty() or (player.size() == 5 and player.all(func(value):return value is float))):return "player position"
	var fresh: Dictionary = game.equipment.save_capture()
	# Saves from before the crane was saved reload it parked, as they did then.
	if not data.equipment.has("service_crane") and fresh.has("service_crane"):data.equipment.service_crane = fresh.service_crane
	if data.equipment.size() != fresh.size() or not fresh.keys().all(func(id):return data.equipment.has(id)):return "equipment changed"
	for id in fresh:
		if not same_shape(data.equipment[id],fresh[id]):return id+" state changed"
		data.equipment[id] = coerce(data.equipment[id],fresh[id])
	# Rope attachment is safety-critical and has variable station identities.
	# Validate it before restoring any live model/equipment, not only in apply().
	var rope = game.equipment.get_equipment("rope_access")
	if rope!=null:
		var errors: Array[String] = rope.validate(data.equipment.rope_access,null,data)
		if not errors.is_empty():return "; ".join(errors)
	return ""

## Places bodies from the restored model, then lets each machine pose its loads.
func _rebuild(equipment: Dictionary) -> void:
	var model: AssemblyModel = game.model
	var order: Array = model.assemblies.keys().filter(func(id):return game.runtime.nodes.has(id))
	# Parents before children, so every mount pose is taken from a placed parent.
	order.sort_custom(func(a,b):return _depth(a) < _depth(b))
	for id in order:
		var a: Dictionary = model.assemblies[id]
		if not a.parent.is_empty():game.runtime.mount(a.parent,a.parent_slot,id)
		elif a.location.begins_with("station:"):game.suspend_build(id,a.location.trim_prefix("station:"))
		elif a.location == "loose" and game.bodies.has(id) and game.bodies[id].get_parent() != game:
			# Only a build that starts mounted needs moving; fresh loose builds stay put.
			var body: RigidBody3D = game.bodies[id]
			body.reparent(game)
			body.global_transform = Transform3D(Basis.IDENTITY,game.home_position(id)+Vector3.UP*.06)
			body.freeze = false
			body.gravity_scale = 1
	game.equipment.apply_saved(equipment)
	for id in order:game.components.sync(id)
	for id in order:
		if model.assemblies[id].parent.is_empty():game.refresh_assembly_collision(id)
	# Machines that follow the model resync with their restored state.
	model.changed.emit()

func _depth(id: String) -> int:
	var depth = 0
	var parent: String = game.model.assemblies[id].parent
	while not parent.is_empty():
		depth += 1
		parent = game.model.assemblies[parent].parent
	return depth

## Saved machine state must have exactly the fields today's capture has.
static func same_shape(saved: Variant, fresh: Variant) -> bool:
	if not saved is Dictionary or not fresh is Dictionary or saved.size() != fresh.size():return false
	return fresh.keys().all(func(key):return saved.has(key))

## JSON turns every number into a float. Restore ints wherever today's value is
## an int, recursively, so typed fields and comparisons keep working.
static func coerce(saved: Variant, fresh: Variant) -> Variant:
	if fresh is int and saved is float:return int(saved)
	if fresh is Dictionary and saved is Dictionary:
		var result = {}
		for key in saved:result[key] = coerce(saved[key],fresh[key]) if fresh.has(key) else saved[key]
		return result
	if fresh is Array and saved is Array and not fresh.is_empty():
		var result = []
		for index in range(saved.size()):result.append(coerce(saved[index],fresh[mini(index,fresh.size()-1)]))
		return result
	return saved
