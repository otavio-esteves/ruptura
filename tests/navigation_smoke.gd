extends SceneTree
## Exercita deslocamento físico real em links autorados e queda de plataforma.

class NavigationTarget extends CharacterBody2D:
	var is_dead: bool = false

	func receive_damage(_amount: float, _impulse: Vector2, _source: Node = null) -> bool:
		return not is_dead

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world: Node2D = Node2D.new()
	root.add_child(world)
	var arena_scene: PackedScene = load("res://game/world/levels/prototype_arena.tscn") as PackedScene
	world.add_child(arena_scene.instantiate())
	var victim: NavigationTarget = NavigationTarget.new()
	victim.position = Vector2(350.0, 552.0)
	victim.collision_layer = 2
	victim.collision_mask = 0
	var collider: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(12.0, 24.0)
	collider.shape = shape
	collider.position.y = -12.0
	victim.add_child(collider)
	world.add_child(victim)
	var enemy_scene: PackedScene = load("res://game/actor/enemies/enemy.tscn") as PackedScene
	var scout: CharacterBody2D = enemy_scene.instantiate() as CharacterBody2D
	scout.position = Vector2(200.0, 620.0)
	scout.call("configure", "scout", victim)
	var links: Array[Dictionary] = [{"from": Vector2(230.0, 620.0), "to": Vector2(280.0, 552.0)}]
	scout.set("navigation_links", links)
	world.add_child(scout)
	var reached_platform: bool = false
	for step: int in range(300):
		await physics_frame
		await process_frame
		if scout.is_on_floor() and absf(scout.position.y - 552.0) < 3.0 and scout.position.x >= 250.0:
			reached_platform = true
			break
	_check(reached_platform, "scout physically lands on upper platform through authored link")
	if reached_platform:
		_check(scout.get_collision_mask_value(5), "platform collision remains active after landing")
		victim.position = Vector2(350.0, 620.0)
		var reached_ground: bool = false
		for step: int in range(300):
			await physics_frame
			await process_frame
			if scout.is_on_floor() and absf(scout.position.y - 620.0) < 3.0:
				reached_ground = true
				break
		_check(reached_ground, "scout drops through platform to pursue lower target")
		for step: int in range(30):
			await physics_frame
		await process_frame
		_check(scout.get_collision_mask_value(5), "platform collision restores after drop window")
	print("NAVIGATION_SMOKE failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
