extends CanvasLayer
signal retry_requested
var player: CharacterBody2D
var director: Node2D
var header := Label.new()
var objective := Label.new()
var radio := Label.new()
var result := PanelContainer.new()
var result_title := Label.new()
var retry := Button.new()
var _result_visible: bool = false

func _ready() -> void:
	layer = 5
	var top := ColorRect.new()
	top.color = Color(0.025, 0.04, 0.055, 0.92)
	top.position = Vector2(0, 0)
	top.size = Vector2(640, 47)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	_style(header, Vector2(12, 7), 14)
	_style(objective, Vector2(12, 29), 11)
	var bottom := ColorRect.new()
	bottom.position = Vector2(0, 304)
	bottom.size = Vector2(640, 56)
	bottom.color = Color(0.025, 0.04, 0.055, 0.9)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	_style(radio, Vector2(12, 310), 12)
	radio.size = Vector2(615, 46)
	radio.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.position = Vector2(125, 108)
	result.size = Vector2(390, 140)
	add_child(result)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	result.add_child(box)
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 17)
	box.add_child(result_title)
	retry.text = "Retomar checkpoint / F5"
	retry.pressed.connect(func() -> void: retry_requested.emit())
	box.add_child(retry)
	var hint := Label.new()
	hint.text = "Esc / Start · menu e opções"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	box.add_child(hint)
	result.hide()

func _style(label: Label, position_value: Vector2, font_size: int) -> void:
	label.position = position_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("d2dfdc"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)

func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(director):
		return
	var state: Dictionary = player.weapon_controller.snapshot()
	var reload_text: String = "  RECARREGANDO %d%%" % int(float(state.get("reload_progress", 0.0)) * 100.0) if state.get("reloading", false) else ""
	header.text = "VIDA %03d   %s  %02d / %02d%s" % [int(player.health.current_health), str(state.get("display_name", "PISTOLA")).to_upper(), int(state.get("ammo", 0)), int(state.get("reserve", 0)), reload_text]
	objective.text = director.objective
	if director.radio_remaining > 0.0:
		radio.text = director.radio
	else:
		radio.text = "Mouse1 / RT atirar · Mouse2 / RB golpear · R / X recarregar\n1/2/Q / Y trocar · E / ↑ interagir · F5 retry · Esc menu"
	var ended: bool = player.is_dead or director.is_complete
	if ended and not _result_visible:
		_result_visible = true
		result_title.text = "TRANSMISSÃO CONCLUÍDA\nA resistência recebeu os registros." if director.is_complete else "ESPECTRO CAIU\nO checkpoint foi preservado."
		retry.text = "Repetir missão / F5" if director.is_complete else "Retomar checkpoint / F5"
		result.show()
		retry.grab_focus()
	elif not ended:
		_result_visible = false
		result.hide()
