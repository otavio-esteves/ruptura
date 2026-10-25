extends Node2D
## A compact authored mission. Cleared sectors stay cleared in the checkpoint.
signal checkpoint_reached(stage: int, evidence: bool, completed: bool)
signal sector_requested
signal completed
signal message_changed(text: String)
const ENEMY = preload("res://game/actor/enemies/enemy.tscn")
const BOSS = preload("res://game/bosses/chacal.tscn")
const PROP = preload("res://game/world/interactables/destructible.tscn")
const PICKUP = preload("res://game/world/interactables/pickup.tscn")
const DOCUMENT = preload("res://game/narrative/field_document.gd")
const SECTOR_NAMES: Array[String] = ["RUÍNA / DISTRITO DE DESCARTE", "PÁTIO / CARGA MORTA", "CHACAL / TORRE DE CONTROLE"]
var player: CharacterBody2D
var sound_bank: Node
var sector: Node2D
var stage: int = 0
var evidence: bool = false
var is_complete: bool = false
var assisted: bool = false
var active_enemies: int = 0
var encounter_started: bool = false
var awaiting_exit: bool = false
var transition_remaining: float = -1.0
var objective: String = ""
var radio: String = ""
var radio_remaining: float = 0.0
var elapsed: float = 0.0
var enemies_defeated: int = 0
var deaths: int = 0
var secrets: Array[String] = []
var boss: CharacterBody2D
var boss_defeated: bool = false
var sector_title: String = ""
var shotgun_unlocked: bool = false
var _layout: Dictionary = {}
var _proof_spawned: bool = false
var _intro_remaining: float = 0.0
var _exit_requested: bool = false
var _collected_pickups: Dictionary = {}

static func sector_for_stage(value: int) -> int:
	if value < 2: return 0
	if value < 4: return 1
	return 2

func setup(actor: CharacterBody2D, checkpoint: Dictionary, audio: Node, easier: bool, level: Node2D) -> void:
	player = actor
	sound_bank = audio
	sector = level
	assisted = easier
	stage = clampi(int(checkpoint.get("stage", 0)), 0, 6)
	evidence = bool(checkpoint.get("evidence", false))
	is_complete = bool(checkpoint.get("completed", false))
	boss_defeated = bool(checkpoint.get("boss_defeated", stage >= 5))
	shotgun_unlocked = bool(checkpoint.get("shotgun_unlocked", stage >= 2))
	deaths = int(checkpoint.get("deaths", 0))
	for id: String in checkpoint.get("secrets", []): secrets.append(id)
	sector_title = SECTOR_NAMES[sector.sector_index]
	_layout = sector.get_stage_layout(stage)
	player.reset_to(_layout.spawn)
	player.assisted = assisted
	if shotgun_unlocked: player.weapon_controller.unlock_shotgun()
	_spawn_props()
	_spawn_pickups()
	_spawn_documents()
	player.died.connect(_on_player_died)
	if is_complete:
		_set_radio("NARA: A prova chegou. Os trabalhadores interromperam as cargas e abriram os portões.\nLIA: Não estamos sozinhos. A reconstrução começa agora.", 30.0)
	elif stage == 0:
		_set_radio("LIA: Espectro, você sobreviveu. A Chacal guarda os registros da sua execução. Siga até a torre; eu abro as passagens.", 9.0)
		_intro_remaining = 1.0
	elif stage == 4:
		_set_radio("LIA: A Chacal está na torre. O avanço deixa uma brecha; os barris podem quebrar a postura dela.", 8.0)
	elif stage >= 5:
		_set_radio("NARA: A segurança caiu. Pegue os registros e use o transmissor. Não basta derrubar a direção: todos precisam saber.", 9.0)
	else:
		_set_radio("LIA: Checkpoint seguro. Recursos repostos; procure altura, coberturas e um segundo caminho.", 6.0)
	_update_objective()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return
	elapsed += delta
	radio_remaining = maxf(0.0, radio_remaining - delta)
	_intro_remaining = maxf(0.0, _intro_remaining - delta)
	if player.is_dead or is_complete: return
	if awaiting_exit:
		if player.position.distance_to(_layout.exit_position) < 65.0 and Input.is_action_just_pressed("interact") and not _exit_requested:
			_exit_requested = true
			sector_requested.emit()
		queue_redraw()
		return
	if transition_remaining >= 0.0:
		transition_remaining -= delta
		if transition_remaining <= 0.0: _advance()
	elif stage <= 4 and not encounter_started and _intro_remaining <= 0.0:
		if player.position.x >= float(_layout.trigger_x): _begin_encounter()
	if stage == 5:
		if not evidence and not _proof_spawned:
			_proof_spawned = true
			_pickup("evidence", _layout.terminal_position + Vector2(-70, -2))
		if evidence and player.position.distance_to(_layout.terminal_position) < 65.0 and Input.is_action_just_pressed("interact"):
			_finish()
	queue_redraw()

func snapshot() -> Dictionary:
	return {"schema_version": 1, "stage": stage, "evidence": evidence, "completed": is_complete, "boss_defeated": stage >= 5, "shotgun_unlocked": shotgun_unlocked or stage >= 2, "secrets": secrets.duplicate(), "deaths": deaths}

func _begin_encounter() -> void:
	encounter_started = true
	for definition: Dictionary in _layout.enemies:
		var enemy: CharacterBody2D
		if definition.kind == "chacal":
			enemy = BOSS.instantiate()
			enemy.configure(player, sector.world_bounds, assisted)
			boss = enemy
			enemy.feedback.connect(sound_bank.play)
			enemy.phase_changed.connect(func(value: int) -> void:
				_set_radio("CHACAL: Você não vai sair daqui.\nLIA: Fase %d. Observe o aviso; afaste-se do impacto e ataque na recuperação." % value, 7.0)
			)
		else:
			enemy = ENEMY.instantiate()
			enemy.configure(definition.kind, player, assisted)
			enemy.navigation_links = sector.navigation_links
		enemy.position = definition.position
		add_child(enemy)
		active_enemies += 1
		enemy.died.connect(_on_enemy_died)
	match stage:
		0: _set_radio("LIA: Um recruta. O aviso laranja antecipa o tiro. Experimente a caixa e o golpe, sem ficar na linha de disparo.", 7.0)
		1: _set_radio("LIA: O batedor vai encurtar a distância. Use o caminho alto para mudar o ângulo.")
		2: _set_radio("NARA: O pátio está vigiado. A arma no caminho é uma espingarda; teste-a de perto.")
		3: _set_radio("LIA: A torre fica além do portão. Você tem cobertura e barris, mas as explosões também atingem você.")
		4: _set_radio("CHACAL: Eu mesma confirmei sua morte. Não vou cometer o mesmo erro.\nLIA: Espere o avanço terminar. Ela fica exposta na recuperação.", 9.0)
	_update_objective()

func _on_enemy_died(enemy: Node) -> void:
	active_enemies = maxi(active_enemies - 1, 0)
	enemies_defeated += 1
	if enemy == boss:
		boss_defeated = true
		boss = null
	sound_bank.play("hit")
	if active_enemies == 0 and encounter_started:
		transition_remaining = 1.1
		_set_radio("ÁREA SEGURA · vida e munição serão repostas no checkpoint.", 3.0)
	_update_objective()

func _advance() -> void:
	transition_remaining = -1.0
	var previous: int = stage
	stage = mini(stage + 1, 5)
	encounter_started = false
	player.heal(100.0)
	var keep_shotgun: bool = player.weapon_controller.snapshot().shotgun_unlocked or stage >= 2
	player.weapon_controller.reset_loadout()
	if keep_shotgun: player.weapon_controller.unlock_shotgun()
	shotgun_unlocked = keep_shotgun
	if previous in [1, 3]:
		awaiting_exit = true
		_set_radio("LIA: Portão liberado. Siga até a saída leste e pressione E / ↑. O próximo setor já está salvo.", 8.0)
	else:
		_layout = sector.get_stage_layout(stage)
		_spawn_pickups()
	if previous == 4:
		boss_defeated = true
		shotgun_unlocked = true
		_set_radio("CHACAL DERROTADA · ESPINGARDA LIBERADA\nNARA: Agora, os registros. Há gente esperando essa prova para se recusar a obedecer.", 10.0)
	checkpoint_reached.emit(stage, evidence, false)
	sound_bank.play("clear")
	_update_objective()

func _finish() -> void:
	stage = 6
	is_complete = true
	checkpoint_reached.emit(6, true, true)
	_set_radio("NARA: Transmissão confirmada. Os trabalhadores interromperam as cargas e abriram os portões.\nLIA: Você não está sozinho. A reconstrução começa agora.", 30.0)
	sound_bank.play("victory")
	_update_objective()
	completed.emit()

func _on_player_died() -> void:
	deaths = mini(99999, deaths + 1)
	# Keep the authored checkpoint stage; never persist a partial boss fight.
	checkpoint_reached.emit(stage, evidence, is_complete)

func _spawn_props() -> void:
	for definition: Dictionary in _layout.props:
		var prop: StaticBody2D = PROP.instantiate()
		prop.configure(definition.kind)
		prop.position = definition.position
		add_child(prop)
		prop.destroyed.connect(func(object: Node) -> void:
			if object.kind == "barrel": sound_bank.play("explosion")
		)

func _spawn_pickups() -> void:
	for definition: Dictionary in _layout.pickups:
		var key: String = str(definition.kind) + str(definition.position)
		if _collected_pickups.has(key): continue
		_collected_pickups[key] = true
		_pickup(definition.kind, definition.position)

func _pickup(kind: String, location: Vector2) -> void:
	var item: Area2D = PICKUP.instantiate()
	item.configure(kind)
	item.position = location
	add_child(item)
	item.collected.connect(func(type: String) -> void:
		sound_bank.play("pickup")
		if type == "evidence":
			evidence = true
			_set_radio("REGISTRO AUTENTICADO · aproxime-se do transmissor e pressione E / ↑.", 9.0)
		elif type == "shotgun":
			shotgun_unlocked = true
			_set_radio("ESPINGARDA · 2 / Q / Y para trocar. Alcance curto e dispersão; a pistola continua útil à distância.", 8.0)
		if type in ["evidence", "shotgun"]: checkpoint_reached.emit(stage, evidence, is_complete)
		_update_objective()
	)

func _spawn_documents() -> void:
	for definition: Dictionary in _layout.secrets:
		if definition.id in secrets: continue
		var item: Area2D = DOCUMENT.new()
		item.document_id = definition.id
		item.document_text = definition.text
		item.position = definition.position
		add_child(item)
		item.found.connect(func(id: String, text: String) -> void:
			if id in secrets: return
			secrets.append(id)
			player.heal(15.0)
			player.weapon_controller.add_ammo(18)
			_set_radio(text + "\nREGISTRO OPCIONAL · recursos recuperados.", 12.0)
			sound_bank.play("pickup")
			checkpoint_reached.emit(stage, evidence, is_complete)
		)

func _update_objective() -> void:
	if is_complete:
		objective = "TRANSMISSÃO CONCLUÍDA · a resistência recebeu os registros"
	elif awaiting_exit:
		objective = "E / ↑ · atravessar o portão leste →"
	elif stage == 5:
		objective = "E / ↑ · transmitir no terminal →" if evidence else "Recolha os registros da Chacal no terminal →"
	elif stage == 4 and encounter_started:
		objective = "CHACAL · desvie do aviso e ataque durante a recuperação"
	elif encounter_started:
		objective = "%d ameaça(s) · cobertura, golpe e altura abrem caminho" % active_enemies
	else:
		objective = "Avance para leste → · explore a rota alta para suprimentos"
	message_changed.emit(objective)

func _set_radio(text: String, seconds: float = 6.0) -> void:
	radio = text
	radio_remaining = seconds

func _draw() -> void:
	if sector == null or _layout.is_empty(): return
	if sector.sector_index < 2:
		var exit_at: Vector2 = _layout.exit_position
		var color: Color = Color("8dccb3") if awaiting_exit else Color("6d7b7c")
		draw_rect(Rect2(exit_at + Vector2(-13, -56), Vector2(26, 56)), Color("243a3f"))
		draw_rect(Rect2(exit_at + Vector2(-9, -50), Vector2(18, 42)), color, false, 2)
		if awaiting_exit:
			draw_string(ThemeDB.fallback_font, exit_at + Vector2(-46, -67), "E / ↑ · SAÍDA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
	else:
		var terminal: Vector2 = _layout.terminal_position
		var color: Color = Color("85c9b5") if stage >= 5 else Color("82776e")
		draw_rect(Rect2(terminal + Vector2(-16, -44), Vector2(32, 44)), Color("243a3f"))
		draw_rect(Rect2(terminal + Vector2(-11, -38), Vector2(22, 15)), color)
		if stage >= 5:
			draw_string(ThemeDB.fallback_font, terminal + Vector2(-48, -57), "TRANSMISSOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
		if is_complete:
			for index: int in range(3):
				var x: float = terminal.x - 170 - index * 24
				draw_rect(Rect2(x, terminal.y - 21, 10, 21), Color("7e9c8d"))
				draw_rect(Rect2(x + 1, terminal.y - 27, 8, 6), Color("c2b397"))
