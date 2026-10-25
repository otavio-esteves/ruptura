extends SceneTree
## Regressões de contrato e contrajogo da Chacal, sem aferir diversão.

class Victim extends CharacterBody2D:
	var is_dead: bool = false
	var hits: int = 0
	var damage: float = 0.0
	var dodging: bool = false

	func receive_damage(amount: float, _impulse: Vector2, _source: Node = null) -> bool:
		if dodging:
			return false
		hits += 1
		damage += amount
		return true

const BossScript = preload("res://game/bosses/chacal.gd")
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var floor_body: StaticBody2D = _block(Vector2(800, 630), Vector2(1600, 20), 1)
	root.add_child(floor_body)
	var victim: Victim = Victim.new()
	victim.position = Vector2(300, 620)
	victim.collision_layer = 2
	victim.collision_mask = 0
	_add_shape(victim, Vector2(12, 24), Vector2(0, -12))
	root.add_child(victim)
	var boss: CharacterBody2D = load("res://game/bosses/chacal.tscn").instantiate() as CharacterBody2D
	boss.position = Vector2(600, 620)
	boss.call("configure", victim, Rect2(0, 0, 1600, 720), false)
	root.add_child(boss)
	boss.set_physics_process(false)
	await _frames(2)
	_check(boss.is_in_group("bosses") and boss.is_in_group("damageable"), "boss registers targeting groups")
	var health: Node = boss.get("health")
	_check(float(health.get("current_health")) == 420.0, "boss starts with authored health")
	boss.set("state", BossScript.State.RECOVERY)
	boss.call("receive_damage", 10.0, Vector2.ZERO)
	_check(float(health.get("current_health")) == 406.0, "recovery increases received damage by 1.4")
	boss.set("state", BossScript.State.APPROACH)
	boss.call("receive_damage", 200.0, Vector2.ZERO)
	_check(int(boss.get("phase")) == 2 and int(boss.get("state")) == BossScript.State.PHASE_CHANGE, "half health triggers safe second phase")
	var hits_before: int = victim.hits
	boss.call("_physics_process", 0.4)
	_check(victim.hits == hits_before and int(boss.get("state")) == BossScript.State.PHASE_CHANGE, "phase transition cannot attack early")
	boss.call("_physics_process", 0.5)
	boss.call("receive_damage", 1.0, Vector2(250, 0))
	_check(int(boss.get("state")) == BossScript.State.STUNNED, "explosion breaks posture")
	boss.call("_physics_process", 0.4)
	var stun_remaining: float = float(boss.get("_timer"))
	boss.call("receive_damage", 1.0, Vector2(250, 0))
	_check(float(boss.get("_timer")) == stun_remaining, "repeated blast cannot extend stun during cooldown")
	boss.call("_physics_process", 0.6)
	boss.call("receive_damage", 1.0, Vector2(210, -65), victim)
	_check(int(boss.get("state")) != BossScript.State.STUNNED, "player melee cannot repeatedly stun boss")
	boss.position = Vector2(600, 620)
	victim.position = Vector2(300, 620)
	await _frames(2)
	boss.call("_start_pattern", BossScript.Pattern.BURST)
	boss.call("_fire_bullet")
	boss.call("_fire_bullet")
	boss.call("_fire_bullet")
	_check(victim.hits == hits_before + 1, "burst deals damage once despite three bullets")
	boss.call("_start_pattern", BossScript.Pattern.BURST)
	victim.position.y = 520.0
	await _frames(2)
	boss.call("_fire_bullet")
	_check(victim.hits == hits_before + 1, "moving away from locked burst aim avoids damage")
	victim.position.y = 620.0
	var cover: StaticBody2D = _block(Vector2(450, 580), Vector2(20, 80), 8)
	root.add_child(cover)
	await _frames(2)
	boss.call("_start_pattern", BossScript.Pattern.BURST)
	boss.call("_fire_bullet")
	_check(victim.hits == hits_before + 1, "cover blocks boss pistol")
	cover.queue_free()
	await _frames(2)
	victim.position = Vector2(700, 620)
	boss.call("_start_pattern", BossScript.Pattern.SLAM)
	boss.call("_impact_slam")
	boss.call("_impact_slam")
	_check(victim.hits == hits_before + 2, "slam damages once per pattern")
	victim.position.y = 570.0
	boss.call("_start_pattern", BossScript.Pattern.SLAM)
	boss.call("_impact_slam")
	_check(victim.hits == hits_before + 2, "jumping or upper platform avoids ground shock")
	victim.position = Vector2(600, 620)
	victim.dodging = true
	boss.call("_start_pattern", BossScript.Pattern.DASH)
	boss.call("_check_dash_contact", Vector2(580, 620), Vector2(620, 620))
	victim.dodging = false
	boss.call("_check_dash_contact", Vector2(580, 620), Vector2(620, 620))
	_check(victim.hits == hits_before + 2, "dodged contact cannot hit again later in same dash")
	victim.position = Vector2(300, 620)
	var crate: StaticBody2D = load("res://game/world/interactables/destructible.tscn").instantiate() as StaticBody2D
	crate.call("configure", "crate")
	crate.position = Vector2(550, 620)
	root.add_child(crate)
	await _frames(2)
	boss.call("_start_pattern", BossScript.Pattern.DASH)
	boss.call("_begin_active")
	boss.set_physics_process(true)
	await _frames(8)
	boss.set_physics_process(false)
	_check(float(crate.get("health")) == 10.0 and int(boss.get("state")) == BossScript.State.RECOVERY, "blocked dash damages crate once and recovers")
	crate.queue_free()
	await _frames(2)
	boss.position = Vector2(600, 620)
	victim.position = Vector2(650, 552)
	var platform: StaticBody2D = _block(Vector2(600, 558), Vector2(180, 12), 16)
	(platform.get_child(0) as CollisionShape2D).one_way_collision = true
	root.add_child(platform)
	await _frames(2)
	boss.call("_start_pattern", BossScript.Pattern.SLAM)
	boss.call("_begin_active")
	boss.set_physics_process(true)
	await _frames(50)
	boss.set_physics_process(false)
	var impact_center: Vector2 = boss.get("_slam_center")
	_check(absf(impact_center.y - 620.0) < 1.0 and victim.hits == hits_before + 2, "slam lands on announced floor and preserves upper platform counterplay")
	boss.set("state", BossScript.State.APPROACH)
	var previous_x: float = boss.position.x
	boss.call("_physics_process", 1.0 / 60.0)
	_check(absf(boss.position.x - previous_x) > 0.5, "boss leaves blocked angle instead of endlessly shooting platform underside")
	platform.queue_free()
	var deaths: Array[int] = [0]
	boss.connect("died", func(_enemy: Node) -> void: deaths[0] += 1)
	boss.call("receive_damage", 1000.0, Vector2.ZERO)
	_check(bool(boss.get("is_dead")) and deaths[0] == 1, "lethal damage emits death exactly once")
	boss.call("receive_damage", 1000.0, Vector2.ZERO)
	_check(deaths[0] == 1 and boss.collision_layer == 0 and not boss.is_in_group("damageable"), "dead boss stops collisions and targeting")
	boss.call("_physics_process", 0.81)
	await process_frame
	_check(not is_instance_valid(boss) or boss.is_queued_for_deletion(), "boss corpse cleans up after death window")
	print("BOSS_SMOKE failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _block(center: Vector2, size: Vector2, layer: int) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = center
	body.collision_layer = layer
	_add_shape(body, size, Vector2.ZERO)
	return body


func _add_shape(body: CollisionObject2D, size: Vector2, offset: Vector2) -> void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	var collider: CollisionShape2D = CollisionShape2D.new()
	collider.position = offset
	collider.shape = shape
	body.add_child(collider)


func _frames(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
	await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
