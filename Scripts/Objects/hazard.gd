## Environmental hazard for every kingdom.
## Kinds: lava, quicksand, wind, fire, moving_spike, icicle, rock, fireball.
## The node draws itself procedurally and owns one Area2D used for damage or
## zone detection. Falling hazards reuse the same Area2D and move it downwards.
extends Node2D

@export var kind := "lava"
@export var size := Vector2(160.0, 70.0)
@export var push := Vector2.ZERO
@export var target_y := 620.0
@export var fall_speed := 280.0
@export var interval := 2.0
@export var phase := 0.0
@export var travel_range := 130.0
@export var speed := 1.0
@export var theme := 0

var _time := 0.0
var _area: Area2D
var _shape: CollisionShape2D
var _rect: RectangleShape2D
var _circle: CircleShape2D
var _drop_offset := 0.0
var _drop_distance := 380.0
var _dropping := false
var _fall_timer := 1.5
var _pushing := false
var _base_x := 0.0


func _ready() -> void:
	add_to_group("hazards")
	_base_x = position.x
	_time = phase
	_build_area()
	if _is_falling():
		_drop_distance = maxf(60.0, target_y - position.y)
		_fall_timer = fposmod(phase, maxf(0.3, interval))
	queue_redraw()


func setup(info: Dictionary, world_theme: int = 0) -> void:
	if info.has("kind"):
		kind = String(info["kind"])
	size = Vector2(float(info.get("w", size.x)), float(info.get("h", size.y)))
	push = info.get("push", push)
	target_y = float(info.get("target_y", target_y))
	fall_speed = float(info.get("speed", fall_speed))
	interval = float(info.get("interval", interval))
	phase = float(info.get("phase", phase))
	travel_range = float(info.get("range", travel_range))
	speed = float(info.get("speed", speed))
	theme = world_theme
	_time = phase
	if is_inside_tree():
		_build_area()
	queue_redraw()


func _is_falling() -> bool:
	return kind == "icicle" or kind == "rock" or kind == "fireball"


func _build_area() -> void:
	if _area == null:
		_area = Area2D.new()
		_area.name = "Trigger"
		_area.collision_layer = 16
		_area.collision_mask = 1
		add_child(_area)
		_shape = CollisionShape2D.new()
		_shape.name = "Shape"
		_area.add_child(_shape)

	if _is_falling():
		if _circle == null:
			_circle = CircleShape2D.new()
		_circle.radius = clampf(size.x * 0.5, 12.0, 22.0)
		_shape.shape = _circle
		_area.position = Vector2.ZERO
	else:
		if _rect == null:
			_rect = RectangleShape2D.new()
		_rect.size = size
		_shape.shape = _rect
		_area.position = Vector2.ZERO

	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	_time += delta

	if _is_falling():
		_tick_falling(delta)
	elif kind == "moving_spike":
		_area.position.x = sin(_time * maxf(0.25, speed)) * travel_range
	elif kind == "wind":
		_apply_wind(delta)
	elif kind == "quicksand":
		_tick_quicksand()
	elif kind == "lava" or kind == "fire":
		_damage_overlaps()
	queue_redraw()


func _tick_falling(delta: float) -> void:
	if _dropping:
		_drop_offset += fall_speed * delta
		_area.position.y = _drop_offset
		if _drop_offset >= _drop_distance:
			_dropping = false
			_drop_offset = 0.0
			_area.position.y = 0.0
			_fall_timer = maxf(0.4, interval)
	else:
		_fall_timer = maxf(0.0, _fall_timer - delta)
		if _fall_timer <= 0.0:
			_dropping = true
			_drop_offset = 0.0


func _damage_overlaps() -> void:
	for body in _area.get_overlapping_bodies():
		if body.is_in_group("player"):
			var damage := 3 if kind == "lava" else 1
			body.take_damage(damage, global_position)
			break


func _apply_wind(_delta: float) -> void:
	var found := false
	for body in _area.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.call("set_wind", push)
			found = true
			break
	if _pushing and not found:
		for body in get_tree().get_nodes_in_group("player"):
			body.call("set_wind", Vector2.ZERO)
	_pushing = found


func _tick_quicksand() -> void:
	var found := false
	for body in _area.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.call("set_quicksand", true)
			found = true
			break
	if not found:
		for body in get_tree().get_nodes_in_group("player"):
			body.call("set_quicksand", false)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	match kind:
		"quicksand":
			body.call("set_quicksand", true)
		"moving_spike", "icicle", "rock", "fireball":
			body.take_damage(1, global_position)


func _on_body_exited(body: Node) -> void:
	if kind == "quicksand" and body.is_in_group("player"):
		body.call("set_quicksand", false)


# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------
func _draw() -> void:
	match kind:
		"lava":
			_draw_lava()
		"quicksand":
			_draw_quicksand()
		"wind":
			_draw_wind()
		"fire":
			_draw_fire()
		"moving_spike":
			_draw_spike_strip(_area.position.x, 0.0)
		"icicle":
			_draw_icicle()
		"rock":
			_draw_rock()
		"fireball":
			_draw_fireball()


func _draw_lava() -> void:
	var half := size * 0.5
	draw_rect(Rect2(-half, size), Color(0.32, 0.07, 0.04))
	draw_rect(Rect2(-half + Vector2(0, 6), Vector2(size.x, size.y - 6.0)), Color(0.85, 0.22, 0.05))
	draw_rect(Rect2(-half + Vector2(0, 16), Vector2(size.x, size.y - 16.0)), Color(1.0, 0.42, 0.08))
	var bubbles := maxi(3, int(size.x / 46.0))
	for i in bubbles:
		var bx := -half.x + fposmod(float(i) * 47.0 + _time * 14.0, maxf(1.0, size.x))
		var by := -half.y + 12.0 + sin(_time * 2.4 + float(i)) * 7.0
		draw_circle(Vector2(bx, by), 3.0 + fmod(float(i), 3.0), Color(1.0, 0.88, 0.36, 0.85))
	draw_rect(Rect2(-half.x, -half.y, size.x, 7.0), Color(1.0, 0.74, 0.24, 0.95))
	for i in 4:
		draw_circle(Vector2(-half.x + 30.0 + float(i) * size.x * 0.25, -half.y), 2.6, Color(1.0, 0.95, 0.66, 0.9))


func _draw_quicksand() -> void:
	var half := size * 0.5
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.52))
	draw_circle(Vector2.ZERO, half.x, Color(0.42, 0.30, 0.14))
	draw_circle(Vector2(0, 2), half.x - 10.0, Color(0.60, 0.45, 0.21))
	draw_circle(Vector2(0, 5), half.x - 24.0, Color(0.75, 0.58, 0.29))
	for i in 4:
		var angle := _time * 0.8 + float(i) * TAU / 4.0
		var radius := half.x * (0.30 + 0.16 * sin(_time * 1.4 + float(i)))
		draw_arc(Vector2(cos(angle), sin(angle)) * radius * 0.4, radius, angle, angle + 2.2, 12, Color(0.47, 0.34, 0.16, 0.7), 2.4, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in 3:
		var px := -half.x * 0.6 + fmod(_time * 18.0 + float(i) * 41.0, size.x * 0.6)
		draw_circle(Vector2(px, -6.0 + sin(_time + float(i)) * 3.0), 1.8, Color(0.90, 0.76, 0.47, 0.8))


func _draw_wind() -> void:
	var half := size * 0.5
	draw_rect(Rect2(-half, size), Color(0.72, 0.86, 1.0, 0.06))
	var streak_color := Color(0.92, 0.97, 1.0, 0.24)
	if theme == 1:
		streak_color = Color(1.0, 0.90, 0.62, 0.24)
	elif theme == 2:
		streak_color = Color(0.86, 0.96, 1.0, 0.28)
	var direction := 1.0 if push.x >= 0.0 else -1.0
	for i in 16:
		var y := -half.y + fposmod(float(i) * 61.0, maxf(1.0, size.y))
		var x := -half.x + fposmod(float(i) * 93.0 + _time * 220.0 * direction, maxf(1.0, size.x))
		var length := 26.0 + float(i % 4) * 14.0
		draw_line(Vector2(x, y), Vector2(x + length * direction, y - 2.0), streak_color, 2.0, true)
	if theme == 0:
		for i in 12:
			var px := -half.x + fposmod(float(i) * 79.0 + _time * 40.0, maxf(1.0, size.x))
			var py := -half.y + fposmod(float(i) * 53.0 + _time * 58.0, maxf(1.0, size.y))
			draw_circle(Vector2(px, py), 1.7, Color(1, 1, 1, 0.55))
	elif theme == 2:
		for i in 5:
			var cx := -half.x + fposmod(float(i) * 151.0 + _time * 30.0, maxf(1.0, size.x))
			var cy := -half.y + fposmod(float(i) * 87.0, maxf(1.0, size.y))
			draw_circle(Vector2(cx, cy), 14.0, Color(1, 1, 1, 0.10))
			draw_circle(Vector2(cx + 12.0, cy + 4.0), 10.0, Color(1, 1, 1, 0.10))


func _draw_fire() -> void:
	var half := size * 0.5
	for i in 7:
		var x := -half.x + 10.0 + float(i) * (size.x - 20.0) / 6.0
		var height := 18.0 + fmod(float(i) * 13.0 + _time * 30.0, 28.0)
		var sway := sin(_time * 5.0 + float(i)) * 5.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 8.0, half.y),
			Vector2(x + sway, half.y - height),
			Vector2(x + 8.0, half.y),
		]), Color(1.0, 0.34, 0.08, 0.88))
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 4.0, half.y),
			Vector2(x + sway * 0.6, half.y - height * 0.6),
			Vector2(x + 4.0, half.y),
		]), Color(1.0, 0.82, 0.30, 0.9))
	draw_circle(Vector2(0, half.y - 8.0), size.x * 0.36, Color(1.0, 0.44, 0.10, 0.10))


func _draw_spike_strip(offset_x: float, offset_y: float) -> void:
	var width := size.x
	var count := maxi(3, int(width / 26.0))
	var cell := width / float(count)
	var base := Vector2(offset_x, offset_y)
	draw_rect(Rect2(base + Vector2(-width * 0.5, -6.0), Vector2(width, 10.0)), Color(0.28, 0.12, 0.12))
	for i in count:
		var left := base.x - width * 0.5 + float(i) * cell
		var tip := Vector2(left + cell * 0.5, base.y - size.y)
		draw_colored_polygon(PackedVector2Array([
			Vector2(left + 2.0, base.y), tip, Vector2(left + cell - 2.0, base.y)
		]), Color(0.72, 0.22, 0.24))
		draw_line(tip, Vector2(left + cell * 0.5 + 2.0, base.y), Color(1.0, 0.66, 0.55, 0.7), 1.4, true)
	draw_circle(Vector2(base.x, base.y - 3.0), 3.0, Color(1.0, 0.35, 0.25, 0.8))


func _draw_icicle() -> void:
	var wobble := sin(_time * 7.0) * 2.0
	if not _dropping:
		# Warning glint where the icicle will fall.
		var alpha := 0.35 + 0.35 * sin(_time * 8.0)
		draw_circle(Vector2(wobble, 0), 11.0, Color(0.72, 0.92, 1.0, alpha * 0.35))
		draw_line(Vector2(wobble, -14.0), Vector2(wobble, -4.0), Color(0.86, 0.97, 1.0, alpha), 2.0, true)
		draw_colored_polygon(PackedVector2Array([
			Vector2(wobble - 9.0, 0), Vector2(wobble, -30.0), Vector2(wobble + 9.0, 0)
		]), Color(0.78, 0.92, 1.0, 0.55))
		return
	var y := _area.position.y
	draw_colored_polygon(PackedVector2Array([
		Vector2(wobble - 10.0, y - 6.0), Vector2(wobble, y + 24.0), Vector2(wobble + 10.0, y - 6.0)
	]), Color(0.72, 0.90, 1.0, 0.95))
	draw_colored_polygon(PackedVector2Array([
		Vector2(wobble - 5.0, y - 4.0), Vector2(wobble, y + 16.0), Vector2(wobble + 2.0, y - 4.0)
	]), Color(0.94, 0.99, 1.0, 0.9))
	draw_circle(Vector2(wobble, y - 8.0), 8.0, Color(0.82, 0.95, 1.0, 0.35))


func _draw_rock() -> void:
	var y := _area.position.y
	if not _dropping:
		var alpha := 0.30 + 0.30 * sin(_time * 7.0)
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 18, Color(0.95, 0.72, 0.40, alpha), 2.0, true)
		return
	draw_circle(Vector2(0, y), 19.0, Color(0.34, 0.26, 0.17))
	draw_circle(Vector2(-4, y - 4), 13.0, Color(0.52, 0.40, 0.26))
	draw_circle(Vector2(-8, y - 8), 5.0, Color(0.66, 0.53, 0.35, 0.8))
	draw_line(Vector2(-12, y + 6), Vector2(10, y + 10), Color(0.24, 0.18, 0.11), 2.0)


func _draw_fireball() -> void:
	var y := _area.position.y
	draw_circle(Vector2(0, y - 12.0), 8.0, Color(1.0, 0.36, 0.10, 0.20))
	draw_circle(Vector2(0, y - 22.0), 5.0, Color(1.0, 0.44, 0.10, 0.18))
	draw_circle(Vector2(0, y), 15.0, Color(1.0, 0.30, 0.06, 0.55))
	draw_circle(Vector2(0, y), 10.0, Color(1.0, 0.58, 0.14))
	draw_circle(Vector2(-2, y - 3), 4.5, Color(1.0, 0.92, 0.48))
	draw_circle(Vector2(3, y - 1), 2.0, Color(1, 1, 0.9, 0.9))
