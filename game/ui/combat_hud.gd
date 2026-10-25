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
var is_mission: bool = false
var boss_label := Label.new()
var boss_bar := ColorRect.new()
var boss_fill := ColorRect.new()
var dodge_label := Label.new()
var result_stats := Label.new()

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
	objective.size.x = 520
	objective.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_style(dodge_label, Vector2(540, 29), 10)
	_style(boss_label, Vector2(150, 258), 11)
	boss_bar.position = Vector2(150, 277)
	boss_bar.size = Vector2(340, 8)
	boss_bar.color = Color("16272b")
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_fill.color = Color("bd8167")
	boss_fill.position = Vector2(1, 1)
	boss_fill.size = Vector2(338, 6)
	boss_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_bar.add_child(boss_fill)
	add_child(boss_bar)
	boss_bar.hide()
	boss_label.hide()
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
	var result_style := StyleBoxFlat.new()
	result_style.bg_color = Color(0.035, 0.055, 0.066, 0.97)
	result_style.border_color = Color("667c7c")
	result_style.set_border_width_all(1)
	result_style.content_margin_left = 12
	result_style.content_margin_right = 12
	result_style.content_margin_top = 10
	result_style.content_margin_bottom = 10
	result.add_theme_stylebox_override("panel", result_style)
	add_child(result)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	result.add_child(box)
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_title.add_theme_font_size_override("font_size", 17)
	box.add_child(result_title)
	result_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_stats.add_theme_font_size_override("font_size", 12)
	box.add_child(result_stats)
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

func attach(actor: CharacterBody2D, level_director: Node2D, mission: bool) -> void:
	player = actor
	director = level_director
	is_mission = mission
	_result_visible = false
	result.hide()
	boss_bar.hide()
	boss_label.hide()

func _process(_delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(director):
		return
	var state: Dictionary = player.weapon_controller.snapshot()
	var reload_text: String = "  RECARREGANDO %d%%" % int(float(state.get("reload_progress", 0.0)) * 100.0) if state.get("reloading", false) else ""
	header.text = "VIDA %03d   %s  %02d / %02d%s" % [int(player.health.current_health), str(state.get("display_name", "PISTOLA")).to_upper(), int(state.get("ammo", 0)), int(state.get("reserve", 0)), reload_text]
	objective.text = director.objective
	dodge_label.text = "ESQUIVA %.1f" % player.dodge_cooldown_remaining if player.dodge_cooldown_remaining > 0 else "ESQUIVA ✓"
	var boss: Node
	if is_mission and is_instance_valid(director.get("boss")):
		boss = director.get("boss")
	var show_boss: bool = is_instance_valid(boss) and not boss.is_dead
	boss_label.visible = show_boss
	boss_bar.visible = show_boss
	if show_boss:
		boss_label.text = "%s · FASE %d" % [boss.display_name, boss.phase]
		boss_fill.size.x = 338.0 * clampf(boss.health.current_health / boss.health.max_health, 0.0, 1.0)
	if director.radio_remaining > 0.0:
		radio.text = director.radio
	else:
		radio.text = "Mouse1 / RT atirar · Mouse2 / RB golpear · R / X recarregar\n1/2/Q / Y trocar · E / ↑ interagir · F5 retry · Esc menu"
	var ended: bool = player.is_dead or director.is_complete
	if ended and not _result_visible:
		_result_visible = true
		result_title.text = "CINZAS · TRANSMISSÃO CONCLUÍDA\nA resistência abriu os portões." if director.is_complete else "ESPECTRO CAIU\nO checkpoint foi preservado."
		if is_mission:
			result_stats.text = "%d/2 registros opcionais · %d queda(s)\n%s" % [director.secrets.size(), director.deaths, "Espingarda liberada · Chacal derrotada" if director.boss_defeated else "Aprenda o aviso e tente outro caminho."]
		else:
			result_stats.text = "Laboratório de combate"
		retry.text = "Repetir missão / F5" if director.is_complete else "Retomar checkpoint / F5"
		result.show()
		retry.grab_focus()
	elif not ended:
		_result_visible = false
		result.hide()
