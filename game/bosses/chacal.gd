extends CharacterBody2D
## Três padrões compartilhados entre duas fases; sem bloqueio arbitrário de dano.
signal died(enemy: Node)
signal phase_changed(phase: int)
signal feedback(kind: String, position: Vector2)

const HealthScript = preload("res://game/combat/health_component.gd")
enum State { INTRO, APPROACH, WINDUP, DASH, BURST, LEAP, RECOVERY, PHASE_CHANGE, STUNNED, DEAD }
enum Pattern { DASH, BURST, SLAM }

var display_name: String = "MARA «CHACAL»"
var health := HealthScript.new()
var target: CharacterBody2D
var phase: int = 1
var is_dead: bool = false
var state: State = State.INTRO
var arena_bounds: Rect2 = Rect2(0, 0, 1600, 720)

var _assisted: bool = false
var _timer: float = 1.0
var _pattern: Pattern = Pattern.DASH
var _cycle: int = 0
var _facing: float = -1.0
var _locked_direction: Vector2 = Vector2.LEFT
var _attack_resolved: bool = false
var _damaged_props: Dictionary = {}
var _burst_remaining: int = 0
var _shot_timer: float = 0.0
var _stun_cooldown: float = 0.0
var _knockback: float = 0.0
var _airtime: float = 0.0
var _slam_center: Vector2 = Vector2.ZERO
var _hit_flash: float = 0.0
var _tracers: Array[Dictionary] = []
var _shock_remaining: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("damageable")
	add_to_group("bosses")
	health.name = "Health"
	health.max_health = 420.0
	health.depleted.connect(_die)
	add_child(health)


func configure(victim: CharacterBody2D, bounds: Rect2, assisted: bool = false) -> void:
	target = victim
	arena_bounds = bounds
	_assisted = assisted
	phase = 1
	is_dead = false
	state = State.INTRO
	_timer = 1.0
	_cycle = 0
	_stun_cooldown = 0.0
	_knockback = 0.0
	_attack_resolved = false
	_damaged_props.clear()
	_burst_remaining = 0
	_tracers.clear()
	_shock_remaining = 0.0
	velocity = Vector2.ZERO
	collision_layer = 4
	collision_mask = 25
	health.max_health = 420.0
	health.reset_health()
	queue_redraw()


func _physics_process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	_stun_cooldown = maxf(0.0, _stun_cooldown - delta)
	_hit_flash = maxf(0.0, _hit_flash - delta)
	_shock_remaining = maxf(0.0, _shock_remaining - delta)
	_update_tracers(delta)
	if is_dead:
		if _timer <= 0.0:
			queue_free()
		queue_redraw()
		return
	if not is_on_floor():
		velocity.y = minf(750.0, velocity.y + 1050.0 * delta)
	elif state != State.LEAP:
		# Uma interrupção no salto também espera o piso antes de reativar passarelas.
		set_collision_mask_value(5, true)
	var desired_speed: float = 0.0
	var before: Vector2 = global_position
	if not _target_alive():
		_attack_resolved = true
		_burst_remaining = 0
		state = State.APPROACH
	elif state == State.INTRO or state == State.PHASE_CHANGE or state == State.STUNNED or state == State.RECOVERY:
		if _timer <= 0.0:
			state = State.APPROACH
	elif state == State.APPROACH:
		var offset: Vector2 = target.global_position - global_position
		if absf(offset.x) > 2.0:
			_facing = signf(offset.x)
		var elevated: bool = offset.y < -48.0
		var visible: bool = _visible_from(_shoulder())
		if elevated and not visible:
			# Sair de baixo da plataforma abre um ângulo, sem navmesh nem tiro através dela.
			desired_speed = -_facing * 110.0
		elif is_on_floor() and (absf(offset.x) < 460.0 or (elevated and absf(offset.x) < 800.0 and visible)):
			var next_pattern: Pattern = Pattern.SLAM if phase == 2 and _cycle % 3 == 2 else (Pattern.DASH if _cycle % 2 == 0 else Pattern.BURST)
			if absf(offset.y) > 48.0:
				next_pattern = Pattern.BURST
			_start_pattern(next_pattern)
			_cycle += 1
		else:
			desired_speed = _facing * 95.0
		if state == State.APPROACH and is_on_wall() and absf(desired_speed) > 0.1:
			var cover: Dictionary = _ray(_shoulder(), _shoulder() + Vector2(signf(desired_speed) * 34.0, 0))
			var obstacle: CollisionObject2D = cover.get("collider") as CollisionObject2D
			if obstacle != null and obstacle.get_collision_layer_value(4) and obstacle.has_method("receive_damage"):
				_facing = signf(desired_speed)
				_start_pattern(Pattern.DASH)
				_cycle += 1
				desired_speed = 0.0
	elif state == State.WINDUP:
		if _timer <= 0.0:
			_begin_active()
	elif state == State.DASH:
		desired_speed = _locked_direction.x * (470.0 if phase == 2 else 420.0)
		if _timer <= 0.0:
			_recover(1.0)
			desired_speed = 0.0
	elif state == State.BURST:
		_shot_timer -= delta
		if _burst_remaining > 0 and _shot_timer <= 0.0:
			_fire_bullet()
			_burst_remaining -= 1
			_shot_timer = 0.16
		elif _burst_remaining == 0 and _shot_timer <= 0.0:
			_recover(1.0)
	elif state == State.LEAP:
		_airtime += delta
		if is_on_floor() and _airtime > 0.10:
			_impact_slam()
			_recover(1.25)
	_knockback = move_toward(_knockback, 0.0, 650.0 * delta)
	velocity.x = desired_speed + _knockback
	move_and_slide()
	var left: float = arena_bounds.position.x + 40.0
	var right: float = arena_bounds.end.x - 40.0
	global_position.x = clampf(global_position.x, left, right)
	if state == State.DASH:
		_check_dash_contact(before, global_position)
		if is_on_wall() or global_position.x <= left or global_position.x >= right:
			for index: int in range(get_slide_collision_count()):
				var obstacle: CollisionObject2D = get_slide_collision(index).get_collider() as CollisionObject2D
				_damage_cover(obstacle)
			_recover(1.25)
	queue_redraw()


func _target_alive() -> bool:
	return is_instance_valid(target) and not target.is_queued_for_deletion() and not bool(target.get("is_dead"))


func _shoulder() -> Vector2:
	return global_position + Vector2(0, -24)


func _target_center() -> Vector2:
	return target.global_position + Vector2(0, -12)


func _ray(start: Vector2, finish: Vector2) -> Dictionary:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, finish, 27, [get_rid()])
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query)


func _visible_from(origin: Vector2) -> bool:
	if not _target_alive():
		return false
	var obstruction: Dictionary = _ray(origin, _target_center())
	return obstruction.is_empty() or obstruction.get("collider") == target


func _start_pattern(pattern: Pattern) -> void:
	_pattern = pattern
	state = State.WINDUP
	_attack_resolved = false
	_damaged_props.clear()
	_burst_remaining = 0
	var offset: Vector2 = _target_center() - _shoulder()
	_locked_direction = offset.normalized() if offset.length_squared() > 0.01 else Vector2(_facing, 0)
	if pattern == Pattern.DASH:
		_locked_direction = Vector2(_facing, 0)
		_timer = 0.70
	elif pattern == Pattern.BURST:
		_timer = 0.85
	else:
		_timer = 0.95
		_slam_center = global_position
	if _assisted:
		_timer *= 1.3
	feedback.emit("boss_warn", global_position)


func _begin_active() -> void:
	match _pattern:
		Pattern.DASH:
			state = State.DASH
			_timer = 0.65
			feedback.emit("melee", global_position)
		Pattern.BURST:
			state = State.BURST
			_burst_remaining = 3
			_shot_timer = 0.0
		Pattern.SLAM:
			state = State.LEAP
			_airtime = 0.0
			# O aviso anuncia o piso: não pousar numa passarela e deslocar a onda para cima.
			set_collision_mask_value(5, false)
			velocity.y = -320.0


func _check_dash_contact(start: Vector2, finish: Vector2) -> void:
	if _attack_resolved or not _target_alive():
		return
	var victim: Vector2 = _target_center()
	var nearest_x: float = clampf(victim.x, minf(start.x, finish.x), maxf(start.x, finish.x))
	if absf(victim.x - nearest_x) <= 25.0 and absf(victim.y - (finish.y - 18.0)) <= 25.0 and _visible_from(_shoulder()):
		_deal_damage(20.0, Vector2(_locked_direction.x * 155.0, -65.0))


func _damage_cover(obstacle: CollisionObject2D) -> void:
	if obstacle == null or not obstacle.get_collision_layer_value(4) or not obstacle.has_method("receive_damage"):
		return
	var key: int = obstacle.get_instance_id()
	if _damaged_props.has(key):
		return
	_damaged_props[key] = true
	obstacle.call("receive_damage", 35.0, _locked_direction * 240.0, self)
	feedback.emit("hit", global_position)


func _fire_bullet() -> void:
	var start: Vector2 = _shoulder()
	var muzzle: Vector2 = start + _locked_direction * 23.0
	var hit: Dictionary = _ray(start, muzzle)
	var finish: Vector2 = muzzle + _locked_direction * 850.0
	if hit.is_empty():
		hit = _ray(muzzle, finish)
	else:
		muzzle = start
	if not hit.is_empty():
		finish = hit["position"]
		if hit.get("collider") == target:
			_deal_damage(14.0, _locked_direction * 95.0)
	_tracers.append({"from": muzzle, "to": finish, "remaining": 0.10})
	if _tracers.size() > 3:
		_tracers.pop_front()
	feedback.emit("pistol", muzzle)


func _impact_slam() -> void:
	_slam_center = global_position
	_shock_remaining = 0.32
	if _target_alive() and absf(target.global_position.x - global_position.x) <= 160.0 and absf(target.global_position.y - global_position.y) <= 24.0 and _visible_from(_shoulder()):
		var push: float = signf(target.global_position.x - global_position.x)
		_deal_damage(26.0, Vector2(push * 150.0, -100.0))
	feedback.emit("explosion", global_position)


func _deal_damage(amount: float, impulse: Vector2) -> void:
	if _attack_resolved or not _target_alive():
		return
	# Um contato já evitado pela esquiva também encerra o dano deste ataque.
	_attack_resolved = true
	target.call("receive_damage", amount * (0.7 if _assisted else 1.0), impulse, self)


func _recover(duration: float) -> void:
	state = State.RECOVERY
	_timer = duration
	velocity.x = 0.0
	_burst_remaining = 0
	if is_on_floor():
		set_collision_mask_value(5, true)


func receive_damage(amount: float, impulse: Vector2, source: Node = null) -> bool:
	if is_dead:
		return false
	var multiplier: float = 1.4 if state == State.RECOVERY else 1.0
	if not health.apply_damage(amount * multiplier):
		return false
	_hit_flash = 0.12
	if is_dead:
		return true
	_knockback = clampf(impulse.x, -100.0, 100.0)
	if phase == 1 and health.current_health <= health.max_health * 0.5:
		phase = 2
		state = State.PHASE_CHANGE
		_timer = 0.8
		_attack_resolved = true
		_burst_remaining = 0
		velocity.x = 0.0
		phase_changed.emit(phase)
		feedback.emit("boss_phase", global_position)
	elif impulse.length() >= 200.0 and _stun_cooldown <= 0.0 and not source is CharacterBody2D:
		state = State.STUNNED
		_timer = 0.9
		_stun_cooldown = 3.0
		_attack_resolved = true
		_burst_remaining = 0
		feedback.emit("boss_stun", global_position)
	queue_redraw()
	return true


func _die() -> void:
	if is_dead:
		return
	is_dead = true
	state = State.DEAD
	_timer = 0.8
	velocity = Vector2.ZERO
	_burst_remaining = 0
	_tracers.clear()
	_shock_remaining = 0.0
	collision_layer = 0
	collision_mask = 0
	remove_from_group("enemies")
	remove_from_group("damageable")
	remove_from_group("bosses")
	died.emit(self)


func _update_tracers(delta: float) -> void:
	var active: Array[Dictionary] = []
	for tracer: Dictionary in _tracers:
		tracer["remaining"] = float(tracer["remaining"]) - delta
		if float(tracer["remaining"]) > 0.0:
			active.append(tracer)
	_tracers = active


func _draw() -> void:
	var armor: Color = Color("a67766") if phase == 1 else Color("c67c59")
	if _hit_flash > 0.0:
		armor = Color("f4e4ba")
	if is_dead:
		draw_rect(Rect2(-19, -10, 38, 10), armor.darkened(0.45))
		return
	draw_rect(Rect2(-14, -35, 28, 35), Color("172631"))
	draw_rect(Rect2(-13, -27, 26, 20), armor)
	draw_rect(Rect2(-15, -29, 10, 10), armor.darkened(0.25))
	draw_rect(Rect2(5, -29, 10, 10), armor.darkened(0.25))
	draw_rect(Rect2(-8, -36, 16, 10), Color("bcc0a8"))
	draw_rect(Rect2(-9, -36, 18, 4), Color("633e39"))
	draw_rect(Rect2(-7 if _facing < 0 else 0, -31, 7, 3), Color("f2b780"))
	draw_rect(Rect2(-10, -8, 8, 8), Color("394a53"))
	draw_rect(Rect2(2, -8, 8, 8), Color("394a53"))
	var arm: Vector2 = _locked_direction if state == State.WINDUP or state == State.BURST else Vector2(_facing, 0)
	draw_line(Vector2(0, -24), Vector2(0, -24) + arm * 24.0, Color("d2c9ae"), 5.0)
	if state == State.RECOVERY:
		draw_arc(Vector2(0, -22), 25.0, 0.0, TAU, 20, Color("a8dfc7"), 1.0)
	if state == State.STUNNED:
		draw_string(ThemeDB.fallback_font, Vector2(-10, -44), "///", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e5d687"))
	if state == State.WINDUP:
		var warning: Color = Color("f1b876")
		draw_string(ThemeDB.fallback_font, Vector2(-4, -48), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, warning)
		if _pattern == Pattern.DASH:
			draw_line(Vector2(0, -4), Vector2(_locked_direction.x * 280.0, -4), warning, 2.0)
			var tip: Vector2 = Vector2(_locked_direction.x * 280.0, -4)
			draw_line(tip, tip + Vector2(-_locked_direction.x * 13, -7), warning, 2.0)
			draw_line(tip, tip + Vector2(-_locked_direction.x * 13, 7), warning, 2.0)
		elif _pattern == Pattern.BURST:
			draw_line(Vector2(0, -24), Vector2(0, -24) + _locked_direction * 850.0, Color(0.95, 0.55, 0.36, 0.65), 1.0)
	if (state == State.WINDUP and _pattern == Pattern.SLAM) or state == State.LEAP:
		var center: Vector2 = to_local(_slam_center)
		draw_line(center + Vector2(-160, -2), center + Vector2(160, -2), Color("efb172"), 3.0)
		for x: float in [-160.0, -80.0, 0.0, 80.0, 160.0]:
			draw_line(center + Vector2(x, -2), center + Vector2(x, -10), Color("efb172"), 2.0)
	if _shock_remaining > 0.0:
		var center: Vector2 = to_local(_slam_center)
		var radius: float = 160.0 * (1.0 - _shock_remaining / 0.32)
		draw_arc(center, radius, PI, TAU, 20, Color("f0c597"), 2.0)
	for tracer: Dictionary in _tracers:
		draw_line(to_local(tracer["from"]), to_local(tracer["to"]), Color("f4d8a0"), 2.0)
