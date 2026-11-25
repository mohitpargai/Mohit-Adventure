## Mohit, the playable explorer. Handles keyboard/touch movement, jumping,
## coyote time, variable jump height, damage, invulnerability and respawning.
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died
signal damaged
signal jumped
signal landed
signal powerup_gained(kind: int)

const MAX_HEALTH := 3
const SHIELD_DURATION := 9.0
const SPEED_DURATION := 9.0
const SPEED_MULTIPLIER := 1.45
const BURST_SCENE := preload("res://Scenes/BurstEffect.tscn")

@export var move_speed := 340.0
@export var acceleration := 2400.0
@export var air_acceleration := 1700.0
@export var friction := 2700.0
@export var gravity := 1900.0
@export var max_fall_speed := 1050.0
@export var jump_velocity := -690.0
@export var coyote_time := 0.12
@export var jump_buffer_time := 0.13

var health := MAX_HEALTH
var facing := 1
var alive := true
var controllable := true
var invulnerable_time := 0.0
var kill_y := 1600.0
var spawn_position := Vector2.ZERO

# --- Power-ups and environment ---------------------------------------------
var shield_time := 0.0
var speed_time := 0.0
var in_quicksand := false
var wind_force := Vector2.ZERO
var surface_style := 0
var _wind_decay := 0.0

var _coyote := 0.0
var _jump_buffer := 0.0
var _control_lock := 0.0
var _was_on_floor := true
var _fall_speed := 0.0
var _shake := 0.0
var _shake_strength := 0.0

@onready var visual: Node2D = $Visual
@onready var camera: Camera2D = $Camera2D
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("player")
	health = MAX_HEALTH
	health_changed.emit(health, MAX_HEALTH)
	camera.position_smoothing_enabled = true


func _physics_process(delta: float) -> void:
	_tick_invulnerability(delta)
	_tick_status(delta)

	if not alive:
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		move_and_slide()
		return

	_control_lock = maxf(0.0, _control_lock - delta)
	var direction := 0.0
	if controllable and _control_lock <= 0.0:
		direction = Input.get_axis("move_left", "move_right")

	var speed_scale := SPEED_MULTIPLIER if speed_time > 0.0 else 1.0
	if in_quicksand:
		speed_scale *= 0.45
	var target_speed := move_speed * speed_scale
	var slippery := is_on_floor() and surface_style == 3
	var sandy := is_on_floor() and surface_style == 4

	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
		var accel := acceleration if is_on_floor() else air_acceleration
		if slippery:
			accel *= 0.45
		if in_quicksand:
			accel *= 0.7
		velocity.x = move_toward(velocity.x, direction * target_speed, accel * delta)
	else:
		var stop_force := friction
		if slippery:
			stop_force *= 0.16
		elif sandy:
			stop_force *= 0.72
		velocity.x = move_toward(velocity.x, 0.0, stop_force * delta)

	# Coyote time and jump buffering make touch controls feel responsive.
	if is_on_floor():
		_coyote = coyote_time
	else:
		_coyote = maxf(0.0, _coyote - delta)

	if controllable and _control_lock <= 0.0 and Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer_time
	else:
		_jump_buffer = maxf(0.0, _jump_buffer - delta)

	if _jump_buffer > 0.0 and _coyote > 0.0:
		_jump()

	# Short taps give a lower jump, holding gives full height.
	if Input.is_action_just_released("jump") and velocity.y < -260.0:
		velocity.y = -260.0

	# Environmental push from wind zones. Hazards refresh this every frame.
	if wind_force != Vector2.ZERO:
		velocity += wind_force * delta * 4.2
		wind_force = wind_force.move_toward(Vector2.ZERO, 320.0 * delta)
	if in_quicksand and is_on_floor():
		velocity.y += 230.0 * delta

	_fall_speed = velocity.y
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	move_and_slide()
	_detect_surface()

	if is_on_floor() and not _was_on_floor and _fall_speed > 260.0:
		visual.call("squash_land")
		_spawn_dust(7)
		landed.emit()
	_was_on_floor = is_on_floor()

	if global_position.y > kill_y:
		die()


func _process(delta: float) -> void:
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 2.7)
		camera.offset = Vector2(
			randf_range(-1.0, 1.0) * _shake_strength * _shake,
			randf_range(-1.0, 1.0) * _shake_strength * _shake
		)
	else:
		camera.offset = camera.offset.lerp(Vector2.ZERO, 10.0 * delta)


func _tick_invulnerability(delta: float) -> void:
	if invulnerable_time > 0.0:
		invulnerable_time = maxf(0.0, invulnerable_time - delta)
		var blink := int(invulnerable_time * 14.0) % 2
		visual.modulate.a = 0.35 if blink == 0 else 1.0
	else:
		visual.modulate.a = 1.0


func _jump() -> void:
	velocity.y = jump_velocity * (0.62 if in_quicksand else 1.0)
	_coyote = 0.0
	_jump_buffer = 0.0
	visual.call("stretch_jump")
	AudioManager.play_sfx("jump")
	jumped.emit()


func _tick_status(delta: float) -> void:
	shield_time = maxf(0.0, shield_time - delta)
	speed_time = maxf(0.0, speed_time - delta)


func _detect_surface() -> void:
	surface_style = 0
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision.get_normal().y < -0.55:
			var collider := collision.get_collider()
			if collider != null and collider.get("style") != null:
				surface_style = int(collider.get("style"))
				return


## Called by PowerUp nodes through the level builder.
func apply_powerup(kind: int) -> void:
	match kind:
		0:
			shield_time = maxf(shield_time, SHIELD_DURATION)
			_spawn_burst(Color(0.44, 0.82, 1.0), 14, global_position + Vector2(0, -16))
		1:
			speed_time = maxf(speed_time, SPEED_DURATION)
			_spawn_burst(Color(1.0, 0.86, 0.36), 12, global_position + Vector2(0, -16))
		3:
			heal(1)
			_spawn_burst(Color(0.52, 1.0, 0.62), 12, global_position + Vector2(0, -16))
	powerup_gained.emit(kind)


func set_wind(force: Vector2) -> void:
	wind_force = force


func set_quicksand(active: bool) -> void:
	in_quicksand = active


func has_shield() -> bool:
	return shield_time > 0.0


func has_speed() -> bool:
	return speed_time > 0.0


func bounce() -> void:
	velocity.y = -500.0
	_coyote = 0.0
	visual.call("stretch_jump")


func take_damage(amount: int = 1, source_position: Vector2 = Vector2.ZERO) -> bool:
	if not alive or invulnerable_time > 0.0:
		return false
	if shield_time > 0.0:
		# The shield absorbs the hit and flickers, but keeps Mohit safe.
		invulnerable_time = 0.75
		_shake = 0.6
		_shake_strength = 4.5
		AudioManager.play_sfx("shield")
		_spawn_burst(Color(0.46, 0.84, 1.0), 14, global_position + Vector2(0, -12))
		return false
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	damaged.emit()
	invulnerable_time = 1.25
	_shake = 1.0
	_shake_strength = 7.0
	AudioManager.play_sfx("hurt")
	_spawn_burst(Color(1.0, 0.34, 0.28), 10, global_position + Vector2(0, -10))

	var away := signf(global_position.x - source_position.x)
	if away == 0.0:
		away = -float(facing)
	velocity = Vector2(away * 330.0, -390.0)
	_control_lock = 0.3

	if health <= 0:
		die()
	return true


func heal(amount: int) -> void:
	health = clampi(health + amount, 0, MAX_HEALTH)
	health_changed.emit(health, MAX_HEALTH)


func die() -> void:
	if not alive:
		return
	alive = false
	controllable = false
	velocity = Vector2(0.0, -380.0)
	set_deferred("collision_layer", 0)
	health = 0
	health_changed.emit(health, MAX_HEALTH)
	died.emit()


func respawn(at_position: Vector2) -> void:
	global_position = at_position
	velocity = Vector2.ZERO
	collision_layer = 1
	health = MAX_HEALTH
	alive = true
	controllable = true
	invulnerable_time = 1.1
	_control_lock = 0.0
	_was_on_floor = true
	_shake = 0.0
	in_quicksand = false
	wind_force = Vector2.ZERO
	surface_style = 0
	camera.offset = Vector2.ZERO
	camera.reset_smoothing()
	health_changed.emit(health, MAX_HEALTH)


func set_controllable(value: bool) -> void:
	controllable = value
	if not value:
		velocity.x = 0.0


func setup_camera(limits: Rect2) -> void:
	camera.limit_left = int(limits.position.x)
	camera.limit_top = int(limits.position.y)
	camera.limit_right = int(limits.position.x + limits.size.x)
	camera.limit_bottom = int(limits.position.y + limits.size.y)
	camera.reset_smoothing()


func get_visual_anchor_y() -> float:
	return 28.0


func is_invulnerable() -> bool:
	return invulnerable_time > 0.0


func _spawn_dust(amount: int) -> void:
	var effect = BURST_SCENE.instantiate()
	effect.color = Color(0.95, 0.92, 0.80, 0.9)
	effect.particle_count = amount
	effect.lifetime = 0.4
	effect.start_speed = 100.0
	effect.gravity = 150.0
	effect.particle_size = 4.0
	effect.spread = 160.0
	effect.global_position = global_position + Vector2(0, 27)
	_get_world().add_child(effect)


func _spawn_burst(color: Color, amount: int, at: Vector2) -> void:
	var effect = BURST_SCENE.instantiate()
	effect.color = color
	effect.particle_count = amount
	effect.start_speed = 210.0
	effect.particle_size = 5.0
	effect.global_position = at
	_get_world().add_child(effect)


func _get_world() -> Node:
	return get_parent() if get_parent() != null else self
