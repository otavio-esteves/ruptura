extends SceneTree
## Executar após importação: godot --headless --path . --script tests/player_smoke.gd

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for action: String in ["move_left", "move_right", "crouch", "jump", "dodge", "sprint", "aim_left", "aim_right", "aim_up", "aim_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var world: Node2D = Node2D.new()
	root.add_child(world)
	var floor_body: StaticBody2D = _make_block(world, Vector2(200.0, 110.0), Vector2(400.0, 20.0), 1)
	var scene: PackedScene = load("res://game/actor/player/player.tscn") as PackedScene
	var player: CharacterBody2D = scene.instantiate() as CharacterBody2D
	world.add_child(player)
	player.call("reset_to", Vector2(100.0, 95.0))
	await _frames(8)
	_check(player.is_on_floor(), "player settles on static floor")
	Input.action_press("move_right")
	await _frames(10)
	Input.action_release("move_right")
	_check(player.position.x > 110.0, "movement advances right independently of aim")
	Input.action_press("jump")
	await _frames(3)
	Input.action_release("jump")
	_check(player.velocity.y < 0.0 and player.position.y < 95.0, "jump launches off floor")
	await _frames(70)
	Input.action_press("crouch")
	await _frames(3)
	_check(bool(player.get("is_crouching")), "crouch on floor")
	var ceiling: StaticBody2D = _make_block(world, Vector2(player.position.x, 78.0), Vector2(50.0, 8.0), 1)
	await _frames(2)
	Input.action_release("crouch")
	await _frames(3)
	_check(bool(player.get("is_crouching")), "standing blocked by low ceiling")
	ceiling.queue_free()
	await _frames(3)
	_check(not bool(player.get("is_crouching")), "standing resumes after ceiling removed")
	player.set("input_device", "gamepad")
	player.set("aim_direction", Vector2.UP)
	await _frames(3)
	_check((player.get("aim_direction") as Vector2).is_equal_approx(Vector2.UP), "neutral stick retains last aim")
	Input.action_press("dodge")
	await _frames(3)
	Input.action_release("dodge")
	_check(bool(player.get("is_dodging")), "dodge starts")
	await _frames(20)
	_check(not bool(player.get("is_dodging")), "dodge finishes without stuck state")
	Input.action_press("dodge")
	await _frames(2)
	Input.action_release("dodge")
	_check(not bool(player.get("is_dodging")), "cooldown blocks immediate repeat")
	player.call("reset_to", Vector2(100.0, 20.0))
	_check(player.velocity == Vector2.ZERO and not bool(player.get("is_dodging")), "reset clears motion and dodge")
	floor_body.queue_free()
	var platform: StaticBody2D = _make_block(world, Vector2(200.0, 24.0), Vector2(400.0, 8.0), 16)
	(platform.get_child(0) as CollisionShape2D).one_way_collision = true
	await _frames(8)
	_check(player.is_on_floor(), "one way platform supports player")
	Input.action_press("crouch")
	await _frames(2)
	Input.action_press("jump")
	await _frames(10)
	Input.action_release("jump")
	Input.action_release("crouch")
	_check(player.position.y > 36.0, "crouch plus jump drops through platform")
	await _frames(10)
	_check(player.get_collision_mask_value(5), "platform collision restores after drop window")
	print("PLAYER_SMOKE failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _make_block(parent: Node2D, center: Vector2, dimensions: Vector2, layer: int) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = center
	body.collision_layer = layer
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = dimensions
	var collider: CollisionShape2D = CollisionShape2D.new()
	collider.shape = shape
	body.add_child(collider)
	parent.add_child(body)
	return body


func _frames(count: int) -> void:
	for index: int in range(count):
		await physics_frame
	await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
