extends SceneTree
var failures: int = 0
class EnemyTarget extends CharacterBody2D:
	var is_dead: bool = false
	func _ready() -> void: add_to_group("enemies")

func _initialize() -> void: call_deferred("run")
func run() -> void:
	load("res://game/core/input_setup.gd").install()
	# Isolate synthetic stick actions from any real/virtual gamepad in the session.
	for action: String in ["aim_left", "aim_right", "aim_up", "aim_down"]:
		InputMap.action_erase_events(action)
		Input.action_release(action)
	var world := Node2D.new()
	root.add_child(world)
	var player: CharacterBody2D = load("res://game/actor/player/player.tscn").instantiate()
	world.add_child(player)
	player.position = Vector2(100, 100)
	player.set_physics_process(false)
	var enemy := EnemyTarget.new()
	enemy.position = Vector2(300, 110)
	world.add_child(enemy)
	await frames(2)
	var raw := Vector2.RIGHT
	var adjusted: Vector2 = player.call("_assisted_aim", raw)
	check(adjusted.y > 0.0 and absf(adjusted.angle()) < deg_to_rad(2.0), "assist nudges within a small angle")
	check(absf(adjusted.length() - 1.0) < 0.001, "assisted direction remains normalized")
	enemy.position = Vector2(300, 240)
	check((player.call("_assisted_aim", raw) as Vector2).is_equal_approx(raw), "assist ignores targets far outside firing cone")
	enemy.position = Vector2(600, 110)
	check((player.call("_assisted_aim", raw) as Vector2).is_equal_approx(raw), "assist ignores distant targets")
	enemy.position = Vector2(300, 110)
	var wall := StaticBody2D.new()
	wall.position = Vector2(200, 95)
	wall.collision_layer = 1
	var collider := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(16, 70)
	collider.shape = rectangle
	wall.add_child(collider)
	world.add_child(wall)
	await frames(2)
	check((player.call("_assisted_aim", raw) as Vector2).is_equal_approx(raw), "assist never targets through cover")
	wall.queue_free()
	await frames(2)
	player.aim_assist_enabled = false
	player.input_device = "gamepad"
	Input.action_press("aim_right", 1.0)
	player.call("_update_aim")
	check(player.aim_direction.is_equal_approx(raw), "gamepad assistance is disabled by default")
	player.aim_assist_enabled = true
	player.call("_update_aim")
	var retained: Vector2 = player.aim_direction
	check(retained.y > 0.0, "optional assistance applies only to active gamepad aim")
	Input.action_release("aim_right")
	player.call("_update_aim")
	check(player.aim_direction.is_equal_approx(retained), "neutral stick retains assisted last direction")
	player.input_device = "mouse_keyboard"
	var expected: Vector2 = (player.get_global_mouse_position() - (player.global_position + Vector2(0, -18))).normalized()
	player.call("_update_aim")
	check(player.aim_direction.is_equal_approx(expected), "mouse direction stays exact even with assistance enabled")
	world.queue_free()
	await process_frame
	print("AIM_ASSIST_SMOKE failures=", failures)
	quit(0 if failures == 0 else 1)

func frames(count: int) -> void:
	for index: int in range(count): await physics_frame
	await process_frame
func check(value: bool, message: String) -> void:
	if value: print("PASS ", message)
	else:
		failures += 1
		push_error(message)
