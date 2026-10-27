extends RefCounted
## Poses recortadas da folha fornecida. Física e decisões de combate ficam no ator.
const ROOT: String = "res://assets/art/reference/"
const SCALE: float = 0.1875
static var _metadata: Array = []
static var _textures: Dictionary = {}

static func _load_assets() -> void:
	if not _metadata.is_empty(): return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "hero-poses.json"))
	_metadata = data.frames
	for name: String in ["poses", "bodies", "arms"]:
		_textures[name] = load(ROOT + "hero-" + name + ".png")

static func frame_for_pose(pose: Dictionary) -> int:
	var state: String = str(pose.get("state", "idle"))
	var cycle: float = clampf(float(pose.get("cycle", 0.0)), 0.0, 0.9999)
	var action: String = str(pose.get("action", "neutral"))
	if state == "dead": return 23 + mini(3, int(cycle * 4.0))
	if state == "hurt": return 21 + mini(1, int(cycle * 2.0))
	if state == "dodge": return [14, 20, 15, 14][mini(3, int(cycle * 4.0))]
	if action == "melee": return 31 + mini(3, int(float(pose.get("action_progress", 0.0)) * 4.0))
	if action == "reload" and state != "crouch" and state != "run":
		return 27 + mini(3, int(float(pose.get("action_progress", 0.0)) * 4.0))
	match state:
		"run": return 9 + mini(4, int(cycle * 5.0))
		"crouch": return 14 + mini(1, int(cycle * 2.0)) if bool(pose.get("crouch_moving", false)) else 14
		"jump": return 16
		"apex": return 17
		"fall": return 18
		"land": return 19
	if float(pose.get("recoil", 0.0)) > 0.1: return 3
	return mini(3, int(cycle * 4.0))

static func draw_actor(canvas: CanvasItem, pose: Dictionary) -> void:
	_load_assets()
	var frame: int = frame_for_pose(pose)
	var metadata: Dictionary = _metadata[frame]
	var origin := Vector2(float(metadata.origin[0]), float(metadata.origin[1]))
	var pivot := Vector2(float(metadata.pivot[0]), float(metadata.pivot[1]))
	var facing: float = -1.0 if float(pose.get("facing", 1.0)) < 0.0 else 1.0
	var aim: Vector2 = pose.get("aim", Vector2.RIGHT)
	var local_aim := Vector2(aim.x * facing, aim.y).normalized()
	var angle: float = local_aim.angle()
	var state: String = str(pose.get("state", "idle"))
	var action: String = str(pose.get("action", "neutral"))
	var cell := Vector2(256, 256)
	var region := Rect2(Vector2(frame % 8, frame / 8) * cell, cell)
	var destination := Rect2(-origin * SCALE, cell * SCALE)
	var tint: Color = Color(1.18, 1.08, 1.0) if bool(pose.get("flash", false)) else Color.WHITE
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1))
	# O recorte inteiro conserva a referência exatamente nas poses horizontais.
	var articulated: bool = absf(angle) > 0.10 and not state in ["dead", "hurt", "dodge"] and not action in ["reload", "melee"]
	if action == "reload" and state in ["crouch", "run"]:
		canvas.draw_texture_rect_region(_textures.bodies, destination, region, tint)
		var reload_frame: int = 27 + mini(3, int(float(pose.get("action_progress", 0.0)) * 4.0))
		var reload_metadata: Dictionary = _metadata[reload_frame]
		var reload_pivot := Vector2(float(reload_metadata.pivot[0]), float(reload_metadata.pivot[1]))
		var reload_region := Rect2(Vector2(reload_frame % 8, reload_frame / 8) * cell, cell)
		var joint: Vector2 = (pivot - origin) * SCALE
		canvas.draw_texture_rect_region(_textures.arms, Rect2(joint - reload_pivot * SCALE, cell * SCALE), reload_region, tint)
	elif not articulated:
		canvas.draw_texture_rect_region(_textures.poses, destination, region, tint)
	else:
		canvas.draw_texture_rect_region(_textures.bodies, destination, region, tint)
		var joint: Vector2 = (pivot - origin) * SCALE
		canvas.draw_set_transform(Vector2(joint.x * facing, joint.y), angle * facing, Vector2(facing, 1))
		canvas.draw_texture_rect_region(_textures.arms, Rect2(-pivot * SCALE, cell * SCALE), region, tint)
	canvas.draw_set_transform(Vector2.ZERO)

static func weapon_geometry(pose: Dictionary) -> Dictionary:
	_load_assets()
	var data: Dictionary = _metadata[frame_for_pose(pose)]
	var origin := Vector2(float(data.origin[0]), float(data.origin[1]))
	var pivot := Vector2(float(data.pivot[0]), float(data.pivot[1]))
	var muzzle := Vector2(float(data.muzzle[0]), float(data.muzzle[1]))
	var facing: float = -1.0 if float(pose.get("facing", 1.0)) < 0.0 else 1.0
	var aim: Vector2 = pose.get("aim", Vector2.RIGHT)
	var joint := (pivot - origin) * SCALE
	joint.x *= facing
	var side := Vector2(-aim.y, aim.x) * facing
	return {"origin": joint + side * (muzzle.y - pivot.y) * SCALE, "length": maxf(1.0, (muzzle.x - pivot.x) * SCALE)}
