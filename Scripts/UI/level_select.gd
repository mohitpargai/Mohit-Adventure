## Scrollable level selection grouped by the six worlds. All 30 cards are
## generated from WorldData so locks, stars, best scores and shards stay in
## sync with the save file. Mouse, keyboard and touch all work.
extends Control

@onready var back_button: Button = $Center/Panel/VBox/BackButton
@onready var best_label: Label = $Center/Panel/VBox/BestLabel
@onready var scroll: ScrollContainer = $Center/Panel/VBox/Scroll
@onready var world_list: VBoxContainer = $Center/Panel/VBox/Scroll/WorldList

var play_buttons: Array[Button] = []
var _world_info_labels: Array[Label] = []


func _ready() -> void:
	visible = false
	back_button.pressed.connect(close)
	back_button.pressed.connect(AudioManager.play_click)
	_build_cards()


func _build_cards() -> void:
	if not play_buttons.is_empty():
		return
	for world in WorldData.WORLD_COUNT:
		var header := PanelContainer.new()
		header.theme_type_variation = &"HudPanel"
		var header_box := HBoxContainer.new()
		header_box.name = "HeaderBox"
		header_box.add_theme_constant_override("separation", 14)
		header.add_child(header_box)
		var world_label := Label.new()
		world_label.text = "WORLD %d  •  %s" % [world + 1, WorldData.world_name(world)]
		world_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		world_label.add_theme_font_size_override("font_size", 22)
		world_label.add_theme_color_override("font_color", WorldData.accent(world).lightened(0.18))
		world_label.add_theme_color_override("font_outline_color", Color(0.02, 0.07, 0.05, 1.0))
		world_label.add_theme_constant_override("outline_size", 4)
		header_box.add_child(world_label)
		var world_info := Label.new()
		world_info.name = "WorldInfo"
		world_info.add_theme_font_size_override("font_size", 16)
		world_info.add_theme_color_override("font_color", Color(0.88, 0.93, 0.86, 0.8))
		header_box.add_child(world_info)
		_world_info_labels.append(world_info)
		world_list.add_child(header)

		var subtitle := Label.new()
		subtitle.text = WorldData.world_subtitle(world)
		subtitle.add_theme_font_size_override("font_size", 15)
		subtitle.add_theme_color_override("font_color", Color(0.82, 0.90, 0.82, 0.65))
		subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		world_list.add_child(subtitle)

		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		grid.name = "World%dGrid" % (world + 1)
		for local in WorldData.LEVELS_PER_WORLD:
			var index := world * WorldData.LEVELS_PER_WORLD + local
			var button := Button.new()
			button.name = "Level%dButton" % (index + 1)
			button.custom_minimum_size = Vector2(206, 84)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.add_theme_font_size_override("font_size", 15)
			button.pressed.connect(_on_play.bind(index))
			button.focus_entered.connect(_ensure_visible.bind(button))
			button.mouse_entered.connect(_ensure_visible.bind(button))
			grid.add_child(button)
			play_buttons.append(button)
		world_list.add_child(grid)

		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 8)
		world_list.add_child(spacer)


func open() -> void:
	visible = true
	_refresh()
	AudioManager.play_click()
	var focus_index: int = clampi(GameManager.unlocked_level, 0, play_buttons.size() - 1)
	play_buttons[focus_index].grab_focus()
	call_deferred("_ensure_visible", play_buttons[focus_index])


func close() -> void:
	if not visible:
		return
	visible = false
	AudioManager.play_click()


func _refresh() -> void:
	for world in _world_info_labels.size():
		var info: Label = _world_info_labels[world]
		var earned := 0
		var total := 0
		for local in WorldData.LEVELS_PER_WORLD:
			var index := world * WorldData.LEVELS_PER_WORLD + local
			earned += GameManager.level_stars(index)
			total += 3
		var crystal := "◆" if bool(GameManager.world_crystals[world]) else "◇"
		info.text = "%s  ★ %d / %d   SHARDS %d / 5" % [
			crystal, earned, total,
			_shard_count_in_world(world),
		]
	for i in play_buttons.size():
		var button := play_buttons[i]
		var unlocked := GameManager.is_level_unlocked(i)
		var completed := GameManager.is_level_complete(i)
		var level_stars := GameManager.level_stars(i)
		var best := GameManager.level_best_score(i)
		var shard := "◆" if GameManager.has_shard(i) else "◇"
		var name := WorldData.level_name(i)
		if WorldData.is_boss_level(i):
			name = "BOSS • " + name
		if not unlocked:
			button.text = "%02d  %s\nLOCKED" % [i + 1, name]
			button.disabled = true
			button.theme_type_variation = &"GhostButton"
			button.modulate = Color(1, 1, 1, 0.55)
			button.tooltip_text = "Complete the previous level to unlock."
		else:
			var star_text := "★".repeat(level_stars) + "☆".repeat(3 - level_stars)
			var state := "CLEAR" if completed else "PLAY"
			button.text = "%02d  %s\n%s  %s  %d  %s" % [i + 1, name, star_text, shard, best, state]
			button.disabled = false
			button.theme_type_variation = &"PrimaryButton" if completed else &"GhostButton"
			button.modulate = Color.WHITE
			button.tooltip_text = WorldData.level_subtitle(i)
	best_label.text = "BEST SCORE  •  %d      CRYSTALS  ◆ %d / 6      SHARDS  ◆ %d / 30      STARS  ★ %d / 90" % [
		GameManager.best_score,
		GameManager.crystal_count(),
		GameManager.shard_count(),
		GameManager.star_count(),
	]


func _shard_count_in_world(world: int) -> int:
	var count := 0
	for local in WorldData.LEVELS_PER_WORLD:
		if GameManager.has_shard(world * WorldData.LEVELS_PER_WORLD + local):
			count += 1
	return count


func _ensure_visible(button: Control) -> void:
	await get_tree().process_frame
	if is_instance_valid(scroll) and is_instance_valid(button):
		scroll.ensure_control_visible(button)


func _on_play(index: int) -> void:
	AudioManager.play_click()
	GameManager.play_level(index)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
