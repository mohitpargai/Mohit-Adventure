## Friendly checkpoint lantern. Touching it moves Mohit's respawn point here.
extends Area2D

signal activated(at: Vector2)

var _active := false
var _time := 0.0
var _collision: CollisionShape2D


func _ready() -> void:
	add_to_group("checkpoints")
	collision_layer = 32
	collision_mask = 1
	_create_collision()
	body_entered.connect(_on_body_entered)


func _create_collision() -> void:
	_collision = CollisionShape2D.new()
	_collision.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(74.0, 130.0)
	_collision.shape = rect
	_collision.position = Vector2(0, -65.0)
	add_child(_collision)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _active or not body.is_in_group("player"):
		return
	_active = true
	# Deferred: changing monitoring inside a physics signal is not allowed.
	set_deferred("monitoring", false)
	AudioManager.play_sfx("coin")
	activated.emit(global_position)


func _draw() -> void:
	var glow_color := Color(0.56, 1.0, 0.52) if _active else Color(0.55, 0.66, 0.68)
	var pulse := 0.5 + 0.5 * sin(_time * 3.4)

	# Stone base.
	draw_circle(Vector2(0, -3), 15.0, Color(0.36, 0.42, 0.40))
	draw_circle(Vector2(-10, -2), 9.0, Color(0.30, 0.35, 0.34))
	draw_circle(Vector2(11, -2), 8.0, Color(0.42, 0.48, 0.45))

	# Wooden post.
	draw_rect(Rect2(-3.5, -102, 7, 100), Color(0.37, 0.23, 0.12))
	draw_rect(Rect2(-2.0, -101, 2.4, 98), Color(0.58, 0.40, 0.24))

	# Lantern housing.
	draw_rect(Rect2(-17, -136, 34, 38), Color(0.22, 0.26, 0.27))
	draw_rect(Rect2(-13, -132, 26, 30), Color(0.08, 0.11, 0.10))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22, -136), Vector2(0, -152), Vector2(22, -136)
	]), Color(0.18, 0.22, 0.23))
	draw_rect(Rect2(-17, -101, 34, 5), Color(0.18, 0.22, 0.23))

	# Crystal / flame.
	if _active:
		for i in 4:
			draw_circle(Vector2(0, -117), 12.0 + i * 8.0, Color(glow_color, 0.03 + 0.02 * pulse))
		draw_circle(Vector2(0, -117), 11.0, Color(glow_color, 0.28))
	draw_circle(Vector2(0, -117), 8.5, glow_color)
	draw_circle(Vector2(-2, -120), 4.0, Color(1, 1, 0.94, 0.9))
	draw_circle(Vector2(0, -117), 2.0, Color.WHITE)

	if _active:
		draw_arc(Vector2(0, -117), 20.0 + pulse * 4.0, 0.0, TAU, 24, Color(glow_color, 0.4), 2.0, true)
