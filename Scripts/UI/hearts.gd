## Draws a row of hearts without needing any texture assets.
extends Control

@export var max_hearts := 3

var _health := 3
var _time := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(146, 36)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func set_health(current: int, maximum: int = -1) -> void:
	_health = maxi(0, current)
	if maximum > 0:
		max_hearts = maximum
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _health == 1:
		queue_redraw()


func _draw() -> void:
	var spacing := 46.0
	var start_x := 20.0
	var center_y := size.y * 0.52
	for i in max_hearts:
		var center := Vector2(start_x + float(i) * spacing, center_y)
		var filled := i < _health
		var pulse := 1.0
		if _health == 1 and filled:
			pulse = 1.0 + sin(_time * 7.0) * 0.06
		_draw_heart(center, 1.0 * pulse, filled)
	# Empty slots are drawn dark so the player always knows the maximum.


func _draw_heart(center: Vector2, scale_value: float, filled: bool) -> void:
	var fill := Color(0.94, 0.26, 0.31) if filled else Color(0.16, 0.28, 0.22, 0.75)
	var shade := fill.darkened(0.25) if filled else Color(0.10, 0.18, 0.14, 0.7)
	var highlight := Color(1.0, 0.65, 0.64) if filled else Color(0.25, 0.38, 0.30, 0.6)
	var s := scale_value
	# Dark outline.
	draw_circle(center + Vector2(-7.5, -4.0) * s, 10.5 * s, shade)
	draw_circle(center + Vector2(7.5, -4.0) * s, 10.5 * s, shade)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-17.0, -2.0) * s,
		center + Vector2(17.0, -2.0) * s,
		center + Vector2(0, 17.0) * s,
	]), shade)
	# Fill.
	draw_circle(center + Vector2(-7.0, -4.0) * s, 8.8 * s, fill)
	draw_circle(center + Vector2(7.0, -4.0) * s, 8.8 * s, fill)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-15.2, -1.5) * s,
		center + Vector2(15.2, -1.5) * s,
		center + Vector2(0, 15.0) * s,
	]), fill)
	# Gloss.
	if filled:
		draw_circle(center + Vector2(-8.0, -7.0) * s, 3.1 * s, highlight)
		draw_circle(center + Vector2(-12.0, -4.0) * s, 1.5 * s, Color(1, 0.85, 0.82, 0.7))
