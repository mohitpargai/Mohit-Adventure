## Reusable settings overlay used from both the main menu and pause menu.
extends Control

signal closed

@onready var music_slider: HSlider = $Center/Panel/VBox/MusicRow/MusicSlider
@onready var music_value: Label = $Center/Panel/VBox/MusicRow/MusicValue
@onready var sfx_slider: HSlider = $Center/Panel/VBox/SfxRow/SfxSlider
@onready var sfx_value: Label = $Center/Panel/VBox/SfxRow/SfxValue
@onready var touch_option: OptionButton = $Center/Panel/VBox/TouchRow/TouchOption
@onready var back_button: Button = $Center/Panel/VBox/ButtonRow/BackButton

var _updating := false


func _ready() -> void:
	visible = false
	touch_option.clear()
	touch_option.add_item("AUTO (recommended)")
	touch_option.add_item("ALWAYS SHOW")
	touch_option.add_item("HIDE")
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	touch_option.item_selected.connect(_on_touch_selected)
	back_button.pressed.connect(close)


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
	closed.emit()


func _refresh() -> void:
	_updating = true
	music_slider.value = roundf(GameManager.music_volume * 100.0)
	sfx_slider.value = roundf(GameManager.sfx_volume * 100.0)
	music_value.text = "%d%%" % int(music_slider.value)
	sfx_value.text = "%d%%" % int(sfx_slider.value)
	touch_option.select(GameManager.touch_mode)
	_updating = false


func _on_music_changed(value: float) -> void:
	music_value.text = "%d%%" % int(value)
	if not _updating:
		GameManager.set_music_volume(value / 100.0)


func _on_sfx_changed(value: float) -> void:
	sfx_value.text = "%d%%" % int(value)
	if not _updating:
		GameManager.set_sfx_volume(value / 100.0)


func _on_touch_selected(index: int) -> void:
	if _updating:
		return
	GameManager.set_touch_mode(index)
	AudioManager.play_click()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
