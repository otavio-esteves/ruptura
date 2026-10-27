extends Node2D
## Corredor horizontal da imagem fornecida: um único panorama, sem repetição.
const ART: Texture2D = preload("res://assets/art/reference/office-corridor.png")
const ART_SCALE: float = 0.1875
const FLOOR_Y: float = 620.0
const ART_FLOOR_Y: float = 584.0
var world_bounds := Rect2(0, 0, 407.25, 720)
var spawn_position := Vector2(36, FLOOR_Y)
var navigation_links: Array[Dictionary] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_surface("Floor", Rect2(0, FLOOR_Y, 407.25, 100))
	_surface("West", Rect2(-16, 0, 16, 720))
	_surface("East", Rect2(407.25, 0, 16, 720))
	_surface("Ceiling", Rect2(0, 0, 407.25, 16))

func _surface(title: String, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.name = title
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _draw() -> void:
	draw_rect(world_bounds, Color.BLACK)
	var origin := Vector2(0, FLOOR_Y - ART_FLOOR_Y * ART_SCALE)
	draw_texture_rect(ART, Rect2(origin, ART.get_size() * ART_SCALE), false)
