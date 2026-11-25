## In-game heads-up display: hearts, lives, coins, score, level name, mission
## tracker, boss health bar, power-up status and achievement toasts.
extends Control

signal pause_pressed

@onready var hearts = $TopLeft/VBox/Hearts
@onready var lives_label: Label = $TopLeft/VBox/LivesLabel
@onready var status_label: Label = $TopLeft/VBox/StatusLabel
@onready var mission_panel: Control = $MissionPanel
@onready var mission_main: Label = $MissionPanel/VBox/MissionMain
@onready var mission_optional: Label = $MissionPanel/VBox/MissionOptional
@onready var level_label: Label = $TopCenter/VBox/LevelLabel
@onready var coin_label: Label = $TopCenter/VBox/CoinRow/CoinLabel
@onready var score_label: Label = $TopRight/HBox/ScoreLabel
@onready var pause_button: Button = $TopRight/HBox/PauseButton
@onready var boss_bar: Control = $BossBar
@onready var boss_name: Label = $BossBar/VBox/BossName
@onready var boss_progress: ProgressBar = $BossBar/VBox/BossProgress
@onready var toast: Control = $AchievementToast
@onready var toast_title: Label = $AchievementToast/VBox/ToastTitle
@onready var toast_desc: Label = $AchievementToast/VBox/ToastDesc
@onready var intro_banner: Control = $IntroBanner
@onready var intro_title: Label = $IntroBanner/Panel/VBox/IntroTitle
@onready var intro_subtitle: Label = $IntroBanner/Panel/VBox/IntroSubtitle

var _player: Node
var _intro_tween: Tween
var _mission: Dictionary = {}
var _mission_progress := 0
var _mission_done := false
var _toast_queue: Array = []
var _toasting := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	if not GameManager.achievement_unlocked.is_connected(_on_achievement_unlocked):
		GameManager.achievement_unlocked.connect(_on_achievement_unlocked)
	pause_button.pressed.connect(_on_pause_pressed)

	intro_banner.visible = false
	intro_banner.modulate.a = 0.0
	mission_panel.visible = false
	boss_bar.visible = false
	toast.visible = false
	status_label.visible = false
	_update_score(GameManager.score)
	_update_coins(GameManager.level_coins, GameManager.level_coin_total)
	_update_lives(GameManager.lives)


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		status_label.visible = false
		return
	var parts: Array = []
	if float(_player.shield_time) > 0.0:
		parts.append("SHIELD %.1fs" % float(_player.shield_time))
	if float(_player.speed_time) > 0.0:
		parts.append("SPEED %.1fs" % float(_player.speed_time))
	if bool(_player.in_quicksand):
		parts.append("SLOWED")
	status_label.visible = not parts.is_empty()
	status_label.text = "  •  ".join(parts)


func bind_player(player: Node) -> void:
	if _player != null and is_instance_valid(_player):
		if _player.health_changed.is_connected(_on_health_changed):
			_player.health_changed.disconnect(_on_health_changed)
	_player = player
	if _player == null:
		return
	_player.health_changed.connect(_on_health_changed)
	_on_health_changed(_player.health, _player.MAX_HEALTH)


func set_level(index: int) -> void:
	var world := WorldData.world_index_for_level(index)
	level_label.text = "LEVEL %d / %d  •  %s" % [
		WorldData.level_number(index), WorldData.TOTAL_LEVELS, WorldData.world_name(world)
	]
	intro_title.text = "LEVEL %d" % WorldData.level_number(index)
	intro_subtitle.text = GameManager.get_level_name(index)


func show_intro(subtitle: String = "") -> void:
	if subtitle.is_empty():
		subtitle = GameManager.get_level_subtitle(GameManager.level_index)
	intro_subtitle.text = subtitle
	intro_banner.visible = true
	intro_banner.modulate.a = 0.0
	if _intro_tween != null and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_tween = create_tween()
	_intro_tween.set_trans(Tween.TRANS_SINE)
	_intro_tween.tween_property(intro_banner, "modulate:a", 1.0, 0.35)
	_intro_tween.tween_interval(1.35)
	_intro_tween.tween_property(intro_banner, "modulate:a", 0.0, 0.55)
	_intro_tween.tween_callback(func() -> void: intro_banner.visible = false)


# ---------------------------------------------------------------------------
# Mission tracker
# ---------------------------------------------------------------------------
func set_mission(mission: Dictionary) -> void:
	_mission = mission
	_mission_progress = 0
	_mission_done = false
	mission_panel.visible = not mission.is_empty()
	mission_main.text = String(mission.get("main", "Reach the finish flag"))
	_update_mission_label()


func update_mission(progress: int, done: bool = false) -> void:
	_mission_progress = maxi(_mission_progress, progress)
	_mission_done = done or _mission_done
	_update_mission_label()


func _update_mission_label() -> void:
	if _mission.is_empty():
		return
	var target := int(_mission.get("optional_target", 1))
	var text := String(_mission.get("optional", "Optional mission"))
	if _mission_done:
		mission_optional.text = "✔ %s  —  COMPLETE" % text
		mission_optional.add_theme_color_override("font_color", Color(0.62, 1.0, 0.62))
	else:
		var track := ""
		if String(_mission.get("optional_kind", "")) == "coins" \
				or String(_mission.get("optional_kind", "")) == "enemies" \
				or String(_mission.get("optional_kind", "")) == "checkpoints":
			track = "  (%d / %d)" % [mini(_mission_progress, target), target]
		mission_optional.text = "◇ %s%s" % [text, track]
		mission_optional.add_theme_color_override("font_color", Color(1.0, 0.85098, 0.482353))


# ---------------------------------------------------------------------------
# Boss bar
# ---------------------------------------------------------------------------
func show_boss_bar(boss_title: String, hp: int, max_hp: int) -> void:
	boss_name.text = boss_title
	boss_progress.max_value = float(maxi(1, max_hp))
	boss_progress.value = float(clampi(hp, 0, max_hp))
	boss_bar.visible = true
	boss_bar.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(boss_bar, "modulate:a", 1.0, 0.28)


func update_boss_bar(hp: int, max_hp: int) -> void:
	boss_progress.max_value = float(maxi(1, max_hp))
	boss_progress.value = float(clampi(hp, 0, max_hp))


func hide_boss_bar() -> void:
	boss_bar.visible = false


# ---------------------------------------------------------------------------
# Achievement toasts
# ---------------------------------------------------------------------------
func show_achievement(title: String, description: String) -> void:
	_toast_queue.append({"title": title, "desc": description})
	if not _toasting:
		_show_next_toast()


func _show_next_toast() -> void:
	if _toast_queue.is_empty():
		_toasting = false
		toast.visible = false
		return
	_toasting = true
	var entry: Dictionary = _toast_queue.pop_front()
	toast_title.text = "ACHIEVEMENT UNLOCKED  ★"
	toast_desc.text = "%s — %s" % [String(entry["title"]), String(entry["desc"])]
	toast.visible = true
	toast.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.24)
	tween.tween_interval(2.2)
	tween.tween_property(toast, "modulate:a", 0.0, 0.32)
	tween.tween_callback(_show_next_toast)


func _on_achievement_unlocked(_id: String, title: String, description: String) -> void:
	show_achievement(title, description)


# ---------------------------------------------------------------------------
# HUD feedback
# ---------------------------------------------------------------------------
func flash_coin() -> void:
	coin_label.pivot_offset = coin_label.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(coin_label, "scale", Vector2(1.35, 1.35), 0.09)
	tween.tween_property(coin_label, "scale", Vector2.ONE, 0.16)


func show_hurt_flash() -> void:
	var flash := ColorRect.new()
	flash.color = Color(0.95, 0.16, 0.18, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.22, 0.06)
	tween.tween_property(flash, "color:a", 0.0, 0.28)
	tween.tween_callback(flash.queue_free)


func _on_health_changed(current: int, maximum: int) -> void:
	hearts.set_health(current, maximum)
	var low := current <= 1
	hearts.modulate = Color(1.0, 0.72, 0.72) if low else Color.WHITE


func _on_score_changed(value: int) -> void:
	_update_score(value)


func _on_coins_changed(collected: int, total: int) -> void:
	_update_coins(collected, total)
	flash_coin()


func _on_lives_changed(value: int) -> void:
	_update_lives(value)


func _update_score(value: int) -> void:
	score_label.text = "SCORE  %d" % value


func _update_coins(collected: int, total: int) -> void:
	coin_label.text = "%d / %d" % [collected, total]


func _update_lives(value: int) -> void:
	lives_label.text = "LIVES  ×%d" % value


func _on_pause_pressed() -> void:
	AudioManager.play_click()
	pause_pressed.emit()
