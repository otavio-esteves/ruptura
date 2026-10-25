extends CanvasLayer
## Render-frame deltas, not physics times. Headless runs never produce metrics.

var status := Label.new()
var samples: Array[float] = []
var collecting: bool = false
var elapsed: float = 0.0
var duration: float = 10.0
var warmup: float = 2.0
var quit_after_capture: bool = false
var player: CharacterBody2D
var preset_label: String = "A"
var status_tick: float = 0.0
var previous_frame_usec: int = 0

func _ready() -> void:
	layer = 10
	status.position = Vector2(10, 56)
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_color_override("font_color", Color("c4d0d7"))
	add_child(status)
	process_mode = Node.PROCESS_MODE_ALWAYS
	previous_frame_usec = Time.get_ticks_usec()

func begin_capture(seconds: float, close_after: bool = false) -> void:
	if DisplayServer.get_name() == "headless":
		push_warning("Benchmark ignorado: sessão headless não mede renderização.")
		return
	duration = maxf(seconds, 1.0)
	elapsed = 0.0
	warmup = 2.0
	samples.clear()
	collecting = true
	quit_after_capture = close_after

func _process(delta: float) -> void:
	var now_usec: int = Time.get_ticks_usec()
	var wall_delta: float = float(now_usec - previous_frame_usec) / 1000000.0
	previous_frame_usec = now_usec
	if collecting:
		if warmup > 0.0:
			warmup -= wall_delta
		else:
			samples.append(wall_delta * 1000.0)
			elapsed += wall_delta
			if elapsed >= duration:
				finish_capture()
	status_tick -= delta
	if status_tick > 0.0:
		return
	status_tick = 0.2
	var device: String = str(player.get("input_device")) if is_instance_valid(player) else "menu"
	status.text = "DEBUG %d FPS · %.1f ms · %s\nF2 salto %s · F3 30/60 FPS · F6 medir · F4 ocultar%s" % [Engine.get_frames_per_second(), wall_delta * 1000.0, device, preset_label, "\nMEDINDO (2s aquecimento)" if collecting else ""]

func finish_capture() -> void:
	collecting = false
	DirAccess.make_dir_recursive_absolute("user://benchmarks")
	var stamp: String = Time.get_datetime_string_from_system().replace(":", "-")
	var path: String = "user://benchmarks/%s.csv" % stamp
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Falha gravando benchmark: %s" % FileAccess.get_open_error())
	else:
		file.store_line("frame_ms")
		for value: float in samples:
			file.store_line("%.6f" % value)
		file.close()
		print("BENCHMARK_CSV=", ProjectSettings.globalize_path(path))
		var metadata := FileAccess.open(path + ".json", FileAccess.WRITE)
		if metadata != null:
			metadata.store_string(JSON.stringify({"engine": Engine.get_version_info().string, "gpu": RenderingServer.get_video_adapter_name(), "window": str(DisplayServer.window_get_size()), "viewport": str(get_viewport().get_visible_rect().size), "max_fps": Engine.max_fps, "scenario": "combat prototype; manual activity must be recorded separately", "warmup_seconds": 2, "frames": samples.size(), "clock": "Time.get_ticks_usec"}, "\t"))
			metadata.close()
	if quit_after_capture:
		get_tree().quit()

func cancel_capture(reason: String) -> void:
	collecting = false
	samples.clear()
	push_warning("Benchmark cancelado: " + reason)
	if quit_after_capture:
		get_tree().quit(1)
