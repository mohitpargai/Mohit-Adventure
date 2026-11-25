## Hidden treasure chest. Opening it awards a coin and score bonus.
extends Area2D

signal opened(at: Vector2, bonus: int)

@export var bonus := 5

var _time := 0.0
var _open := false


func _ready() -> void:
	collision_layer = 32
	collision_mask = 1
	add_to_group("treasure")
	_create_collision()
	body_entered.connect(_on_body_entered)


func _create_collision() -> void:
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(86.0, 70.0)
	collision.shape = rect
	collision.position = Vector2(0, -35.0)
	add_child(collision)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _open or not body.is_in_group("player"):
		return
	_open = true
	set_deferred("monitoring", false)
	AudioManager.play_sfx("treasure")
	opened.emit(global_position, bonus)


func _draw() -> void:
	var bob := sin(_time * 2.2) * 1.6
	var lid := -24.0 if _open else 0.0
	# Warm glow.
	for i in 3:
		draw_circle(Vector2(0, -22), 34.0 + i * 9.0, Color(1.0, 0.82, 0.36, 0.045 if not _open else 0.02))
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	# Chest body.
	draw_rect(Rect2(-30, -32, 60, 30), Color(0.43, 0.23, 0.10))
	draw_rect(Rect2(-30, -32, 60, 8), Color(0.58, 0.34, 0.15))
	draw_rect(Rect2(-30, -8, 60, 6), Color(0.28, 0.15, 0.07))
	for x in [-24, 18]:
		draw_rect(Rect2(float(x), -34, 6, 32), Color(0.86, 0.64, 0.22))
	# Lid.
	draw_set_transform(Vector2(0, bob + lid), -0.10 if _open else 0.0, Vector2.ONE)
	draw_rect(Rect2(-31, -46, 62, 18), Color(0.52, 0.29, 0.13))
	draw_rect(Rect2(-31, -46, 62, 6), Color(0.66, 0.40, 0.18))
	draw_rect(Rect2(-31, -31, 62, 5), Color(0.86, 0.64, 0.22))
	draw_rect(Rect2(-6, -41, 12, 14), Color(0.94, 0.76, 0.30))
	draw_circle(Vector2(0, -34), 3.0, Color(0.32, 0.20, 0.09))
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	if _open:
		for i in 4:
			var angle := float(i) * TAU / 4.0 + _time
			draw_circle(Vector2(cos(angle) * 22.0, -44.0 + sin(angle) * 12.0), 2.4, Color(1.0, 0.92, 0.54, 0.85))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
