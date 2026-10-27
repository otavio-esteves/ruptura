extends SceneTree
## Original high-density pixel recipes. Atlas resolution is twice the logical actor rig.
## Feet, logical frame rectangles and weapon muzzles remain identical to the gameplay contract.
const OUT: String = "res://assets/art/actors/"
const Recipe = preload("res://tools/art/detail_actor_recipe.gd")
const DENSITY: int = 2

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	for kind: String in ["spectre", "recruit", "scout", "chacal", "chacal_rage"]:
		_build_body(kind)
	for weapon: String in ["pistol", "shotgun", "blade"]:
		_build_weapon(weapon)
	print("ACTOR_ATLASES_BUILT=", ProjectSettings.globalize_path(OUT), " DENSITY=", DENSITY)
	quit()

func _build_body(kind: String) -> void:
	var frame_size := Vector2i(96, 96) if kind.begins_with("chacal") else Vector2i(64, 80)
	var sheet := Image.create(frame_size.x * 8, frame_size.y * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	for index: int in range(32):
		var frame := Image.create(frame_size.x, frame_size.y, false, Image.FORMAT_RGBA8)
		frame.fill(Color.TRANSPARENT)
		Recipe.draw_body(frame, kind, index)
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, frame_size), Vector2i(index % 8, index / 8) * frame_size)
	assert(sheet.save_png(OUT + kind + ".png") == OK, "Cannot write actor atlas")

func _build_weapon(weapon: String) -> void:
	const FRAME: int = 96
	const CENTER: Vector2 = Vector2(48, 48)
	var base := Image.create(FRAME, FRAME, false, Image.FORMAT_RGBA8)
	base.fill(Color.TRANSPARENT)
	Recipe.draw_weapon(base, weapon)
	var sheet := Image.create(FRAME * 8, FRAME * 4, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.TRANSPARENT)
	for index: int in range(32):
		var angle: float = index * TAU / 32.0
		var mirror_grip: bool = cos(angle) < -0.001
		var frame := Image.create(FRAME, FRAME, false, Image.FORMAT_RGBA8)
		frame.fill(Color.TRANSPARENT)
		# Each direction is authored by inverse nearest rasterization, with no texture blur.
		for y: int in range(FRAME):
			for x: int in range(FRAME):
				var source: Vector2 = (Vector2(x, y) - CENTER).rotated(-angle)
				# Mirror the local grip before forward rotation on the left-facing hemisphere.
				# Horizontal left therefore keeps its magazine/stock below the barrel.
				if mirror_grip: source.y = -source.y
				source += CENTER
				var point := Vector2i(roundi(source.x), roundi(source.y))
				if point.x >= 0 and point.x < FRAME and point.y >= 0 and point.y < FRAME:
					frame.set_pixel(x, y, base.get_pixelv(point))
		sheet.blit_rect(frame, Rect2i(0, 0, FRAME, FRAME), Vector2i(index % 8, index / 8) * FRAME)
	assert(sheet.save_png(OUT + weapon + ".png") == OK, "Cannot write weapon atlas")
