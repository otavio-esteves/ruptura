extends RefCounted
## Render-only actor rig. High-density atlases use two authoring pixels per world unit.
## The logical frame, foot pivot, independently aimed gun and all gameplay positions are unchanged.
static var _textures: Dictionary = {}
const ReferenceHero = preload("res://game/visuals/reference_hero.gd")
const ROOT: String = "res://assets/art/actors/"
const DENSITY: int = 2
const ARM_COLORS: Dictionary = {"spectre": Color("2c2933"), "recruit": Color("4f5748"), "scout": Color("66504d"), "chacal": Color("66505d")}
const ARM_SHADE: Dictionary = {"spectre": Color("201e28"), "recruit": Color("30372f"), "scout": Color("3b2b32"), "chacal": Color("3e2d37")}
const ARM_EDGE: Dictionary = {"spectre": Color("5c535b"), "recruit": Color("919276"), "scout": Color("a68b71"), "chacal": Color("ab8883")}

static func draw_actor(canvas: CanvasItem, pose: Dictionary) -> void:
	if str(pose.get("kind", "spectre")) == "spectre":
		ReferenceHero.draw_actor(canvas, pose)
		return
	var kind: String = str(pose.get("kind", "spectre"))
	if not kind in ["spectre", "recruit", "scout", "chacal"]: kind = "spectre"
	var large: bool = kind == "chacal"
	var state: String = str(pose.get("state", "idle"))
	var cycle: float = clampf(float(pose.get("cycle", 0.0)), 0.0, 0.9999)
	var facing: float = -1.0 if float(pose.get("facing", 1.0)) < 0.0 else 1.0
	var action: String = str(pose.get("action", "neutral"))
	var action_progress: float = clampf(float(pose.get("action_progress", 0.0)), 0.0, 1.0)
	var frame: int = _frame(state, cycle, bool(pose.get("crouch_moving", false)))
	var reloading: bool = action == "reload" and not state in ["dead", "dodge", "hurt"]
	if reloading and state == "idle": frame = 29 + mini(2, int(action_progress * 3.0))
	if action == "windup" and state == "idle": frame = 20
	elif action == "recovery" and state == "idle": frame = 21
	elif large and action == "attack" and state == "run": frame = 23
	var frame_size := Vector2i(48, 48) if large else Vector2i(32, 40)
	var origin := Vector2i(24, 44) if large else Vector2i(16, 36)
	var source_size: Vector2i = frame_size * DENSITY
	var atlas_name: String = "chacal_rage" if large and int(pose.get("phase", 1)) >= 2 else kind
	var tint: Color = Color(1.18, 1.08, 1.0) if bool(pose.get("flash", false)) else Color.WHITE
	if not state in ["jump", "apex", "fall"]:
		# Ground contact remains quiet and does not read as an extra collision surface.
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(-8 if not large else -12, 0.5), Vector2(-5 if not large else -8, -0.5), Vector2(6 if not large else 10, -0.5), Vector2(9 if not large else 13, 0.5), Vector2(5 if not large else 8, 1.5), Vector2(-4 if not large else -7, 1.5)]), Color(0.025, 0.02, 0.03, 0.38))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	canvas.draw_texture_rect_region(_texture(atlas_name), Rect2(-Vector2(origin), Vector2(frame_size)), Rect2(Vector2(Vector2i(frame % 8, frame / 8) * source_size), Vector2(source_size)), tint)
	canvas.draw_set_transform(Vector2.ZERO)
	if state == "dead": return
	var shoulder := Vector2(0, -24 if large else -18)
	if state == "crouch": shoulder.y = -10 if not large else -15
	if state == "dodge": shoulder.y = -11 if not large else -22
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
	var reload_blend: float = 0.0
	if reloading:
		reload_blend = smoothstep(0.0, 0.18, action_progress) * (1.0 - smoothstep(0.80, 1.0, action_progress))
		var inspection_aim := Vector2(facing * (0.82 if weapon == "shotgun" else 0.60), -0.80).normalized()
		aim = aim.slerp(inspection_aim, reload_blend).normalized()
	var recoil: float = clampf(float(pose.get("recoil", 0.0)), 0.0, 1.0)
	var hand_origin: Vector2 = _snap(shoulder - aim * roundf(recoil * 2.0) + Vector2(facing * 0.75, 0.5) * reload_blend)
	var sleeve: Color = ARM_COLORS[kind]
	var shade: Color = ARM_SHADE[kind]
	var edge: Color = ARM_EDGE[kind]
	if large and int(pose.get("phase", 1)) >= 2:
		sleeve = Color("7d4e4b"); shade = Color("3e2d37"); edge = Color("c28f70")
	var upper_width: float = 4.5 if large else 3.5
	var fore_width: float = 4.0 if large else 3.0
	var root_x: float = -2.5
	var support_root_x: float = -3.0
	var support_start_y: float = 1.0
	if state == "dodge" or (large and action == "attack" and state == "run"):
		root_x = [0.5, 4.5, 4.5, -1.5][mini(3, frame - 22)]
		support_root_x = [0.0, 3.0, 3.0, -2.0][mini(3, frame - 22)]
		support_start_y = -1.5
	var gait: float = sin(cycle * TAU) * 0.5 if state == "run" else 0.0
	var elbow: Vector2 = _snap(hand_origin + aim * 2.0 + Vector2(-facing * 0.5, 3.0 + gait))
	var wrist: Vector2 = _snap(hand_origin + aim * 6.0)
	if weapon != "blade":
		var support_elbow: Vector2 = _snap(shoulder + Vector2(facing * (support_root_x - 1.0), 5.0 - gait))
		var support_hand: Vector2 = _snap(hand_origin + aim * (11.5 if weapon == "shotgun" else 7.5) + Vector2(0, 1.5))
		if reloading:
			var down: Vector2 = Vector2(-aim.y, aim.x) * facing
			var magazine_at: Vector2 = _snap(hand_origin + aim * (12.0 if weapon == "shotgun" else 10.0) + down * (2.0 if weapon == "shotgun" else 4.0))
			var belt_at: Vector2 = _snap(shoulder + Vector2(-facing * 3.0, 10.0))
			var task_hand: Vector2 = magazine_at
			if action_progress >= 0.25 and action_progress < 0.50:
				task_hand = magazine_at.lerp(belt_at, smoothstep(0.25, 0.50, action_progress))
			elif action_progress >= 0.50 and action_progress < 0.64:
				task_hand = belt_at
			elif action_progress >= 0.64 and action_progress < 0.84:
				task_hand = belt_at.lerp(magazine_at, smoothstep(0.64, 0.84, action_progress))
			var grip_blend: float = smoothstep(0.08, 0.22, action_progress) * (1.0 - smoothstep(0.85, 0.98, action_progress))
			support_hand = _snap(support_hand.lerp(task_hand, grip_blend))
			# Two equal visual arm segments keep the reaching forearm from stretching across the torso.
			var reload_root: Vector2 = _snap(shoulder + Vector2(facing * support_root_x, support_start_y))
			var reach_offset: Vector2 = task_hand - reload_root
			var bend: Vector2 = Vector2(-reach_offset.y, reach_offset.x).normalized() * facing
			var bend_height: float = sqrt(maxf(0.0, 7.5 * 7.5 - reach_offset.length_squared() * 0.25))
			var working_elbow: Vector2 = _snap(reload_root + reach_offset * 0.5 + bend * bend_height)
			support_elbow = _snap(support_elbow.lerp(working_elbow, grip_blend))
			if (action_progress >= 0.26 and action_progress <= 0.49) or (action_progress >= 0.64 and action_progress < 0.83):
				_draw_reload_item(canvas, support_hand, down, weapon)
		_arm_segment(canvas, _snap(shoulder + Vector2(facing * support_root_x, support_start_y)), support_elbow, upper_width, shade, edge.darkened(0.2))
		_arm_segment(canvas, support_elbow, support_hand, fore_width - 0.5, shade, sleeve)
		canvas.draw_rect(Rect2(support_hand - Vector2(0.5, 0.5), Vector2(2, 1.5)), Color("b36f54"))
		canvas.draw_rect(Rect2(support_hand + Vector2(0, -0.5), Vector2(1, 0.5)), Color("f6c28d"))
	_arm_segment(canvas, _snap(shoulder + Vector2(facing * root_x, -1.0)), elbow, upper_width, sleeve, edge)
	_arm_segment(canvas, elbow, wrist, fore_width, sleeve, edge.darkened(0.15))
	# Tailored cuff, warm knuckles and one quiet seam replace the old single block arm.
	var cuff: Vector2 = _snap(wrist - aim * 1.0)
	_pixel_line(canvas, cuff - aim.orthogonal() * 0.75, cuff + aim.orthogonal() * 0.75, Color("ddd7c4") if kind == "spectre" else edge, 1.0)
	if kind == "spectre":
		canvas.draw_rect(Rect2(_snap(shoulder + Vector2(-facing * 1.0, 1.0)), Vector2(1, 0.5)), Color("b36f54"))
		canvas.draw_rect(Rect2(_snap(elbow + Vector2(facing * 0.5, -0.5)), Vector2(0.5, 0.5)), Color("8c7467"))
	var direction: int = posmod(roundi(aim.angle() * 32.0 / TAU), 32)
	var weapon_region := Rect2(Vector2(Vector2i(direction % 8, direction / 8) * 96), Vector2(96, 96))
	canvas.draw_texture_rect_region(_texture(weapon), Rect2(hand_origin - Vector2(24, 24), Vector2(48, 48)), weapon_region, tint)

static func _draw_reload_item(canvas: CanvasItem, hand: Vector2, down: Vector2, weapon: String) -> void:
	var side := Vector2(-down.y, down.x)
	if weapon == "shotgun":
		_pixel_line(canvas, hand - side * 1.0, hand + side * 1.0, Color("5b322f"), 1.5)
		canvas.draw_rect(Rect2(_snap(hand + side * 1.0), Vector2(0.5, 1.0)), Color("c3a275"))
	else:
		var tip: Vector2 = _snap(hand + down * 3.0)
		canvas.draw_colored_polygon(PackedVector2Array([_snap(hand - side), _snap(hand + side), _snap(tip + side * 0.75), _snap(tip - side * 0.75)]), Color("100f15"))
		_pixel_line(canvas, hand, tip, Color("484752"), 1.0)
		_pixel_line(canvas, hand - side * 0.5, hand + side * 0.5, Color("9a9c94"), 0.5)

static func _arm_segment(canvas: CanvasItem, start: Vector2, finish: Vector2, width: float, cloth: Color, edge: Color) -> void:
	_pixel_line(canvas, start, finish, Color("100f15"), width)
	_pixel_line(canvas, start, finish, cloth, width - 1.0)
	var seam_offset := Vector2(0, -0.5)
	_pixel_line(canvas, start + seam_offset, finish + seam_offset, edge, 0.5)

static func _snap(point: Vector2) -> Vector2:
	return (point * 2.0).round() * 0.5

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

static func _pixel_line(canvas: CanvasItem, from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var steps: int = maxi(1, roundi(maxf(absf(to.x - from.x), absf(to.y - from.y)) * 2.0))
	var offset: Vector2 = Vector2.ONE * floorf(width) * 0.5
	for step: int in range(steps + 1):
		var point: Vector2 = _snap(from.lerp(to, float(step) / steps))
		canvas.draw_rect(Rect2(point - offset, Vector2(width, width)), color)
