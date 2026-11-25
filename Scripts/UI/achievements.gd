## Achievements browser. Builds the list from GameManager.ACHIEVEMENTS so new
## achievements only need to be added in one place.
extends Control

@onready var list: VBoxContainer = $Center/Panel/VBox/Scroll/List
@onready var summary_label: Label = $Center/Panel/VBox/Summary
@onready var back_button: Button = $Center/Panel/VBox/BackButton


func _ready() -> void:
	visible = false
	back_button.pressed.connect(close)
	back_button.pressed.connect(AudioManager.play_click)


func open() -> void:
	visible = true
	_refresh()
	AudioManager.play_click()
	back_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	AudioManager.play_click()


func _refresh() -> void:
	for child in list.get_children():
		child.queue_free()
	summary_label.text = "UNLOCKED  %d / %d" % [GameManager.achievement_count(), GameManager.ACHIEVEMENTS.size()]
	for id in GameManager.ACHIEVEMENTS:
		var info: Dictionary = GameManager.ACHIEVEMENTS[id]
		var unlocked: bool = GameManager.has_achievement(String(id))
		var row := PanelContainer.new()
		row.theme_type_variation = &"HudPanel"
		var box := HBoxContainer.new()
		box.add_theme_constant_override("separation", 14)
		row.add_child(box)
		var badge := Label.new()
		badge.custom_minimum_size = Vector2(56, 0)
		badge.text = "★" if unlocked else "☆"
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 34)
		badge.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38) if unlocked else Color(0.55, 0.60, 0.54))
		box.add_child(badge)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label := Label.new()
		name_label.text = String(info["name"])
		name_label.add_theme_font_size_override("font_size", 23)
		name_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.56) if unlocked else Color(0.82, 0.85, 0.79, 0.65))
		text.add_child(name_label)
		var desc_label := Label.new()
		desc_label.text = String(info["desc"])
		desc_label.add_theme_font_size_override("font_size", 17)
		desc_label.add_theme_color_override("font_color", Color(0.88, 0.92, 0.85, 0.75 if unlocked else 0.42))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(desc_label)
		box.add_child(text)
		var state_label := Label.new()
		state_label.text = "DONE" if unlocked else "LOCKED"
		state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		state_label.add_theme_font_size_override("font_size", 17)
		state_label.add_theme_color_override("font_color", Color(0.62, 1.0, 0.64) if unlocked else Color(0.72, 0.75, 0.70, 0.55))
		box.add_child(state_label)
		list.add_child(row)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
