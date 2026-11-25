## One reusable boss with six distinct looks and attack patterns.
## Ground bosses walk and hop, flyers hover and drift. Every boss can be
## damaged by stomping it from above and shoots themed projectiles.
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal defeated(at: Vector2)

const GRAVITY := 1850.0
const BOSS_PROJECTILE_SCENE := preload("res://Scenes/BossProjectile.tscn")
const BURST_SCENE := preload("res://Scenes/BurstEffect.tscn")

@export var world := 0
@export var max_hp := 6
@export var arena := Rect2(0.0, 0.0, 1700.0, 1250.0)

var hp := 6
var active := true
var grounded := true
var player: Node = null

var _time := 0.0
var _attack_timer := 1.8
var _special_timer := 3.5
var _hop_timer := 2.0
var _dash_time := 0.0
var _invulnerable := 0.0
var _hitbox: Area2D
var _body_shape: CollisionShape2D


func _ready() -> void:
	add_to_group("bosses")
	z_index = 4
	collision_layer = 8
	collision_mask = 2
	hp = maxi(1, max_hp)
	grounded = world != 4 and world != 5
	if not grounded:
		collision_mask = 0
	_create_shapes()
	_attack_timer = 1.6
	_special_timer = 3.0
	_time = fmod(position.x * 0.01, TAU)
	queue_redraw()


func setup(world_index: int, hp_value: int, arena_rect: Rect2) -> void:
	world = clampi(world_index, 0, 5)
	max_hp = maxi(1, hp_value)
	hp = max_hp
	arena = arena_rect


func _create_shapes() -> void:
	var body := CollisionShape2D.new()
	body.name = "BodyShape"
	if grounded:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(86.0, 118.0)
		body.shape = rect
		body.position = Vector2(0, 4.0)
	else:
		var circle := CircleShape2D.new()
		circle.radius = 52.0
		body.shape = circle
		body.position = Vector2(0, 0)
	add_child(body)
	_body_shape = body

	_hitbox = Area2D.new()
	_hitbox.name = "Hitbox"
	_hitbox.collision_layer = 8
	_hitbox.collision_mask = 1
	var hit_shape := CollisionShape2D.new()
	var hit_circle := CircleShape2D.new()
	hit_circle.radius = 74.0
	hit_shape.shape = hit_circle
	hit_shape.position = Vector2(0, -6.0)
	_hitbox.add_child(hit_shape)
	add_child(_hitbox)
	_hitbox.body_entered.connect(_on_hitbox_body_entered)


func _physics_process(delta: float) -> void:
	if not active:
		return
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(player):
			return
	_time += delta
	_invulnerable = maxf(0.0, _invulnerable - delta)
	_attack_timer -= delta
	_special_timer -= delta

	if grounded:
		_move_grounded(delta)
	else:
		_move_flying(delta)

	if _attack_timer <= 0.0:
		_attack()
		_attack_timer = maxf(1.0, 2.2 - float(world) * 0.12)
	queue_redraw()


func _move_grounded(delta: float) -> void:
	velocity.y = minf(velocity.y + GRAVITY * delta, 1100.0)
	velocity.x = 0.0
	var dx: float = player.global_position.x - global_position.x
	var target_speed := 70.0 + float(world) * 12.0
	if absf(dx) > 120.0:
		velocity.x = signf(dx) * target_speed

	if world == 1 or world == 2:
		if _special_timer <= 0.0:
			_dash_time = 0.85
			_special_timer = 3.8
		if _dash_time > 0.0:
			_dash_time -= delta
			velocity.x = signf(dx) * 360.0

	_hop_timer -= delta
	if _hop_timer <= 0.0 and is_on_floor():
		velocity.y = -560.0
		_hop_timer = 2.4 if world < 3 else 1.7

	move_and_slide()
	global_position.x = clampf(global_position.x, arena.position.x + 110.0, arena.end.x - 110.0)


func _move_flying(delta: float) -> void:
	var target := Vector2(
		clampf(player.global_position.x + sin(_time * 0.7) * 200.0, arena.position.x + 170.0, arena.end.x - 170.0),
		arena.position.y + 330.0 + sin(_time * 1.3 + 0.6) * 62.0
	)
	global_position = global_position.lerp(target, clampf(delta * 1.5, 0.0, 1.0))
	if world == 5 and _special_timer <= 0.0:
		_special_timer = 4.5
		global_position.x = clampf(player.global_position.x - signf(player.global_position.x - global_position.x) * 260.0, arena.position.x + 180.0, arena.end.x - 180.0)


func _on_hitbox_body_entered(body: Node) -> void:
	if not active or _invulnerable > 0.0 or not body.is_in_group("player"):
		return
	var player_body := body
	var stomped: bool = player_body.velocity.y > 60.0 and player_body.global_position.y < global_position.y - 20.0
	if stomped:
		player_body.call("bounce")
		take_damage(1)
	else:
		player_body.take_damage(1, global_position)


func take_damage(amount: int) -> void:
	if not active or _invulnerable > 0.0:
		return
	hp = maxi(0, hp - amount)
	_invulnerable = 0.65
	AudioManager.play_sfx("boss_hit")
	health_changed.emit(hp, max_hp)
	var burst = BURST_SCENE.instantiate()
	burst.color = WorldData.accent(world).lightened(0.2)
	burst.particle_count = 12
	burst.start_speed = 200.0
	burst.particle_size = 4.5
	burst.global_position = global_position + Vector2(0, -16)
	get_parent().add_child(burst)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.35, 0.06)
	tween.tween_property(self, "modulate:a", 1.0, 0.16)
	if hp <= 0:
		_die()


func _die() -> void:
	active = false
	set_deferred("collision_layer", 0)
	if _hitbox != null:
		_hitbox.set_deferred("monitoring", false)
	AudioManager.play_sfx("boss_defeat")
	health_changed.emit(0, max_hp)
	defeated.emit(global_position)
	var burst = BURST_SCENE.instantiate()
	burst.color = WorldData.accent(world)
	burst.particle_count = 34
	burst.start_speed = 320.0
	burst.particle_size = 7.0
	burst.global_position = global_position
	get_parent().add_child(burst)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.4, 0.2), 0.55)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_property(self, "rotation", 0.5, 0.6)


# ---------------------------------------------------------------------------
# Attacks
# ---------------------------------------------------------------------------
func _attack() -> void:
	if not is_instance_valid(player):
		return
	var toward: Vector2 = (player.global_position - global_position).normalized()
	match world:
		0:
			AudioManager.play_sfx("boss_shot")
			_shoot("orb", Vector2.LEFT, 250.0)
			_shoot("orb", Vector2.RIGHT, 250.0)
		1:
			AudioManager.play_sfx("boss_shot")
			for i in 3:
				var angle: float = toward.angle() + (float(i) - 1.0) * 0.22
				_shoot("icicle", Vector2.from_angle(angle), 330.0)
		2:
			AudioManager.play_sfx("boss_shot")
			_shoot("rock", Vector2(toward.x * 0.8, -0.9), 300.0, 620.0)
			_shoot("rock", Vector2(toward.x * 0.5 + 0.3, -1.0), 260.0, 620.0)
		3:
			AudioManager.play_sfx("boss_shot")
			global_position.x = clampf(
				player.global_position.x + (300.0 if player.global_position.x < global_position.x else -300.0),
				arena.position.x + 130.0, arena.end.x - 130.0
			)
			for i in 5:
				_shoot("dark", Vector2.from_angle(TAU * float(i) / 5.0), 240.0)
		4:
			AudioManager.play_sfx("boss_shot")
			for i in 5:
				_shoot("fireball", Vector2((-1.0 + float(i) * 0.5) * 0.7, 0.9), 280.0)
		5:
			AudioManager.play_sfx("boss_shot")
			for i in 7:
				_shoot("dark", Vector2.from_angle(TAU * float(i) / 7.0 + _time * 0.2), 220.0)
		_:
			_shoot("orb", toward, 260.0)


func _shoot(kind: String, direction: Vector2, speed: float, gravity: float = 0.0) -> void:
	var shot = BOSS_PROJECTILE_SCENE.instantiate()
	shot.position = global_position + Vector2(0, -18)
	shot.setup(kind, direction.normalized() * speed, world, gravity)
	get_parent().add_child(shot)


# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------
func _draw() -> void:
	var bob := sin(_time * 2.4) * 4.0
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	# Ground shadow.
	draw_set_transform(Vector2(0, 56), 0.0, Vector2(1.0, 0.28))
	draw_circle(Vector2.ZERO, 52.0, Color(0.02, 0.04, 0.06, 0.28))
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	match world:
		0:
			_draw_forest_guardian()
		1:
			_draw_ice_monster()
		2:
			_draw_desert_king()
		3:
			_draw_shadow_knight()
		4:
			_draw_lava_dragon()
		_:
			_draw_dark_lord()
	_draw_damage_marks()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_damage_marks() -> void:
	if hp > max_hp / 2:
		return
	for i in 3:
		var x := -34.0 + float(i) * 30.0
		var y := -46.0 + float(i % 2) * 26.0
		draw_line(Vector2(x, y), Vector2(x + 12.0, y + 14.0), Color(1.0, 0.42, 0.26, 0.75), 2.0, true)
		draw_line(Vector2(x + 12.0, y), Vector2(x, y + 12.0), Color(1.0, 0.42, 0.26, 0.55), 2.0, true)


func _eyes(left: Vector2, right: Vector2, color: Color, radius: float = 4.2) -> void:
	for pos in [left, right]:
		draw_circle(pos, radius, Color(0.05, 0.05, 0.06))
		draw_circle(pos, radius * 0.74, color)
		draw_circle(pos + Vector2(-1, -1), radius * 0.28, Color.WHITE)


func _draw_forest_guardian() -> void:
	# Roots and trunk.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-52, 54), Vector2(-24, -28), Vector2(20, -30), Vector2(52, 54)
	]), Color(0.30, 0.20, 0.11))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-40, 54), Vector2(-50, 66), Vector2(-10, 58)
	]), Color(0.24, 0.16, 0.09))
	draw_colored_polygon(PackedVector2Array([
		Vector2(38, 54), Vector2(52, 66), Vector2(12, 58)
	]), Color(0.24, 0.16, 0.09))
	# Branch arms.
	draw_line(Vector2(-30, 8), Vector2(-76, -16), Color(0.30, 0.20, 0.11), 13.0, true)
	draw_line(Vector2(30, 8), Vector2(76, -16), Color(0.30, 0.20, 0.11), 13.0, true)
	draw_line(Vector2(-76, -16), Vector2(-92, -38), Color(0.30, 0.20, 0.11), 8.0, true)
	draw_line(Vector2(76, -16), Vector2(92, -38), Color(0.30, 0.20, 0.11), 8.0, true)
	# Leafy crown.
	for i in 9:
		var angle := TAU * float(i) / 9.0
		var center := Vector2(cos(angle) * 38.0, -72.0 + sin(angle) * 26.0)
		draw_circle(center, 24.0, Color(0.18, 0.48, 0.24))
		draw_circle(center + Vector2(-5, -5), 15.0, Color(0.29, 0.66, 0.33))
	draw_circle(Vector2(0, -70), 34.0, Color(0.20, 0.54, 0.27))
	draw_circle(Vector2(-10, -79), 20.0, Color(0.34, 0.72, 0.36))
	_eyes(Vector2(-16, -14), Vector2(16, -14), Color(1.0, 0.86, 0.32), 5.2)
	# Angry wooden mouth.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, 18), Vector2(16, 18), Vector2(0, 34)
	]), Color(0.12, 0.08, 0.05))
	draw_circle(Vector2(0, 46), 7.0, Color(0.78, 0.58, 1.0, 0.35))


func _draw_ice_monster() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-58, 56), Vector2(-44, -22), Vector2(-16, -58), Vector2(18, -54),
		Vector2(48, -18), Vector2(58, 56),
	]), Color(0.42, 0.66, 0.84))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-34, 50), Vector2(-26, -26), Vector2(-4, -48), Vector2(26, -14), Vector2(32, 50)
	]), Color(0.64, 0.86, 0.98))
	# Jagged ice spikes on the back.
	for i in 5:
		var x := -46.0 + float(i) * 23.0
		var height := 30.0 + float(i % 3) * 16.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 8, -22), Vector2(x, -22 - height), Vector2(x + 8, -22)
		]), Color(0.76, 0.94, 1.0))
	# Arms.
	draw_line(Vector2(-42, 4), Vector2(-74, 32), Color(0.50, 0.74, 0.90), 14.0, true)
	draw_line(Vector2(42, 4), Vector2(74, 32), Color(0.50, 0.74, 0.90), 14.0, true)
	draw_circle(Vector2(-78, 36), 10.0, Color(0.66, 0.88, 1.0))
	draw_circle(Vector2(78, 36), 10.0, Color(0.66, 0.88, 1.0))
	_eyes(Vector2(-18, -12), Vector2(18, -12), Color(0.54, 0.94, 1.0), 5.4)
	# Frozen mouth.
	draw_rect(Rect2(-16, 16, 32, 8), Color(0.18, 0.36, 0.52))
	for i in 3:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-14 + float(i) * 12, 16), Vector2(-8 + float(i) * 12, 27), Vector2(-2 + float(i) * 12, 16)
		]), Color(0.90, 0.98, 1.0))


func _draw_desert_king() -> void:
	# Sandstone body.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-54, 56), Vector2(-44, -16), Vector2(-20, -42), Vector2(20, -42),
		Vector2(46, -14), Vector2(56, 56)
	]), Color(0.74, 0.56, 0.29))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-34, 54), Vector2(-30, -10), Vector2(0, -32), Vector2(32, -8), Vector2(38, 54)
	]), Color(0.90, 0.72, 0.42))
	# Golden chest plate.
	draw_rect(Rect2(-26, 2, 52, 34), Color(0.94, 0.76, 0.30))
	draw_circle(Vector2(0, 18), 8.0, Color(0.36, 0.62, 0.86))
	# Arms.
	draw_line(Vector2(-42, 0), Vector2(-72, 26), Color(0.80, 0.62, 0.34), 14.0, true)
	draw_line(Vector2(42, 0), Vector2(72, 26), Color(0.80, 0.62, 0.34), 14.0, true)
	draw_circle(Vector2(-76, 30), 10.0, Color(0.90, 0.72, 0.42))
	draw_circle(Vector2(76, 30), 10.0, Color(0.90, 0.72, 0.42))
	# Turban and crown jewel.
	draw_circle(Vector2(0, -48), 28.0, Color(0.88, 0.68, 0.30))
	draw_circle(Vector2(-8, -54), 18.0, Color(0.98, 0.82, 0.44))
	draw_circle(Vector2(0, -58), 6.0, Color(0.38, 0.70, 0.92))
	for i in 5:
		draw_circle(Vector2(-18 + float(i) * 9.0, -70.0), 3.4, Color(1.0, 0.88, 0.44))
	_eyes(Vector2(-16, -12), Vector2(16, -12), Color(1.0, 0.72, 0.24), 4.8)
	draw_rect(Rect2(-18, 16, 36, 8), Color(0.36, 0.24, 0.12))
	for i in 3:
		draw_rect(Rect2(-13 + float(i) * 11.0, 16, 5, 9), Color(0.98, 0.90, 0.62))


func _draw_shadow_knight() -> void:
	# Cape.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-38, -20), Vector2(40, -18), Vector2(58, 58), Vector2(-56, 58)
	]), Color(0.18, 0.09, 0.28))
	# Armour.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-36, 56), Vector2(-34, -22), Vector2(0, -44), Vector2(34, -22), Vector2(36, 56)
	]), Color(0.20, 0.20, 0.29))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-20, 54), Vector2(-18, -18), Vector2(0, -34), Vector2(18, -18), Vector2(20, 54)
	]), Color(0.34, 0.33, 0.46))
	# Helmet.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-24, -42), Vector2(-18, -68), Vector2(18, -68), Vector2(24, -42), Vector2(16, -30), Vector2(-16, -30)
	]), Color(0.16, 0.15, 0.24))
	draw_rect(Rect2(-18, -48, 36, 8), Color(0.08, 0.07, 0.13))
	_eyes(Vector2(-9, -44), Vector2(9, -44), Color(1.0, 0.22, 0.26), 3.8)
	# Sword.
	draw_line(Vector2(44, 4), Vector2(88, -56), Color(0.66, 0.70, 0.80), 8.0, true)
	draw_line(Vector2(44, 4), Vector2(52, 12), Color(0.34, 0.26, 0.20), 10.0, true)
	draw_line(Vector2(66, -26), Vector2(84, -20), Color(0.86, 0.68, 0.30), 5.0, true)
	# Glowing chest rune.
	draw_circle(Vector2(0, 20), 8.0, Color(0.60, 0.24, 1.0, 0.30))
	draw_circle(Vector2(0, 20), 4.0, Color(0.82, 0.58, 1.0))


func _draw_lava_dragon() -> void:
	# Wings.
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * 22, -10), Vector2(side * 104, -66),
			Vector2(side * 88, -4), Vector2(side * 96, 42), Vector2(side * 36, 18)
		]), Color(0.46, 0.13, 0.10))
		draw_colored_polygon(PackedVector2Array([
			Vector2(side * 30, -8), Vector2(side * 92, -54), Vector2(side * 76, -2), Vector2(side * 40, 12)
		]), Color(0.78, 0.24, 0.10))
	# Tail.
	draw_line(Vector2(0, 40), Vector2(-30, 72), Color(0.60, 0.18, 0.10), 12.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-30, 66), Vector2(-52, 80), Vector2(-26, 84)
	]), Color(0.92, 0.48, 0.14))
	# Body.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-34, 52), Vector2(-28, -6), Vector2(0, -34), Vector2(30, -6), Vector2(36, 52)
	]), Color(0.52, 0.16, 0.11))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, 46), Vector2(-14, -4), Vector2(0, -24), Vector2(16, -4), Vector2(20, 46)
	]), Color(0.82, 0.30, 0.14))
	# Head.
	draw_circle(Vector2(0, -46), 26.0, Color(0.64, 0.20, 0.12))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18, -56), Vector2(-8, -80), Vector2(-2, -58)
	]), Color(0.34, 0.10, 0.08))
	draw_colored_polygon(PackedVector2Array([
		Vector2(18, -56), Vector2(8, -80), Vector2(2, -58)
	]), Color(0.34, 0.10, 0.08))
	_eyes(Vector2(-10, -48), Vector2(10, -48), Color(1.0, 0.86, 0.26), 4.2)
	# Mouth glow.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, -34), Vector2(14, -34), Vector2(0, -22)
	]), Color(1.0, 0.58, 0.12))
	draw_circle(Vector2(0, -30), 5.0, Color(1.0, 0.92, 0.46, 0.85))
	# Lava cracks.
	for i in 3:
		var x := -22.0 + float(i) * 22.0
		draw_line(Vector2(x, 0), Vector2(x + 6.0, 16.0), Color(1.0, 0.52, 0.12, 0.8), 2.4, true)
		draw_line(Vector2(x + 6.0, 16.0), Vector2(x - 2.0, 32.0), Color(1.0, 0.52, 0.12, 0.6), 2.0, true)


func _draw_dark_lord() -> void:
	# Floating cloak.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -56), Vector2(40, -18), Vector2(56, 62), Vector2(28, 50),
		Vector2(0, 66), Vector2(-28, 50), Vector2(-56, 62), Vector2(-40, -18)
	]), Color(0.13, 0.05, 0.22))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -50), Vector2(30, -12), Vector2(38, 50), Vector2(12, 40),
		Vector2(0, 54), Vector2(-12, 40), Vector2(-38, 50), Vector2(-30, -12)
	]), Color(0.24, 0.09, 0.40))
	# Hood.
	draw_circle(Vector2(0, -50), 30.0, Color(0.10, 0.04, 0.18))
	draw_circle(Vector2(0, -46), 22.0, Color(0.26, 0.10, 0.42))
	_eyes(Vector2(-10, -50), Vector2(10, -50), Color(1.0, 0.28, 0.42), 4.0)
	# Crown.
	for i in 5:
		var x := -20.0 + float(i) * 10.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 4, -72), Vector2(x, -86), Vector2(x + 4, -72)
		]), Color(0.72, 0.46, 1.0))
	draw_rect(Rect2(-24, -74, 48, 5), Color(0.52, 0.28, 0.82))
	# Hands holding a storm orb.
	draw_circle(Vector2(0, 20), 20.0, Color(0.46, 0.16, 0.72, 0.20))
	draw_circle(Vector2(0, 20), 12.0, Color(0.62, 0.30, 0.94))
	draw_circle(Vector2(-3, 16), 5.0, Color(0.90, 0.76, 1.0, 0.9))
	for i in 4:
		var angle := _time * 1.8 + float(i) * TAU / 4.0
		draw_circle(Vector2(cos(angle) * 26.0, 20.0 + sin(angle) * 12.0), 2.6, Color(0.88, 0.70, 1.0, 0.85))
