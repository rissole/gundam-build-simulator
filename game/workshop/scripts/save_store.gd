class_name WorkshopSaveStore
extends RefCounted

const VERSION := 1
const MAX_BYTES := 8 * 1024 * 1024
const MAX_DEPTH := 64

static func exists(path: String) -> bool:
	return FileAccess.file_exists(path)

# The coordinator owns payload semantics and the decision to replace a bad save.
# Passing false preserves the last known good backup during recovery/reset.
static func write(path: String, fingerprint: String, payload: Dictionary, rotate_backup: bool = true) -> String:
	if not _json_value(payload):
		return "Save contains a value that cannot be stored as JSON."
	var normalized = JSON.parse_string(JSON.stringify(payload))
	var envelope := {
		"version": VERSION,
		"fingerprint": fingerprint,
		"saved_at": Time.get_datetime_string_from_system(true) + "Z",
		"payload": normalized,
		"checksum": JSON.stringify(normalized).sha256_text(),
	}
	var bytes := JSON.stringify(envelope).to_utf8_buffer()
	if bytes.size() > MAX_BYTES:
		return "Save exceeds the 8 MB limit."
	var absolute := ProjectSettings.globalize_path(path)
	var suffix := ".tmp-%s-%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	var temporary := absolute + suffix
	var error := _write_bytes(temporary, bytes)
	if not error.is_empty():
		return error
	if rotate_backup and exists(path):
		var previous := read(path, fingerprint)
		if not previous.ok:
			DirAccess.remove_absolute(temporary)
			return "Existing save is not valid; explicit recovery is required before replacing it. " + previous.error
		var old_file := FileAccess.open(absolute, FileAccess.READ)
		if old_file == null:
			DirAccess.remove_absolute(temporary)
			return "Cannot read the existing save for backup: " + error_string(FileAccess.get_open_error())
		var old_bytes := old_file.get_buffer(old_file.get_length())
		var read_error := old_file.get_error()
		old_file.close()
		if read_error != OK:
			DirAccess.remove_absolute(temporary)
			return "Cannot read the existing save for backup: " + error_string(read_error)
		var backup_temp := absolute + ".bak" + suffix
		error = _write_bytes(backup_temp, old_bytes)
		if error.is_empty():
			var backup_error := DirAccess.rename_absolute(backup_temp, absolute + ".bak")
			if backup_error != OK:
				error = "Cannot replace save backup: " + error_string(backup_error)
				DirAccess.remove_absolute(backup_temp)
		if not error.is_empty():
			DirAccess.remove_absolute(temporary)
			return error
	var replace_error := DirAccess.rename_absolute(temporary, absolute)
	if replace_error != OK:
		DirAccess.remove_absolute(temporary)
		return "Cannot replace save file: " + error_string(replace_error)
	return ""

static func read(path: String, fingerprint: String) -> Dictionary:
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		return _failure("Save path is a directory.")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var open_error := FileAccess.get_open_error()
		if open_error == ERR_FILE_NOT_FOUND:
			return _failure("No saved workshop was found.", true)
		return _failure("Cannot open save file: " + error_string(open_error))
	var length := file.get_length()
	if length > MAX_BYTES:
		file.close()
		return _failure("Save exceeds the 8 MB limit.")
	var bytes := file.get_buffer(length)
	var read_error := file.get_error()
	file.close()
	if read_error != OK or bytes.size() != length:
		return _failure("Cannot read the complete save file: " + error_string(read_error))
	var json := JSON.new()
	if json.parse(bytes.get_string_from_utf8()) != OK:
		return _failure("Save is not valid JSON: " + json.get_error_message())
	if not json.data is Dictionary:
		return _failure("Save envelope must be a JSON object.")
	var envelope: Dictionary = json.data
	var version = envelope.get("version")
	if not (version is float or version is int):
		return _failure("Save has no valid format version.")
	if version != VERSION:
		return _failure("Save format version is unsupported.", false, true)
	if not envelope.get("fingerprint") is String:
		return _failure("Save has no content fingerprint.")
	if envelope.fingerprint != fingerprint:
		return _failure("Save belongs to different workshop content.", false, true)
	if not envelope.get("payload") is Dictionary or not _json_value(envelope.payload):
		return _failure("Save payload must be a valid JSON object.")
	if not envelope.get("saved_at") is String or envelope.saved_at.is_empty():
		return _failure("Save has no valid timestamp.")
	if not envelope.get("checksum") is String:
		return _failure("Save has no integrity checksum.")
	if envelope.checksum != JSON.stringify(envelope.payload).sha256_text():
		return _failure("Save integrity check failed.")
	return {"ok": true, "payload": envelope.payload, "saved_at": envelope.saved_at, "error": "", "missing": false, "unsupported": false}

static func _failure(message: String, missing: bool = false, unsupported: bool = false) -> Dictionary:
	return {"ok": false, "error": message, "missing": missing, "unsupported": unsupported}

static func _write_bytes(path: String, bytes: PackedByteArray) -> String:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "Cannot create save file: " + error_string(FileAccess.get_open_error())
	file.store_buffer(bytes)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		DirAccess.remove_absolute(path)
		return "Cannot write save file: " + error_string(error)
	return ""

static func _json_value(value: Variant, depth: int = 0) -> bool:
	if depth > MAX_DEPTH:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY:
			for entry in value:
				if not _json_value(entry, depth + 1):
					return false
			return true
		TYPE_DICTIONARY:
			for key in value:
				if not key is String or not _json_value(value[key], depth + 1):
					return false
			return true
	return false
