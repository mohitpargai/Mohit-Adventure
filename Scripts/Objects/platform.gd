## Reusable solid platform with procedural artwork for all six worlds.
## Styles: 0 grass, 1 stone, 2 wood, 3 ice, 4 sand, 5 dark stone,
## 6 lava basalt, 7 cloud.
extends StaticBody2D

@export var size := Vector2(320.0, 64.0)
@export var style := 0
@export var seed_value := 12345

var _collision: CollisionShape2D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	_ensure_collision()
	queue_redraw()


func setup(new_size: Vector2, new_style: int = 0, new_seed: int = 12345) -> void:
	size = new_size
	style = new_style
	seed_value = new_seed
	if is_inside_tree():
		_ensure_collision()
	queue_redraw()


func _ensure_collision() -> void:
	if _collision == null:
		_collision = CollisionShape2D.new()
		_collision.name = "CollisionShape2D"
		add_child(_collision)
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	_collision.shape = rectangle


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	match style:
		1:
			_draw_stone(rect, rng)
		2:
			_draw_wood(rect, rng)
		3:
			_draw_ice(rect, rng)
		4:
			_draw_sand(rect, rng)
		5:
			_draw_dark_stone(rect, rng)
		6:
			_draw_lava(rect, rng)
		7:
			_draw_cloud(rect, rng)
		_:
			_draw_grass(rect, rng)


func _draw_grass(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var dirt := StyleBoxFlat.new()
	dirt.bg_color = Color(0.39, 0.23, 0.12)
	dirt.border_color = Color(0.28, 0.15, 0.07)
	dirt.set_border_width_all(0)
	dirt.set_corner_radius_all(13)
	draw_style_box(dirt, rect)

	var under := Rect2(rect.position + Vector2(10, rect.size.y * 0.48), Vector2(rect.size.x - 20.0, rect.size.y * 0.44))
	var under_box := StyleBoxFlat.new()
	under_box.bg_color = Color(0.31, 0.17, 0.09, 0.65)
	under_box.set_corner_radius_all(9)
	draw_style_box(under_box, under)

	var grass_band := Rect2(rect.position + Vector2(0, 0), Vector2(rect.size.x, minf(21.0, rect.size.y)))
	var grass := StyleBoxFlat.new()
	grass.bg_color = Color(0.28, 0.68, 0.28)
	grass.set_corner_radius_all(13)
	grass.corner_radius_bottom_left = 4
	grass.corner_radius_bottom_right = 4
	draw_style_box(grass, grass_band)
	draw_rect(Rect2(rect.position + Vector2(8, 5), Vector2(rect.size.x - 16.0, 5.0)), Color(0.61, 0.87, 0.36, 0.75))

	# Grass blades, tiny flowers and pebbles.
	var blade_count := maxi(4, int(rect.size.x / 29.0))
	for i in blade_count:
		var x := rect.position.x + rng.randf_range(8.0, rect.size.x - 8.0)
		var blade_height := rng.randf_range(5.0, 15.0)
		var sway := rng.randf_range(-4.0, 4.0)
		var green := Color(0.18, 0.52, 0.22).lerp(Color(0.45, 0.82, 0.32), rng.randf())
		draw_line(Vector2(x, rect.position.y + 3.0), Vector2(x + sway, rect.position.y - blade_height), green, 2.2, true)
		if i % 7 == 3:
			var petal_color: Color = [Color(1.0, 0.84, 0.32), Color(1.0, 0.52, 0.62), Color(0.72, 0.72, 1.0)][i % 3]
			var flower_pos := Vector2(x, rect.position.y - blade_height - 1.0)
			for petal in 4:
				var angle := TAU * float(petal) / 4.0
				draw_circle(flower_pos + Vector2(cos(angle), sin(angle)) * 2.7, 2.3, petal_color)
			draw_circle(flower_pos, 1.7, Color(1.0, 0.95, 0.65))

	for i in maxi(2, int(rect.size.x / 110.0)):
		var pebble := Vector2(
			rect.position.x + rng.randf_range(20.0, rect.size.x - 20.0),
			rect.position.y + rng.randf_range(rect.size.y * 0.35, rect.size.y - 10.0)
		)
		draw_circle(pebble, rng.randf_range(2.5, 5.0), Color(0.25, 0.15, 0.10, 0.5))

	# Soft top highlight.
	draw_line(rect.position + Vector2(14, 1.4), Vector2(rect.position.x + rect.size.x - 14.0, rect.position.y + 1.4), Color(0.78, 0.96, 0.52, 0.65), 2.4, true)


func _draw_stone(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var stone := StyleBoxFlat.new()
	stone.bg_color = Color(0.38, 0.43, 0.45)
	stone.set_corner_radius_all(12)
	draw_style_box(stone, rect)
	draw_rect(Rect2(rect.position + Vector2(7, 7), Vector2(rect.size.x - 14.0, 6.0)), Color(0.62, 0.68, 0.69, 0.45))
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 16.0), Vector2(rect.size.x, 14.0)), Color(0.27, 0.31, 0.33, 0.7))

	for i in maxi(4, int(rect.size.x / 48.0)):
		var x := rect.position.x + rng.randf_range(14.0, rect.size.x - 14.0)
		var y := rect.position.y + rng.randf_range(12.0, rect.size.y - 12.0)
		var crack := PackedVector2Array([
			Vector2(x, y),
			Vector2(x + rng.randf_range(-7.0, 8.0), y + 6.0),
			Vector2(x + rng.randf_range(-10.0, 10.0), y + 13.0),
		])
		draw_polyline(crack, Color(0.22, 0.25, 0.26, 0.55), 1.6, true)

	# Mossy top.
	var moss := Rect2(rect.position + Vector2(4, 0), Vector2(rect.size.x - 8.0, 10.0))
	var moss_box := StyleBoxFlat.new()
	moss_box.bg_color = Color(0.34, 0.55, 0.31, 0.8)
	moss_box.set_corner_radius_all(8)
	draw_style_box(moss_box, moss)
	for i in maxi(3, int(rect.size.x / 55.0)):
		var x := rect.position.x + rng.randf_range(10.0, rect.size.x - 10.0)
		draw_circle(Vector2(x, rect.position.y + 9.0), rng.randf_range(3.0, 6.0), Color(0.47, 0.70, 0.36, 0.6))


func _draw_wood(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var wood := StyleBoxFlat.new()
	wood.bg_color = Color(0.58, 0.35, 0.17)
	wood.border_color = Color(0.34, 0.18, 0.07)
	wood.set_border_width_all(3)
	wood.set_corner_radius_all(8)
	draw_style_box(wood, rect)
	for i in maxi(2, int(rect.size.y / 18.0)):
		var y := rect.position.y + 12.0 + float(i) * 18.0
		draw_line(Vector2(rect.position.x + 7.0, y), Vector2(rect.end.x - 7.0, y), Color(0.39, 0.21, 0.09, 0.55), 1.6)
	for i in maxi(2, int(rect.size.x / 120.0)):
		var nail := Vector2(rect.position.x + rng.randf_range(18.0, rect.size.x - 18.0), rect.position.y + 7.0)
		draw_circle(nail, 2.6, Color(0.30, 0.30, 0.32))
		draw_circle(nail + Vector2(-0.5, -0.5), 1.0, Color(0.75, 0.76, 0.78))


func _draw_ice(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = Color(0.55, 0.78, 0.94)
	base.border_color = Color(0.31, 0.54, 0.75)
	base.set_border_width_all(2)
	base.set_corner_radius_all(12)
	draw_style_box(base, rect)
	draw_rect(
		Rect2(rect.position + Vector2(6, 4), Vector2(rect.size.x - 12.0, 9.0)),
		Color(0.90, 0.98, 1.0, 0.72)
	)
	# Icicles hanging under floating ice.
	if rect.size.y < 70.0:
		var count := maxi(3, int(rect.size.x / 60.0))
		for i in count:
			var x := rect.position.x + rng.randf_range(14.0, rect.size.x - 14.0)
			var length := rng.randf_range(10.0, 26.0)
			draw_colored_polygon(PackedVector2Array([
				Vector2(x - 7.0, rect.end.y), Vector2(x + 7.0, rect.end.y), Vector2(x, rect.end.y + length)
			]), Color(0.72, 0.90, 1.0, 0.78))
	# Cracks and sparkles.
	for i in maxi(3, int(rect.size.x / 70.0)):
		var x := rect.position.x + rng.randf_range(16.0, rect.size.x - 16.0)
		var y := rect.position.y + rng.randf_range(16.0, maxf(18.0, rect.size.y - 10.0))
		draw_line(Vector2(x, y), Vector2(x + rng.randf_range(8.0, 24.0), y + rng.randf_range(4.0, 13.0)), Color(0.83, 0.95, 1.0, 0.6), 1.4, true)
		if i % 3 == 0:
			draw_circle(Vector2(x, y - 6.0), 1.8, Color(1, 1, 1, 0.85))
	draw_line(rect.position + Vector2(14, 1.2), Vector2(rect.end.x - 14.0, rect.position.y + 1.2), Color(0.94, 1.0, 1.0, 0.9), 2.2, true)


func _draw_sand(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = Color(0.80, 0.64, 0.35)
	base.border_color = Color(0.57, 0.42, 0.20)
	base.set_border_width_all(2)
	base.set_corner_radius_all(10)
	draw_style_box(base, rect)
	draw_rect(Rect2(rect.position + Vector2(0, 0), Vector2(rect.size.x, minf(16.0, rect.size.y))), Color(0.95, 0.82, 0.50))
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 14.0), Vector2(rect.size.x, 12.0)), Color(0.63, 0.46, 0.22, 0.65))
	for i in maxi(5, int(rect.size.x / 38.0)):
		var x := rect.position.x + rng.randf_range(8.0, rect.size.x - 8.0)
		var y := rect.position.y + rng.randf_range(12.0, rect.size.y - 8.0)
		draw_circle(Vector2(x, y), rng.randf_range(1.2, 2.8), Color(0.99, 0.91, 0.67, 0.75))
	# Carved temple lines on thick ground.
	if rect.size.y > 100.0:
		for i in maxi(2, int(rect.size.x / 170.0)):
			var x := rect.position.x + 28.0 + float(i) * 160.0
			draw_line(Vector2(x, rect.position.y + 34.0), Vector2(x + 80.0, rect.position.y + 34.0), Color(0.58, 0.42, 0.22, 0.4), 3.0)
			draw_line(Vector2(x + 40.0, rect.position.y + 26.0), Vector2(x + 40.0, rect.position.y + 44.0), Color(0.58, 0.42, 0.22, 0.4), 3.0)


func _draw_dark_stone(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = Color(0.24, 0.22, 0.31)
	base.border_color = Color(0.13, 0.11, 0.18)
	base.set_border_width_all(3)
	base.set_corner_radius_all(9)
	draw_style_box(base, rect)
	var top := Rect2(rect.position, Vector2(rect.size.x, minf(15.0, rect.size.y)))
	draw_rect(top, Color(0.36, 0.32, 0.46))
	# Brick pattern.
	var row_h := 26.0
	for row in maxi(1, int(rect.size.y / row_h)):
		var y := rect.position.y + float(row) * row_h + 14.0
		if y > rect.end.y - 6.0:
			break
		draw_line(Vector2(rect.position.x + 4.0, y), Vector2(rect.end.x - 4.0, y), Color(0.11, 0.09, 0.16, 0.8), 2.0)
		var offset := 0.0 if row % 2 == 0 else 44.0
		var x := rect.position.x + 24.0 + offset
		while x < rect.end.x - 10.0:
			draw_line(Vector2(x, y), Vector2(x, y + row_h), Color(0.11, 0.09, 0.16, 0.7), 2.0)
			x += 88.0
	# Eerie glowing runes.
	for i in maxi(2, int(rect.size.x / 140.0)):
		var x := rect.position.x + rng.randf_range(28.0, maxf(30.0, rect.size.x - 28.0))
		draw_circle(Vector2(x, rect.position.y + 22.0), 3.5, Color(0.72, 0.52, 1.0, 0.85))
		draw_circle(Vector2(x, rect.position.y + 22.0), 8.0, Color(0.62, 0.42, 1.0, 0.18))


func _draw_lava(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = Color(0.22, 0.16, 0.16)
	base.border_color = Color(0.12, 0.07, 0.07)
	base.set_border_width_all(3)
	base.set_corner_radius_all(8)
	draw_style_box(base, rect)
	var glow_top := Rect2(rect.position, Vector2(rect.size.x, minf(13.0, rect.size.y)))
	draw_rect(glow_top, Color(0.98, 0.42, 0.14))
	draw_line(rect.position + Vector2(8, 2.0), Vector2(rect.end.x - 8.0, rect.position.y + 2.0), Color(1.0, 0.82, 0.36, 0.9), 3.0, true)
	for i in maxi(3, int(rect.size.x / 62.0)):
		var x := rect.position.x + rng.randf_range(10.0, rect.size.x - 10.0)
		var y := rect.position.y + rng.randf_range(20.0, maxf(22.0, rect.size.y - 8.0))
		var crack := PackedVector2Array([
			Vector2(x, y), Vector2(x + rng.randf_range(-6.0, 7.0), y + 9.0),
			Vector2(x + rng.randf_range(-11.0, 12.0), y + 18.0),
		])
		draw_polyline(crack, Color(1.0, 0.45, 0.12, 0.85), 2.2, true)
	for i in maxi(2, int(rect.size.x / 90.0)):
		var x := rect.position.x + rng.randf_range(12.0, rect.size.x - 12.0)
		draw_circle(Vector2(x, rect.position.y + 5.0), rng.randf_range(2.0, 4.5), Color(1.0, 0.88, 0.48, 0.9))


func _draw_cloud(rect: Rect2, rng: RandomNumberGenerator) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = Color(0.90, 0.95, 1.0, 0.96)
	base.border_color = Color(0.73, 0.85, 1.0, 0.9)
	base.set_border_width_all(2)
	base.set_corner_radius_all(18)
	draw_style_box(base, rect)
	var puffs := maxi(3, int(rect.size.x / 56.0))
	for i in puffs:
		var x := rect.position.x + 18.0 + float(i) * (rect.size.x - 36.0) / float(puffs)
		var radius := rng.randf_range(13.0, 23.0)
		draw_circle(Vector2(x, rect.position.y + 2.0), radius, Color(0.97, 0.99, 1.0, 0.95))
		draw_circle(Vector2(x, rect.end.y - 4.0), radius * 0.8, Color(0.84, 0.92, 1.0, 0.8))
	draw_line(rect.position + Vector2(14, 2.0), Vector2(rect.end.x - 14.0, rect.position.y + 2.0), Color(1, 1, 1, 0.95), 2.4, true)
	# Tiny golden sparkles on sky platforms.
	for i in maxi(1, int(rect.size.x / 130.0)):
		var x := rect.position.x + rng.randf_range(18.0, rect.size.x - 18.0)
		draw_circle(Vector2(x, rect.position.y + 12.0), 2.0, Color(1.0, 0.90, 0.52, 0.75))
