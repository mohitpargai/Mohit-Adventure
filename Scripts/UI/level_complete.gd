## Level-complete celebration. Shows coins, score, stars, the optional mission
## result, crystal shard progress and the mission bonus score.
extends Control

@onready var title_label: Label = $Center/Panel/VBox/Title
@onready var subtitle_label: Label = $Center/Panel/VBox/Subtitle
@onready var stars_label: Label = $Center/Panel/VBox/Stars
@onready var coins_label: Label = $Center/Panel/VBox/Stats/CoinsLabel
@onready var score_label: Label = $Center/Panel/VBox/Stats/ScoreLabel
@onready var optional_label: Label = $Center/Panel/VBox/Stats/OptionalLabel
@onready var shard_label: Label = $Center/Panel/VBox/Stats/ShardLabel
@onready var bonus_label: Label = $Center/Panel/VBox/Stats/BonusLabel
@onready var deaths_label: Label = $Center/Panel/VBox/Stats/DeathsLabel
@onready var next_button: Button = $Center/Panel/VBox/Buttons/NextButton
@onready var replay_button: Button = $Center/Panel/VBox/Buttons/ReplayButton
@onready var menu_button: Button = $Center/Panel/VBox/Buttons/MenuButton

var _final_level := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	next_button.pressed.connect(_on_next)
	replay_button.pressed.connect(_on_replay)
	menu_button.pressed.connect(_on_menu)
	for button in [next_button, replay_button, menu_button]:
		button.pressed.connect(AudioManager.play_click)


func show_result(final_level: bool, coins: int, total: int, score: int, stars: int, extra: Dictionary = {}) -> void:
	_final_level = final_level
	visible = true
	get_tree().paused = true

	var world := clampi(int(extra.get("world", 0)), 0, WorldData.WORLD_COUNT - 1)
	var boss := bool(extra.get("boss", false))
	var optional_done := bool(extra.get("optional_done", false))
	var optional_text := String(extra.get("optional_text", ""))
	var shard := bool(extra.get("shard", false))
	var reward := int(extra.get("reward", 0))
	var optional_reward := int(extra.get("optional_reward", 0))
	var deaths := int(extra.get("deaths", 0))

	if final_level:
		title_label.text = "ADVENTURE COMPLETE!"
		subtitle_label.text = "Six crystals shine again. The kingdoms are free!"
	elif boss:
		title_label.text = "BOSS DEFEATED!"
		subtitle_label.text = WorldData.WORLD_VICTORY[world]
	else:
		title_label.text = "LEVEL COMPLETE!"
		subtitle_label.text = "%s — %s" % [
			WorldData.world_name(world), WorldData.level_subtitle(GameManager.level_index)
		]

	coins_label.text = "COINS     %d / %d" % [coins, total]
	score_label.text = "SCORE     %d" % score
	var filled := clampi(stars, 0, 3)
	stars_label.text = "★".repeat(filled) + "☆".repeat(3 - filled)

	optional_label.visible = not optional_text.is_empty()
	if not optional_text.is_empty():
		if optional_done:
			optional_label.text = "✔ OPTIONAL: %s — DONE (+%d)" % [optional_text, optional_reward]
			optional_label.add_theme_color_override("font_color", Color(0.62, 1.0, 0.62))
		else:
			optional_label.text = "◇ OPTIONAL: %s — MISSED" % optional_text
			optional_label.add_theme_color_override("font_color", Color(1.0, 0.85098, 0.482353))

	shard_label.text = "◆ CRYSTAL SHARD FOUND!" if shard else "◇ CRYSTAL SHARD LEFT BEHIND"
	shard_label.add_theme_color_override(
		"font_color", Color(0.66, 0.91, 1.0) if shard else Color(0.72, 0.78, 0.74, 0.7)
	)
	var bonus := reward + (optional_reward if optional_done else 0)
	bonus_label.text = "MISSION BONUS     +%d" % bonus
	deaths_label.text = "LIVES LOST     %d" % deaths

	next_button.text = "PLAY AGAIN" if final_level else "NEXT LEVEL"
	next_button.grab_focus()


func _on_next() -> void:
	get_tree().paused = false
	AudioManager.set_music_paused(false)
	if _final_level:
		GameManager.return_to_menu()
	else:
		GameManager.next_level()


func _on_replay() -> void:
	get_tree().paused = false
	AudioManager.set_music_paused(false)
	GameManager.replay_current_level()


func _on_menu() -> void:
	get_tree().paused = false
	AudioManager.set_music_paused(false)
	GameManager.return_to_menu()
