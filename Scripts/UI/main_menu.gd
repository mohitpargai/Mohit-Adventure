## Animated main menu and entry point of Mohit Adventure.
## Offers separate Continue and New Game actions, the 30-level select screen
## and the achievements browser.
extends Control

@onready var title_area: Control = $TitleArea
@onready var play_button: Button = $MenuPanel/VBox/PlayButton
@onready var new_game_button: Button = $MenuPanel/VBox/NewGameButton
@onready var levels_button: Button = $MenuPanel/VBox/LevelsButton
@onready var achievements_button: Button = $MenuPanel/VBox/AchievementsButton
@onready var settings_button: Button = $MenuPanel/VBox/SettingsButton
@onready var quit_button: Button = $MenuPanel/VBox/QuitButton
@onready var best_label: Label = $BestLabel
@onready var progress_label: Label = $ProgressLabel
@onready var level_select: Control = $LevelSelect
@onready var achievements: Control = $Achievements
@onready var settings_panel: Control = $SettingsPanel


func _ready() -> void:
	get_tree().paused = false
	AudioManager.set_music_paused(false)
	AudioManager.play_music()
	AudioManager.set_music_volume(GameManager.music_volume)

	var has_progress: bool = GameManager.has_progress()
	play_button.pressed.connect(_on_continue)
	new_game_button.pressed.connect(_on_new_game)
	levels_button.pressed.connect(_on_levels)
	achievements_button.pressed.connect(_on_achievements)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	quit_button.visible = not OS.has_feature("web")

	play_button.disabled = not has_progress
	play_button.text = "CONTINUE" if has_progress else "START ADVENTURE"
	best_label.text = "BEST SCORE  •  %d" % GameManager.best_score
	progress_label.text = "LEVELS  %d / %d      ★  %d / %d      ◆  %d / 6" % [
		GameManager.completed_count(), GameManager.TOTAL_LEVELS,
		GameManager.star_count(), GameManager.TOTAL_LEVELS * 3,
		GameManager.crystal_count(),
	]
	if has_progress:
		play_button.grab_focus()
	else:
		new_game_button.grab_focus()
	_animate_title()


func _animate_title() -> void:
	await get_tree().process_frame
	title_area.pivot_offset = title_area.size * 0.5
	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title_area, "scale", Vector2(1.02, 1.02), 1.8)
	tween.tween_property(title_area, "scale", Vector2.ONE, 1.8)


func _on_continue() -> void:
	AudioManager.play_click()
	if GameManager.has_progress():
		GameManager.continue_game()
	else:
		GameManager.start_new_game()


func _on_new_game() -> void:
	AudioManager.play_click()
	GameManager.start_new_game()


func _on_levels() -> void:
	level_select.open()


func _on_achievements() -> void:
	achievements.open()


func _on_settings() -> void:
	settings_panel.open()


func _on_quit() -> void:
	AudioManager.play_click()
	get_tree().quit()
