extends Node2D
## Efeito transitório original, em coordenadas de mundo e sem colisão.

var segments: Array[Dictionary] = []
var melee_center: Vector2 = Vector2.ZERO
var melee_direction: Vector2 = Vector2.RIGHT
var is_melee: bool = false
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
	for segment: Dictionary in segments:
		var start: Vector2 = segment["from"]
		var finish: Vector2 = segment["to"]
		draw_line(start, finish, Color("eed4a0"), 1.0)
		if bool(segment.get("hit", false)):
			draw_line(finish + Vector2(-3, -3), finish + Vector2(3, 3), Color("f1e7bf"), 1.0)
			draw_line(finish + Vector2(-3, 3), finish + Vector2(3, -3), Color("f1e7bf"), 1.0)
	if is_melee:
		var angle: float = melee_direction.angle()
		draw_arc(melee_center, 29.0, angle - 0.85, angle + 0.85, 8, Color("c7e7dd"), 2.0)
