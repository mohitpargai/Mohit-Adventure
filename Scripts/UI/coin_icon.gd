## Small spinning coin icon used by the HUD.
extends Control

var _time := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(30, 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var spin := clampf(absf(cos(_time * 2.5)), 0.26, 1.0)
	draw_set_transform(center, 0.0, Vector2(spin, 1.0))
	draw_circle(Vector2.ZERO, 13.0, Color(0.74, 0.45, 0.04))
	draw_circle(Vector2.ZERO, 11.5, Color(1.0, 0.79, 0.22))
	draw_circle(Vector2.ZERO, 8.6, Color(1.0, 0.90, 0.46))
	var points := PackedVector2Array()
	for i in 10:
		var radius := 5.6 if i % 2 == 0 else 2.4
		var angle := -PI * 0.5 + TAU * float(i) / 10.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, Color(0.76, 0.47, 0.07, 0.8))
	draw_circle(Vector2(-3.5, -4.5), 1.7, Color(1, 1, 1, 0.9))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
