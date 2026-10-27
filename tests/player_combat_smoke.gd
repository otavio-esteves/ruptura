extends SceneTree
## Integra player real, health e arma; não simula conforto ou arte.

class ShotTarget:
	extends StaticBody2D
	var damage_received: float = 0.0
	func receive_damage(amount: float, _impulse: Vector2, _source: Node = null) -> bool:
		damage_received += amount
		return true

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	load("res://game/core/input_setup.gd").install(false)
	var floor_body: StaticBody2D = _block(Vector2(200, 110), Vector2(400, 20), 1)
	root.add_child(floor_body)
	var player: CharacterBody2D = load("res://game/actor/player/player.tscn").instantiate() as CharacterBody2D
	root.add_child(player)
	player.call("reset_to", Vector2(100, 95))
	var weapons: Node2D = load("res://game/combat/weapons/weapon_controller.gd").new() as Node2D
	player.add_child(weapons)
	player.set("weapon_controller", weapons)
	weapons.call("setup", player)
	await _frames(8)
	player.set_physics_process(false)
	weapons.set_physics_process(false)
	var health: Node = player.get("health")
	health.set_physics_process(false)
	_check(bool(player.call("receive_damage", 10.0, Vector2.ZERO)), "initial damage accepted")
	_check(not bool(player.call("receive_damage", 10.0, Vector2.ZERO)), "health immunity prevents repeated instant hit")
	_check(float(health.get("current_health")) == 90.0, "repeated damage does not stack")
	health.set("invulnerability_remaining", 0.0)
	player.set("is_dodging", true)
	player.set("_dodge_remaining", 0.18)
	_check(not bool(player.call("receive_damage", 20.0, Vector2.ZERO)), "middle dodge window evades incoming damage")
	player.set("_dodge_remaining", 0.05)
	_check(bool(player.call("receive_damage", 10.0, Vector2.ZERO)), "dodge recovery remains vulnerable")
	player.set("is_dodging", false)
	player.set("_dodge_remaining", 0.0)
	weapons.call("try_fire")
	_check(bool(weapons.call("start_reload")), "real player weapon starts reload")
	player.set("_hurt_control_remaining", 0.0)
	weapons.call("_physics_process", 0.35)
	var pose: Dictionary = player.call("_animation_pose")
	_check(pose.get("action") == "reload" and is_equal_approx(float(pose.get("action_progress", -1.0)), 0.35), "reload animation follows actual weapon transfer progress")
	player.set("is_dodging", true)
	pose = player.call("_animation_pose")
	_check(pose.get("action") == "neutral" and pose.get("state") == "dodge", "dodge immediately removes reload pose before any ammunition transfer")
	weapons.call("_physics_process", 1.2)
	var state: Dictionary = weapons.call("snapshot")
	_check(not state["reloading"] and state["ammo"] == 11, "real player dodge cancels reload without transferring ammo")
	player.call("reset_to", Vector2(100, 100))
	weapons.call("reset_loadout")
	_check(float(health.get("current_health")) == 100.0 and not bool(player.get("is_dead")), "reset restores health and alive state")
	player.call("receive_damage", 1.0, Vector2(0, 120))
	player.call("_physics_process", 1.0 / 60.0)
	_check(player.velocity.y >= -0.1, "downward impulse blocked by floor cannot create upward velocity")
	player.call("reset_to", Vector2(100, 100))
	player.call("_set_crouching", true)
	var overhead_prop: StaticBody2D = _block(Vector2(100, 78), Vector2(40, 8), 8)
	root.add_child(overhead_prop)
	await _frames(2)
	player.call("_set_crouching", false)
	_check(bool(player.get("is_crouching")), "solid prop prevents standing into its collider")
	overhead_prop.queue_free()
	await _frames(2)
	player.call("reset_to", Vector2(100, 100))
	var deaths: Array[int] = [0]
	player.connect("died", func() -> void: deaths[0] += 1)
	_check(bool(player.call("receive_damage", 1000.0, Vector2.ZERO)), "lethal damage accepted")
	_check(bool(player.get("is_dead")) and deaths[0] == 1, "death state and signal occur once")
	_check(not bool(player.call("receive_damage", 1000.0, Vector2.ZERO)) and deaths[0] == 1, "dead player cannot die twice")
	_check(not bool(weapons.call("try_fire")), "death blocks attached weapon")
	player.call("reset_to", Vector2(100, 100))
	weapons.call("reset_loadout")
	state = weapons.call("snapshot")
	_check(float(health.get("invulnerability_remaining")) == 0.0 and state["ammo"] == 12, "retry clears immunity and restores ammunition")
	# A origem importada da arma deve respeitar obstrução real, inclusive antes do cano.
	player.aim_direction = Vector2.RIGHT
	player.input_device = "gamepad"
	player.set("_facing", 1.0)
	player.set("_land_remaining", 0.0)
	var shot_origin: Vector2 = player.get_fire_origin()
	var muzzle_wall: StaticBody2D = _block(shot_origin + Vector2(5, 0), Vector2(2, 10), 1)
	root.add_child(muzzle_wall)
	var target := ShotTarget.new()
	target.collision_layer = 4
	target.collision_mask = 0
	target.position = shot_origin + Vector2(70, 0)
	var target_shape := RectangleShape2D.new()
	target_shape.size = Vector2(8, 16)
	var target_collision := CollisionShape2D.new()
	target_collision.shape = target_shape
	target.add_child(target_collision)
	target.add_to_group("damageable")
	root.add_child(target)
	await _frames(2)
	_check(bool(weapons.try_fire()) and target.damage_received == 0.0, "imported hero cannot fire through wall between arm and muzzle")
	_check(int(weapons.snapshot().ammo) == 11, "blocked imported-hero discharge still spends one round")
	muzzle_wall.queue_free()
	await _frames(2)
	weapons.reset_loadout()
	_check(bool(weapons.try_fire()) and target.damage_received == 24.0, "imported hero fires from visible arm origin after obstruction is removed")
	print("PLAYER_COMBAT_SMOKE failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _block(center: Vector2, size: Vector2, layer: int) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = center
	body.collision_layer = layer
	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = rectangle
	body.add_child(collision)
	return body


func _frames(count: int) -> void:
	for _index: int in range(count):
		await physics_frame
	await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
