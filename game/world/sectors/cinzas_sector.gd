extends Node2D
## Cenários originais com colisão simples e layouts de encontro orientados a dados.
## Toda decoração é estática: sem luz dinâmica, partículas ou processamento por frame.

@export_range(0, 2) var sector_index: int = 0
var world_bounds: Rect2:
	get:
		return Rect2(0.0, 0.0, [1800.0, 2000.0, 1600.0][clampi(sector_index, 0, 2)], 720.0)
var spawn_position: Vector2 = Vector2(120.0, 550.0)
var navigation_links: Array[Dictionary] = []
var _platforms: Array[Rect2] = []
var _solids: Array[Rect2] = []

const AMBER: Color = Color("d5aa67")
const EDGE: Color = Color("acb9b5")
const TEXT: Color = Color("8c9e9d")


func _ready() -> void:
	sector_index = clampi(sector_index, 0, 2)
	_build_geometry()
	for index: int in range(_solids.size()):
		_add_surface("Solid%d" % index, _solids[index], false)
	for index: int in range(_platforms.size()):
		_add_surface("Walkway%d" % index, _platforms[index], true)
	_build_links()
	queue_redraw()


func _build_geometry() -> void:
	var width: float = world_bounds.size.x
	_solids = [Rect2(0.0, 620.0, width, 100.0), Rect2(-24.0, -24.0, 24.0, 744.0), Rect2(width, -24.0, 24.0, 744.0), Rect2(0.0, -24.0, width, 24.0)]
	match sector_index:
		0:
			_platforms = [Rect2(260, 552, 180, 12), Rect2(470, 484, 160, 12), Rect2(660, 416, 180, 12), Rect2(870, 348, 220, 12), Rect2(1120, 416, 180, 12), Rect2(1330, 484, 160, 12), Rect2(1520, 552, 170, 12)]
			_solids.append(Rect2(700, 588, 48, 32))
			_solids.append(Rect2(1250, 588, 48, 32))
		1:
			_platforms = [Rect2(260, 552, 180, 12), Rect2(470, 484, 180, 12), Rect2(680, 416, 180, 12), Rect2(890, 348, 250, 12), Rect2(1170, 416, 180, 12), Rect2(1380, 484, 180, 12), Rect2(1590, 552, 220, 12)]
			_solids.append(Rect2(900, 588, 48, 32))
			_solids.append(Rect2(1500, 588, 40, 32))
		2:
			# Centro sem obstáculos sólidos: espaço para ler e evitar o avanço de Chacal.
			_platforms = [Rect2(230, 552, 180, 12), Rect2(440, 484, 180, 12), Rect2(990, 484, 180, 12), Rect2(1200, 552, 180, 12)]


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


func _build_links() -> void:
	navigation_links.clear()
	if sector_index < 2:
		_link_route(_platforms, true, true)
	else:
		var west: Array[Rect2] = [_platforms[0], _platforms[1]]
		var east: Array[Rect2] = [_platforms[2], _platforms[3]]
		_link_route(west, true, false)
		_link_route(east, false, true)


func _link_route(route: Array[Rect2], ground_west: bool, ground_east: bool) -> void:
	if ground_west:
		_bidirectional_link(Vector2(route[0].position.x - 20.0, 620.0), route[0].position + Vector2(30.0, 0.0))
	for index: int in range(route.size() - 1):
		var from: Vector2 = Vector2(route[index].end.x - 15.0, route[index].position.y)
		var to: Vector2 = route[index + 1].position + Vector2(30.0, 0.0)
		_bidirectional_link(from, to)
	if ground_east:
		var last: Rect2 = route[route.size() - 1]
		_bidirectional_link(Vector2(last.end.x - 30.0, last.position.y), Vector2(last.end.x + 40.0, 620.0))


func _bidirectional_link(from: Vector2, to: Vector2) -> void:
	navigation_links.append({"from": from, "to": to})
	navigation_links.append({"from": to, "to": from})


func get_stage_layout(stage: int) -> Dictionary:
	var current: int = clampi(stage, 0, 6)
	var sector: int = 0 if current < 2 else (1 if current < 4 else 2)
	var layout: Dictionary = {
		"spawn": Vector2(120, 550), "trigger_x": 220.0,
		"enemies": [], "props": _props_for_sector(sector), "pickups": [],
		"exit_position": Vector2([1740.0, 1940.0, 1530.0][sector], 620.0),
		"terminal_position": Vector2(1530, 620), "secrets": _secrets_for_sector(sector),
	}
	match current:
		0:
			layout["enemies"] = [_entry("recruit", Vector2(450, 620))]
			layout["pickups"] = [_entry("ammo", Vector2(570, 484)), _entry("health", Vector2(760, 416))]
		1:
			layout["spawn"] = Vector2(800, 610)
			layout["trigger_x"] = 930.0
			layout["enemies"] = [_entry("recruit", Vector2(1210, 416)), _entry("scout", Vector2(1420, 620))]
			layout["pickups"] = [_entry("shotgun", Vector2(880, 620)), _entry("ammo", Vector2(1435, 484)), _entry("health", Vector2(1640, 552))]
		2:
			layout["trigger_x"] = 250.0
			layout["enemies"] = [_entry("recruit", Vector2(650, 620)), _entry("recruit", Vector2(820, 416)), _entry("scout", Vector2(1000, 620))]
			layout["pickups"] = [_entry("shotgun", Vector2(350, 620)), _entry("ammo", Vector2(560, 484)), _entry("health", Vector2(780, 416))]
		3:
			layout["spawn"] = Vector2(1050, 610)
			layout["trigger_x"] = 1200.0
			layout["enemies"] = [_entry("recruit", Vector2(1440, 484)), _entry("scout", Vector2(1700, 620)), _entry("recruit", Vector2(1860, 620))]
			layout["pickups"] = [_entry("ammo", Vector2(1140, 620)), _entry("health", Vector2(1260, 416)), _entry("ammo", Vector2(1740, 552))]
		4:
			layout["trigger_x"] = 350.0
			layout["enemies"] = [_entry("chacal", Vector2(1100, 620))]
			layout["pickups"] = [_entry("shotgun", Vector2(240, 620)), _entry("ammo", Vector2(560, 484)), _entry("health", Vector2(1280, 552)), _entry("ammo", Vector2(1440, 620))]
		5, 6:
			layout["spawn"] = Vector2(1250, 550)
			layout["trigger_x"] = 1500.0
			layout["pickups"] = [_entry("health", Vector2(1430, 620))]
	return layout


func _entry(kind: String, position: Vector2) -> Dictionary:
	return {"kind": kind, "position": position}


func _props_for_sector(sector: int) -> Array[Dictionary]:
	match sector:
		0:
			return [_entry("crate", Vector2(350, 620)), _entry("crate", Vector2(550, 620)), _entry("barrel", Vector2(980, 620)), _entry("glass", Vector2(1030, 348)), _entry("crate", Vector2(1350, 620)), _entry("barrel", Vector2(1550, 620)), _entry("crate", Vector2(1560, 552)), _entry("glass", Vector2(1670, 552))]
		1:
			return [_entry("crate", Vector2(430, 620)), _entry("barrel", Vector2(720, 620)), _entry("glass", Vector2(970, 348)), _entry("crate", Vector2(1180, 620)), _entry("barrel", Vector2(1350, 620)), _entry("crate", Vector2(1570, 620)), _entry("barrel", Vector2(1780, 620)), _entry("glass", Vector2(1760, 552))]
		_:
			return [_entry("crate", Vector2(300, 620)), _entry("crate", Vector2(380, 552)), _entry("glass", Vector2(520, 484)), _entry("barrel", Vector2(720, 620)), _entry("barrel", Vector2(1320, 620)), _entry("glass", Vector2(1060, 484)), _entry("crate", Vector2(1350, 552)), _entry("crate", Vector2(1130, 484))]


func _secrets_for_sector(sector: int) -> Array[Dictionary]:
	match sector:
		0:
			return [{"id": "ruins_cache", "position": Vector2(940, 348), "text": "Lote A-17: corpos registrados como sucata. Lia reconhece nomes de colegas nas listas."}]
		1:
			return [{"id": "yard_manifest", "position": Vector2(1080, 348), "text": "O manifesto chama armas de suprimentos. Um carregador marcou as remessas para a resistência."}]
		_:
			return []


func _palette() -> Array[Color]:
	match sector_index:
		0:
			return [Color("131d25"), Color("1b2932"), Color("293c43"), Color("3d4b4f"), Color("875f48"), Color("6e9995")]
		1:
			return [Color("131f24"), Color("1a3035"), Color("2a4246"), Color("405259"), Color("8c7151"), Color("7da79b")]
		_:
			return [Color("1d1c27"), Color("2b2936"), Color("3c3948"), Color("4c4b58"), Color("8d5c58"), Color("b09583")]


func _draw() -> void:
	var palette: Array[Color] = _palette()
	draw_rect(world_bounds, palette[0])
	_draw_distant_silhouette(palette)
	_draw_factory_bays(palette)
	_draw_sector_identity(palette)
	for rect: Rect2 in _solids:
		_draw_solid(rect, palette)
	for rect: Rect2 in _platforms:
		_draw_walkway(rect, palette)
	_draw_floor_details(palette)
	if sector_index < 2:
		_draw_exit(palette)


func _draw_distant_silhouette(palette: Array[Color]) -> void:
	var width: float = world_bounds.size.x
	for index: int in range(int(width / 120.0) + 1):
		var x: float = float(index) * 120.0
		var height: float = 80.0 + float((index * 43 + sector_index * 31) % 120)
		draw_rect(Rect2(x, 300.0 - height, 112.0, height + 280.0), palette[1])
		if index % 3 == 0:
			draw_rect(Rect2(x + 68.0, 70.0, 20.0, 220.0), palette[1])
		for window: int in range(3):
			draw_rect(Rect2(x + 14.0 + float(window) * 26.0, 282.0 - height, 13.0, 6.0), palette[2].darkened(0.35))
	# Cabos com queda: segmentos fixos, sem simulação de cordas.
	for span: int in range(int(width / 320.0) + 1):
		var x: float = float(span) * 320.0
		var cable: PackedVector2Array = PackedVector2Array([Vector2(x, 64), Vector2(x + 80, 93), Vector2(x + 160, 105), Vector2(x + 240, 93), Vector2(x + 320, 64)])
		draw_polyline(cable, palette[2], 2.0)


func _draw_factory_bays(palette: Array[Color]) -> void:
	var width: float = world_bounds.size.x
	for bay: int in range(int(width / 240.0) + 1):
		var x: float = float(bay) * 240.0
		draw_rect(Rect2(x + 14.0, 156.0, 210.0, 438.0), palette[1].lightened(0.025))
		_draw_wall_material(Vector2(x + 22, 372), bay + sector_index * 13, palette)
		draw_rect(Rect2(x + 20.0, 180.0, 198.0, 94.0), palette[0].lightened(0.02))
		for pane: int in range(6):
			var pane_x: float = x + 26.0 + float(pane) * 31.0
			draw_rect(Rect2(pane_x, 187.0, 25.0, 78.0), palette[2].darkened(0.25))
			if (bay + pane) % 4 == 0:
				draw_rect(Rect2(pane_x + 3.0, 194.0, 19.0, 60.0), palette[5].darkened(0.67))
		draw_line(Vector2(x + 20.0, 224.0), Vector2(x + 218.0, 224.0), palette[1], 3.0)
		draw_rect(Rect2(x + 2.0, 104.0, 8.0, 490.0), palette[2])
		draw_rect(Rect2(x + 11.0, 104.0, 3.0, 490.0), palette[0])
		# Tubulação de fundo: tom baixo e sem aresta clara de piso.
		draw_line(Vector2(x + 203.0, 300.0), Vector2(x + 203.0, 584.0), palette[2], 6.0)
		draw_line(Vector2(x + 203.0, 300.0), Vector2(x + 158.0, 300.0), palette[2], 6.0)
		for joint_y: float in [320.0, 412.0, 520.0]:
			draw_rect(Rect2(x + 198.0, joint_y, 10.0, 3.0), palette[3].darkened(0.25))
		# Detalhes baixos permanecem visíveis na câmera de combate, com contraste de fundo.
		draw_rect(Rect2(x + 32, 382, 104, 132), palette[2].darkened(0.45))
		draw_rect(Rect2(x + 33, 383, 102, 2), palette[3].darkened(0.4))
		draw_rect(Rect2(x + 133, 386, 2, 126), palette[0])
		for bolt: Vector2 in [Vector2(36, 386), Vector2(130, 386), Vector2(36, 507), Vector2(130, 507)]:
			draw_rect(Rect2(Vector2(x, 0) + bolt, Vector2(2, 2)), palette[3].darkened(0.3))
		draw_rect(Rect2(x + 39, 389, 90, 30), palette[0].lightened(0.02))
		for vent: int in range(5):
			draw_line(Vector2(x + 45, 394 + vent * 5), Vector2(x + 122, 394 + vent * 5), palette[2].darkened(0.18), 2)
		draw_rect(Rect2(x + 43, 435, 6, 50), palette[4].darkened(0.55))
		draw_rect(Rect2(x + 53, 435, 45, 24), palette[0].lightened(0.02))
		draw_rect(Rect2(x + 57, 439, 14, 2), palette[5].darkened(0.47))
		draw_rect(Rect2(x + 57, 444, 26, 2), palette[2])
		draw_rect(Rect2(x + 57, 449, 19, 2), palette[2])
		draw_rect(Rect2(x + 107, 441, 3, 3), AMBER.darkened(0.55))
		draw_rect(Rect2(x + 109, 471, 6, 8), palette[0])
		draw_rect(Rect2(x + 110, 472, 3, 4), palette[3].darkened(0.2))
		draw_string(ThemeDB.fallback_font, Vector2(x + 57, 493), "VT / %03d" % (bay + sector_index * 20), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, palette[3].darkened(0.12))
		draw_line(Vector2(x + 140, 548), Vector2(x + 186, 548), palette[2], 4)
		draw_rect(Rect2(x + 154, 535, 14, 21), palette[2])
		# Arandela baixa visível durante combate, com halo de apenas poucos pixels.
		draw_rect(Rect2(x + 174, 366, 19, 14), palette[0])
		draw_rect(Rect2(x + 177, 369, 13, 7), palette[4].darkened(0.4))
		draw_rect(Rect2(x + 179, 370, 9, 3), AMBER.darkened(0.2))
		draw_rect(Rect2(x + 179, 377, 9, 2), palette[4].darkened(0.6))
		var lamp_x: float = x + 116.0
		draw_line(Vector2(lamp_x, 108), Vector2(lamp_x, 139), palette[2], 2.0)
		draw_rect(Rect2(lamp_x - 18.0, 140.0, 36.0, 6.0), palette[3])
		draw_rect(Rect2(lamp_x - 14.0, 146.0, 28.0, 3.0), AMBER.darkened(0.15))
		var cone: PackedVector2Array = PackedVector2Array([Vector2(lamp_x - 12, 149), Vector2(lamp_x + 12, 149), Vector2(lamp_x + 66, 335), Vector2(lamp_x - 66, 335)])
		draw_colored_polygon(cone, Color(0.8, 0.64, 0.39, 0.035))


func _draw_wall_material(at: Vector2, seed_value: int, palette: Array[Color]) -> void:
	# Clusters de 2–16 px, repetíveis por módulo: sem RNG ou ruído por pixel.
	for cluster: int in range(7):
		var key: int = seed_value * 17 + cluster * 43
		var local: Vector2 = Vector2(float((key * 7) % 174), float((key * 11) % 214))
		var width: float = 5.0 + float(key % 12)
		var base: Color = palette[2].darkened(0.4) if cluster % 3 != 0 else palette[4].darkened(0.67)
		draw_rect(Rect2(at + local, Vector2(width, 2)), base)
		draw_rect(Rect2(at + local + Vector2(2, 2), Vector2(maxf(2.0, width - 5.0), 3)), base.darkened(0.15))
		if cluster % 3 == 0:
			draw_rect(Rect2(at + local + Vector2(3, 5), Vector2(2, 7 + key % 8)), palette[4].darkened(0.73))
	# Juntas quebradas ficam escuras e verticais, sem sugerir um piso transitável.
	draw_rect(Rect2(at + Vector2(153, 20), Vector2(1, 56)), palette[0])
	draw_rect(Rect2(at + Vector2(151, 75), Vector2(3, 1)), palette[0])
	draw_rect(Rect2(at + Vector2(151, 76), Vector2(1, 21)), palette[0])


func _draw_sector_identity(palette: Array[Color]) -> void:
	match sector_index:
		0:
			for pile: int in range(9):
				var x: float = 72.0 + float(pile) * 192.0
				var points: PackedVector2Array = PackedVector2Array([Vector2(x - 54, 609), Vector2(x - 42, 582), Vector2(x - 18, 594), Vector2(x + 4, 564), Vector2(x + 22, 589), Vector2(x + 50, 576), Vector2(x + 62, 609)])
				draw_colored_polygon(points, palette[2].darkened(0.2))
				draw_line(Vector2(x - 34, 600), Vector2(x + 30, 579), palette[4].darkened(0.5), 4.0)
				draw_rect(Rect2(x - 16, 583, 18, 4), palette[4].darkened(0.48))
				draw_rect(Rect2(x - 12, 587, 12, 2), palette[0])
				draw_rect(Rect2(x + 24, 592, 17, 7), palette[1])
				for tooth: int in range(3):
					draw_rect(Rect2(x + 27 + tooth * 5, 590, 2, 3), palette[3].darkened(0.45))
			_draw_sign(Vector2(66, 458), "DESCARTE / A-17", palette)
			_draw_sign(Vector2(1120, 526), "REGISTROS DE BAIXA", palette)
			draw_string(ThemeDB.fallback_font, Vector2(790, 582), "OS NOMES AINDA ESTAO AQUI", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, palette[5].darkened(0.25))
		1:
			# Contêineres são fundo recuado; não usam bordas claras das colisões.
			for container: int in range(5):
				var x: float = 72.0 + float(container) * 390.0
				draw_rect(Rect2(x, 446, 300, 154), palette[2].darkened(0.16))
				for rib: int in range(13):
					draw_line(Vector2(x + 12 + rib * 22, 456), Vector2(x + 12 + rib * 22, 588), palette[1], 3.0)
					draw_rect(Rect2(x + 14 + rib * 22, 458, 1, 126), palette[3].darkened(0.55))
				for latch: float in [46.0, 250.0]:
					draw_rect(Rect2(x + latch, 492, 3, 82), palette[3].darkened(0.35))
					draw_rect(Rect2(x + latch - 3, 532, 9, 3), palette[4].darkened(0.4))
					draw_rect(Rect2(x + latch - 1, 583, 5, 5), palette[0])
				for chip: int in range(4):
					var chip_x: float = x + 22 + ((container * 17 + chip * 61) % 250)
					var chip_y: float = 502 + ((container * 11 + chip * 29) % 81)
					draw_rect(Rect2(chip_x, chip_y, 9 + chip * 2, 2), palette[4].darkened(0.57))
					draw_rect(Rect2(chip_x + 3, chip_y + 2, 3, 5), palette[4].darkened(0.68))
				draw_string(ThemeDB.fallback_font, Vector2(x + 22, 478), "VT / CARGA %02d" % (17 + container), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, palette[5].darkened(0.36))
			draw_line(Vector2(980, 96), Vector2(980, 300), palette[4].darkened(0.22), 8.0)
			draw_line(Vector2(830, 100), Vector2(1140, 100), palette[4].darkened(0.22), 10.0)
			draw_line(Vector2(1120, 107), Vector2(1120, 214), palette[2], 2.0)
			draw_arc(Vector2(1120, 220), 8, 0, PI, 10, palette[3], 3)
			_draw_sign(Vector2(66, 358), "PATIO / LOGISTICA", palette)
			_draw_sign(Vector2(1500, 360), "REMESSAS SOB ESCOLTA", palette)
		2:
			# Emblema geométrico original e grades fechadas reforçam a arena fixa.
			var emblem: PackedVector2Array = PackedVector2Array([Vector2(800, 180), Vector2(882, 264), Vector2(849, 264), Vector2(800, 215), Vector2(751, 264), Vector2(718, 264)])
			draw_colored_polygon(emblem, palette[4].darkened(0.25))
			draw_string(ThemeDB.fallback_font, Vector2(725, 298), "VERTICE / SEGURANCA", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, TEXT.darkened(0.1))
			for side_x: float in [28.0, 1400.0]:
				draw_rect(Rect2(side_x, 390, 170, 218), palette[0])
				for bar: int in range(9):
					draw_line(Vector2(side_x + 9 + bar * 19, 395), Vector2(side_x + 9 + bar * 19, 606), palette[2], 3)
					draw_rect(Rect2(side_x + 8 + bar * 19, 397, 1, 204), palette[3].darkened(0.35))
				draw_line(Vector2(side_x, 470), Vector2(side_x + 170, 470), palette[2], 3)
			_draw_sign(Vector2(666, 505), "PONTO DE CONTROLE / 07", palette)


func _draw_sign(at: Vector2, label: String, palette: Array[Color]) -> void:
	var width: float = maxf(150.0, label.length() * 7.0 + 20.0)
	draw_rect(Rect2(at, Vector2(width, 29)), palette[0])
	draw_rect(Rect2(at, Vector2(4, 29)), palette[4])
	draw_string(ThemeDB.fallback_font, at + Vector2(12, 19), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TEXT)


func _draw_solid(rect: Rect2, palette: Array[Color]) -> void:
	draw_rect(rect, palette[3])
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1)), EDGE)
	draw_rect(Rect2(rect.position + Vector2(0, 1), Vector2(rect.size.x, 3)), palette[3].lightened(0.12))
	if rect.size.y <= 40.0:
		draw_rect(Rect2(rect.position, Vector2(1, rect.size.y)), EDGE.darkened(0.3))
		draw_rect(Rect2(rect.end - Vector2(3, rect.size.y - 2), Vector2(3, rect.size.y - 2)), palette[0])
		for scratch: int in range(3):
			var point: Vector2 = rect.position + Vector2(8 + scratch * 9, 9 + scratch % 2 * 6)
			draw_rect(Rect2(point, Vector2(6, 2)), palette[4].darkened(0.15))
			draw_rect(Rect2(point + Vector2(2, 2), Vector2(2, 4)), palette[4].darkened(0.4))
		draw_rect(Rect2(rect.position + Vector2(4, 5), Vector2(2, 2)), EDGE)
		draw_rect(Rect2(rect.end - Vector2(7, 7), Vector2(2, 2)), EDGE.darkened(0.2))


func _draw_walkway(rect: Rect2, palette: Array[Color]) -> void:
	# Apenas o topo âmbar comunica colisão unilateral. Suportes ficam no fundo.
	draw_line(rect.position + Vector2(12, 12), rect.position + Vector2(12, 32), palette[2], 3.0)
	draw_line(Vector2(rect.end.x - 12, rect.end.y), Vector2(rect.end.x - 12, rect.end.y + 20), palette[2], 3.0)
	draw_rect(rect, palette[3])
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1)), AMBER)
	draw_rect(Rect2(rect.position + Vector2(0, 1), Vector2(rect.size.x, 2)), AMBER.darkened(0.45))
	draw_line(Vector2(rect.position.x, rect.end.y), rect.end, palette[0], 2.0)
	for module: int in range(int(rect.size.x / 24.0)):
		var x: float = rect.position.x + 8 + module * 24
		draw_line(Vector2(x, rect.position.y + 4), Vector2(x + 7, rect.position.y + 9), EDGE.darkened(0.4), 1.0)
		draw_rect(Rect2(x + 12, rect.position.y + 5, 2, 2), EDGE.darkened(0.25))
		if module % 3 == 1:
			draw_rect(Rect2(x + 3, rect.position.y + 8, 7, 2), palette[4].darkened(0.25))


func _draw_floor_details(palette: Array[Color]) -> void:
	var width: float = world_bounds.size.x
	for tile: int in range(int(width / 32.0)):
		var x: float = tile * 32.0
		draw_line(Vector2(x, 638), Vector2(x, 710), palette[2], 1.0)
		draw_rect(Rect2(x + 4, 624, 12, 3), AMBER.darkened(0.28))
		if tile % 4 == 0:
			draw_line(Vector2(x + 6, 654), Vector2(x + 24, 654), palette[0], 2.0)
			draw_rect(Rect2(x + 5, 646, 3, 2), EDGE.darkened(0.3))
			draw_rect(Rect2(x + 21, 646, 3, 2), EDGE.darkened(0.3))
		var chip_y: float = 664 + (tile * 11) % 36
		draw_rect(Rect2(x + 7, chip_y, 8 + tile % 3 * 3, 2), palette[2])
		draw_rect(Rect2(x + 10, chip_y + 2, 4, 3), palette[3].darkened(0.12))
	draw_line(Vector2(0, 636), Vector2(width, 636), palette[0], 3.0)
	draw_line(Vector2(0, 682), Vector2(width, 682), palette[2], 2.0)
	draw_line(Vector2(92, 617), Vector2(148, 617), Color("7bb7af"), 2.0)


func _draw_exit(palette: Array[Color]) -> void:
	var x: float = world_bounds.end.x - 62.0
	draw_rect(Rect2(x - 18, 532, 58, 86), palette[0])
	draw_line(Vector2(x - 18, 532), Vector2(x + 40, 532), palette[5], 3.0)
	draw_line(Vector2(x - 18, 532), Vector2(x - 18, 618), palette[3], 4.0)
	draw_line(Vector2(x + 40, 532), Vector2(x + 40, 618), palette[3], 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(x - 20, 519), "SAIDA >", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, palette[5])
