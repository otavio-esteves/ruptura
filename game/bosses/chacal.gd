extends CharacterBody2D
## Três padrões compartilhados entre duas fases; sem bloqueio arbitrário de dano.
signal died(enemy: Node)
signal phase_changed(phase: int)
signal feedback(kind: String, position: Vector2)

const HealthScript = preload("res://game/combat/health_component.gd")
const PixelActor = preload("res://game/visuals/pixel_actor.gd")
enum State { INTRO, APPROACH, WINDUP, DASH, BURST, LEAP, RECOVERY, PHASE_CHANGE, STUNNED, DEAD }
enum Pattern { DASH, BURST, SLAM }

const BOSS_HEALTH: float = 420.0
const DASH_DAMAGE: float = 24.0
const BURST_DAMAGE: float = 18.0
const SLAM_DAMAGE: float = 30.0
const DASH_WINDUP: float = 0.60
const BURST_WINDUP: float = 0.72
const SLAM_WINDUP: float = 0.85
const ATTACK_RECOVERY: float = 0.85
const HEAVY_RECOVERY: float = 1.10
const ASSISTED_DAMAGE_MULTIPLIER: float = 0.7
const ASSISTED_WINDUP_MULTIPLIER: float = 1.45
const INTRO_DURATION: float = 1.0
const PHASE_CHANGE_DURATION: float = 0.8
const PHASE_TWO_HEALTH_RATIO: float = 0.5
const DASH_DURATION: float = 0.65
const DASH_SPEED: float = 420.0
const DASH_PHASE_TWO_SPEED: float = 470.0
const DASH_CONTACT_RADIUS: float = 25.0

var display_name: String = "MARA «CHACAL»"
var health := HealthScript.new()
var target: CharacterBody2D
var phase: int = 1
var is_dead: bool = false
var state: State = State.INTRO
var arena_bounds: Rect2 = Rect2(0, 0, 1600, 720)

var _assisted: bool = false
var _timer: float = INTRO_DURATION
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
var _walk_cycle: float = 0.0
var _idle_cycle: float = 0.0
var _land_remaining: float = 0.0
var _visual_speed: float = 0.0
var _visual_state: int = -1
var _visual_state_duration: float = 1.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_to_group("enemies")
	add_to_group("damageable")
	add_to_group("bosses")
	health.name = "Health"
	health.max_health = BOSS_HEALTH
	health.depleted.connect(_die)
	add_child(health)


func configure(victim: CharacterBody2D, bounds: Rect2, assisted: bool = false) -> void:
	target = victim
	arena_bounds = bounds
	_assisted = assisted
	phase = 1
	is_dead = false
	state = State.INTRO
	_timer = INTRO_DURATION
	_cycle = 0
	_stun_cooldown = 0.0
	_knockback = 0.0
	_attack_resolved = false
	_damaged_props.clear()
	_burst_remaining = 0
	_tracers.clear()
	_shock_remaining = 0.0
	_walk_cycle = 0.0
	_idle_cycle = 0.0
	_land_remaining = 0.0
	_visual_speed = 0.0
	_visual_state = -1
	velocity = Vector2.ZERO
	collision_layer = 4
	collision_mask = 25
	health.max_health = BOSS_HEALTH
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
	var grounded_before: bool = is_on_floor()
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
		desired_speed = _locked_direction.x * (DASH_PHASE_TWO_SPEED if phase == 2 else DASH_SPEED)
		if _timer <= 0.0:
			_recover(ATTACK_RECOVERY)
			desired_speed = 0.0
	elif state == State.BURST:
		_shot_timer -= delta
		if _burst_remaining > 0 and _shot_timer <= 0.0:
			_fire_bullet()
			_burst_remaining -= 1
			_shot_timer = 0.16
		elif _burst_remaining == 0 and _shot_timer <= 0.0:
			_recover(ATTACK_RECOVERY)
	elif state == State.LEAP:
		_airtime += delta
		if is_on_floor() and _airtime > 0.10:
			_impact_slam()
			_recover(HEAVY_RECOVERY)
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
			_recover(HEAVY_RECOVERY)
	_update_animation(delta, before, grounded_before)
	queue_redraw()


func _update_animation(delta: float, previous_position: Vector2, grounded_before: bool) -> void:
	var displacement: float = global_position.x - previous_position.x
	var distance: float = absf(displacement)
	_visual_speed = distance / maxf(delta, 0.001)
	_idle_cycle = fposmod(_idle_cycle + delta * 0.5, 1.0)
	_land_remaining = maxf(0.0, _land_remaining - delta)
	if is_on_floor():
		if not grounded_before:
			_land_remaining = 0.10
		elif distance > 0.01:
			_walk_cycle = fposmod(_walk_cycle + displacement * _facing / 44.0, 1.0)
	if _visual_state != int(state):
		_visual_state = int(state)
		_visual_state_duration = maxf(0.01, _timer)


func _animation_pose() -> Dictionary:
	var body_state: String = "idle"
	if is_dead:
		body_state = "dead"
	elif _hit_flash > 0.0 or state == State.STUNNED:
		body_state = "hurt"
	elif not is_on_floor():
		body_state = "jump" if velocity.y < -40.0 else ("fall" if velocity.y > 40.0 else "apex")
	elif _land_remaining > 0.0:
		body_state = "land"
	elif _visual_speed > 8.0:
		body_state = "run"
	var action: String = "neutral"
	var progress: float = 0.0
	if state == State.WINDUP or state == State.PHASE_CHANGE:
		action = "windup"
		progress = 1.0 - _timer / _visual_state_duration
	elif state == State.DASH:
		action = "attack"
		progress = 1.0 - _timer / DASH_DURATION
	elif state == State.BURST:
		action = "attack"
		progress = 1.0 - float(_burst_remaining) / 3.0
	elif state == State.LEAP:
		action = "attack"
		progress = minf(1.0, _airtime / 0.65)
	elif state == State.RECOVERY:
		action = "recovery"
		progress = 1.0 - _timer / _visual_state_duration
	var recoil: float = 0.0
	for tracer: Dictionary in _tracers:
		recoil = maxf(recoil, float(tracer["remaining"]) / 0.10)
	var aiming: bool = state == State.WINDUP or state == State.BURST or state == State.DASH or state == State.RECOVERY
	var cycle: float = _walk_cycle if body_state == "run" else _idle_cycle
	if body_state == "dead":
		cycle = clampf(1.0 - _timer / 0.8, 0.0, 0.99)
	if body_state == "land":
		cycle = clampf(1.0 - _land_remaining / 0.10, 0.0, 1.0)
	return {
		"kind": "chacal", "state": body_state,
		"cycle": cycle,
		"facing": _facing, "aim": _locked_direction if aiming else Vector2(_facing, 0),
		"recoil": clampf(recoil, 0.0, 1.0), "flash": _hit_flash > 0.0,
		"phase": phase, "weapon": "pistol" if _pattern == Pattern.BURST else "blade",
		"action": action, "action_progress": clampf(progress, 0.0, 1.0),
	}


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
		_timer = DASH_WINDUP
	elif pattern == Pattern.BURST:
		_timer = BURST_WINDUP
	else:
		_timer = SLAM_WINDUP
		_slam_center = global_position
	if _assisted:
		_timer *= ASSISTED_WINDUP_MULTIPLIER
	feedback.emit("boss_warn", global_position)


func _begin_active() -> void:
	match _pattern:
		Pattern.DASH:
			state = State.DASH
			_timer = DASH_DURATION
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
	if absf(victim.x - nearest_x) <= DASH_CONTACT_RADIUS and absf(victim.y - (finish.y - 18.0)) <= DASH_CONTACT_RADIUS and _visible_from(_shoulder()):
		_deal_damage(DASH_DAMAGE, Vector2(_locked_direction.x * 155.0, -65.0))


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
			_deal_damage(BURST_DAMAGE, _locked_direction * 95.0)
	_tracers.append({"from": muzzle, "to": finish, "remaining": 0.10})
	if _tracers.size() > 3:
		_tracers.pop_front()
	feedback.emit("pistol", muzzle)


func _impact_slam() -> void:
	_slam_center = global_position
	_shock_remaining = 0.32
	if _target_alive() and absf(target.global_position.x - global_position.x) <= 160.0 and absf(target.global_position.y - global_position.y) <= 24.0 and _visible_from(_shoulder()):
		var push: float = signf(target.global_position.x - global_position.x)
		_deal_damage(SLAM_DAMAGE, Vector2(push * 150.0, -100.0))
	feedback.emit("explosion", global_position)


func _deal_damage(amount: float, impulse: Vector2) -> void:
	if _attack_resolved or not _target_alive():
		return
	# Um contato já evitado pela esquiva também encerra o dano deste ataque.
	_attack_resolved = true
	target.call("receive_damage", amount * (ASSISTED_DAMAGE_MULTIPLIER if _assisted else 1.0), impulse, self)


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
	if phase == 1 and health.current_health <= health.max_health * PHASE_TWO_HEALTH_RATIO:
		phase = 2
		state = State.PHASE_CHANGE
		_timer = PHASE_CHANGE_DURATION
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
	PixelActor.draw_actor(self, _animation_pose())
	if is_dead:
		return
	if state == State.RECOVERY:
		draw_arc(Vector2(0, -22), 25.0, 0.0, TAU, 20, Color("a8dfc7"), 1.0)
	if state == State.STUNNED:
		draw_string(ThemeDB.fallback_font, Vector2(-10, -44), "///", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e5d687"))
	if state == State.WINDUP:
		var warning: Color = Color("f1b876")
		draw_string(ThemeDB.fallback_font, Vector2(-4, -48), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, warning)
		if _pattern == Pattern.DASH:
			# Incluir o contato corporal e a velocidade da fase: o aviso cobre todo o avanço.
			var reach: float = (DASH_PHASE_TWO_SPEED if phase == 2 else DASH_SPEED) * DASH_DURATION + DASH_CONTACT_RADIUS
			var tip: Vector2 = Vector2(_locked_direction.x * reach, -4)
			draw_line(Vector2(0, -4), tip, warning, 2.0)
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
