extends CharacterBody2D
## Dois oponentes com aviso, ataque único e navegação limitada por links autorados.
signal died(enemy: Node)

const HealthScript = preload("res://game/combat/health_component.gd")
enum State { APPROACH, TELEGRAPH, RECOVERY, STUNNED, DEAD }

@export_enum("recruit", "scout") var archetype: String = "recruit"
@export var navigation_links: Array[Dictionary] = []
var target: CharacterBody2D
var is_dead: bool = false
var health := HealthScript.new()
var state: State = State.APPROACH

var _assisted: bool = false
var _timer: float = 0.0
var _stun_immunity: float = 0.0
var _drop_remaining: float = 0.0
var _navigation_cooldown: float = 0.0
var _jump_goal: Vector2 = Vector2.ZERO
var _jump_active: bool = false
var _facing: float = -1.0
var _attack_direction: Vector2 = Vector2.LEFT
var _attack_origin: Vector2 = Vector2.ZERO
var _tracer_start: Vector2 = Vector2.ZERO
var _tracer_end: Vector2 = Vector2.ZERO
var _tracer_remaining: float = 0.0
var _hit_flash: float = 0.0
var _knockback: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("damageable")
	health.name = "Health"
	health.max_health = 40.0 if archetype == "scout" else 55.0
	health.depleted.connect(_die)
	add_child(health)


func configure(kind: String, victim: CharacterBody2D, assisted: bool = false) -> void:
	archetype = "scout" if kind == "scout" else "recruit"
	target = victim
	_assisted = assisted
	health.max_health = 40.0 if archetype == "scout" else 55.0
	health.reset_health()
	queue_redraw()


func _physics_process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	_stun_immunity = maxf(0.0, _stun_immunity - delta)
	_drop_remaining = maxf(0.0, _drop_remaining - delta)
	_navigation_cooldown = maxf(0.0, _navigation_cooldown - delta)
	_tracer_remaining = maxf(0.0, _tracer_remaining - delta)
	_hit_flash = maxf(0.0, _hit_flash - delta)
	set_collision_mask_value(5, _drop_remaining <= 0.0)
	if is_dead:
		if _timer <= 0.0:
			queue_free()
		queue_redraw()
		return
	if not is_on_floor():
		velocity.y = minf(velocity.y + 1050.0 * delta, 750.0)
	var desired_speed: float = 0.0
	if not _target_alive():
		state = State.APPROACH
		_jump_active = false
	elif state == State.STUNNED:
		if _timer <= 0.0:
			state = State.APPROACH
	elif state == State.TELEGRAPH:
		if not _target_visible():
			state = State.RECOVERY
			_timer = 0.35
		elif _timer <= 0.0:
			_execute_attack()
			state = State.RECOVERY
			_timer = 1.0 if archetype == "scout" else 1.1
	elif state == State.RECOVERY:
		if _timer <= 0.0:
			state = State.APPROACH
	else:
		var offset: Vector2 = target.global_position - global_position
		if absf(offset.x) > 2.0:
			_facing = signf(offset.x)
		var attack_range: float = 36.0 if archetype == "scout" else 350.0
		if is_on_floor() and not _jump_active and offset.length() <= attack_range and _target_visible():
			_start_attack()
		else:
			desired_speed = _navigate(offset)
	_knockback = move_toward(_knockback, 0.0, 650.0 * delta)
	velocity.x = move_toward(velocity.x, desired_speed + _knockback, 1100.0 * delta)
	move_and_slide()
	queue_redraw()


func _target_alive() -> bool:
	return is_instance_valid(target) and not target.is_queued_for_deletion() and not bool(target.get("is_dead"))


func _muzzle() -> Vector2:
	return global_position + Vector2(_facing * 8.0, -17.0)


func _target_center() -> Vector2:
	return target.global_position + Vector2(0.0, -12.0)


func _ray(from: Vector2, to: Vector2) -> Dictionary:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to, 27)
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query)


func _target_visible() -> bool:
	if not _target_alive():
		return false
	# Não permitir que o cano atravesse cobertura e inicie o raio do outro lado.
	var muzzle_block: Dictionary = _ray(global_position + Vector2(0.0, -17.0), _muzzle())
	if not muzzle_block.is_empty() and muzzle_block.get("collider") != target:
		return false
	var hit: Dictionary = _ray(_muzzle(), _target_center())
	return hit.is_empty() or hit.get("collider") == target


func _start_attack() -> void:
	state = State.TELEGRAPH
	_timer = 0.45 if archetype == "scout" else 0.8
	if _assisted:
		_timer *= 1.3
	_attack_origin = _muzzle()
	_attack_direction = (_target_center() - _attack_origin).normalized()
	if _attack_direction.is_zero_approx():
		_attack_direction = Vector2(_facing, 0.0)


func _execute_attack() -> void:
	if not _target_alive():
		return
	var damage: float = 12.0 if archetype == "scout" else 8.0
	if _assisted:
		damage *= 0.7
	if archetype == "scout":
		var offset: Vector2 = _target_center() - (global_position + Vector2(0.0, -12.0))
		if offset.length() <= 38.0 and offset.dot(_attack_direction) > 0.0 and _target_visible():
			target.call("receive_damage", damage, Vector2(_facing * 130.0, -60.0), self)
		_tracer_start = _muzzle()
		_tracer_end = _tracer_start + _attack_direction * 30.0
	else:
		_tracer_start = _muzzle()
		_tracer_end = _tracer_start + _attack_direction * 420.0
		var hit: Dictionary = _ray(_tracer_start, _tracer_end)
		if not hit.is_empty():
			_tracer_end = hit["position"]
			if hit.get("collider") == target:
				target.call("receive_damage", damage, _attack_direction * 70.0, self)
	_tracer_remaining = 0.10


func _navigate(offset: Vector2) -> float:
	var speed: float = 110.0 if archetype == "scout" else 80.0
	if _jump_active:
		if is_on_floor() and velocity.y >= 0.0:
			_jump_active = false
		else:
			return clampf((_jump_goal.x - global_position.x) * 5.0, -180.0, 180.0)
	if is_on_floor() and _navigation_cooldown <= 0.0:
		if offset.y > 48.0 and _on_one_way_platform():
			_drop_remaining = 0.3
			set_collision_mask_value(5, false)
			velocity.y = 60.0
			_navigation_cooldown = 0.6
		elif offset.y < -40.0:
			var link: Dictionary = _best_upward_link()
			if not link.is_empty():
				var from: Vector2 = link["from"]
				if absf(from.x - global_position.x) <= 25.0:
					_jump_goal = link["to"]
					_jump_active = true
					velocity.y = -420.0
					_navigation_cooldown = 0.4
					return clampf((_jump_goal.x - global_position.x) * 5.0, -180.0, 180.0)
				if is_on_wall():
					velocity.y = -420.0
					_navigation_cooldown = 0.7
				return signf(from.x - global_position.x) * speed
	if absf(offset.x) < 12.0:
		return 0.0
	# Obstáculos baixos compartilham o salto simples, sem navmesh ou busca global.
	if is_on_floor() and is_on_wall() and _navigation_cooldown <= 0.0:
		velocity.y = -420.0
		_navigation_cooldown = 0.7
	return signf(offset.x) * speed


func _best_upward_link() -> Dictionary:
	var result: Dictionary = {}
	var best_score: float = INF
	for link: Dictionary in navigation_links:
		if not link.get("from") is Vector2 or not link.get("to") is Vector2:
			continue
		var from: Vector2 = link["from"]
		var to: Vector2 = link["to"]
		if absf(from.y - global_position.y) > 20.0 or to.y >= from.y:
			continue
		if to.y < target.global_position.y - 100.0:
			continue
		var score: float = absf(from.x - global_position.x) + absf(to.x - target.global_position.x) * 0.35
		if score < best_score:
			best_score = score
			result = link
	return result


func _on_one_way_platform() -> bool:
	for index: int in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(index)
		var body: CollisionObject2D = collision.get_collider() as CollisionObject2D
		if body != null and body.get_collision_layer_value(5) and collision.get_normal().y < -0.5:
			return true
	return false


func receive_damage(amount: float, impulse: Vector2, _source: Node = null) -> bool:
	if is_dead or not health.apply_damage(amount):
		return false
	_hit_flash = 0.10
	if not is_dead:
		_knockback = clampf(impulse.x, -260.0, 260.0)
		velocity.y = minf(velocity.y, clampf(impulse.y, -240.0, 0.0))
		if impulse.length() >= 80.0 and _stun_immunity <= 0.0:
			state = State.STUNNED
			_timer = 0.16
			_stun_immunity = 0.45
	queue_redraw()
	return true


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	state = State.DEAD
	_timer = 0.55
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	remove_from_group("damageable")
	remove_from_group("enemies")
	died.emit(self)


func _draw() -> void:
	var outfit: Color = Color("ab7759") if archetype == "recruit" else Color("9684b8")
	if _hit_flash > 0.0:
		outfit = Color("f2dba1")
	if is_dead:
		draw_rect(Rect2(-11.0, -7.0, 22.0, 7.0), outfit.darkened(0.45))
		return
	draw_rect(Rect2(-7.0, -24.0, 14.0, 24.0), Color("15202a"))
	draw_rect(Rect2(-6.0, -16.0, 12.0, 12.0), outfit)
	draw_rect(Rect2(-5.0, -24.0, 10.0, 7.0), Color("b0b3a5"))
	draw_rect(Rect2(-6.0, -25.0, 12.0, 4.0), outfit.darkened(0.3))
	draw_rect(Rect2(0.0 if _facing > 0.0 else -5.0, -21.0, 5.0, 2.0), Color("e18c6a"))
	draw_rect(Rect2(-5.0, -5.0, 4.0, 5.0), Color("313c45"))
	draw_rect(Rect2(1.0, -5.0, 4.0, 5.0), Color("313c45"))
	if archetype == "scout":
		draw_line(Vector2(_facing * 7.0, -13.0), Vector2(_facing * 15.0, -20.0), Color("e0d0a4"), 3.0)
	else:
		var direction: Vector2 = _attack_direction if state == State.TELEGRAPH else Vector2(_facing, 0.0)
		draw_line(Vector2(0.0, -17.0), Vector2(0.0, -17.0) + direction * 19.0, Color("c5beb0"), 3.0)
	if health.current_health < health.max_health:
		draw_rect(Rect2(-12.0, -33.0, 24.0, 3.0), Color("16212b"))
		draw_rect(Rect2(-12.0, -33.0, 24.0 * health.current_health / health.max_health, 3.0), outfit)
	if state == State.TELEGRAPH:
		var shoulder: Vector2 = to_local(_muzzle())
		if archetype == "recruit":
			draw_line(shoulder, shoulder + _attack_direction * 420.0, Color(1.0, 0.54, 0.3, 0.6), 1.0)
		else:
			draw_arc(Vector2.ZERO + Vector2(0.0, -12.0), 28.0, _attack_direction.angle() - 0.7, _attack_direction.angle() + 0.7, 12, Color("ffc66c"), 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(-3.0, -38.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color("ffd38a"))
	if _tracer_remaining > 0.0:
		draw_line(to_local(_tracer_start), to_local(_tracer_end), Color("ffe5ad"), 2.0)
