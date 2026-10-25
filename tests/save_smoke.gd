extends SceneTree
## Isola toda escrita em diretório exclusivo; nunca toca os saves reais.

const STORE = preload("res://game/progression/local_store.gd")
var _failures: int = 0
var _store: RefCounted
var _directory: String
var _checkpoint: String
var _settings: String


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_directory = "user://tests_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	_checkpoint = _directory + "/checkpoint.json"
	_settings = _directory + "/settings.json"
	if DirAccess.make_dir_recursive_absolute(_directory) != OK:
		push_error("Não foi possível criar diretório exclusivo do teste.")
		quit(1)
		return
	_store = STORE.new()
	_store.set("checkpoint_path", _checkpoint)
	_store.set("settings_path", _settings)
	# Falhar antes de qualquer save se a API de injeção não estiver integrada.
	if _store.get("checkpoint_path") != _checkpoint or _store.get("settings_path") != _settings:
		push_error("Store não oferece caminhos injetáveis; teste cancelado para preservar save real.")
		_cleanup()
		quit(1)
		return
	_test_roundtrip_and_backup()
	_test_corruption_preserved()
	_test_checkpoint_validation()
	_test_settings_types()
	_cleanup()
	print("SAVE_SMOKE failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _test_roundtrip_and_backup() -> void:
	_check((_store.call("load_checkpoint") as Dictionary).is_empty(), "fresh profile has no checkpoint")
	_check(bool(_store.call("save_checkpoint", 1, false, false)), "first checkpoint saved")
	var loaded: Dictionary = _store.call("load_checkpoint")
	_check(int(loaded.get("stage", -1)) == 1 and loaded.get("evidence") == false and loaded.get("completed") == false, "checkpoint roundtrip retains state")
	_check(bool(_store.call("save_checkpoint", 3, true, true)), "completed checkpoint with evidence saved")
	loaded = _store.call("load_checkpoint")
	_check(int(loaded.get("stage", -1)) == 3 and loaded.get("completed") == true, "completed state roundtrip")
	_check(FileAccess.file_exists(_checkpoint + ".bak"), "previous valid checkpoint preserved as backup")
	_write_text(_checkpoint, "{corrupted principal")
	loaded = _store.call("load_checkpoint")
	_check(int(loaded.get("stage", -1)) == 1, "corrupt principal recovers prior valid backup")
	_check(not str(_store.get("last_error")).is_empty(), "backup recovery produces visible diagnostic")
	_check(_read_text(_checkpoint) == "{corrupted principal", "recovery does not silently overwrite corrupt principal")
	_check(bool(_store.call("save_checkpoint", 2, true, false)), "new save can replace corrupt principal")
	var backup: Variant = JSON.parse_string(_read_text(_checkpoint + ".bak"))
	_check(backup is Dictionary and int(backup.get("stage", -1)) == 1, "new save never promotes corrupt principal over valid backup")


func _test_corruption_preserved() -> void:
	_write_text(_checkpoint, "principal original corrompido")
	_write_text(_checkpoint + ".bak", "backup original corrompido")
	var loaded: Dictionary = _store.call("load_checkpoint")
	_check(loaded.is_empty(), "both corrupt files offer no fake progress")
	_check(not str(_store.get("last_error")).is_empty(), "both corrupt files report recoverable error")
	_check(_read_text(_checkpoint) == "principal original corrompido" and _read_text(_checkpoint + ".bak") == "backup original corrompido", "corrupt files remain byte-for-byte preserved")


func _test_checkpoint_validation() -> void:
	_remove_file(_checkpoint + ".bak")
	var valid := {"schema_version": 1, "stage": 2, "evidence": false, "completed": false}
	for invalid: Dictionary in [
		{"stage": -1}, {"stage": 4}, {"stage": 1.5}, {"stage": "2"}, {"stage": true},
		{"schema_version": 2}, {"schema_version": 1.5}, {"schema_version": "1"}, {"schema_version": true},
		{"evidence": 1}, {"completed": "false"}, {"completed": true},
		{"stage": 3, "completed": true, "evidence": false}
	]:
		var fixture: Dictionary = valid.duplicate(true)
		fixture.merge(invalid, true)
		_write_text(_checkpoint, JSON.stringify(fixture))
		var loaded: Dictionary = _store.call("load_checkpoint")
		_check(loaded.is_empty(), "reject malformed checkpoint %s" % JSON.stringify(invalid))
	for missing: String in ["schema_version", "stage", "evidence", "completed"]:
		var fixture: Dictionary = valid.duplicate(true)
		fixture.erase(missing)
		_write_text(_checkpoint, JSON.stringify(fixture))
		_check((_store.call("load_checkpoint") as Dictionary).is_empty(), "reject checkpoint missing %s" % missing)
	_write_text(_checkpoint, JSON.stringify(valid))
	var preserved: String = _read_text(_checkpoint)
	_check(not bool(_store.call("save_checkpoint", -1, false, false)), "save refuses negative stage")
	_check(not bool(_store.call("save_checkpoint", 4, false, false)), "save refuses unknown stage")
	_check(not bool(_store.call("save_checkpoint", 2, true, true)), "save refuses early completion")
	_check(not bool(_store.call("save_checkpoint", 3, false, true)), "save refuses completion without evidence")
	_check(_read_text(_checkpoint) == preserved, "rejected save leaves prior checkpoint unchanged")
	_write_text(_checkpoint, "[]")
	_check((_store.call("load_checkpoint") as Dictionary).is_empty(), "reject non-object checkpoint")
	_write_text(_checkpoint, "x".repeat(65537))
	_check((_store.call("load_checkpoint") as Dictionary).is_empty(), "reject oversized checkpoint")


func _test_settings_types() -> void:
	var settings := {"assisted": true, "alternate_jump": false, "volume": 0.3, "bindings": {"jump": 32, "reload": 82}}
	_check(bool(_store.call("save_settings", settings)), "settings saved")
	_check(not settings.has("schema_version"), "save settings does not mutate caller dictionary")
	var loaded: Dictionary = _store.call("load_settings")
	_check(loaded.get("assisted") == true and loaded.get("alternate_jump") == false, "settings booleans roundtrip")
	_check(is_equal_approx(float(loaded.get("volume", -1.0)), 0.3), "settings volume roundtrip")
	_check(int(loaded.get("bindings", {}).get("jump", -1)) == 32, "settings key binding roundtrip")
	_check(loaded.get("reduced_effects") == false and loaded.get("aim_assist") == false and loaded.get("screen_shake") == false, "legacy settings keep accessibility flags opt-in")
	_check(is_equal_approx(float(loaded.get("aim_deadzone", -1.0)), 0.2), "legacy settings use default aim deadzone")
	var expanded := {"reduced_effects": true, "aim_assist": true, "screen_shake": true, "aim_deadzone": 0.27}
	_check(bool(_store.call("save_settings", expanded)), "expanded accessibility settings saved")
	_check(not expanded.has("schema_version"), "expanded settings caller dictionary unchanged")
	loaded = _store.call("load_settings")
	_check(loaded.get("reduced_effects") == true and loaded.get("aim_assist") == true and loaded.get("screen_shake") == true, "accessibility flags roundtrip")
	_check(is_equal_approx(float(loaded.get("aim_deadzone", -1.0)), 0.27), "configured aim deadzone roundtrip")
	for deadzone: Variant in [-2.0, 3.0, "0.25", true, null]:
		_write_text(_settings, JSON.stringify({"schema_version": 1, "aim_deadzone": deadzone, "reduced_effects": 1, "aim_assist": "true", "screen_shake": []}))
		loaded = _store.call("load_settings")
		var expected: float = clampf(float(deadzone), 0.1, 0.35) if deadzone is float else 0.2
		_check(is_equal_approx(float(loaded.get("aim_deadzone", -1.0)), expected), "aim deadzone clamps numeric values and defaults invalid types")
		_check(loaded.get("reduced_effects") == false and loaded.get("aim_assist") == false and loaded.get("screen_shake") == false, "accessibility flags reject malformed types")
	_write_text(_settings, JSON.stringify({"schema_version": 1, "assisted": "true", "alternate_jump": 1, "volume": "loud", "bindings": {"jump": "32", "reload": 82.5, "move_left": -1, "move_right": 50000000, "dodge": 32, "unknown_action": 65}}))
	loaded = _store.call("load_settings")
	_check(loaded.get("assisted") == false and loaded.get("alternate_jump") == false, "malformed setting flags use false without coercion")
	_check(is_equal_approx(float(loaded.get("volume", -1.0)), 0.55), "invalid volume falls back to default")
	var bindings: Dictionary = loaded.get("bindings", {})
	_check(bindings.size() == 1 and int(bindings.get("dodge", -1)) == 32, "bindings reject strings, fractions, bounds and unknown actions")
	for volume: float in [-2.0, 3.0]:
		_write_text(_settings, JSON.stringify({"schema_version": 1, "volume": volume, "bindings": []}))
		loaded = _store.call("load_settings")
		_check(is_equal_approx(float(loaded.get("volume", -1.0)), clampf(volume, 0.0, 1.0)), "volume clamps to supported range")
		_check((loaded.get("bindings", {}) as Dictionary).is_empty(), "invalid bindings container becomes empty")
	for schema: Variant in [2, 1.5, "1", true]:
		_write_text(_settings, JSON.stringify({"schema_version": schema}))
		_check((_store.call("load_settings") as Dictionary).is_empty(), "settings reject schema %s" % str(schema))
	_write_text(_settings, "not JSON")
	_check((_store.call("load_settings") as Dictionary).is_empty(), "corrupt settings return defaults without crashing")


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "fixture file writable")
		return
	file.store_string(text)
	file.close()


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _cleanup() -> void:
	for filename: String in ["checkpoint.json", "checkpoint.json.bak", "checkpoint.json.tmp", "checkpoint.json.bak.tmp", "settings.json", "settings.json.bak", "settings.json.tmp", "settings.json.bak.tmp"]:
		_remove_file(_directory + "/" + filename)
	DirAccess.remove_absolute(_directory)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
