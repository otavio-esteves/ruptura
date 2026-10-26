extends RefCounted
## Versioned local checkpoints. Backups contain only previously validated data.
var checkpoint_path: String = "user://checkpoint.json"
var settings_path: String = "user://settings.json"
var mission_path: String = "user://cinzas.json"
var last_error: String = ""

func load_checkpoint() -> Dictionary:
	last_error = ""
	for path: String in [checkpoint_path, checkpoint_path + ".bak"]:
		var value: Variant = _read(path)
		if _valid_checkpoint(value):
			if path.ends_with(".bak"):
				last_error = "Checkpoint principal inválido; backup recuperado."
			return value
	if FileAccess.file_exists(checkpoint_path) or FileAccess.file_exists(checkpoint_path + ".bak"):
		last_error = "Checkpoint inválido. Arquivos preservados; inicie uma nova tentativa."
	return {}

func save_checkpoint(stage: int, evidence: bool, completed: bool) -> bool:
	if stage < 0 or stage > 3 or (completed and (stage != 3 or not evidence)):
		return false
	return _safe_write(checkpoint_path, {"schema_version": 1, "stage": stage, "evidence": evidence, "completed": completed}, "checkpoint")

func load_mission() -> Dictionary:
	last_error = ""
	for path: String in [mission_path, mission_path + ".bak"]:
		var value: Variant = _read(path)
		if _valid_mission(value):
			if path.ends_with(".bak"):
				last_error = "Missão principal inválida; backup recuperado."
			return value
	if FileAccess.file_exists(mission_path) or FileAccess.file_exists(mission_path + ".bak"):
		last_error = "Missão inválida. Arquivos preservados; inicie uma nova tentativa."
	return {}

func save_mission(value: Dictionary) -> bool:
	var copy: Dictionary = value.duplicate(true)
	if not copy.has("schema_version"):
		copy["schema_version"] = 1
	if not _valid_mission(copy):
		last_error = "Estado de missão inválido; progresso anterior preservado."
		return false
	return _safe_write(mission_path, copy, "mission")

func load_settings() -> Dictionary:
	var value: Variant = _read(settings_path)
	if not value is Dictionary or not _valid_schema(value.get("schema_version")):
		return {}
	var result: Dictionary = {}
	result["assisted"] = value.get("assisted") is bool and value.assisted
	result["alternate_jump"] = value.get("alternate_jump") is bool and value.alternate_jump
	for flag: String in ["reduced_effects", "aim_assist", "screen_shake", "independent_aim"]:
		result[flag] = value.get(flag) is bool and value[flag]
	var volume: Variant = value.get("volume", 0.55)
	result["volume"] = clampf(float(volume), 0.0, 1.0) if _finite_number(volume) else 0.55
	var deadzone: Variant = value.get("aim_deadzone", 0.2)
	result["aim_deadzone"] = clampf(float(deadzone), 0.1, 0.35) if _finite_number(deadzone) else 0.2
	var bindings: Variant = value.get("bindings", {})
	result["bindings"] = {}
	if bindings is Dictionary:
		for action: String in ["move_left", "move_right", "jump", "dodge", "reload", "interact", "sprint", "crouch"]:
			var key: Variant = bindings.get(action)
			if key is int or key is float:
				if is_finite(float(key)) and float(key) == floorf(float(key)) and float(key) > 0 and float(key) < 50000000:
					result["bindings"][action] = int(key)
	return result

func save_settings(value: Dictionary) -> bool:
	var copy: Dictionary = value.duplicate(true)
	copy["schema_version"] = 1
	return _safe_write(settings_path, copy, "settings")

func _valid_mission(value: Variant) -> bool:
	if not value is Dictionary or not _valid_schema(value.get("schema_version")):
		return false
	var stage: Variant = value.get("stage")
	if not _bounded_integer(stage, 0, 6) or not _bounded_integer(value.get("deaths"), 0, 99999):
		return false
	for flag: String in ["evidence", "completed", "boss_defeated", "shotgun_unlocked"]:
		if not value.get(flag) is bool:
			return false
	if value.boss_defeated != (stage >= 5):
		return false
	if value.completed != (stage == 6) or (value.completed and not value.evidence):
		return false
	if (value.evidence and stage < 5) or (stage >= 2 and not value.shotgun_unlocked):
		return false
	var secrets: Variant = value.get("secrets")
	if not secrets is Array or secrets.size() > 2:
		return false
	var seen: Dictionary = {}
	for secret: Variant in secrets:
		if not secret is String or secret not in ["ruins_cache", "yard_manifest"] or seen.has(secret):
			return false
		seen[secret] = true
	return true

func _finite_number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

func _bounded_integer(value: Variant, minimum: int, maximum: int) -> bool:
	return _finite_number(value) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum

func _valid_checkpoint(value: Variant) -> bool:
	if not value is Dictionary or not _valid_schema(value.get("schema_version")):
		return false
	var stage: Variant = value.get("stage")
	if not (stage is float or stage is int) or not is_finite(float(stage)) or float(stage) != floorf(float(stage)):
		return false
	if stage < 0 or stage > 3 or not value.get("evidence") is bool or not value.get("completed") is bool:
		return false
	return not value.completed or (stage == 3 and value.evidence)

func _read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 65536:
		return null
	var text: String = file.get_as_text()
	file.close()
	var parser := JSON.new()
	return parser.data if parser.parse(text) == OK else null

func _valid_payload(value: Variant, kind: String) -> bool:
	match kind:
		"checkpoint":
			return _valid_checkpoint(value)
		"mission":
			return _valid_mission(value)
		"settings":
			return value is Dictionary and _valid_schema(value.get("schema_version"))
	return false

func _safe_write(path: String, value: Dictionary, kind: String) -> bool:
	last_error = ""
	var temporary: String = path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "Não foi possível escrever no diretório do usuário."
		return false
	file.store_string(JSON.stringify(value, "\t"))
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		last_error = "Falha ao gravar arquivo temporário: %s" % write_error
		return false
	var verified: Variant = _read(temporary)
	if not _valid_payload(verified, kind):
		last_error = "Falha ao verificar arquivo temporário."
		return false
	var previous: Variant = _read(path)
	if _valid_payload(previous, kind):
		var backup_temporary: String = path + ".bak.tmp"
		var backup_error: Error = DirAccess.copy_absolute(path, backup_temporary)
		if backup_error != OK:
			last_error = "Não foi possível preservar backup."
			return false
		if not _valid_payload(_read(backup_temporary), kind):
			last_error = "Falha ao verificar backup temporário."
			return false
		if DirAccess.rename_absolute(backup_temporary, path + ".bak") != OK:
			last_error = "Não foi possível substituir backup."
			return false
	var error: Error = DirAccess.rename_absolute(temporary, path)
	if error != OK:
		last_error = "Falha ao substituir arquivo local: %s" % error
		return false
	return true

func _valid_schema(value: Variant) -> bool:
	return (value is float or value is int) and float(value) == 1.0
