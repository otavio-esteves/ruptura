extends Node2D
## Authored three-encounter loop. Reloading a checkpoint reconstructs transient world.
signal checkpoint_reached(stage: int, evidence: bool, completed: bool)
signal message_changed(text: String)
signal completed

const ENEMY = preload("res://game/actor/enemies/enemy.tscn")
const PROP = preload("res://game/world/interactables/destructible.tscn")
const PICKUP = preload("res://game/world/interactables/pickup.tscn")
var player: CharacterBody2D
var sound_bank: Node
var stage: int = 0
var evidence: bool = false
var is_complete: bool = false
var assisted: bool = false
var active_enemies: int = 0
var encounter_started: bool = false
var transition_remaining: float = -1.0
var objective: String = ""
var radio: String = ""
var radio_remaining: float = 0.0
var elapsed: float = 0.0
var enemies_defeated: int = 0
var _proof_spawned: bool = false

func setup(actor: CharacterBody2D, checkpoint: Dictionary, audio: Node, easier: bool) -> void:
	player = actor
	sound_bank = audio
	assisted = easier
	stage = int(checkpoint.get("stage", 0))
	evidence = bool(checkpoint.get("evidence", false))
	is_complete = bool(checkpoint.get("completed", false))
	_spawn_props()
	_spawn_pickups()
	player.reset_to(checkpoint_spawn(stage))
	player.assisted = assisted
	if stage >= 2:
		player.weapon_controller.unlock_shotgun()
	if is_complete:
		_set_radio("NARA: A transmissão chegou aos trabalhadores. Eles estão recusando as ordens.", 12.0)
	else:
		_set_radio("LIA: Espectro, os registros estão no terminal leste. Use as coberturas e volte inteiro.", 8.0)
	_update_objective()

static func checkpoint_spawn(index: int) -> Vector2:
	return [Vector2(120, 550), Vector2(620, 610), Vector2(1125, 550), Vector2(1380, 550)][clampi(index, 0, 3)]

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	elapsed += delta
	radio_remaining = maxf(0.0, radio_remaining - delta)
	if player.is_dead or is_complete:
		return
	if transition_remaining >= 0.0:
		transition_remaining -= delta
		if transition_remaining <= 0.0:
			_advance()
	elif stage < 3 and not encounter_started:
		var trigger: float = [160.0, 680.0, 1160.0][stage]
		if player.position.x >= trigger:
			_begin_encounter()
	if stage == 3:
		if not evidence and not _proof_spawned:
			_proof_spawned = true
			_pickup("evidence", Vector2(1470, 618))
		if evidence and player.position.distance_to(Vector2(1530, 620)) < 65.0 and Input.is_action_just_pressed("interact"):
			is_complete = true
			checkpoint_reached.emit(3, true, true)
			_set_radio("NARA: Arquivo autenticado. Os trabalhadores interromperam o carregamento. Conseguimos!", 20.0)
			sound_bank.play("victory")
			_update_objective()
			completed.emit()
	queue_redraw()

func _begin_encounter() -> void:
	encounter_started = true
	match stage:
		0:
			_spawn_enemy("recruit", Vector2(430, 618))
			_set_radio("LIA: Um recruta à frente. O aviso vermelho antecipa o disparo; mude de posição.")
		1:
			_spawn_enemy("recruit", Vector2(950, 346))
			_spawn_enemy("scout", Vector2(1050, 618))
			_set_radio("LIA: O batedor vai encurtar a distância. Um golpe o empurra; o barril também pode ajudar.")
		2:
			_spawn_enemy("recruit", Vector2(1490, 618))
			_spawn_enemy("scout", Vector2(1400, 550))
			_spawn_enemy("recruit", Vector2(1240, 482))
			_set_radio("NARA: Última defesa. Limpe o pátio para alcançarmos o terminal.")
	_update_objective()

func _spawn_enemy(kind: String, location: Vector2) -> void:
	var enemy: CharacterBody2D = ENEMY.instantiate()
	enemy.position = location
	enemy.configure(kind, player, assisted)
	enemy.navigation_links = _links()
	add_child(enemy)
	active_enemies += 1
	enemy.died.connect(_on_enemy_died)

func _on_enemy_died(_enemy: Node) -> void:
	active_enemies = maxi(0, active_enemies - 1)
	enemies_defeated += 1
	sound_bank.play("hit")
	if active_enemies == 0 and encounter_started:
		transition_remaining = 1.2
		_set_radio("ÁREA SEGURA · vida recuperada e checkpoint registrado.", 3.0)
	_update_objective()

func _advance() -> void:
	transition_remaining = -1.0
	stage = mini(stage + 1, 3)
	encounter_started = false
	player.heal(100.0)
	player.weapon_controller.reset_loadout()
	if stage >= 2:
		player.weapon_controller.unlock_shotgun()
	checkpoint_reached.emit(stage, evidence, false)
	sound_bank.play("clear")
	_update_objective()

func _spawn_props() -> void:
	for entry: Array in [["crate", Vector2(355, 620)], ["barrel", Vector2(810, 620)], ["crate", Vector2(1148, 620)], ["barrel", Vector2(1325, 620)], ["barrel", Vector2(1385, 620)], ["glass", Vector2(1460, 552)]]:
		var prop: StaticBody2D = PROP.instantiate()
		prop.position = entry[1]
		prop.configure(entry[0])
		add_child(prop)
		prop.destroyed.connect(func(object: Node) -> void:
			if object.get("kind") == "barrel": sound_bank.play("explosion")
		)

func _spawn_pickups() -> void:
	_pickup("shotgun", Vector2(700, 618))
	_pickup("ammo", Vector2(500, 482))
	_pickup("health", Vector2(715, 414))
	_pickup("ammo", Vector2(1210, 482))
	_pickup("health", Vector2(1475, 550))

func _pickup(kind: String, location: Vector2) -> void:
	var item: Area2D = PICKUP.instantiate()
	item.position = location
	item.configure(kind)
	add_child(item)
	item.collected.connect(func(type: String) -> void:
		sound_bank.play("pickup")
		if type == "evidence":
			evidence = true
			checkpoint_reached.emit(stage, true, false)
			_set_radio("REGISTRO OBTIDO · aproxime-se do terminal e pressione E / ↑ para transmitir.", 8.0)
			_update_objective()
		elif type == "shotgun":
			_set_radio("ESPINGARDA · 2 / Q ou direcional → para trocar. Forte de perto; espalha à distância.", 7.0)
	)

func _update_objective() -> void:
	if is_complete:
		objective = "TRANSMISSÃO CONCLUÍDA · F5 para repetir / Esc para menu"
	elif stage == 3:
		objective = "E / ↑ · transmitir no terminal leste" if evidence else "Recolha os registros no terminal leste →"
	elif encounter_started:
		objective = "%s · %d ameaça(s) restante(s)" % [["RUÍNA", "PÁTIO", "TERMINAL"][stage], active_enemies]
	else:
		objective = "%s · avance para leste →" % [["RUÍNA", "PÁTIO", "TERMINAL"][stage]]
	message_changed.emit(objective)

func _set_radio(text: String, seconds: float = 6.0) -> void:
	radio = text
	radio_remaining = seconds

func _links() -> Array[Dictionary]:
	var links: Array[Dictionary] = []
	var route: Array[Vector2] = [Vector2(230, 620), Vector2(280, 552), Vector2(400, 552), Vector2(460, 484), Vector2(575, 484), Vector2(635, 416), Vector2(750, 416), Vector2(810, 348), Vector2(965, 348), Vector2(1035, 416), Vector2(1140, 416), Vector2(1210, 484), Vector2(1320, 484), Vector2(1380, 552), Vector2(1490, 552), Vector2(1570, 620)]
	for index: int in range(0, route.size(), 2):
		links.append({"from": route[index], "to": route[index + 1]})
		links.append({"from": route[index + 1], "to": route[index]})
	return links

func _draw() -> void:
	var color: Color = Color("74c7b3") if stage >= 3 else Color("5a7880")
	draw_rect(Rect2(1514, 578, 30, 42), Color("243b42"))
	draw_rect(Rect2(1518, 583, 22, 14), color)
	draw_line(Vector2(1522, 603), Vector2(1536, 603), color, 2.0)
	if stage >= 3:
		draw_string(ThemeDB.fallback_font, Vector2(1485, 568), "TRANSMISSOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
