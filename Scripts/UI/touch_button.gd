## Large, multi-touch friendly on-screen button. It presses InputMap actions
## so keyboard, touch and gamepad all flow through the same player code.
extends Control

@export var action: StringName = &"move_left"
@export var icon := "left"
@export var accent := Color(0.45, 0.79, 0.44)

var _touch_index := -1
var _mouse_pressed := false
var _active := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	pivot_offset = size * 0.5
	set_process(true)


func _process(_delta: float) -> void:
	var pressed := _active or Input.is_action_pressed(action)
	if pressed != _active:
		_active = pressed
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1:
			_touch_index = touch.index
			_press()
			accept_event()
		elif not touch.pressed and touch.index == _touch_index:
			_touch_index = -1
			_release()
			accept_event()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index and _touch_index != -1:
			# Keep the button held even if the finger drifts a little.
			accept_event()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed and not _mouse_pressed:
				_mouse_pressed = true
				_press()
			elif not mouse.pressed and _mouse_pressed:
				_mouse_pressed = false
				_release()
			accept_event()


func _press() -> void:
	if _active:
		return
	_active = true
	Input.action_press(action, 1.0)
	queue_redraw()


func _release() -> void:
	if not _active:
		return
	_active = false
	Input.action_release(action)
	queue_redraw()


func release() -> void:
	_touch_index = -1
	_mouse_pressed = false
	_release()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible:
		release()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 3.0
	if _active:
		center.y += 2.0

	# Shadow.
	draw_circle(Vector2(size.x * 0.5, size.y * 0.5 + 7.0), radius, Color(0.02, 0.07, 0.05, 0.32))
	# Outer ring.
	draw_circle(center, radius, Color(0.05, 0.17, 0.12, 0.62))
	draw_arc(center, radius - 2.0, 0.0, TAU, 48, Color(0.94, 0.98, 0.87, 0.38), 3.0, true)
	# Main face.
	var face := accent
	if _active:
		face = accent.lightened(0.16)
	draw_circle(center, radius - 9.0, Color(face, 0.95))
	draw_circle(center + Vector2(0, -radius * 0.16), radius * 0.62, Color(1, 1, 1, 0.08))
	if _active:
		draw_circle(center, radius + 3.0, Color(1, 1, 1, 0.12))

	# Icon.
	var icon_color := Color(1.0, 0.98, 0.90, 0.96)
	var icon_scale := radius / 62.0
	var c := center

	match icon:
		"left":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-19, 0) * icon_scale,
				c + Vector2(-2, -16) * icon_scale,
				c + Vector2(-2, 16) * icon_scale,
			]), icon_color)
			draw_rect(Rect2(c + Vector2(2, -8) * icon_scale, Vector2(16, 16) * icon_scale), icon_color)
		"right":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(19, 0) * icon_scale,
				c + Vector2(2, -16) * icon_scale,
				c + Vector2(2, 16) * icon_scale,
			]), icon_color)
			draw_rect(Rect2(c + Vector2(-18, -8) * icon_scale, Vector2(16, 16) * icon_scale), icon_color)
		"jump":
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -22) * icon_scale,
				c + Vector2(-18, -4) * icon_scale,
				c + Vector2(18, -4) * icon_scale,
			]), icon_color)
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -2) * icon_scale,
				c + Vector2(-18, 16) * icon_scale,
				c + Vector2(18, 16) * icon_scale,
			]), Color(icon_color, 0.8))
