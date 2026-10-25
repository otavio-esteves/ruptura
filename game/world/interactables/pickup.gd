extends Area2D

signal collected(kind: String)

@export_enum("health", "ammo", "shotgun", "evidence") var kind: String = "ammo"
var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()


func configure(type: String) -> void:
	kind = type if type in ["health", "ammo", "shotgun", "evidence"] else "ammo"
	queue_redraw()


func _on_body_entered(actor: Node2D) -> void:
	if _collected or not actor.is_in_group("player") or bool(actor.get("is_dead")):
		return
	match kind:
		"health":
			if not actor.has_method("heal"):
				return
			actor.call("heal", 30.0)
		"ammo", "shotgun":
			var controller: Node = actor.get("weapon_controller") as Node
			if controller == null:
				return
			if kind == "ammo":
				controller.call("add_ammo", 30)
			else:
				controller.call("unlock_shotgun")
	_collected = true
	set_deferred("monitoring", false)
	hide()
	collected.emit(kind)
	queue_free()


func _draw() -> void:
	var color := Color("d3b979")
	match kind:
		"health":
			color = Color("91cbb8")
		"shotgun":
			color = Color("d79d7f")
		"evidence":
			color = Color("b5c8e2")
	draw_rect(Rect2(-9.0, -17.0, 18.0, 16.0), Color("18262e"))
	draw_rect(Rect2(-9.0, -17.0, 18.0, 16.0), color, false, 1.0)
	match kind:
		"health":
			draw_line(Vector2(-5.0, -9.0), Vector2(5.0, -9.0), color, 3.0)
			draw_line(Vector2(0.0, -14.0), Vector2(0.0, -4.0), color, 3.0)
		"ammo":
			for x: float in [-4.0, 0.0, 4.0]:
				draw_line(Vector2(x, -13.0), Vector2(x, -5.0), color, 2.0)
		"shotgun":
			draw_line(Vector2(-6.0, -11.0), Vector2(6.0, -11.0), color, 3.0)
			draw_line(Vector2(-4.0, -10.0), Vector2(-6.0, -5.0), color, 3.0)
		"evidence":
			draw_rect(Rect2(-5.0, -14.0, 10.0, 10.0), color, false, 1.0)
			draw_line(Vector2(-3.0, -10.0), Vector2(3.0, -10.0), color, 1.0)
