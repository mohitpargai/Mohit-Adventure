## Thorny spike strip. Hurts the player and knocks them away.
extends Area2D

@export var size := Vector2(104.0, 32.0)
@export var spike_count := 4

var _collision: CollisionShape2D


func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	_ensure_collision()
	body_entered.connect(_on_body_entered)
	queue_redraw()


func setup(new_size: Vector2, count: int = 4) -> void:
	size = new_size
	spike_count = count
	if is_inside_tree():
		_ensure_collision()
	queue_redraw()


func _ensure_collision() -> void:
	if _collision == null:
		_collision = CollisionShape2D.new()
		_collision.name = "CollisionShape2D"
		add_child(_collision)
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(size.x - 8.0, size.y * 0.68)
	_collision.shape = rectangle
	_collision.position = Vector2(0, -size.y * 0.42)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1, global_position)


func _draw() -> void:
	var width := size.x / float(maxi(1, spike_count))
	var base_color := Color(0.42, 0.47, 0.52)
	var dark_color := Color(0.18, 0.22, 0.27)
	var tip_color := Color(0.85, 0.91, 0.95)

	# Base bar.
	var base_box := StyleBoxFlat.new()
	base_box.bg_color = Color(0.24, 0.20, 0.20)
	base_box.set_corner_radius_all(5)
	draw_style_box(base_box, Rect2(-size.x * 0.5, -7.0, size.x, 10.0))

	for i in spike_count:
		var left := -size.x * 0.5 + float(i) * width
		var tip := Vector2(left + width * 0.5, -size.y)
		draw_colored_polygon(PackedVector2Array([
			Vector2(left + 3.0, 0),
			tip,
			Vector2(left + width - 3.0, 0),
		]), base_color)
		draw_colored_polygon(PackedVector2Array([
			Vector2(left + width * 0.5, 0),
			tip,
			Vector2(left + width - 3.0, 0),
		]), dark_color)
		draw_line(tip + Vector2(-1, 0), Vector2(left + width * 0.5 - 1.0, 0), Color(tip_color, 0.5), 1.5, true)

	# Danger glints.
	draw_circle(Vector2(-size.x * 0.5 + 3.0, -3.0), 2.0, Color(1.0, 0.35, 0.25, 0.8))
	draw_circle(Vector2(size.x * 0.5 - 3.0, -3.0), 2.0, Color(1.0, 0.35, 0.25, 0.8))
