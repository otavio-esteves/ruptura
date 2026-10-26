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

const AMBER: Color = Color("bba071")
const EDGE: Color = Color("959d9d")
const TEXT: Color = Color("828985")


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
			return [{"id": "ruins_cache", "position": Vector2(940, 348), "text": "Ata reservada A-17: o conselho aprovou execuções como desligamentos. A assinatura da diretoria prova quem deu as ordens."}]
		1:
			return [{"id": "yard_manifest", "position": Vector2(1080, 348), "text": "Contrato de operações: metas de lucro exigem trabalho compulsório. A cláusula foi assinada pela classe executiva e ocultada dos trabalhadores."}]
		_:
			return []


func _palette() -> Array[Color]:
	# Carvão, vidro cinza e madeira dessaturada; a faixa atrás do terno evita preto sobre preto.
	match sector_index:
		0:
			return [Color("11151a"), Color("1c2127"), Color("2a3035"), Color("3a4145"), Color("645549"), Color("747c70")]
		1:
			return [Color("101519"), Color("1b2227"), Color("293238"), Color("394247"), Color("5e594a"), Color("76847a")]
		_:
			return [Color("141518"), Color("232326"), Color("323235"), Color("414246"), Color("635149"), Color("878373")]


func _draw() -> void:
	var palette: Array[Color] = _palette()
	draw_rect(world_bounds, palette[0])
	_draw_distant_silhouette(palette)
	_draw_office_bays(palette)
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
	# Cidade noturna atrás das janelas; os prédios nunca recebem arestas de colisão.
	for index: int in range(int(width / 96.0) + 1):
		var x: float = float(index) * 96.0
		var height: float = 70.0 + float((index * 43 + sector_index * 31) % 130)
		draw_rect(Rect2(x, 330.0 - height, 86.0, height), palette[1].darkened(0.22))
		for window: int in range(6):
			var wx: float = x + 10 + (window % 3) * 25
			var wy: float = 344.0 - height + floorf(float(window) / 3.0) * 30
			draw_rect(Rect2(wx, wy, 8, 4), palette[5].darkened(0.66 if (index + window) % 3 == 0 else 0.82))


func _draw_office_bays(palette: Array[Color]) -> void:
	var width: float = world_bounds.size.x
	# Parede cinza contínua no plano recuado: o executivo preto mantém silhueta até os pés.
	draw_rect(Rect2(0, 336, width, 284), palette[1].lightened(0.035))
	draw_rect(Rect2(0, 576, width, 33), palette[2].darkened(0.03))
	draw_rect(Rect2(0, 610, width, 10), palette[1])
	for bay: int in range(int(width / 240.0) + 1):
		var x: float = float(bay) * 240.0
		# Caixilhos e persianas em contraste baixo; sem faixas âmbar decorativas.
		draw_rect(Rect2(x + 12, 156, 212, 184), palette[1])
		draw_rect(Rect2(x + 19, 163, 198, 169), palette[0])
		for pane: int in range(4):
			var pane_x: float = x + 23 + pane * 48
			draw_rect(Rect2(pane_x, 169, 43, 156), palette[1].darkened(0.18))
			for city_light: int in range(4):
				draw_rect(Rect2(pane_x + 7 + city_light % 2 * 19, 229 + (bay * 13 + pane * 23 + city_light * 29) % 81, 4, 2), palette[5].darkened(0.6))
			for blind: int in range(7):
				draw_rect(Rect2(pane_x, 174 + blind * 8, 43, 2), palette[2].darkened(0.35))
			draw_rect(Rect2(pane_x + 5, 170, 1, 54), palette[3].darkened(0.5))
		draw_rect(Rect2(x + 7, 336, 3, 274), palette[2])
		_draw_wall_material(Vector2(x + 22, 382), bay + sector_index * 13, palette)
		# Luminárias embutidas frias e leitores de crachá discretos.
		draw_rect(Rect2(x + 72, 119, 106, 7), palette[1])
		draw_rect(Rect2(x + 78, 121, 94, 2), palette[3].darkened(0.16))
		draw_rect(Rect2(x + 207, 450, 12, 21), palette[0])
		draw_rect(Rect2(x + 209, 452, 8, 8), palette[2])
		draw_rect(Rect2(x + 211, 455, 4, 1), palette[5].darkened(0.25))
		draw_rect(Rect2(x + 210, 465, 6, 2), palette[3].darkened(0.2))
		if sector_index == 1 or bay % 3 == 1:
			_draw_workstation(Vector2(x + 38, 500), palette, bay)
		elif sector_index == 0:
			_draw_filing_cabinet(Vector2(x + 38, 444), palette, bay)
		else:
			_draw_partition(Vector2(x + 25, 382), palette)


func _draw_wall_material(at: Vector2, seed_value: int, palette: Array[Color]) -> void:
	# Pintura e juntas: poucos clusters determinísticos, sem sujeira industrial dominante.
	for cluster: int in range(4):
		var key: int = seed_value * 17 + cluster * 43
		var local: Vector2 = Vector2(float((key * 7) % 174), float((key * 11) % 172))
		draw_rect(Rect2(at + local, Vector2(5 + key % 8, 1)), palette[2].darkened(0.24))
		draw_rect(Rect2(at + local + Vector2(2, 1), Vector2(3, 2)), palette[1])
	draw_rect(Rect2(at + Vector2(153, 8), Vector2(1, 177)), palette[0].lightened(0.02))


func _draw_workstation(at: Vector2, palette: Array[Color], index: int) -> void:
	# Mesas ao fundo, com pés e cadeiras visíveis; tampo sem a aresta clara do piso real.
	draw_rect(Rect2(at + Vector2(0, 48), Vector2(133, 6)), palette[4].darkened(0.33))
	draw_rect(Rect2(at + Vector2(5, 54), Vector2(4, 38)), palette[2])
	draw_rect(Rect2(at + Vector2(120, 54), Vector2(4, 38)), palette[2])
	draw_rect(Rect2(at + Vector2(38, 10), Vector2(52, 34)), palette[0])
	draw_rect(Rect2(at + Vector2(41, 13), Vector2(46, 27)), palette[2].darkened(0.2))
	for row: int in range(4):
		draw_rect(Rect2(at + Vector2(45, 18 + row * 5), Vector2(15 + (index + row) % 3 * 7, 1)), palette[5].darkened(0.2 if row == 0 else 0.45))
	draw_rect(Rect2(at + Vector2(61, 44), Vector2(7, 4)), palette[2])
	draw_rect(Rect2(at + Vector2(43, 55), Vector2(27, 28)), palette[0])
	draw_rect(Rect2(at + Vector2(45, 57), Vector2(23, 22)), palette[2].darkened(0.15))
	draw_rect(Rect2(at + Vector2(40, 81), Vector2(33, 5)), palette[2])
	draw_rect(Rect2(at + Vector2(55, 86), Vector2(3, 10)), palette[0])
	draw_rect(Rect2(at + Vector2(44, 94), Vector2(26, 2)), palette[0])
	draw_rect(Rect2(at + Vector2(83, 46), Vector2(24, 2)), palette[3].darkened(0.2))
	draw_rect(Rect2(at + Vector2(9, 43), Vector2(14, 4)), palette[5].darkened(0.25))
	draw_rect(Rect2(at + Vector2(13, 44), Vector2(6, 1)), palette[1])


func _draw_filing_cabinet(at: Vector2, palette: Array[Color], index: int) -> void:
	draw_rect(Rect2(at, Vector2(99, 148)), palette[0])
	draw_rect(Rect2(at + Vector2(2, 2), Vector2(95, 144)), palette[2].darkened(0.09))
	for drawer: int in range(4):
		var y: float = 5 + drawer * 34
		draw_rect(Rect2(at + Vector2(5, y), Vector2(88, 31)), palette[1].lightened(0.025))
		draw_rect(Rect2(at + Vector2(38, y + 15), Vector2(22, 2)), palette[3].darkened(0.1))
		draw_rect(Rect2(at + Vector2(10, y + 7), Vector2(19, 8)), palette[4].darkened(0.15))
		draw_rect(Rect2(at + Vector2(13, y + 10), Vector2(13, 1)), palette[5].darkened(0.15))
	draw_string(ThemeDB.fallback_font, at + Vector2(10, -7), "ARQ. %02d" % (17 + index), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, palette[5].darkened(0.15))


func _draw_partition(at: Vector2, palette: Array[Color]) -> void:
	draw_rect(Rect2(at, Vector2(153, 214)), palette[2].darkened(0.15))
	draw_rect(Rect2(at + Vector2(3, 3), Vector2(147, 208)), palette[1].lightened(0.015))
	for blind: int in range(16):
		draw_rect(Rect2(at + Vector2(7, 12 + blind * 7), Vector2(139, 1)), palette[2].darkened(0.2))
	draw_rect(Rect2(at + Vector2(78, 3), Vector2(2, 208)), palette[2])
	draw_rect(Rect2(at + Vector2(130, 143), Vector2(8, 2)), palette[3].darkened(0.1))


func _draw_sector_identity(palette: Array[Color]) -> void:
	match sector_index:
		0:
			_draw_sign(Vector2(58, 382), "VÉRTICE / ARQUIVO MORTO", palette)
			_draw_sign(Vector2(1110, 382), "ATAS / ACESSO RESTRITO", palette)
			draw_string(ThemeDB.fallback_font, Vector2(775, 536), "RETENÇÃO DOCUMENTAL · DIRETORIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, palette[5].darkened(0.12))
		1:
			_draw_sign(Vector2(58, 382), "VÉRTICE / OPERAÇÕES", palette)
			_draw_sign(Vector2(1400, 382), "CONTRATOS / COMPLIANCE", palette)
			for screen: int in range(3):
				var x: float = 870 + screen * 79
				draw_rect(Rect2(x, 273, 72, 49), palette[0])
				draw_rect(Rect2(x + 3, 276, 66, 43), palette[2])
				for bar: int in range(4):
					draw_rect(Rect2(x + 8 + bar * 12, 310 - (bar + screen) % 4 * 7, 7, 5 + (bar + screen) % 4 * 7), palette[5].darkened(0.22))
			_draw_sign(Vector2(870, 382), "CENTRO DE OPERAÇÕES", palette)
		2:
			var emblem: PackedVector2Array = PackedVector2Array([Vector2(800, 180), Vector2(882, 264), Vector2(849, 264), Vector2(800, 215), Vector2(751, 264), Vector2(718, 264)])
			draw_colored_polygon(emblem, palette[4].darkened(0.15))
			draw_string(ThemeDB.fallback_font, Vector2(697, 298), "VÉRTICE / CONSELHO EXECUTIVO", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, palette[5])
			# Mesa de conselho e cadeiras no recuo; corredor de combate permanece intacto.
			for chair: int in range(5):
				var x: float = 605 + chair * 80
				draw_rect(Rect2(x, 471, 29, 57), palette[0])
				draw_rect(Rect2(x + 2, 473, 25, 40), palette[2])
				draw_rect(Rect2(x - 3, 516, 35, 5), palette[2])
			draw_rect(Rect2(570, 532, 460, 9), palette[4].darkened(0.18))
			draw_rect(Rect2(586, 541, 11, 52), palette[2])
			draw_rect(Rect2(1005, 541, 11, 52), palette[2])
			for folder: int in range(4):
				draw_rect(Rect2(640 + folder * 84, 529, 26, 2), palette[5].darkened(0.08))
			_draw_sign(Vector2(60, 382), "SEGURANÇA / DIRETORIAS", palette)
			_draw_sign(Vector2(1240, 382), "SESSÃO CONFIDENCIAL", palette)


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
		draw_rect(Rect2(x + 4, 624, 12, 2), palette[3].lightened(0.12))
		if tile % 4 == 0:
			draw_line(Vector2(x + 6, 654), Vector2(x + 24, 654), palette[0], 2.0)
			draw_rect(Rect2(x + 5, 646, 3, 2), EDGE.darkened(0.3))
			draw_rect(Rect2(x + 21, 646, 3, 2), EDGE.darkened(0.3))
		var chip_y: float = 664 + (tile * 11) % 36
		draw_rect(Rect2(x + 7, chip_y, 8 + tile % 3 * 3, 2), palette[2])
		draw_rect(Rect2(x + 10, chip_y + 2, 4, 3), palette[3].darkened(0.12))
	draw_line(Vector2(0, 636), Vector2(width, 636), palette[0], 3.0)
	draw_line(Vector2(0, 682), Vector2(width, 682), palette[2], 2.0)
	draw_line(Vector2(92, 617), Vector2(148, 617), Color("90998d"), 2.0)


func _draw_exit(palette: Array[Color]) -> void:
	var x: float = world_bounds.end.x - 62.0
	draw_rect(Rect2(x - 18, 532, 58, 86), palette[0])
	draw_line(Vector2(x - 18, 532), Vector2(x + 40, 532), palette[5], 3.0)
	draw_line(Vector2(x - 18, 532), Vector2(x - 18, 618), palette[3], 4.0)
	draw_line(Vector2(x + 40, 532), Vector2(x + 40, 618), palette[3], 4.0)
	draw_string(ThemeDB.fallback_font, Vector2(x - 20, 519), "SAIDA >", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, palette[5])
