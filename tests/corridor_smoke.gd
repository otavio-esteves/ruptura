extends SceneTree
## Fluxo real do corredor, colisão e preservação de saves; sem testes de pixels.
class TestMain:
	extends "res://game/core/main.gd"
	func _write_probe() -> void: pass
	func _notification(_what: int) -> void: pass

var failures: int = 0

func _initialize() -> void: call_deferred("run")
func run() -> void:
	var directory: String = "user://corridor_tests_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(directory)
	var main := TestMain.new()
	main.store.settings_path = directory + "/settings.json"
	main.store.mission_path = directory + "/cinzas.json"
	main.store.checkpoint_path = directory + "/checkpoint.json"
	check(main.store.save_mission({"stage": 2, "evidence": false, "completed": false, "boss_defeated": false, "shotgun_unlocked": true, "secrets": [], "deaths": 3}), "corridor creates isolated existing mission fixture")
	check(main.store.save_checkpoint(1, false, false), "corridor creates isolated laboratory fixture")
	var before: String = FileAccess.get_file_as_string(main.store.mission_path)
	var lab_before: String = FileAccess.get_file_as_string(main.store.checkpoint_path)
	root.add_child(main)
	await process_frame
	check(main.play_button.text == "Jogar corredor / início", "corridor is directly accessible from first menu button")
	main.call("_open_corridor")
	await frames(8)
	check(main.mission_mode == "corridor" and main.player != null, "menu opens playable corridor")
	check(main.camera.zoom == Vector2(16.0 / 3.0, 16.0 / 3.0) and main.camera.position.y == -45.0, "corridor has its own close camera framing")
	check(main.arena.world_bounds.size.x == 407.25 and main.arena.navigation_links.is_empty(), "corridor is a single horizontal panorama")
	check(main.player.is_on_floor() and absf(main.player.position.y - 620.0) < 0.2, "painted floor agrees with actual foot contact")
	check(FileAccess.get_file_as_string(main.store.mission_path) == before and FileAccess.get_file_as_string(main.store.checkpoint_path) == lab_before, "opening corridor preserves mission and laboratory saves")
	main.player.velocity = Vector2(-200, 0)
	main.player.position.x = 5
	await frames(4)
	check(main.player.position.x >= 5.0, "corridor west wall blocks the actual player body")
	main.call("_retry")
	await frames(8)
	check(main.mission_mode == "corridor" and absf(main.player.position.x - 36.0) < 0.2, "corridor retry restores entrance")
	check(main.director.active_enemies == 0 and not main.director.encounter_started, "corridor retry starts without duplicate guards")
	main.player.position = Vector2(232.5, 620)
	main.director.call("_physics_process", 1.0 / 60.0)
	check(main.director.active_enemies == 1, "crossing reception starts one guard encounter")
	main.director.call("_physics_process", 1.0 / 60.0)
	check(main.director.active_enemies == 1, "corridor trigger cannot duplicate encounter")
	var enemy: Node = main.director.get_children().filter(func(child: Node) -> bool: return child.is_in_group("enemies"))[0]
	enemy.receive_damage(1000.0, Vector2.ZERO, main.player)
	check(main.director.stage == 1 and main.director.active_enemies == 0, "defeating guard unlocks corridor exit")
	check(main.director.objective.contains("E / ↑"), "unlocked exit exposes the interaction prompt")
	check(FileAccess.get_file_as_string(main.store.mission_path) == before, "clearing corridor does not overwrite mission checkpoint")
	main.player.position = Vector2(390, 620)
	Input.action_press("interact")
	main.director.call("_physics_process", 1.0 / 60.0)
	await process_frame
	Input.action_release("interact")
	await process_frame
	check(main.mission_mode == "cinzas" and main.director.stage == 2, "exit resumes existing Cinzas checkpoint")
	check(main.arena.sector_index == 1 and main.director.deaths == 3, "corridor exit retains prior sector and mission statistics")
	check(FileAccess.get_file_as_string(main.store.mission_path) == before, "entering existing mission preserves saved progress")
	main.call("_open_corridor")
	await frames(4)
	main.call("_new_run")
	await frames(4)
	check(main.mission_mode == "corridor" and FileAccess.get_file_as_string(main.store.mission_path) == before, "starting corridor again still preserves mission save")
	main.queue_free()
	await process_frame
	await process_frame
	paused = false
	var dir := DirAccess.open(directory)
	for file: String in dir.get_files(): dir.remove(file)
	DirAccess.remove_absolute(directory)
	print("CORRIDOR_SMOKE failures=", failures)
	quit(0 if failures == 0 else 1)

func frames(count: int) -> void:
	for index: int in range(count): await physics_frame

func check(condition: bool, message: String) -> void:
	if condition: print("PASS ", message)
	else:
		failures += 1
		push_error(message)
