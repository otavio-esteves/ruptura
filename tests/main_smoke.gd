extends SceneTree
## Integration regressions: menu transitions and repeated input-preset changes.

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main: Node = load("res://game/core/main.tscn").instantiate()
	var directory: String = "user://main_tests_%s" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(directory)
	main.mission_mode = "laboratory"
	main.store.checkpoint_path = directory + "/checkpoint.json"
	main.store.settings_path = directory + "/settings.json"
	root.add_child(main)
	await process_frame
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	main.call("_unhandled_input", escape)
	check(main.get("menu").visible and main.get("arena") == null, "Esc inicial mantém menu disponível")
	main.call("_start")
	await physics_frame
	check(main.get("player") != null and not main.get("menu").visible, "menu abre arena")
	check(not main.player.independent_aim, "new game defaults to principal-stick aim")
	main.settings.independent_aim = true
	main.call("_save_settings")
	check(main.player.independent_aim and main.store.load_settings().get("independent_aim") == true, "precision setting applies live and persists")
	main.settings.independent_aim = false
	main.call("_save_settings")
	main.call("_unhandled_input", escape)
	check(main.get("menu").visible and not main.get("player").is_physics_processing(), "pause interrompe jogador")
	main.call("_start")
	check(not main.get("menu").visible and main.get("player").is_physics_processing(), "continuar restaura jogador")
	var preset := InputEventKey.new()
	preset.physical_keycode = KEY_F2
	preset.pressed = true
	for index: int in range(6):
		main.call("_unhandled_input", preset)
	check(InputMap.action_get_events("jump").size() == 2, "troca de preset não duplica salto")
	check(InputMap.action_get_events("move_left").size() == 3, "troca de preset não duplica eixo")
	main.call("_open_options")
	main.call("_begin_binding", "jump", main.binding_buttons.jump)
	var remap := InputEventKey.new()
	remap.physical_keycode = KEY_F
	remap.pressed = true
	main.call("_input", remap)
	main.call("_close_options")
	check(main.settings.bindings.get("jump", 0) == KEY_F, "remapeamento persiste sem consultar ação vazia")
	main.call("_begin_binding", "sprint", main.binding_buttons.sprint)
	main.call("_input", remap)
	check(not main.settings.bindings.has("sprint"), "remapeamento rejeita conflito de teclas")
	main.call("_cancel_binding")
	main.call("_notification", MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(main.get("menu").visible and not main.get("player").is_physics_processing(), "perda de foco pausa")
	print("MAIN_SMOKE failures=", failures)
	for file: String in ["settings.json", "settings.json.bak", "settings.json.tmp", "checkpoint.json", "checkpoint.json.bak", "checkpoint.json.tmp"]:
		DirAccess.remove_absolute(directory + "/" + file)
	DirAccess.remove_absolute(directory)
	quit(0 if failures == 0 else 1)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS ", description)
	else:
		failures += 1
		push_error(description)
