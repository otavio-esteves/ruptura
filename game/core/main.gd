extends Node

const INPUT_SETUP = preload("res://game/core/input_setup.gd")
const ARENA_SCENE = preload("res://game/world/levels/prototype_arena.tscn")
const PLAYER_SCENE = preload("res://game/actor/player/player.tscn")
const OVERLAY = preload("res://game/ui/performance_overlay.gd")

var arena: Node2D
var player: CharacterBody2D
var menu: CanvasLayer
var overlay: CanvasLayer
var alternate_jump: bool = false
var cap_30: bool = false
var tone_player := AudioStreamPlayer.new()
var play_button: Button

func _ready() -> void:
	INPUT_SETUP.install()
	Engine.max_fps = 60
	_build_menu()
	add_child(tone_player)
	overlay = OVERLAY.new()
	add_child(overlay)
	overlay.hide()
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--auto-arena":
			_start()
		if argument.begins_with("--benchmark-seconds="):
			if arena == null:
				_start()
			overlay.begin_capture(float(argument.get_slice("=", 1)), true)
		if argument == "--fps=30":
			cap_30 = true
			Engine.max_fps = 30

func _build_menu() -> void:
	menu = CanvasLayer.new()
	add_child(menu)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.035, 0.047, 0.063, 0.96)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	center.add_child(column)
	var title := Label.new()
	title.text = "R U P T U R A"
	title.add_theme_font_size_override("font_size", 32)
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "LABORATÓRIO DE MOVIMENTO / CINZAS\nProtótipo inicial · sem combate\n\nA/D mover · Ctrl correr · Espaço saltar\nS agachar / S+Espaço descer · Shift esquivar\nMouse / analógico direito mirar\nF2 alterna salto A/LB no controle"
	subtitle.add_theme_font_size_override("font_size", 14)
	column.add_child(subtitle)
	var play := Button.new()
	play_button = play
	play.text = "Entrar / continuar"
	play.pressed.connect(_start)
	column.add_child(play)
	var sound := Button.new()
	sound.text = "Testar áudio (tom curto)"
	sound.pressed.connect(_play_tone)
	column.add_child(sound)
	var exit_button := Button.new()
	exit_button.text = "Sair"
	exit_button.pressed.connect(func() -> void: get_tree().quit())
	column.add_child(exit_button)
	play.grab_focus()

func _start() -> void:
	if arena == null:
		arena = ARENA_SCENE.instantiate()
		add_child(arena)
		player = PLAYER_SCENE.instantiate()
		arena.add_child(player)
		player.reset_to(arena.spawn_position)
		var camera := Camera2D.new()
		camera.position = Vector2(0, -70)
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 7.0
		var bounds: Rect2 = arena.world_bounds
		camera.limit_left = int(bounds.position.x)
		camera.limit_top = int(bounds.position.y)
		camera.limit_right = int(bounds.end.x)
		camera.limit_bottom = int(bounds.end.y)
		player.add_child(camera)
		camera.reset_smoothing()
		overlay.player = player
	menu.hide()
	overlay.show()
	player.set_process_input(true)
	player.set_physics_process(true)
	_write_probe()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if arena == null:
			return
		if overlay.collecting:
			overlay.cancel_capture("menu aberto")
		menu.visible = not menu.visible
		overlay.visible = not menu.visible
		if is_instance_valid(player):
			player.set_physics_process(not menu.visible)
			player.set_process_input(not menu.visible)
			player.velocity = Vector2.ZERO
		if menu.visible:
			play_button.grab_focus()
	if event.is_action_pressed("restart") and is_instance_valid(player) and not menu.visible:
		player.reset_to(arena.spawn_position)
	if event.is_action_pressed("switch_preset"):
		alternate_jump = not alternate_jump
		INPUT_SETUP.install(alternate_jump)
		overlay.preset_label = "LB" if alternate_jump else "A"
	if event.is_action_pressed("toggle_fps"):
		cap_30 = not cap_30
		Engine.max_fps = 30 if cap_30 else 60
	if event.is_action_pressed("benchmark") and not menu.visible:
		overlay.begin_capture(10.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(player):
		if is_instance_valid(overlay) and overlay.collecting:
			overlay.cancel_capture("janela perdeu foco")
		menu.show()
		overlay.hide()
		player.set_physics_process(false)
		player.set_process_input(false)
		player.velocity = Vector2.ZERO

func _process(_delta: float) -> void:
	if is_instance_valid(player) and player.position.y > arena.world_bounds.end.y + 100:
		player.reset_to(arena.spawn_position)

func _write_probe() -> void:
	var file := FileAccess.open("user://prototype_probe.txt", FileAccess.WRITE)
	if file == null:
		push_error("Diretório de usuário sem escrita: %s" % FileAccess.get_open_error())
	else:
		file.store_line("RUPTURA prototype " + Time.get_datetime_string_from_system())
		file.close()
		print("USER_WRITE_OK=", ProjectSettings.globalize_path("user://prototype_probe.txt"))

func _play_tone() -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(4410 * 2)
	for index: int in range(4410):
		var envelope: float = sin(PI * float(index) / 4410.0)
		var sample: int = int(sin(TAU * 440.0 * float(index) / 22050.0) * 5000.0 * envelope)
		data.encode_s16(index * 2, sample)
	stream.data = data
	tone_player.stream = stream
	tone_player.play()
