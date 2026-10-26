extends SceneTree
## Pressão por cadência e posicionamento; fixtures locais sem perfil/save.

const ENEMY = preload("res://game/actor/enemies/enemy.tscn")
const BOSS = preload("res://game/bosses/chacal.tscn")
const EnemyScript = preload("res://game/actor/enemies/enemy.gd")
const BossScript = preload("res://game/bosses/chacal.gd")
var _failures: int = 0


class Victim:
	extends CharacterBody2D
	var is_dead: bool = false
	var packets: Array[float] = []
	var hit_frames: Array[int] = []
	func receive_damage(amount: float, _impulse: Vector2, _source: Node = null) -> bool:
		packets.append(amount)
		hit_frames.append(Engine.get_physics_frames())
		return true


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for kind: String in ["recruit", "scout"]:
		var normal: Dictionary = await _measure_cadence(kind, false)
		var assisted: Dictionary = await _measure_cadence(kind, true)
		var damage: float = 12.0 if kind == "recruit" else 18.0
		_check(is_equal_approx(normal.damage, damage), "%s standard attack uses increased damage" % kind)
		_check(is_equal_approx(assisted.damage, damage * 0.7), "%s assisted attack keeps damage reduction" % kind)
		_check(assisted.first_frame > normal.first_frame + 7, "%s assisted warning gives more reaction time" % kind)
		_check(assisted.gap > normal.gap + 0.10, "%s assisted cadence stays slower than standard" % kind)
		var shortest: float = 1.40 if kind == "recruit" else 1.10
		var longest: float = 1.60 if kind == "recruit" else 1.30
		_check(normal.gap >= shortest and normal.gap < longest, "%s cadence preserves full warning and recovery between hits" % kind)
	await _test_reposition(false)
	await _test_reposition(true)
	await _test_stable_range_and_ledge()
	await _test_boss_pressure(false)
	await _test_boss_pressure(true)
	print("DIFFICULTY_SMOKE failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _measure_cadence(kind: String, easier: bool) -> Dictionary:
	var world := Node2D.new()
	root.add_child(world)
	_block(world, Vector2(600, 630), Vector2(1200, 20))
	var victim: Victim = _victim(world, Vector2(600, 620))
	var enemy: CharacterBody2D = _enemy(world, kind, victim, Vector2(400 if kind == "recruit" else 574, 620), easier)
	var started: int = Engine.get_physics_frames()
	await _frames(220)
	_check(float(enemy.get("health").get("max_health")) == (55.0 if kind == "recruit" else 40.0), "%s pressure keeps original health budget" % kind)
	_check(victim.packets.size() >= 2, "%s %s produces repeated telegraphed attacks" % [kind, "assisted" if easier else "standard"])
	var result := {"damage": -1.0, "first_frame": 0, "gap": 0.0}
	if victim.packets.size() >= 2:
		result.damage = victim.packets[0]
		result.first_frame = victim.hit_frames[0] - started
		result.gap = float(victim.hit_frames[1] - victim.hit_frames[0]) / 60.0
		var before: int = victim.packets.size()
		enemy.call("_start_attack")
		enemy.call("_execute_attack")
		enemy.call("_execute_attack")
		_check(victim.packets.size() == before + 1, "%s attack resolves damage once even if called repeatedly" % kind)
	world.queue_free()
	await _frames(2)
	return result


func _test_reposition(obstructed: bool) -> void:
	var world := Node2D.new()
	root.add_child(world)
	_block(world, Vector2(600, 630), Vector2(1200, 20))
	if obstructed:
		_block(world, Vector2(360, 570), Vector2(20, 100))
	var victim: Victim = _victim(world, Vector2(480, 620))
	var enemy: CharacterBody2D = _enemy(world, "recruit", victim, Vector2(400, 620), false)
	await _wait_first_hit(victim)
	var initial_x: float = enemy.position.x
	await _frames(30)
	_check(int(enemy.get("state")) == EnemyScript.State.RECOVERY and enemy.position.x < initial_x - 10.0, "recruit repositions away from close target during recovery")
	_check(absf(enemy.position.y - 620.0) < 1.0 and not bool(enemy.get("_jump_active")), "recovery reposition stays grounded without invoking navigation jumps")
	if obstructed:
		_check(enemy.position.x >= 375.0, "real collision stops recovery reposition at wall")
	await _frames(10)
	var settled: float = enemy.position.x
	await _frames(7)
	_check(absf(enemy.position.x - settled) < 0.1 and absf(enemy.velocity.x) < 0.1, "recruit plants feet for final 0.2 seconds before next warning")
	world.queue_free()
	await _frames(2)


func _test_stable_range_and_ledge() -> void:
	var world := Node2D.new()
	root.add_child(world)
	_block(world, Vector2(600, 630), Vector2(440, 20))
	var victim: Victim = _victim(world, Vector2(600, 620))
	var enemy: CharacterBody2D = _enemy(world, "recruit", victim, Vector2(400, 620), false)
	await _wait_first_hit(victim)
	var supported_x: float = enemy.position.x
	await _frames(25)
	_check(absf(enemy.position.x - supported_x) < 0.1, "preferred 160-240 pixel range does not cause unnecessary movement")
	victim.position = Vector2(480, 620)
	enemy.set("state", EnemyScript.State.RECOVERY)
	enemy.set("_timer", 0.85)
	await _frames(35)
	_check(enemy.position.x >= 385.0 and absf(enemy.position.y - 620.0) < 1.0, "recovery probes floor and refuses to retreat blindly off ledge")
	world.queue_free()
	await _frames(2)
	world = Node2D.new()
	root.add_child(world)
	_block(world, Vector2(600, 630), Vector2(1200, 20))
	victim = _victim(world, Vector2(720, 620))
	enemy = _enemy(world, "recruit", victim, Vector2(400, 620), false)
	await _wait_first_hit(victim)
	supported_x = enemy.position.x
	await _frames(25)
	_check(enemy.position.x > supported_x + 20.0, "recruit approaches distant target during recovery instead of remaining stationary")
	world.queue_free()
	await _frames(2)


func _test_boss_pressure(easier: bool) -> void:
	var world := Node2D.new()
	root.add_child(world)
	_block(world, Vector2(800, 630), Vector2(1600, 20))
	var victim: Victim = _victim(world, Vector2(300, 620))
	var boss: CharacterBody2D = BOSS.instantiate() as CharacterBody2D
	boss.position = Vector2(600, 620)
	boss.call("configure", victim, Rect2(0, 0, 1600, 720), easier)
	world.add_child(boss)
	await _frames(3)
	boss.set_physics_process(false)
	_check(float(boss.get("health").get("current_health")) == 420.0, "boss pressure keeps 420 HP")
	for pattern: int in [BossScript.Pattern.DASH, BossScript.Pattern.BURST, BossScript.Pattern.SLAM]:
		boss.call("_start_pattern", pattern)
		var expected: float = [0.60, 0.72, 0.85][pattern] * (1.45 if easier else 1.0)
		_check(is_equal_approx(float(boss.get("_timer")), expected), "boss pattern %s retains explicit %s warning" % [pattern, "assisted" if easier else "standard"])
		var before: int = victim.packets.size()
		if pattern == BossScript.Pattern.DASH:
			boss.call("_check_dash_contact", Vector2(280, 620), Vector2(320, 620))
			boss.call("_check_dash_contact", Vector2(280, 620), Vector2(320, 620))
		elif pattern == BossScript.Pattern.BURST:
			boss.call("_fire_bullet")
			boss.call("_fire_bullet")
			boss.call("_fire_bullet")
		else:
			victim.position = Vector2(650, 620)
			await _frames(2)
			boss.call("_impact_slam")
			boss.call("_impact_slam")
		_check(victim.packets.size() == before + 1, "boss pattern %s damages once" % pattern)
		if victim.packets.size() == before + 1:
			var amount: float = [24.0, 18.0, 30.0][pattern] * (0.7 if easier else 1.0)
			_check(is_equal_approx(victim.packets[-1], amount), "boss pattern %s uses new damage with assisted reduction" % pattern)
	boss.call("_start_pattern", BossScript.Pattern.DASH)
	boss.call("_begin_active")
	boss.set("_timer", 0.0)
	boss.call("_physics_process", 1.0 / 60.0)
	_check(int(boss.get("state")) == BossScript.State.RECOVERY and is_equal_approx(float(boss.get("_timer")), 0.85), "completed dash preserves shortened vulnerable recovery")
	world.queue_free()
	await _frames(2)


func _wait_first_hit(victim: Victim) -> void:
	for _index: int in range(100):
		if not victim.packets.is_empty(): return
		await physics_frame
	await process_frame
	_check(false, "fixture reaches first telegraphed attack")


func _enemy(parent: Node, kind: String, victim: Victim, at: Vector2, easier: bool) -> CharacterBody2D:
	var enemy: CharacterBody2D = ENEMY.instantiate() as CharacterBody2D
	enemy.position = at
	enemy.call("configure", kind, victim, easier)
	parent.add_child(enemy)
	return enemy


func _victim(parent: Node, at: Vector2) -> Victim:
	var victim := Victim.new()
	victim.position = at
	victim.collision_layer = 2
	victim.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 24)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position.y = -12.0
	victim.add_child(collision)
	parent.add_child(victim)
	return victim


func _block(parent: Node, center: Vector2, dimensions: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


func _frames(count: int) -> void:
	for _index: int in range(count): await physics_frame
	await process_frame


func _check(condition: bool, message: String) -> void:
	if condition: print("PASS ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
