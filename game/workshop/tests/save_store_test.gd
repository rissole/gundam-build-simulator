extends SceneTree

const Store = preload("res://scripts/save_store.gd")
var checks: Array[Dictionary] = []
var directory := "/tmp/workshop-save-store-%s-%s" % [OS.get_process_id(), Time.get_ticks_usec()]

func expect(condition: bool, label: String) -> void:
	checks.append({"check": label, "passed": condition})
	if not condition:
		push_error(label)

func put(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()

func _initialize() -> void:
	DirAccess.make_dir_absolute(directory)
	var path := directory.path_join("profile.json")
	var first := {"state": {"part": "tray", "count": 1, "position": [1.25, 2, -3]}, "history": []}
	var second := {"state": {"part": "bench", "count": 2}, "history": [{"move": true}]}
	first = JSON.parse_string(JSON.stringify(first))
	second = JSON.parse_string(JSON.stringify(second))
	expect(Store.read(path, "content-v1").missing, "Absent file is an empty profile")
	expect(Store.write(path, "content-v1", first).is_empty(), "Initial save succeeds")
	var restored := Store.read(path, "content-v1")
	expect(restored.ok and restored.payload == first and not restored.saved_at.is_empty(), "JSON state round trips with timestamp")
	expect(Store.write(path, "content-v1", second).is_empty(), "Replacement save succeeds")
	expect(Store.read(path, "content-v1").payload == second, "Primary contains newest state")
	expect(Store.read(path + ".bak", "content-v1").payload == first, "Backup contains prior good state")
	var good_json := FileAccess.get_file_as_string(path)
	put(path, "{\"version\":1,")
	expect(not Store.read(path, "content-v1").ok, "Truncated JSON is rejected")
	expect(not Store.write(path, "content-v1", second).is_empty(), "Default write refuses to rotate corrupt primary")
	expect(Store.read(path + ".bak", "content-v1").payload == first, "Corrupt primary never replaces valid backup")
	expect(Store.write(path, "content-v1", second, false).is_empty(), "Explicit recovery can replace corrupt primary")
	expect(Store.read(path + ".bak", "content-v1").payload == first, "Recovery preserves last good backup")
	var envelope: Dictionary = JSON.parse_string(good_json)
	envelope.version = 99
	put(path, JSON.stringify(envelope))
	expect(Store.read(path, "content-v1").unsupported, "Future save version blocks overwrite")
	envelope.version = 0
	put(path, JSON.stringify(envelope))
	expect(Store.read(path, "content-v1").unsupported, "Unknown older version blocks overwrite")
	put(path, good_json)
	expect(Store.read(path, "other-content").unsupported, "Content mismatch blocks overwrite")
	envelope = JSON.parse_string(good_json)
	envelope.payload.state.part = "tampered"
	put(path, JSON.stringify(envelope))
	expect(not Store.read(path, "content-v1").ok, "Payload corruption fails checksum")
	envelope.payload = []
	put(path, JSON.stringify(envelope))
	expect(not Store.read(path, "content-v1").ok, "Non-object payload is rejected")
	put(path, "[]")
	expect(not Store.read(path, "content-v1").ok, "Non-object envelope is rejected")
	put(path, good_json)
	expect(not Store.write(directory.path_join("missing/profile.json"), "content-v1", first).is_empty(), "Unavailable parent reports save failure")
	expect(Store.read(path, "content-v1").payload == second, "Failed save leaves existing primary intact")
	expect(not Store.write(path, "content-v1", {"invalid": Vector3.ZERO}).is_empty(), "Resource or engine types cannot enter JSON")
	expect(not Store.write(path, "content-v1", {"invalid": NAN}).is_empty(), "Non-finite numbers cannot enter JSON")
	expect(not Store.read(directory, "content-v1").missing, "Directory path is reported as a read error")
	var blocked := directory.path_join("blocked.json")
	expect(Store.write(blocked, "content-v1", first).is_empty(), "Prepare backup failure fixture")
	DirAccess.make_dir_absolute(blocked + ".bak")
	expect(not Store.write(blocked, "content-v1", second).is_empty(), "Backup replacement failure is reported")
	expect(Store.read(blocked, "content-v1").payload == first, "Backup failure preserves primary state")
	DirAccess.remove_absolute(blocked + ".bak")
	DirAccess.remove_absolute(blocked)
	var oversized := " ".repeat(Store.MAX_BYTES + 1)
	put(directory.path_join("large.json"), oversized)
	expect(not Store.read(directory.path_join("large.json"), "content-v1").ok, "Oversized save is rejected before parsing")
	var names := DirAccess.get_files_at(directory)
	expect(names.size() == 3 and "profile.json" in names and "profile.json.bak" in names and "large.json" in names, "All successful and failed writes clean temporary files")
	for name in names:
		DirAccess.remove_absolute(directory.path_join(name))
	DirAccess.remove_absolute(directory)
	var passed := checks.all(func(check): return check.passed)
	print("SAVE_STORE_AUDIT ", "PASS" if passed else "FAIL", " ", checks.size(), " checks")
	quit(0 if passed else 1)
