## Pause overlay. Runs while the scene tree is paused so Escape and the
## buttons keep working. Also hosts the reusable settings panel.
extends Control

signal paused_state_changed(paused: bool)

@onready var dim: ColorRect = $Dim
@onready var main_panel: Control = $Center/Panel
@onready var resume_button: Button = $Center/Panel/VBox/ResumeButton
@onready var restart_button: Button = $Center/Panel/VBox/RestartButton
@onready var settings_button: Button = $Center/Panel/VBox/SettingsButton
@onready var menu_button: Button = $Center/Panel/VBox/MenuButton
@onready var settings_panel: Control = $SettingsPanel

var _enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(close)
	restart_button.pressed.connect(_on_restart)
	settings_button.pressed.connect(_on_settings)
	menu_button.pressed.connect(_on_main_menu)
	settings_panel.closed.connect(_on_settings_closed)
	for button in [resume_button, restart_button, settings_button, menu_button]:
		button.pressed.connect(AudioManager.play_click)


func open() -> void:
	if visible or not _enabled:
		return
	visible = true
	main_panel.visible = true
	settings_panel.visible = false
	get_tree().paused = true
	AudioManager.set_music_paused(true)
	_release_touch_controls()
	paused_state_changed.emit(true)
	resume_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	settings_panel.visible = false
	get_tree().paused = false
	AudioManager.set_music_paused(false)
	paused_state_changed.emit(false)


func set_enabled(value: bool) -> void:
	_enabled = value
	if not value and visible:
		close()


func _on_restart() -> void:
	get_tree().paused = false
	AudioManager.set_music_paused(false)
	GameManager.replay_current_level()


func _on_settings() -> void:
	main_panel.visible = false
	settings_panel.open()


func _on_settings_closed() -> void:
	if visible:
		main_panel.visible = true
		resume_button.grab_focus()


func _on_main_menu() -> void:
	get_tree().paused = false
	AudioManager.set_music_paused(false)
	GameManager.return_to_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return
	if settings_panel.visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func _release_touch_controls() -> void:
	for node in get_tree().get_nodes_in_group("touch_controls"):
		if node.has_method("release_all"):
			node.call("release_all")
