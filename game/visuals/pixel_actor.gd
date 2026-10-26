extends RefCounted
## Render-only actor rig. Atlases are authored at native resolution, feet at origin.
## Body facing and weapon aim are deliberately independent. Never modifies physics.
static var _textures: Dictionary = {}
const ROOT: String = "res://assets/art/actors/"
const ARM_COLORS: Dictionary = {"spectre": Color("2b3037"), "recruit": Color("565c50"), "scout": Color("74605b"), "chacal": Color("76616a")}

static func draw_actor(canvas: CanvasItem, pose: Dictionary) -> void:
	var kind: String = str(pose.get("kind", "spectre"))
	if not kind in ["spectre", "recruit", "scout", "chacal"]: kind = "spectre"
	var large: bool = kind == "chacal"
	var state: String = str(pose.get("state", "idle"))
	var cycle: float = clampf(float(pose.get("cycle", 0.0)), 0.0, 0.9999)
	var facing: float = -1.0 if float(pose.get("facing", 1.0)) < 0.0 else 1.0
	var action: String = str(pose.get("action", "neutral"))
	var action_progress: float = clampf(float(pose.get("action_progress", 0.0)), 0.0, 1.0)
	var frame: int = _frame(state, cycle, bool(pose.get("crouch_moving", false)))
	if action == "windup" and state == "idle": frame = 20
	elif action == "recovery" and state == "idle": frame = 21
	elif large and action == "attack" and state == "run": frame = 23
	var frame_size := Vector2i(48, 48) if large else Vector2i(32, 40)
	var origin := Vector2i(24, 44) if large else Vector2i(16, 36)
	var atlas_name: String = "chacal_rage" if large and int(pose.get("phase", 1)) >= 2 else kind
	var tint: Color = Color(1.25, 1.14, 1.02) if bool(pose.get("flash", false)) else Color.WHITE
	if not state in ["jump", "apex", "fall"]:
		canvas.draw_rect(Rect2(-10 if large else -7, 0, 20 if large else 14, 2), Color(0.03, 0.05, 0.07, 0.35))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	canvas.draw_texture_rect_region(_texture(atlas_name), Rect2(-Vector2(origin), Vector2(frame_size)), Rect2(Vector2(Vector2i(frame % 8, frame / 8) * frame_size), Vector2(frame_size)), tint)
	canvas.draw_set_transform(Vector2.ZERO)
	if state == "dead": return
	var shoulder := Vector2(0, -24 if large else -18)
	if state == "crouch": shoulder.y = -10 if not large else -15
	if state == "dodge": shoulder.y = -11 if not large else -16
	if pose.has("shoulder"): shoulder = pose.shoulder
	var aim: Vector2 = pose.get("aim", Vector2(facing, 0))
	if aim.length_squared() < 0.001: aim = Vector2(facing, 0)
	aim = aim.normalized()
	var weapon: String = str(pose.get("weapon", "pistol"))
	if not weapon in ["pistol", "shotgun", "blade"]: weapon = "pistol"
	if weapon == "blade":
		if action == "neutral": aim = Vector2(facing, -0.7).normalized()
		elif action == "windup": aim = aim.rotated(-facing * lerpf(0.9, 0.5, action_progress))
		elif action == "attack": aim = aim.rotated(facing * lerpf(-0.5, 0.4, action_progress))
	var recoil: float = clampf(float(pose.get("recoil", 0.0)), 0.0, 1.0)
	var hand_origin: Vector2 = (shoulder - aim * roundf(recoil * 2.0)).round()
	var sleeve: Color = ARM_COLORS[kind]
	if large and int(pose.get("phase", 1)) >= 2: sleeve = Color("8a665c")
	_pixel_line(canvas, shoulder.round(), (hand_origin + aim * 7).round(), Color("11161b"), 4 if not large else 6)
	_pixel_line(canvas, shoulder.round(), (hand_origin + aim * 6).round(), sleeve, 2 if not large else 4)
	if kind == "spectre":
		_pixel_line(canvas, (shoulder + Vector2(0, -1)).round(), (hand_origin + aim * 4 + Vector2(0, -1)).round(), Color("3b4148"), 1)
		canvas.draw_rect(Rect2((hand_origin + aim * 4).round() - Vector2.ONE, Vector2(2, 2)), Color("c4c2b6"))
	var direction: int = posmod(roundi(aim.angle() * 32.0 / TAU), 32)
	var weapon_region := Rect2(Vector2(Vector2i(direction % 8, direction / 8) * 48), Vector2(48, 48))
	canvas.draw_texture_rect_region(_texture(weapon), Rect2(hand_origin - Vector2(24, 24), Vector2(48, 48)), weapon_region, tint)

static func _texture(name: String) -> Texture2D:
	if not _textures.has(name): _textures[name] = load(ROOT + name + ".png")
	return _textures[name] as Texture2D

static func _frame(state: String, cycle: float, crouch_moving: bool) -> int:
	match state:
		"run": return 4 + mini(7, int(cycle * 8))
		"crouch": return 13 + mini(3, int(cycle * 4)) if crouch_moving else 12
		"jump": return 17
		"apex": return 18
		"fall": return 19
		"land": return 20 if cycle < 0.5 else 21
		"dodge": return 22 + mini(3, int(cycle * 4))
		"hurt": return 26
		"dead": return 27 if cycle < 0.25 else 28
	return mini(3, int(cycle * 4))

static func _pixel_line(canvas: CanvasItem, from: Vector2, to: Vector2, color: Color, width: int) -> void:
	var steps: int = maxi(1, roundi(maxf(absf(to.x - from.x), absf(to.y - from.y))))
	for step: int in range(steps + 1):
		var point: Vector2 = from.lerp(to, float(step) / steps).round()
		canvas.draw_rect(Rect2(point - Vector2(floorf(width * 0.5), floorf(width * 0.5)), Vector2(width, width)), color)
