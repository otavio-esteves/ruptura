extends SceneTree
## Comparação visual isolada. Não importa referências nem instancia o jogo.
## godot --path . --script tools/art/compare_references.gd -- --sector=archive

const SIZE := Vector2i(1800, 1240)
const OUTPUT: String = "res://reports/reference-comparison.png"
var _sector: String = "corridor"

class ActorPose extends Node2D:
	const PixelActor = preload("res://game/visuals/pixel_actor.gd")
	var pose: Dictionary = {}
	func _draw() -> void:
		PixelActor.draw_actor(self, pose)

class Board extends Node2D:
	var stage_reference: Texture2D
	var actor_reference: Texture2D
	var current_capture: Texture2D
	var sector: String = "corridor"
	var font: Font
	const INK := Color("9aa5ad")
	const LIGHT := Color("e0d9c9")

	func _ready() -> void:
		font = ThemeDB.fallback_font
		var definitions: Array[Dictionary] = [
			{"kind": "spectre", "state": "idle", "cycle": 0.0, "at": Vector2(610, 925), "name": "ESPECTRO / APOIO"},
			{"kind": "spectre", "state": "run", "cycle": 0.125, "at": Vector2(930, 925), "name": "ESPECTRO / CORRIDA"},
			{"kind": "recruit", "state": "idle", "cycle": 0.0, "at": Vector2(1235, 925), "name": "RECRUTA / APOIO"},
			{"kind": "chacal", "state": "idle", "cycle": 0.0, "at": Vector2(1570, 925), "name": "CHACAL / APOIO"},
		]
		for definition: Dictionary in definitions:
			var actor := ActorPose.new()
			actor.position = definition.at
			actor.scale = Vector2.ONE * (5.0 if definition.kind == "chacal" else 6.0)
			actor.pose = {"kind": definition.kind, "state": definition.state, "cycle": definition.cycle, "facing": 1.0, "aim": Vector2.RIGHT, "recoil": 0.0, "flash": false, "phase": 1, "weapon": "pistol", "action": "neutral", "action_progress": 0.0}
			add_child(actor)
		queue_redraw()

	func _fit(texture: Texture2D, area: Rect2, source: Rect2 = Rect2()) -> void:
		var region: Rect2 = source
		if region.size == Vector2.ZERO: region = Rect2(Vector2.ZERO, texture.get_size())
		var ratio: float = minf(area.size.x / region.size.x, area.size.y / region.size.y)
		var size: Vector2 = (region.size * ratio).floor()
		var at: Vector2 = (area.position + (area.size - size) * 0.5).floor()
		draw_texture_rect_region(texture, Rect2(at, size), region)

	func _label(at: Vector2, text: String, size: int = 19, color: Color = LIGHT) -> void:
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE)), Color("0d141b"))
		_label(Vector2(24, 33), "RUPTURA / REFERÊNCIA E IMPLEMENTAÇÃO", 25)
		_label(Vector2(24, 61), "Comparação de direção: não aprova estética, diversão ou desempenho. Proporções preservadas; enquadramentos distintos.", 17, INK)
		for left: float in [24.0, 914.0]:
			draw_rect(Rect2(left, 108, 862, 460), Color("18232c"))
		_label(Vector2(24, 97), "ALVO / ESCRITÓRIO CORPORATIVO", 20)
		_label(Vector2(914, 97), "JOGO ATUAL / " + sector.to_upper(), 20)
		_fit(stage_reference, Rect2(34, 118, 842, 440), Rect2(0, 88, 2172, 536))
		_fit(current_capture, Rect2(924, 118, 842, 440))
		_label(Vector2(24, 597), "Comparar composição do panorama, escala, contato dos pés, silhueta e preservação dos pixels fornecidos.", 18, INK)
		_label(Vector2(24, 636), "PERSONAGEM / SILHUETA, VOLUME E DETALHE", 21)
		draw_rect(Rect2(24, 655, 1752, 322), Color("19232d"))
		# Primeira pose fornecida; o renderer usa os recortes autorizados na0.4.3.
		_fit(actor_reference, Rect2(72, 690, 264, 235), Rect2(15, 16, 155, 210))
		_label(Vector2(72, 960), "REFERÊNCIA / APOIO", 17)
		for definition: Dictionary in [
			{"x": 482.0, "name": "ESPECTRO / APOIO"}, {"x": 798.0, "name": "ESPECTRO / CORRIDA"},
			{"x": 1122.0, "name": "RECRUTA / APOIO"}, {"x": 1454.0, "name": "CHACAL / APOIO"}]:
			_label(Vector2(definition.x, 960), definition.name, 16)
		draw_line(Vector2(54, 927), Vector2(1746, 927), Color("52606b"), 1.0)
		_label(Vector2(24, 1010), "0.4.3: poses horizontais usam recortes literais; os ângulos ausentes articulam camadas da mesma folha.", 18, INK)
		_label(Vector2(24, 1044), "Observar nariz/mandíbula/cabelo, ombros/antebraços, paletó/gravata, joelhos, mãos e apoio dos pés.", 18, INK)
		_label(Vector2(24, 1078), "Corrida e esquiva exigem vídeo: esta prancha não revela escorregamento, timing, transições ou leitura sob pressão.", 18, INK)
		_label(Vector2(24, 1130), "Fontes: references/ · reports/corridor-review/ · renderer real de game/visuals/pixel_actor.gd", 17, INK)
		_label(Vector2(24, 1162), "Uso direto dos pixels solicitado em27/10/2026. Esta prancha é somente relatório local.", 17, INK)

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--sector="):
			var value: String = argument.get_slice("=", 1)
			if value in ["corridor", "archive", "operations", "boardroom"]: _sector = value
	call_deferred("_render")

func _read_texture(path: String) -> Texture2D:
	var source := Image.new()
	var error: Error = source.load(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Falha lendo imagem de comparação %s: %s" % [path, error])
		return null
	return ImageTexture.create_from_image(source)

func _render() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("A prancha comparativa requer sessão gráfica.")
		quit(1)
		return
	var board := Board.new()
	board.stage_reference = _read_texture("res://references/Pixel-Art Corporate Lobby Brawl Stage.png")
	board.actor_reference = _read_texture("res://references/Retro Pixel Action Hero Sprite Sheet.png")
	board.current_capture = _read_texture("res://reports/corridor-review/entrance.png" if _sector == "corridor" else "res://reports/reference-review/" + _sector + ".png")
	board.sector = _sector
	if board.stage_reference == null or board.actor_reference == null or board.current_capture == null:
		board.free()
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = SIZE
	viewport.disable_3d = true
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.add_child(board)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path: String = ProjectSettings.globalize_path("res://reports/corridor-review/reference-comparison.png" if _sector == "corridor" else OUTPUT)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var error: Error = viewport.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Falha salvando comparação: %s" % error)
		quit(1)
		return
	print("REFERENCE_COMPARISON=", path)
	quit()
