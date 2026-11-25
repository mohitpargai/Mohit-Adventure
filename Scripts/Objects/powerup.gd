## Floating power-up orb. kind 0 = shield, 1 = speed, 2 = extra life, 3 = heal.
extends Area2D

signal collected(kind: int, at: Vector2)
signal effect_applied(kind: int)

@export var kind := 0
@export var bob_height := 7.0

var _time := 0.0
var _taken := false


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	monitoring = true
	add_to_group("powerups")
	_time = fmod(global_position.x * 0.01, TAU)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	set_deferred("monitoring", false)
	AudioManager.play_sfx("powerup")
	collected.emit(kind, global_position)
	effect_applied.emit(kind)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.9, 1.9), 0.14)
	tween.tween_property(self, "modulate:a", 0.0, 0.28).set_delay(0.06)
	await tween.finished
	queue_free()


func _draw() -> void:
	var bob := sin(_time * 3.0) * bob_height
	var color := _color()
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	# Aura.
	for i in 3:
		draw_circle(Vector2.ZERO, 20.0 + i * 6.0 + sin(_time * 2.4) * 2.0, Color(color, 0.05))
	draw_circle(Vector2.ZERO, 17.0, Color(0.04, 0.10, 0.08, 0.45))
	draw_circle(Vector2.ZERO, 15.0, color.darkened(0.36))
	draw_circle(Vector2.ZERO, 12.5, color)
	draw_arc(Vector2.ZERO, 13.5, -2.6, -0.6, 12, Color(1, 1, 1, 0.55), 2.0, true)
	match kind:
		0:
			_draw_shield(color)
		1:
			_draw_bolt(color)
		2:
			_draw_heart(Color(0.99, 0.50, 0.50))
		_:
			_draw_cross(Color(0.66, 1.0, 0.72))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _color() -> Color:
	match kind:
		0:
			return Color(0.36, 0.72, 1.0)
		1:
			return Color(1.0, 0.84, 0.26)
		2:
			return Color(0.98, 0.42, 0.46)
		_:
			return Color(0.42, 0.90, 0.52)


func _draw_shield(color: Color, _unused: float = 0.0) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -9), Vector2(8, -5), Vector2(7, 4), Vector2(0, 10),
		Vector2(-7, 4), Vector2(-8, -5)
	]), Color(1, 1, 1, 0.92))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -6), Vector2(5, -3), Vector2(4, 3), Vector2(0, 7),
		Vector2(-4, 3), Vector2(-5, -3)
	]), color)


func _draw_bolt(_color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(1, -10), Vector2(-6, 1), Vector2(-1, 1), Vector2(-2, 10),
		Vector2(7, -2), Vector2(1, -2)
	]), Color(1, 1, 1, 0.95))


func _draw_heart(color: Color) -> void:
	draw_circle(Vector2(-4, -3), 5.0, color)
	draw_circle(Vector2(4, -3), 5.0, color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, -1), Vector2(9, -1), Vector2(0, 10)
	]), color)


func _draw_cross(color: Color) -> void:
	draw_rect(Rect2(-3, -9, 6, 18), color)
	draw_rect(Rect2(-9, -3, 18, 6), color)
