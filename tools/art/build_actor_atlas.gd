extends SceneTree
## Original pixel recipes. Builds native-size, nearest-filtered animation atlases.
## Feet are the origin; no external pictures, fonts or random noise are used.
const OUT: String = "res://assets/art/actors/"
const FOOT_X: Array[int] = [7, 4, 0, -4, -7, -3, 2, 6]
const FOOT_LIFT: Array[int] = [0, 0, 0, 0, 1, 4, 4, 2]
var palette: Dictionary
var origin: Vector2i

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	for kind: String in ["spectre", "recruit", "scout", "chacal", "chacal_rage"]:
		_build_body(kind)
	for weapon: String in ["pistol", "shotgun", "blade"]:
		_build_weapon(weapon)
	print("ACTOR_ATLASES_BUILT=", ProjectSettings.globalize_path(OUT))
	quit()

func _palette(kind: String) -> Dictionary:
	var p: Dictionary = {
		"ink": Color("11161b"), "boot": Color("17191d"), "sole": Color("414447"),
		"pants": Color("24272c"), "pants_shadow": Color("191d22"), "knee": Color("363c42"),
		"shade": Color("1c2027"), "coat": Color("2b3037"), "light": Color("484f57"),
		"skin_dark": Color("9e806d"), "skin": Color("d1b39a"), "hair": Color("292320"),
		"accent": Color("878a89"), "steel": Color("b4b9b3"), "glove": Color("d1b39a"),
		"shirt": Color("c4c2b6"), "shirt_shadow": Color("8d9493"),
		"tie": Color("242124"), "lapel": Color("3b4148"), "hair_light": Color("4a4036")
	}
	match kind:
		"recruit":
			p.shade = Color("373e36"); p.coat = Color("565c50"); p.light = Color("868b70")
			p.hair = Color("42493d"); p.accent = Color("a09c79")
			p.pants = Color("303834"); p.knee = Color("586058")
		"scout":
			p.shade = Color("49383b"); p.coat = Color("74605b"); p.light = Color("a48c76")
			p.hair = Color("332c31"); p.accent = Color("b59b79")
		"chacal", "chacal_rage":
			p.shade = Color("45383f"); p.coat = Color("76616a"); p.light = Color("9b8176")
			p.hair = Color("393039"); p.accent = Color("b4a589")
			p.pants = Color("30383e"); p.knee = Color("59636b")
			if kind == "chacal_rage":
				p.coat = Color("8a665c"); p.light = Color("b39576"); p.accent = Color("d4b792")
	return p

func _build_body(kind: String) -> void:
	var large: bool = kind.begins_with("chacal")
	var frame_size := Vector2i(48, 48) if large else Vector2i(32, 40)
	origin = Vector2i(24, 44) if large else Vector2i(16, 36)
	palette = _palette(kind)
	var sheet := Image.create(frame_size.x * 8, frame_size.y * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	for index: int in range(32):
		var frame := Image.create(frame_size.x, frame_size.y, false, Image.FORMAT_RGBA8)
		frame.fill(Color.TRANSPARENT)
		_draw_body(frame, kind, index, large)
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame_size), Vector2i(index % 8, index / 8) * frame_size)
	var error: Error = sheet.save_png(OUT + kind + ".png")
	assert(error == OK, "Cannot write actor atlas")

func _draw_body(image: Image, kind: String, frame: int, large: bool) -> void:
	var executive: bool = kind == "spectre"
	var height: int = 36 if large else 25
	var torso_width: int = 22 if large else 11
	var leg_height: int = 12 if large else 9
	var head_width: int = 12 if large else 8
	var head_height: int = 10 if large else 7
	var bob: int = 0
	var lean: int = 0
	var stride: int = -1
	var low: bool = frame >= 12 and frame <= 16
	var dodge: bool = frame >= 22 and frame <= 25
	var air: bool = frame >= 17 and frame <= 19
	if frame in [27, 28]:
		_draw_dead(image, large, frame == 28, executive)
		return
	if frame < 4:
		bob = -1 if frame >= 2 else 0
	elif frame >= 4 and frame <= 11:
		stride = frame - 4
		bob = -1 if stride in [1, 2, 5, 6] else 0
		lean = 1
	elif frame >= 13 and frame <= 16:
		stride = (frame - 13) * 2
	if low:
		height = 21 if large else 15
		leg_height = 7 if large else 5
		lean = 1
	if frame == 20: bob = 2
	if frame == 21: bob = 1
	if frame == 26: lean = -2; bob = 1
	if dodge:
		height = (33 if large else 17) if frame in [22, 25] else (30 if large else 14)
		leg_height = 10 if large else 5
		lean = 2 if frame == 22 else (4 if frame in [23, 24] else 1)
	var front := Vector2i(3, 0)
	var back := Vector2i(-3, 0)
	if stride >= 0:
		front = Vector2i(FOOT_X[stride], -FOOT_LIFT[stride])
		back = Vector2i(FOOT_X[(stride + 4) % 8], -FOOT_LIFT[(stride + 4) % 8])
		if large: front.x = roundi(front.x * 1.4); back.x = roundi(back.x * 1.4)
		if low: front.y = maxi(front.y, -1); back.y = maxi(back.y, -1)
	if air:
		match frame:
			17: front = Vector2i(5, -7); back = Vector2i(-4, -3)
			18: front = Vector2i(4, -4); back = Vector2i(-5, -5)
			19: front = Vector2i(2, -1); back = Vector2i(-3, -4)
		lean = 1 if frame != 19 else -1
	if frame == 20: front.x = 5; back.x = -5
	if dodge: front = Vector2i(9 if not large else 13, 0); back = Vector2i(-7 if not large else -11, -2)
	_draw_leg(image, Vector2i(-2, -leg_height + bob), back, false, large, executive)
	# Far shoulder and elbow sit behind the torso; foreground arm is aimed at runtime.
	var shoulder_y: int = -height + head_height + 2 + bob
	var far_x: int = lean - torso_width / 2 - 1
	_r(image, far_x, shoulder_y + 1, 4 if not large else 6, 6 if not large else 9, "ink")
	_r(image, far_x + 1, shoulder_y + 2, 2 if not large else 4, 5 if not large else 7, "shade")
	_r(image, far_x + 1, shoulder_y + (6 if not large else 9), 3, 3, "glove")
	if executive: _r(image, far_x + 1, shoulder_y + 5, 2, 1, "shirt")
	_draw_leg(image, Vector2i(2, -leg_height + bob), front, true, large, executive)
	var body_top: int = -height + head_height - 1 + bob
	var body_bottom: int = -leg_height + 2 + bob
	var left: int = lean - torso_width / 2
	_r(image, left - 1, body_top, torso_width + 2, body_bottom - body_top + 1, "ink")
	_r(image, left, body_top + 1, torso_width, body_bottom - body_top - 1, "coat")
	_r(image, left, body_top + 1, 3 if not large else 5, body_bottom - body_top - 1, "shade")
	if executive:
		_draw_suit(image, left, body_top, body_bottom, torso_width, lean)
	else:
		_r(image, left + 4, body_top + 2, 2 if not large else 3, body_bottom - body_top - 3, "light")
		# Security jackets retain their compact equipment silhouette.
		_r(image, left, body_bottom - 2, torso_width, 2, "pants_shadow")
		_r(image, lean + 1, body_bottom - 2, 2, 1, "accent")
		_r(image, left + torso_width - 4, body_bottom - 5, 3, 3, "shade")
		_r(image, left + torso_width - 4, body_top + 3, 3, 1, "accent")
	if large:
		_r(image, left - 2, body_top + 1, 7, 8, "ink")
		_r(image, left - 1, body_top + 2, 6, 5, "shade")
		_r(image, left - 1, body_top + 2, 5, 1, "light")
		_r(image, left + torso_width - 5, body_top + 1, 8, 7, "ink")
		_r(image, left + torso_width - 4, body_top + 2, 6, 4, "coat")
		_r(image, left + torso_width - 3, body_top + 2, 4, 1, "light")
		_r(image, lean + 2, body_top + 6, 3, 4, "accent")
	if kind == "scout":
		# A trailing scarf and diagonal harness separate scout from recruit at a glance.
		_r(image, left - 3, body_top + 1, 5, 3, "shade")
		_r(image, left - 5 - (1 if stride in [2, 3, 6, 7] else 0), body_top + 2, 4, 2, "accent")
		_l(image, Vector2i(left + 1, body_top + 3), Vector2i(left + torso_width - 2, body_bottom - 4), "pants_shadow", 2)
	var head_x: int = lean - head_width / 2
	var head_y: int = -height + bob
	_r(image, head_x - 1, head_y, head_width + 2, head_height + 2, "ink")
	_r(image, head_x, head_y + 1, head_width, head_height, "skin_dark")
	_r(image, head_x + 2, head_y + 2, head_width - 2, head_height - 2, "skin")
	_r(image, head_x, head_y, head_width, 2 if not large else 3, "hair")
	_r(image, head_x - 1, head_y + 2, 3, head_height - 1, "hair")
	_r(image, head_x + head_width - 2, head_y + 3, 2, 1, "ink")
	_r(image, head_x + head_width - 1, head_y + 3, 1, 1, "light")
	if kind == "spectre":
		# Side-parted hair, a bare eye and an uncovered jaw: no visor or mask.
		_r(image, head_x, head_y, head_width, 2, "hair")
		_l(image, Vector2i(head_x + 1, head_y), Vector2i(head_x + head_width - 2, head_y + 1), "hair_light")
		_r(image, head_x - 1, head_y + 2, 2, head_height - 1, "hair")
		_r(image, head_x + head_width - 2, head_y + 3, 1, 1, "ink")
		_r(image, head_x + head_width - 1, head_y + 3, 1, 1, "skin")
		_r(image, head_x + head_width - 1, head_y + 4, 1, 2, "skin_dark")
		_r(image, head_x + 2, head_y + 5, head_width - 3, 2, "skin")
		_r(image, head_x + head_width - 3, head_y + 6, 2, 1, "skin_dark")
	elif kind == "recruit":
		_r(image, head_x - 1, head_y - 1, head_width + 1, 4, "ink")
		_r(image, head_x, head_y, head_width, 2, "hair")
		_r(image, head_x + 1, head_y, 4, 1, "knee")
		_r(image, head_x + head_width - 1, head_y + 2, 3, 1, "accent")
	elif kind == "scout":
		_r(image, head_x, head_y, head_width, 2, "shade")
		_r(image, head_x + 2, head_y, 3, 1, "light")
	else:
		_r(image, head_x - 1, head_y, head_width + 2, 3, "hair")
		_r(image, head_x, head_y + 1, head_width, 1, "coat")
		_r(image, head_x - 2, head_y + 3, 2, 4, "accent")

func _draw_suit(image: Image, left: int, top: int, bottom: int, width: int, center: int) -> void:
	# Lapels frame a small light shirt wedge; the jacket opens below its single button.
	var length: int = bottom - top
	var shirt_length: int = mini(6, maxi(2, length - 2))
	_r(image, center - 2, top + 1, 5, shirt_length, "shirt_shadow")
	_r(image, center - 1, top + 1, 3, shirt_length, "shirt")
	_r(image, center, top + 2, 1, maxi(1, shirt_length - 1), "tie")
	_r(image, center - 1, top + 1, 1, 1, "shirt")
	_r(image, center + 1, top + 1, 1, 1, "shirt")
	_l(image, Vector2i(center - 3, top + 1), Vector2i(center - 1, top + shirt_length), "lapel")
	_l(image, Vector2i(center + 3, top + 1), Vector2i(center + 1, top + shirt_length), "light")
	_r(image, left, top + 2, 1, maxi(1, length - 3), "lapel")
	_r(image, left + width - 1, top + 2, 1, maxi(1, length - 3), "light")
	if length >= 8:
		_r(image, center, top + shirt_length + 1, 1, 1, "accent")
		_r(image, center, bottom - 2, 1, 3, "pants_shadow")
		_r(image, left + 1, bottom - 1, 3, 1, "lapel")
		_r(image, left + width - 4, bottom - 1, 3, 1, "lapel")

func _draw_leg(image: Image, hip: Vector2i, foot: Vector2i, front: bool, large: bool, tailored: bool = false) -> void:
	var knee := Vector2i(roundi((hip.x + foot.x) * 0.5) + (1 if front else -1), -5 + mini(foot.y / 2, 0))
	var ankle: Vector2i = foot + Vector2i(0, -2)
	var width: int = 6 if large else 4
	_l(image, hip, knee, "ink", width)
	_l(image, knee, ankle, "ink", width)
	_l(image, hip, knee, "pants" if front else "pants_shadow", width - 2)
	_l(image, knee, ankle, "pants" if front else "pants_shadow", width - 2)
	if front: _r(image, knee.x - 1, knee.y, 1 if tailored else (2 if not large else 3), 2, "knee")
	_r(image, foot.x - 2, foot.y - 3, 7 if large else 6, 3, "ink")
	_r(image, foot.x - 1, foot.y - 2, 5 if large else 4, 1, "boot")
	_r(image, foot.x - 1, foot.y - 1, 5 if large else 4, 1, "sole")

func _draw_dead(image: Image, large: bool, settled: bool, executive: bool = false) -> void:
	var width: int = 34 if large else 25
	var left: int = -width / 2
	var y: int = -7 if settled else -10
	_r(image, left, y + 3, width, 5, "ink")
	_r(image, left + 2, y + 4, 9 if large else 7, 3, "pants")
	_r(image, left + 11, y + 1, 14 if large else 9, 7, "ink")
	_r(image, left + 12, y + 2, 12 if large else 7, 4, "coat")
	_r(image, left + width - 7, y, 8, 7, "ink")
	_r(image, left + width - 6, y + 1, 6, 4, "skin")
	_r(image, left + width - 6, y + 1, 6, 2, "hair")
	if executive:
		_r(image, left + 13, y + 2, 2, 1, "lapel")
		_r(image, left + 16, y + 2, 2, 3, "shirt")
		_r(image, left + 16, y + 3, 1, 2, "tie")
		_r(image, left + 12, y + 5, 5, 1, "lapel")
		_r(image, left + width - 6, y + 1, 4, 1, "hair_light")
		_r(image, left + width - 3, y + 4, 1, 1, "skin_dark")
		_r(image, left + 1, y + 6, 4, 1, "boot")

func _r(image: Image, x: int, y: int, w: int, h: int, key: String) -> void:
	var rect := Rect2i(origin + Vector2i(x, y), Vector2i(w, h)).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if rect.has_area(): image.fill_rect(rect, palette[key])

func _l(image: Image, a: Vector2i, b: Vector2i, key: String, width: int = 1) -> void:
	var dx: int = absi(b.x - a.x)
	var sx: int = 1 if a.x < b.x else -1
	var dy: int = -absi(b.y - a.y)
	var sy: int = 1 if a.y < b.y else -1
	var error: int = dx + dy
	while true:
		_r(image, a.x - width / 2, a.y - width / 2, width, width, key)
		if a == b: break
		var twice: int = error * 2
		if twice >= dy: error += dy; a.x += sx
		if twice <= dx: error += dx; a.y += sy

func _build_weapon(weapon: String) -> void:
	origin = Vector2i(24, 24)
	palette = _palette("spectre")
	var base := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	base.fill(Color.TRANSPARENT)
	match weapon:
		"pistol":
			_r(base, 7, -4, 14, 6, "ink"); _r(base, 8, -3, 12, 3, "pants")
			_r(base, 9, -3, 10, 1, "steel"); _r(base, 9, 0, 5, 5, "ink")
			_r(base, 10, 1, 2, 3, "shade"); _r(base, 6, 0, 5, 3, "glove")
		"shotgun":
			_r(base, 4, -4, 18, 5, "ink"); _r(base, 7, -3, 14, 1, "steel")
			_r(base, 9, -2, 12, 2, "pants"); _r(base, 10, 0, 8, 3, "hair")
			_r(base, 11, 0, 5, 1, "accent"); _r(base, 1, 0, 7, 3, "ink")
			_r(base, 2, 1, 6, 1, "shade"); _r(base, 7, 0, 4, 3, "glove")
		"blade":
			_r(base, 5, -1, 15, 3, "ink"); _r(base, 9, -1, 10, 1, "steel")
			_r(base, 9, 0, 8, 1, "knee"); _r(base, 7, -3, 2, 7, "ink")
			_r(base, 4, 0, 4, 2, "glove")
	var sheet := Image.create(48 * 8, 48 * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	for index: int in range(32):
		var angle: float = index * TAU / 32.0
		var frame := Image.create(48, 48, false, Image.FORMAT_RGBA8)
		frame.fill(Color.TRANSPARENT)
		# Inverse nearest sampling produces solid pixel clusters at every direction.
		for y: int in range(48):
			for x: int in range(48):
				var source: Vector2 = (Vector2(x, y) - Vector2(24, 24)).rotated(-angle) + Vector2(24, 24)
				var point := Vector2i(roundi(source.x), roundi(source.y))
				if point.x >= 0 and point.x < 48 and point.y >= 0 and point.y < 48:
					frame.set_pixel(x, y, base.get_pixelv(point))
		sheet.blit_rect(frame, Rect2i(0, 0, 48, 48), Vector2i(index % 8, index / 8) * 48)
	assert(sheet.save_png(OUT + weapon + ".png") == OK)
