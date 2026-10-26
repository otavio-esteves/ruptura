extends SceneTree
## Offline animation review of the real player controller. No mission or profile files.
const OUTPUT: String = "res://reports/movement-frames/"
const FPS: int = 12
const DURATION: float = 9.0
var player: CharacterBody2D
var caption: Label
var camera: Camera2D

class Backdrop extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(-200, -200, 3000, 600), Color("252b30"))
		for index: int in range(70):
			var x: float = index * 32.0 - 100
			draw_line(Vector2(x, -100), Vector2(x, 139), Color("343b40"), 1)
			draw_rect(Rect2(x, 140, 31, 20), Color("3a4145"))
			draw_rect(Rect2(x, 140, 16, 2), Color("a0a79c"))
			draw_rect(Rect2(x + 5, 148, 8, 2), Color("8c8d72"))

func _initialize() -> void: call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("A captura de movimento requer renderização gráfica.")
		quit(1)
		return
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var output_directory := DirAccess.open(OUTPUT)
	for filename: String in output_directory.get_files():
		if filename.length() == 13 and filename.begins_with("frame_") and filename.ends_with(".png") and filename.substr(6, 3).is_valid_int():
			output_directory.remove(filename)
	load("res://game/core/input_setup.gd").install()
	for action: String in ["move_left", "move_right", "jump", "crouch", "dodge", "sprint", "aim_left", "aim_right", "aim_up", "aim_down", "move_aim_left", "move_aim_right", "move_aim_up", "move_aim_down", "fire"]:
		InputMap.action_erase_events(action)
		Input.action_release(action)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(960, 360)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	root.add_child(viewport)
	viewport.add_child(Backdrop.new())
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(1200, 150)
	floor_body.collision_layer = 1
	var shape := RectangleShape2D.new()
	shape.size = Vector2(2800, 20)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	floor_body.add_child(collider)
	viewport.add_child(floor_body)
	player = load("res://game/actor/player/player.tscn").instantiate()
	viewport.add_child(player)
	player.reset_to(Vector2(200, 140))
	player.set_process_input(false)
	player.input_device = "gamepad"
	Input.action_press("aim_right")
	var weapons: Node2D = load("res://game/combat/weapons/weapon_controller.gd").new()
	player.add_child(weapons)
	player.weapon_controller = weapons
	weapons.setup(player)
	weapons.feedback.connect(func(kind: String, _position: Vector2) -> void:
		if kind == "pistol": player.recoil_remaining = 0.08
	)
	camera = Camera2D.new()
	camera.position = Vector2(200, 90)
	camera.zoom = Vector2(2, 2)
	viewport.add_child(camera)
	var hud := CanvasLayer.new()
	viewport.add_child(hud)
	caption = Label.new()
	caption.position = Vector2(16, 12)
	caption.add_theme_font_size_override("font_size", 18)
	hud.add_child(caption)
	for tick: int in range(8): await physics_frame
	var started: int = Time.get_ticks_usec()
	var next_frame: int = 0
	while float(Time.get_ticks_usec() - started) / 1000000.0 < DURATION:
		await process_frame
		var elapsed: float = float(Time.get_ticks_usec() - started) / 1000000.0
		# This is an offline capture fixture: keep it running if the preview window loses focus.
		player.set("_has_focus", true)
		weapons.set("_has_focus", true)
		_update_actions(elapsed)
		camera.position.x = roundf(player.position.x)
		if elapsed >= float(next_frame) / FPS:
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png(OUTPUT + "frame_%03d.png" % next_frame)
			next_frame += 1
	for action: String in ["move_left", "move_right", "jump", "crouch", "dodge", "sprint", "fire"]: Input.action_release(action)
	print("MOVEMENT_FRAMES=", next_frame, " FPS=", FPS, " PATH=", ProjectSettings.globalize_path(OUTPUT))
	quit()

func _hold(action: String, active: bool) -> void:
	if active and not Input.is_action_pressed(action): Input.action_press(action)
	elif not active and Input.is_action_pressed(action): Input.action_release(action)

func _update_actions(time: float) -> void:
	var text: String = "RESPIRAÇÃO / APOIO"
	var moving_right: bool = time >= 1.0 and time < 3.0 or time >= 4.0 and time < 6.8
	_hold("move_right", moving_right)
	_hold("move_left", time >= 3.0 and time < 4.0 or time >= 8.0)
	_hold("move_aim_right", moving_right)
	_hold("move_aim_left", time >= 3.0 and time < 4.0)
	player.independent_aim = time >= 8.0
	_hold("sprint", time >= 4.0 and time < 6.0)
	_hold("jump", time >= 5.0 and time < 5.30)
	_hold("crouch", time >= 6.0 and time < 6.8)
	_hold("dodge", time >= 7.0 and time < 7.08)
	_hold("fire", time >= 8.0 and time < 8.8)
	if time >= 8.0: text = "DIREITO OPCIONAL / MIRA INDEPENDENTE"
	elif time >= 7.0: text = "ESQUIVA / RECUPERAÇÃO"
	elif time >= 6.0: text = "AGACHAR E DESLOCAR"
	elif time >= 5.0: text = "SALTO / QUEDA / ATERRISSAGEM"
	elif time >= 4.0: text = "CORRIDA"
	elif time >= 3.0: text = "ESQUERDO / MIRA PELO MOVIMENTO"
	elif time >= 1.0: text = "PASSADA / PÉ DE APOIO"
	caption.text = "RUPTURA 0.4 · " + text
