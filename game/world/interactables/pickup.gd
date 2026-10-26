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
	var ink := Color("101b23")
	# Pequena marca comum sob o item; as silhuetas comunicam o tipo sem depender da cor.
	draw_rect(Rect2(-7, -1, 14, 1), Color("34474b"))
	match kind:
		"health":
			draw_rect(Rect2(-5, -18, 10, 4), ink)
			draw_rect(Rect2(-3, -17, 6, 2), Color("8ab6a7"))
			draw_rect(Rect2(-10, -15, 20, 14), ink)
			draw_rect(Rect2(-9, -14, 18, 12), Color("648e84"))
			draw_rect(Rect2(-8, -14, 16, 2), Color("a1c6b5"))
			draw_rect(Rect2(6, -11, 3, 9), Color("426b65"))
			draw_rect(Rect2(-2, -12, 4, 8), Color("e0dec4"))
			draw_rect(Rect2(-4, -10, 8, 4), Color("e0dec4"))
			draw_rect(Rect2(-8, -9, 2, 4), Color("365950"))
		"ammo":
			draw_rect(Rect2(-9, -14, 18, 13), ink)
			draw_rect(Rect2(-8, -13, 16, 11), Color("777653"))
			draw_rect(Rect2(-8, -14, 16, 3), Color("b8aa73"))
			draw_rect(Rect2(5, -10, 3, 8), Color("50543f"))
			for x: float in [-5.0, -1.0, 3.0]:
				draw_rect(Rect2(x, -10, 2, 6), Color("dfc88a"))
				draw_rect(Rect2(x, -11, 1, 2), Color("ece1ac"))
				draw_rect(Rect2(x, -5, 2, 1), Color("a07e50"))
		"shotgun":
			draw_rect(Rect2(-11, -14, 22, 13), ink)
			draw_rect(Rect2(-10, -13, 20, 11), Color("514a43"))
			draw_rect(Rect2(-10, -13, 20, 1), Color("b18b70"))
			draw_rect(Rect2(-4, -11, 13, 2), Color("c6c9b7"))
			draw_rect(Rect2(-6, -10, 10, 3), Color("7b8790"))
			draw_rect(Rect2(-3, -9, 6, 3), Color("bb805e"))
			draw_rect(Rect2(-8, -9, 4, 5), Color("bb805e"))
			draw_rect(Rect2(-9, -6, 3, 2), Color("d0a075"))
			draw_rect(Rect2(6, -5, 2, 2), Color("927b61"))
		"evidence":
			draw_rect(Rect2(-8, -21, 16, 20), ink)
			draw_rect(Rect2(-7, -20, 14, 18), Color("bcc4b7"))
			draw_rect(Rect2(4, -19, 3, 17), Color("82969a"))
			draw_rect(Rect2(3, -20, 4, 4), Color("536c79"))
			draw_rect(Rect2(-5, -17, 6, 2), Color("47626e"))
			draw_rect(Rect2(-5, -13, 9, 1), Color("6a7c7c"))
			draw_rect(Rect2(-5, -10, 7, 1), Color("6a7c7c"))
			draw_rect(Rect2(-5, -7, 5, 1), Color("6a7c7c"))
			draw_rect(Rect2(1, -7, 4, 4), Color("a86658"))
			draw_rect(Rect2(2, -6, 2, 1), Color("d7a07b"))
