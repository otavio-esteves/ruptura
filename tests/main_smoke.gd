extends SceneTree
## Integration regressions: menu transitions and repeated input-preset changes.

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main: Node = load("res://game/core/main.tscn").instantiate()
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
	main.call("_notification", MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(main.get("menu").visible and not main.get("player").is_physics_processing(), "perda de foco pausa")
	print("MAIN_SMOKE failures=", failures)
	quit(0 if failures == 0 else 1)

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS ", description)
	else:
		failures += 1
		push_error(description)
