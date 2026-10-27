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
	var ink := Color("151a1c")
	# Meios pixels são pixels nativos na apresentação2×; a física permanece idêntica.
	draw_rect(Rect2(-7, -0.5, 14, 0.5), Color("8b9b86"))
	draw_rect(Rect2(-9, 0, 18, 0.5), Color(0.04, 0.07, 0.06, 0.5))
	match kind:
		"health": _draw_medical_case(ink)
		"ammo": _draw_ammo_case(ink)
		"shotgun": _draw_shotgun_case(ink)
		"evidence": _draw_evidence(ink)


func _draw_medical_case(ink: Color) -> void:
	# Maleta médica de couro verde; fechos e costuras fazem o volume parecer usado.
	draw_rect(Rect2(-4.5, -19, 9, 4), ink)
	draw_rect(Rect2(-3.5, -18, 7, 1), Color("8a9f8b"))
	draw_rect(Rect2(-3.5, -17, 1, 2), Color("718774"))
	draw_rect(Rect2(2.5, -17, 1, 2), Color("425b50"))
	draw_rect(Rect2(-9.5, -15.5, 19, 1), ink)
	draw_rect(Rect2(-10, -14.5, 20, 12), ink)
	draw_rect(Rect2(-9, -2.5, 18, 1), ink)
	draw_rect(Rect2(-9, -14, 18, 10.5), Color("557b6b"))
	draw_rect(Rect2(-8.5, -14.5, 17, 2), Color("7da18a"))
	draw_rect(Rect2(-8.5, -14.5, 15, 0.5), Color("c0c6a6"))
	draw_rect(Rect2(6.5, -12.5, 2.5, 9), Color("365c50"))
	draw_rect(Rect2(8.5, -12, 0.5, 8), Color("293e37"))
	draw_rect(Rect2(-8.5, -12, 0.5, 8), Color("a1b198"))
	for x: float in [-6.5, 4.5]:
		draw_rect(Rect2(x, -14, 2, 3.5), Color("313e35"))
		draw_rect(Rect2(x + 0.5, -14, 1, 2.5), Color("bea67d"))
		draw_rect(Rect2(x + 0.5, -13.5, 0.5, 1), Color("e4d0a7"))
	draw_rect(Rect2(-2, -12, 4, 8), Color("d6d5b4"))
	draw_rect(Rect2(-4, -10, 8, 4), Color("d6d5b4"))
	draw_rect(Rect2(-1.5, -11.5, 2.5, 0.5), Color("f3e8c6"))
	draw_rect(Rect2(3, -9.5, 0.5, 3), Color("a7b59b"))
	for stitch: int in range(7):
		draw_rect(Rect2(-7.5 + stitch * 2, -4.5, 0.5, 0.5), Color("91ab90"))
	draw_rect(Rect2(-7.5, -9, 1, 1.5), Color("334b40"))
	draw_rect(Rect2(5, -5, 1.5, 0.5), Color("a0b292"))


func _draw_ammo_case(ink: Color) -> void:
	draw_rect(Rect2(-9, -14.5, 18, 13), ink)
	draw_rect(Rect2(-8.5, -14, 17, 11.5), Color("6a6953"))
	draw_rect(Rect2(-8.5, -14, 17, 2), Color("a99b71"))
	draw_rect(Rect2(-8, -14, 15, 0.5), Color("d8c796"))
	draw_rect(Rect2(-8.5, -12, 17, 0.5), Color("3e4539"))
	draw_rect(Rect2(6, -11.5, 2.5, 9), Color("414a3d"))
	draw_rect(Rect2(-8, -11, 0.5, 7.5), Color("aaa27b"))
	# Cartuchos modelados em latão, com pontas claras e sombras nas bases.
	for x: float in [-5.5, -1.5, 2.5]:
		draw_rect(Rect2(x, -10, 2.5, 6), Color("453f2c"))
		draw_rect(Rect2(x + 0.5, -11, 1.5, 1.5), Color("d4b57d"))
		draw_rect(Rect2(x + 0.5, -9.5, 1.5, 5), Color("b68f52"))
		draw_rect(Rect2(x + 0.5, -9.5, 0.5, 4), Color("efd49b"))
		draw_rect(Rect2(x, -4.5, 2.5, 0.5), Color("e5bd78"))
		draw_rect(Rect2(x + 1.5, -8.5, 0.5, 3.5), Color("805b35"))
	for x: float in [-7.0, 6.5]:
		draw_rect(Rect2(x, -13.5, 1, 1), Color("d2c098"))
		draw_rect(Rect2(x, -3.5, 1, 1), Color("9a9977"))
	draw_rect(Rect2(-5.5, -2.5, 9, 0.5), Color("a79e7b"))


func _draw_shotgun_case(ink: Color) -> void:
	# Estojo aberto e silhueta horizontal de espingarda, distinta da munição.
	draw_rect(Rect2(-12, -14, 24, 12.5), ink)
	draw_rect(Rect2(-11.5, -13.5, 23, 11), Color("4f4942"))
	draw_rect(Rect2(-11, -13, 21.5, 0.5), Color("a98c69"))
	draw_rect(Rect2(-11, -12, 21.5, 8.5), Color("282d2b"))
	for index: int in range(9):
		draw_rect(Rect2(-10.5 + index * 2.5, -11.5, 0.5, 7), Color("353c36"))
	draw_rect(Rect2(-3, -10.5, 13.5, 2), Color("a9b2aa"))
	draw_rect(Rect2(-2.5, -10.5, 12, 0.5), Color("d4d5bd"))
	draw_rect(Rect2(-3, -8.5, 13, 1), Color("39484c"))
	draw_rect(Rect2(8.5, -10, 2, 0.5), ink)
	draw_rect(Rect2(-7.5, -9.5, 8, 2.5), Color("6c7777"))
	draw_rect(Rect2(-7, -9.5, 6.5, 0.5), Color("9da8a0"))
	draw_rect(Rect2(-3, -7.5, 3, 2.5), ink)
	draw_rect(Rect2(-2.5, -7, 2, 1), Color("7e725a"))
	draw_rect(Rect2(1, -8, 6.5, 2), Color("aa7351"))
	draw_rect(Rect2(2, -8, 5, 0.5), Color("c69264"))
	draw_rect(Rect2(-10, -8, 4.5, 4), Color("956244"))
	draw_rect(Rect2(-9.5, -7.5, 1, 3), Color("c08a5b"))
	draw_rect(Rect2(-10, -4, 3.5, 0.5), Color("d09c6a"))
	for x: float in [-8.0, 7.0]:
		draw_rect(Rect2(x, -3, 2, 1), Color("b9a57c"))


func _draw_evidence(ink: Color) -> void:
	# Pasta executiva com folha, dobra e lacre. O vermelho é selo, não aviso de ataque.
	draw_rect(Rect2(-8.5, -20.5, 17, 19), ink)
	draw_rect(Rect2(-8, -20, 15.5, 17.5), Color("9b8a68"))
	draw_rect(Rect2(-7.5, -19.5, 14.5, 0.5), Color("d0bd92"))
	draw_rect(Rect2(-6.5, -22, 12.5, 18), Color("d2cfb4"))
	draw_rect(Rect2(-6, -21.5, 10.5, 0.5), Color("ede3c6"))
	draw_rect(Rect2(4, -22, 2, 3), Color("979e92"))
	draw_rect(Rect2(4.5, -21.5, 1, 1.5), Color("eff0d2"))
	draw_rect(Rect2(-5, -19, 6.5, 1.5), Color("475f63"))
	for row: int in range(4):
		draw_rect(Rect2(-5, -15.5 + row * 2, 7.5 - float(row % 3), 0.5), Color("7c8b80"))
	# A aba e o lacre ficam à frente do documento.
	draw_rect(Rect2(-8, -9, 15.5, 6), Color("b4a17b"))
	draw_rect(Rect2(-7.5, -9, 14.5, 0.5), Color("dfc79b"))
	draw_rect(Rect2(4, -19, 3.5, 15.5), Color("708c89"))
	draw_rect(Rect2(4.5, -18.5, 0.5, 14), Color("a2b2a0"))
	draw_rect(Rect2(-1.5, -7, 4.5, 3.5), Color("7d443f"))
	draw_rect(Rect2(-1, -6.5, 3.5, 2.5), Color("b36d55"))
	draw_rect(Rect2(0, -6, 1.5, 0.5), Color("e3b17c"))
	draw_rect(Rect2(-6, -4.5, 3, 0.5), Color("806e51"))
