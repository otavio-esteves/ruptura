extends CharacterBody2D
## Posição nos pés. Movimento responsivo, dano e janela curta de esquiva.
signal died
signal damaged(amount: float)
const ReferenceHero = preload("res://game/visuals/reference_hero.gd")
const PixelActor = preload("res://game/visuals/pixel_actor.gd")
const HEALTH = preload("res://game/combat/health_component.gd")

@export var walk_speed: float = 150.0
@export var run_speed: float = 220.0
@export var ground_acceleration: float = 1800.0
@export var air_acceleration: float = 1000.0
@export var gravity: float = 1050.0
@export var jump_speed: float = 420.0
@export var coyote_duration: float = 0.10
@export var jump_buffer_duration: float = 0.12
@export_range(0.05, 0.50) var aim_deadzone: float = 0.20
@export var dodge_speed: float = 340.0
@export var dodge_duration: float = 0.28
@export var dodge_cooldown: float = 0.65

var aim_direction: Vector2 = Vector2.RIGHT
var input_device: String = "mouse_keyboard"
var is_crouching: bool = false
var is_dodging: bool = false
var dodge_cooldown_remaining: float = 0.0
var health: Node
var weapon_controller: Node2D
var is_dead: bool = false
var assisted: bool = false
var aim_assist_enabled: bool = false
var independent_aim: bool = false
var reduced_effects: bool = false
var recoil_remaining: float = 0.0
var _walk_cycle: float = 0.0
var _idle_cycle: float = 0.0
var _land_remaining: float = 0.0
var _visual_speed: float = 0.0
var _death_time: float = 0.0
var _hurt_flash: float = 0.0
var _knockback: Vector2 = Vector2.ZERO
var _hurt_control_remaining: float = 0.0

var _coyote_remaining: float = 0.0
var _jump_buffer_remaining: float = 0.0
var _dodge_remaining: float = 0.0
var _drop_remaining: float = 0.0
var _dodge_direction: float = 1.0
var _facing: float = 1.0
var _has_focus: bool = true
var _standing_shape: RectangleShape2D = RectangleShape2D.new()
var _crouching_shape: RectangleShape2D = RectangleShape2D.new()

@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_to_group("player")
	add_to_group("damageable")
	health = HEALTH.new()
	health.invulnerability_duration = 0.55
	add_child(health)
	_standing_shape.size = Vector2(12.0, 24.0)
	_crouching_shape.size = Vector2(12.0, 14.0)
	_collision.shape = _standing_shape
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.relative.length_squared() > 4.0:
			input_device = "mouse_keyboard"
	elif event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed():
			input_device = "mouse_keyboard"
	elif event is InputEventJoypadButton:
		if event.pressed:
			input_device = "gamepad"
	elif event is InputEventJoypadMotion:
		if absf(event.axis_value) > aim_deadzone:
			input_device = "gamepad"


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_has_focus = false
		velocity = Vector2.ZERO
		_jump_buffer_remaining = 0.0
		_dodge_remaining = 0.0
		is_dodging = false
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_has_focus = true


func _physics_process(delta: float) -> void:
	if not _has_focus:
		return
	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	recoil_remaining = maxf(0.0, recoil_remaining - delta)
	var previous_position: Vector2 = global_position
	var grounded_before: bool = is_on_floor()
	_idle_cycle = fposmod(_idle_cycle + delta * 0.6, 1.0)
	_land_remaining = maxf(0.0, _land_remaining - delta)
	if is_dead:
		_death_time += delta
		velocity.x = move_toward(velocity.x, 0.0, 1100.0 * delta)
		velocity.y = minf(velocity.y + gravity * delta, 750.0)
		move_and_slide()
		queue_redraw()
		return
	_update_aim()
	dodge_cooldown_remaining = maxf(0.0, dodge_cooldown_remaining - delta)
	_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)
	_drop_remaining = maxf(0.0, _drop_remaining - delta)
	set_collision_mask_value(5, _drop_remaining <= 0.0)
	var grounded: bool = is_on_floor() and _drop_remaining <= 0.0
	if grounded:
		_coyote_remaining = coyote_duration
	else:
		_coyote_remaining = maxf(0.0, _coyote_remaining - delta)
	var move_axis: float = Input.get_axis("move_left", "move_right")
	var wants_crouch: bool = Input.is_action_pressed("crouch")
	_set_crouching(wants_crouch and grounded)
	if Input.is_action_just_pressed("jump"):
		if wants_crouch and grounded and _on_one_way_platform():
			_drop_remaining = 0.20
			set_collision_mask_value(5, false)
			_coyote_remaining = 0.0
			_jump_buffer_remaining = 0.0
			velocity.y = 80.0
		else:
			_jump_buffer_remaining = jump_buffer_duration
	if Input.is_action_just_pressed("dodge") and dodge_cooldown_remaining <= 0.0:
		_dodge_direction = signf(move_axis) if absf(move_axis) > 0.10 else _facing
		_dodge_remaining = dodge_duration
		dodge_cooldown_remaining = dodge_duration + dodge_cooldown
		_jump_buffer_remaining = 0.0
	is_dodging = _dodge_remaining > 0.0
	if is_dodging:
		_dodge_remaining = maxf(0.0, _dodge_remaining - delta)
		velocity.x = _dodge_direction * dodge_speed
	else:
		var speed: float = run_speed if Input.is_action_pressed("sprint") else walk_speed
		if is_crouching:
			speed *= 0.45
		var acceleration: float = ground_acceleration if grounded else air_acceleration
		velocity.x = move_toward(velocity.x, move_axis * speed, acceleration * delta)
		if _jump_buffer_remaining > 0.0 and _coyote_remaining > 0.0 and not is_crouching:
			velocity.y = -jump_speed
			_coyote_remaining = 0.0
			_jump_buffer_remaining = 0.0
	if not grounded:
		velocity.y = minf(velocity.y + gravity * delta, 750.0)
	if Input.is_action_just_released("jump") and velocity.y < -160.0:
		velocity.y *= 0.55
	_hurt_control_remaining = maxf(0.0, _hurt_control_remaining - delta)
	if _hurt_control_remaining > 0.0:
		velocity.x = _knockback.x
	_knockback = _knockback.move_toward(Vector2.ZERO, 700.0 * delta)
	move_and_slide()
	var displacement: float = global_position.x - previous_position.x
	_visual_speed = absf(displacement) / maxf(delta, 0.001)
	if is_on_floor():
		if not grounded_before: _land_remaining = 0.10
		elif absf(displacement) > 0.01 and not is_dodging:
			_walk_cycle = fposmod(_walk_cycle + displacement * _facing / (40.0 if Input.is_action_pressed("sprint") else 32.0), 1.0)
	queue_redraw()

func receive_damage(amount: float, impulse: Vector2, _source: Node = null) -> bool:
	if is_dead or (is_dodging and _dodge_remaining >= 0.10 and _dodge_remaining <= 0.25):
		return false
	if not health.apply_damage(amount * (0.6 if assisted else 1.0)):
		return false
	_hurt_flash = 0.16
	_knockback = impulse.limit_length(180.0)
	velocity.y = clampf(velocity.y + _knockback.y, -200.0, 450.0)
	_hurt_control_remaining = 0.12
	damaged.emit(amount)
	if health.current_health <= 0.0:
		is_dead = true
		is_dodging = false
		_dodge_remaining = 0.0
		if is_instance_valid(weapon_controller):
			weapon_controller.cancel_reload()
		died.emit()
	return true

func heal(amount: float) -> void:
	health.heal(amount)


func _update_aim() -> void:
	if input_device == "gamepad":
		var stick := Vector2.ZERO
		if independent_aim:
			stick = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", aim_deadzone)
		elif InputMap.has_action("move_aim_left"):
			stick = Input.get_vector("move_aim_left", "move_aim_right", "move_aim_up", "move_aim_down", aim_deadzone)
		if stick.length_squared() > 0.001:
			aim_direction = _assisted_aim(stick.normalized()) if aim_assist_enabled else stick.normalized()
	else:
		# A origem do cano acompanha o braço importado e muda de lado com o corpo.
		var horizontal: float = get_global_mouse_position().x - global_position.x
		if absf(horizontal) > 2.0: _facing = signf(horizontal)
		var mouse_delta: Vector2 = get_global_mouse_position() - (global_position + _shoulder())
		if mouse_delta.length_squared() > 4.0:
			aim_direction = mouse_delta.normalized()
	if absf(aim_direction.x) > 0.10:
		_facing = signf(aim_direction.x)

func _assisted_aim(raw: Vector2) -> Vector2:
	var origin: Vector2 = global_position + _shoulder()
	var selected: Vector2 = raw
	var best: float = INF
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not node is Node2D or bool(node.get("is_dead")): continue
		var offset: Vector2 = node.global_position + Vector2(0, -16) - origin
		if offset.length_squared() < 16.0 or offset.length_squared() > 360.0 * 360.0: continue
		var angle: float = absf(raw.angle_to(offset))
		if angle > deg_to_rad(7.0): continue
		var ray := PhysicsRayQueryParameters2D.create(origin, origin + offset, 25, [get_rid()])
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		var score: float = angle * 500.0 + offset.length() * 0.05
		if score < best:
			best = score
			selected = offset.normalized()
	return raw.slerp(selected, 0.22).normalized()


func _set_crouching(requested: bool) -> void:
	if requested == is_crouching:
		return
	if not requested and not _can_stand():
		return
	is_crouching = requested
	_collision.shape = _crouching_shape if is_crouching else _standing_shape
	_collision.position.y = -7.0 if is_crouching else -12.0


func _can_stand() -> bool:
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = _standing_shape
	query.transform = global_transform.translated_local(Vector2(0.0, -12.1))
	query.collision_mask = 9
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _on_one_way_platform() -> bool:
	for index: int in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(index)
		var body: CollisionObject2D = collision.get_collider() as CollisionObject2D
		if body != null and body.get_collision_layer_value(5) and collision.get_normal().y < -0.5:
			return true
	return false


func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if not connected:
		input_device = "mouse_keyboard"


func reset_to(spawn: Vector2) -> void:
	global_position = spawn
	velocity = Vector2.ZERO
	_coyote_remaining = 0.0
	_jump_buffer_remaining = 0.0
	_dodge_remaining = 0.0
	_drop_remaining = 0.0
	dodge_cooldown_remaining = 0.0
	is_dodging = false
	is_crouching = false
	is_dead = false
	_knockback = Vector2.ZERO
	_hurt_control_remaining = 0.0
	_hurt_flash = 0.0
	recoil_remaining = 0.0
	_walk_cycle = 0.0
	_land_remaining = 0.0
	_visual_speed = 0.0
	_death_time = 0.0
	if is_instance_valid(health):
		health.reset_health()
	_collision.shape = _standing_shape
	_collision.position.y = -12.0
	set_collision_mask_value(5, true)
	queue_redraw()


func _shoulder() -> Vector2:
	return ReferenceHero.weapon_geometry(_animation_pose()).origin


func get_fire_origin() -> Vector2:
	return global_position + _shoulder()

func get_muzzle_distance() -> float:
	return float(ReferenceHero.weapon_geometry(_animation_pose()).length)

func _animation_pose() -> Dictionary:
	var state: String = "idle"
	var cycle: float = _idle_cycle
	if is_dead:
		state = "dead"
		cycle = minf(0.99, _death_time / 0.35)
	elif is_dodging:
		state = "dodge"
		cycle = 1.0 - _dodge_remaining / dodge_duration
	elif _hurt_control_remaining > 0.0:
		state = "hurt"
	elif not is_on_floor():
		state = "jump" if velocity.y < -40.0 else ("fall" if velocity.y > 40.0 else "apex")
	elif is_crouching:
		state = "crouch"
		cycle = _walk_cycle
	elif _land_remaining > 0.0:
		state = "land"
		cycle = 1.0 - _land_remaining / 0.10
	elif _visual_speed > 8.0:
		state = "run"
		cycle = _walk_cycle
	var weapon: String = "pistol"
	var action: String = "neutral"
	var action_progress: float = 0.0
	if is_instance_valid(weapon_controller):
		weapon = weapon_controller.selected_weapon
		var loadout: Dictionary = weapon_controller.snapshot()
		if loadout.reloading and not is_dead and not is_dodging:
			action = "reload"
			action_progress = float(loadout.reload_progress)
		elif bool(loadout.get("melee_active", false)) and not is_dead and not is_dodging:
			action = "melee"
			action_progress = float(loadout.melee_progress)
	return {"kind": "spectre", "state": state, "cycle": cycle, "facing": _facing, "aim": aim_direction,
		"recoil": recoil_remaining / 0.08, "phase": 1, "weapon": weapon,
		"flash": _hurt_flash > 0.0 and not reduced_effects, "crouch_moving": _visual_speed > 8.0,
		"action": action, "action_progress": action_progress}

func _draw() -> void:
	PixelActor.draw_actor(self, _animation_pose())
	if is_dead: return
	var reticle: Vector2 = _shoulder() + aim_direction * 64.0
	var ink := Color("10191e")
	var light := Color("e3dc9c")
	# Pixel crosshair: integer coordinates, always visible over bright or dark props.
	var center: Vector2 = reticle.round()
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		draw_line(center + direction * 2.0, center + direction * 4.5, ink, 1.5)
		draw_line(center + direction * 2.0, center + direction * 4.0, light, 0.5)
	draw_rect(Rect2(center - Vector2(1, 1), Vector2(2, 2)), ink)
	draw_rect(Rect2(center - Vector2(0.5, 0.5), Vector2(1, 1)), light)
