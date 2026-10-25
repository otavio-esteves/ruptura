extends Node
## Short original synthesized sounds; fixed voice pool, no audio files.
var volume: float = 0.55
var voices: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var cursor: int = 0

func _ready() -> void:
	for index: int in range(8):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	for kind: String in ["pistol", "shotgun", "melee", "reload", "reload_complete", "empty", "hit", "blocked", "hurt", "explosion", "pickup", "clear", "victory", "boss_warn", "boss_phase", "boss_stun"]:
		streams[kind] = _synthesize(kind)

func play(kind: String, _position: Vector2 = Vector2.ZERO) -> void:
	if DisplayServer.get_name() == "headless" or volume <= 0.0 or not streams.has(kind):
		return
	var voice: AudioStreamPlayer = voices[cursor]
	cursor = (cursor + 1) % voices.size()
	voice.stream = streams[kind]
	voice.volume_db = linear_to_db(volume * 0.6)
	voice.play()

func _exit_tree() -> void:
	for voice: AudioStreamPlayer in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
	streams.clear()

func _synthesize(kind: String) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var seconds: float = 0.10
	var frequency: float = 200.0
	var noisy: bool = false
	match kind:
		"boss_warn": frequency = 180.0; seconds = 0.20
		"boss_phase": frequency = 150.0; seconds = 0.55
		"boss_stun": frequency = 320.0; seconds = 0.20; noisy = true
		"pistol": frequency = 140.0; noisy = true
		"shotgun": frequency = 85.0; seconds = 0.22; noisy = true
		"explosion": frequency = 50.0; seconds = 0.38; noisy = true
		"melee": frequency = 220.0; seconds = 0.08; noisy = true
		"hurt": frequency = 110.0; seconds = 0.18
		"hit": frequency = 700.0; seconds = 0.045
		"pickup": frequency = 880.0; seconds = 0.18
		"clear": frequency = 660.0; seconds = 0.30
		"victory": frequency = 520.0; seconds = 0.65
		"empty", "blocked": frequency = 80.0; seconds = 0.04
		"reload_complete": frequency = 400.0; seconds = 0.07
		"reload": frequency = 260.0; seconds = 0.08
	var count: int = int(seconds * stream.mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 417
	for index: int in range(count):
		var progress: float = float(index) / count
		var pitch: float = frequency * (1.0 - 0.4 * progress)
		if kind in ["pickup", "clear", "victory", "boss_warn", "boss_phase", "boss_stun"]:
			pitch = frequency * (1.0 + floorf(progress * 3.0) * 0.25)
		var sample: float = sin(TAU * pitch * index / stream.mix_rate)
		if noisy:
			sample = sample * 0.4 + rng.randf_range(-1.0, 1.0) * 0.6
		var envelope: float = minf(1.0, progress * 30.0) * pow(1.0 - progress, 2.0)
		bytes.encode_s16(index * 2, int(sample * envelope * 17000.0))
	stream.data = bytes
	return stream
