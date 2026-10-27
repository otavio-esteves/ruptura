extends "res://game/world/levels/combat_director.gd"
## Abertura jogável isolada, sem checkpoint persistente ou escrita no save de Cinzas.
signal archive_requested
const EXIT := Vector2(390, 620)

func setup(actor: CharacterBody2D, _checkpoint: Dictionary, audio: Node, easier: bool) -> void:
	player = actor
	sound_bank = audio
	assisted = easier
	player.assisted = easier
	player.reset_to(Vector2(36, 620))
	_set_radio("LIA: O elevador ficou para trás. Atravesse a recepção; a saída está à direita.", 6.0)
	_update_objective()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player): return
	elapsed += delta
	radio_remaining = maxf(0.0, radio_remaining - delta)
	if player.is_dead: return
	if not encounter_started and player.position.x >= 225.0:
		_begin_encounter()
	if stage == 1 and player.position.distance_to(EXIT) < 24.0 and Input.is_action_just_pressed("interact"):
		archive_requested.emit()

func _begin_encounter() -> void:
	encounter_started = true
	_spawn_enemy("recruit", Vector2(326.25, 620))
	_set_radio("LIA: Segurança na saída. Espere o aviso e abra caminho.", 4.0)
	_update_objective()

func _on_enemy_died(_enemy: Node) -> void:
	active_enemies = maxi(0, active_enemies - 1)
	enemies_defeated += 1
	if active_enemies == 0:
		stage = 1
		player.heal(100.0)
		player.weapon_controller.reset_loadout()
		_set_radio("LIA: Caminho livre. E / ↑ junto à porta para entrar no Arquivo Morto.", 6.0)
	_update_objective()

func _links() -> Array[Dictionary]:
	return []

func _update_objective() -> void:
	objective = "RECEPÇÃO · atravesse o corredor" if not encounter_started else ("SAÍDA · E / ↑ para entrar no Arquivo Morto" if stage == 1 else "SEGURANÇA · abra caminho até a saída")
