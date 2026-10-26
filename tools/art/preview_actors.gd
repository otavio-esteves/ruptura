extends SceneTree
## Prancha visual isolada. Executar graficamente após importar o atlas.
## godot --path . --script tools/art/preview_actors.gd

const OUTPUT: String = "res://reports/pixel-art-sheet.png"
const SHEET_SIZE := Vector2i(960, 832)


class ActorPose:
	extends Node2D
	const PixelActor = preload("res://game/visuals/pixel_actor.gd")
	var pose: Dictionary = {}
	func _draw() -> void:
		PixelActor.draw_actor(self, pose)


class Sheet:
	extends Node2D
	const KINDS: Array[String] = ["spectre", "recruit", "scout", "chacal"]
	const NAMES: Array[String] = ["ESPECTRO", "RECRUTA", "BATEDOR", "CHACAL"]
	const STATES: Array[String] = ["jump", "apex", "fall", "land", "crouch", "dodge", "hurt", "dead", "idle"]
	const LABELS: Array[String] = ["salto", "ápice", "queda", "pouso", "agachar", "esquiva", "dano", "morte", "recuo"]
	const INK := Color("8b9d9f")
	const LIGHT := Color("d4d8cd")
	var font: Font


	func _ready() -> void:
		font = ThemeDB.fallback_font
		for row: int in range(KINDS.size()):
			var kind: String = KINDS[row]
			var top: float = 55.0 + row * 190.0
			_add_pose(Vector2(153, top + 77), 2, _pose(kind, "idle"))
			for frame: int in range(8):
				_add_pose(Vector2(265 + frame * 80, top + 77), 2, _pose(kind, "run", float(frame) / 8.0))
			for state_index: int in range(STATES.size()):
				var pose: Dictionary = _pose(kind, STATES[state_index], 0.25)
				if state_index == 8: pose["recoil"] = 1.0
				_add_pose(Vector2(123 + state_index * 52, top + 171), 2, pose)
			for direction: int in range(8):
				var aim := Vector2.from_angle(-float(direction) * TAU / 8.0)
				var pose: Dictionary = _pose(kind, "idle", 0.0, aim)
				pose["facing"] = -1.0 if aim.x < -0.01 else 1.0
				_add_pose(Vector2(617 + direction * 43, top + 171), 1, pose)
		queue_redraw()


	func _pose(kind: String, state: String, cycle: float = 0.0, aim: Vector2 = Vector2.RIGHT) -> Dictionary:
		return {"kind": kind, "state": state, "cycle": cycle, "facing": 1.0, "aim": aim, "recoil": 0.0, "flash": false, "phase": 1, "crouch_moving": false, "weapon": "blade" if kind == "scout" else "pistol", "action": "neutral", "action_progress": 0.0}


	func _add_pose(at: Vector2, zoom: int, pose: Dictionary) -> void:
		var actor := ActorPose.new()
		actor.position = at
		actor.scale = Vector2.ONE * float(zoom)
		actor.pose = pose
		add_child(actor)


	func _draw() -> void:
		draw_rect(Rect2(0, 0, 960, 832), Color("101921"))
		draw_string(font, Vector2(16, 23), "RUPTURA / ESTUDO DE PIXEL ART E ANIMAÇÃO · 0.3.1", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, LIGHT)
		draw_string(font, Vector2(16, 43), "Corpos/estados em 2× · mira em 1× · poses estáticas para revisão; conforto e movimento dependem do jogo", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, INK)
		for row: int in range(KINDS.size()):
			var top: float = 55.0 + row * 190.0
			draw_rect(Rect2(10, top, 940, 184), Color("19252d") if row % 2 == 0 else Color("142129"))
			draw_string(font, Vector2(18, top + 21), NAMES[row], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, LIGHT)
			draw_string(font, Vector2(18, top + 39), "idle / corrida", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, INK)
			draw_line(Vector2(111, top + 78), Vector2(928, top + 78), Color("34434a"), 1.0)
			draw_string(font, Vector2(136, top + 91), "idle", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, INK)
			for frame: int in range(8):
				draw_string(font, Vector2(244 + frame * 80, top + 91), "c %.3f" % (float(frame) / 8.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, INK)
			for state_index: int in range(LABELS.size()):
				draw_string(font, Vector2(103 + state_index * 52, top + 184), LABELS[state_index], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, INK)
			for direction: int in range(8):
				draw_string(font, Vector2(605 + direction * 43, top + 184), "%d°" % (direction * 45), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, INK)
			draw_string(font, Vector2(18, top + 141), "estados / mira", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, INK)


func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("A prancha requer sessão gráfica; execute sem --headless.")
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = SHEET_SIZE
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.add_child(Sheet.new())
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var path: String = ProjectSettings.globalize_path(OUTPUT)
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if directory_error != OK:
		push_error("Falha criando diretório da prancha: %s" % directory_error)
		quit(1)
		return
	var rendered: Image = viewport.get_texture().get_image()
	if rendered == null or rendered.is_empty():
		push_error("Renderer não produziu imagem da prancha.")
		quit(1)
		return
	var save_error: Error = rendered.save_png(path)
	if save_error != OK:
		push_error("Falha exportando prancha: %s" % save_error)
		quit(1)
		return
	print("PIXEL_ART_SHEET=", path, " SIZE=", rendered.get_width(), "x", rendered.get_height())
	quit(0)
