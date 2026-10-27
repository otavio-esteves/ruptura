extends Node2D
## Efeito transitório original, em coordenadas de mundo e sem colisão.

var segments: Array[Dictionary] = []
var melee_center: Vector2 = Vector2.ZERO
var melee_direction: Vector2 = Vector2.RIGHT
var is_melee: bool = false
var muzzle: Vector2 = Vector2.INF
var muzzle_direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.10
var _remaining: float = 0.10


func _ready() -> void:
	top_level = true
	global_transform = Transform2D.IDENTITY
	z_index = 20
	_remaining = lifetime
	queue_redraw()


func _process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		queue_free()
	else:
		modulate.a = clampf(_remaining / lifetime, 0.0, 1.0)


func _draw() -> void:
	if muzzle.is_finite():
		# Compact warm pixel clusters; origin is the actual unblocked weapon muzzle.
		var direction: Vector2 = muzzle_direction.normalized()
		var side: Vector2 = direction.orthogonal()
		var outer := PackedVector2Array()
		for point: Vector2 in [Vector2(-1, 0), Vector2(2, -2), Vector2(3, -1), Vector2(7, -0.5), Vector2(4, 1), Vector2(3, 2), Vector2(1, 1)]:
			outer.append(((muzzle + direction * point.x + side * point.y) * 2.0).round() * 0.5)
		draw_colored_polygon(outer, Color("cd793b"))
		draw_line(muzzle, muzzle + direction * 5.0, Color("f9cf73"), 2.0)
		draw_line(muzzle, muzzle + direction * 3.0, Color("fff0b4"), 1.0)
	for segment: Dictionary in segments:
		var start: Vector2 = segment["from"]
		var finish: Vector2 = segment["to"]
		draw_line(start, finish, Color("eed4a0"), 0.5)
		if bool(segment.get("hit", false)):
			var direction: Vector2 = (finish - start).normalized()
			for index: int in range(4):
				var spark_direction: Vector2 = -direction.rotated(-0.8 + index * 0.5)
				draw_line(finish + spark_direction, finish + spark_direction * (3.0 + index % 2 * 2.0), Color("f1cc83") if index % 2 == 0 else Color("f1e7bf"), 0.5)
	if is_melee:
		var angle: float = melee_direction.angle()
		draw_arc(melee_center, 29.0, angle - 0.85, angle + 0.85, 8, Color("c7e7dd"), 2.0)
