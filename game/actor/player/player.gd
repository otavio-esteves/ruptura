extends CharacterBody2D
## Posição nos pés. Movimento responsivo, dano e janela curta de esquiva.
signal died
signal damaged(amount: float)
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
	if is_dead:
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
		var stick: Vector2 = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", aim_deadzone)
		if stick.length_squared() > 0.001:
			aim_direction = stick.normalized()
	else:
		var mouse_delta: Vector2 = get_global_mouse_position() - (global_position + _shoulder())
		if mouse_delta.length_squared() > 4.0:
			aim_direction = mouse_delta.normalized()
	if absf(aim_direction.x) > 0.10:
		_facing = signf(aim_direction.x)


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
	if is_instance_valid(health):
		health.reset_health()
	_collision.shape = _standing_shape
	_collision.position.y = -12.0
	set_collision_mask_value(5, true)
	queue_redraw()


func _shoulder() -> Vector2:
	return Vector2(0.0, -10.0 if is_crouching else -18.0)


func _draw() -> void:
	var height: float = 14.0 if is_crouching else 24.0
	var jacket: Color = Color("6b9395")
	if is_dodging:
		jacket = Color("b2d6cf")
	if _hurt_flash > 0.0:
		jacket = Color("ee997d")
	if is_dead:
		draw_rect(Rect2(-11, -7, 22, 7), Color("6a5354"))
		return
	draw_rect(Rect2(-6.0, -height, 12.0, height - 6.0), Color("15252d"))
	draw_rect(Rect2(-5.0, -height + 6.0, 10.0, height - 12.0), jacket)
	draw_rect(Rect2(-4.0, -height, 8.0, 6.0), Color("c3b99c"))
	draw_rect(Rect2(0.0 if _facing > 0.0 else -5.0, -height + 2.0, 5.0, 2.0), Color("c9eee0"))
	draw_rect(Rect2(-5.0, -6.0, 4.0, 6.0), Color("364650"))
	draw_rect(Rect2(1.0, -6.0, 4.0, 6.0), Color("364650"))
	var shoulder: Vector2 = _shoulder()
	draw_line(shoulder, shoulder + aim_direction * 10.0, jacket, 4.0)
	draw_line(shoulder + aim_direction * 8.0, shoulder + aim_direction * 18.0, Color("c4c6b4"), 3.0)
	var reticle: Vector2 = shoulder + aim_direction * 64.0
	var ink: Color = Color("10191e")
	var light: Color = Color("e3dc9c")
	draw_circle(reticle, 5.0, ink, false, 3.0)
	draw_circle(reticle, 4.0, light, false, 1.0)
	draw_line(reticle + Vector2(-7.0, 0.0), reticle + Vector2(-3.0, 0.0), light)
	draw_line(reticle + Vector2(3.0, 0.0), reticle + Vector2(7.0, 0.0), light)
	draw_line(reticle + Vector2(0.0, -7.0), reticle + Vector2(0.0, -3.0), light)
	draw_line(reticle + Vector2(0.0, 3.0), reticle + Vector2(0.0, 7.0), light)
