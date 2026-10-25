extends SceneTree
## Contratos de autoria e colisão real dos três setores, sem main/save/diretor.

var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://game/world/sectors/cinzas_sector.tscn") as PackedScene
	for sector_index: int in range(3):
		var sector: Node2D = scene.instantiate() as Node2D
		sector.set("sector_index", sector_index)
		root.add_child(sector)
		await physics_frame
		await process_frame
		var bounds: Rect2 = sector.get("world_bounds")
		_check(bounds.size == Vector2([1800.0, 2000.0, 1600.0][sector_index], 720), "sector %d has authored bounds" % sector_index)
		var stages: Array = [0, 1] if sector_index == 0 else ([2, 3] if sector_index == 1 else [4, 5, 6])
		for stage: int in stages:
			var layout: Dictionary = sector.call("get_stage_layout", stage)
			_check_layout(sector, layout, stage, bounds)
		var links: Array[Dictionary] = sector.get("navigation_links")
		_check(not links.is_empty(), "sector %d exposes navigation links" % sector_index)
		for link: Dictionary in links:
			var from: Vector2 = link["from"]
			var to: Vector2 = link["to"]
			_check(_has_surface(sector, from) and _has_surface(sector, to), "sector %d link endpoints lie on real surfaces" % sector_index)
			_check(absf(from.y - to.y) <= 68.0 and absf(from.x - to.x) <= 90.0, "sector %d link fits movement envelope" % sector_index)
		# Um corpo real cai até o chão; não basta o layout declarar y620.
		var probe: CharacterBody2D = CharacterBody2D.new()
		probe.collision_layer = 0
		probe.collision_mask = 17
		var collider: CollisionShape2D = CollisionShape2D.new()
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = Vector2(12, 24)
		collider.shape = shape
		collider.position.y = -12.0
		probe.add_child(collider)
		sector.add_child(probe)
		probe.position = Vector2(120, 550)
		for step: int in range(60):
			await physics_frame
			probe.velocity.y += 1050.0 / 60.0
			probe.move_and_slide()
		await process_frame
		_check(probe.is_on_floor() and absf(probe.position.y - 620.0) < 2.0, "sector %d spawn settles on collision floor" % sector_index)
		sector.queue_free()
		await process_frame
	print("SECTORS_SMOKE failures=", _failures)
	quit(0 if _failures == 0 else 1)


func _check_layout(sector: Node2D, layout: Dictionary, stage: int, bounds: Rect2) -> void:
	for field: String in ["spawn", "trigger_x", "enemies", "props", "pickups", "exit_position", "terminal_position", "secrets"]:
		_check(layout.has(field), "stage %d exposes %s" % [stage, field])
	var spawn: Vector2 = layout["spawn"]
	_check(bounds.has_point(spawn) and float(layout["trigger_x"]) > spawn.x, "stage %d starts before its trigger" % stage)
	_check(_has_surface(sector, layout["exit_position"]), "stage %d exit is accessible at ground level" % stage)
	_check((layout["props"] as Array).size() >= 6 and (layout["props"] as Array).size() <= 10, "stage %d keeps prop budget" % stage)
	for field: String in ["enemies", "props", "pickups", "secrets"]:
		for entry: Dictionary in layout[field]:
			var position: Vector2 = entry["position"]
			_check(bounds.has_point(position) and _has_surface(sector, position), "stage %d %s rests on real geometry" % [stage, field])
	for entry: Dictionary in layout["props"]:
		var position: Vector2 = entry["position"]
		var prop_height: float = 40.0 if entry["kind"] == "glass" else 30.0
		var prop_width: float = 8.0 if entry["kind"] == "glass" else 28.0
		var occupied: Rect2 = Rect2(position - Vector2(prop_width * 0.5, prop_height), Vector2(prop_width, prop_height))
		var actor: Rect2 = Rect2(spawn - Vector2(6, 24), Vector2(12, 24))
		_check(not occupied.intersects(actor), "stage %d spawn clear of destructible props" % stage)
	if stage == 4:
		_check((layout["enemies"] as Array).size() == 1 and layout["enemies"][0]["kind"] == "chacal", "stage 4 contains Chacal alone")
	if stage >= 5:
		_check((layout["enemies"] as Array).is_empty(), "post-boss stages contain no fresh enemies")


func _has_surface(sector: Node2D, feet: Vector2) -> bool:
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(feet + Vector2(0, -2), feet + Vector2(0, 3), 17)
	return not sector.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS ", message)
	else:
		_failures += 1
		push_error("FAIL " + message)
