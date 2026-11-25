## Skippable story overlay used for the intro, world intros, boss intros and
## victory epilogues. It pauses the tree while it is visible.
extends Control

signal finished

@onready var chapter_label: Label = $Center/Panel/VBox/Chapter
@onready var title_label: Label = $Center/Panel/VBox/Title
@onready var body_label: Label = $Center/Panel/VBox/Body
@onready var progress_label: Label = $Center/Panel/VBox/Progress
@onready var continue_button: Button = $Center/Panel/VBox/Buttons/ContinueButton
@onready var skip_button: Button = $Center/Panel/VBox/Buttons/SkipButton

var _lines: Array = []
var _index := 0
var _active := false
var _paused_tree := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	continue_button.pressed.connect(_advance)
	skip_button.pressed.connect(_close)
	continue_button.pressed.connect(AudioManager.play_click)
	skip_button.pressed.connect(AudioManager.play_click)
	GameManager.settings_changed.connect(_apply_font_scale)
	get_viewport().size_changed.connect(_apply_font_scale)


func show_story(lines: Array, chapter: String, title: String, subtitle: String = "") -> void:
	if GameManager.suppress_story or lines.is_empty():
		call_deferred("_emit_finished")
		return
	_lines = lines.duplicate()
	_index = 0
	_active = true
	chapter_label.text = chapter
	title_label.text = title
	if subtitle.is_empty():
		body_label.text = ""
	else:
		body_label.text = subtitle
	visible = true
	modulate.a = 0.0
	_paused_tree = not get_tree().paused
	get_tree().paused = true
	AudioManager.play_sfx("story")
	_apply_font_scale()
	_render()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	continue_button.grab_focus()


func _render() -> void:
	if _lines.is_empty():
		return
	var line := String(_lines[_index])
	if _index == 0 and not body_label.text.is_empty():
		body_label.text = "%s\n\n%s" % [body_label.text, line]
	else:
		body_label.text = line
	progress_label.text = "%d / %d" % [_index + 1, _lines.size()]
	continue_button.text = "CONTINUE" if _index < _lines.size() - 1 else "LET'S GO"
	skip_button.text = "SKIP"


func _advance() -> void:
	if not _active:
		return
	_index += 1
	if _index >= _lines.size():
		_close()
		return
	AudioManager.play_sfx("click")
	body_label.modulate.a = 0.0
	_render()
	var tween := create_tween()
	tween.tween_property(body_label, "modulate:a", 1.0, 0.18)


func _close() -> void:
	if not _active:
		return
	_active = false
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	await tween.finished
	visible = false
	if _paused_tree:
		get_tree().paused = false
	_paused_tree = false
	finished.emit()


func _emit_finished() -> void:
	finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _active:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_advance()
		get_viewport().set_input_as_handled()


func _apply_font_scale() -> void:
	if not is_inside_tree():
		return
	var viewport := get_viewport_rect().size
	var scale_factor := clampf(viewport.y / 720.0, 0.85, 1.7)
	body_label.add_theme_font_size_override("font_size", int(26.0 * scale_factor))
	title_label.add_theme_font_size_override("font_size", int(46.0 * scale_factor))
	chapter_label.add_theme_font_size_override("font_size", int(18.0 * scale_factor))
