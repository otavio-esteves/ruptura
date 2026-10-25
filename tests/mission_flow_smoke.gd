extends SceneTree
## Fluxo integrado real; fixture não escreve nos perfis ou probe do usuário.

class MainUnderTest:
	extends "res://game/core/main.gd"
	func _write_probe() -> void:
		pass

var _main: Node
var _directory: String
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_directory = "user://mission_flow_tests_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	if DirAccess.make_dir_recursive_absolute(_directory) != OK:
		push_error("Não foi possível criar fixture isolada de fluxo.")
		quit(1)
		return
	_main = _make_main()
	root.add_child(_main)
	await _frames(2)
	_main.call("_start")
	await _frames(3)
	_stabilize_player()
	_check(_main.mission_mode == "cinzas" and _main.arena.sector_index == 0, "fresh mission opens ruins sector")
	for stage: int in range(4):
		_check(_main.director.stage == stage, "authored mission reaches stage %d" % stage)
		if stage in [1, 3]:
			await _collect_secret_and_retry()
		_main.director._intro_remaining = 0.0
		var layout: Dictionary = _main.director.get("_layout")
		_main.player.position = Vector2(float(layout.trigger_x) + 10.0, 610.0)
		await _frames(4)
		_check(_main.director.encounter_started and _main.director.active_enemies == layout.enemies.size(), "stage %d starts authored wave" % stage)
		for enemy: Node in get_nodes_in_group("enemies"):
			if enemy.get_parent() == _main.director and not enemy.is_dead:
				enemy.receive_damage(9999.0, Vector2.ZERO, _main.player)
		await _frames(80)
		_check(_main.director.stage == stage + 1, "clearing stage %d advances exactly once" % stage)
		_check(int(_main.store.load_mission().get("stage", -1)) == stage + 1, "cleared stage persists mission checkpoint")
		if stage in [1, 3]:
			await _cross_sector_gate(stage)
	await _test_boss_retry_and_finish()
	await _test_reload_and_laboratory()
	_main.queue_free()
	await _frames(2)
	paused = false
	_cleanup()
	print("MISSION_FLOW_SMOKE failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _make_main() -> Node:
	var main: Node = MainUnderTest.new()
	main.mission_mode = "cinzas"
	main.store.mission_path = _directory + "/cinzas.json"
	main.store.settings_path = _directory + "/settings.json"
	main.store.checkpoint_path = _directory + "/checkpoint.json"
	return main


func _stabilize_player() -> void:
	# Este teste verifica progressão, não a eficácia da IA ou habilidade do jogador.
	_main.player.set_physics_process(false)
	_main.player.velocity = Vector2.ZERO
	_main.player.health.invulnerability_remaining = 1000.0


func _collect_secret_and_retry() -> void:
	var stage: int = _main.director.stage
	var layout: Dictionary = _main.director.get("_layout")
	var definition: Dictionary = layout.secrets[0]
	_main.director.set_physics_process(false)
	_main.player.position = definition.position
	await _frames(4)
	await _interact()
	_check(definition.id in _main.director.secrets, "physical document interaction collects %s" % definition.id)
	var saved: Dictionary = _main.store.load_mission()
	_check(int(saved.get("stage", -1)) == stage and definition.id in saved.get("secrets", []), "secret persists without advancing encounter")
	_main.call("_retry")
	await _frames(4)
	_stabilize_player()
	_check(_main.director.stage == stage and definition.id in _main.director.secrets, "retry retains secret at same checkpoint")
	var document_count: int = 0
	for child: Node in _main.director.get_children():
		if child.has_signal("found") and child.get("document_id") == definition.id:
			document_count += 1
	_check(document_count == 0, "collected document does not respawn for duplicate rewards")
	_main.director.set_physics_process(false)
	_main.player.position = definition.position
	var ammo_before: Dictionary = _main.player.weapon_controller.snapshot()
	await _frames(4)
	await _interact()
	_check(_main.player.weapon_controller.snapshot() == ammo_before, "interacting at collected secret grants no repeated ammunition")
	_main.player.position = (_main.director.get("_layout") as Dictionary).spawn
	_main.director.set_physics_process(true)


func _cross_sector_gate(cleared_stage: int) -> void:
	var previous_sector: int = 0 if cleared_stage == 1 else 1
	_check(_main.director.awaiting_exit and _main.arena.sector_index == previous_sector, "cleared sector waits for manual exit")
	var layout: Dictionary = _main.director.get("_layout")
	_main.player.position = Vector2(100.0, 610.0)
	await _interact()
	_check(_main.arena.sector_index == previous_sector, "interact away from gate does not cross sector")
	_main.player.position = layout.exit_position
	await _frames(2)
	await _interact()
	await _frames(4)
	_stabilize_player()
	_check(_main.arena.sector_index == previous_sector + 1, "manual exit rebuilds next authored sector")
	_check(not _main.director.awaiting_exit and _main.director.stage == cleared_stage + 1, "new sector restores saved next-stage checkpoint")
	_check(get_nodes_in_group("player").size() == 1, "sector transition leaves exactly one player")


func _start_boss() -> void:
	_main.director._intro_remaining = 0.0
	var layout: Dictionary = _main.director.get("_layout")
	_main.player.position = Vector2(float(layout.trigger_x) + 10.0, 610.0)
	await _frames(4)
	_check(is_instance_valid(_main.director.boss) and _main.director.active_enemies == 1, "boss stage spawns one Chacal")


func _test_boss_retry_and_finish() -> void:
	_check(_main.director.stage == 4 and _main.arena.sector_index == 2, "third sector begins at pre-boss checkpoint")
	await _start_boss()
	var boss: CharacterBody2D = _main.director.boss
	_check(is_equal_approx(boss.health.current_health, 420.0) and boss.phase == 1, "boss starts with authored health and first phase")
	boss.receive_damage(240.0, Vector2.ZERO, _main.player)
	_check(boss.phase == 2, "boss damage transitions into second phase")
	var crate: Node
	for child: Node in _main.director.get_children():
		if child.has_signal("destroyed") and child.get("kind") == "crate":
			crate = child
			break
	var old_crate_id: int = crate.get_instance_id()
	crate.receive_damage(999.0, Vector2.ZERO, _main.player)
	_check(crate.is_dead, "boss encounter cover can be destroyed")
	_main.player.health.invulnerability_remaining = 0.0
	_main.player.receive_damage(9999.0, Vector2.ZERO, boss)
	_check(_main.player.is_dead, "boss encounter player death enters retry")
	var dead_checkpoint: Dictionary = _main.store.load_mission()
	_check(int(dead_checkpoint.get("stage", -1)) == 4 and dead_checkpoint.get("boss_defeated") == false and int(dead_checkpoint.get("deaths", 0)) == 1, "death saves pre-boss checkpoint and death count")
	_main.call("_retry")
	await _frames(4)
	_stabilize_player()
	_check(not _main.player.is_dead and is_equal_approx(_main.player.health.current_health, 100.0), "boss retry restores player resources")
	var fresh_crate: bool = false
	for child: Node in _main.director.get_children():
		if child.has_signal("destroyed") and child.get("kind") == "crate" and child.get_instance_id() != old_crate_id:
			fresh_crate = not child.is_dead and is_equal_approx(child.health, 45.0)
			if fresh_crate: break
	_check(fresh_crate, "boss retry reconstructs fresh destructible cover")
	await _start_boss()
	boss = _main.director.boss
	_check(is_equal_approx(boss.health.current_health, 420.0) and boss.phase == 1, "boss retry discards partial boss damage and phase")
	boss.receive_damage(240.0, Vector2.ZERO, _main.player)
	boss.receive_damage(9999.0, Vector2.ZERO, _main.player)
	_check(boss.is_dead, "boss can be defeated after retry")
	await _frames(80)
	_check(_main.director.stage == 5 and _main.store.load_mission().get("boss_defeated") == true, "boss defeat advances to persisted proof objective")
	var layout: Dictionary = _main.director.get("_layout")
	_main.player.position = layout.terminal_position + Vector2(-70.0, -2.0)
	await _frames(7)
	_check(_main.director.evidence and _main.store.load_mission().get("evidence") == true, "physical proof pickup persists authenticated evidence")
	_main.player.position = layout.terminal_position
	await _frames(2)
	await _interact()
	_check(_main.director.stage == 6 and _main.director.is_complete, "transmitter interaction completes mission")
	var finished: Dictionary = _main.store.load_mission()
	_check(finished.get("completed") == true and finished.get("evidence") == true and finished.get("boss_defeated") == true, "mission completion persists all required evidence flags")
	_check(finished.get("secrets", []).size() == 2 and int(finished.get("deaths", -1)) == 1, "completion retains optional documents and retry count")


func _test_reload_and_laboratory() -> void:
	_main.queue_free()
	await _frames(3)
	paused = false
	_main = _make_main()
	root.add_child(_main)
	await _frames(2)
	_main.call("_start")
	await _frames(4)
	_stabilize_player()
	_check(_main.director.is_complete and _main.director.stage == 6 and _main.arena.sector_index == 2, "reopening reconstructs completed mission in third sector")
	_check(get_nodes_in_group("bosses").is_empty(), "completed mission reload does not respawn Chacal")
	_check(bool(_main.store.save_checkpoint(1, false, false)), "legacy laboratory checkpoint can coexist with mission")
	var completed_bytes: String = _read(_directory + "/cinzas.json")
	_main.call("_open_laboratory")
	await _frames(4)
	_stabilize_player()
	_check(_main.mission_mode == "laboratory" and _main.director.stage == 1, "laboratory opens its independent legacy checkpoint")
	_main.call("_checkpoint_reached", 2, false, false)
	_check(int(_main.store.load_checkpoint().get("stage", -1)) == 2, "laboratory retains legacy checkpoint API")
	_check(_read(_directory + "/cinzas.json") == completed_bytes, "laboratory progress never overwrites mission completion")
	_main.call("_continue_mission")
	await _frames(4)
	_stabilize_player()
	_check(_main.mission_mode == "cinzas" and _main.director.is_complete, "continue returns from laboratory to saved Cinzas without resetting")


func _interact() -> void:
	Input.action_release("interact")
	await _frames(1)
	Input.action_press("interact")
	await _frames(3)
	Input.action_release("interact")
	await _frames(1)


func _frames(count: int) -> void:
	for index: int in range(count):
		await physics_frame
	await process_frame


func _read(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return ""
	var contents: String = file.get_as_text()
	file.close()
	return contents


func _cleanup() -> void:
	for filename: String in ["cinzas.json", "checkpoint.json", "settings.json"]:
		for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
			var path: String = _directory + "/" + filename + suffix
			if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(_directory)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
