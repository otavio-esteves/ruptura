extends Node2D
## Munição é estado desta instância. Sem Resources compartilhados mutáveis.

signal feedback(kind: String, position: Vector2)
signal loadout_changed

const Flash = preload("res://game/combat/effects/combat_flash.gd")
const DEFINITIONS: Dictionary = {
	"pistol": {"name": "PISTOLA", "capacity": 12, "reserve": 72, "damage": 24.0, "cooldown": 0.22, "reload": 1.0, "range": 800.0, "pellets": 1},
	"shotgun": {"name": "ESPINGARDA", "capacity": 6, "reserve": 24, "damage": 10.0, "cooldown": 0.65, "reload": 1.5, "range": 420.0, "pellets": 5},
}
const MAX_EFFECTS: int = 12

var selected_weapon: String = "pistol"
var shotgun_unlocked: bool = false
var reduced_effects: bool = false
var _actor: CharacterBody2D
var _magazines: Dictionary = {"pistol": 12, "shotgun": 6}
var _reserves: Dictionary = {"pistol": 72, "shotgun": 24}
var _fire_remaining: float = 0.0
var _melee_remaining: float = 0.0
var _reload_remaining: float = 0.0
var _reload_weapon: String = ""
var _empty_remaining: float = 0.0
var _effects: Array[Node2D] = []
var _has_focus: bool = true


func setup(actor: CharacterBody2D) -> void:
	_actor = actor
	reset_loadout()


func reset_loadout() -> void:
	selected_weapon = "pistol"
	shotgun_unlocked = false
	_magazines = {"pistol": 12, "shotgun": 6}
	_reserves = {"pistol": 72, "shotgun": 24}
	_fire_remaining = 0.0
	_melee_remaining = 0.0
	_reload_remaining = 0.0
	_reload_weapon = ""
	_empty_remaining = 0.0
	for effect: Node2D in _effects:
		if is_instance_valid(effect):
			effect.queue_free()
	_effects.clear()
	loadout_changed.emit()


func add_ammo(amount: int) -> void:
	if amount <= 0:
		return
	_reserves["pistol"] = mini(240, int(_reserves["pistol"]) + amount)
	if shotgun_unlocked:
		_reserves["shotgun"] = mini(96, int(_reserves["shotgun"]) + maxi(1, amount / 3))
	loadout_changed.emit()


func unlock_shotgun() -> void:
	if not shotgun_unlocked:
		shotgun_unlocked = true
		select_weapon("shotgun")
	else:
		_reserves["shotgun"] = mini(96, int(_reserves["shotgun"]) + 6)
		loadout_changed.emit()


func snapshot() -> Dictionary:
	var definition: Dictionary = DEFINITIONS[selected_weapon]
	var reloading: bool = not _reload_weapon.is_empty()
	return {
		"selected_weapon": selected_weapon,
		"display_name": definition["name"],
		"ammo": int(_magazines[selected_weapon]),
		"reserve": int(_reserves[selected_weapon]),
		"capacity": int(definition["capacity"]),
		"reloading": reloading,
		"melee_active": _melee_remaining > 0.25,
		"melee_progress": clampf((0.45 - _melee_remaining) / 0.20, 0.0, 1.0),
		"reload_progress": 1.0 - _reload_remaining / float(definition["reload"]) if reloading else 0.0,
		"shotgun_unlocked": shotgun_unlocked,
		"cooldown": _fire_remaining,
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_has_focus = false
		cancel_reload()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_has_focus = true


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_actor):
		return
	_fire_remaining = maxf(0.0, _fire_remaining - delta)
	_melee_remaining = maxf(0.0, _melee_remaining - delta)
	_empty_remaining = maxf(0.0, _empty_remaining - delta)
	if not _can_act():
		cancel_reload()
		return
	if not _reload_weapon.is_empty():
		_reload_remaining = maxf(0.0, _reload_remaining - delta)
		if _reload_remaining <= 0.0:
			_complete_reload()
	if Input.is_action_just_pressed("weapon_1"):
		select_weapon("pistol")
	elif Input.is_action_just_pressed("weapon_2"):
		select_weapon("shotgun")
	elif Input.is_action_just_pressed("switch_weapon"):
		select_weapon("shotgun" if selected_weapon == "pistol" else "pistol")
	if Input.is_action_just_pressed("melee"):
		try_melee()
	elif Input.is_action_just_pressed("reload"):
		start_reload()
	elif Input.is_action_pressed("fire"):
		try_fire()


func _can_act() -> bool:
	return is_instance_valid(_actor) and _has_focus and not bool(_actor.get("is_dead")) and not bool(_actor.get("is_dodging"))


func select_weapon(weapon: String) -> bool:
	if not DEFINITIONS.has(weapon) or (weapon == "shotgun" and not shotgun_unlocked):
		return false
	if selected_weapon == weapon:
		return true
	cancel_reload()
	selected_weapon = weapon
	loadout_changed.emit()
	return true


func start_reload() -> bool:
	if not _can_act() or not _reload_weapon.is_empty() or _melee_remaining > 0.0:
		return false
	var capacity: int = int(DEFINITIONS[selected_weapon]["capacity"])
	if int(_magazines[selected_weapon]) >= capacity or int(_reserves[selected_weapon]) <= 0:
		return false
	_reload_weapon = selected_weapon
	_reload_remaining = float(DEFINITIONS[selected_weapon]["reload"])
	feedback.emit("reload", _shoulder())
	loadout_changed.emit()
	return true


func cancel_reload() -> void:
	if _reload_weapon.is_empty():
		return
	_reload_weapon = ""
	_reload_remaining = 0.0
	loadout_changed.emit()


func _complete_reload() -> void:
	if _reload_weapon.is_empty():
		return
	var weapon: String = _reload_weapon
	var capacity: int = int(DEFINITIONS[weapon]["capacity"])
	var transferred: int = mini(capacity - int(_magazines[weapon]), int(_reserves[weapon]))
	_magazines[weapon] = int(_magazines[weapon]) + transferred
	_reserves[weapon] = int(_reserves[weapon]) - transferred
	_reload_weapon = ""
	_reload_remaining = 0.0
	feedback.emit("reload_complete", _shoulder())
	loadout_changed.emit()


func try_fire() -> bool:
	if not _can_act() or _fire_remaining > 0.0 or _melee_remaining > 0.0 or not _reload_weapon.is_empty():
		return false
	if int(_magazines[selected_weapon]) <= 0:
		if _empty_remaining <= 0.0:
			feedback.emit("empty", _shoulder())
			_empty_remaining = 0.30
		return false
	var definition: Dictionary = DEFINITIONS[selected_weapon]
	_magazines[selected_weapon] = int(_magazines[selected_weapon]) - 1
	_fire_remaining = float(definition["cooldown"])
	var direction: Vector2 = _aim()
	var shoulder: Vector2 = _shoulder()
	var muzzle_distance: float = float(_actor.call("get_muzzle_distance")) if _actor.has_method("get_muzzle_distance") else 19.0
	var muzzle: Vector2 = shoulder + direction * muzzle_distance
	var obstruction: Dictionary = _ray(shoulder, muzzle)
	var segments: Array[Dictionary] = []
	var accumulated: Dictionary = {}
	var pellet_count: int = int(definition["pellets"])
	if not obstruction.is_empty():
		_record_hit(obstruction, float(definition["damage"]) * pellet_count, accumulated)
		segments.append({"from": shoulder, "to": obstruction["position"], "hit": true})
		feedback.emit("blocked", obstruction["position"])
	else:
		for index: int in range(pellet_count):
			var angle: float = (float(index) - float(pellet_count - 1) * 0.5) * 0.065
			var pellet_direction: Vector2 = direction.rotated(angle)
			var endpoint: Vector2 = muzzle + pellet_direction * float(definition["range"])
			var hit: Dictionary = _ray(muzzle, endpoint)
			if not hit.is_empty():
				endpoint = hit["position"]
				_record_hit(hit, float(definition["damage"]), accumulated)
			segments.append({"from": muzzle, "to": endpoint, "hit": not hit.is_empty()})
	for hit_id: int in accumulated:
		var entry: Dictionary = accumulated[hit_id]
		var target: Node = entry["target"]
		if is_instance_valid(target):
			var accepted: bool = bool(target.call("receive_damage", float(entry["damage"]), direction * (150.0 if selected_weapon == "shotgun" else 65.0), _actor))
			if accepted:
				feedback.emit("hit", entry["position"])
	_spawn_flash(segments, muzzle if obstruction.is_empty() else Vector2.INF)
	feedback.emit(selected_weapon, muzzle)
	loadout_changed.emit()
	return true


func try_melee() -> bool:
	if not _can_act() or _melee_remaining > 0.0:
		return false
	cancel_reload()
	_melee_remaining = 0.45
	var shoulder: Vector2 = _shoulder()
	var direction: Vector2 = _aim()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 35.0
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, shoulder)
	query.collision_mask = 12
	query.exclude = [_actor.get_rid()]
	var targets: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(query, 16)
	var contacted: Dictionary = {}
	for hit: Dictionary in targets:
		var target: Node2D = hit["collider"] as Node2D
		if target == null or not target.has_method("receive_damage"):
			continue
		var target_id: int = target.get_instance_id()
		if contacted.has(target_id):
			continue
		contacted[target_id] = true
		var center: Vector2 = target.global_position
		if target is CharacterBody2D:
			center.y -= 12.0
		var offset: Vector2 = center - shoulder
		if offset.length_squared() > 1.0 and direction.dot(offset.normalized()) < 0.05:
			continue
		var obstruction: Dictionary = _ray(shoulder, center)
		if not obstruction.is_empty() and obstruction["collider"] != target:
			continue
		var accepted: bool = bool(target.call("receive_damage", 24.0, direction * 210.0 + Vector2(0.0, -65.0), _actor))
		if accepted:
			feedback.emit("hit", center)
	var flash: Node2D = Flash.new()
	flash.set("is_melee", true)
	flash.set("melee_center", shoulder)
	flash.set("melee_direction", direction)
	flash.set("lifetime", 0.12)
	_add_effect(flash)
	feedback.emit("melee", shoulder)
	return true


func _record_hit(hit: Dictionary, damage: float, accumulated: Dictionary) -> void:
	var target: Node = hit["collider"] as Node
	if target == null or not target.has_method("receive_damage"):
		return
	var key: int = target.get_instance_id()
	if accumulated.has(key):
		accumulated[key]["damage"] = float(accumulated[key]["damage"]) + damage
	else:
		accumulated[key] = {"target": target, "damage": damage, "position": hit["position"]}


func _ray(start: Vector2, finish: Vector2) -> Dictionary:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, finish, 31, [_actor.get_rid()])
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query)


func _shoulder() -> Vector2:
	if _actor.has_method("get_fire_origin"): return _actor.call("get_fire_origin")
	return _actor.global_position + Vector2(0.0, -10.0 if bool(_actor.get("is_crouching")) else -18.0)


func _aim() -> Vector2:
	var direction: Vector2 = _actor.get("aim_direction")
	return direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT


func _spawn_flash(segments: Array[Dictionary], muzzle: Vector2) -> void:
	var flash: Node2D = Flash.new()
	flash.set("segments", segments)
	flash.set("muzzle", muzzle)
	flash.set("muzzle_direction", _aim())
	_add_effect(flash)


func _add_effect(effect: Node2D) -> void:
	if reduced_effects: effect.lifetime = 0.055
	var active: Array[Node2D] = []
	for previous: Node2D in _effects:
		if is_instance_valid(previous) and not previous.is_queued_for_deletion():
			active.append(previous)
	_effects = active
	if _effects.size() >= MAX_EFFECTS:
		_effects.pop_front().queue_free()
	_effects.append(effect)
	add_child(effect)
