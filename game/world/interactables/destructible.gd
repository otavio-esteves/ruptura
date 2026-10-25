extends StaticBody2D
## Cobertura estática; impulso altera somente o desenho, nunca o colisor.

signal destroyed(obj: Node)

@export_enum("crate", "barrel", "glass") var kind: String = "crate"
var health: float = 45.0
var is_dead: bool = false
var reduced_effects: bool = false
const EXPLOSION_RADIUS: float = 110.0
const EXPLOSION_DAMAGE: float = 65.0
const MAX_EXPLOSION_TARGETS: int = 64
const EFFECT_LIFETIME: float = 0.38

var _dimensions: Vector2 = Vector2(28.0, 30.0)
var _flash: float = 0.0
var _wobble: Vector2 = Vector2.ZERO
var _effect_age: float = 0.0
var _exploded: bool = false
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("damageable")
	add_to_group("destructibles")
	configure(kind)
	set_process(false)


func configure(type: String) -> void:
	kind = type if type in ["crate", "barrel", "glass"] else "crate"
	match kind:
		"barrel":
			health = 25.0
			_dimensions = Vector2(18.0, 28.0)
		"glass":
			health = 8.0
			_dimensions = Vector2(8.0, 40.0)
		_:
			health = 45.0
			_dimensions = Vector2(28.0, 30.0)
	if _collision != null:
		var shape := RectangleShape2D.new()
		shape.size = _dimensions
		_collision.shape = shape
		_collision.position = Vector2(0.0, -_dimensions.y * 0.5)
	queue_redraw()


func receive_damage(amount: float, impulse: Vector2, _source: Node = null) -> bool:
	if is_dead or amount <= 0.0 or not is_finite(amount):
		return false
	health = maxf(0.0, health - amount)
	_flash = 0.09
	_wobble = impulse.limit_length(180.0) * 0.025
	set_process(true)
	if health <= 0.0:
		_destroy()
	queue_redraw()
	return true


func _destroy() -> void:
	is_dead = true
	remove_from_group("damageable")
	_collision.set_deferred("disabled", true)
	# Diferir também a explosão: uma cadeia não recursa na pilha de dano.
	if kind == "barrel":
		call_deferred("_explode")
	destroyed.emit(self)


func _blast_center() -> Vector2:
	return global_position + Vector2(0.0, -_dimensions.y * 0.5)


func _explode() -> void:
	if _exploded or not is_inside_tree() or is_queued_for_deletion():
		return
	var ancestor: Node = get_parent()
	while ancestor != null:
		if ancestor.is_queued_for_deletion():
			return
		ancestor = ancestor.get_parent()
	_exploded = true
	var origin: Vector2 = _blast_center()
	var pending: Array[Dictionary] = []
	# Snapshot e LOS antes de aplicar dano: destruir cobertura durante esta onda
	# não faz o mesmo evento atravessá-la para atingir quem estava protegido.
	var candidates: Array[Node] = get_tree().get_nodes_in_group("damageable")
	for candidate: Node in candidates:
		if candidate == self or not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
			continue
		if not candidate is Node2D or not candidate.has_method("receive_damage"):
			continue
		var destination: Vector2 = (candidate as Node2D).global_position + Vector2(0.0, -12.0)
		if candidate.has_method("_blast_center"):
			destination = candidate.call("_blast_center")
		var distance: float = origin.distance_to(destination)
		if distance > EXPLOSION_RADIUS:
			continue
		var ray := PhysicsRayQueryParameters2D.create(origin, destination, 25)
		var excluded: Array[RID] = [get_rid()]
		if candidate is CollisionObject2D:
			excluded.append((candidate as CollisionObject2D).get_rid())
		ray.exclude = excluded
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		var direction: Vector2 = origin.direction_to(destination)
		if direction.is_zero_approx():
			direction = Vector2.UP
		var falloff: float = maxf(0.35, 1.0 - distance / EXPLOSION_RADIUS)
		pending.append({"target": candidate, "damage": EXPLOSION_DAMAGE * falloff, "impulse": direction * 270.0 * falloff})
		if pending.size() >= MAX_EXPLOSION_TARGETS:
			break
	for hit: Dictionary in pending:
		var target: Node = hit["target"]
		if is_instance_valid(target) and not target.is_queued_for_deletion():
			target.call("receive_damage", hit["damage"], hit["impulse"], self)
	queue_redraw()


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_wobble = _wobble.move_toward(Vector2.ZERO, delta * 60.0)
	if is_dead:
		_effect_age += delta
		if _effect_age >= EFFECT_LIFETIME:
			queue_free()
	elif _flash <= 0.0 and _wobble.is_zero_approx():
		set_process(false)
	queue_redraw()


func _draw() -> void:
	if is_dead:
		_draw_break_effect()
		return
	var rect := Rect2(Vector2(-_dimensions.x * 0.5, -_dimensions.y) + _wobble, _dimensions)
	var ink := Color("26333c")
	var edge := Color("a5b1b2")
	if _flash > 0.0:
		edge = Color("fff0ce")
	match kind:
		"barrel":
			draw_rect(rect, Color("92574b"))
			draw_rect(rect, edge, false, 1.0)
			for y: float in [-22.0, -7.0]:
				draw_line(Vector2(-9.0, y) + _wobble, Vector2(9.0, y) + _wobble, ink, 3.0)
			draw_colored_polygon(PackedVector2Array([Vector2(-4.0, -11.0), Vector2(0.0, -19.0), Vector2(4.0, -11.0)]), Color("f0c36c"))
		"glass":
			draw_rect(rect, Color("476975"))
			draw_rect(rect, edge, false, 1.0)
			draw_line(rect.position + Vector2(2.0, 8.0), rect.end - Vector2(2.0, 8.0), Color("a7ded9"), 1.0)
		_:
			draw_rect(rect, Color("665c4d"))
			draw_rect(rect, edge, false, 1.0)
			draw_line(rect.position + Vector2(3.0, 3.0), rect.end - Vector2(3.0, 3.0), edge, 2.0)
			draw_line(rect.position + Vector2(rect.size.x - 3.0, 3.0), rect.position + Vector2(3.0, rect.size.y - 3.0), ink, 2.0)


func _draw_break_effect() -> void:
	var progress: float = clampf(_effect_age / EFFECT_LIFETIME, 0.0, 1.0)
	var center := Vector2(0.0, -_dimensions.y * 0.5)
	var color := Color("e7b675") if kind == "barrel" else Color("a5b1b2")
	color.a = 1.0 - progress
	if reduced_effects: color.a *= 0.6
	if kind == "barrel":
		draw_arc(center, 8.0 + EXPLOSION_RADIUS * progress, 0.0, TAU, 32, color, 2.0)
	var shards: int = 3 if reduced_effects else 10
	for index: int in range(shards):
		var direction := Vector2.from_angle(float(index) * TAU / float(shards))
		var shard_position: Vector2 = center + direction * progress * (54.0 if kind == "barrel" else 24.0) + Vector2(0.0, progress * progress * 14.0)
		draw_line(shard_position, shard_position + direction * 3.0, color, 2.0)
