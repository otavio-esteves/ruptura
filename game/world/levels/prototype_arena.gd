extends Node2D
## Arena original de movimento/mira. Alvos são marcas visuais sem dano ou colisão.

@export var spawn_position: Vector2 = Vector2(120.0, 550.0)
@export var world_bounds: Rect2 = Rect2(0.0, 0.0, 1600.0, 720.0)
@export var show_training_targets: bool = true

const BACKGROUND: Color = Color("151e29")
const BACK_PANEL: Color = Color("1a2632")
const BACK_LINE: Color = Color("253340")
const SOLID_FILL: Color = Color("374650")
const SOLID_EDGE: Color = Color("9cacac")
const PLATFORM_FILL: Color = Color("48535b")
const AMBER: Color = Color("dba75b")
const MUTED_TEXT: Color = Color("7c929c")
const TARGET: Color = Color("df7969")

const SOLIDS: Array[Rect2] = [
	Rect2(0.0, 620.0, 1600.0, 100.0),
	Rect2(-24.0, -24.0, 24.0, 744.0),
	Rect2(1600.0, -24.0, 24.0, 744.0),
	Rect2(0.0, -24.0, 1600.0, 24.0),
	Rect2(572.0, 588.0, 48.0, 32.0),
	Rect2(1056.0, 572.0, 64.0, 48.0),
]
const PLATFORMS: Array[Rect2] = [
	Rect2(250.0, 552.0, 160.0, 12.0),
	Rect2(440.0, 484.0, 144.0, 12.0),
	Rect2(614.0, 416.0, 144.0, 12.0),
	Rect2(788.0, 348.0, 192.0, 12.0),
	Rect2(1010.0, 416.0, 144.0, 12.0),
	Rect2(1184.0, 484.0, 144.0, 12.0),
	Rect2(1358.0, 552.0, 160.0, 12.0),
]
const TARGET_POSITIONS: Array[Vector2] = [
	Vector2(48.0, 592.0),
	Vector2(342.0, 518.0),
	Vector2(510.0, 450.0),
	Vector2(698.0, 382.0),
	Vector2(890.0, 294.0),
	Vector2(1090.0, 382.0),
	Vector2(1260.0, 450.0),
	Vector2(1470.0, 518.0),
	Vector2(1550.0, 592.0),
]


func _ready() -> void:
	for index: int in range(SOLIDS.size()):
		_add_surface("Solid%d" % index, SOLIDS[index], false)
	for index: int in range(PLATFORMS.size()):
		_add_surface("Platform%d" % index, PLATFORMS[index], true)
	queue_redraw()


func _add_surface(surface_name: String, rect: Rect2, one_way: bool) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.name = surface_name
	body.position = rect.get_center()
	body.collision_layer = 16 if one_way else 1
	body.collision_mask = 0
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = rect.size
	var collider: CollisionShape2D = CollisionShape2D.new()
	collider.shape = shape
	collider.one_way_collision = one_way
	collider.one_way_collision_margin = 4.0
	body.add_child(collider)
	add_child(body)


func _draw() -> void:
	draw_rect(world_bounds, BACKGROUND)
	_draw_factory_background()
	for rect: Rect2 in SOLIDS:
		_draw_solid(rect)
	for rect: Rect2 in PLATFORMS:
		_draw_platform(rect)
	_draw_spawn()
	if not show_training_targets:
		return
	for index: int in range(TARGET_POSITIONS.size()):
		_draw_target(TARGET_POSITIONS[index], index + 1)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(264.0, 596.0), "01  /  SUBIR E DESCER", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, MUTED_TEXT)
	draw_string(font, Vector2(791.0, 322.0), "02  /  MIRA VERTICAL", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, MUTED_TEXT)
	draw_string(font, Vector2(1332.0, 596.0), "03  /  RETORNAR", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, MUTED_TEXT)


func _draw_factory_background() -> void:
	# Menor contraste e nenhuma borda de plataforma nas peças de fundo.
	for bay: int in range(8):
		var x: float = 22.0 + float(bay) * 200.0
		draw_rect(Rect2(x, 80.0, 172.0, 500.0), BACK_PANEL)
		draw_line(Vector2(x, 80.0), Vector2(x, 580.0), BACK_LINE, 2.0)
		draw_line(Vector2(x + 172.0, 80.0), Vector2(x + 172.0, 580.0), BACK_LINE, 2.0)
		for slat: int in range(4):
			draw_rect(Rect2(x + 24.0, 112.0 + float(slat) * 8.0, 124.0, 2.0), BACK_LINE)
		draw_rect(Rect2(x + 70.0, 188.0, 10.0, 322.0), BACK_LINE)
	draw_rect(Rect2(0.0, 52.0, 1600.0, 8.0), BACK_LINE)
	draw_rect(Rect2(0.0, 66.0, 1600.0, 3.0), BACK_LINE)
	for lamp: int in range(4):
		var x: float = 180.0 + float(lamp) * 400.0
		draw_rect(Rect2(x, 62.0, 32.0, 4.0), AMBER.darkened(0.35))


func _draw_solid(rect: Rect2) -> void:
	draw_rect(rect, SOLID_FILL)
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), SOLID_EDGE, 2.0)
	if rect.size.y <= 48.0:
		draw_rect(rect, SOLID_EDGE.darkened(0.35), false, 1.0)
		draw_line(rect.position + Vector2(5.0, 6.0), rect.end - Vector2(5.0, 5.0), SOLID_EDGE.darkened(0.4), 1.0)
	if rect.position.y == 620.0:
		for index: int in range(100):
			var x: float = float(index) * 16.0
			draw_rect(Rect2(x, 624.0, 8.0, 3.0), AMBER.darkened(0.35))
		draw_line(Vector2(0.0, 636.0), Vector2(1600.0, 636.0), BACKGROUND, 2.0)


func _draw_platform(rect: Rect2) -> void:
	draw_rect(rect, PLATFORM_FILL)
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), AMBER, 2.0)
	draw_line(Vector2(rect.position.x, rect.end.y), rect.end, SOLID_EDGE.darkened(0.55), 1.0)
	for index: int in range(int(rect.size.x / 24.0)):
		var x: float = rect.position.x + 8.0 + float(index) * 24.0
		draw_line(Vector2(x, rect.position.y + 4.0), Vector2(x + 6.0, rect.position.y + 9.0), SOLID_EDGE.darkened(0.4), 1.0)


func _draw_spawn() -> void:
	# Marca o piso seguro, sem criar checkpoint/sistema de progresso.
	draw_line(Vector2(92.0, 617.0), Vector2(148.0, 617.0), Color("7bb7af"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(74.0, 653.0), "INICIO", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, MUTED_TEXT)


func _draw_target(center: Vector2, number: int) -> void:
	# Retículo quadrado/anel diferencia alvo decorativo das superfícies sólidas.
	draw_rect(Rect2(center - Vector2(12.0, 12.0), Vector2(24.0, 24.0)), TARGET.darkened(0.55), false, 1.0)
	draw_arc(center, 7.0, 0.0, TAU, 16, TARGET, 1.0)
	draw_line(center + Vector2(-16.0, 0.0), center + Vector2(16.0, 0.0), TARGET, 1.0)
	draw_line(center + Vector2(0.0, -16.0), center + Vector2(0.0, 16.0), TARGET, 1.0)
	draw_circle(center, 2.0, TARGET)
	draw_string(ThemeDB.fallback_font, center + Vector2(19.0, 4.0), "%02d" % number, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, MUTED_TEXT)
