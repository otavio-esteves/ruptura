extends SceneTree
var failures: int = 0
var directory: String

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	directory = "user://encounter_tests_%s_%s" % [OS.get_process_id(), Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(directory)
	var main: Node = load("res://game/core/main.tscn").instantiate()
	main.store.checkpoint_path = directory + "/checkpoint.json"
	main.store.settings_path = directory + "/settings.json"
	root.add_child(main)
	await process_frame
	main.call("_start")
	for stage: int in range(3):
		main.player.position = [Vector2(200, 610), Vector2(700, 610), Vector2(1180, 610)][stage]
		await frames(4)
		check(main.director.encounter_started and main.director.active_enemies == [1, 2, 3][stage], "encounter %d starts authored enemy set" % stage)
		for enemy: Node in get_nodes_in_group("enemies"):
			if not enemy.is_dead: enemy.receive_damage(999.0, Vector2.ZERO)
		await frames(80)
		check(main.director.stage == stage + 1, "clear %d advances checkpoint exactly once" % stage)
		check(int(main.store.load_checkpoint().get("stage", -1)) == stage + 1, "clear %d persists checkpoint" % stage)
	check(main.director.stage == 3 and main.director.active_enemies == 0, "mission reaches evidence objective")
	main.player.position = Vector2(1470, 606)
	await frames(8)
	check(main.director.evidence, "physical evidence pickup confirms objective")
	main.player.position = Vector2(1520, 610)
	Input.action_press("interact")
	await frames(3)
	Input.action_release("interact")
	check(main.director.is_complete, "interact at terminal completes transmission")
	check(main.store.load_checkpoint().get("completed", false), "victory persists")
	main.call("_new_run")
	await frames(3)
	var initial_count: int = root.get_child_count()
	for index: int in range(10):
		main.call("_retry")
		await frames(3)
	check(root.get_child_count() == initial_count, "ten resets leave no root accumulation")
	check(get_nodes_in_group("player").size() == 1, "ten resets leave one player")
	check(get_nodes_in_group("damageable").size() == 7, "ten resets restore exactly player and six props")
	main.player.receive_damage(999.0, Vector2.ZERO)
	check(main.player.is_dead, "lethal damage enters retry state")
	main.call("_retry")
	await frames(3)
	check(not main.player.is_dead and main.player.health.current_health == 100.0, "retry restores living player")
	check(main.player.weapon_controller.snapshot().ammo == 12, "retry restores authored magazine")
	main.queue_free()
	await process_frame
	paused = false
	for file: String in ["checkpoint.json", "checkpoint.json.bak", "checkpoint.json.tmp", "settings.json", "settings.json.bak", "settings.json.tmp"]:
		DirAccess.remove_absolute(directory + "/" + file)
	DirAccess.remove_absolute(directory)
	print("ENCOUNTER_SMOKE failures=", failures)
	quit(0 if failures == 0 else 1)

func frames(count: int) -> void:
	for index: int in range(count): await physics_frame
	await process_frame

func check(value: bool, message: String) -> void:
	if value: print("PASS ", message)
	else:
		failures += 1
		push_error(message)
