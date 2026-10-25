extends SceneTree
## Fixtures isoladas; nunca acessa cinzas.json/checkpoint.json reais.

const STORE = preload("res://game/progression/local_store.gd")
var _store: RefCounted
var _directory: String
var _mission: String
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_directory = "user://mission_tests_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	_mission = _directory + "/cinzas.json"
	if DirAccess.make_dir_recursive_absolute(_directory) != OK:
		push_error("Não foi possível criar diretório isolado de teste da missão.")
		quit(1)
		return
	_store = STORE.new()
	_store.set("mission_path", _mission)
	_store.set("checkpoint_path", _directory + "/checkpoint.json")
	_store.set("settings_path", _directory + "/settings.json")
	if _store.get("mission_path") != _mission or _store.get("checkpoint_path") != _directory + "/checkpoint.json" or _store.get("settings_path") != _directory + "/settings.json":
		push_error("Injeção de caminhos não disponível; teste abortado antes de acessar saves.")
		_cleanup()
		quit(1)
		return
	_test_stage_roundtrip()
	_test_recovery()
	_test_validation()
	_test_io_failure_preserves_previous()
	_cleanup()
	print("MISSION_SAVE_SMOKE failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _state(stage: int = 0) -> Dictionary:
	return {"stage": stage, "evidence": stage == 6, "completed": stage == 6, "boss_defeated": stage >= 5, "shotgun_unlocked": stage >= 2, "secrets": [], "deaths": 0}


func _test_stage_roundtrip() -> void:
	_check((_store.call("load_mission") as Dictionary).is_empty(), "new mission has no fabricated checkpoint")
	_check(bool(_store.call("save_checkpoint", 1, false, false)), "legacy laboratory checkpoint saved independently")
	_check(bool(_store.call("save_settings", {"volume": 0.4})), "settings saved independently")
	var checkpoint_before: String = _read(_directory + "/checkpoint.json")
	var settings_before: String = _read(_directory + "/settings.json")
	for stage: int in range(7):
		var state: Dictionary = _state(stage)
		state["deaths"] = stage * 3
		state["secrets"] = ["ruins_cache", "yard_manifest"]
		var before: Dictionary = state.duplicate(true)
		_check(bool(_store.call("save_mission", state)), "mission stage %s saved" % stage)
		_check(state == before and not state.has("schema_version"), "mission save does not mutate caller or nested arrays")
		var loaded: Dictionary = _store.call("load_mission")
		_check(int(loaded.get("stage", -1)) == stage and int(loaded.get("deaths", -1)) == stage * 3, "mission stage and deaths roundtrip")
		_check(loaded.get("secrets") == ["ruins_cache", "yard_manifest"], "secret IDs roundtrip")
	_check(_read(_directory + "/checkpoint.json") == checkpoint_before and _read(_directory + "/settings.json") == settings_before, "mission writes preserve laboratory checkpoint and settings")
	var early_shotgun: Dictionary = _state(0)
	early_shotgun["shotgun_unlocked"] = true
	_check(bool(_store.call("save_mission", early_shotgun)), "early optional shotgun is valid")
	var after_boss: Dictionary = _state(5)
	after_boss["evidence"] = true
	_check(bool(_store.call("save_mission", after_boss)), "post-boss evidence may precede transmission")


func _test_recovery() -> void:
	_check(bool(_store.call("save_mission", _state(1))), "recovery baseline saved")
	_check(bool(_store.call("save_mission", _state(4))), "newer mission checkpoint saved")
	_write(_mission, "{principal corrompido")
	var loaded: Dictionary = _store.call("load_mission")
	_check(int(loaded.get("stage", -1)) == 1, "corrupt mission principal falls back to last valid backup")
	_check(not str(_store.get("last_error")).is_empty(), "backup recovery reports diagnostic")
	_check(_read(_mission) == "{principal corrompido", "backup recovery preserves corrupt principal for review")
	_check(bool(_store.call("save_mission", _state(3))), "valid mission can replace corrupt principal")
	var parser := JSON.new()
	var parsed: Error = parser.parse(_read(_mission + ".bak"))
	_check(parsed == OK and parser.data is Dictionary and int(parser.data.get("stage", -1)) == 1, "corrupt principal never replaces known good mission backup")
	_write(_mission, "principal sem JSON")
	_write(_mission + ".bak", "backup sem JSON")
	loaded = _store.call("load_mission")
	_check(loaded.is_empty() and not str(_store.get("last_error")).is_empty(), "both corrupt mission files return recoverable error")
	_check(_read(_mission) == "principal sem JSON" and _read(_mission + ".bak") == "backup sem JSON", "both corrupt mission files preserved byte-for-byte")
	_remove(_mission + ".bak")
	_write(_mission, JSON.stringify(_state(2)))
	_check((_store.call("load_mission") as Dictionary).is_empty(), "mission loaded from disk requires explicit schema")


func _test_validation() -> void:
	_remove(_mission + ".bak")
	var good: Dictionary = _state(2)
	good["schema_version"] = 1
	_write(_mission, JSON.stringify(good))
	var valid_bytes: String = _read(_mission)
	var invalid_states: Array[Dictionary] = [
		{"schema_version": 2}, {"schema_version": 1.5}, {"schema_version": "1"}, {"schema_version": true},
		{"stage": -1}, {"stage": 7}, {"stage": 2.5}, {"stage": "2"}, {"stage": true},
		{"deaths": -1}, {"deaths": 100000}, {"deaths": 1.5}, {"deaths": true}, {"deaths": "3"},
		{"evidence": true}, {"evidence": 1}, {"completed": true}, {"completed": "false"},
		{"boss_defeated": true}, {"boss_defeated": 0}, {"shotgun_unlocked": false}, {"shotgun_unlocked": 1},
		{"secrets": ["unknown"]}, {"secrets": ["ruins_cache", "ruins_cache"]},
		{"secrets": ["ruins_cache", "yard_manifest", "unknown"]}, {"secrets": [1]}, {"secrets": {}}, {"secrets": null},
		{"stage": 4, "boss_defeated": true}, {"stage": 5, "boss_defeated": false},
		{"stage": 6, "boss_defeated": true, "completed": false, "evidence": true},
		{"stage": 6, "boss_defeated": true, "completed": true, "evidence": false}
	]
	for invalid: Dictionary in invalid_states:
		var candidate: Dictionary = good.duplicate(true)
		candidate.merge(invalid, true)
		_check(not bool(_store.call("save_mission", candidate)), "reject invalid mission write %s" % JSON.stringify(invalid))
		_check(_read(_mission) == valid_bytes, "rejected mission write preserves existing bytes")
		_write(_mission, JSON.stringify(candidate))
		_check((_store.call("load_mission") as Dictionary).is_empty(), "reject invalid mission fixture on load")
		_write(_mission, valid_bytes)
	for missing: String in ["stage", "evidence", "completed", "boss_defeated", "shotgun_unlocked", "secrets", "deaths"]:
		var candidate: Dictionary = good.duplicate(true)
		candidate.erase(missing)
		_check(not bool(_store.call("save_mission", candidate)), "reject mission missing required %s" % missing)
	var boundary: Dictionary = _state(6)
	boundary["deaths"] = 99999
	_check(bool(_store.call("save_mission", boundary)), "maximum supported deaths accepted")
	_remove(_mission + ".bak")
	for malformed: String in ["null", "[]", "7", "x".repeat(65537)]:
		_write(_mission, malformed)
		_check((_store.call("load_mission") as Dictionary).is_empty(), "reject malformed/oversized mission fixture")


func _test_io_failure_preserves_previous() -> void:
	var fixture: Dictionary = _state(2)
	fixture["schema_version"] = 1
	_write(_mission, JSON.stringify(fixture))
	var before: String = _read(_mission)
	# Force temp-file open failure locally without depending on host permissions.
	_remove(_mission + ".tmp")
	_check(DirAccess.make_dir_absolute(_mission + ".tmp") == OK, "I/O failure fixture created")
	_check(not bool(_store.call("save_mission", _state(3))), "mission save reports temporary-path I/O failure")
	_check(_read(_mission) == before, "failed mission write preserves previous checkpoint")
	DirAccess.remove_absolute(_mission + ".tmp")


func _write(path: String, contents: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_check(false, "fixture file writable")
		return
	file.store_string(contents)
	file.close()


func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var contents: String = file.get_as_text()
	file.close()
	return contents


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _cleanup() -> void:
	for filename: String in ["cinzas.json", "checkpoint.json", "settings.json"]:
		for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
			_remove(_directory + "/" + filename + suffix)
	DirAccess.remove_absolute(_directory)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
