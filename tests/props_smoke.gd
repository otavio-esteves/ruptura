extends SceneTree
## godot --headless --path . --script tests/props_smoke.gd

const PROP = preload("res://game/world/interactables/destructible.tscn")
const PICKUP = preload("res://game/world/interactables/pickup.tscn")
var _failures: int = 0
var _destroy_events: Dictionary = {}
var _collected_events: int = 0


class DummyWeapons:
	extends Node
	var ammo: int = 0
	var shotgun_grants: int = 0
	func add_ammo(amount: int) -> void:
		ammo += amount
	func unlock_shotgun() -> void:
		shotgun_grants += 1


class DummyActor:
	extends CharacterBody2D
	var is_dead: bool = false
	var damage_calls: int = 0
	var received: float = 0.0
	var healed: float = 0.0
	var sources: Dictionary = {}
	var weapon_controller: Node
	func receive_damage(amount: float, _impulse: Vector2, source: Node = null) -> bool:
		damage_calls += 1
		received += amount
		if source != null:
			var identity: int = source.get_instance_id()
			sources[identity] = int(sources.get(identity, 0)) + 1
		return true
	func heal(amount: float) -> void:
		healed += amount


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_single_and_cover()
	await _test_prop_cover_snapshot()
	await _test_chain_and_cleanup()
	await _test_reset_cancels_pending()
	await _test_pickups()
	print("PROPS_SMOKE failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _test_single_and_cover() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var barrel: StaticBody2D = _prop(world, "barrel", Vector2(0.0, 100.0))
	var exposed: DummyActor = _actor(world, Vector2(-45.0, 100.0))
	var covered: DummyActor = _actor(world, Vector2(70.0, 100.0))
	_block(world, Vector2(35.0, 80.0), Vector2(10.0, 100.0), 1)
	await _frames(3)
	_check(bool(barrel.call("receive_damage", 25.0, Vector2.RIGHT * 40.0, null)), "lethal damage accepted")
	_check(not bool(barrel.call("receive_damage", 25.0, Vector2.ZERO, null)), "destroyed prop rejects duplicate damage")
	await _frames(4)
	_check(exposed.damage_calls == 1 and exposed.received > 0.0, "one explosion damages exposed actor once")
	_check(covered.damage_calls == 0, "world cover blocks blast line of sight")
	_check(int(_destroy_events.get(barrel.get_instance_id(), 0)) == 1, "destroyed signal emitted once")
	_check((barrel.get_node("CollisionShape2D") as CollisionShape2D).disabled, "destroyed coverage releases collider deferred")
	world.queue_free()
	await _frames(2)


func _test_chain_and_cleanup() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var first: StaticBody2D = _prop(world, "barrel", Vector2(0.0, 100.0))
	var second: StaticBody2D = _prop(world, "barrel", Vector2(60.0, 100.0))
	var third: StaticBody2D = _prop(world, "barrel", Vector2(120.0, 100.0))
	var witness: DummyActor = _actor(world, Vector2(-40.0, 100.0))
	await _frames(3)
	first.call("receive_damage", 100.0, Vector2.ZERO, null)
	await _frames(5)
	_check(bool(second.get("is_dead")) and bool(third.get("is_dead")), "deferred chain reaches next barrel beyond initial radius")
	_check(witness.damage_calls >= 1, "explosions also affect player group")
	var once_per_source: bool = true
	for count: int in witness.sources.values():
		once_per_source = once_per_source and count == 1
	_check(once_per_source, "each explosion source affects actor at most once")
	await create_timer(0.5).timeout
	_check(not is_instance_valid(first) and not is_instance_valid(second) and not is_instance_valid(third), "effects and props expire without persistent debris")
	world.queue_free()
	await _frames(2)


func _test_prop_cover_snapshot() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var barrel: StaticBody2D = _prop(world, "barrel", Vector2(0.0, 100.0))
	var cover: StaticBody2D = _prop(world, "crate", Vector2(30.0, 100.0))
	var covered: DummyActor = _actor(world, Vector2(75.0, 100.0))
	var glass: StaticBody2D = _prop(world, "glass", Vector2(-80.0, 100.0))
	await _frames(3)
	_check(is_equal_approx(float(cover.get("health")), 45.0) and is_equal_approx(float(glass.get("health")), 8.0), "crate and glass use distinct health budgets")
	barrel.call("receive_damage", 100.0, Vector2.ZERO, null)
	await _frames(4)
	_check(bool(cover.get("is_dead")), "near explosion destroys crate cover")
	_check(covered.damage_calls == 0, "same explosion respects cover before destruction")
	_check(bool(glass.get("is_dead")), "glass breaks under explosion damage")
	world.queue_free()
	await _frames(2)


func _test_reset_cancels_pending() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var barrel: StaticBody2D = _prop(world, "barrel", Vector2(0.0, 100.0))
	var survivor: DummyActor = _actor(root, Vector2(30.0, 100.0))
	await _frames(2)
	barrel.call("receive_damage", 100.0, Vector2.ZERO, null)
	world.queue_free()
	await _frames(3)
	_check(survivor.damage_calls == 0, "reset cancels pending explosion from deleted encounter")
	survivor.queue_free()
	await _frames(2)


func _test_pickups() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var actor: DummyActor = _actor(world, Vector2(0.0, 100.0))
	var enemy: DummyActor = _actor(world, Vector2(300.0, 100.0))
	enemy.remove_from_group("player")
	for kind: String in ["health", "ammo", "shotgun", "evidence"]:
		var pickup: Area2D = PICKUP.instantiate() as Area2D
		pickup.call("configure", kind)
		pickup.position = Vector2(500.0, 100.0)
		world.add_child(pickup)
		pickup.connect("collected", _on_collected)
		var previous_events: int = _collected_events
		pickup.call("_on_body_entered", enemy)
		actor.is_dead = true
		pickup.call("_on_body_entered", actor)
		_check(_collected_events == previous_events, "pickup %s ignores enemies and dead player" % kind)
		actor.is_dead = false
		pickup.call("_on_body_entered", actor)
		pickup.call("_on_body_entered", actor)
		_check(_collected_events == previous_events + 1, "pickup %s collects once" % kind)
		await _frames(2)
	_check(is_equal_approx(actor.healed, 30.0), "health amount granted once")
	_check(int(actor.weapon_controller.get("ammo")) == 30, "ammo amount granted once")
	_check(int(actor.weapon_controller.get("shotgun_grants")) == 1, "shotgun unlocked once")
	# Exercise actual Area2D overlap rather than only its callback.
	var proximity: Area2D = PICKUP.instantiate() as Area2D
	proximity.call("configure", "evidence")
	proximity.position = actor.position
	proximity.connect("collected", _on_collected)
	var before_overlap: int = _collected_events
	world.add_child(proximity)
	await _frames(5)
	_check(_collected_events == before_overlap + 1, "physical proximity triggers automatic collection")
	world.queue_free()
	await _frames(2)


func _prop(parent: Node, kind: String, position: Vector2) -> StaticBody2D:
	var prop: StaticBody2D = PROP.instantiate() as StaticBody2D
	prop.call("configure", kind)
	prop.position = position
	prop.connect("destroyed", _on_destroyed)
	parent.add_child(prop)
	return prop


func _actor(parent: Node, position: Vector2) -> DummyActor:
	var actor := DummyActor.new()
	actor.position = position
	actor.collision_layer = 2
	actor.collision_mask = 0
	actor.add_to_group("player")
	actor.add_to_group("damageable")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12.0, 24.0)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(0.0, -12.0)
	actor.add_child(collision)
	actor.weapon_controller = DummyWeapons.new()
	actor.add_child(actor.weapon_controller)
	parent.add_child(actor)
	return actor


func _block(parent: Node, center: Vector2, dimensions: Vector2, layer: int) -> void:
	var body := StaticBody2D.new()
	body.position = center
	body.collision_layer = layer
	body.collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


func _on_destroyed(prop: Node) -> void:
	var identity: int = prop.get_instance_id()
	_destroy_events[identity] = int(_destroy_events.get(identity, 0)) + 1


func _on_collected(_kind: String) -> void:
	_collected_events += 1


func _frames(count: int) -> void:
	for index: int in range(count):
		await physics_frame
	await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
