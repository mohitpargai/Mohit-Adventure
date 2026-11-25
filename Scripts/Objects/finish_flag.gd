## Goal flag at the end of each level.
extends Area2D

signal reached

var _time := 0.0
var _triggered := false
var _collision: CollisionShape2D


func _ready() -> void:
	add_to_group("finish_flags")
	collision_layer = 32
	collision_mask = 1
	_ensure_collision()
	body_entered.connect(_on_body_entered)


func _ensure_collision() -> void:
	if _collision == null:
		_collision = CollisionShape2D.new()
		_collision.name = "CollisionShape2D"
		add_child(_collision)
	var rect := RectangleShape2D.new()
	rect.size = Vector2(76.0, 196.0)
	_collision.shape = rect
	_collision.position = Vector2(0, -98.0)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	# Deferred: changing monitoring inside a physics signal is not allowed.
	set_deferred("monitoring", false)
	AudioManager.play_sfx("win")
	reached.emit()


func _draw() -> void:
	var wave := sin(_time * 3.2) * 5.0
	var wave2 := sin(_time * 3.2 + 1.1) * 7.0

	# Warm goal glow.
	for i in 4:
		draw_circle(Vector2(24, -142), 38.0 + i * 12.0, Color(1.0, 0.86, 0.38, 0.035))

	# Stone base.
	draw_circle(Vector2(-15, -2), 12.0, Color(0.36, 0.40, 0.39))
	draw_circle(Vector2(13, -2), 10.0, Color(0.42, 0.46, 0.44))
	draw_circle(Vector2(0, -6), 15.0, Color(0.47, 0.51, 0.48))
	draw_circle(Vector2(-4, -10), 10.0, Color(0.57, 0.61, 0.56))

	# Pole.
	var pole_x := 0.0
	draw_rect(Rect2(pole_x - 4.0, -206.0, 8.0, 202.0), Color(0.38, 0.24, 0.13))
	draw_rect(Rect2(pole_x - 4.0, -206.0, 3.0, 202.0), Color(0.62, 0.43, 0.25))
	draw_circle(Vector2(pole_x, -210), 8.0, Color(1.0, 0.80, 0.28))
	draw_circle(Vector2(pole_x - 2, -212), 3.0, Color(1.0, 0.96, 0.72))

	# Waving banner.
	draw_colored_polygon(PackedVector2Array([
		Vector2(4, -197),
		Vector2(96, -191 + wave),
		Vector2(84, -151 + wave2),
		Vector2(4, -158),
	]), Color(0.93, 0.34, 0.30))
	draw_colored_polygon(PackedVector2Array([
		Vector2(4, -158),
		Vector2(84, -151 + wave2),
		Vector2(78, -168 + wave),
		Vector2(4, -178),
	]), Color(0.99, 0.55, 0.34))
	draw_line(Vector2(4, -197), Vector2(96, -191 + wave), Color(1.0, 0.88, 0.55, 0.8), 2.0, true)
	_draw_star(Vector2(47, -173 + wave * 0.6), 13.0, Color(1.0, 0.92, 0.55))

	# Sparkles rising from the base.
	for i in 5:
		var sparkle_y := fmod(_time * 25.0 + float(i) * 31.0, 170.0)
		var sparkle_x := sin(_time * 1.4 + float(i) * 1.8) * 30.0
		var alpha := 0.25 + 0.4 * sin(_time * 2.0 + float(i))
		draw_circle(Vector2(sparkle_x, -20.0 - sparkle_y), 2.2, Color(1.0, 0.95, 0.65, alpha))


func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var r := radius if i % 2 == 0 else radius * 0.45
		var angle := -PI * 0.5 + TAU * float(i) / 10.0
		points.append(center + Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color)
