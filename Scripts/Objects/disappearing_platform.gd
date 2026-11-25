## Platform that blinks and fades away on a fixed cycle, then returns.
extends StaticBody2D

@export var size := Vector2(160.0, 24.0)
@export var style := 0
@export var phase := 0.0
@export var period := 3.0 # solid, blinking and gone share this period

var _collision: CollisionShape2D
var _time := 0.0
var _solid := true


func _ready() -> void:
	add_to_group("disappearing_platforms")
	collision_layer = 2
	collision_mask = 0
	_time = phase
	_ensure_collision()
	_apply_cycle()
	queue_redraw()


func setup(new_size: Vector2, new_style: int = 0, start_phase: float = 0.0, new_period: float = 3.0) -> void:
	size = new_size
	style = new_style
	phase = start_phase
	period = maxf(1.2, new_period)
	_time = phase
	if is_inside_tree():
		_ensure_collision()
		_apply_cycle()
	queue_redraw()


func _ensure_collision() -> void:
	if _collision == null:
		_collision = CollisionShape2D.new()
		_collision.name = "CollisionShape2D"
		add_child(_collision)
	var rect := RectangleShape2D.new()
	rect.size = size
	_collision.shape = rect


func _process(delta: float) -> void:
	_time += delta
	_apply_cycle()
	queue_redraw()


func _apply_cycle() -> void:
	var t := fposmod(_time, maxf(1.0, period))
	var solid := t < period * 0.66
	if solid != _solid:
		_solid = solid
		if _collision != null:
			_collision.set_deferred("disabled", not solid)


func _draw() -> void:
	if _collision == null:
		return
	var t := fposmod(_time, maxf(1.0, period))
	var alpha := 1.0
	if t >= period * 0.66:
		alpha = 0.08
	elif t >= period * 0.52:
		alpha = 0.35 + 0.35 * sin(_time * 22.0)
	var rect := Rect2(-size * 0.5, size)
	var base := StyleBoxFlat.new()
	base.bg_color = Color(_color(), 0.80 * alpha)
	base.border_color = Color(_color().darkened(0.34), alpha)
	base.set_border_width_all(2)
	base.set_corner_radius_all(8)
	draw_style_box(base, rect)
	draw_rect(Rect2(rect.position + Vector2(5, 3), Vector2(size.x - 10.0, 4.0)), Color(1.0, 1.0, 1.0, 0.40 * alpha))
	for i in 3:
		var x := -size.x * 0.28 + float(i) * size.x * 0.28
		draw_circle(Vector2(x, 0), 2.4, Color(_color().lightened(0.55), 0.8 * alpha))
	# Ghostly outline showing where the platform will return.
	if alpha < 0.2:
		draw_rect(rect, Color(_color(), 0.16), false, 2.0)


func _color() -> Color:
	match style:
		3:
			return Color(0.66, 0.88, 1.0)
		4:
			return Color(0.86, 0.70, 0.42)
		5:
			return Color(0.52, 0.44, 0.66)
		6:
			return Color(0.78, 0.36, 0.22)
		7:
			return Color(0.90, 0.96, 1.0)
		_:
			return Color(0.72, 0.86, 0.58)
