extends SceneTree
## Recortes literais autorizados em 27/10/2026. Sem redesenho ou reamostragem.
const OUT: String = "res://assets/art/reference/"
const CELL := Vector2i(256, 256)
# x, y, largura, altura, pivô x, início dos braços, fim dos braços.
const FRAMES: Array[Array] = [
	[20,20,145,205,65,77,131], [165,20,130,205,61,80,133],
	[295,20,133,205,61,80,133], [430,20,135,205,61,80,133],
	[18,238,140,196,66,72,126], [158,238,125,196,59,72,126],
	[283,238,128,196,59,72,126], [411,238,118,196,54,72,126], [530,238,130,196,60,72,126],
	[710,238,154,196,72,68,123], [864,238,151,196,73,68,123],
	[1016,238,130,196,61,68,123], [1146,238,137,196,66,68,123], [1283,238,150,196,72,68,123],
	[20,630,141,155,65,57,112], [175,640,132,145,64,47,102],
	[345,610,132,220,65,82,136], [480,610,131,220,65,82,136], [612,610,135,220,66,82,136],
	[748,610,135,220,66,82,136], [890,640,140,183,66,60,115],
	[560,834,140,208,60,74,135], [700,834,137,208,58,74,135],
	[835,834,147,208,70,74,135], [982,834,134,208,66,74,135],
	[1116,834,128,208,63,74,135], [1244,834,193,208,90,74,135],
	[870,438,135,202,62,72,133], [1017,438,129,202,61,72,133],
	[1150,438,140,202,65,72,133], [1290,438,145,202,67,72,133],
	[10,834,129,208,61,72,133], [139,834,117,208,57,72,133],
	[257,834,145,208,65,72,133], [402,834,140,208,62,72,133],
	[732,18,142,210,67,72,133], [585,18,148,210,66,72,133],
]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var source: Image = Image.load_from_file("res://references/Retro Pixel Action Hero Sprite Sheet.png")
	assert(source != null and source.get_format() == Image.FORMAT_RGBA8)
	var atlas := Image.create(CELL.x * 8, CELL.y * 5, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.TRANSPARENT)
	var bodies: Image = atlas.duplicate()
	var arms: Image = atlas.duplicate()
	var metadata: Array[Dictionary] = []
	for index: int in range(FRAMES.size()):
		var recipe: Array = FRAMES[index]
		var rect := Rect2i(recipe[0], recipe[1], recipe[2], recipe[3])
		var isolated: Dictionary = _literal_crop(source, rect) if index <= 3 or (index >= 14 and index <= 20) or (index >= 27 and index <= 30) or index >= 35 else _isolate(source, rect)
		var original_rect: Rect2i = rect
		rect = isolated.rect
		print("FRAME ", index, " RECT ", rect)
		var frame: Image = isolated.image
		var shift := Vector2(rect.position - original_rect.position)
		var used: Rect2i = frame.get_used_rect()
		var origin := Vector2i(int(recipe[4]) - int(shift.x), used.end.y - 1)
		var cell_at := Vector2i(index % 8, index / 8) * CELL
		atlas.blit_rect(frame, Rect2i(Vector2i.ZERO, rect.size), cell_at)
		var body: Image = frame.duplicate()
		var arm := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
		arm.fill(Color.TRANSPARENT)
		var arm_top: int = int(recipe[5]) - int(shift.y)
		var arm_bottom: int = int(recipe[6]) - int(shift.y)
		var arm_left: int = 32 - int(shift.x)
		var pivot := Vector2i(arm_left, arm_top + 9)
		# Camada articulada somente para ângulos que não existem na folha.
		# A apresentação horizontal usa o recorte original inteiro, pixel por pixel.
		var mask := PackedVector2Array([Vector2(arm_left, arm_top + 9), Vector2(59 - shift.x, arm_top + 11), Vector2(75 - shift.x, arm_top), Vector2(rect.size.x, arm_top), Vector2(rect.size.x, arm_bottom), Vector2(81 - shift.x, arm_bottom), Vector2(60 - shift.x, arm_bottom - 15), Vector2(arm_left, arm_bottom - 17)])
		var weapon_mask := PackedVector2Array([Vector2(75, 110) - shift, Vector2(65, 90) - shift, Vector2(110, 0) - shift, Vector2(140, 0) - shift, Vector2(103, 130) - shift])
		var is_reload: bool = index >= 27 and index <= 30
		for y: int in range(0 if is_reload else maxi(0, arm_top), mini(maxi(arm_bottom, 155 - int(shift.y)) if is_reload else arm_bottom, rect.size.y)):
			for x: int in range(maxi(0, arm_left), rect.size.x):
				var point := Vector2(x, y)
				if not Geometry2D.is_point_in_polygon(point, mask) and not (is_reload and Geometry2D.is_point_in_polygon(point, weapon_mask)): continue
				var color: Color = frame.get_pixel(x, y)
				arm.set_pixel(x, y, color)
				# O tórax oculto vem da pose de punhos da mesma folha, sem inventar roupa.
				var patch_at := Vector2i(71, 1022) + Vector2i(x, y) - origin
				var patch: Color = source.get_pixelv(patch_at) if Rect2i(Vector2i.ZERO, source.get_size()).has_point(patch_at) else Color.TRANSPARENT
				body.set_pixel(x, y, patch if x < 85 - shift.x and y >= arm_top + 8 and color.a > 0.0 else Color.TRANSPARENT)
		bodies.blit_rect(body, Rect2i(Vector2i.ZERO, rect.size), cell_at)
		arms.blit_rect(arm, Rect2i(Vector2i.ZERO, rect.size), cell_at)
		metadata.append({"source": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "origin": [origin.x, origin.y], "pivot": [pivot.x, pivot.y], "muzzle": [int(recipe[2]) - 3 - int(shift.x), int(recipe[5]) + 9 - int(shift.y)]})
	assert(atlas.save_png(OUT + "hero-poses.png") == OK)
	assert(bodies.save_png(OUT + "hero-bodies.png") == OK)
	assert(arms.save_png(OUT + "hero-arms.png") == OK)
	var file := FileAccess.open(OUT + "hero-poses.json", FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify({"cell": [CELL.x, CELL.y], "frames": metadata}, "\t"))
	file.close()
	assert(DirAccess.copy_absolute("res://references/Pixel-Art Corporate Lobby Brawl Stage.png", OUT + "office-corridor.png") == OK)
	print("REFERENCE_ART_IMPORTED frames=", metadata.size(), " direct_source_pixels=true")
	quit()

func _isolate(source: Image, initial: Rect2i) -> Dictionary:
	# Componentes conexos separam os pés/cabelos de vizinhos sem repintar o ator.
	var area: Rect2i = initial.grow(20).intersection(Rect2i(Vector2i.ZERO, source.get_size()))
	var part: Image = source.get_region(area)
	var width: int = part.get_width()
	var height: int = part.get_height()
	var opaque := PackedByteArray()
	opaque.resize(width * height)
	for y: int in range(height):
		for x: int in range(width):
			var sample: Color = part.get_pixel(x, y)
			var blood_bridge: bool = initial.position.y >= 830 and sample.r > 0.08 and sample.r > sample.g * 1.8 and sample.r > sample.b * 1.6
			opaque[y * width + x] = 1 if sample.a > 0.5 and not blood_bridge else 0
	var core := PackedByteArray()
	core.resize(width * height)
	# Pontes de contorno muito finas entre duas poses não pertencem ao mesmo corpo.
	for y: int in range(2, height - 2):
		for x: int in range(2, width - 2):
			var solid: bool = true
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					if opaque[(y + dy) * width + x + dx] == 0:
						solid = false
						break
				if not solid: break
			if solid: core[y * width + x] = 1
	var visited := PackedByteArray()
	visited.resize(width * height)
	var best := PackedInt32Array()
	for y: int in range(height):
		for x: int in range(width):
			var start: int = y * width + x
			if visited[start] != 0: continue
			visited[start] = 1
			if core[start] == 0: continue
			var component := PackedInt32Array([start])
			var cursor: int = 0
			while cursor < component.size():
				var pixel: int = component[cursor]
				cursor += 1
				var px: int = pixel % width
				var py: int = pixel / width
				for dy: int in range(-1, 2):
					for dx: int in range(-1, 2):
						var nx: int = px + dx
						var ny: int = py + dy
						if nx < 0 or nx >= width or ny < 0 or ny >= height: continue
						var next: int = ny * width + nx
						if visited[next] != 0: continue
						visited[next] = 1
						if core[next] != 0: component.append(next)
			if component.size() > best.size(): best = component
	assert(not best.is_empty())
	var isolated := Image.create(width, height, false, Image.FORMAT_RGBA8)
	isolated.fill(Color.TRANSPARENT)
	for pixel: int in best:
		var px: int = pixel % width
		var py: int = pixel / width
		for dy: int in range(-4, 5):
			for dx: int in range(-4, 5):
				var point := Vector2i(px + dx, py + dy)
				if point.x < 0 or point.x >= width or point.y < 0 or point.y >= height: continue
				isolated.set_pixelv(point, part.get_pixelv(point))
	var bounds: Rect2i = isolated.get_used_rect()
	assert(bounds.size.x <= CELL.x and bounds.size.y <= CELL.y)
	return {"image": isolated.get_region(bounds), "rect": Rect2i(area.position + bounds.position, bounds.size)}

func _literal_crop(source: Image, rect: Rect2i) -> Dictionary:
	var frame: Image = source.get_region(rect)
	var bounds: Rect2i = frame.get_used_rect()
	return {"image": frame.get_region(bounds), "rect": Rect2i(rect.position + bounds.position, bounds.size)}
