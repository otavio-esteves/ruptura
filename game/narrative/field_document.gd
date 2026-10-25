extends Area2D
## Optional evidence: readable in a short radio message, never blocks the mission.
signal found(id: String, text: String)
var document_id: String = ""
var document_text: String = ""
var _collected: bool = false
var _nearby: CharacterBody2D
var _pulse: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CircleShape2D.new()
	shape.radius = 34.0
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position.y = -12.0
	add_child(collider)
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"): _nearby = body as CharacterBody2D
	)
	body_exited.connect(func(body: Node2D) -> void:
		if body == _nearby: _nearby = null
	)

func _physics_process(delta: float) -> void:
	_pulse += delta
	if not _collected and is_instance_valid(_nearby) and not _nearby.is_dead and Input.is_action_just_pressed("interact"):
		_collected = true
		found.emit(document_id, document_text)
		queue_free()
	queue_redraw()

func _draw() -> void:
	var color := Color("c5b774")
	draw_rect(Rect2(-8, -20, 16, 20), Color("213b41"))
	draw_rect(Rect2(-8, -20, 16, 20), color, false, 1.0)
	for y: int in [-15, -10, -5]: draw_line(Vector2(-4, y), Vector2(5, y), color, 1.0)
	if is_instance_valid(_nearby):
		draw_string(ThemeDB.fallback_font, Vector2(-25, -29), "E / ↑ · ler", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
	else:
		draw_circle(Vector2(0, -27), 2.0, color * (0.65 + sin(_pulse * 3.0) * 0.15))
