extends SceneTree
var failures: int = 0
const MOVEMENT: Array[String] = ["move_aim_left", "move_aim_right", "move_aim_up", "move_aim_down"]
const PRECISION: Array[String] = ["aim_left", "aim_right", "aim_up", "aim_down"]

func _initialize() -> void: call_deferred("run")
func run() -> void:
	load("res://game/core/input_setup.gd").install()
	for action: String in MOVEMENT + PRECISION:
		check(InputMap.has_action(action), "controller action exists: " + action)
		InputMap.action_erase_events(action)
		Input.action_release(action)
	var actor: CharacterBody2D = load("res://game/actor/player/player.tscn").instantiate()
	root.add_child(actor)
	actor.set_physics_process(false)
	actor.set_process_input(false)
	actor.input_device = "gamepad"
	check(not actor.independent_aim, "default mode follows principal movement stick")
	Input.action_press("move_aim_right", 1.0)
	actor.call("_update_aim")
	check(actor.aim_direction.is_equal_approx(Vector2.RIGHT), "principal stick points aim right")
	Input.action_release("move_aim_right")
	Input.action_press("move_aim_left", 0.8)
	Input.action_press("move_aim_up", 0.8)
	actor.call("_update_aim")
	check(actor.aim_direction.is_equal_approx(Vector2(-1, -1).normalized()), "principal stick supports diagonal aim")
	Input.action_release("move_aim_left")
	actor.call("_update_aim")
	check(actor.aim_direction.is_equal_approx(Vector2.UP), "vertical principal stick aims up without horizontal movement")
	Input.action_release("move_aim_up")
	actor.call("_update_aim")
	check(actor.aim_direction.is_equal_approx(Vector2.UP), "neutral principal stick retains last direction")
	Input.action_press("move_aim_down", 0.1)
	actor.call("_update_aim")
	check(actor.aim_direction.is_equal_approx(Vector2.UP), "principal deadzone rejects drift")
	Input.action_release("move_aim_down")
	Input.action_press("aim_left", 1.0)
	actor.call("_update_aim")
	check(actor.aim_direction.is_equal_approx(Vector2.UP), "precision stick is ignored when optional mode is disabled")
	actor.independent_aim = true
	Input.action_press("move_aim_right", 1.0)
	actor.call("_update_aim")
	check(actor.aim_direction.is_equal_approx(Vector2.LEFT), "optional right stick overrides movement direction")
	Input.action_release("aim_left")
	actor.call("_update_aim")
	check(actor.aim_direction.is_equal_approx(Vector2.LEFT), "precision mode retains aim while principal stick moves")
	actor.independent_aim = false
	actor.call("_update_aim")
	check(actor.aim_direction.is_equal_approx(Vector2.RIGHT), "switching back restores movement-facing aim")
	actor.input_device = "mouse_keyboard"
	actor.position = Vector2(100, 100)
	var expected: Vector2 = (actor.get_global_mouse_position() - (actor.global_position + Vector2(0, -18))).normalized()
	actor.call("_update_aim")
	check(actor.aim_direction.is_equal_approx(expected), "mouse remains independent in default controller mode")
	actor.independent_aim = true
	actor.call("_update_aim")
	check(actor.aim_direction.is_equal_approx(expected), "precision toggle does not alter mouse aim")
	for action: String in MOVEMENT + PRECISION: Input.action_release(action)
	actor.queue_free()
	await process_frame
	print("CONTROLLER_AIM_SMOKE failures=", failures)
	quit(0 if failures == 0 else 1)
func check(value: bool, message: String) -> void:
	if value: print("PASS ", message)
	else:
		failures += 1
		push_error(message)
