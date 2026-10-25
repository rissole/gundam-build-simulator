# 03 — Save store, load and workshop hooks

Read [README.md](README.md) "Rules for every task" first. Requires tasks 01 and 02
to be committed: check that `git log --oneline -5` shows both, and that
`AssemblyModel.restore` and `EquipmentRegistry.save_capture` exist. If either is
missing, stop.

**Files you may touch:**
- `game/workshop/scripts/workshop_save.gd`
- `game/workshop/scripts/workshop.gd`
- `game/workshop/scripts/service_crane.gd` (one method only)

## Goal

- Normal launches write `user://workshop-save.json` each time the normalised
  assembly model changes, unless a load is hanging on the crane.
- The save is restored synchronously during `_ready`, before drawers and stock are
  laid out.
- An invalid file is deleted and the workshop starts fresh.
- Tests, tools and `--stage` launches never read or write the human save; tests opt
  in with `save_path`.

## Step 1 — crane query

In `game/workshop/scripts/service_crane.gd`, anchor (must match once):

```
func _crane_owned(model: AssemblyModel = null) -> bool:
	return _record(model).location == "support:"+support
```

Insert this **immediately after** it, with a blank line before it:

```gdscript
## True while the active load hangs on the crane: the workshop save waits for delivery.
func holds_load() -> bool:return _crane_owned()
```

## Step 2 — extend `game/workshop/scripts/workshop_save.gd`

Replace the file's first three lines:

```
extends RefCounted
## One local workshop save slot. Task 03 adds the store and load; these helpers
## are generic so no machine needs its own save code.
```

with:

```gdscript
extends RefCounted
## One local save slot, written each time the player sets a component. It holds
## the assembly model and each machine's last stop; the crane always reloads
## parked. Anything invalid is deleted: there are no migrations. Hands, pockets,
## loose parts, the player and the manual are not saved.
const PATH = "user://workshop-save.json"
## Bump to discard every existing save after an incompatible change.
const FORMAT = 1
const SKIPPED = ["service_crane"]
## Survives reload_current_scene, so the pause menu can explain a discarded save.
static var notice: String = ""
var game: Node
var path: String = ""
var _last: int = 0
var _queued: bool = false

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
	return {"format":FORMAT,"model":normalised_model(),"equipment":game.equipment.save_capture(SKIPPED)}

## Connected to model.changed: queue at most one write per frame.
func model_changed() -> void:
	if not enabled() or _queued:return
	_queued = true
	flush.call_deferred()

func flush() -> void:
	_queued = false
	if not enabled():return
	var signature: int = JSON.stringify(normalised_model()).hash()
	if signature == _last:return
	# Save after delivery: a load hanging on the crane is never saved.
	var crane = game.equipment.get_equipment("service_crane")
	if crane != null and crane.holds_load():return
	var error: String = write(snapshot())
	if error.is_empty():_last = signature
	else:push_warning("Workshop save failed: "+error)

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
			notice = "Restored your saved workshop. Loose parts went back to their drawers and the crane is parked."
			restored = true
		else:discard(error)
	_last = JSON.stringify(normalised_model()).hash()
	return restored

func _check(data: Variant) -> String:
	if not data is Dictionary:return "unreadable file"
	if data.get("format") != FORMAT:return "format "+str(data.get("format"))
	if not data.get("model") is Dictionary or not data.get("equipment") is Dictionary:return "missing sections"
	var fresh: Dictionary = game.equipment.save_capture(SKIPPED)
	if data.equipment.size() != fresh.size() or not fresh.keys().all(func(id):return data.equipment.has(id)):return "equipment changed"
	for id in fresh:
		if not same_shape(data.equipment[id],fresh[id]):return id+" state changed"
		data.equipment[id] = coerce(data.equipment[id],fresh[id])
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
```

Keep the existing `same_shape` and `coerce` functions below this code, unchanged.

## Step 3 — workshop.gd

All anchors are in `game/workshop/scripts/workshop.gd` and each must match once.

**3a.** Anchor:
```
const Stages = preload("res://scripts/build_stages.gd")
```
Replace with:
```gdscript
const Stages = preload("res://scripts/build_stages.gd")
const Save = preload("res://scripts/workshop_save.gd")
```

**3b.** Anchor:
```
var stage_notice: String = ""
```
Replace with:
```gdscript
var stage_notice: String = ""
## The save slot. Empty (no saving) unless this is a normal launch; tests opt in.
var save_path: String = ""
var save: RefCounted
```

**3c.** Anchor:
```
	_build_equipment(EQUIPMENT.filter(func(id):return id != "foot_fixture"))
```
Replace with:
```gdscript
	_build_equipment(EQUIPMENT.filter(func(id):return id != "foot_fixture"))
	start_stage = Stages.stage_flag(Array(OS.get_cmdline_user_args()))
	# Only a normal launch keeps a save; tests, tools (custom SceneTree scripts)
	# and --stage launches never touch it.
	if save_path.is_empty() and not automated_test and start_stage.is_empty() and get_tree().get_script() == null:save_path = Save.PATH
	save = Save.new(self,save_path)
	if save.load_saved():
		# Restored milestones are not new: no toast or chime on load.
		for id in builds:
			prepared_flags[id] = build_prepared(id)
			completed_flags[id] = build_complete(id)
```

**3d.** Anchor:
```
	model.changed.connect(_state_changed)
```
Replace with:
```gdscript
	model.changed.connect(_state_changed)
	model.changed.connect(save.model_changed)
```

**3e.** Anchor: the line below, followed by the `if not start_stage.is_empty()` line.
```
	start_stage = Stages.stage_flag(Array(OS.get_cmdline_user_args()))
	if not start_stage.is_empty() and not automated_test:call_deferred("run_stage",start_stage)
```
Replace both lines with just the second one (step 3c now sets `start_stage`):
```gdscript
	if not start_stage.is_empty() and not automated_test:call_deferred("run_stage",start_stage)
```
After 3c, the `start_stage = …` line appears twice. Do 3e by matching the two-line
block above, which must match exactly once.

**3f.** Anchor:
```
	# Nothing is saved; reloading also re-runs any --stage launch flag.
```
Replace with:
```gdscript
	# Reloading restores the saved workshop, if any, or re-runs a --stage launch.
```

**3g.** Find `func reset_demo() -> void:` and the body line after it. Immediately after
that function, insert:
```gdscript

## Pause menu: forget the saved workshop and start again from a fresh launch.
func new_workshop() -> void:
	Save.delete(save_path)
	Save.notice = ""
	reset_demo()
```

## Acceptance

1. `grep -c "Stages.stage_flag" game/workshop/scripts/workshop.gd` prints `1`.
2. `grep -c "model.changed.connect(save.model_changed)" game/workshop/scripts/workshop.gd` prints `1`.
3. `grep -c "func holds_load() -> bool" game/workshop/scripts/service_crane.gd` prints `1`.
4. `grep -c "class_name" game/workshop/scripts/workshop_save.gd` prints `0`.
5. `python3 game/workshop/tools/run_regressions.py --only workshop_smoke_test stage_contract_test assembly_model_test wide_elevators_test crane_policy_test`
   passes.
6. Check that tests never touched the human save:
   `ls ~/Library/Application\ Support/Godot/app_userdata/*/workshop-save.json 2>/dev/null`
   prints nothing new. If a `workshop-save.json` exists, check its modification time
   with `ls -l`. If your test runs created it, the isolation guard is wrong: stop and
   report.

Task 05 adds the round-trip test. Don't write one here.

## Commit

```
git commit -m "Save the workshop each time a component is set and restore it on launch" -- game/workshop/scripts/workshop_save.gd game/workshop/scripts/workshop.gd game/workshop/scripts/service_crane.gd
```
