extends RefCounted
## Original high-density pixel recipes. Coordinates are authoring pixels (2 per world unit).
## Every frame is drawn independently from articulated poses, never upscaled from a small atlas.
var _image: Image
var _origin: Vector2i
var _colors: Dictionary
var _torso_top: float = 0.0
var _torso_height: float = 1.0
var _torso_lean: float = 0.0

const STRIDE_X: Array[int] = [14, 9, 1, -9, -14, -6, 5, 13]
const STRIDE_Y: Array[int] = [0, 0, 0, 0, -2, -9, -8, -4]
const KNEE_X: Array[int] = [9, 8, 5, 1, -5, -8, -1, 7]

static func palette(kind: String) -> Dictionary:
	var p: Dictionary = {
		"ink": Color("100f15"), "deep": Color("17171e"), "shadow": Color("201e28"),
		"cloth": Color("2c2933"), "mid": Color("3e3944"), "edge": Color("5c535b"), "rim": Color("8c7467"),
		"pants": Color("292731"), "pants_light": Color("45404b"), "pants_dark": Color("19191f"),
		"boot": Color("211c22"), "boot_edge": Color("51444a"), "sole": Color("77716a"),
		"skin_shade": Color("80483e"), "skin_dark": Color("b36f54"), "skin": Color("e4a574"), "skin_light": Color("f6c28d"),
		"hair": Color("2b2025"), "hair_mid": Color("483037"), "hair_light": Color("65423d"),
		"shirt": Color("ddd7c4"), "shirt_shadow": Color("969b98"), "shirt_light": Color("f2e8cf"),
		"accent": Color("b8a783"), "accent_dark": Color("6e6656"),
		"tie": Color("92313b"), "tie_light": Color("c35a50"),
		"steel": Color("8a9298"), "steel_light": Color("c5c7bd"), "steel_dark": Color("42454e"),
		"glove": Color("2c252b"), "grip": Color("4b3431")
	}
	match kind:
		"recruit":
			p.shadow = Color("30372f"); p.cloth = Color("4f5748"); p.mid = Color("6c7159")
			p.edge = Color("919276"); p.rim = Color("b5a582")
			p.pants = Color("353e36"); p.pants_light = Color("5a6351"); p.pants_dark = Color("232a27")
			p.accent = Color("b3a984"); p.hair = Color("342b28")
		"scout":
			p.shadow = Color("3b2b32"); p.cloth = Color("66504d"); p.mid = Color("856b5d")
			p.edge = Color("a68b71"); p.rim = Color("c3aa83")
			p.pants = Color("322c36"); p.pants_light = Color("55444c"); p.accent = Color("c2aa7f")
		"chacal", "chacal_rage":
			p.shadow = Color("3e2d37"); p.cloth = Color("66505d"); p.mid = Color("856775")
			p.edge = Color("ab8883"); p.rim = Color("d2af91")
			p.pants = Color("30313c"); p.pants_light = Color("535965"); p.pants_dark = Color("22232d")
			p.skin_dark = Color("a36757"); p.skin = Color("d59a78"); p.skin_light = Color("eab894")
			p.accent = Color("c9b68c"); p.hair = Color("28212d"); p.hair_mid = Color("42313f")
			if kind == "chacal_rage":
				p.cloth = Color("7d4e4b"); p.mid = Color("a36d5a"); p.edge = Color("c28f70"); p.rim = Color("e5ba8b")
	return p

static func draw_body(image: Image, kind: String, frame: int) -> void:
	var recipe := new()
	recipe._image = image
	recipe._origin = Vector2i(48, 88) if kind.begins_with("chacal") else Vector2i(32, 72)
	recipe._colors = palette(kind)
	recipe._actor(kind, frame)

static func draw_weapon(image: Image, weapon: String) -> void:
	var recipe := new()
	recipe._image = image
	recipe._origin = Vector2i(48, 48)
	recipe._colors = palette("spectre")
	recipe._weapon(weapon)

func _actor(kind: String, frame: int) -> void:
	var large: bool = kind.begins_with("chacal")
	var hero: bool = kind == "spectre"
	if frame in [27, 28]:
		_dead(kind, frame == 28)
		return
	var stride: int = frame - 4 if frame >= 4 and frame <= 11 else -1
	var crouched: bool = frame >= 12 and frame <= 16
	var dodge: bool = frame >= 22 and frame <= 25
	var hip: Vector2 = Vector2(0, -23 if not large else -29)
	var lean: int = 0
	var bob: int = -1 if frame in [2, 3] else 0
	var front := Vector2(6, 0)
	var rear := Vector2(-7, 0)
	var front_knee: float = 2.0
	var rear_knee: float = -3.0
	if stride >= 0:
		bob = -2 if stride in [1, 2, 5, 6] else 0
		lean = 6 if stride in [1, 2, 5, 6] else 5
		front = Vector2(STRIDE_X[stride], STRIDE_Y[stride])
		rear = Vector2(STRIDE_X[(stride + 4) % 8], STRIDE_Y[(stride + 4) % 8])
		front_knee = KNEE_X[stride]
		rear_knee = KNEE_X[(stride + 4) % 8] - 2
	if hero and (frame < 4 or frame >= 29):
		# A forward, spring-loaded stance: bent knees and lowered center of mass.
		lean = 2
		bob += 2
		front = Vector2(10, 0); rear = Vector2(-10, 0)
		front_knee = 7; rear_knee = -6
	if hero and frame == 30:
		lean += 1
		bob += 1
	if crouched:
		hip.y = -12 if not large else -18
		lean = 5
		front = Vector2(12, 0); rear = Vector2(-11, 0)
		front_knee = 13; rear_knee = -6
		if frame >= 13:
			var crawl: int = (frame - 13) * 2
			front.x = STRIDE_X[crawl]; rear.x = STRIDE_X[(crawl + 4) % 8]
			front_knee = front.x * 0.5 + 5; rear_knee = rear.x * 0.5 - 2
	if frame in [17, 18, 19]:
		match frame:
			17: front = Vector2(11, -12); rear = Vector2(-11, -5); front_knee = 10; rear_knee = -9
			18: front = Vector2(9, -5); rear = Vector2(-10, -10); front_knee = 11; rear_knee = -9
			19: front = Vector2(5, 0); rear = Vector2(-7, -8); front_knee = 3; rear_knee = -8
		lean = 3 if frame != 19 else 0
	if frame in [20, 21]:
		bob = 5 if frame == 20 else 2
		front.x = 11; rear.x = -10
		front_knee = 8; rear_knee = -7
		lean = 2
	if dodge:
		var rise: int = 10 if frame == 25 else 0
		hip.y = (-22 if large else -12) - rise * 0.5
		lean = 18 if frame in [23, 24] else (10 if frame == 22 else 5)
		front = Vector2(18, 0); rear = Vector2(-15, -4)
		front_knee = 9; rear_knee = -14
	if frame == 26:
		lean = -5; bob = 2
	if large:
		front.x *= 1.3; rear.x *= 1.3
		front_knee *= 1.3; rear_knee *= 1.3
	hip += Vector2(lean * 0.35, bob)
	var torso_top: float = hip.y - (26.0 if large else 22.0)
	if crouched: torso_top = hip.y - (20.0 if large else 14.0)
	elif dodge: torso_top = hip.y - (24.0 if large else 18.0)
	var head_at: Vector2 = Vector2(lean + (1 if hero else 0), torso_top - (18 if not large else 20))
	if dodge and frame in [23, 24]: head_at.x = lean - (2 if not large else 0)
	_leg(hip + Vector2(-4 if not large else -7, 0), rear, rear_knee, false, kind)
	# Far arm is a bent silhouette behind the coat, with a visible cuff at the elbow.
	var far_shoulder := Vector2(lean - (9 if not large else 15), torso_top + 5)
	_limb(far_shoulder, far_shoulder + Vector2(-3, 11), 7 if not large else 10, "ink")
	_limb(far_shoulder + Vector2(0, 1), far_shoulder + Vector2(-3, 9), 4 if not large else 7, "shadow")
	if hero:
		_r(far_shoulder + Vector2(-4, 9), Vector2(4, 2), "shirt_shadow")
	_leg(hip + Vector2(4 if not large else 7, 0), front, front_knee, true, kind)
	_torso_top = torso_top
	_torso_height = maxf(1.0, hip.y - torso_top)
	_torso_lean = float(lean) - hip.x
	if hero:
		_suit(Vector2(lean, torso_top), hip.y, stride, frame)
	else:
		_uniform(Vector2(lean, torso_top), hip.y, kind, stride)
	# Neck is deliberately narrow; the hair and cheek remain distinct from the collar.
	_poly([head_at + Vector2(-2, 14), head_at + Vector2(5, 14), Vector2(lean + 5, torso_top + 3), Vector2(lean - 2, torso_top + 2)], "skin_shade")
	_poly([head_at + Vector2(1, 14), head_at + Vector2(5, 14), Vector2(lean + 3, torso_top + 1), Vector2(lean, torso_top)], "skin_dark")
	_head(head_at, kind, frame)

func _leg(hip: Vector2, foot: Vector2, knee_x: float, front: bool, kind: String) -> void:
	var large: bool = kind.begins_with("chacal")
	var knee := Vector2(knee_x, lerpf(hip.y, foot.y, 0.52) - 1)
	var ankle: Vector2 = foot + Vector2(0, -5)
	var width: float = 11 if large else 8
	_limb(hip, knee, width, "ink")
	_limb(knee, ankle, width - 1, "ink")
	_limb(hip + Vector2(0, 1), knee, width - 3, "pants" if front else "pants_dark")
	_limb(knee, ankle, width - 4, "pants" if front else "pants_dark")
	if front:
		_line(hip + Vector2(1, 3), knee + Vector2(1, -3), "pants_light", 2)
		_line(knee + Vector2(1, 3), ankle + Vector2(1, -2), "pants_light")
		_poly([knee + Vector2(-3, -2), knee + Vector2(3, -3), knee + Vector2(3, 0), knee + Vector2(-1, 1)], "mid")
		_line(knee + Vector2(-3, 3), knee + Vector2(2, 4), "ink")
		if kind == "spectre":
			# Small tears are authored clusters, never random pixel noise.
			_poly([knee + Vector2(-2, -1), knee + Vector2(1, -2), knee + Vector2(3, 0), knee], "skin_dark")
			_r(knee + Vector2(0, -1), Vector2(2, 1), "skin")
		elif kind != "scout":
			_poly([knee + Vector2(-4, -4), knee + Vector2(4, -4), knee + Vector2(5, 2), knee + Vector2(-3, 3)], "shadow")
			_line(knee + Vector2(-3, -4), knee + Vector2(3, -4), "edge")
	_poly([foot + Vector2(-5, -7), foot + Vector2(3, -7), foot + Vector2(5, -5), foot + Vector2(9, -4), foot + Vector2(10, -1), foot + Vector2(7, 0), foot + Vector2(-5, 0)], "ink")
	_poly([foot + Vector2(-3, -6), foot + Vector2(2, -6), foot + Vector2(4, -4), foot + Vector2(7, -3), foot + Vector2(8, -2), foot + Vector2(-3, -2)], "boot")
	_line(foot + Vector2(-2, -6), foot + Vector2(1, -5), "boot_edge")
	_line(foot + Vector2(3, -4), foot + Vector2(7, -3), "boot_edge")
	_line(foot + Vector2(-3, -1), foot + Vector2(7, -1), "sole")
	_r(foot + Vector2(-5, -1), Vector2(2, 1), "deep")

func _suit(at: Vector2, hip_y: float, stride: int, frame: int) -> void:
	var h: float = hip_y - at.y
	var flutter: int = -2 if stride in [0, 1, 4, 5] else 0
	_body_poly([at + Vector2(-7, -1), at + Vector2(4, -2), at + Vector2(10, 2), at + Vector2(11, 8), at + Vector2(8, h - 3), at + Vector2(9, h + 4), at + Vector2(1, h + 3), at + Vector2(-2, h), at + Vector2(-9 + flutter, h + 3), at + Vector2(-10, 9), at + Vector2(-12, 4)], "ink")
	_body_poly([at + Vector2(-6, 1), at + Vector2(4, 0), at + Vector2(8, 3), at + Vector2(9, 8), at + Vector2(6, h - 3), at + Vector2(7, h + 1), at + Vector2(1, h + 1), at + Vector2(-1, h - 2), at + Vector2(-7 + flutter, h + 1), at + Vector2(-8, 8), at + Vector2(-9, 4)], "cloth")
	_body_poly([at + Vector2(-8, 4), at + Vector2(-4, 3), at + Vector2(-3, 10), at + Vector2(-5, h - 1), at + Vector2(-8 + flutter, h + 1), at + Vector2(-8, 8)], "shadow")
	# Open jacket frames a pale triangular shirt; knot, tie blade and collar are separate.
	_body_poly([at + Vector2(-3, 0), at + Vector2(4, 0), at + Vector2(3, h - 4), at + Vector2(0, h - 1), at + Vector2(-2, 8)], "shirt_shadow")
	_body_poly([at + Vector2(-2, 0), at + Vector2(3, 0), at + Vector2(2, h - 5), at + Vector2(0, h - 2), at + Vector2(-1, 8)], "shirt")
	_body_poly([at + Vector2(-3, 0), at + Vector2(0, 2), at + Vector2(-1, 6), at + Vector2(-4, 2)], "shirt_light")
	_body_poly([at + Vector2(3, 0), at + Vector2(5, 2), at + Vector2(2, 6), at + Vector2(1, 2)], "shirt_light")
	_body_poly([at + Vector2(0, 2), at + Vector2(2, 3), at + Vector2(1, 5), at + Vector2(-1, 4)], "tie")
	_body_poly([at + Vector2(0, 5), at + Vector2(2, 5), at + Vector2(3, h - 5), at + Vector2(1, h - 2), at + Vector2(0, h - 5)], "tie")
	_body_line(at + Vector2(1, 6), at + Vector2(2, h - 6), "tie_light")
	# Notched lapels, shoulder seams, jacket pockets and narrow folds.
	_body_poly([at + Vector2(-5, 0), at + Vector2(-2, 4), at + Vector2(-4, 7), at + Vector2(0, h - 2), at + Vector2(-6, 8), at + Vector2(-5, 5), at + Vector2(-8, 3)], "mid")
	_body_poly([at + Vector2(5, 0), at + Vector2(3, 5), at + Vector2(5, 6), at + Vector2(2, h - 2), at + Vector2(7, 8), at + Vector2(6, 5), at + Vector2(8, 3)], "edge")
	_body_line(at + Vector2(-8, 3), at + Vector2(-5, 1), "edge")
	_body_line(at + Vector2(6, 1), at + Vector2(9, 4), "rim")
	_body_line(at + Vector2(7, 10), at + Vector2(6, h - 2), "mid")
	_body_line(at + Vector2(-6, h - 6), at + Vector2(-2, h - 7), "edge")
	_body_line(at + Vector2(4, h - 6), at + Vector2(7, h - 7), "deep")
	_body_r(at + Vector2(1, h - 3), Vector2(1, 1), "accent")
	_body_r(at + Vector2(7, 5), Vector2(1, 1), "shirt_light")
	# Frayed shoulder reveals a small patch beneath; no military gear on the executive.
	_body_poly([at + Vector2(-9, 5), at + Vector2(-7, 4), at + Vector2(-6, 6), at + Vector2(-8, 8), at + Vector2(-10, 7)], "skin_dark")
	_body_r(at + Vector2(-9, 5), Vector2(2, 1), "skin")
	if frame == 26:
		_body_line(at + Vector2(-5, h - 1), at + Vector2(-9, h + 3), "rim")

func _uniform(at: Vector2, hip_y: float, kind: String, stride: int) -> void:
	var large: bool = kind.begins_with("chacal")
	var w: float = 17 if large else 10
	var h: float = hip_y - at.y
	_body_poly([at + Vector2(-w + 2, 0), at + Vector2(w - 4, -1), at + Vector2(w + 1, 4), at + Vector2(w, h - 5), at + Vector2(w - 2, h + 2), at + Vector2(-w + 1, h + 2), at + Vector2(-w - 2, 7)], "ink")
	_body_poly([at + Vector2(-w + 3, 2), at + Vector2(w - 4, 1), at + Vector2(w - 1, 5), at + Vector2(w - 2, h - 4), at + Vector2(w - 3, h), at + Vector2(-w + 3, h), at + Vector2(-w, 7)], "cloth")
	_body_poly([at + Vector2(-w + 2, 4), at + Vector2(-w + 7, 3), at + Vector2(-w + 8, h - 3), at + Vector2(-w + 3, h), at + Vector2(-w, 7)], "shadow")
	_body_line(at + Vector2(w - 5, 3), at + Vector2(w - 2, 6), "rim")
	_body_line(at + Vector2(w - 3, 8), at + Vector2(w - 4, h - 3), "mid")
	_body_poly([at + Vector2(-4, 0), at + Vector2(3, -1), at + Vector2(6, 3), at + Vector2(1, 8), at + Vector2(-5, 4)], "deep")
	_body_line(at + Vector2(-3, 1), at + Vector2(1, 4), "edge")
	_body_line(at + Vector2(3, 1), at + Vector2(1, 4), "mid")
	if large:
		# Angular pauldrons and tailored armored panels replace the old box torso.
		_body_poly([at + Vector2(-18, 2), at + Vector2(-7, 0), at + Vector2(-4, 5), at + Vector2(-9, 12), at + Vector2(-20, 10), at + Vector2(-21, 6)], "ink")
		_body_poly([at + Vector2(-17, 3), at + Vector2(-8, 2), at + Vector2(-6, 5), at + Vector2(-10, 9), at + Vector2(-18, 8)], "shadow")
		_body_line(at + Vector2(-17, 3), at + Vector2(-9, 2), "edge")
		_body_poly([at + Vector2(9, 0), at + Vector2(20, 3), at + Vector2(22, 9), at + Vector2(17, 13), at + Vector2(8, 10), at + Vector2(5, 5)], "ink")
		_body_poly([at + Vector2(10, 2), at + Vector2(18, 4), at + Vector2(19, 8), at + Vector2(16, 10), at + Vector2(9, 8), at + Vector2(7, 5)], "mid")
		_body_line(at + Vector2(11, 2), at + Vector2(18, 5), "rim")
		_body_poly([at + Vector2(-4, 9), at + Vector2(6, 8), at + Vector2(10, 14), at + Vector2(7, h - 5), at + Vector2(-5, h - 4), at + Vector2(-8, 14)], "shadow")
		_body_line(at + Vector2(-3, 10), at + Vector2(5, 9), "edge")
		_body_line(at + Vector2(-3, h - 6), at + Vector2(6, h - 7), "mid")
		_body_r(at + Vector2(8, 12), Vector2(4, 6), "accent_dark")
		_body_r(at + Vector2(9, 12), Vector2(2, 4), "accent")
	else:
		# Small flap pockets, radio and material seams, with sparse highlights.
		_body_poly([at + Vector2(-7, 8), at + Vector2(-1, 8), at + Vector2(-2, 14), at + Vector2(-7, 14)], "shadow")
		_body_line(at + Vector2(-7, 8), at + Vector2(-2, 8), "mid")
		_body_r(at + Vector2(4, 7), Vector2(4, 6), "shadow")
		_body_line(at + Vector2(4, 7), at + Vector2(7, 7), "edge")
		_body_r(at + Vector2(-7, 16), Vector2(2, 1), "edge")
		_body_r(at + Vector2(4, 5), Vector2(4, 1), "accent")
	_body_poly([at + Vector2(-w + 2, h - 2), at + Vector2(w - 2, h - 2), at + Vector2(w - 3, h + 1), at + Vector2(-w + 3, h + 1)], "deep")
	_body_r(at + Vector2(1, h - 2), Vector2(4, 2), "accent_dark")
	_body_r(at + Vector2(2, h - 2), Vector2(2, 1), "accent")
	if kind == "scout":
		# Scarf follows the run phase; harness is a clean diagonal over the jacket.
		var tail: float = -3 if stride in [1, 2, 5, 6] else 0
		_body_poly([at + Vector2(-8, 0), at + Vector2(4, 0), at + Vector2(5, 4), at + Vector2(-5, 5), at + Vector2(-9, 3)], "accent_dark")
		_body_line(at + Vector2(-7, 1), at + Vector2(3, 1), "accent")
		_body_poly([at + Vector2(-7, 2), at + Vector2(-15 + tail, 5), at + Vector2(-18 + tail, 3), at + Vector2(-18 + tail, 7), at + Vector2(-11, 8)], "ink")
		_body_poly([at + Vector2(-8, 3), at + Vector2(-15 + tail, 5), at + Vector2(-16 + tail, 6), at + Vector2(-11, 6)], "accent")
		_body_line(at + Vector2(-6, 7), at + Vector2(6, h - 3), "deep", 3)
		_body_line(at + Vector2(-6, 7), at + Vector2(6, h - 3), "mid")

func _head(at: Vector2, kind: String, frame: int = 0) -> void:
	var hero: bool = kind == "spectre"
	# Cheek, nose and jaw are faceted shapes; eyes have brows and clear eye whites.
	_poly([at + Vector2(-7, 0), at + Vector2(5, -1), at + Vector2(10, 3), at + Vector2(11, 7), at + Vector2(14, 9), at + Vector2(13, 11), at + Vector2(10, 11), at + Vector2(10, 15), at + Vector2(6, 18), at + Vector2(-2, 17), at + Vector2(-7, 12), at + Vector2(-9, 6)], "ink")
	_poly([at + Vector2(-5, 1), at + Vector2(4, 0), at + Vector2(8, 3), at + Vector2(9, 7), at + Vector2(12, 9), at + Vector2(9, 10), at + Vector2(9, 14), at + Vector2(5, 16), at + Vector2(-1, 15), at + Vector2(-5, 11), at + Vector2(-7, 6)], "skin_dark")
	_poly([at + Vector2(0, 2), at + Vector2(5, 2), at + Vector2(8, 4), at + Vector2(8, 8), at + Vector2(11, 9), at + Vector2(8, 10), at + Vector2(8, 13), at + Vector2(4, 15), at + Vector2(0, 14), at + Vector2(-2, 9)], "skin")
	_poly([at + Vector2(3, 3), at + Vector2(7, 4), at + Vector2(7, 7), at + Vector2(5, 9), at + Vector2(1, 7)], "skin_light")
	_line(at + Vector2(9, 8), at + Vector2(11, 9), "skin_light")
	_r(at + Vector2(5, 7), Vector2(4, 2), "skin_shade")
	_r(at + Vector2(6, 7), Vector2(3, 1), "ink")
	_r(at + Vector2(7, 8), Vector2(2, 1), "shirt_light")
	_r(at + Vector2(8, 8), Vector2(1, 2), "ink")
	_line(at + Vector2(5, 13), at + Vector2(8, 12), "skin_shade")
	_r(at + Vector2(5, 15), Vector2(2, 1), "skin_light")
	_poly([at + Vector2(-6, 8), at + Vector2(-3, 7), at + Vector2(-2, 11), at + Vector2(-5, 12), at + Vector2(-7, 10)], "skin_shade")
	_r(at + Vector2(-5, 8), Vector2(2, 3), "skin")
	if hero:
		_poly([at + Vector2(-9, 14), at + Vector2(-12, 9), at + Vector2(-11, 6), at + Vector2(-14, 4), at + Vector2(-11, 1), at + Vector2(-12, -1), at + Vector2(-7, -2), at + Vector2(-8, -4), at + Vector2(-3, -3), at + Vector2(0, -5), at + Vector2(3, -3), at + Vector2(7, -4), at + Vector2(9, -2), at + Vector2(13, -1), at + Vector2(12, 2), at + Vector2(14, 4), at + Vector2(11, 7), at + Vector2(8, 7), at + Vector2(7, 4), at + Vector2(4, 6), at + Vector2(1, 5), at + Vector2(-1, 8), at + Vector2(-3, 8), at + Vector2(-3, 12), at + Vector2(-5, 11), at + Vector2(-6, 16)], "ink")
		_poly([at + Vector2(-9, 11), at + Vector2(-10, 6), at + Vector2(-11, 4), at + Vector2(-8, 2), at + Vector2(-9, 0), at + Vector2(-4, -1), at + Vector2(-3, -2), at + Vector2(0, -3), at + Vector2(3, -1), at + Vector2(7, -2), at + Vector2(9, 0), at + Vector2(11, 1), at + Vector2(10, 3), at + Vector2(11, 4), at + Vector2(9, 5), at + Vector2(6, 2), at + Vector2(3, 4), at + Vector2(0, 3), at + Vector2(-3, 6), at + Vector2(-5, 6), at + Vector2(-5, 9), at + Vector2(-7, 13)], "hair")
		_poly([at + Vector2(-8, 2), at + Vector2(-5, 0), at + Vector2(-2, 0), at + Vector2(-4, 2), at + Vector2(-3, 4), at + Vector2(-7, 5)], "hair_mid")
		_poly([at + Vector2(-1, -2), at + Vector2(3, 0), at + Vector2(6, -1), at + Vector2(9, 1), at + Vector2(7, 2), at + Vector2(4, 1), at + Vector2(2, 3), at + Vector2(-1, 1)], "hair_mid")
		_line(at + Vector2(-8, 1), at + Vector2(-5, 0), "hair_light")
		_line(at + Vector2(0, -2), at + Vector2(3, 0), "hair_light")
		_r(at + Vector2(7, 0), Vector2(2, 1), "hair_light")
		_r(at + Vector2(-9, 6), Vector2(1, 3), "hair_mid")
		# Worn cheek, determined brow and a quiet jawline, not a painted-on smile.
		_line(at + Vector2(5, 6), at + Vector2(9, 7), "ink")
		_r(at + Vector2(2, 11), Vector2(1, 2), "skin_dark")
	elif kind == "recruit":
		_poly([at + Vector2(-10, 3), at + Vector2(-8, -2), at + Vector2(-4, -4), at + Vector2(6, -4), at + Vector2(10, -1), at + Vector2(11, 3), at + Vector2(15, 4), at + Vector2(15, 6), at + Vector2(-11, 6)], "ink")
		_poly([at + Vector2(-8, 2), at + Vector2(-6, -1), at + Vector2(-2, -2), at + Vector2(5, -2), at + Vector2(8, 0), at + Vector2(9, 3), at + Vector2(-8, 3)], "cloth")
		_line(at + Vector2(-5, -1), at + Vector2(5, -1), "edge")
		_line(at + Vector2(-8, 4), at + Vector2(13, 4), "mid")
		_poly([at + Vector2(-8, 7), at + Vector2(-5, 7), at + Vector2(-4, 12), at + Vector2(-6, 15), at + Vector2(-9, 13)], "shadow")
		_line(at + Vector2(-6, 12), at + Vector2(1, 16), "deep")
		_r(at + Vector2(-8, 8), Vector2(2, 3), "edge")
	elif kind == "scout":
		_poly([at + Vector2(-9, 10), at + Vector2(-11, 5), at + Vector2(-9, 0), at + Vector2(-4, -3), at + Vector2(4, -3), at + Vector2(9, 0), at + Vector2(11, 4), at + Vector2(8, 5), at + Vector2(4, 2), at + Vector2(1, 4), at + Vector2(-2, 3), at + Vector2(-5, 8), at + Vector2(-7, 12)], "ink")
		_poly([at + Vector2(-8, 5), at + Vector2(-7, 1), at + Vector2(-3, -1), at + Vector2(3, -1), at + Vector2(7, 1), at + Vector2(8, 3), at + Vector2(4, 1), at + Vector2(0, 2), at + Vector2(-3, 1), at + Vector2(-5, 6)], "hair")
		_line(at + Vector2(-5, 0), at + Vector2(1, -1), "hair_light")
		_r(at + Vector2(-9, 6), Vector2(2, 4), "hair_mid")
		_r(at + Vector2(2, 13), Vector2(2, 1), "skin_shade")
	else:
		# Mara's swept hair and short side locks distinguish her from the guards.
		_poly([at + Vector2(-10, 10), at + Vector2(-12, 5), at + Vector2(-10, 0), at + Vector2(-6, -4), at + Vector2(6, -4), at + Vector2(10, -1), at + Vector2(10, 3), at + Vector2(6, 5), at + Vector2(2, 2), at + Vector2(-2, 4), at + Vector2(-5, 3), at + Vector2(-5, 11), at + Vector2(-7, 16), at + Vector2(-10, 14)], "ink")
		_poly([at + Vector2(-9, 5), at + Vector2(-7, 0), at + Vector2(-4, -2), at + Vector2(5, -2), at + Vector2(8, 0), at + Vector2(8, 2), at + Vector2(5, 3), at + Vector2(1, 0), at + Vector2(-3, 2), at + Vector2(-6, 1), at + Vector2(-7, 8)], "hair")
		_line(at + Vector2(-5, -1), at + Vector2(5, -1), "hair_mid", 2)
		_r(at + Vector2(-7, 9), Vector2(2, 5), "hair_mid")
		_r(at + Vector2(-5, 13), Vector2(2, 2), "accent")
		_line(at + Vector2(5, 6), at + Vector2(9, 7), "ink")
		_r(at + Vector2(4, 14), Vector2(3, 1), "skin_shade")
	if frame == 26:
		_r(at + Vector2(6, 8), Vector2(3, 1), "ink")

func _dead(kind: String, settled: bool) -> void:
	var large: bool = kind.begins_with("chacal")
	var lift: float = 0 if settled else -8
	var at := Vector2(0, lift)
	# Bent legs and a sloped torso retain volume, rather than a flat bar of pixels.
	_limb(at + Vector2(-5, -9), Vector2(-16, -8), 10 if not large else 13, "ink")
	_limb(at + Vector2(-5, -9), Vector2(-16, -8), 6 if not large else 9, "pants_dark")
	_limb(Vector2(-16, -8), Vector2(-25, -4), 8 if not large else 11, "ink")
	_limb(Vector2(-16, -8), Vector2(-25, -4), 4 if not large else 7, "pants")
	_line(Vector2(-20, -5), Vector2(-27, -3), "boot_edge", 3)
	_limb(at + Vector2(-4, -6), Vector2(-12, -3), 10 if not large else 13, "ink")
	_limb(at + Vector2(-4, -6), Vector2(-12, -3), 6 if not large else 9, "pants")
	_limb(Vector2(-12, -3), Vector2(-23, -2), 7, "ink")
	_line(Vector2(-22, -1), Vector2(-15, -1), "sole")
	_poly([at + Vector2(-6, -15), at + Vector2(7, -17), at + Vector2(15, -10), at + Vector2(12, -3), at + Vector2(-5, -2), at + Vector2(-10, -8)], "ink")
	_poly([at + Vector2(-5, -13), at + Vector2(6, -15), at + Vector2(12, -10), at + Vector2(10, -5), at + Vector2(-4, -4), at + Vector2(-7, -8)], "cloth")
	_line(at + Vector2(-5, -13), at + Vector2(5, -15), "mid")
	if kind == "spectre":
		_poly([at + Vector2(3, -14), at + Vector2(8, -12), at + Vector2(7, -7), at + Vector2(2, -7)], "shirt")
		_line(at + Vector2(3, -11), at + Vector2(7, -10), "tie", 2)
	# Head is drawn into a temporary buffer and rotated by integer pixels in the authoring pipeline.
	var main_image: Image = _image
	var main_origin: Vector2i = _origin
	var head := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	head.fill(Color.TRANSPARENT)
	_image = head; _origin = Vector2i(17, 12)
	_head(Vector2.ZERO, kind)
	_image = main_image; _origin = main_origin
	var head_at := Vector2i(8 if not large else 19, -26 + int(lift))
	for y: int in range(40):
		for x: int in range(40):
			var color: Color = head.get_pixel(x, y)
			if color.a > 0.0:
				var point: Vector2i = _origin + head_at + Vector2i(29 - y, x - 7)
				if point.x >= 0 and point.y >= 0 and point.x < _image.get_width() and point.y < _image.get_height(): _image.set_pixelv(point, color)
	_limb(at + Vector2(3, -10), Vector2(11, -3), 7, "ink")
	_limb(at + Vector2(3, -10), Vector2(11, -3), 4, "shadow")
	_r(Vector2(10, -4), Vector2(3, 2), "shirt" if kind == "spectre" else "edge")
	_poly([Vector2(13, -4), Vector2(18, -3), Vector2(19, -1), Vector2(13, -1)], "skin_dark")

func _weapon(weapon: String) -> void:
	match weapon:
		"pistol":
			_poly([Vector2(13, -7), Vector2(38, -7), Vector2(41, -5), Vector2(41, 0), Vector2(28, 1), Vector2(26, 10), Vector2(18, 9), Vector2(19, 1), Vector2(13, 0)], "ink")
			_poly([Vector2(15, -5), Vector2(37, -5), Vector2(39, -4), Vector2(39, -2), Vector2(15, -2)], "steel_dark")
			_line(Vector2(16, -5), Vector2(35, -5), "steel")
			_line(Vector2(34, -4), Vector2(38, -4), "steel_light")
			_r(Vector2(17, -8), Vector2(3, 1), "ink")
			_r(Vector2(37, -8), Vector2(2, 1), "steel")
			_r(Vector2(16, -4), Vector2(2, 2), "deep")
			_r(Vector2(19, -4), Vector2(1, 2), "deep")
			_r(Vector2(22, -4), Vector2(1, 2), "deep")
			_poly([Vector2(21, 0), Vector2(26, 0), Vector2(24, 8), Vector2(20, 7)], "grip")
			_line(Vector2(22, 2), Vector2(21, 6), "mid")
			_r(Vector2(28, 1), Vector2(5, 1), "steel_dark")
			_r(Vector2(31, 1), Vector2(1, 3), "steel_dark")
			_r(Vector2(27, 4), Vector2(5, 1), "steel_dark")
			_poly([Vector2(12, -1), Vector2(20, -1), Vector2(21, 2), Vector2(20, 6), Vector2(13, 5), Vector2(11, 3)], "skin_dark")
			_line(Vector2(13, 0), Vector2(19, 0), "skin_light")
			_line(Vector2(13, 2), Vector2(18, 2), "skin")
		"shotgun":
			_poly([Vector2(6, -6), Vector2(43, -6), Vector2(45, -4), Vector2(45, -1), Vector2(29, 0), Vector2(25, 5), Vector2(20, 5), Vector2(17, 2), Vector2(9, 4), Vector2(2, 6), Vector2(-1, 3), Vector2(2, -1)], "ink")
			_r(Vector2(13, -5), Vector2(29, 2), "steel_dark")
			_line(Vector2(16, -5), Vector2(41, -5), "steel")
			_r(Vector2(40, -5), Vector2(3, 1), "steel_light")
			_r(Vector2(18, -2), Vector2(22, 2), "steel_dark")
			_poly([Vector2(18, 0), Vector2(33, 0), Vector2(32, 4), Vector2(21, 4)], "grip")
			for x: int in range(21, 32, 3): _r(Vector2(x, 1), Vector2(1, 3), "edge")
			_poly([Vector2(3, 0), Vector2(13, -2), Vector2(16, 1), Vector2(8, 3), Vector2(1, 4)], "grip")
			_line(Vector2(3, 1), Vector2(10, -1), "mid")
			_poly([Vector2(13, 0), Vector2(20, 0), Vector2(21, 3), Vector2(19, 6), Vector2(13, 5)], "skin_dark")
			_line(Vector2(14, 0), Vector2(18, 0), "skin_light")
		"blade":
			_poly([Vector2(7, -2), Vector2(16, -2), Vector2(16, -6), Vector2(19, -6), Vector2(19, -3), Vector2(40, -3), Vector2(36, 1), Vector2(19, 2), Vector2(19, 6), Vector2(16, 6), Vector2(16, 2), Vector2(7, 2)], "ink")
			_poly([Vector2(20, -2), Vector2(37, -2), Vector2(34, 0), Vector2(20, 1)], "steel")
			_line(Vector2(21, -2), Vector2(37, -2), "steel_light")
			_line(Vector2(20, 1), Vector2(32, 0), "steel_dark")
			_r(Vector2(17, -5), Vector2(1, 10), "accent_dark")
			_r(Vector2(8, -1), Vector2(8, 2), "grip")
			_poly([Vector2(7, 0), Vector2(14, 0), Vector2(14, 4), Vector2(9, 5), Vector2(6, 3)], "skin_dark")
			_line(Vector2(8, 1), Vector2(12, 1), "skin")

func _torso_point(point: Vector2) -> Vector2:
	return Vector2(point.x - (point.y - _torso_top) * _torso_lean / _torso_height, point.y)

func _body_poly(points: Array[Vector2], color: String) -> void:
	var posed: Array[Vector2] = []
	for point: Vector2 in points: posed.append(_torso_point(point))
	_poly(posed, color)

func _body_line(from: Vector2, to: Vector2, color: String, width: int = 1) -> void:
	_line(_torso_point(from), _torso_point(to), color, width)

func _body_r(at: Vector2, size: Vector2, color: String) -> void:
	_r(_torso_point(at), size, color)

func _r(at: Vector2, size: Vector2, color: String) -> void:
	var rect := Rect2i(_origin + Vector2i(roundi(at.x), roundi(at.y)), Vector2i(roundi(size.x), roundi(size.y)))
	rect = rect.intersection(Rect2i(Vector2i.ZERO, _image.get_size()))
	if rect.has_area(): _image.fill_rect(rect, _colors[color])

func _line(from: Vector2, to: Vector2, color: String, width: int = 1) -> void:
	var steps: int = maxi(1, roundi(maxf(absf(to.x - from.x), absf(to.y - from.y))))
	for step: int in range(steps + 1):
		var point: Vector2 = from.lerp(to, float(step) / steps).round()
		_r(point - Vector2(floorf(width * 0.5), floorf(width * 0.5)), Vector2(width, width), color)

func _limb(from: Vector2, to: Vector2, width: float, color: String) -> void:
	var normal: Vector2 = (to - from).normalized().orthogonal() * width * 0.5
	_poly([from + normal, to + normal, to - normal, from - normal], color)
	_disc(from, width * 0.5, color)
	_disc(to, width * 0.5, color)

func _disc(at: Vector2, radius: float, color: String) -> void:
	for y: int in range(floori(at.y - radius), ceili(at.y + radius) + 1):
		for x: int in range(floori(at.x - radius), ceili(at.x + radius) + 1):
			if Vector2(x + 0.5, y + 0.5).distance_squared_to(at) <= radius * radius: _r(Vector2(x, y), Vector2.ONE, color)

func _poly(points: Array[Vector2], color: String) -> void:
	if points.size() < 3: return
	var min_y: float = points[0].y
	var max_y: float = min_y
	for point: Vector2 in points:
		min_y = minf(min_y, point.y); max_y = maxf(max_y, point.y)
	for y: int in range(floori(min_y), ceili(max_y)):
		var intersections: Array[float] = []
		var scan_y: float = float(y) + 0.5
		for index: int in range(points.size()):
			var a: Vector2 = points[index]
			var b: Vector2 = points[(index + 1) % points.size()]
			if (a.y <= scan_y and b.y > scan_y) or (b.y <= scan_y and a.y > scan_y):
				intersections.append(a.x + (scan_y - a.y) * (b.x - a.x) / (b.y - a.y))
		intersections.sort()
		for index: int in range(0, intersections.size() - 1, 2):
			var start: int = ceili(intersections[index] - 0.5)
			var finish: int = ceili(intersections[index + 1] - 0.5)
			if finish > start: _r(Vector2(start, y), Vector2(finish - start, 1), color)
