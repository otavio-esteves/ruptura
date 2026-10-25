extends VBoxContainer
## Scrollable options keep gamepad focus and fit the 640x360 viewport.
signal changed
signal rebind_requested(action: String, button: Button)
signal preset_requested
signal preview_requested
signal restore_requested
signal closed
var settings: Dictionary = {}
var binding_buttons: Dictionary = {}
var first_control: Control
var _body: VBoxContainer
const NAMES: Dictionary = {"move_left": "Esquerda", "move_right": "Direita", "jump": "Saltar", "dodge": "Esquiva", "reload": "Recarregar", "interact": "Interagir", "sprint": "Correr", "crouch": "Agachar"}

func _ready() -> void:
	custom_minimum_size.x = 240
	add_theme_constant_override("separation", 6)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(240, 270)
	scroll.follow_focus = true
	add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 5)
	scroll.add_child(_body)
	first_control = _toggle("assist", "Assistido (próximo retry)", "assisted")
	_add_button("Alternar salto A / LB", func() -> void: preset_requested.emit())
	_toggle("aim", "Assistência leve no controle", "aim_assist")
	_label("Deadzone radial do controle")
	_slider("aim_deadzone", 0.1, 0.35, 0.01)
	_toggle("effects", "Efeitos reduzidos", "reduced_effects")
	_toggle("shake", "Tremor de câmera", "screen_shake")
	_label("Volume dos efeitos")
	_slider("volume", 0.0, 1.0, 0.05)
	_add_button("Ouvir efeitos", func() -> void: preview_requested.emit())
	_label("Remapear teclas (Esc cancela)")
	for action: String in NAMES:
		var button := _add_button(NAMES[action], func() -> void: pass)
		binding_buttons[action] = button
		button.pressed.connect(func() -> void: rebind_requested.emit(action, button))
	_add_button("Restaurar teclas", func() -> void: restore_requested.emit())
	var back := Button.new()
	back.text = "Voltar"
	back.custom_minimum_size.y = 29
	back.add_theme_font_size_override("font_size", 12)
	back.pressed.connect(func() -> void: closed.emit())
	add_child(back)

func focus_first() -> void:
	if is_instance_valid(first_control): first_control.grab_focus()

func _toggle(_id: String, text: String, key: String) -> CheckButton:
	var button := CheckButton.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 11)
	button.button_pressed = settings.get(key, false)
	button.toggled.connect(func(value: bool) -> void: settings[key] = value; changed.emit())
	_body.add_child(button)
	return button

func _slider(key: String, minimum: float, maximum: float, step_value: float) -> void:
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step_value
	slider.value = settings.get(key, 0.2)
	slider.value_changed.connect(func(value: float) -> void: settings[key] = value; changed.emit())
	_body.add_child(slider)

func _label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 11)
	_body.add_child(label)

func _add_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 27
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(callback)
	_body.add_child(button)
	return button
