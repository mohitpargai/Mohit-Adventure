## Screen-space procedural forest backdrop with parallax layers.
## No image assets are required: everything is drawn with primitive shapes.
extends Control

@export var variant := 0
@export var menu_mode := false

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func set_variant(index: int) -> void:
	variant = clampi(index, 0, 7)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 2.0 or h < 2.0:
		return

	var palette := _palette()
	var camera := get_viewport().get_camera_2d()
	var scroll := _time * 26.0 if camera == null else camera.global_position.x
	if menu_mode:
		scroll += _time * 10.0

	_draw_sky(w, h, palette)

	# Sun with soft layered glow.
	var sun_pos := Vector2(w * 0.79, h * 0.23)
	for i in range(7, 0, -1):
		var glow := Color(palette["sun"], 0.035 * i)
		draw_circle(sun_pos, 42.0 + i * 13.0, glow)
	draw_circle(sun_pos, 38.0, palette["sun"])
	draw_circle(sun_pos, 30.0, Color(1, 1, 1, 0.22))

	# Translucent sun rays.
	for i in 2:
		var skew := 120.0 + i * 170.0
		var ray := PackedVector2Array([
			sun_pos + Vector2(-20, 20),
			Vector2(w * 0.12 + skew, h + 20.0),
			Vector2(w * 0.27 + skew, h + 20.0),
		])
		draw_colored_polygon(ray, Color(1.0, 0.97, 0.78, 0.035))

	# Slow clouds.
	for i in 7:
		var cloud_x := fmod(float(i) * 430.0 + 120.0 - scroll * 0.045 + _time * 7.0, w + 480.0) - 240.0
		var cloud_y := h * (0.10 + float(i % 3) * 0.075)
		_draw_cloud(Vector2(cloud_x, cloud_y), 0.72 + float(i % 3) * 0.22, 0.62)

	# Distant scenery. The forest keeps its original hand-drawn layers; the
	# other five worlds get their own silhouettes.
	if variant <= 2:
		_draw_hills(scroll, h, w, h * 0.66, 55.0, 0.0018, palette["far"], 0.0)
		draw_rect(Rect2(0, h * 0.60, w, h * 0.16), Color(palette["mist"], 0.24))
		_draw_hills(scroll, h, w, h * 0.755, 72.0, 0.0026, palette["mid"], 1.3)
		_draw_far_tree_line(scroll, h, w, palette, 0)

		_draw_hills(scroll, h, w, h * 0.86, 46.0, 0.0034, palette["near"], 2.4)
		_draw_far_tree_line(scroll, h, w, palette, 1)

		# Big framing trees in the menu make the title screen feel like a forest.
		if menu_mode:
			_draw_big_tree(Vector2(w * 0.055, h * 1.04), h * 0.78, palette["dark"], 0.92)
			_draw_big_tree(Vector2(w * 0.955, h * 1.1), h * 0.92, palette["dark"], 0.88)
			_draw_big_tree(Vector2(w * 0.17, h * 1.14), h * 0.48, palette["near"], 0.62)

		# Foreground foliage band.
		for i in 9:
			var bush_x := fmod(float(i) * 173.0 - scroll * 0.42, w + 240.0) - 120.0
			var bush_y := h + 8.0 - float(i % 3) * 9.0
			draw_circle(Vector2(bush_x, bush_y), 44.0 + float(i % 4) * 11.0, Color(palette["dark"], 0.75))
			draw_circle(Vector2(bush_x + 36.0, bush_y + 12.0), 32.0, Color(palette["dark"], 0.65))
	else:
		_draw_theme_backdrop(scroll, h, w, palette)

	_draw_particles(scroll, h, w, palette)


func _draw_theme_backdrop(scroll: float, h: float, w: float, palette: Dictionary) -> void:
	match variant:
		3:
			_draw_hills(scroll, h, w, h * 0.66, 88.0, 0.0020, palette["far"], 0.0)
			_draw_hills(scroll, h, w, h * 0.775, 64.0, 0.0028, palette["mid"], 1.5)
			_draw_hills(scroll, h, w, h * 0.90, 42.0, 0.0036, palette["near"], 2.7)
			# Snow pines along the near ridge.
			for i in 16:
				var x := fmod(float(i) * 126.0 - scroll * 0.28, w + 220.0) - 110.0
				_draw_pine(Vector2(x, h * 0.92 + sin(float(i) * 1.7) * 6.0), 62.0 + float((i * 7) % 28), Color(0.76, 0.88, 0.96, 0.72))
			# Glinting ice spires.
			for i in 7:
				var x := fmod(float(i) * 233.0 - scroll * 0.18, w + 200.0) - 80.0
				var base_y := h * 0.86
				draw_colored_polygon(PackedVector2Array([
					Vector2(x - 22, base_y), Vector2(x, base_y - 74.0), Vector2(x + 20, base_y)
				]), Color(0.80, 0.93, 1.0, 0.35))
		4:
			_draw_hills(scroll, h, w, h * 0.68, 42.0, 0.0015, palette["far"], 0.0)
			_draw_hills(scroll, h, w, h * 0.79, 36.0, 0.0021, palette["mid"], 1.4)
			_draw_hills(scroll, h, w, h * 0.90, 34.0, 0.0029, palette["near"], 2.6)
			# Three pyramids on the horizon.
			for i in 3:
				var px := fmod(float(i) * 390.0 - scroll * 0.10 + 180.0, w + 520.0) - 260.0
				var py := h * 0.84
				var size := 130.0 + float(i % 2) * 52.0
				draw_colored_polygon(PackedVector2Array([
					Vector2(px - size, py), Vector2(px, py - size * 1.05), Vector2(px + size, py)
				]), Color(0.63, 0.44, 0.24, 0.85))
				draw_colored_polygon(PackedVector2Array([
					Vector2(px, py - size * 1.05), Vector2(px + size, py), Vector2(px + size * 0.20, py)
				]), Color(0.48, 0.32, 0.17, 0.9))
				draw_line(Vector2(px, py - size * 1.05), Vector2(px, py), Color(0.85, 0.66, 0.36, 0.35), 2.0, true)
			# Palm silhouettes in the foreground.
			for i in 6:
				var x := fmod(float(i) * 247.0 - scroll * 0.36, w + 260.0) - 130.0
				var y := h * 0.99
				draw_line(Vector2(x, y), Vector2(x + 10.0, y - 92.0), Color(0.24, 0.17, 0.11, 0.8), 6.0, true)
				for k in 5:
					var angle := -PI * 0.9 + PI * 0.8 * float(k) / 4.0
					draw_line(Vector2(x + 10.0, y - 92.0), Vector2(x + 10.0, y - 92.0) + Vector2(cos(angle), sin(angle)) * 44.0, Color(0.20, 0.30, 0.18, 0.75), 4.0, true)
		5:
			_draw_hills(scroll, h, w, h * 0.70, 58.0, 0.0022, palette["far"], 0.0)
			# Castle silhouette with lit windows.
			var castle_x := fmod(w * 0.18 - scroll * 0.10, w + 660.0) - 220.0
			var base_y := h * 0.80
			draw_rect(Rect2(castle_x, base_y - 150.0, 300.0, 190.0), Color(0.12, 0.09, 0.17, 0.95))
			for tower in 3:
				var tx := castle_x + 20.0 + float(tower) * 108.0
				var th := 110.0 + float(tower % 2) * 58.0
				draw_rect(Rect2(tx, base_y - 150.0 - th, 58.0, th + 40.0), Color(0.10, 0.08, 0.15, 0.98))
				draw_colored_polygon(PackedVector2Array([
					Vector2(tx - 8.0, base_y - 150.0 - th), Vector2(tx + 29.0, base_y - 202.0 - th), Vector2(tx + 66.0, base_y - 150.0 - th)
				]), Color(0.08, 0.06, 0.12, 1.0))
				for win in 3:
					draw_rect(Rect2(tx + 22.0, base_y - 120.0 - th + float(win) * 34.0, 11.0, 16.0), Color(0.78, 0.52, 1.0, 0.55))
			# Dead trees.
			for i in 10:
				var x := fmod(float(i) * 181.0 - scroll * 0.32, w + 220.0) - 110.0
				var y := h * 0.95
				draw_line(Vector2(x, y), Vector2(x + 6.0, y - 86.0), Color(0.09, 0.07, 0.12, 0.85), 5.0, true)
				draw_line(Vector2(x + 5.0, y - 64.0), Vector2(x - 24.0, y - 102.0), Color(0.09, 0.07, 0.12, 0.85), 3.0, true)
				draw_line(Vector2(x + 5.0, y - 72.0), Vector2(x + 33.0, y - 112.0), Color(0.09, 0.07, 0.12, 0.85), 3.0, true)
		6:
			_draw_hills(scroll, h, w, h * 0.70, 72.0, 0.0020, palette["far"], 0.0)
			# Volcano cone.
			var vx := fmod(w * 0.72 - scroll * 0.08, w + 700.0) - 260.0
			var vy := h * 0.86
			draw_colored_polygon(PackedVector2Array([
				Vector2(vx - 240.0, vy), Vector2(vx - 40.0, vy - 300.0), Vector2(vx + 30.0, vy - 300.0), Vector2(vx + 260.0, vy)
			]), Color(0.24, 0.12, 0.12, 0.95))
			draw_colored_polygon(PackedVector2Array([
				Vector2(vx - 58.0, vy - 274.0), Vector2(vx - 20.0, vy - 190.0), Vector2(vx + 8.0, vy - 260.0)
			]), Color(1.0, 0.42, 0.12, 0.75))
			draw_circle(Vector2(vx - 6.0, vy - 292.0), 74.0, Color(1.0, 0.40, 0.10, 0.12))
			_draw_hills(scroll, h, w, h * 0.90, 44.0, 0.0031, palette["near"], 2.5)
			# Glowing lava river at the bottom edge.
			draw_rect(Rect2(0, h - 34.0, w, 40.0), Color(1.0, 0.34, 0.08, 0.30))
			draw_rect(Rect2(0, h - 12.0, w, 18.0), Color(1.0, 0.55, 0.12, 0.55))
		7:
			# Cloud sea and drifting islands.
			for i in 5:
				var y := h * (0.60 + float(i) * 0.075)
				_draw_cloud(Vector2(fmod(float(i) * 360.0 - scroll * (0.05 + float(i) * 0.01), w + 500.0) - 250.0, y), 1.4 + float(i % 3) * 0.3, 0.48)
			for i in 5:
				var ix := fmod(float(i) * 331.0 - scroll * (0.13 + float(i) * 0.02) + 120.0, w + 420.0) - 210.0
				var iy := h * (0.42 + float(i % 3) * 0.13)
				var iw := 130.0 + float(i % 3) * 45.0
				draw_colored_polygon(PackedVector2Array([
					Vector2(ix - iw, iy), Vector2(ix - iw * 0.45, iy + 34.0),
					Vector2(ix + iw * 0.2, iy + 48.0), Vector2(ix + iw, iy + 10.0),
					Vector2(ix + iw * 0.4, iy - 18.0), Vector2(ix - iw * 0.5, iy - 14.0)
				]), Color(0.36, 0.56, 0.52, 0.82))
				draw_rect(Rect2(ix - iw, iy, iw * 2.0, 10.0), Color(0.52, 0.74, 0.50, 0.9))
				_draw_cloud(Vector2(ix, iy + 8.0), 0.5, 0.55)
			# Distant sky castle.
			var sx := fmod(w * 0.30 - scroll * 0.07, w + 520.0) - 180.0
			draw_rect(Rect2(sx, h * 0.46, 120.0, 90.0), Color(0.70, 0.82, 0.95, 0.55))
			draw_colored_polygon(PackedVector2Array([
				Vector2(sx - 18.0, h * 0.46), Vector2(sx + 60.0, h * 0.36), Vector2(sx + 138.0, h * 0.46)
			]), Color(0.62, 0.76, 0.92, 0.6))
			for i in 3:
				draw_rect(Rect2(sx + 20.0 + float(i) * 34.0, h * 0.48, 10.0, 18.0), Color(1.0, 0.92, 0.60, 0.65))


func _draw_particles(scroll: float, h: float, w: float, palette: Dictionary) -> void:
	if variant <= 2:
		# Floating pollen / fireflies.
		for i in 20:
			var px := fmod(float(i) * 127.3 + _time * (8.0 + float(i % 4) * 3.0) - scroll * 0.03, w + 40.0) - 20.0
			var py := h * 0.16 + fmod(float(i) * 71.7, h * 0.62) + sin(_time * 0.8 + float(i) * 1.7) * 10.0
			var radius := 1.6 + float(i % 3) * 0.8
			var glow_alpha := 0.28 + 0.18 * sin(_time * 1.4 + float(i))
			draw_circle(Vector2(px, py), radius + 2.0, Color(palette["accent"], glow_alpha * 0.4))
			draw_circle(Vector2(px, py), radius, Color(1, 1, 0.86, glow_alpha))
		return
	match variant:
		3:
			for i in 34:
				var px := fmod(float(i) * 113.0 + sin(_time * 0.6 + float(i)) * 22.0 - scroll * 0.05, w + 40.0) - 20.0
				var py := fmod(float(i) * 67.0 + _time * (22.0 + float(i % 5) * 6.0), h + 40.0) - 20.0
				draw_circle(Vector2(px, py), 1.8 + float(i % 3) * 1.1, Color(1, 1, 1, 0.55))
		4:
			for i in 24:
				var px := fmod(float(i) * 149.0 + _time * (40.0 + float(i % 4) * 12.0) - scroll * 0.04, w + 120.0) - 60.0
				var py := h * (0.22 + fmod(float(i) * 0.077, 0.68)) + sin(_time + float(i)) * 8.0
				draw_line(Vector2(px, py), Vector2(px - 18.0, py + 2.0), Color(0.98, 0.86, 0.60, 0.22), 1.5, true)
		5:
			for i in 18:
				var px := fmod(float(i) * 157.0 + sin(_time * 0.5 + float(i)) * 30.0 - scroll * 0.04, w + 40.0) - 20.0
				var py := h * 0.18 + fmod(float(i) * 83.0, h * 0.64) + sin(_time * 0.9 + float(i)) * 12.0
				draw_circle(Vector2(px, py), 3.8, Color(0.70, 0.42, 1.0, 0.12))
				draw_circle(Vector2(px, py), 1.6, Color(0.86, 0.68, 1.0, 0.72))
		6:
			for i in 26:
				var px := fmod(float(i) * 137.0 + sin(_time * 0.8 + float(i)) * 18.0 - scroll * 0.04, w + 40.0) - 20.0
				var py := h - fmod(float(i) * 74.0 + _time * (34.0 + float(i % 4) * 10.0), h * 0.86)
				draw_circle(Vector2(px, py), 2.4 + float(i % 3), Color(1.0, 0.48, 0.12, 0.28))
				draw_circle(Vector2(px, py), 1.2, Color(1.0, 0.86, 0.38, 0.85))
		7:
			for i in 22:
				var px := fmod(float(i) * 141.0 + _time * (12.0 + float(i % 4) * 4.0) - scroll * 0.03, w + 40.0) - 20.0
				var py := h * 0.14 + fmod(float(i) * 79.0, h * 0.60) + sin(_time * 0.7 + float(i)) * 9.0
				var glow := 0.35 + 0.25 * sin(_time * 1.6 + float(i))
				draw_circle(Vector2(px, py), 4.0, Color(1.0, 0.94, 0.68, glow * 0.25))
				draw_circle(Vector2(px, py), 1.4, Color(1, 1, 0.92, glow + 0.2))


func _draw_sky(w: float, h: float, palette: Dictionary) -> void:
	var bands := 32
	var band_height := h / float(bands)
	for i in bands:
		var t := float(i) / float(bands - 1)
		var color: Color = Color(palette["sky_top"]).lerp(Color(palette["sky_bottom"]), pow(t, 0.82))
		draw_rect(Rect2(0.0, float(i) * band_height, w, band_height + 1.0), color)


func _draw_cloud(center: Vector2, cloud_scale: float, alpha: float) -> void:
	var color := Color(1.0, 1.0, 1.0, alpha * 0.75)
	draw_circle(center + Vector2(-46, 6) * cloud_scale, 28.0 * cloud_scale, color)
	draw_circle(center + Vector2(-12, -6) * cloud_scale, 38.0 * cloud_scale, color)
	draw_circle(center + Vector2(28, 2) * cloud_scale, 31.0 * cloud_scale, color)
	draw_circle(center + Vector2(58, 10) * cloud_scale, 22.0 * cloud_scale, color)
	draw_rect(Rect2(center + Vector2(-62, 8) * cloud_scale, Vector2(120, 22) * cloud_scale), Color(color, color.a * 0.85))


func _draw_hills(scroll: float, h: float, w: float, base_y: float, amplitude: float, frequency: float, color: Color, phase: float) -> void:
	var points := PackedVector2Array()
	points.append(Vector2(-60.0, h + 40.0))
	var offset := scroll * (0.07 + phase * 0.018)
	var x := -60.0
	while x <= w + 80.0:
		var y := base_y - (
			sin((x + offset) * frequency + phase) * amplitude
			+ sin((x + offset) * frequency * 2.4 + phase * 1.7) * amplitude * 0.32
			+ amplitude * 0.45
		)
		points.append(Vector2(x, y))
		x += 44.0
	points.append(Vector2(w + 80.0, h + 40.0))
	draw_colored_polygon(points, color)


func _draw_far_tree_line(scroll: float, h: float, w: float, palette: Dictionary, layer: int) -> void:
	var count := 15 + layer * 4
	var base_y := h * (0.72 if layer == 0 else 0.83)
	var color: Color = Color(palette["dark"], 0.55 if layer == 0 else 0.82)
	for i in count:
		var spacing := 118.0 - layer * 12.0
		var x := fmod(float(i) * spacing - scroll * (0.16 + layer * 0.12), w + spacing * 2.0) - spacing
		var tree_height := (48.0 + float((i * 13 + layer * 7) % 42)) * (0.8 + layer * 0.28)
		_draw_pine(Vector2(x, base_y + sin(float(i) * 2.4) * 8.0), tree_height, color)
		if i % 3 == 0:
			_draw_round_tree(Vector2(x + spacing * 0.5, base_y + 4.0), tree_height * 0.72, color)


func _draw_pine(base: Vector2, tree_height: float, color: Color) -> void:
	var width := tree_height * 0.48
	draw_rect(Rect2(base.x - 3.0, base.y - tree_height * 0.36, 6.0, tree_height * 0.36), Color(color.darkened(0.2), color.a))
	var top := base.y - tree_height
	for i in 3:
		var level_y := base.y - tree_height * (0.28 + float(i) * 0.2)
		var level_w := width * (1.0 - float(i) * 0.22)
		var triangle := PackedVector2Array([
			Vector2(base.x, top + float(i) * tree_height * 0.18),
			Vector2(base.x - level_w, level_y),
			Vector2(base.x + level_w, level_y),
		])
		draw_colored_polygon(triangle, color)


func _draw_round_tree(base: Vector2, tree_height: float, color: Color) -> void:
	var trunk_color := Color(color.darkened(0.22), color.a)
	draw_rect(Rect2(base.x - 3.0, base.y - tree_height * 0.5, 6.0, tree_height * 0.5), trunk_color)
	draw_circle(Vector2(base.x, base.y - tree_height * 0.64), tree_height * 0.28, color)
	draw_circle(Vector2(base.x - tree_height * 0.18, base.y - tree_height * 0.5), tree_height * 0.22, color)
	draw_circle(Vector2(base.x + tree_height * 0.2, base.y - tree_height * 0.52), tree_height * 0.24, color)


func _draw_big_tree(base: Vector2, tree_height: float, color: Color, alpha: float) -> void:
	var body_color := Color(color, alpha)
	var trunk_color := Color(color.darkened(0.35), alpha)
	draw_rect(Rect2(base.x - tree_height * 0.055, base.y - tree_height * 0.72, tree_height * 0.11, tree_height * 0.72), trunk_color)
	# Exposed roots.
	draw_circle(base + Vector2(-tree_height * 0.08, 3.0), tree_height * 0.075, trunk_color)
	draw_circle(base + Vector2(tree_height * 0.09, 2.0), tree_height * 0.065, trunk_color)
	# Lumpy canopy.
	draw_circle(base + Vector2(0, -tree_height * 0.80), tree_height * 0.20, body_color)
	draw_circle(base + Vector2(-tree_height * 0.20, -tree_height * 0.68), tree_height * 0.18, body_color)
	draw_circle(base + Vector2(tree_height * 0.21, -tree_height * 0.67), tree_height * 0.19, body_color)
	draw_circle(base + Vector2(-tree_height * 0.10, -tree_height * 0.94), tree_height * 0.16, body_color)
	draw_circle(base + Vector2(tree_height * 0.12, -tree_height * 0.92), tree_height * 0.15, body_color)
	draw_circle(base + Vector2(0, -tree_height * 1.04), tree_height * 0.12, body_color)


func _palette() -> Dictionary:
	match variant:
		1:
			return {
				"sky_top": Color(0.29, 0.38, 0.68),
				"sky_bottom": Color(0.98, 0.84, 0.71),
				"sun": Color(1.0, 0.88, 0.66, 0.95),
				"far": Color(0.46, 0.48, 0.67),
				"mist": Color(0.91, 0.79, 0.77),
				"mid": Color(0.27, 0.47, 0.44),
				"near": Color(0.16, 0.34, 0.30),
				"dark": Color(0.08, 0.21, 0.19),
				"accent": Color(0.86, 0.74, 1.0),
			}
		2:
			return {
				"sky_top": Color(0.85, 0.38, 0.34),
				"sky_bottom": Color(1.0, 0.82, 0.58),
				"sun": Color(1.0, 0.94, 0.72, 0.96),
				"far": Color(0.59, 0.43, 0.51),
				"mist": Color(1.0, 0.76, 0.57),
				"mid": Color(0.33, 0.43, 0.31),
				"near": Color(0.17, 0.31, 0.21),
				"dark": Color(0.09, 0.19, 0.13),
				"accent": Color(1.0, 0.83, 0.42),
			}
		3:
			return {
				"sky_top": Color(0.33, 0.53, 0.78),
				"sky_bottom": Color(0.82, 0.92, 0.99),
				"sun": Color(0.92, 0.97, 1.0, 0.95),
				"far": Color(0.66, 0.80, 0.93),
				"mist": Color(0.85, 0.94, 1.0),
				"mid": Color(0.52, 0.70, 0.86),
				"near": Color(0.36, 0.56, 0.72),
				"dark": Color(0.20, 0.34, 0.48),
				"accent": Color(0.78, 0.94, 1.0),
			}
		4:
			return {
				"sky_top": Color(0.92, 0.62, 0.29),
				"sky_bottom": Color(1.0, 0.89, 0.62),
				"sun": Color(1.0, 0.93, 0.64, 1.0),
				"far": Color(0.84, 0.62, 0.35),
				"mist": Color(1.0, 0.85, 0.58),
				"mid": Color(0.70, 0.49, 0.26),
				"near": Color(0.52, 0.35, 0.18),
				"dark": Color(0.35, 0.23, 0.13),
				"accent": Color(1.0, 0.86, 0.45),
			}
		5:
			return {
				"sky_top": Color(0.055, 0.04, 0.12),
				"sky_bottom": Color(0.24, 0.15, 0.34),
				"sun": Color(0.82, 0.84, 1.0, 0.82),
				"far": Color(0.22, 0.17, 0.31),
				"mist": Color(0.30, 0.22, 0.42),
				"mid": Color(0.15, 0.12, 0.23),
				"near": Color(0.09, 0.07, 0.15),
				"dark": Color(0.04, 0.03, 0.08),
				"accent": Color(0.76, 0.56, 1.0),
			}
		6:
			return {
				"sky_top": Color(0.32, 0.07, 0.09),
				"sky_bottom": Color(0.92, 0.38, 0.13),
				"sun": Color(1.0, 0.58, 0.22, 0.95),
				"far": Color(0.42, 0.13, 0.12),
				"mist": Color(0.78, 0.28, 0.12),
				"mid": Color(0.26, 0.10, 0.10),
				"near": Color(0.15, 0.06, 0.07),
				"dark": Color(0.07, 0.03, 0.04),
				"accent": Color(1.0, 0.66, 0.24),
			}
		7:
			return {
				"sky_top": Color(0.28, 0.60, 0.92),
				"sky_bottom": Color(0.78, 0.92, 1.0),
				"sun": Color(1.0, 0.95, 0.72, 0.98),
				"far": Color(0.56, 0.74, 0.94),
				"mist": Color(0.80, 0.92, 1.0),
				"mid": Color(0.44, 0.64, 0.88),
				"near": Color(0.30, 0.50, 0.76),
				"dark": Color(0.16, 0.30, 0.52),
				"accent": Color(1.0, 0.94, 0.62),
			}
		_:
			return {
				"sky_top": Color(0.33, 0.75, 0.96),
				"sky_bottom": Color(0.82, 0.96, 0.84),
				"sun": Color(1.0, 0.95, 0.68, 0.98),
				"far": Color(0.56, 0.76, 0.67),
				"mist": Color(0.80, 0.94, 0.85),
				"mid": Color(0.31, 0.61, 0.42),
				"near": Color(0.17, 0.43, 0.28),
				"dark": Color(0.07, 0.23, 0.15),
				"accent": Color(0.95, 1.0, 0.73),
			}
