## Projectile thrown by a boss. Handles its own movement, glow and player hit.
extends Area2D

@export var kind := "orb"
@export var velocity := Vector2.ZERO
@export var gravity_accel := 0.0
@export var life := 4.5
@export var theme := 0

var _time := 0.0
var _radius := 11.0


func _ready() -> void:
	z_index = 5
	collision_layer = 16
	collision_mask = 1
	add_to_group("boss_projectiles")
	_time = fmod(position.x * 0.01, TAU)
	_create_collision()
	body_entered.connect(_on_body_entered)


func setup(new_kind: String, new_velocity: Vector2, new_theme: int = 0, new_gravity: float = 0.0) -> void:
	kind = new_kind
	velocity = new_velocity
	theme = new_theme
	gravity_accel = new_gravity
	if is_inside_tree():
		_create_collision()
	queue_redraw()


func _create_collision() -> void:
	if has_node("CollisionShape2D"):
		return
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	_radius = 9.0 if kind == "icicle" else 12.0
	circle.radius = _radius
	collision.shape = circle
	add_child(collision)


func _physics_process(delta: float) -> void:
	_time += delta
	life -= delta
	velocity.y += gravity_accel * delta
	position += velocity * delta
	if life <= 0.0 or position.y > 1500.0 or position.x < -300.0 or position.x > 2600.0:
		queue_free()
		return
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(1, global_position)
	set_deferred("monitoring", false)
	queue_free()


func _draw() -> void:
	match kind:
		"icicle":
			_draw_icicle()
		"rock":
			_draw_rock()
		"fireball":
			_draw_fireball()
		"dark":
			_draw_dark()
		_:
			_draw_orb()


func _draw_orb() -> void:
	var color := _theme_color()
	draw_circle(Vector2.ZERO, _radius + 8.0, Color(color, 0.12))
	draw_circle(Vector2.ZERO, _radius, color)
	draw_circle(Vector2(-2, -2), _radius * 0.55, color.lightened(0.45))
	draw_circle(Vector2(-3, -3), 2.4, Color(1, 1, 1, 0.9))


func _draw_icicle() -> void:
	var angle := velocity.angle() + PI * 0.5
	draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, -10), Vector2(0, 20), Vector2(9, -10)
	]), Color(0.74, 0.92, 1.0))
	draw_line(Vector2(0, -8), Vector2(0, 15), Color(1, 1, 1, 0.7), 1.6, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_rock() -> void:
	draw_circle(Vector2.ZERO, 15.0, Color(0.34, 0.25, 0.16))
	draw_circle(Vector2(-3, -3), 11.0, Color(0.53, 0.40, 0.25))
	draw_circle(Vector2(-6, -6), 4.0, Color(0.68, 0.55, 0.36, 0.8))


func _draw_fireball() -> void:
	draw_circle(Vector2.ZERO, 18.0, Color(1.0, 0.34, 0.08, 0.25))
	draw_circle(Vector2.ZERO, 12.0, Color(1.0, 0.45, 0.10))
	draw_circle(Vector2(-2, -2), 7.0, Color(1.0, 0.74, 0.24))
	draw_circle(Vector2(-3, -3), 3.0, Color(1, 1, 0.86, 0.95))


func _draw_dark() -> void:
	var pulse := 1.0 + sin(_time * 8.0) * 0.12
	draw_circle(Vector2.ZERO, 18.0 * pulse, Color(0.42, 0.12, 0.64, 0.22))
	draw_circle(Vector2.ZERO, 11.0, Color(0.22, 0.06, 0.38))
	draw_circle(Vector2.ZERO, 8.0, Color(0.62, 0.28, 0.96))
	draw_circle(Vector2(-2, -2), 3.0, Color(0.92, 0.80, 1.0, 0.9))


func _theme_color() -> Color:
	return [
		Color(0.54, 0.92, 0.48),
		Color(0.66, 0.92, 1.0),
		Color(1.0, 0.82, 0.42),
		Color(0.72, 0.44, 1.0),
		Color(1.0, 0.52, 0.18),
		Color(0.78, 0.88, 1.0),
	][clampi(theme, 0, 5)]
