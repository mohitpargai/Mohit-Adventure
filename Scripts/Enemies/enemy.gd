## Patrolling enemy used across all six kingdoms.
## Ground: 0 slime, 2 snowball, 3 scorpion.
## Flying: 1 bee, 4 ghost, 5 fire imp, 6 sky bat.
## All are stompable; touching their side hurts Mohit.
extends CharacterBody2D

signal defeated(enemy: Node, at: Vector2)

@export var kind := 0
@export var patrol_left := -120.0
@export var patrol_right := 120.0
@export var speed := 58.0
@export var phase := 0.0
@export var tint := Color(0.30, 0.76, 0.37)

const GRAVITY := 1700.0
const BURST_SCENE := preload("res://Scenes/BurstEffect.tscn")

var _time := 0.0
var _direction := 1.0
var _dead := false
var _base_y := 0.0
var _center_x := 0.0
var _body_shape: CollisionShape2D
var _hitbox: Area2D
var _hitbox_shape: CollisionShape2D


func _is_grounded() -> bool:
	return kind == 0 or kind == 2 or kind == 3


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 8
	collision_mask = 2 if _is_grounded() else 0
	_base_y = position.y
	_center_x = (patrol_left + patrol_right) * 0.5
	_direction = -1.0 if phase > 1.0 else 1.0
	_create_shapes()
	_hitbox = $Hitbox
	_hitbox.body_entered.connect(_on_hitbox_body_entered)
	_time = phase


func _create_shapes() -> void:
	_body_shape = CollisionShape2D.new()
	_body_shape.name = "BodyShape"
	add_child(_body_shape)
	var circle := CircleShape2D.new()
	match kind:
		0:
			circle.radius = 18.0
		2:
			circle.radius = 19.0
		3:
			circle.radius = 16.0
		6:
			circle.radius = 16.0
		_:
			circle.radius = 15.0
	_body_shape.position = Vector2(0, 0)
	_body_shape.shape = circle

	var hitbox_circle := CircleShape2D.new()
	hitbox_circle.radius = 27.0 if kind == 0 else (26.0 if kind == 2 else 24.0)
	var shape_node := CollisionShape2D.new()
	shape_node.name = "HitboxShape"
	shape_node.shape = hitbox_circle
	_hitbox_shape = shape_node
	# The Hitbox node exists in the scene; add its collision shape at runtime so
	# each enemy instance gets its own unique shape resource.
	get_node("Hitbox").add_child(shape_node)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_time += delta

	if _is_grounded():
		velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
		if position.x <= patrol_left:
			_direction = 1.0
		elif position.x >= patrol_right:
			_direction = -1.0
		if is_on_wall():
			_direction *= -1.0
		var move_speed := speed
		if kind == 2:
			move_speed *= 1.15
			# Snowballs bounce a little as they roll.
			if is_on_floor() and sin(_time * 4.0 + phase) > 0.92:
				velocity.y = -150.0
		elif kind == 3:
			move_speed *= 1.35
		velocity.x = _direction * move_speed
		move_and_slide()
	else:
		var amplitude := maxf(10.0, (patrol_right - patrol_left) * 0.5)
		var bob_speed := 1.8
		var bob_amplitude := 20.0 + absf(sin(phase)) * 14.0
		var drift := 0.9
		match kind:
			4:
				drift = 0.55
				bob_amplitude = 28.0
			5:
				drift = 1.15
				bob_speed = 2.6
			6:
				drift = 1.7
				bob_speed = 3.2
				bob_amplitude = 32.0
		position.x = _center_x + sin(_time * drift + phase) * amplitude
		position.y = _base_y + sin(_time * bob_speed + phase) * bob_amplitude
	queue_redraw()


func _on_hitbox_body_entered(body: Node) -> void:
	if _dead or not body.is_in_group("player"):
		return
	var player = body
	var stomped: bool = player.velocity.y > 70.0 and player.global_position.y < global_position.y - 5.0
	if stomped:
		player.bounce()
		die()
	else:
		player.take_damage(1, global_position)


func die() -> void:
	if _dead:
		return
	_dead = true
	velocity = Vector2.ZERO
	_hitbox.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	AudioManager.play_sfx("stomp")
	defeated.emit(self, global_position)

	var burst = BURST_SCENE.instantiate()
	burst.color = tint.lightened(0.18)
	burst.particle_count = 14
	burst.start_speed = 220.0
	burst.particle_size = 5.0
	burst.global_position = global_position
	get_parent().add_child(burst)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.5, 0.12), 0.24)
	tween.tween_property(self, "modulate:a", 0.0, 0.28)
	await tween.finished
	queue_free()


func _draw() -> void:
	match kind:
		0:
			_draw_slime()
		2:
			_draw_snowball()
		3:
			_draw_scorpion()
		4:
			_draw_ghost()
		5:
			_draw_fire_imp()
		6:
			_draw_sky_bat()
		_:
			_draw_bee()


func _draw_slime() -> void:
	var squash := sin(_time * 4.6 + phase) * 0.08
	# Shadow.
	draw_set_transform(Vector2(0, 21), 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 21.0, Color(0.02, 0.08, 0.05, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_set_transform(Vector2(0, sin(_time * 6.2 + phase) * 1.5), 0.0, Vector2(1.0 + squash, 1.0 - squash))
	draw_circle(Vector2(0, 2), 19.5, tint.darkened(0.30))
	draw_circle(Vector2(0, 1), 17.5, tint)
	draw_circle(Vector2(-6, -5), 6.5, tint.lightened(0.35))
	# Feet.
	draw_circle(Vector2(-10, 16), 5.5, tint.darkened(0.16))
	draw_circle(Vector2(10, 16), 5.5, tint.darkened(0.16))
	# Eyes.
	var look := _direction * 2.3
	draw_circle(Vector2(-5.5 + look, -2), 4.7, Color.WHITE)
	draw_circle(Vector2(5.5 + look, -2), 4.7, Color.WHITE)
	draw_circle(Vector2(-4.5 + look, -1.6), 2.2, Color(0.10, 0.13, 0.12))
	draw_circle(Vector2(6.5 + look, -1.6), 2.2, Color(0.10, 0.13, 0.12))
	# Smile.
	draw_arc(Vector2(0 + look, 4.5), 4.8, 0.25, PI - 0.25, 10, Color(0.12, 0.30, 0.18), 1.8, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_bee() -> void:
	var wing_flap := 0.35 + absf(sin(_time * 17.0 + phase)) * 0.65
	# Wings.
	draw_set_transform(Vector2(-11, -12), -0.5, Vector2(wing_flap, 1.0))
	draw_circle(Vector2.ZERO, 11.0, Color(0.86, 0.96, 1.0, 0.55))
	draw_set_transform(Vector2(11, -13), 0.5, Vector2(wing_flap, 1.0))
	draw_circle(Vector2.ZERO, 9.0, Color(0.86, 0.96, 1.0, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var body_color := Color(1.0, 0.76, 0.22) if tint == Color(0.30, 0.76, 0.37) else tint
	# Stinger.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-15, 2), Vector2(-25, 5), Vector2(-14, 8)
	]), Color(0.20, 0.17, 0.12))
	draw_circle(Vector2.ZERO, 15.0, Color(0.24, 0.18, 0.10))
	draw_circle(Vector2.ZERO, 13.5, body_color)
	_draw_band(-6.0, -2.0, Color(0.17, 0.15, 0.12), 13.5)
	_draw_band(4.0, 8.0, Color(0.17, 0.15, 0.12), 13.5)
	draw_circle(Vector2(-5, -5), 4.2, Color(1.0, 0.89, 0.55, 0.8))
	# Face.
	draw_circle(Vector2(6, -2), 4.3, Color.WHITE)
	draw_circle(Vector2(7.3, -1.8), 2.1, Color(0.10, 0.12, 0.12))
	draw_circle(Vector2(7.8, -2.4), 0.7, Color.WHITE)
	# Antennae.
	draw_line(Vector2(8, -12), Vector2(13, -22), Color(0.22, 0.17, 0.10), 1.8, true)
	draw_line(Vector2(2, -12), Vector2(2, -23), Color(0.22, 0.17, 0.10), 1.8, true)
	draw_circle(Vector2(13, -22), 2.0, Color(0.22, 0.17, 0.10))
	draw_circle(Vector2(2, -23), 2.0, Color(0.22, 0.17, 0.10))


func _draw_snowball() -> void:
	var spin := _time * 2.4
	# Shadow.
	draw_set_transform(Vector2(0, 22), 0.0, Vector2(1.0, 0.30))
	draw_circle(Vector2.ZERO, 21.0, Color(0.12, 0.24, 0.34, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2.ZERO, 20.0, Color(0.62, 0.80, 0.92))
	draw_circle(Vector2(-2, -2), 17.0, Color(0.94, 0.98, 1.0))
	draw_circle(Vector2(-8, -8), 7.0, Color(1, 1, 1, 0.95))
	# Frozen crystal chunks.
	for i in 5:
		var angle := spin + float(i) * TAU / 5.0
		var center := Vector2(cos(angle), sin(angle)) * 16.0
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-4, 4), center + Vector2(0, -8), center + Vector2(4, 4)
		]), Color(0.64, 0.88, 1.0, 0.9))
	# Face.
	draw_circle(Vector2(-6, -2), 3.6, Color(0.16, 0.28, 0.40))
	draw_circle(Vector2(6, -2), 3.6, Color(0.16, 0.28, 0.40))
	draw_circle(Vector2(-5, -3), 1.2, Color.WHITE)
	draw_circle(Vector2(7, -3), 1.2, Color.WHITE)
	draw_arc(Vector2(0, 6), 5.0, 0.2, PI - 0.2, 10, Color(0.28, 0.44, 0.58), 1.6, true)


func _draw_scorpion() -> void:
	var walk := sin(_time * 12.0 + phase) * 4.0
	# Shadow.
	draw_set_transform(Vector2(0, 15), 0.0, Vector2(1.0, 0.30))
	draw_circle(Vector2.ZERO, 21.0, Color(0.16, 0.10, 0.04, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Legs.
	for i in 3:
		var lx := -8.0 + float(i) * 8.0
		draw_line(Vector2(lx, 6), Vector2(lx - 8.0 + walk, 16), Color(0.42, 0.28, 0.12), 2.4, true)
		draw_line(Vector2(lx, 6), Vector2(lx + 8.0 - walk, 16), Color(0.42, 0.28, 0.12), 2.4, true)
	# Tail and stinger.
	var tail := PackedVector2Array([
		Vector2(-12, 2), Vector2(-22, -8), Vector2(-20, -22), Vector2(-8, -28)
	])
	draw_polyline(tail, Color(0.54, 0.36, 0.16), 5.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -28), Vector2(-2, -36), Vector2(-13, -34)
	]), Color(0.80, 0.24, 0.18))
	# Body.
	draw_circle(Vector2(0, 2), 15.0, Color(0.58, 0.40, 0.18))
	draw_circle(Vector2(-2, 0), 12.0, Color(0.76, 0.56, 0.28))
	draw_line(Vector2(-8, -4), Vector2(6, 6), Color(0.48, 0.32, 0.14), 2.0, true)
	# Claws.
	draw_line(Vector2(12, 2), Vector2(22, -6), Color(0.58, 0.40, 0.18), 4.0, true)
	draw_line(Vector2(12, 5), Vector2(23, 8), Color(0.58, 0.40, 0.18), 4.0, true)
	draw_circle(Vector2(24, -7), 5.0, Color(0.64, 0.44, 0.20))
	draw_circle(Vector2(25, 9), 5.0, Color(0.64, 0.44, 0.20))
	_eyes(Vector2(5, -4), Vector2(12, -3), Color(1.0, 0.42, 0.26), 2.6)


func _draw_ghost() -> void:
	var sway := sin(_time * 2.0 + phase) * 3.0
	# Cold aura.
	draw_circle(Vector2(0, -4), 28.0, Color(0.70, 0.62, 1.0, 0.10))
	draw_circle(Vector2(0, -4), 20.0, Color(0.86, 0.84, 1.0, 0.22))
	# Body.
	draw_circle(Vector2(0, -6), 17.0, Color(0.86, 0.88, 1.0, 0.85))
	draw_circle(Vector2(-2, -9), 13.0, Color(0.96, 0.97, 1.0, 0.92))
	# Wavy tail.
	for i in 3:
		var x := -12.0 + float(i) * 12.0
		var wave := sin(_time * 5.0 + float(i) * 1.4 + phase) * 3.0
		draw_circle(Vector2(x + sway * 0.3 + wave, 12.0), 6.0 - float(i % 2), Color(0.82, 0.84, 1.0, 0.75))
	# Hollow eyes and mouth.
	draw_circle(Vector2(-6, -8), 4.2, Color(0.26, 0.20, 0.42))
	draw_circle(Vector2(7, -8), 4.2, Color(0.26, 0.20, 0.42))
	draw_circle(Vector2(-6, -8), 1.6, Color(0.82, 0.72, 1.0))
	draw_circle(Vector2(7, -8), 1.6, Color(0.82, 0.72, 1.0))
	draw_circle(Vector2(0, 2), 3.6, Color(0.40, 0.30, 0.60, 0.8))


func _draw_fire_imp() -> void:
	var flap := 0.35 + absf(sin(_time * 15.0 + phase)) * 0.65
	# Wings.
	draw_set_transform(Vector2(-10, -10), -0.4, Vector2(flap, 1.0))
	draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.46, 0.18, 0.55))
	draw_set_transform(Vector2(10, -10), 0.4, Vector2(flap, 1.0))
	draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.52, 0.20, 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Flame tuft.
	for i in 3:
		var sway := sin(_time * 7.0 + float(i) * 1.8 + phase) * 3.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(-8 + float(i) * 7.0, -14), Vector2(sway, -28 - float(i) * 3.0),
			Vector2(2 + float(i) * 7.0, -14)
		]), Color(1.0, 0.48, 0.12, 0.9))
	# Body.
	draw_circle(Vector2(0, 2), 15.0, Color(0.66, 0.14, 0.10))
	draw_circle(Vector2(0, 0), 12.5, Color(0.92, 0.32, 0.14))
	draw_circle(Vector2(-3, -4), 5.5, Color(1.0, 0.62, 0.24, 0.85))
	# Horns.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11, -11), Vector2(-16, -22), Vector2(-6, -14)
	]), Color(0.30, 0.12, 0.10))
	draw_colored_polygon(PackedVector2Array([
		Vector2(11, -11), Vector2(16, -22), Vector2(6, -14)
	]), Color(0.30, 0.12, 0.10))
	_eyes(Vector2(-5, -1), Vector2(6, -1), Color(1.0, 0.94, 0.42), 3.2)
	draw_arc(Vector2(0, 8), 4.4, 0.1, PI - 0.1, 8, Color(0.36, 0.06, 0.05), 1.6, true)


func _draw_sky_bat() -> void:
	var flap := 0.28 + absf(sin(_time * 17.0 + phase)) * 0.72
	# Wings.
	for side in [-1.0, 1.0]:
		draw_set_transform(Vector2(side * 8.0, -3.0), side * 0.35, Vector2(flap, 1.0))
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, 0), Vector2(side * 20, -14), Vector2(side * 26, 2),
			Vector2(side * 16, 10), Vector2(side * 6, 4)
		]), Color(0.34, 0.26, 0.52))
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * 2, 0), Vector2(side * 16, -8), Vector2(side * 18, 2), Vector2(side * 8, 5)
		]), Color(0.46, 0.36, 0.68))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Body.
	draw_circle(Vector2(0, 2), 13.0, Color(0.20, 0.16, 0.34))
	draw_circle(Vector2(0, 0), 10.5, Color(0.36, 0.30, 0.54))
	# Ears.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -8), Vector2(-10, -22), Vector2(-2, -11)
	]), Color(0.26, 0.20, 0.42))
	draw_colored_polygon(PackedVector2Array([
		Vector2(8, -8), Vector2(10, -22), Vector2(2, -11)
	]), Color(0.26, 0.20, 0.42))
	# Face and fangs.
	draw_circle(Vector2(-4, -1), 3.2, Color(1.0, 0.82, 0.42))
	draw_circle(Vector2(4, -1), 3.2, Color(1.0, 0.82, 0.42))
	draw_circle(Vector2(-4, -1), 1.4, Color(0.10, 0.08, 0.16))
	draw_circle(Vector2(4, -1), 1.4, Color(0.10, 0.08, 0.16))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-5, 6), Vector2(-2, 11), Vector2(0, 6)
	]), Color.WHITE)
	draw_colored_polygon(PackedVector2Array([
		Vector2(5, 6), Vector2(2, 11), Vector2(0, 6)
	]), Color.WHITE)


func _eyes(left: Vector2, right: Vector2, color: Color, radius: float = 3.0) -> void:
	for pos in [left, right]:
		draw_circle(pos, radius + 0.8, Color(0.10, 0.09, 0.08))
		draw_circle(pos, radius, color)
		draw_circle(pos + Vector2(-0.8, -0.8), radius * 0.35, Color.WHITE)


func _draw_band(y0: float, y1: float, color: Color, radius: float) -> void:
	# Draws a curved-looking stripe inside the bee's circular body.
	var top_half := sqrt(maxf(0.0, radius * radius - y0 * y0))
	var bottom_half := sqrt(maxf(0.0, radius * radius - y1 * y1))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-top_half, y0), Vector2(top_half, y0),
		Vector2(bottom_half, y1), Vector2(-bottom_half, y1),
	]), color)
