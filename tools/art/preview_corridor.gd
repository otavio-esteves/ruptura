extends SceneTree
## Capturas do corredor real e poses importadas. Perfil descartável, sem save real.
class ReviewMain:
	extends "res://game/core/main.gd"
	func _write_probe() -> void: pass
	func _notification(_what: int) -> void: pass

class HeroPose:
	extends Node2D
	var pose: Dictionary
	func _draw() -> void:
		preload("res://game/visuals/pixel_actor.gd").draw_actor(self, pose)

const OUT: String = "res://reports/corridor-review/"
var profile: String
var main: Node

func _initialize() -> void: call_deferred("run")
func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("A captura requer renderização gráfica.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUT)
	profile = "user://corridor_review_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(profile)
	main = ReviewMain.new()
	main.store.settings_path = profile + "/settings.json"
	main.store.mission_path = profile + "/cinzas.json"
	main.store.checkpoint_path = profile + "/checkpoint.json"
	root.add_child(main)
	main.sound_bank.volume = 0.0
	main.call("_open_corridor")
	main.director.set_physics_process(false)
	main.player.set_process_input(false)
	main.player.input_device = "gamepad"
	main.camera.position_smoothing_enabled = false
	for index: int in range(3):
		main.player.set_physics_process(true)
		main.player.position = Vector2([41.25, 202.5, 367.5][index], 620)
		main.player.velocity = Vector2.ZERO
		for tick: int in range(4):
			main.player.set("_has_focus", true)
			await physics_frame
		main.player.set_physics_process(false)
		main.player.set("_land_remaining", 0.0)
		main.player.set("_idle_cycle", 0.0)
		main.player.aim_direction = Vector2.RIGHT
		main.player.queue_redraw()
		main.camera.reset_smoothing()
		await capture(["entrance", "middle", "exit"][index])
	main.queue_free()
	await process_frame
	await process_frame
	paused = false
	var sheet := Node2D.new()
	root.add_child(sheet)
	var states: Array[String] = ["idle", "run", "crouch", "jump", "dodge", "hurt", "dead"]
	for index: int in range(states.size()):
		var actor := HeroPose.new()
		actor.pose = {"kind": "spectre", "state": states[index], "cycle": 0.35, "facing": 1.0, "aim": Vector2.RIGHT}
		actor.position = Vector2(85 + index * 180, 245)
		actor.scale = Vector2(4, 4)
		sheet.add_child(actor)
	for index: int in range(8):
		var actor := HeroPose.new()
		var aim := Vector2.from_angle(index * TAU / 8.0)
		actor.pose = {"kind": "spectre", "state": "idle", "cycle": 0.0, "facing": -1.0 if aim.x < 0 else 1.0, "aim": aim}
		actor.position = Vector2(75 + index * 160, 465)
		actor.scale = Vector2(4, 4)
		sheet.add_child(actor)
	for index: int in range(5):
		var actor := HeroPose.new()
		actor.pose = {"kind": "spectre", "state": ["idle", "idle", "idle", "crouch", "run"][index], "cycle": 0.0, "facing": 1.0, "aim": Vector2.RIGHT, "action": "reload", "action_progress": [0.1, 0.4, 0.7, 0.4, 0.7][index]}
		actor.position = Vector2(110 + index * 250, 705)
		actor.scale = Vector2(4, 4)
		sheet.add_child(actor)
	await capture("hero-poses")
	sheet.queue_free()
	await process_frame
	var directory := DirAccess.open(profile)
	for filename: String in directory.get_files(): directory.remove(filename)
	DirAccess.remove_absolute(profile)
	quit()

func capture(title: String) -> void:
	for tick: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	var path: String = OUT + title + ".png"
	assert(root.get_texture().get_image().save_png(path) == OK)
	print("CORRIDOR_REVIEW=", ProjectSettings.globalize_path(path))
