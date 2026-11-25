## Hand-drawn forest decorations: broadleaf trees, pines, bushes, rocks,
## mushrooms, flowers, ferns and a friendly wooden signpost.
extends Node2D

@export var kind := 0
@export var decoration_scale := 1.0
@export var variant_seed := 1


func setup(new_kind: int, new_scale: float = 1.0, new_seed: int = 1) -> void:
	kind = new_kind
	decoration_scale = new_scale
	variant_seed = new_seed
	queue_redraw()


func _draw() -> void:
	var s := decoration_scale
	var rng := RandomNumberGenerator.new()
	rng.seed = variant_seed

	match kind:
		0:
			_draw_broadleaf(s, rng)
		1:
			_draw_pine(s, rng)
		2:
			_draw_bush(s, rng)
		3:
			_draw_rock(s, rng)
		4:
			_draw_mushroom(s, rng)
		5:
			_draw_flowers(s, rng)
		6:
			_draw_fern(s, rng)
		8:
			_draw_snow_pine(s, rng)
		9:
			_draw_ice_crystal(s, rng)
		10:
			_draw_snowman(s, rng)
		11:
			_draw_cactus(s, rng)
		12:
			_draw_palm(s, rng)
		13:
			_draw_dune_rock(s, rng)
		14:
			_draw_dead_tree(s, rng)
		15:
			_draw_gravestone(s, rng)
		16:
			_draw_torch(s, rng)
		17:
			_draw_magma_rock(s, rng)
		18:
			_draw_fire_flower(s, rng)
		19:
			_draw_obsidian(s, rng)
		20:
			_draw_cloud_bush(s, rng)
		21:
			_draw_star_flower(s, rng)
		22:
			_draw_floating_rock(s, rng)
		_:
			_draw_sign(s)


func _draw_broadleaf(s: float, rng: RandomNumberGenerator) -> void:
	# Trunk with roots.
	var trunk := Color(0.31, 0.18, 0.09)
	var trunk_light := Color(0.45, 0.28, 0.14)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-13 * s, 0),
		Vector2(-8 * s, -82 * s),
		Vector2(8 * s, -84 * s),
		Vector2(15 * s, 0),
	]), trunk)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12 * s, 0), Vector2(-28 * s, 5 * s), Vector2(-5 * s, -8 * s)
	]), trunk.darkened(0.15))
	draw_colored_polygon(PackedVector2Array([
		Vector2(10 * s, 0), Vector2(28 * s, 4 * s), Vector2(4 * s, -8 * s)
	]), trunk.darkened(0.15))
	draw_line(Vector2(-4 * s, -8 * s), Vector2(-7 * s, -70 * s), trunk_light, 3.0 * s, true)
	draw_line(Vector2(6 * s, -12 * s), Vector2(9 * s, -66 * s), trunk.darkened(0.2), 2.0 * s, true)

	# Branch silhouette.
	draw_line(Vector2(0, -60 * s), Vector2(-28 * s, -84 * s), trunk, 5.0 * s, true)
	draw_line(Vector2(2, -68 * s), Vector2(27 * s, -92 * s), trunk, 4.0 * s, true)

	var dark := Color(0.11, 0.40, 0.23)
	var mid := Color(0.20, 0.56, 0.30)
	var light := Color(0.42, 0.75, 0.39)
	# Big lumpy canopy.
	var blobs := [
		Vector2(-28, -100), Vector2(0, -119), Vector2(31, -104),
		Vector2(-46, -78), Vector2(47, -80), Vector2(-14, -142),
		Vector2(22, -138), Vector2(0, -92),
	]
	for i in blobs.size():
		var blob: Vector2 = blobs[i]
		var radius := (25.0 + rng.randf_range(0.0, 10.0)) * s
		draw_circle(blob * s, radius, dark)
	for i in blobs.size():
		var blob: Vector2 = blobs[i]
		var offset := Vector2(rng.randf_range(-5.0, 3.0), rng.randf_range(-7.0, 2.0)) * s
		var radius := (20.0 + rng.randf_range(0.0, 7.0)) * s
		draw_circle(blob * s + offset, radius, mid)
	for i in 5:
		var blob: Vector2 = blobs[(i * 2 + 1) % blobs.size()]
		draw_circle(blob * s + Vector2(-5, -8) * s, (10.0 + i * 1.7) * s, Color(light, 0.75))

	# Hanging vines and fruit.
	for i in 3:
		var x := (-30.0 + float(i) * 28.0) * s
		draw_line(Vector2(x, -88 * s), Vector2(x + sin(float(i)) * 7.0 * s, -64 * s), Color(0.25, 0.55, 0.27), 2.0 * s, true)
		draw_circle(Vector2(x + sin(float(i)) * 7.0 * s, -62 * s), 2.5 * s, Color(0.95, 0.72, 0.27))


func _draw_pine(s: float, rng: RandomNumberGenerator) -> void:
	var trunk := Color(0.35, 0.20, 0.10)
	draw_rect(Rect2(-6 * s, -72 * s, 12 * s, 72 * s), trunk)
	for i in 5:
		var y := float(i) * 28.0
		var width := (58.0 - float(i) * 6.0) * s
		var top := (-145.0 + y) * s
		var bottom := (-38.0 + y) * s
		var color := Color(0.10, 0.36, 0.23).lerp(Color(0.22, 0.55, 0.30), float(i) / 4.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, top),
			Vector2(-width, bottom),
			Vector2(width, bottom),
		]), color)
		draw_line(Vector2(0, top + 8 * s), Vector2(-width * 0.65, bottom - 4 * s), Color(0.43, 0.69, 0.37, 0.45), 2.0 * s, true)
	for i in 4:
		var x := rng.randf_range(-22.0, 22.0) * s
		draw_circle(Vector2(x, rng.randf_range(-115.0, -42.0) * s), 2.2 * s, Color(1.0, 0.84, 0.32, 0.85))


func _draw_bush(s: float, rng: RandomNumberGenerator) -> void:
	var dark := Color(0.12, 0.38, 0.20)
	var mid := Color(0.24, 0.60, 0.30)
	for i in 5:
		var x := (-28.0 + float(i) * 14.0) * s
		var y := (-12.0 - float(i % 3) * 8.0) * s
		draw_circle(Vector2(x, y), (16.0 + float(i % 2) * 5.0) * s, dark)
	for i in 4:
		var x := (-18.0 + float(i) * 13.0) * s
		draw_circle(Vector2(x, -17 * s), (12.0 + float(i % 2) * 4.0) * s, mid)
	for i in maxi(2, int(4 * s)):
		draw_circle(Vector2(rng.randf_range(-30.0, 30.0) * s, rng.randf_range(-26.0, -8.0) * s), 2.6 * s, Color(1.0, 0.55, 0.62))
	draw_line(Vector2(-30 * s, 0), Vector2(30 * s, 0), Color(0.20, 0.48, 0.24), 3.0 * s, true)


func _draw_rock(s: float, rng: RandomNumberGenerator) -> void:
	var gray := Color(0.40, 0.45, 0.46)
	var light := Color(0.62, 0.67, 0.66)
	var dark := Color(0.26, 0.30, 0.31)
	var points := PackedVector2Array([
		Vector2(-30, 0), Vector2(-24, -26), Vector2(-6, -39),
		Vector2(17, -33), Vector2(31, -12), Vector2(26, 0),
	])
	for i in points.size():
		points[i] = points[i] * s
	draw_colored_polygon(points, gray)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22 * s, -22 * s), Vector2(-5 * s, -36 * s), Vector2(13 * s, -31 * s), Vector2(4 * s, -19 * s)
	]), light)
	draw_colored_polygon(PackedVector2Array([
		Vector2(4 * s, -19 * s), Vector2(28 * s, -11 * s), Vector2(24 * s, 0), Vector2(0, 0)
	]), dark)
	draw_circle(Vector2(-14 * s, -28 * s), 9.0 * s, Color(0.33, 0.58, 0.30, 0.65))
	draw_circle(Vector2(9 * s, -26 * s), 6.0 * s, Color(0.40, 0.65, 0.34, 0.55))
	for i in 3:
		draw_circle(Vector2(rng.randf_range(-18.0, 18.0) * s, rng.randf_range(-18.0, -3.0) * s), 1.8 * s, Color(0.24, 0.27, 0.27, 0.5))


func _draw_mushroom(s: float, rng: RandomNumberGenerator) -> void:
	var stem_color := Color(0.94, 0.88, 0.72)
	var cap_color := Color(0.91, 0.31, 0.25)
	draw_rect(Rect2(-5 * s, -28 * s, 10 * s, 28 * s), stem_color)
	draw_rect(Rect2(-2 * s, -26 * s, 3 * s, 22 * s), Color(1, 0.97, 0.87, 0.5))
	var cap := PackedVector2Array()
	for i in 16:
		var angle := PI + PI * float(i) / 15.0
		cap.append(Vector2(cos(angle) * 26.0 * s, -29 * s + sin(angle) * 16.0 * s))
	draw_colored_polygon(cap, cap_color)
	draw_rect(Rect2(-26 * s, -30 * s, 52 * s, 3 * s), cap_color.darkened(0.15))
	for i in 5:
		var spot := Vector2(rng.randf_range(-17.0, 17.0) * s, rng.randf_range(-40.0, -31.0) * s)
		draw_circle(spot, rng.randf_range(2.4, 4.4) * s, Color(1, 0.94, 0.78, 0.9))
	# Grass at the base.
	for i in 4:
		var x := (-16.0 + float(i) * 10.0) * s
		draw_line(Vector2(x, 0), Vector2(x + sin(float(i)) * 4.0 * s, -8 * s), Color(0.28, 0.62, 0.30), 2.0 * s, true)


func _draw_flowers(s: float, rng: RandomNumberGenerator) -> void:
	var petal_colors := [Color(1.0, 0.55, 0.68), Color(1.0, 0.84, 0.32), Color(0.72, 0.68, 1.0), Color(0.98, 0.96, 0.90)]
	for i in 5:
		var x := (-20.0 + float(i) * 10.0 + rng.randf_range(-3.0, 3.0)) * s
		var height := rng.randf_range(13.0, 24.0) * s
		draw_line(Vector2(x, 0), Vector2(x + sin(float(i)) * 3.0 * s, -height), Color(0.25, 0.60, 0.29), 2.0 * s, true)
		draw_circle(Vector2(x + sin(float(i)) * 3.0 * s, -height), 4.8 * s, petal_colors[i % petal_colors.size()])
		draw_circle(Vector2(x + sin(float(i)) * 3.0 * s, -height), 2.1 * s, Color(1.0, 0.92, 0.55))
	# Leaves.
	draw_set_transform(Vector2(-10 * s, -5 * s), -0.5, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 5.0 * s, Color(0.30, 0.65, 0.32))
	draw_set_transform(Vector2(12 * s, -3 * s), 0.4, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 4.5 * s, Color(0.30, 0.65, 0.32))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_fern(s: float, _rng: RandomNumberGenerator) -> void:
	for i in 7:
		var angle := -PI * 0.92 + PI * 0.84 * float(i) / 6.0
		var length := (35.0 + float(i % 3) * 8.0) * s
		var start := Vector2.ZERO
		var end := Vector2(cos(angle) * length, sin(angle) * length)
		draw_line(start, end, Color(0.16, 0.46, 0.24), 2.4 * s, true)
		for j in 3:
			var t := 0.35 + float(j) * 0.2
			var point := start.lerp(end, t)
			var leaf := Vector2(cos(angle - 0.9), sin(angle - 0.9)) * 6.0 * s
			draw_line(point, point + leaf, Color(0.28, 0.66, 0.31), 2.0 * s, true)
			draw_line(point, point + Vector2(cos(angle + 0.9), sin(angle + 0.9)) * 5.0 * s, Color(0.25, 0.60, 0.28), 2.0 * s, true)


func _draw_snow_pine(s: float, rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(-6 * s, -78 * s, 12 * s, 78 * s), Color(0.36, 0.27, 0.22))
	for i in 5:
		var y := float(i) * 26.0
		var width := (56.0 - float(i) * 6.0) * s
		var top := (-150.0 + y) * s
		var bottom := (-44.0 + y) * s
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, top), Vector2(-width, bottom), Vector2(width, bottom)
		]), Color(0.20, 0.42, 0.44).lerp(Color(0.38, 0.66, 0.68), float(i) / 4.0))
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, top), Vector2(-width * 0.82, bottom - 9 * s), Vector2(width * 0.82, bottom - 9 * s)
		]), Color(0.92, 0.97, 1.0, 0.9))
	for i in 5:
		draw_circle(Vector2(rng.randf_range(-24.0, 24.0) * s, rng.randf_range(-120.0, -40.0) * s), 1.8 * s, Color(1, 1, 1, 0.8))


func _draw_ice_crystal(s: float, rng: RandomNumberGenerator) -> void:
	var base := Color(0.62, 0.88, 1.0)
	for i in 4:
		var x := (-20.0 + float(i) * 13.0) * s
		var height := (28.0 + rng.randf_range(0.0, 34.0)) * s
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 8 * s, 0), Vector2(x, -height), Vector2(x + 8 * s, 0)
		]), Color(base, 0.85))
		draw_line(Vector2(x, 0), Vector2(x, -height), Color(1, 1, 1, 0.85), 1.6 * s, true)
	draw_circle(Vector2(0, -22 * s), 16.0 * s, Color(0.75, 0.95, 1.0, 0.18))


func _draw_snowman(s: float, rng: RandomNumberGenerator) -> void:
	draw_circle(Vector2(0, -18 * s), 17.0 * s, Color(0.94, 0.97, 1.0))
	draw_circle(Vector2(0, -44 * s), 12.0 * s, Color(0.97, 0.99, 1.0))
	draw_circle(Vector2(-4 * s, -47 * s), 1.8 * s, Color(0.10, 0.12, 0.16))
	draw_circle(Vector2(4 * s, -47 * s), 1.8 * s, Color(0.10, 0.12, 0.16))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -42 * s), Vector2(11 * s, -40 * s), Vector2(0, -38 * s)
	]), Color(1.0, 0.62, 0.20))
	# Scarf and twig arms.
	draw_rect(Rect2(-12 * s, -36 * s, 24 * s, 5 * s), Color(0.88, 0.28, 0.30))
	draw_line(Vector2(-14 * s, -26 * s), Vector2(-34 * s, -38 * s), Color(0.34, 0.24, 0.16), 2.0 * s, true)
	draw_line(Vector2(14 * s, -26 * s), Vector2(34 * s, -40 * s), Color(0.34, 0.24, 0.16), 2.0 * s, true)
	if rng.randf() < 0.5:
		draw_circle(Vector2(0, -62 * s), 10.0 * s, Color(0.15, 0.15, 0.20))


func _draw_cactus(s: float, _rng: RandomNumberGenerator) -> void:
	var green := Color(0.29, 0.56, 0.30)
	var dark := Color(0.20, 0.40, 0.22)
	draw_rect(Rect2(-10 * s, -92 * s, 20 * s, 92 * s), green)
	draw_rect(Rect2(-8 * s, -88 * s, 5 * s, 82 * s), Color(0.44, 0.70, 0.38, 0.75))
	# Arms.
	draw_rect(Rect2(-34 * s, -62 * s, 14 * s, 28 * s), green)
	draw_rect(Rect2(-34 * s, -62 * s, 26 * s, 13 * s), green)
	draw_rect(Rect2(20 * s, -76 * s, 14 * s, 34 * s), green)
	draw_rect(Rect2(8 * s, -76 * s, 26 * s, 13 * s), green)
	for i in 9:
		var x := (-8.0 + float(i % 3) * 8.0) * s
		var y := (-84.0 + float(i) * 8.0) * s
		draw_line(Vector2(x, y), Vector2(x + 2.0 * s, y + 3.0 * s), dark, 1.3 * s, true)
	draw_circle(Vector2(0, -96 * s), 5.0 * s, Color(1.0, 0.52, 0.60))


func _draw_palm(s: float, _rng: RandomNumberGenerator) -> void:
	draw_line(Vector2(0, 0), Vector2(8 * s, -96 * s), Color(0.55, 0.36, 0.18), 9.0 * s, true)
	for i in 6:
		var angle := -PI * 0.9 + PI * 0.8 * float(i) / 5.0
		var end := Vector2(8 * s, -96 * s) + Vector2(cos(angle), sin(angle)) * 44.0 * s
		draw_line(Vector2(8 * s, -96 * s), end, Color(0.18, 0.48, 0.28), 5.0 * s, true)
		draw_line(Vector2(8 * s, -96 * s), end, Color(0.34, 0.66, 0.34), 2.5 * s, true)
	for i in 3:
		draw_circle(Vector2((2.0 + float(i) * 6.0) * s, -88 * s), 4.0 * s, Color(0.56, 0.36, 0.18))


func _draw_dune_rock(s: float, rng: RandomNumberGenerator) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-32 * s, 0), Vector2(-22 * s, -22 * s), Vector2(-2 * s, -32 * s),
		Vector2(22 * s, -24 * s), Vector2(33 * s, 0)
	]), Color(0.66, 0.48, 0.26))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18 * s, -20 * s), Vector2(-2 * s, -31 * s), Vector2(16 * s, -23 * s), Vector2(4 * s, -14 * s)
	]), Color(0.84, 0.66, 0.40))
	for i in 4:
		draw_circle(Vector2(rng.randf_range(-22.0, 22.0) * s, rng.randf_range(-22.0, -4.0) * s), 1.6 * s, Color(0.50, 0.35, 0.18, 0.6))


func _draw_dead_tree(s: float, _rng: RandomNumberGenerator) -> void:
	var wood := Color(0.24, 0.20, 0.22)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9 * s, 0), Vector2(-5 * s, -96 * s), Vector2(6 * s, -98 * s), Vector2(11 * s, 0)
	]), wood)
	draw_line(Vector2(-4 * s, -60 * s), Vector2(-36 * s, -92 * s), wood, 4.0 * s, true)
	draw_line(Vector2(4 * s, -72 * s), Vector2(38 * s, -104 * s), wood, 4.0 * s, true)
	draw_line(Vector2(-30 * s, -88 * s), Vector2(-42 * s, -78 * s), wood, 3.0 * s, true)
	draw_line(Vector2(34 * s, -100 * s), Vector2(44 * s, -116 * s), wood, 3.0 * s, true)
	# Spooky eyes in the hollow.
	draw_circle(Vector2(0, -48 * s), 7.0 * s, Color(0.08, 0.06, 0.09))
	draw_circle(Vector2(-3 * s, -49 * s), 1.6 * s, Color(0.85, 0.36, 1.0))
	draw_circle(Vector2(3 * s, -49 * s), 1.6 * s, Color(0.85, 0.36, 1.0))


func _draw_gravestone(s: float, _rng: RandomNumberGenerator) -> void:
	var stone := Color(0.36, 0.36, 0.43)
	var box := StyleBoxFlat.new()
	box.bg_color = stone
	box.border_color = Color(0.22, 0.22, 0.28)
	box.set_border_width_all(2)
	box.corner_radius_top_left = 22
	box.corner_radius_top_right = 22
	draw_style_box(box, Rect2(-20 * s, -58 * s, 40 * s, 58 * s))
	draw_line(Vector2(0, -46 * s), Vector2(0, -20 * s), Color(0.20, 0.20, 0.26), 3.0 * s, true)
	draw_line(Vector2(-9 * s, -36 * s), Vector2(9 * s, -36 * s), Color(0.20, 0.20, 0.26), 3.0 * s, true)
	draw_circle(Vector2(-16 * s, -10 * s), 8.0 * s, Color(0.24, 0.34, 0.24, 0.8))


func _draw_torch(s: float, _rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(-4 * s, -70 * s, 8 * s, 70 * s), Color(0.33, 0.23, 0.16))
	draw_circle(Vector2(0, -76 * s), 16.0 * s, Color(1.0, 0.48, 0.16, 0.20))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9 * s, -72 * s), Vector2(0, -98 * s), Vector2(9 * s, -72 * s), Vector2(0, -66 * s)
	]), Color(1.0, 0.56, 0.16))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5 * s, -74 * s), Vector2(0, -88 * s), Vector2(5 * s, -74 * s)
	]), Color(1.0, 0.90, 0.46))
	draw_circle(Vector2(0, -76 * s), 3.0 * s, Color(1, 1, 0.82, 0.9))


func _draw_magma_rock(s: float, rng: RandomNumberGenerator) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-32 * s, 0), Vector2(-24 * s, -26 * s), Vector2(-4 * s, -38 * s),
		Vector2(20 * s, -30 * s), Vector2(32 * s, 0)
	]), Color(0.22, 0.17, 0.17))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18 * s, -23 * s), Vector2(-4 * s, -36 * s), Vector2(14 * s, -27 * s), Vector2(2 * s, -18 * s)
	]), Color(0.34, 0.25, 0.24))
	for i in 3:
		var x := rng.randf_range(-20.0, 20.0) * s
		var y := rng.randf_range(-30.0, -8.0) * s
		draw_line(Vector2(x, y), Vector2(x + rng.randf_range(-6.0, 6.0) * s, y + 9.0 * s), Color(1.0, 0.46, 0.12, 0.9), 2.2 * s, true)
	draw_circle(Vector2(-6 * s, -28 * s), 2.0 * s, Color(1.0, 0.72, 0.22))


func _draw_fire_flower(s: float, _rng: RandomNumberGenerator) -> void:
	for i in 3:
		var x := (-14.0 + float(i) * 14.0) * s
		draw_line(Vector2(x, 0), Vector2(x + sin(float(i)) * 3.0 * s, -26 * s), Color(0.28, 0.38, 0.20), 2.2 * s, true)
		draw_circle(Vector2(x + sin(float(i)) * 3.0 * s, -30 * s), 6.0 * s, Color(1.0, 0.36, 0.12, 0.9))
		draw_circle(Vector2(x + sin(float(i)) * 3.0 * s, -31 * s), 3.0 * s, Color(1.0, 0.82, 0.30))
	draw_circle(Vector2(0, -20 * s), 22.0 * s, Color(1.0, 0.40, 0.12, 0.10))


func _draw_obsidian(s: float, _rng: RandomNumberGenerator) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16 * s, 0), Vector2(-10 * s, -64 * s), Vector2(2 * s, -82 * s),
		Vector2(14 * s, -56 * s), Vector2(18 * s, 0)
	]), Color(0.14, 0.11, 0.16))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8 * s, -12 * s), Vector2(-5 * s, -58 * s), Vector2(0, -74 * s), Vector2(2 * s, -20 * s)
	]), Color(0.30, 0.24, 0.38))
	draw_line(Vector2(-2 * s, -16 * s), Vector2(3 * s, -52 * s), Color(1.0, 0.42, 0.16, 0.7), 1.6 * s, true)


func _draw_cloud_bush(s: float, rng: RandomNumberGenerator) -> void:
	for i in 5:
		var x := (-28.0 + float(i) * 14.0) * s
		var y := (-12.0 - float(i % 3) * 9.0) * s
		draw_circle(Vector2(x, y), (15.0 + float(i % 2) * 6.0) * s, Color(0.84, 0.92, 1.0, 0.95))
	for i in 4:
		var x := (-18.0 + float(i) * 13.0) * s
		draw_circle(Vector2(x, -18 * s), (11.0 + float(i % 2) * 4.0) * s, Color(0.97, 0.99, 1.0))
	for i in 2:
		draw_circle(Vector2(rng.randf_range(-24.0, 24.0) * s, rng.randf_range(-26.0, -10.0) * s), 2.4 * s, Color(1.0, 0.90, 0.56, 0.9))


func _draw_star_flower(s: float, rng: RandomNumberGenerator) -> void:
	for i in 5:
		var x := (-20.0 + float(i) * 10.0 + rng.randf_range(-2.0, 2.0)) * s
		var height := rng.randf_range(16.0, 30.0) * s
		draw_line(Vector2(x, 0), Vector2(x, -height), Color(0.36, 0.60, 0.42), 2.0 * s, true)
		var center := Vector2(x, -height)
		for k in 5:
			var angle := TAU * float(k) / 5.0 - PI * 0.5
			draw_line(center, center + Vector2(cos(angle), sin(angle)) * 6.0 * s, Color(1.0, 0.92, 0.62), 2.0 * s, true)
		draw_circle(center, 2.4 * s, Color(1.0, 0.98, 0.82))


func _draw_floating_rock(s: float, rng: RandomNumberGenerator) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-28 * s, -18 * s), Vector2(-16 * s, -38 * s), Vector2(8 * s, -42 * s),
		Vector2(27 * s, -24 * s), Vector2(20 * s, -8 * s), Vector2(-10 * s, -4 * s)
	]), Color(0.45, 0.48, 0.55))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16 * s, -36 * s), Vector2(6 * s, -40 * s), Vector2(23 * s, -23 * s), Vector2(-4 * s, -18 * s)
	]), Color(0.62, 0.66, 0.72))
	for i in 3:
		draw_circle(Vector2(rng.randf_range(-14.0, 14.0) * s, -22 * s), 1.8 * s, Color(0.30, 0.32, 0.38, 0.6))
	draw_circle(Vector2(0, -14 * s), 20.0 * s, Color(0.72, 0.88, 1.0, 0.12))


func _draw_sign(s: float) -> void:
	var wood := Color(0.56, 0.34, 0.16)
	draw_rect(Rect2(-4 * s, -62 * s, 8 * s, 62 * s), Color(0.39, 0.22, 0.09))
	var board := Rect2(-37 * s, -70 * s, 74 * s, 30 * s)
	var box := StyleBoxFlat.new()
	box.bg_color = wood
	box.border_color = Color(0.31, 0.16, 0.05)
	box.set_border_width_all(3)
	box.set_corner_radius_all(6)
	draw_style_box(box, board)
	# Painted arrow pointing right.
	var arrow := Color(1.0, 0.91, 0.62)
	draw_line(Vector2(-20 * s, -55 * s), Vector2(12 * s, -55 * s), arrow, 4.0 * s, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(10 * s, -62 * s), Vector2(23 * s, -55 * s), Vector2(10 * s, -48 * s)
	]), arrow)
	draw_circle(Vector2(-2 * s, -55 * s), 2.0 * s, wood.darkened(0.3))
