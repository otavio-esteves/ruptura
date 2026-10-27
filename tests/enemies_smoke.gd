extends SceneTree
## Dano, morte única e tiro condicionado à cobertura. Executar após importação central.

class TestTarget extends CharacterBody2D:
	var is_dead: bool = false
	var damage_received: float = 0.0

	func receive_damage(amount: float, _impulse: Vector2, _source: Node = null) -> bool:
		if is_dead:
			return false
		damage_received += amount
		return true

var _failures: int = 0
var _deaths: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var world: Node2D = Node2D.new()
	root.add_child(world)
	_make_block(world, Vector2(250.0, 110.0), Vector2(600.0, 20.0))
	var victim: TestTarget = TestTarget.new()
	victim.position = Vector2(260.0, 100.0)
	victim.collision_layer = 2
	victim.collision_mask = 0
	var victim_shape: CollisionShape2D = CollisionShape2D.new()
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(12.0, 24.0)
	victim_shape.shape = rectangle
	victim_shape.position.y = -12.0
	victim.add_child(victim_shape)
	world.add_child(victim)
	var scene: PackedScene = load("res://game/actor/enemies/enemy.tscn") as PackedScene
	var enemy: CharacterBody2D = scene.instantiate() as CharacterBody2D
	enemy.position = Vector2(100.0, 100.0)
	enemy.call("configure", "recruit", victim)
	world.add_child(enemy)
	enemy.connect("died", _on_died)
	await _frames(10)
	_check(victim.damage_received == 0.0, "recruit warns before firing")
	var cover: StaticBody2D = _make_block(world, Vector2(180.0, 60.0), Vector2(20.0, 100.0))
	await _frames(90)
	_check(victim.damage_received == 0.0, "new cover cancels prepared attack and blocks shots")
	cover.queue_free()
	await _frames(130)
	_check(victim.damage_received > 0.0, "recruit resumes attacks after cover is removed")
	victim.is_dead = true
	var previous_damage: float = victim.damage_received
	await _frames(100)
	_check(victim.damage_received == previous_damage, "dead target receives no further attacks")
	_check(bool(enemy.call("receive_damage", 10.0, Vector2(140.0, -40.0))), "enemy accepts damage and impulse")
	await _frames(15)
	_check(int(enemy.get("state")) != 3, "stagger recovers without a stuck attack state")
	_check(bool(enemy.call("receive_damage", 100.0, Vector2.ZERO)), "lethal hit accepted")
	_check(bool(enemy.get("is_dead")) and _deaths == 1, "death signal emitted once")
	_check(not bool(enemy.call("receive_damage", 100.0, Vector2.ZERO)) and _deaths == 1, "dead enemy rejects repeated damage")
	await _frames(40)
	_check(not is_instance_valid(enemy), "dead enemy is removed after bounded feedback")
	var scout: CharacterBody2D = scene.instantiate() as CharacterBody2D
	scout.call("configure", "scout", victim)
	world.add_child(scout)
	scout.set_physics_process(false)
	_check(float(scout.get("health").get("max_health")) == 40.0, "scout has separate health configuration")
	victim.is_dead = false
	scout.position = Vector2(100.0, 100.0)
	victim.position = Vector2(126.0, 100.0)
	await _frames(2)
	scout.call("_start_attack")
	# Ainda dentro dos38px e no semiplano frontal, porém fora do arco anunciado.
	victim.position = Vector2(110.0, 76.0)
	await _frames(2)
	previous_damage = victim.damage_received
	scout.call("_execute_attack")
	_check(victim.damage_received == previous_damage, "moving outside scout's locked warning cone avoids melee damage")
	victim.position = Vector2(126.0, 100.0)
	await _frames(2)
	scout.call("_start_attack")
	scout.call("_execute_attack")
	_check(victim.damage_received == previous_damage + 18.0, "scout still hits target inside warning cone")
	scout.call("_execute_attack")
	_check(victim.damage_received == previous_damage + 18.0, "scout warning cone resolves only one damage packet")
	print("ENEMIES_SMOKE failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _on_died(_enemy: Node) -> void:
	_deaths += 1


func _make_block(parent: Node2D, center: Vector2, size: Vector2) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var collider: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
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
