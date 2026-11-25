## Floating platform that glides between two points. Uses an AnimatableBody2D
## so CharacterBody2D players are carried smoothly.
extends AnimatableBody2D

@export var size := Vector2(150.0, 30.0)
@export var travel := Vector2(180.0, 0.0)
@export var speed := 1.1
@export var phase := 0.0
@export var style := 0

var _start := Vector2.ZERO
var _time := 0.0
var _collision: CollisionShape2D


func _ready() -> void:
	add_to_group("moving_platforms")
	collision_layer = 2
	collision_mask = 0
	sync_to_physics = true
	_start = position
	_ensure_collision()
	_time = phase
	queue_redraw()


func setup(travel_vector: Vector2, platform_size: Vector2, travel_speed: float = 1.1, start_phase: float = 0.0, platform_style: int = 0) -> void:
	travel = travel_vector
	size = platform_size
	speed = travel_speed
	phase = start_phase
	style = platform_style
	if is_inside_tree():
		_start = position
		_ensure_collision()
	queue_redraw()


func _physics_process(delta: float) -> void:
	_time += delta * speed
	var factor := 0.5 + 0.5 * sin(_time)
	position = _start + travel * factor


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
	var shadow := Color(0.02, 0.09, 0.06, 0.25)
	draw_set_transform(Vector2(4, 9), 0.0, Vector2(1.0, 0.6))
	draw_circle(Vector2.ZERO, size.x * 0.42, shadow)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if style != 0 and style != 2:
		_draw_themed(rect)
		return

	var wood := StyleBoxFlat.new()
	wood.bg_color = Color(0.47, 0.29, 0.15)
	wood.border_color = Color(0.27, 0.15, 0.06)
	wood.set_border_width_all(3)
	wood.set_corner_radius_all(10)
	draw_style_box(wood, rect)
	draw_rect(Rect2(rect.position + Vector2(8, 3), Vector2(rect.size.x - 16.0, 5.0)), Color(0.64, 0.46, 0.26, 0.6))
	for i in 3:
		var x := -size.x * 0.31 + float(i) * size.x * 0.31
		draw_line(Vector2(x, rect.position.y + 5.0), Vector2(x, rect.end.y - 5.0), Color(0.32, 0.18, 0.08, 0.6), 1.5)

	# Moss and little glowing runes.
	var moss := StyleBoxFlat.new()
	moss.bg_color = Color(0.33, 0.59, 0.29, 0.9)
	moss.set_corner_radius_all(7)
	draw_style_box(moss, Rect2(rect.position + Vector2(3, 0), Vector2(rect.size.x - 6.0, 8.0)))
	for i in 3:
		var rune_pos := Vector2(-size.x * 0.27 + float(i) * size.x * 0.27, 0)
		draw_circle(rune_pos, 3.0, Color(0.72, 1.0, 0.57, 0.9))
		draw_circle(rune_pos, 6.0, Color(0.72, 1.0, 0.57, 0.18))

	# Hanging vines.
	var sway := sin(_time * 2.2) * 4.0
	draw_line(Vector2(-size.x * 0.38, size.y * 0.5), Vector2(-size.x * 0.40 + sway, size.y * 0.5 + 23.0), Color(0.24, 0.50, 0.25), 2.4, true)
	draw_line(Vector2(size.x * 0.37, size.y * 0.5), Vector2(size.x * 0.39 - sway, size.y * 0.5 + 18.0), Color(0.24, 0.50, 0.25), 2.0, true)


func _draw_themed(rect: Rect2) -> void:
	var base := StyleBoxFlat.new()
	base.set_corner_radius_all(10)
	base.set_border_width_all(2)
	var accent := Color(0.80, 1.0, 0.90)
	match style:
		3:
			base.bg_color = Color(0.62, 0.84, 0.97)
			base.border_color = Color(0.34, 0.58, 0.78)
			accent = Color(0.94, 1.0, 1.0)
		4:
			base.bg_color = Color(0.82, 0.66, 0.37)
			base.border_color = Color(0.58, 0.43, 0.22)
			accent = Color(1.0, 0.91, 0.66)
		5:
			base.bg_color = Color(0.30, 0.27, 0.39)
			base.border_color = Color(0.14, 0.12, 0.19)
			accent = Color(0.80, 0.62, 1.0)
		6:
			base.bg_color = Color(0.26, 0.16, 0.15)
			base.border_color = Color(0.12, 0.06, 0.06)
			accent = Color(1.0, 0.52, 0.16)
		7:
			base.bg_color = Color(0.92, 0.96, 1.0)
			base.border_color = Color(0.72, 0.85, 1.0)
			accent = Color(1.0, 0.94, 0.64)
	draw_style_box(base, rect)
	draw_rect(Rect2(rect.position + Vector2(7, 3), Vector2(rect.size.x - 14.0, 5.0)), accent)
	for i in 3:
		var rune_pos := Vector2(-size.x * 0.27 + float(i) * size.x * 0.27, 0)
		draw_circle(rune_pos, 3.0, Color(accent, 0.9))
		draw_circle(rune_pos, 6.0, Color(accent, 0.18))
	if style == 6:
		draw_circle(Vector2(0, size.y * 0.55), size.x * 0.30, Color(1.0, 0.36, 0.10, 0.22))
