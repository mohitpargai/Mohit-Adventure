## Spinning collectible coin.
extends Area2D

signal picked_up(value: int, at: Vector2)

@export var value := 1

var _collected := false
var _time := 0.0
var _spin := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	monitoring = true
	add_to_group("coins")
	_time = fmod(global_position.x * 0.013, TAU)
	_spin = _time
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_spin += delta * 4.2
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if not body.is_in_group("player"):
		return
	_collected = true
	# Deferred: changing monitoring inside a physics signal is not allowed.
	set_deferred("monitoring", false)
	picked_up.emit(value, global_position)
	AudioManager.play_sfx("coin")

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.75, 1.75), 0.10)
	tween.tween_property(self, "modulate:a", 0.0, 0.24).set_delay(0.06)
	await tween.finished
	queue_free()


func _draw() -> void:
	var bob := sin(_time * 3.4) * 3.5
	var width_scale := clampf(absf(cos(_spin)), 0.18, 1.0)
	draw_set_transform(Vector2(0, bob), -0.08, Vector2(width_scale, 1.0))

	# Soft glow.
	draw_circle(Vector2.ZERO, 21.0, Color(1.0, 0.85, 0.30, 0.12))
	draw_circle(Vector2.ZERO, 17.5, Color(0.76, 0.47, 0.05))
	draw_circle(Vector2.ZERO, 15.0, Color(1.0, 0.77, 0.20))
	draw_circle(Vector2.ZERO, 11.5, Color(1.0, 0.89, 0.43))
	draw_arc(Vector2.ZERO, 12.2, 0.35, 2.2, 14, Color(1.0, 0.97, 0.78, 0.85), 2.0, true)

	# Embossed star.
	var points := PackedVector2Array()
	for i in 10:
		var radius := 7.2 if i % 2 == 0 else 3.2
		var angle := -PI * 0.5 + TAU * float(i) / 10.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, Color(0.77, 0.47, 0.07, 0.8))

	# Little glint when the coin is nearly edge-on.
	if width_scale > 0.7:
		draw_circle(Vector2(-5, -6), 2.1, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(6, 5), 1.3, Color(1, 1, 1, 0.55))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
