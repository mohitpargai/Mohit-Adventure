## Reusable, lightweight shape-particle burst used for coin pops, dust,
## stomps and level-finish sparkles.
extends Node2D

var color := Color(1.0, 0.82, 0.34)
var particle_count := 12
var lifetime := 0.55
var start_speed := 170.0
var gravity := 360.0
var particle_size := 5.0
var spread := 360.0

var _particles: Array = []
var _age := 0.0


func _ready() -> void:
	z_index = 20
	var rng := RandomNumberGenerator.new()
	rng.seed = randi()
	for i in particle_count:
		var angle := rng.randf_range(0.0, TAU)
		if spread < 300.0:
			angle = rng.randf_range(-PI, 0.0)
		var speed := rng.randf_range(start_speed * 0.35, start_speed)
		_particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"size": particle_size * rng.randf_range(0.5, 1.25),
			"spin": rng.randf_range(-6.0, 6.0),
		})


func _process(delta: float) -> void:
	_age += delta
	var fade := clampf(1.0 - _age / lifetime, 0.0, 1.0)
	for p in _particles:
		p["vel"].y += gravity * delta
		p["pos"] += p["vel"] * delta
		p["vel"] *= 1.0 - delta * 0.8
	queue_redraw()
	if _age >= lifetime:
		queue_free()
	modulate.a = fade


func _draw() -> void:
	var fade := clampf(1.0 - _age / lifetime, 0.0, 1.0)
	for p in _particles:
		var draw_color := Color(color, fade)
		draw_circle(p["pos"], p["size"] * (0.5 + fade * 0.5), draw_color)
