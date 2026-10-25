extends SceneTree
## Headless lógico; não valida percepção de impacto ou conforto do controle.

class Actor extends CharacterBody2D:
	var aim_direction: Vector2 = Vector2.RIGHT
	var is_dead: bool = false
	var is_dodging: bool = false
	var is_crouching: bool = false

class Target extends StaticBody2D:
	var damage_received: float = 0.0
	var damage_calls: int = 0

	func receive_damage(amount: float, _impulse: Vector2, _source: Node = null) -> bool:
		damage_received += amount
		damage_calls += 1
		return true

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for action: String in ["fire", "reload", "melee", "switch_weapon", "weapon_1", "weapon_2"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var actor: Actor = Actor.new()
	actor.position = Vector2(0.0, 100.0)
	root.add_child(actor)
	var controller: Node2D = load("res://game/combat/weapons/weapon_controller.gd").new() as Node2D
	actor.add_child(controller)
	controller.call("setup", actor)
	controller.set_physics_process(false)
	var target: Target = Target.new()
	target.position = Vector2(150.0, 82.0)
	target.collision_layer = 4
	_add_shape(target, Vector2(20.0, 90.0))
	root.add_child(target)
	await physics_frame
	await process_frame
	_check(bool(controller.call("try_fire")), "first pistol shot fires")
	_check(target.damage_received == 24.0, "pistol hits target")
	_check(not bool(controller.call("try_fire")), "cooldown blocks repeated shot in same tick")
	_check(_state(controller)["ammo"] == 11, "one accepted shot consumes exactly one round")
	controller.call("_physics_process", 0.25)
	_check(bool(controller.call("try_fire")), "shot available after cooldown")
	_check(bool(controller.call("start_reload")), "partial magazine can reload")
	controller.call("_physics_process", 0.5)
	_check(_state(controller)["ammo"] == 10 and _state(controller)["reserve"] == 72, "reload transfers nothing before completion")
	actor.is_dodging = true
	controller.call("_physics_process", 0.75)
	_check(not _state(controller)["reloading"] and _state(controller)["ammo"] == 10, "dodge cancels before transfer")
	actor.is_dodging = false
	controller.call("start_reload")
	controller.call("_physics_process", 1.1)
	_check(_state(controller)["ammo"] == 12 and _state(controller)["reserve"] == 70, "reload transfers exact missing rounds")
	controller.call("_physics_process", 2.0)
	_check(_state(controller)["reserve"] == 70, "completed reload cannot duplicate ammunition")
	_check(not bool(controller.call("select_weapon", "shotgun")), "shotgun selection locked before pickup")
	controller.call("unlock_shotgun")
	var before_calls: int = target.damage_calls
	var before_damage: float = target.damage_received
	controller.call("try_fire")
	_check(target.damage_calls == before_calls + 1 and target.damage_received == before_damage + 50.0, "shotgun aggregates five pellets once per target")
	controller.call("reset_loadout")
	_check(_state(controller)["selected_weapon"] == "pistol" and _state(controller)["ammo"] == 12 and not _state(controller)["shotgun_unlocked"], "retry restores original loadout")
	var wall: StaticBody2D = StaticBody2D.new()
	wall.position = Vector2(10.0, 82.0)
	wall.collision_layer = 1
	_add_shape(wall, Vector2(3.0, 70.0))
	root.add_child(wall)
	await physics_frame
	await process_frame
	before_damage = target.damage_received
	controller.call("try_fire")
	_check(target.damage_received == before_damage, "wall between shoulder and muzzle blocks shot")
	_check(_state(controller)["ammo"] == 11, "blocked discharge still consumes round")
	target.position.x = 25.0
	await physics_frame
	await process_frame
	controller.call("try_melee")
	_check(target.damage_received == before_damage, "melee cannot reach target through wall")
	wall.queue_free()
	await physics_frame
	await process_frame
	controller.call("_physics_process", 0.5)
	_check(bool(controller.call("try_melee")) and target.damage_received == before_damage + 24.0, "melee damages visible close target")
	_check(not bool(controller.call("try_melee")), "melee cooldown blocks repeated contact")
	actor.is_dead = true
	controller.call("_physics_process", 1.0)
	_check(not bool(controller.call("try_fire")) and not bool(controller.call("try_melee")), "dead actor cannot attack")
	print("WEAPONS_SMOKE failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _state(controller: Node2D) -> Dictionary:
	return controller.call("snapshot")


func _add_shape(body: CollisionObject2D, size: Vector2) -> void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
