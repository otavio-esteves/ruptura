extends SceneTree
## Captura gráfica reproduzível do jogo real, com perfil temporário isolado.
## godot --path . --script tools/art/preview_mission.gd

class ReviewMain:
	extends "res://game/core/main.gd"
	func _write_probe() -> void:
		pass
	func _notification(_what: int) -> void:
		# A captura offline continua mesmo com outra janela em foco.
		pass

const OUTPUT: String = "res://reports/reference-review/"
var _profile: String

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("A revisão da missão requer sessão gráfica.")
		quit(1)
		return
	_profile = "user://art_review_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(_profile)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var names: Array[String] = ["archive", "operations", "boardroom"]
	for sector_index: int in range(3):
		var main := ReviewMain.new()
		main.store.settings_path = _profile + "/settings.json"
		main.store.mission_path = _profile + "/cinzas.json"
		main.store.checkpoint_path = _profile + "/checkpoint.json"
		root.add_child(main)
		main.sound_bank.volume = 0.0
		if sector_index == 0:
			await _capture("menu")
			main.call("_open_options")
			await _capture("options")
			main.call("_close_options")
		main.checkpoint = {"stage": sector_index * 2, "shotgun_unlocked": sector_index > 0}
		main.call("_start")
		main.director.set_physics_process(false)
		main.director.call("_begin_encounter")
		main.player.set_physics_process(false)
		main.player.set_process_input(false)
		main.player.position = Vector2([260, 530, 620][sector_index], 620)
		main.player.aim_direction = Vector2.RIGHT
		main.player.input_device = "gamepad"
		await _settle(main.player)
		main.camera.position_smoothing_enabled = false
		main.camera.position = Vector2(0, -100)
		main.camera.reset_smoothing()
		main.set("_transition_time", 0.0)
		var banner: Label = main.get("_transition_label")
		banner.hide()
		for enemy: Node in get_nodes_in_group("enemies"):
			enemy.set_physics_process(false)
			if sector_index == 2: enemy.position = Vector2(800, 620)
		for frame: int in range(4): await process_frame
		await RenderingServer.frame_post_draw
		var output_path: String = OUTPUT + names[sector_index] + ".png"
		var error: Error = root.get_texture().get_image().save_png(output_path)
		if error != OK:
			push_error("Falha salvando captura: %s" % error)
			_cleanup()
			quit(1)
			return
		print("MISSION_REVIEW=", ProjectSettings.globalize_path(output_path))
		if sector_index == 0:
			var original_position: Vector2 = main.player.position
			main.player.position = Vector2(950, 348)
			await _settle(main.player)
			main.camera.reset_smoothing()
			await _capture("archive-upper-route")
			main.player.position = original_position
			await _settle(main.player)
			main.camera.reset_smoothing()
		if sector_index == 2:
			# Segunda fase e alcance anunciado no renderer real, sem resolver o ataque.
			main.director.boss.receive_damage(240.0, Vector2.ZERO, main.player)
			main.director.boss.call("_start_pattern", 0)
			main.director.boss.queue_redraw()
			main.settings.reduced_effects = true
			main.call("_apply_live_settings")
			for frame: int in range(3): await process_frame
			await RenderingServer.frame_post_draw
			var warning_path: String = OUTPUT + "boardroom-warning.png"
			if root.get_texture().get_image().save_png(warning_path) != OK:
				push_error("Falha salvando aviso da segunda fase.")
				_cleanup()
				quit(1)
				return
			print("MISSION_REVIEW=", ProjectSettings.globalize_path(warning_path))
		main.queue_free()
		await process_frame
		await process_frame
		paused = false
	_cleanup()
	quit()

func _capture(name: String) -> void:
	for frame: int in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var path: String = OUTPUT + name + ".png"
	if root.get_texture().get_image().save_png(path) != OK:
		push_error("Falha salvando captura %s" % name)
		_cleanup()
		quit(1)
		return
	print("MISSION_REVIEW=", ProjectSettings.globalize_path(path))

func _settle(actor: CharacterBody2D) -> void:
	# Establish actual floor contact before freezing an idle pose for art review.
	actor.velocity = Vector2.ZERO
	actor.set_physics_process(true)
	for frame: int in range(3):
		actor.set("_has_focus", true)
		await physics_frame
	actor.set_physics_process(false)
	actor.velocity = Vector2.ZERO
	actor.set("_land_remaining", 0.0)
	actor.queue_redraw()

func _cleanup() -> void:
	var directory := DirAccess.open(_profile)
	if directory == null: return
	for filename: String in directory.get_files():
		directory.remove(filename)
	DirAccess.remove_absolute(_profile)
