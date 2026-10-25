extends RefCounted
## Versioned local checkpoints. Backups contain only previously validated data.
var checkpoint_path: String = "user://checkpoint.json"
var settings_path: String = "user://settings.json"
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
	return _safe_write(checkpoint_path, {"schema_version": 1, "stage": stage, "evidence": evidence, "completed": completed}, true)

func load_settings() -> Dictionary:
	var value: Variant = _read(settings_path)
	if not value is Dictionary or not _valid_schema(value.get("schema_version")):
		return {}
	var result: Dictionary = {}
	result["assisted"] = value.get("assisted") is bool and value.assisted
	result["alternate_jump"] = value.get("alternate_jump") is bool and value.alternate_jump
	var volume: Variant = value.get("volume", 0.55)
	result["volume"] = clampf(float(volume), 0.0, 1.0) if (volume is float or volume is int) else 0.55
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
	return _safe_write(settings_path, copy, false)

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

func _safe_write(path: String, value: Dictionary, checkpoint: bool) -> bool:
	last_error = ""
	var temporary: String = path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "Não foi possível escrever no diretório do usuário."
		return false
	file.store_string(JSON.stringify(value, "\t"))
	file.close()
	var verified: Variant = _read(temporary)
	if (checkpoint and not _valid_checkpoint(verified)) or not verified is Dictionary:
		last_error = "Falha ao verificar arquivo temporário."
		return false
	var previous: Variant = _read(path)
	if previous is Dictionary and (not checkpoint or _valid_checkpoint(previous)):
		var backup_error: Error = DirAccess.copy_absolute(path, path + ".bak")
		if backup_error != OK:
			last_error = "Não foi possível preservar backup."
			return false
	var error: Error = DirAccess.rename_absolute(temporary, path)
	if error != OK:
		last_error = "Falha ao substituir arquivo local: %s" % error
		return false
	return true

func _valid_schema(value: Variant) -> bool:
	return (value is float or value is int) and float(value) == 1.0
