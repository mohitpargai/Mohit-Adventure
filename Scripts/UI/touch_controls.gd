## Container for the three mobile controls. Handles auto-show rules,
## safe margins on odd screens and releasing touches when gameplay pauses.
extends Control

@onready var left_button: Control = $LeftButton
@onready var right_button: Control = $RightButton
@onready var jump_button: Control = $JumpButton

var _enabled := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManager.settings_changed.connect(_refresh_visibility)
	get_viewport().size_changed.connect(_apply_safe_margins)
	_apply_safe_margins()
	_refresh_visibility()


func set_controls_enabled(value: bool) -> void:
	_enabled = value
	_refresh_visibility()
	if not value:
		release_all()


func release_all() -> void:
	if is_instance_valid(left_button):
		left_button.call("release")
	if is_instance_valid(right_button):
		right_button.call("release")
	if is_instance_valid(jump_button):
		jump_button.call("release")


func _refresh_visibility() -> void:
	visible = _enabled and GameManager.should_show_touch_controls()
	if not visible:
		release_all()


func _apply_safe_margins() -> void:
	if not is_inside_tree():
		return
	# Keep buttons inside comfortable thumb reach on landscape phones and
	# tablets. The anchors already adapt; this only tunes the outer margin.
	var viewport_size := get_viewport_rect().size
	var margin := clampf(viewport_size.x * 0.022, 24.0, 52.0)
	var bottom_margin := clampf(viewport_size.y * 0.04, 28.0, 64.0)
	var button_size := clampf(viewport_size.y * 0.19, 100.0, 144.0)
	var gap := clampf(button_size * 0.18, 18.0, 30.0)
	var jump_size := button_size * 1.18

	left_button.size = Vector2(button_size, button_size)
	left_button.position = Vector2(margin, viewport_size.y - bottom_margin - button_size)
	right_button.size = Vector2(button_size, button_size)
	right_button.position = Vector2(margin + button_size + gap, viewport_size.y - bottom_margin - button_size)
	jump_button.size = Vector2(jump_size, jump_size)
	jump_button.position = Vector2(
		viewport_size.x - margin - jump_size,
		viewport_size.y - bottom_margin - jump_size
	)
	for button in [left_button, right_button, jump_button]:
		button.pivot_offset = button.size * 0.5
		button.queue_redraw()
