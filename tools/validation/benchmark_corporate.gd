extends SceneTree
## Exercício gráfico curto e reproduzível: Operações, três inimigos, corrida e tiros.
## Perfis isolados; imunidade na fixture mantém a carga de combate constante.

class BenchmarkMain:
	extends "res://game/core/main.gd"
	func _write_probe() -> void: pass
	func _notification(_what: int) -> void: pass

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Benchmark requer renderização gráfica.")
		quit(1)
		return
	var profile: String = "user://corporate_benchmark_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(profile)
	var main := BenchmarkMain.new()
	main.store.settings_path = profile + "/settings.json"
	main.store.mission_path = profile + "/cinzas.json"
	main.store.checkpoint_path = profile + "/checkpoint.json"
	root.add_child(main)
	main.sound_bank.volume = 0.0
	main.checkpoint = {"stage": 2, "shotgun_unlocked": true}
	main.call("_start")
	main.player.position = Vector2(530, 620)
	main.director.call("_begin_encounter")
	main.player.input_device = "gamepad"
	main.player.independent_aim = true
	main.player.set_process_input(false)
	main.settings.screen_shake = false
	main.settings.reduced_effects = false
	for action: String in ["move_left", "move_right", "aim_right", "fire", "reload"]:
		InputMap.action_erase_events(action)
	Input.action_press("aim_right")
	main.overlay.begin_capture(12.0)
	var start: int = Time.get_ticks_usec()
	while main.overlay.collecting:
		await process_frame
		var elapsed: float = float(Time.get_ticks_usec() - start) / 1000000.0
		main.player.set("_has_focus", true)
		main.player.weapon_controller.set("_has_focus", true)
		main.player.health.invulnerability_remaining = 1000.0
		for enemy: Node in get_nodes_in_group("enemies"):
			enemy.health.invulnerability_remaining = 1000.0
		var right: bool = fmod(elapsed, 4.0) < 2.0
		Input.action_press("move_right" if right else "move_left")
		Input.action_release("move_left" if right else "move_right")
		if fmod(elapsed, 5.0) < 3.0:
			Input.action_release("reload")
			Input.action_press("fire")
		else:
			Input.action_release("fire")
			Input.action_press("reload")
	DirAccess.make_dir_recursive_absolute("res://reports")
	var report_name: String = "corporate-combat-30" if Engine.max_fps == 30 else "corporate-combat"
	var csv := FileAccess.open("res://reports/" + report_name + ".csv", FileAccess.WRITE)
	if csv == null:
		push_error("Falha gravando relatório de benchmark.")
		quit(1)
		return
	csv.store_line("frame_ms")
	for sample: float in main.overlay.samples: csv.store_line("%.6f" % sample)
	csv.close()
	print("CORPORATE_BENCHMARK frames=", main.overlay.samples.size(), " enemies=", get_nodes_in_group("enemies").size(), " stage=", main.director.stage, " gpu=", RenderingServer.get_video_adapter_name())
	for action: String in ["move_left", "move_right", "aim_right", "fire", "reload"]: Input.action_release(action)
	main.queue_free()
	await process_frame
	var directory := DirAccess.open(profile)
	for filename: String in directory.get_files(): directory.remove(filename)
	DirAccess.remove_absolute(profile)
	quit()
