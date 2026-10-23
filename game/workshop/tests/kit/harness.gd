extends SceneTree
## Shared headless suite lifecycle and evidence. Scene fixtures still own their
## assertions; booting and supplied construction are never gameplay evidence.
const PlayerDriver = preload("res://tests/kit/player_driver.gd")
const Staging = preload("res://scripts/scenario_staging.gd")
var checks: Array[Dictionary] = []

static func record(into: Array, ok: bool, label: String) -> void:
	into.append({"check":label,"passed":ok})
	print("CHECK ","PASS " if ok else "FAIL ",label)
	if not ok:push_error(label)

func expect(ok: bool, label: String) -> void:
	record(checks,ok,label)

func frames(count: int = 3, physics: bool = true) -> void:
	await wait_frames(self,count,physics)

static func wait_frames(tree: SceneTree, count: int, physics: bool = true) -> void:
	for tick in range(count):
		if physics:await tree.physics_frame
		else:await tree.process_frame

static func write_evidence(path: String, report: Dictionary) -> void:
	var directory = path.get_base_dir()
	var error = DirAccess.make_dir_recursive_absolute(directory)
	if error != OK:
		push_error("Cannot create evidence directory: "+directory+" ("+str(error)+")")
		return
	var file = FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		push_error("Cannot write evidence: "+path+" ("+str(FileAccess.get_open_error())+")")
		return
	file.store_string(JSON.stringify(report,"  ")+"\n")
	file.close()

static func instantiate_profile(tree: SceneTree, profile_id: String, options: Dictionary = {}) -> Node:
	var workshop = load("res://scenes/workshop.tscn").instantiate()
	workshop.profile_override = profile_id
	workshop.automated_test = true
	for property in options:workshop.set(property,options[property])
	tree.root.add_child(workshop)
	return workshop

func boot_profile(profile_id: String = "foot", settle_frames: int = 8, options: Dictionary = {}) -> Node:
	var workshop = instantiate_profile(self,profile_id,options)
	await frames(settle_frames)
	workshop.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return workshop

static func build_state(workshop: Node, owner: String) -> HeelAssemblyState:
	# Explicitly bound compatibility view for historical pad assertions only.
	# Runtime targeting/installation uses generic model/component owners.
	var view = HeelAssemblyState.new()
	view.bind(workshop.model,owner)
	return view
