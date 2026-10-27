extends StaticBody2D
## Cobertura estática; impulso altera somente o desenho, nunca o colisor.

signal destroyed(obj: Node)

@export_enum("crate", "barrel", "glass") var kind: String = "crate"
var health: float = 45.0
var is_dead: bool = false
var reduced_effects: bool = false
const EXPLOSION_RADIUS: float = 110.0
const EXPLOSION_DAMAGE: float = 65.0
const MAX_EXPLOSION_TARGETS: int = 64
const EFFECT_LIFETIME: float = 0.38

var _dimensions: Vector2 = Vector2(28.0, 30.0)
var _flash: float = 0.0
var _wobble: Vector2 = Vector2.ZERO
var _effect_age: float = 0.0
var _exploded: bool = false
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("damageable")
	add_to_group("destructibles")
	configure(kind)
	set_process(false)


func configure(type: String) -> void:
	kind = type if type in ["crate", "barrel", "glass"] else "crate"
	match kind:
		"barrel":
			health = 25.0
			_dimensions = Vector2(18.0, 28.0)
		"glass":
			health = 8.0
			_dimensions = Vector2(8.0, 40.0)
		_:
			health = 45.0
			_dimensions = Vector2(28.0, 30.0)
	if _collision != null:
		var shape := RectangleShape2D.new()
		shape.size = _dimensions
		_collision.shape = shape
		_collision.position = Vector2(0.0, -_dimensions.y * 0.5)
	queue_redraw()


func receive_damage(amount: float, impulse: Vector2, _source: Node = null) -> bool:
	if is_dead or amount <= 0.0 or not is_finite(amount):
		return false
	health = maxf(0.0, health - amount)
	_flash = 0.09
	_wobble = impulse.limit_length(180.0) * 0.025
	set_process(true)
	if health <= 0.0:
		_destroy()
	queue_redraw()
	return true


func _destroy() -> void:
	is_dead = true
	remove_from_group("damageable")
	_collision.set_deferred("disabled", true)
	# Diferir também a explosão: uma cadeia não recursa na pilha de dano.
	if kind == "barrel":
		call_deferred("_explode")
	destroyed.emit(self)


func _blast_center() -> Vector2:
	return global_position + Vector2(0.0, -_dimensions.y * 0.5)


func _explode() -> void:
	if _exploded or not is_inside_tree() or is_queued_for_deletion():
		return
	var ancestor: Node = get_parent()
	while ancestor != null:
		if ancestor.is_queued_for_deletion():
			return
		ancestor = ancestor.get_parent()
	_exploded = true
	var origin: Vector2 = _blast_center()
	var pending: Array[Dictionary] = []
	# Snapshot e LOS antes de aplicar dano: destruir cobertura durante esta onda
	# não faz o mesmo evento atravessá-la para atingir quem estava protegido.
	var candidates: Array[Node] = get_tree().get_nodes_in_group("damageable")
	for candidate: Node in candidates:
		if candidate == self or not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
			continue
		if not candidate is Node2D or not candidate.has_method("receive_damage"):
			continue
		var destination: Vector2 = (candidate as Node2D).global_position + Vector2(0.0, -12.0)
		if candidate.has_method("_blast_center"):
			destination = candidate.call("_blast_center")
		var distance: float = origin.distance_to(destination)
		if distance > EXPLOSION_RADIUS:
			continue
		var ray := PhysicsRayQueryParameters2D.create(origin, destination, 25)
		var excluded: Array[RID] = [get_rid()]
		if candidate is CollisionObject2D:
			excluded.append((candidate as CollisionObject2D).get_rid())
		ray.exclude = excluded
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		var direction: Vector2 = origin.direction_to(destination)
		if direction.is_zero_approx():
			direction = Vector2.UP
		var falloff: float = maxf(0.35, 1.0 - distance / EXPLOSION_RADIUS)
		pending.append({"target": candidate, "damage": EXPLOSION_DAMAGE * falloff, "impulse": direction * 270.0 * falloff})
		if pending.size() >= MAX_EXPLOSION_TARGETS:
			break
	for hit: Dictionary in pending:
		var target: Node = hit["target"]
		if is_instance_valid(target) and not target.is_queued_for_deletion():
			target.call("receive_damage", hit["damage"], hit["impulse"], self)
	queue_redraw()


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_wobble = _wobble.move_toward(Vector2.ZERO, delta * 60.0)
	if is_dead:
		_effect_age += delta
		if _effect_age >= EFFECT_LIFETIME:
			queue_free()
	elif _flash <= 0.0 and _wobble.is_zero_approx():
		set_process(false)
	queue_redraw()


func _draw() -> void:
	if is_dead:
		_draw_break_effect()
		return
	# Autoria em meios pixels do mundo: um pixel de tela na câmera2×.
	# A silhueta fica exatamente dentro das dimensões físicas conhecidas.
	var ink := Color("15171b")
	var edge := Color("b1a895") if _flash <= 0.0 else Color("fff0ce")
	draw_set_transform(_wobble.snapped(Vector2(0.5, 0.5)))
	draw_rect(Rect2(-_dimensions.x * 0.5 + 1, -1, _dimensions.x - 2, 1), Color(0.03, 0.04, 0.05, 0.5))
	match kind:
		"barrel": _draw_maintenance_drum(ink, edge)
		"glass": _draw_office_glass(ink, edge)
		_: _draw_archive_crate(ink, edge)
	draw_set_transform(Vector2.ZERO)


func _draw_archive_crate(ink: Color, edge: Color) -> void:
	# Caixa documental de fibra vulcanizada; tampa abaulada, ferragens e lateral.
	draw_rect(Rect2(-13, -30, 25, 1), ink)
	draw_rect(Rect2(-14, -29, 28, 27.5), ink)
	draw_rect(Rect2(-13, -1.5, 26, 1.5), ink)
	draw_rect(Rect2(-13, -28.5, 21, 26), Color("867860"))
	draw_rect(Rect2(-12.5, -27, 20, 23.5), Color("776b56"))
	draw_rect(Rect2(8, -28, 5, 25.5), Color("4d4d44"))
	draw_rect(Rect2(8.5, -27, 0.5, 24), Color("9e9477"))
	draw_rect(Rect2(12, -27, 1, 23), Color("303b37"))
	# A tampa projeta uma sombra curta, sem transformar cada caixa em armário.
	draw_rect(Rect2(-13.5, -29, 26.5, 3.5), Color("a19479"))
	draw_rect(Rect2(-12.5, -29, 24.5, 0.5), edge)
	draw_rect(Rect2(-13, -25.5, 26, 1), Color("3e4037"))
	draw_rect(Rect2(-12.5, -24.5, 20, 0.5), Color("a08e6e"))
	# Duas cintas finas e protetores nos cantos, com recortes e rebites de1px.
	for x: float in [-10.5, 4.0]:
		draw_rect(Rect2(x, -28.5, 2, 26), Color("353e37"))
		draw_rect(Rect2(x, -28.5, 0.5, 25.5), Color("83836b"))
		draw_rect(Rect2(x + 0.5, -27, 0.5, 1), Color("c3b593"))
		draw_rect(Rect2(x + 0.5, -5, 0.5, 1), Color("c3b593"))
	for x: float in [-13.0, 10.0]:
		for y: float in [-28.5, -5.5]:
			draw_rect(Rect2(x, y, 2.5, 3.5), Color("485047"))
			draw_rect(Rect2(x + 0.5, y + 0.5, 1.5, 0.5), edge.darkened(0.2))
			draw_rect(Rect2(x + 0.5, y + 1.5, 0.5, 0.5), Color("c0b497"))
	# Etiqueta de papel com dobra, carimbo vinho e linhas de registro.
	draw_rect(Rect2(-7.5, -22.5, 10.5, 7.5), Color("524e40"))
	draw_rect(Rect2(-7, -22, 10, 6.5), Color("c8bda1"))
	draw_rect(Rect2(-6.5, -21.5, 7, 0.5), Color("e3d3b2"))
	draw_rect(Rect2(1.5, -22, 1.5, 1.5), Color("8e866d"))
	for row: int in range(3):
		draw_rect(Rect2(-5.5, -20 + row * 1.5, 5.5 - row * 0.5, 0.5), Color("666759"))
	draw_rect(Rect2(-6.5, -16.5, 4, 1), Color("8c5149"))
	# Pega encaixada, com luz na borda superior e sombra abaixo.
	draw_rect(Rect2(-6, -11, 7, 4.5), Color("4b4d40"))
	draw_rect(Rect2(-5.5, -10.5, 6, 3.5), Color("242d29"))
	draw_rect(Rect2(-5, -10.5, 5, 0.5), Color("b3a486"))
	draw_rect(Rect2(-5, -7, 5, 0.5), Color("97896f"))
	# Desgaste esparso, determinístico e agrupado em torno das quinas.
	for index: int in range(10):
		var x: float = -12.0 + float((index * 19) % 39) * 0.5
		var y: float = -23.0 + float((index * 13) % 38) * 0.5
		draw_rect(Rect2(x, y, 1.5 + float(index % 3) * 0.5, 0.5), Color("a29475") if index % 2 == 0 else Color("5a5a49"))
	draw_rect(Rect2(9.5, -20, 2, 6), Color("746b54"))
	draw_rect(Rect2(10, -19.5, 1.5, 0.5), edge.darkened(0.2))
	draw_rect(Rect2(-8, -3, 11, 0.5), Color("a28f6a"))


func _draw_maintenance_drum(ink: Color, edge: Color) -> void:
	# Faixas verticais modelam o cilindro, com quinas em degraus de meio pixel.
	draw_rect(Rect2(-7, -28, 14, 1), ink)
	draw_rect(Rect2(-8.5, -27, 17, 25), ink)
	draw_rect(Rect2(-7, -2, 14, 2), ink)
	draw_rect(Rect2(-8, -26, 2, 23), Color("7c5448"))
	draw_rect(Rect2(-6, -26.5, 2, 24), Color("a16c55"))
	draw_rect(Rect2(-4, -26.5, 5.5, 24.5), Color("8e584b"))
	draw_rect(Rect2(1.5, -26.5, 3.5, 24.5), Color("73463f"))
	draw_rect(Rect2(5, -26, 2.5, 23), Color("51383a"))
	draw_rect(Rect2(7.5, -25, 0.5, 21.5), Color("322b31"))
	# Tampa elíptica em degraus, duas tampas de enchimento e aro gasto.
	draw_rect(Rect2(-6.5, -27.5, 13, 2.5), Color("b18b6d"))
	draw_rect(Rect2(-8, -26.5, 16, 1.5), Color("6e5145"))
	draw_rect(Rect2(-6.5, -27, 12, 0.5), edge)
	draw_rect(Rect2(-4, -26.5, 7, 1), Color("5c453e"))
	draw_rect(Rect2(3.5, -27, 2, 1.5), ink)
	draw_rect(Rect2(4, -27, 1, 0.5), Color("d0af84"))
	draw_rect(Rect2(-5, -26, 1, 0.5), Color("d0af84"))
	for y: float in [-23.5, -7.5]:
		draw_rect(Rect2(-9, y, 18, 2), Color("292c30"))
		draw_rect(Rect2(-8.5, y, 15, 0.5), edge.darkened(0.12))
		draw_rect(Rect2(-7, y + 0.5, 3.5, 0.5), Color("b0a18a"))
		draw_rect(Rect2(5.5, y + 0.5, 2.5, 1), Color("3a3031"))
	# Etiqueta amarela funcional: a única área saturada é o risco explosivo.
	draw_rect(Rect2(-4.5, -19.5, 9, 10), Color("3d2e28"))
	draw_rect(Rect2(-4, -19, 8, 9), Color("d0a36b"))
	draw_rect(Rect2(-3.5, -18.5, 7, 0.5), Color("ead1a0"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -18), Vector2(3, -12), Vector2(-3, -12)]), Color("302d2b"))
	draw_rect(Rect2(-0.5, -16.5, 1, 2.5), Color("eac78b"))
	draw_rect(Rect2(-0.5, -13.5, 1, 0.5), Color("eac78b"))
	draw_rect(Rect2(-2.5, -11.5, 5, 0.5), Color("8a6144"))
	# Ferrugem em pequenos grupos na base e abrasão na barriga do cilindro.
	for index: int in range(7):
		var x: float = -6.5 + float((index * 7) % 23) * 0.5
		var y: float = -5.5 + float(index % 3) * 0.5
		draw_rect(Rect2(x, y, 1.5, 1), Color("ba865c") if index % 2 == 0 else Color("4b4238"))
	draw_rect(Rect2(-6.5, -21, 0.5, 9), Color("c1906b"))
	draw_rect(Rect2(3.5, -21.5, 1.5, 0.5), Color("b49b7a"))
	draw_rect(Rect2(4, -20.5, 0.5, 1.5), Color("493c36"))
	draw_rect(Rect2(-6.5, -2, 13, 0.5), Color("a18367"))


func _draw_office_glass(ink: Color, edge: Color) -> void:
	# Perfil de alumínio e lâmina estreita de vidro; não sugere uma parede larga.
	draw_rect(Rect2(-4, -40, 8, 40), ink)
	draw_rect(Rect2(-3.5, -39.5, 7, 39), Color("536268"))
	draw_rect(Rect2(-3, -39, 1, 38), Color("aeb9b3"))
	draw_rect(Rect2(-2, -39, 4, 38), Color("405663"))
	draw_rect(Rect2(2, -39, 1, 38), Color("293d47"))
	draw_rect(Rect2(3, -39.5, 0.5, 39), Color("7c8989"))
	# Reflexos inclinados preservam a leitura transparente e deixam lacunas.
	for index: int in range(5):
		var y: float = -36 + index * 6.5
		draw_rect(Rect2(-1.5, y, 1, 2), Color("98b4bb"))
		draw_rect(Rect2(-0.5, y + 2, 1, 2), Color("708f99"))
		draw_rect(Rect2(0.5, y + 4, 1, 1), Color("526e7b"))
	draw_rect(Rect2(-2, -29, 4.5, 3), Color("b9c1b7"))
	draw_rect(Rect2(-1.5, -28.5, 3.5, 0.5), Color("e0ded0"))
	draw_rect(Rect2(-1, -27, 2.5, 0.5), Color("89958e"))
	# Maçaneta escovada e parafusos mostram a orientação da folha.
	draw_rect(Rect2(-3.5, -15, 2.5, 0.5), Color("c5c5b5"))
	draw_rect(Rect2(-3.5, -15, 0.5, 4), Color("c5c5b5"))
	draw_rect(Rect2(-3, -14.5, 0.5, 3), Color("6b7a7b"))
	for y: float in [-39.0, -2.0]:
		draw_rect(Rect2(-4, y, 8, 1), edge.darkened(0.2))
		draw_rect(Rect2(-3.5, y, 0.5, 0.5), Color("e1dfcc"))
	draw_rect(Rect2(-4, -1, 8, 1), Color("303b42"))
	if health < 8.0:
		# Fratura angular fina; o feedback não altera a transparência ou colisão.
		var crack := PackedVector2Array([Vector2(1, -24), Vector2(-0.5, -20), Vector2(1.5, -17), Vector2(-1, -12), Vector2(0.5, -8)])
		draw_polyline(crack, ink, 0.5)
		draw_line(Vector2(-0.5, -20), Vector2(-2, -21.5), edge, 0.5)


func _draw_break_effect() -> void:
	var progress: float = clampf(_effect_age / EFFECT_LIFETIME, 0.0, 1.0)
	var center := Vector2(0.0, -_dimensions.y * 0.5)
	var color := Color("e7b675") if kind == "barrel" else Color("a5b1b2")
	color.a = 1.0 - progress
	if reduced_effects: color.a *= 0.6
	if kind == "barrel":
		draw_arc(center, 8.0 + EXPLOSION_RADIUS * progress, 0.0, TAU, 32, color, 2.0)
	var shards: int = 3 if reduced_effects else 10
	for index: int in range(shards):
		var direction := Vector2.from_angle(float(index) * TAU / float(shards))
		var shard_position: Vector2 = center + direction * progress * (54.0 if kind == "barrel" else 24.0) + Vector2(0.0, progress * progress * 14.0)
		draw_line(shard_position, shard_position + direction * 3.0, color, 2.0)
