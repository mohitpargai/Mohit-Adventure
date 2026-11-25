## Cracking platform that shatters shortly after Mohit lands on it.
extends StaticBody2D

@export var size := Vector2(180.0, 26.0)
@export var style := 0
@export var seed_value := 991

const BURST_SCENE := preload("res://Scenes/BurstEffect.tscn")

var _collision: CollisionShape2D
var _trigger: Area2D
var _breaking := false
var _time := 0.0


func _ready() -> void:
	add_to_group("breakable_platforms")
	collision_layer = 2
	collision_mask = 0
	_ensure_collision()
	_ensure_trigger()
	queue_redraw()


func setup(new_size: Vector2, new_style: int = 0, new_seed: int = 991) -> void:
	size = new_size
	style = new_style
	seed_value = new_seed
	if is_inside_tree():
		_ensure_collision()
		_ensure_trigger()
	queue_redraw()


func _ensure_collision() -> void:
	if _collision == null:
		_collision = CollisionShape2D.new()
		_collision.name = "CollisionShape2D"
		add_child(_collision)
	var rect := RectangleShape2D.new()
	rect.size = size
	_collision.shape = rect


func _ensure_trigger() -> void:
	if _trigger != null:
		_trigger.queue_free()
	_trigger = Area2D.new()
	_trigger.name = "Trigger"
	_trigger.collision_layer = 64
	_trigger.collision_mask = 1
	var collision := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x, maxf(16.0, size.y + 18.0))
	collision.shape = rect
	_trigger.add_child(collision)
	add_child(_trigger)
	_trigger.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	if _breaking:
		queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _breaking or not body.is_in_group("player"):
		return
	# Only shatter when the player comes down onto the top surface.
	var top := global_position.y - size.y * 0.5
	if body.global_position.y > top + 30.0:
		return
	if body.velocity.y < -40.0:
		return
	_break()


func _break() -> void:
	_breaking = true
	AudioManager.play_sfx("break")
	_shake()
	await get_tree().create_timer(0.16).timeout
	var burst = BURST_SCENE.instantiate()
	burst.color = _color().lightened(0.22)
	burst.particle_count = 16
	burst.start_speed = 230.0
	burst.particle_size = 6.0
	burst.global_position = global_position
	get_parent().add_child(burst)
	queue_free()


func _shake() -> void:
	var tween := create_tween()
	for i in 4:
		tween.tween_property(self, "position:x", position.x + (4.0 if i % 2 == 0 else -4.0), 0.035)
	tween.tween_property(self, "position:x", position.x, 0.03)


func _color() -> Color:
	match style:
		3:
			return Color(0.62, 0.84, 0.97)
		4:
			return Color(0.82, 0.66, 0.37)
		5:
			return Color(0.30, 0.27, 0.39)
		6:
			return Color(0.34, 0.20, 0.18)
		7:
			return Color(0.88, 0.94, 1.0)
		_:
			return Color(0.56, 0.42, 0.25)


func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var base := StyleBoxFlat.new()
	base.bg_color = _color()
	base.border_color = _color().darkened(0.35)
	base.set_border_width_all(2)
	base.set_corner_radius_all(6)
	draw_style_box(base, rect)
	draw_rect(Rect2(rect.position + Vector2(5, 3), Vector2(size.x - 10.0, 4.0)), _color().lightened(0.30))
	# Cracks grow as the platform starts breaking.
	var crack_count := 6 if _breaking else 3
	for i in crack_count:
		var x := rng.randf_range(rect.position.x + 12.0, rect.end.x - 12.0)
		var y := rng.randf_range(rect.position.y + 4.0, rect.end.y - 4.0)
		var points := PackedVector2Array([Vector2(x, y)])
		var cx := x
		var cy := y
		for k in 3:
			cx += rng.randf_range(-9.0, 9.0)
			cy += rng.randf_range(2.0, 8.0)
			points.append(Vector2(cx, minf(cy, rect.end.y - 2.0)))
		draw_polyline(points, Color(0.12, 0.08, 0.05, 0.75), 1.6, true)
	if _breaking:
		draw_rect(rect, Color(1.0, 0.86, 0.55, 0.20))
