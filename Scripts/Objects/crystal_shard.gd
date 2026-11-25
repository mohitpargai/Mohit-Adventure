## Collectible crystal shard hidden in every level. Boss levels guard the
## larger world crystal shard.
extends Area2D

signal collected(at: Vector2)

@export var color := Color(0.62, 0.90, 1.0)

var _time := 0.0
var _taken := false


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	add_to_group("crystal_shards")
	_time = fmod(global_position.y * 0.02, TAU)
	_create_collision()
	body_entered.connect(_on_body_entered)


func _create_collision() -> void:
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var circle := CircleShape2D.new()
	circle.radius = 24.0
	collision.shape = circle
	add_child(collision)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	set_deferred("monitoring", false)
	AudioManager.play_sfx("shard")
	collected.emit(global_position)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.34).set_delay(0.08)
	await tween.finished
	queue_free()


func _draw() -> void:
	var bob := sin(_time * 2.6) * 6.0
	for i in 4:
		draw_circle(Vector2(0, bob), 25.0 + i * 7.0, Color(color, 0.035))
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	# Crystal shard.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -24), Vector2(13, -4), Vector2(7, 18), Vector2(-7, 18), Vector2(-13, -4)
	]), Color(color, 0.95))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -24), Vector2(13, -4), Vector2(0, 5)
	]), Color(1, 1, 1, 0.55))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 5), Vector2(7, 18), Vector2(-7, 18)
	]), Color(color.darkened(0.30), 0.95))
	draw_line(Vector2(0, -22), Vector2(0, 16), Color(1, 1, 1, 0.65), 1.6, true)
	# Orbiting sparks.
	for i in 3:
		var angle := _time * 2.0 + float(i) * TAU / 3.0
		draw_circle(Vector2(cos(angle) * 24.0, sin(angle) * 12.0 - 2.0), 2.0, Color(1, 1, 1, 0.85))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
