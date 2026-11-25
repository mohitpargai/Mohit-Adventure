## Game-over overlay shown when Mohit runs out of lives.
extends Control

@onready var score_label: Label = $Center/Panel/VBox/ScoreLabel
@onready var best_label: Label = $Center/Panel/VBox/BestLabel
@onready var retry_button: Button = $Center/Panel/VBox/Buttons/RetryButton
@onready var menu_button: Button = $Center/Panel/VBox/Buttons/MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	retry_button.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_menu)
	for button in [retry_button, menu_button]:
		button.pressed.connect(AudioManager.play_click)


func show_game_over(score: int) -> void:
	visible = true
	get_tree().paused = true
	AudioManager.set_music_paused(true)
	score_label.text = "SCORE     %d" % score
	best_label.text = "BEST     %d" % maxi(GameManager.best_score, score)
	AudioManager.play_sfx("game_over")
	retry_button.grab_focus()


func _on_retry() -> void:
	get_tree().paused = false
	AudioManager.set_music_paused(false)
	GameManager.retry_after_game_over()


func _on_menu() -> void:
	get_tree().paused = false
	AudioManager.set_music_paused(false)
	GameManager.return_to_menu()
