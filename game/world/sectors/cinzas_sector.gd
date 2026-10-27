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
const TEXT: Color = Color("b7b2a1")
const ENVIRONMENT_PATHS: Array[String] = [
	"res://assets/art/environments/archive-lobby-v1.png",
	"res://assets/art/environments/operations-floor-v1.png",
	"res://assets/art/environments/boardroom-floor-v1.png",
]
static var _environment_cache: Dictionary = {}
var _environment: Texture2D
var _environment_variants: Array[Texture2D] = []
var _environment_panels: Array[Dictionary] = []


func _ready() -> void:
	sector_index = clampi(sector_index, 0, 2)
	_load_environment()
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
	# Fundo de vidro azulado e reboco taupe. O terno carvão recorta contra ambos.
	match sector_index:
		0:
			return [Color("151a20"), Color("303b45"), Color("45464a"), Color("666566"), Color("705442"), Color("b2aa94")]
		1:
			return [Color("141b23"), Color("2c3e4c"), Color("3b454b"), Color("62686b"), Color("665344"), Color("a0b2ae")]
		_:
			return [Color("19191f"), Color("343d48"), Color("484346"), Color("726967"), Color("765342"), Color("bcae91")]


func _draw() -> void:
	var palette: Array[Color] = _palette()
	draw_rect(world_bounds, palette[0])
	if _environment != null:
		_draw_painted_offices(palette)
	else:
		_draw_office_bays(palette)
	_draw_sector_identity(palette)
	for rect: Rect2 in _solids:
		_draw_solid(rect, palette)
	for rect: Rect2 in _platforms:
		_draw_walkway(rect, palette)
	_draw_floor_details(palette)
	if sector_index < 2:
		_draw_exit(palette)


func _load_environment() -> void:
	_environment_variants.clear()
	for path: String in ENVIRONMENT_PATHS:
		if not _environment_cache.has(path) and ResourceLoader.exists(path):
			_environment_cache[path] = load(path) as Texture2D
		_environment_variants.append(_environment_cache.get(path) as Texture2D)
	_environment = _environment_variants[sector_index]
	if _environment == null: _environment = _environment_variants[0]
	if _environment == null: return
	for index: int in range(_environment_variants.size()):
		if _environment_variants[index] == null: _environment_variants[index] = _environment
	# Zonas de largura e composição diferentes evitam um lobby que reinicia a cada434px.
	var choices: Array = [[0, 1, 0, 2, 1, 0], [1, 1, 1, 0, 1, 1], [2, 2, 2, 2, 2, 2]][sector_index]
	var starts: Array[float] = [0.0, 0.22, 0.06, 0.40, 0.0, 0.44]
	var widths: Array[float] = [1.0, 0.78, 0.69, 0.60, 0.72, 0.56]
	if sector_index == 2:
		# O centro do conselho é uma mesa contínua, sem balcão de recepção no duelo.
		starts = [0.0, 0.285, 0.31, 0.285, 0.31, 0.285]
		widths = [1.0, 0.38, 0.35, 0.38, 0.35, 0.38]
	var cursor: float = 0.0
	var zone: int = 0
	_environment_panels.clear()
	while cursor < world_bounds.size.x:
		var recipe: int = zone % choices.size()
		var texture: Texture2D = _environment_variants[int(choices[recipe])]
		var size: Vector2 = texture.get_size()
		var source_x: float = floorf(size.x * starts[recipe])
		var source_width: float = minf(size.x - source_x, size.x * widths[recipe])
		var width: float = minf(snappedf(source_width * 0.2, 0.5), world_bounds.size.x - cursor)
		_environment_panels.append({"texture": texture, "source_x": source_x, "source_width": width / 0.2, "x": cursor, "width": width, "choice": int(choices[recipe])})
		cursor += width
		zone += 1


func _draw_painted_offices(_palette: Array[Color]) -> void:
	# Vãos arquitetônicos contínuos usam apenas vidro/colunas do bitmap.
	# Os andares recuados não contêm piso e não criam salas em caixas flutuantes.
	for row: int in range(5):
		var top: float = -18.0 + row * 106.0
		var tint := Color(0.50, 0.57, 0.64) if row < 4 else Color(0.64, 0.68, 0.73)
		for panel: Dictionary in _environment_panels:
			var variant: int = sector_index if sector_index > 0 else (int(panel.choice) + row) % _environment_variants.size()
			var texture: Texture2D = _environment_variants[variant]
			var size: Vector2 = texture.get_size()
			var source := Rect2(float(panel.source_x), size.y * (140.0 / 724.0), float(panel.source_width), size.y * (280.0 / 724.0))
			draw_texture_rect_region(texture, Rect2(float(panel.x), top, float(panel.width), 106), source, tint)
			if float(panel.x) > 0.0:
				_draw_painted_column(texture, float(panel.x), top, 106, 140.0, 280.0, tint)
		# Sombra de encontro entre vãos, sem aresta iluminada que prometa apoio.
		# O escurecimento também recua os fragmentos de móveis do recorte pintado.
		for band: int in range(4):
			draw_rect(Rect2(0, top + 98 + band * 2, world_bounds.size.x, 2), Color(0.035, 0.05, 0.065, 0.12 + band * 0.16))
		draw_rect(Rect2(0, top, world_bounds.size.x, 2), Color("171f26"))
	# Corredor principal em escala0,2; mesas~25px e atores~30px.
	for panel: Dictionary in _environment_panels:
		var texture: Texture2D = panel.texture as Texture2D
		var size: Vector2 = texture.get_size()
		var crop_top: float = size.y * (56.0 / 724.0)
		var source_height: float = size.y * (544.0 / 724.0)
		var panel_height: float = snappedf(source_height * 0.2, 0.5)
		var source := Rect2(float(panel.source_x), crop_top, float(panel.source_width), source_height)
		var destination := Rect2(float(panel.x), 620.0 - panel_height, float(panel.width), panel_height)
		draw_texture_rect_region(texture, destination, source)
		if float(panel.x) > 0.0:
			_draw_painted_column(texture, float(panel.x), destination.position.y, panel_height, 56.0, 544.0)


func _draw_painted_column(texture: Texture2D, x: float, top: float, height: float, source_y: float, source_height: float, tint: Color = Color.WHITE) -> void:
	# A emenda usa reboco/luz/folhagem da própria pintura, sem coluna de cor chapada.
	var size: Vector2 = texture.get_size()
	var source := Rect2(0, size.y * source_y / 724.0, size.x * (55.0 / 2172.0), size.y * source_height / 724.0)
	draw_texture_rect_region(texture, Rect2(x - 5.5, top, 11, height), source, tint)
	draw_rect(Rect2(x - 5.5, top, 0.5, height), Color(0.05, 0.08, 0.10, 0.5))


func _draw_window(at: Vector2, width: float, palette: Array[Color], bay: int) -> void:
	var glass := Rect2(at, Vector2(width, 376))
	draw_rect(glass.grow(5), palette[0])
	draw_rect(glass, palette[1].lightened(0.12))
	# Faixas discretas substituem gradiente e mantêm pixels sólidos.
	for band: int in range(5):
		draw_rect(Rect2(at + Vector2(0, 76 + band * 60), Vector2(width, 60)), palette[1].lightened(0.09 - band * 0.025))
	# Skyline própria por vão: antenas, prédios próximos e luzes esparsas.
	for building: int in range(5):
		var key: int = bay * 29 + building * 17 + sector_index * 11
		var bx: float = at.x + building * 39
		var height: float = 64 + key % 111
		var y: float = at.y + 376 - height
		draw_rect(Rect2(bx, y, 34, height), palette[1].darkened(0.21))
		draw_rect(Rect2(bx + 12, y - 7, 12, 7), palette[1].darkened(0.22))
		if key % 3 == 0:
			draw_rect(Rect2(bx + 17, y - 25, 1, 18), palette[1].darkened(0.22))
		for row: int in range(5):
			for column: int in range(3):
				if (row + column * 3 + key) % 4 == 0 and row * 18 < height - 12:
					draw_rect(Rect2(bx + 5 + column * 9, y + 10 + row * 18, 3, 3), palette[5].darkened(0.43))
	for mullion: int in range(1, 4):
		var x: float = at.x + mullion * width / 4.0
		draw_rect(Rect2(x, at.y, 3, 376), palette[0])
		draw_rect(Rect2(x + 3, at.y, 1, 376), palette[3].darkened(0.28))
	for blind: int in range(9 + bay % 3):
		var y: float = at.y + 4 + blind * 6
		draw_rect(Rect2(at.x, y, width, 3), palette[0])
		draw_rect(Rect2(at.x + 2, y, width - 4, 1), palette[3].darkened(0.16))
	draw_rect(Rect2(at.x + width - 12, at.y + 4, 1, 97), palette[5].darkened(0.36))
	draw_rect(Rect2(at.x + width - 13, at.y + 99, 3, 5), palette[0])
	draw_rect(Rect2(at.x, at.y + 376, width, 5), palette[3].darkened(0.16))
	# Um único impacto em alguns vãos; sem riscar toda a superfície de combate.
	if bay % 4 == 2:
		var hit: Vector2 = at + Vector2(137, 159)
		for tip: Vector2 in [Vector2(-17, -32), Vector2(8, -28), Vector2(29, -7), Vector2(16, 27), Vector2(-19, 33)]:
			draw_line(hit, hit + tip * 0.45, palette[0], 1.0)
			draw_line(hit + tip * 0.45, hit + tip, palette[5].darkened(0.35), 1.0)
		draw_rect(Rect2(hit - Vector2(2, 2), Vector2(4, 4)), palette[0])


func _draw_office_bays(palette: Array[Color]) -> void:
	var width: float = world_bounds.size.x
	draw_rect(Rect2(0, 122, width, 498), palette[2])
	draw_rect(Rect2(0, 570, width, 44), palette[2].lightened(0.08))
	draw_rect(Rect2(0, 608, width, 12), palette[0])
	for bay: int in range(int(width / 240.0) + 1):
		var x: float = float(bay) * 240.0
		_draw_window(Vector2(x + 22, 184), 194, palette, bay)
		# Colunas de concreto com recortes de luz e juntas de reboco.
		draw_rect(Rect2(x, 126, 17, 482), palette[2].lightened(0.045))
		draw_rect(Rect2(x + 1, 127, 2, 479), palette[3].darkened(0.08))
		draw_rect(Rect2(x + 14, 128, 3, 478), palette[0].lightened(0.05))
		_draw_wall_material(Vector2(x + 1, 399), bay + sector_index * 13, palette)
		_draw_pendant(Vector2(x + 58, 143), 130, palette)
		_draw_wall_sconce(Vector2(x + 8, 472 + bay % 2 * 24), palette)
		if sector_index == 1:
			_draw_workstation(Vector2(x + 49, 606), palette, bay)
			if bay % 2 == 0:
				_draw_plant(Vector2(x + 195, 606), palette, bay)
		elif sector_index == 0:
			match bay % 4:
				0:
					_draw_reception(Vector2(x + 47, 606), palette)
				1:
					_draw_filing_cabinet(Vector2(x + 61, 606), palette, bay)
				2:
					_draw_sofa(Vector2(x + 40, 606), palette)
					_draw_water_cooler(Vector2(x + 172, 606), palette)
				3:
					_draw_workstation(Vector2(x + 49, 606), palette, bay)
			if bay % 2 == 0:
				_draw_plant(Vector2(x + 17, 606), palette, bay)
		else:
			if bay < 2 or bay > 4:
				_draw_sofa(Vector2(x + 40, 606), palette)
				_draw_plant(Vector2(x + 191, 606), palette, bay)
				_draw_framed_art(Vector2(x + 50, 538), palette, bay)
		# Restos narrativos ficam atrás dos pés, sem borda de plataforma.
		for paper: int in range(3):
			var px: float = x + 45 + (bay * 17 + paper * 51) % 150
			var py: float = 608 + (paper + bay) % 4
			draw_rect(Rect2(px, py, 7 + paper % 2 * 3, 2), palette[5].darkened(0.12))
			draw_rect(Rect2(px + 2, py - 1, 4, 1), palette[5].darkened(0.31))
	# Vigas e conduítes alinhados à arquitetura, longe do plano dos atores.
	draw_rect(Rect2(0, 104, width, 17), palette[0])
	draw_rect(Rect2(0, 107, width, 2), palette[3].darkened(0.12))
	draw_rect(Rect2(0, 125, width, 3), palette[0])
	draw_rect(Rect2(0, 135, width, 2), palette[3].darkened(0.28))


func _draw_pendant(at: Vector2, width: float, palette: Array[Color]) -> void:
	for x: float in [8.0, width - 8]:
		draw_rect(Rect2(at + Vector2(x, -20), Vector2(1, 20)), palette[0])
	# Halo desenhado em dois planos de pixels, sem luz/shader dinâmicos.
	draw_rect(Rect2(at + Vector2(-4, 8), Vector2(width + 8, 7)), Color(0.76, 0.61, 0.39, 0.045))
	draw_rect(Rect2(at, Vector2(width, 7)), palette[0])
	draw_rect(Rect2(at + Vector2(3, 5), Vector2(width - 6, 3)), Color("bba17b"))
	draw_rect(Rect2(at + Vector2(7, 6), Vector2(width - 14, 1)), Color("dec7a0"))


func _draw_wall_sconce(at: Vector2, palette: Array[Color]) -> void:
	# Halo em blocos suaves; o núcleo quente é pequeno e não usa a cor de alerta.
	draw_rect(Rect2(at + Vector2(-10, -13), Vector2(21, 36)), Color(0.78, 0.58, 0.33, 0.045))
	draw_rect(Rect2(at + Vector2(-7, -9), Vector2(15, 28)), Color(0.83, 0.63, 0.37, 0.055))
	draw_rect(Rect2(at + Vector2(-4, -6), Vector2(8, 20)), palette[0])
	draw_rect(Rect2(at + Vector2(-2, -4), Vector2(4, 16)), Color("b49a74"))
	draw_rect(Rect2(at + Vector2(-1, -2), Vector2(2, 12)), Color("dec69e"))
	draw_rect(Rect2(at + Vector2(-3, 1), Vector2(6, 1)), Color("746253"))
	draw_rect(Rect2(at + Vector2(-3, 8), Vector2(6, 1)), Color("746253"))


func _draw_plant(at: Vector2, palette: Array[Color], seed_value: int) -> void:
	draw_rect(Rect2(at + Vector2(-6, -11), Vector2(12, 11)), palette[0])
	draw_rect(Rect2(at + Vector2(-5, -10), Vector2(10, 9)), Color("807c6e"))
	draw_rect(Rect2(at + Vector2(3, -9), Vector2(2, 8)), Color("5a5c56"))
	draw_rect(Rect2(at + Vector2(-6, -12), Vector2(12, 2)), palette[5].darkened(0.17))
	for leaf: int in range(7):
		var x: float = -11 + (leaf * 9 + seed_value * 3) % 21
		var y: float = -19 - (leaf * 7) % 21
		draw_line(at + Vector2(0, -11), at + Vector2(x, y), Color("363e30"), 1.0)
		draw_rect(Rect2(at + Vector2(x - 2, y - 3), Vector2(4, 8)), Color("4c5e40") if leaf % 2 == 0 else Color("61704b"))
		draw_rect(Rect2(at + Vector2(x - 1, y - 2), Vector2(1, 4)), Color("77815a"))


func _draw_reception(at: Vector2, palette: Array[Color]) -> void:
	_draw_framed_art(at + Vector2(12, -76), palette, 0)
	draw_rect(Rect2(at + Vector2(0, -25), Vector2(88, 25)), palette[0])
	draw_rect(Rect2(at + Vector2(2, -23), Vector2(84, 21)), palette[4])
	draw_rect(Rect2(at + Vector2(5, -22), Vector2(1, 19)), palette[4].lightened(0.15))
	draw_rect(Rect2(at + Vector2(82, -23), Vector2(4, 21)), palette[4].darkened(0.3))
	draw_rect(Rect2(at + Vector2(-2, -27), Vector2(92, 3)), palette[0])
	draw_rect(Rect2(at + Vector2(-1, -27), Vector2(90, 1)), palette[4].lightened(0.2))
	draw_rect(Rect2(at + Vector2(18, -42), Vector2(20, 14)), palette[0])
	draw_rect(Rect2(at + Vector2(20, -40), Vector2(16, 10)), palette[1])
	draw_rect(Rect2(at + Vector2(27, -28), Vector2(3, 1)), palette[3])
	for stack: int in range(3):
		draw_rect(Rect2(at + Vector2(46, -29 - stack * 2), Vector2(13 - stack, 1)), palette[5].darkened(0.13 + stack * 0.08))
	_draw_desk_lamp(at + Vector2(74, -28), palette)
	# Veio de madeira e pequeno emblema próprio, em clusters de pixels.
	draw_rect(Rect2(at + Vector2(20, -16), Vector2(16, 1)), palette[4].darkened(0.16))
	draw_rect(Rect2(at + Vector2(59, -8), Vector2(12, 1)), palette[4].lightened(0.12))
	draw_line(at + Vector2(40, -17), at + Vector2(44, -12), palette[5].darkened(0.25), 1.0)
	draw_line(at + Vector2(44, -12), at + Vector2(48, -17), palette[5].darkened(0.25), 1.0)


func _draw_desk_lamp(at: Vector2, palette: Array[Color]) -> void:
	draw_rect(Rect2(at + Vector2(-4, -1), Vector2(8, 1)), palette[0])
	draw_rect(Rect2(at + Vector2(0, -10), Vector2(1, 10)), palette[4].lightened(0.18))
	draw_rect(Rect2(at + Vector2(-4, -14), Vector2(8, 5)), palette[4])
	draw_rect(Rect2(at + Vector2(-5, -10), Vector2(10, 2)), Color("c1a17a"))
	draw_rect(Rect2(at + Vector2(-3, -9), Vector2(6, 1)), Color("ddc39c"))


func _draw_sofa(at: Vector2, palette: Array[Color]) -> void:
	draw_rect(Rect2(at + Vector2(0, -26), Vector2(67, 23)), palette[0])
	draw_rect(Rect2(at + Vector2(2, -24), Vector2(63, 14)), Color("343338"))
	for cushion: int in range(3):
		draw_rect(Rect2(at + Vector2(5 + cushion * 19, -24), Vector2(17, 13)), Color("484347"))
		draw_rect(Rect2(at + Vector2(6 + cushion * 19, -23), Vector2(14, 1)), Color("5c5352"))
		draw_rect(Rect2(at + Vector2(5 + cushion * 19, -10), Vector2(17, 4)), Color("575052"))
	for side: float in [0.0, 61.0]:
		draw_rect(Rect2(at + Vector2(side, -16), Vector2(6, 13)), palette[0])
		draw_rect(Rect2(at + Vector2(side + 1, -15), Vector2(4, 10)), Color("484347"))
	for foot: float in [5.0, 58.0]:
		draw_rect(Rect2(at + Vector2(foot, -3), Vector2(2, 3)), palette[0])
	# Costura e desgaste esparsos não competem com a silhueta dos atores.
	draw_rect(Rect2(at + Vector2(12, -20), Vector2(3, 1)), Color("655b55"))
	draw_rect(Rect2(at + Vector2(37, -7), Vector2(4, 1)), Color("655b55"))


func _draw_water_cooler(at: Vector2, palette: Array[Color]) -> void:
	draw_rect(Rect2(at + Vector2(-7, -27), Vector2(14, 27)), palette[0])
	draw_rect(Rect2(at + Vector2(-6, -26), Vector2(12, 25)), Color("908e80"))
	draw_rect(Rect2(at + Vector2(-5, -21), Vector2(10, 11)), palette[0])
	draw_rect(Rect2(at + Vector2(-3, -18), Vector2(6, 5)), Color("5e6466"))
	draw_rect(Rect2(at + Vector2(-3, -21), Vector2(1, 2)), Color("9d5b4f"))
	draw_rect(Rect2(at + Vector2(2, -21), Vector2(1, 2)), Color("67929b"))
	draw_rect(Rect2(at + Vector2(-5, -42), Vector2(10, 15)), Color("3d5d74"))
	draw_rect(Rect2(at + Vector2(-4, -41), Vector2(2, 13)), Color("6b8ea0"))
	for y: float in [-39.0, -35.0, -30.0]:
		draw_rect(Rect2(at + Vector2(-5, y), Vector2(10, 1)), Color("587b91"))
	draw_rect(Rect2(at + Vector2(-4, -44), Vector2(8, 2)), palette[0])


func _draw_framed_art(at: Vector2, palette: Array[Color], index: int) -> void:
	draw_rect(Rect2(at, Vector2(46, 30)), palette[0])
	draw_rect(Rect2(at + Vector2(1, 1), Vector2(44, 28)), palette[4])
	draw_rect(Rect2(at + Vector2(3, 3), Vector2(40, 24)), Color("44454a"))
	# Composição geométrica original, sem imagem externa ou texto de marca.
	for patch: int in range(7):
		var x: float = 4 + (patch * 11 + index * 7) % 27
		var y: float = 5 + (patch * 7 + index * 3) % 14
		draw_rect(Rect2(at + Vector2(x, y), Vector2(8 + patch % 3 * 2, 4)), Color("8a7860") if patch % 3 == 0 else Color("343c46"))
	draw_rect(Rect2(at + Vector2(2, 2), Vector2(42, 1)), palette[5].darkened(0.3))


func _draw_wall_material(at: Vector2, seed_value: int, palette: Array[Color]) -> void:
	# Um pequeno remendo e fissura por coluna, sem ruído em runtime.
	var y: float = float(seed_value * 19 % 120)
	draw_rect(Rect2(at + Vector2(4, y), Vector2(7, 24)), palette[3].darkened(0.18))
	draw_rect(Rect2(at + Vector2(3, y + 7), Vector2(2, 8)), palette[4].darkened(0.16))
	draw_line(at + Vector2(8, y + 22), at + Vector2(5, y + 33), palette[0], 1.0)
	draw_line(at + Vector2(5, y + 33), at + Vector2(9, y + 44), palette[0], 1.0)


func _draw_workstation(at: Vector2, palette: Array[Color], index: int) -> void:
	# Referência de escala: tampo de mesa 23px acima do piso; executivo ~30px.
	draw_rect(Rect2(at + Vector2(0, -24), Vector2(88, 3)), palette[4].darkened(0.15))
	for leg: float in [3.0, 81.0]:
		draw_rect(Rect2(at + Vector2(leg, -21), Vector2(2, 21)), palette[0])
		draw_rect(Rect2(at + Vector2(leg, -20), Vector2(1, 19)), palette[3].darkened(0.2))
	draw_rect(Rect2(at + Vector2(29, -42), Vector2(27, 16)), palette[0])
	draw_rect(Rect2(at + Vector2(31, -40), Vector2(23, 12)), palette[1])
	for row: int in range(3):
		draw_rect(Rect2(at + Vector2(33, -37 + row * 3), Vector2(8 + (index + row) % 3 * 3, 1)), palette[5].darkened(0.28 if row == 0 else 0.45))
	draw_rect(Rect2(at + Vector2(41, -26), Vector2(3, 2)), palette[2])
	# Cadeira alta de escritório, com base apoiada no mesmo plano dos pés da mesa.
	draw_rect(Rect2(at + Vector2(34, -22), Vector2(16, 16)), palette[0])
	draw_rect(Rect2(at + Vector2(36, -20), Vector2(12, 11)), palette[2])
	draw_rect(Rect2(at + Vector2(32, -7), Vector2(20, 2)), palette[0])
	draw_rect(Rect2(at + Vector2(41, -5), Vector2(2, 4)), palette[0])
	draw_rect(Rect2(at + Vector2(35, -1), Vector2(15, 1)), palette[0])
	for page: int in range(3):
		draw_rect(Rect2(at + Vector2(6, -26 - page * 2), Vector2(13 - page, 1)), palette[5].darkened(0.15 + page * 0.08))
	draw_rect(Rect2(at + Vector2(60, -29), Vector2(4, 5)), palette[5].darkened(0.14))
	draw_rect(Rect2(at + Vector2(64, -28), Vector2(2, 3)), palette[5].darkened(0.3))
	if index % 2 == 1:
		_draw_desk_lamp(at + Vector2(77, -24), palette)


func _draw_filing_cabinet(at: Vector2, palette: Array[Color], index: int) -> void:
	draw_rect(Rect2(at + Vector2(0, -56), Vector2(34, 56)), palette[0])
	draw_rect(Rect2(at + Vector2(1, -55), Vector2(32, 54)), palette[2].darkened(0.09))
	for drawer: int in range(4):
		var y: float = -53 + drawer * 13
		draw_rect(Rect2(at + Vector2(2, y), Vector2(29, 12)), palette[1].lightened(0.025))
		draw_rect(Rect2(at + Vector2(14, y + 7), Vector2(8, 1)), palette[3])
		draw_rect(Rect2(at + Vector2(4, y + 3), Vector2(7, 3)), palette[4].lightened(0.05))
		draw_rect(Rect2(at + Vector2(5, y + 4), Vector2(5, 1)), palette[5].darkened(0.15))
	# Etiqueta numérica compacta; a sinalização maior do setor continua acima.
	draw_rect(Rect2(at + Vector2(2, -63), Vector2(28, 5)), palette[0])
	for digit: int in range(3):
		draw_rect(Rect2(at + Vector2(5 + digit * 7, -61), Vector2(3 + (index + digit) % 2, 1)), palette[5].darkened(0.25))
	for sheet: int in range(2):
		draw_rect(Rect2(at + Vector2(4 + sheet, -57 - sheet * 2), Vector2(16, 1)), palette[5].darkened(0.17))


func _draw_sector_identity(palette: Array[Color]) -> void:
	var names: Array[String] = ["ARQUIVO MORTO", "OPERAÇÕES", "CONSELHO EXECUTIVO"]
	_draw_sign(Vector2(22, 492), "VÉRTICE / " + names[sector_index], palette)
	if sector_index == 0:
		_draw_sign(Vector2(1125, 492), "ATAS / ACESSO RESTRITO", palette)
	elif sector_index == 1:
		_draw_sign(Vector2(1410, 492), "CONTRATOS / COMPLIANCE", palette)
	else:
		_draw_sign(Vector2(1245, 492), "SESSÃO CONFIDENCIAL", palette)
		var emblem := PackedVector2Array([Vector2(800, 396), Vector2(818, 413), Vector2(812, 413), Vector2(800, 402), Vector2(788, 413), Vector2(782, 413)])
		draw_colored_polygon(emblem, palette[4].lightened(0.15))


func _draw_sign(at: Vector2, label: String, palette: Array[Color]) -> void:
	# Placas de porta, na escala dos atores; o título maior pertence ao HUD.
	var width: float = maxf(82.0, label.length() * 4.35 + 12.0)
	draw_rect(Rect2(at, Vector2(width, 14)), Color("171e23"))
	draw_rect(Rect2(at + Vector2(0.5, 0.5), Vector2(width - 1, 0.5)), palette[3].darkened(0.12))
	draw_rect(Rect2(at + Vector2(1, 1), Vector2(1.5, 12)), palette[4].lightened(0.12))
	draw_string(ThemeDB.fallback_font, at + Vector2(7, 10), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TEXT)


func _draw_solid(rect: Rect2, _palette: Array[Color]) -> void:
	if rect.size.y > 40.0:
		# O corpo físico do piso não vira uma grande faixa cinza na apresentação.
		draw_rect(rect, Color("16191c"))
		return
	# Módulo de infraestrutura danificado. Todas as arestas coincidem com o sólido.
	draw_rect(rect, Color("1c2225"))
	draw_rect(Rect2(rect.position + Vector2(0.5, 0.5), rect.size - Vector2(1, 1)), Color("65665e"))
	draw_rect(Rect2(rect.position + Vector2(0.5, 0.5), Vector2(rect.size.x - 1, 1)), Color("c1b497"))
	draw_rect(Rect2(rect.position + Vector2(1.5, 2), Vector2(rect.size.x - 5, rect.size.y - 4)), Color("4d5550"))
	draw_rect(Rect2(rect.end - Vector2(4, rect.size.y - 1), Vector2(3.5, rect.size.y - 2)), Color("343d3b"))
	for module: int in range(int(rect.size.x / 12.0)):
		var x: float = rect.position.x + 4 + module * 12
		draw_rect(Rect2(x, rect.position.y + 5, 7, 1), Color("8a8974"))
		draw_rect(Rect2(x + 1, rect.position.y + 6, 5, 0.5), Color("2f3c38"))
		for slit: int in range(3):
			draw_rect(Rect2(x, rect.end.y - 9 + slit * 2, 6, 0.5), Color("29342f"))
		draw_rect(Rect2(x + 5, rect.position.y + 11, 0.5, 0.5), Color("c3b591"))
	var scar: Vector2 = rect.position + Vector2(rect.size.x * 0.48, 8)
	draw_polyline(PackedVector2Array([scar, scar + Vector2(-2, 3), scar + Vector2(0.5, 6), scar + Vector2(-1, 11)]), Color("262e2b"), 0.5)
	draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(1, 1)), Color("d1bda0"))
	draw_rect(Rect2(rect.end - Vector2(3, 3), Vector2(1, 1)), Color("878d7b"))


func _draw_walkway(rect: Rect2, _palette: Array[Color]) -> void:
	# Mesma pedra pintada do térreo, na densidade do cenário; geometria inalterada.
	draw_rect(rect, Color("20262b"))
	if _environment != null:
		var size: Vector2 = _environment.get_size()
		var modules: int = ceili(rect.size.x / 64.0)
		for module: int in range(modules):
			var width: float = minf(64.0, rect.size.x - module * 64.0)
			var x: float = rect.position.x + module * 64.0
			var source_x: float = snappedf(fposmod(x * 5.0, size.x - 320.0), 1.0)
			var top_source := Rect2(source_x, size.y * 600.0 / 724.0, width * 5.0, size.y * 15.0 / 724.0)
			var face_source := Rect2(source_x, size.y * 625.0 / 724.0, width * 5.0, size.y * 35.0 / 724.0)
			draw_texture_rect_region(_environment, Rect2(x, rect.position.y + 1, width, 3), top_source, Color("b4ada0"))
			draw_texture_rect_region(_environment, Rect2(x, rect.position.y + 4, width, 7), face_source)
	else:
		draw_rect(Rect2(rect.position + Vector2(0, 1), Vector2(rect.size.x, 3)), Color("777365"))
		draw_rect(Rect2(rect.position + Vector2(0, 4), Vector2(rect.size.x, 7)), Color("3b3c40"))
	# Um pixel de luz marca exatamente o topo físico unilateral, inclusive nas pontas.
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 0.5)), AMBER)
	draw_rect(Rect2(rect.position + Vector2(0, 0.5), Vector2(rect.size.x, 0.5)), Color("6d6659"))
	draw_rect(Rect2(rect.position + Vector2(0, 11), Vector2(rect.size.x, 1)), Color("151c21"))
	for inset: float in [12.0, rect.size.x - 12.0]:
		var at: Vector2 = rect.position + Vector2(inset, 12)
		# Consoles de aço escuro com espessura e parafusos; não são outros degraus.
		draw_colored_polygon(PackedVector2Array([at, at + Vector2(11, 0), at + Vector2(2, 12), at + Vector2(0, 12)]), Color("1c252b"))
		draw_line(at + Vector2(10, 1), at + Vector2(1, 11), Color("4d5353"), 0.5)
		draw_rect(Rect2(at + Vector2(0.5, 1), Vector2(1, 9)), Color("3d4649"))
		for bolt_y: float in [2.0, 9.0]:
			draw_rect(Rect2(at + Vector2(0.5, bolt_y), Vector2(0.5, 0.5)), Color("898574"))


func _draw_floor_details(_palette: Array[Color]) -> void:
	var width: float = world_bounds.size.x
	if _environment != null:
		# Uma única faixa de pedra evita saltos de altura entre fundos gerados.
		# O limite físico620 e o corte inferior632 permanecem uniformes.
		var texture: Texture2D = _environment_variants[0]
		var size: Vector2 = texture.get_size()
		var source := Rect2(0, size.y * (600.0 / 724.0), size.x, size.y * (50.0 / 724.0))
		draw_texture_rect_region(texture, Rect2(0, 620, width, 12), source)
		draw_rect(Rect2(0, 620, width, 0.5), Color("a69d89"))
		draw_rect(Rect2(0, 632, width, 88), Color("11171b"))
		return
	# Fallback sem asset para ferramentas/fixtures anteriores à importação.
	draw_rect(Rect2(0, 620, width, 12), Color("575750"))
	draw_rect(Rect2(0, 620, width, 0.5), Color("aaa594"))
	draw_rect(Rect2(0, 632, width, 88), Color("11171b"))


func _draw_exit(palette: Array[Color]) -> void:
	# A porta acompanha o marcador funcional do diretor em (fim-60,620).
	var x: float = world_bounds.end.x - 60.0
	var ink := Color("141c22")
	draw_rect(Rect2(x - 18, 560, 36, 60), ink)
	draw_rect(Rect2(x - 17, 560.5, 34, 1.5), palette[3])
	draw_rect(Rect2(x - 17, 562, 2, 58), Color("797c74"))
	draw_rect(Rect2(x - 16.5, 562.5, 0.5, 56), Color("b0ad98"))
	draw_rect(Rect2(x + 15, 562, 2, 58), Color("373f40"))
	draw_rect(Rect2(x - 14, 564, 28, 56), Color("263c47"))
	draw_rect(Rect2(x - 13.5, 564.5, 27, 0.5), Color("81918e"))
	draw_rect(Rect2(x + 12.5, 565, 1, 54), Color("162b36"))
	draw_rect(Rect2(x - 10, 570, 20, 20), ink)
	draw_rect(Rect2(x - 9, 571, 18, 18), Color("47616b"))
	draw_rect(Rect2(x - 8.5, 571.5, 1, 16), Color("77918e"))
	draw_rect(Rect2(x - 7, 572, 15.5, 0.5), Color("6d8588"))
	draw_rect(Rect2(x + 4, 574, 0.5, 11), Color("5a757c"))
	draw_rect(Rect2(x - 11, 599, 22, 2), ink)
	draw_rect(Rect2(x - 10.5, 599, 21, 0.5), Color("b6b9a9"))
	draw_rect(Rect2(x - 10, 600, 20, 0.5), Color("7c8885"))
	draw_rect(Rect2(x - 11, 614, 22, 4), Color("414f51"))
	draw_rect(Rect2(x - 10.5, 614, 21, 0.5), Color("82908a"))
	draw_rect(Rect2(x - 17, 619.5, 34, 0.5), Color("aaa28d"))
	# Placa compacta em escala humana; nome e função anteriores são preservados.
	draw_rect(Rect2(x - 22, 549, 44, 9), ink)
	draw_rect(Rect2(x - 21.5, 549.5, 43, 0.5), Color("788374"))
	draw_string(ThemeDB.fallback_font, Vector2(x - 19, 556), "SAIDA >", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("b7c2a8"))
