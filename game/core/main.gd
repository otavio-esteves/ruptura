extends Node

const INPUT_SETUP = preload("res://game/core/input_setup.gd")
const ARENA_SCENE = preload("res://game/world/levels/prototype_arena.tscn")
const PLAYER_SCENE = preload("res://game/actor/player/player.tscn")
const OVERLAY = preload("res://game/ui/performance_overlay.gd")
const WEAPONS = preload("res://game/combat/weapons/weapon_controller.gd")
const DIRECTOR = preload("res://game/world/levels/combat_director.gd")
const HUD = preload("res://game/ui/combat_hud.gd")
const STORE = preload("res://game/progression/local_store.gd")
const SOUND = preload("res://game/core/sound_bank.gd")

var arena: Node2D
var player: CharacterBody2D
var director: Node2D
var menu: CanvasLayer
var overlay: CanvasLayer
var hud: CanvasLayer
var alternate_jump: bool = false
var cap_30: bool = false
var play_button: Button
var sound_bank: Node
var store: RefCounted = STORE.new()
var checkpoint: Dictionary = {}
var settings: Dictionary = {"assisted": false, "alternate_jump": false, "volume": 0.55, "bindings": {}}
var menu_column: VBoxContainer
var options_column: VBoxContainer
var save_notice: Label
var binding_action: String = ""
var binding_button: Button
var checkpoint_recovery_required: bool = false
var binding_buttons: Dictionary = {}
const BINDING_NAMES: Dictionary = {"move_left": "Esquerda", "move_right": "Direita", "jump": "Saltar", "dodge": "Esquiva", "reload": "Recarregar", "interact": "Interagir", "sprint": "Correr", "crouch": "Agachar"}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var loaded: Dictionary = store.load_settings()
	settings.merge(loaded, true)
	alternate_jump = settings.alternate_jump
	_install_input()
	Engine.max_fps = 60
	sound_bank = SOUND.new()
	add_child(sound_bank)
	sound_bank.volume = settings.volume
	checkpoint = store.load_checkpoint()
	checkpoint_recovery_required = checkpoint.is_empty() and not store.last_error.is_empty()
	_build_menu()
	overlay = OVERLAY.new()
	add_child(overlay)
	overlay.hide()
	overlay.preset_label = "LB" if alternate_jump else "A"
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--auto-arena":
			_start()
		if argument.begins_with("--benchmark-seconds="):
			if arena == null: _start()
			overlay.begin_capture(float(argument.get_slice("=", 1)), true)
		if argument == "--fps=30":
			cap_30 = true
			Engine.max_fps = 30

func _build_menu() -> void:
	menu = CanvasLayer.new()
	menu.layer = 20
	add_child(menu)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.035, 0.047, 0.063, 0.97)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(backdrop)
	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		frame.add_theme_constant_override("margin_" + side, 22)
	menu.add_child(frame)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	frame.add_child(row)
	var description := VBoxContainer.new()
	description.custom_minimum_size.x = 312
	description.add_theme_constant_override("separation", 12)
	row.add_child(description)
	var title := Label.new()
	title.text = "R U P T U R A"
	title.add_theme_font_size_override("font_size", 29)
	description.add_child(title)
	var text := Label.new()
	text.text = "CINZAS / PROTÓTIPO DE COMBATE\n\nInfiltre o pátio. Recupere os registros.\nTransmita a prova para a resistência.\n\nA/D mover · Ctrl correr · Espaço pular\nShift esquiva · S agachar/descer\nMouse mirar · esquerdo tiro · direito golpe\nR recarregar · 1/2/Q trocar · E interagir\nF5 checkpoint · F2 salto A/LB · F11 tela\n\nControle: RT tiro · RB golpe · X recarga\nY troca · A salto · B esquiva · ↑ interagir"
	text.add_theme_font_size_override("font_size", 12)
	description.add_child(text)
	save_notice = Label.new()
	save_notice.text = store.last_error
	save_notice.add_theme_font_size_override("font_size", 10)
	save_notice.add_theme_color_override("font_color", Color("dfb975"))
	save_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_notice.custom_minimum_size.x = 300
	description.add_child(save_notice)
	menu_column = VBoxContainer.new()
	menu_column.custom_minimum_size.x = 240
	menu_column.add_theme_constant_override("separation", 10)
	row.add_child(menu_column)
	var heading := Label.new()
	heading.text = "UMA CHANCE DE ROMPER"
	heading.add_theme_font_size_override("font_size", 13)
	menu_column.add_child(heading)
	play_button = _button(menu_column, "Continuar / jogar", _start)
	_button(menu_column, "Nova missão", _new_run)
	_button(menu_column, "Opções e controles", _open_options)
	_button(menu_column, "Sair", func() -> void: get_tree().quit())
	var note := Label.new()
	note.text = "3 encontros · pistola e espingarda\nCaixas, vidro e barris explosivos\nCheckpoint após cada área segura\n\nArte provisória original · v0.2"
	note.add_theme_font_size_override("font_size", 11)
	menu_column.add_child(note)
	options_column = VBoxContainer.new()
	options_column.custom_minimum_size.x = 240
	options_column.add_theme_constant_override("separation", 4)
	row.add_child(options_column)
	var assist := CheckButton.new()
	assist.text = "Modo assistido (próximo retry)"
	assist.add_theme_font_size_override("font_size", 11)
	assist.button_pressed = settings.assisted
	assist.toggled.connect(func(value: bool) -> void: settings.assisted = value; _save_settings())
	options_column.add_child(assist)
	_button(options_column, "Alternar salto A / LB", _toggle_jump_preset)
	var volume_label := Label.new()
	volume_label.text = "Volume dos efeitos"
	volume_label.add_theme_font_size_override("font_size", 11)
	options_column.add_child(volume_label)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = settings.volume
	volume.value_changed.connect(func(value: float) -> void:
		settings.volume = value
		sound_bank.volume = value
		_save_settings()
	)
	options_column.add_child(volume)
	_button(options_column, "Ouvir efeitos", _play_tone)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 108
	options_column.add_child(scroll)
	var binds := VBoxContainer.new()
	binds.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(binds)
	for action: String in BINDING_NAMES:
		var button := _button(binds, BINDING_NAMES[action] + ": " + _binding_name(action), func() -> void: pass)
		binding_buttons[action] = button
		button.pressed.connect(_begin_binding.bind(action, button))
	_button(options_column, "Restaurar teclas", func() -> void:
		settings.bindings = {}
		_install_input()
		_refresh_binding_buttons()
		_save_settings()
		save_notice.text = "Teclas padrão restauradas."
	)
	_button(options_column, "Voltar", _close_options)
	options_column.hide()
	play_button.grab_focus()

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 29
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _start() -> void:
	if checkpoint_recovery_required:
		save_notice.text = "Save inválido preservado. Escolha Nova missão para recomeçar explicitamente."
		return
	if arena == null:
		_build_world()
	_set_paused(false)
	_write_probe()

func _build_world() -> void:
	arena = ARENA_SCENE.instantiate()
	arena.show_training_targets = false
	arena.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(arena)
	player = PLAYER_SCENE.instantiate()
	arena.add_child(player)
	player.assisted = settings.assisted
	var weapons: Node2D = WEAPONS.new()
	player.add_child(weapons)
	player.weapon_controller = weapons
	weapons.setup(player)
	weapons.feedback.connect(sound_bank.play)
	player.damaged.connect(func(_amount: float) -> void: sound_bank.play("hurt"))
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
	director = DIRECTOR.new()
	arena.add_child(director)
	director.checkpoint_reached.connect(_checkpoint_reached)
	director.setup(player, checkpoint, sound_bank, settings.assisted)
	camera.reset_smoothing()
	if is_instance_valid(hud):
		hud.queue_free()
	hud = HUD.new()
	hud.player = player
	hud.director = director
	add_child(hud)
	hud.retry_requested.connect(_retry)
	overlay.player = player

func _set_paused(value: bool) -> void:
	get_tree().paused = value
	menu.visible = value
	overlay.hide()
	if is_instance_valid(hud): hud.visible = not value
	if is_instance_valid(player):
		player.set_process_input(not value)
		player.set_physics_process(not value)
		if value:
			player.velocity = Vector2.ZERO
			player.weapon_controller.cancel_reload()
	if value:
		if options_column.visible: options_column.get_child(0).grab_focus()
		else: play_button.grab_focus()

func _retry() -> void:
	if is_instance_valid(director) and director.is_complete:
		_new_run()
		return
	_rebuild()

func _new_run() -> void:
	checkpoint_recovery_required = false
	checkpoint = {"schema_version": 1, "stage": 0, "evidence": false, "completed": false}
	_checkpoint_reached(0, false, false)
	_rebuild()

func _rebuild() -> void:
	if overlay.collecting: overlay.cancel_capture("reinício da missão")
	if is_instance_valid(arena):
		remove_child(arena)
		arena.queue_free()
	arena = null
	_start()

func _checkpoint_reached(stage: int, evidence: bool, finished: bool) -> void:
	checkpoint = {"schema_version": 1, "stage": stage, "evidence": evidence, "completed": finished}
	if not store.save_checkpoint(stage, evidence, finished):
		save_notice.text = store.last_error
		if is_instance_valid(director):
			director.radio = "Não foi possível gravar checkpoint: " + store.last_error
			director.radio_remaining = 10.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if binding_action != "":
			_cancel_binding()
			return
		if options_column.visible:
			_close_options()
			return
		if arena == null: return
		if overlay.collecting: overlay.cancel_capture("menu aberto")
		_set_paused(not menu.visible)
	if event.is_action_pressed("restart") and is_instance_valid(player) and not menu.visible:
		_retry()
	if event.is_action_pressed("switch_preset"):
		_toggle_jump_preset()
	if event.is_action_pressed("toggle_fps"):
		cap_30 = not cap_30
		Engine.max_fps = 30 if cap_30 else 60
	if event.is_action_pressed("benchmark") and not menu.visible:
		overlay.show()
		overlay.begin_capture(10.0)
	if event.is_action_pressed("fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if event is InputEventKey and event.physical_keycode == KEY_F4 and event.pressed:
		overlay.visible = not overlay.visible

func _input(event: InputEvent) -> void:
	if binding_action == "" or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_ESCAPE:
		_cancel_binding()
		get_viewport().set_input_as_handled()
		return
	if event.physical_keycode in [KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F11]:
		save_notice.text = "Essa tecla está reservada aos atalhos da build."
		get_viewport().set_input_as_handled()
		return
	for action: String in ["move_left", "move_right", "jump", "dodge", "reload", "interact", "sprint", "crouch", "switch_weapon", "weapon_1", "weapon_2"]:
		if action == binding_action: continue
		for existing: InputEvent in InputMap.action_get_events(action):
			if existing is InputEventKey and existing.physical_keycode == event.physical_keycode:
				save_notice.text = "Tecla já usada por outra ação. Escolha outra ou restaure as teclas."
				get_viewport().set_input_as_handled()
				return
	settings.bindings[binding_action] = int(event.physical_keycode)
	_install_input()
	binding_button.text = "Definido: " + _binding_name(binding_action)
	binding_action = ""
	_refresh_binding_buttons()
	_save_settings()
	get_viewport().set_input_as_handled()

func _install_input() -> void:
	INPUT_SETUP.install(alternate_jump)
	for action: String in settings.get("bindings", {}):
		if not InputMap.has_action(action): continue
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey: InputMap.action_erase_event(action, event)
		var key := InputEventKey.new()
		key.physical_keycode = int(settings.bindings[action])
		InputMap.action_add_event(action, key)

func _binding_name(action: String) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey: return OS.get_keycode_string(event.physical_keycode)
	return "—"

func _begin_binding(action: String, button: Button) -> void:
	binding_action = action
	binding_button = button
	button.text = "Pressione tecla / Esc cancela"

func _cancel_binding() -> void:
	if binding_action.is_empty(): return
	binding_action = ""
	_refresh_binding_buttons()

func _refresh_binding_buttons() -> void:
	for action: String in binding_buttons:
		binding_buttons[action].text = BINDING_NAMES[action] + ": " + _binding_name(action)

func _toggle_jump_preset() -> void:
	alternate_jump = not alternate_jump
	settings.alternate_jump = alternate_jump
	_install_input()
	_save_settings()
	overlay.preset_label = "LB" if alternate_jump else "A"
	save_notice.text = "Salto no controle: " + ("LB" if alternate_jump else "A")

func _save_settings() -> void:
	if not store.save_settings(settings): save_notice.text = store.last_error

func _open_options() -> void:
	menu_column.hide()
	options_column.show()
	options_column.get_child(0).grab_focus()

func _close_options() -> void:
	_cancel_binding()
	options_column.hide()
	menu_column.show()
	play_button.grab_focus()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(player):
		if is_instance_valid(overlay) and overlay.collecting: overlay.cancel_capture("janela perdeu foco")
		_set_paused(true)

func _process(_delta: float) -> void:
	if is_instance_valid(player) and player.position.y > arena.world_bounds.end.y + 100:
		_retry()

func _write_probe() -> void:
	var file := FileAccess.open("user://prototype_probe.txt", FileAccess.WRITE)
	if file != null:
		file.store_line("RUPTURA combat prototype " + Time.get_datetime_string_from_system())
		file.close()
		print("USER_WRITE_OK=", ProjectSettings.globalize_path("user://prototype_probe.txt"))

func _play_tone() -> void:
	sound_bank.play("pickup")
