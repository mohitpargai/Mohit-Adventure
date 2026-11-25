## Draws Mohit with primitive shapes and animates him procedurally.
## The node sits at the player's feet, which keeps squash/stretch anchored.
extends Node2D

var player
var _time := 0.0
var _run_phase := 0.0
var _squash := 0.0
var _stretch := 0.0

const SKIN := Color(0.949, 0.725, 0.549)
const SKIN_DARK := Color(0.82, 0.58, 0.42)
const HAIR := Color(0.33, 0.20, 0.13)
const CAP := Color(0.18, 0.55, 0.35)
const CAP_LIGHT := Color(0.37, 0.79, 0.45)
const SHIRT := Color(1.0, 0.45, 0.20)
const SHIRT_DARK := Color(0.84, 0.31, 0.11)
const SCARF := Color(0.17, 0.72, 0.67)
const PANTS := Color(0.18, 0.31, 0.45)
const SHOES := Color(0.13, 0.15, 0.20)
const PACK := Color(0.55, 0.31, 0.15)
const PACK_DARK := Color(0.39, 0.20, 0.09)
const EYE := Color(0.12, 0.15, 0.18)
const GOLD := Color(1.0, 0.79, 0.29)


func _ready() -> void:
	player = get_parent()
	z_index = 2


func _process(delta: float) -> void:
	_time += delta
	if not is_instance_valid(player):
		return

	var speed: float = absf(player.velocity.x)
	if player.is_on_floor() and speed > 18.0:
		_run_phase += speed * delta * 0.055
	elif player.is_on_floor():
		_run_phase = lerpf(_run_phase, 0.0, delta * 6.0)

	_squash = move_toward(_squash, 0.0, delta * 2.8)
	_stretch = move_toward(_stretch, 0.0, delta * 3.2)

	var bob := sin(_time * 2.2) * 1.1 if player.is_on_floor() and speed < 18.0 else 0.0
	var body_scale := 1.0 - _squash * 0.34 + _stretch * 0.24
	var body_width := 1.0 + _squash * 0.34 - _stretch * 0.15
	scale = Vector2(float(player.facing) * body_width, body_scale)
	position.y = player.get_visual_anchor_y() + bob + (7.0 if player.in_quicksand else 0.0)
	queue_redraw()


func squash_land() -> void:
	_squash = 0.65
	_stretch = 0.0


func stretch_jump() -> void:
	_stretch = 0.8
	_squash = 0.0


func _draw() -> void:
	if not is_instance_valid(player):
		return

	var on_floor: bool = player.is_on_floor()
	var speed: float = absf(player.velocity.x)
	var running := on_floor and speed > 18.0
	var rising: bool = not on_floor and player.velocity.y < -20.0
	var falling: bool = not on_floor and player.velocity.y >= -20.0

	# Shield bubble.
	if player.shield_time > 0.0:
		var pulse := 0.5 + 0.5 * sin(_time * 5.0)
		var fading := clampf(player.shield_time, 0.0, 1.0)
		draw_circle(Vector2(0, -28), 33.0 + pulse * 2.0, Color(0.40, 0.78, 1.0, 0.10 * fading))
		draw_arc(Vector2(0, -28), 31.0 + pulse * 2.0, 0.0, TAU, 32, Color(0.58, 0.90, 1.0, 0.55 * fading), 2.4, true)
		draw_circle(Vector2(-14, -46), 3.0, Color(1, 1, 1, 0.55 * fading))

	# Speed streaks.
	if player.speed_time > 0.0:
		var streak := 16.0 + absf(player.velocity.x) * 0.05
		for i in 3:
			var y := -18.0 + float(i) * 14.0
			draw_line(Vector2(-24.0 - float(i) * 5.0, y), Vector2(-24.0 - streak, y + 3.0), Color(1.0, 0.90, 0.42, 0.55), 2.2, true)

	# Quicksand ripple.
	if player.in_quicksand:
		draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.35))
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 20, Color(0.90, 0.74, 0.42, 0.55), 2.0, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Soft ground shadow.
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.30))
	draw_circle(Vector2.ZERO, 22.0, Color(0.03, 0.10, 0.06, 0.26))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var leg_swing := sin(_run_phase) * (8.0 if running else 0.0)
	var arm_swing := sin(_run_phase + PI) * (8.0 if running else 0.0)
	var body_bob := sin(_run_phase * 2.0) * (1.4 if running else 0.0)
	var torso_y := -30.0 + body_bob
	var head_y := -50.0 + body_bob

	# Backpack behind the torso.
	draw_circle(Vector2(-12, torso_y - 2.0), 10.0, PACK)
	draw_rect(Rect2(-18, torso_y - 9.0, 11, 18), PACK)
	draw_rect(Rect2(-18, torso_y - 9.0, 4, 18), PACK_DARK)
	draw_circle(Vector2(-13, torso_y + 8.0), 3.0, GOLD)

	# Scarf tail, animated by run speed and air state.
	var flutter := sin(_time * 7.0) * 3.0 + speed * 0.018
	if rising:
		flutter += 4.0
	elif falling:
		flutter -= 2.0
	var scarf := PackedVector2Array([
		Vector2(-2, head_y + 10.0),
		Vector2(-19, head_y + 9.0 + flutter),
		Vector2(-30, head_y + 15.0 + flutter * 1.4),
		Vector2(-19, head_y + 17.0 + flutter * 0.4),
		Vector2(-2, head_y + 15.0),
	])
	draw_colored_polygon(scarf, SCARF)
	draw_line(Vector2(-2, head_y + 12.0), Vector2(-31, head_y + 15.0 + flutter * 1.4), SCARF.darkened(0.18), 2.0, true)

	# Legs.
	var hip := Vector2(0, torso_y + 11.0)
	var left_foot := Vector2(-8.0, 0.0)
	var right_foot := Vector2(8.0, 0.0)
	if running:
		left_foot = Vector2(-7.0 + leg_swing, 0.0)
		right_foot = Vector2(7.0 - leg_swing, 0.0)
	if not on_floor:
		leg_swing = 5.0 if rising else -4.0
		left_foot = Vector2(-9.0, -5.0 + leg_swing * 0.2)
		right_foot = Vector2(9.0, -2.0 - leg_swing * 0.2)
	draw_line(hip + Vector2(-5, 0), left_foot + Vector2(0, -3), PANTS, 7.0, true)
	draw_line(hip + Vector2(5, 0), right_foot + Vector2(0, -3), PANTS.darkened(0.12), 7.0, true)
	_draw_shoe(left_foot)
	_draw_shoe(right_foot)

	# Torso and shirt highlight.
	draw_circle(Vector2(0, torso_y), 14.0, SHIRT)
	draw_rect(Rect2(-13.5, torso_y - 2.0, 27.0, 13.0), SHIRT)
	draw_circle(Vector2(-5, torso_y - 5.0), 5.0, SHIRT.lightened(0.17))
	draw_line(Vector2(2, torso_y - 10.0), Vector2(2, torso_y + 8.0), SHIRT_DARK, 2.0, true)
	# Little belt.
	draw_rect(Rect2(-13, torso_y + 8.0, 26, 5), Color(0.31, 0.21, 0.12))
	draw_rect(Rect2(-2, torso_y + 8.0, 5, 5), GOLD)

	# Arms.
	var left_hand := Vector2(10.0, torso_y + 9.0 + arm_swing * 0.4)
	var right_hand := Vector2(13.0, torso_y + 10.0 - arm_swing * 0.4)
	if not on_floor:
		left_hand = Vector2(17.0, torso_y - 7.0)
		right_hand = Vector2(14.0, torso_y - 12.0)
	elif running:
		left_hand = Vector2(11.0 + arm_swing * 0.7, torso_y + 9.0)
		right_hand = Vector2(11.0 - arm_swing * 0.7, torso_y + 9.0)
	draw_line(Vector2(0, torso_y - 4.0), left_hand, SHIRT, 6.0, true)
	draw_line(Vector2(2, torso_y - 3.0), right_hand, SHIRT.darkened(0.08), 6.0, true)
	draw_circle(left_hand, 3.6, SKIN)
	draw_circle(right_hand, 3.6, SKIN_DARK)

	# Head, hair and explorer cap.
	draw_circle(Vector2(0, head_y), 15.0, HAIR)
	draw_circle(Vector2(3, head_y + 1.0), 13.3, SKIN)
	draw_circle(Vector2(-10, head_y + 3.0), 4.0, HAIR)
	draw_circle(Vector2(10, head_y + 6.0), 2.8, SKIN_DARK)

	# Cap dome and brim (character faces +X).
	draw_circle(Vector2(1, head_y - 8.0), 11.0, CAP)
	draw_circle(Vector2(-3, head_y - 9.0), 3.5, CAP_LIGHT)
	draw_colored_polygon(PackedVector2Array([
		Vector2(8, head_y - 9.0),
		Vector2(25, head_y - 6.0),
		Vector2(23, head_y - 1.0),
		Vector2(8, head_y - 3.0),
	]), CAP.darkened(0.15))
	draw_circle(Vector2(7, head_y - 5.0), 2.5, GOLD)

	# Face.
	draw_circle(Vector2(9, head_y - 1.0), 3.2, Color.WHITE)
	draw_circle(Vector2(10.2, head_y - 0.5), 1.7, EYE)
	draw_circle(Vector2(10.7, head_y - 1.2), 0.55, Color.WHITE)
	draw_line(Vector2(14, head_y + 5.0), Vector2(19, head_y + 4.0), SKIN_DARK, 1.6, true)
	draw_arc(Vector2(12, head_y + 6.0), 4.0, 0.25, 1.5, 8, Color(0.45, 0.20, 0.15), 1.5, true)

	# Movement squash marks when landing.
	if _squash > 0.45:
		var dust_alpha := (_squash - 0.45) * 0.8
		draw_circle(Vector2(-15, -1.0), 4.0, Color(0.95, 0.93, 0.82, dust_alpha))
		draw_circle(Vector2(15, -1.0), 4.0, Color(0.95, 0.93, 0.82, dust_alpha))


func _draw_shoe(foot: Vector2) -> void:
	draw_set_transform(foot + Vector2(2, -1), 0.0, Vector2(1.25, 0.65))
	draw_circle(Vector2.ZERO, 5.2, SHOES)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
