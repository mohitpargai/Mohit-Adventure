## Expansion regression test for the 30-level, six-world version of Mohit
## Adventure. It checks the level database, every level scene, boss arenas and
## defeat flow, missions, progression, achievements, save migration and
## corruption recovery, the level-select/achievement UI, story cards and the
## new player power-up/environment states.
##
## The test backs up the real save file, mutates progression freely and restores
## the save when it finishes, so running it never costs the player progress.
##
## Run with:
##   godot --path . res://Tests/ExpansionTest.tscn
extends Node

const MENU_PATH := "res://Scenes/MainMenu.tscn"
const STORY_SCENE := "res://UI/StoryCard.tscn"
const ACHIEVEMENTS_SCENE := "res://UI/Achievements.tscn"

var _passed := 0
var _failed := 0
var _save_backup: PackedByteArray
var _had_save := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_backup_save()
	GameManager.suppress_story = true
	GameManager.test_mode = true
	await get_tree().process_frame
	await _run()
	_restore_save()
	print("---------------------------------------------")
	print("EXPANSION TEST: %d passed, %d failed" % [_passed, _failed])
	print("EXPANSION TEST PASSED" if _failed == 0 else "EXPANSION TEST FAILED")
	get_tree().quit(0 if _failed == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  ", label)
	else:
		_failed += 1
		printerr("  FAIL  ", label)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _run() -> void:
	print("MOHT ADVENTURE EXPANSION TEST")
	await _test_level_data()
	await _test_all_level_scenes()
	await _test_boss_level()
	await _test_progression()
	await _test_save_compatibility()
	await _test_ui()
	await _test_story()
	await _test_player_status()


# ---------------------------------------------------------------------------
# Save backup / restore
# ---------------------------------------------------------------------------
func _backup_save() -> void:
	_had_save = FileAccess.file_exists(GameManager.SAVE_PATH)
	if _had_save:
		_save_backup = FileAccess.get_file_as_bytes(GameManager.SAVE_PATH)


func _restore_save() -> void:
	if _had_save:
		var file := FileAccess.open(GameManager.SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_buffer(_save_backup)
			file.close()
	elif FileAccess.file_exists(GameManager.SAVE_PATH):
		DirAccess.remove_absolute(GameManager.SAVE_PATH)
	GameManager.load_data()


# ---------------------------------------------------------------------------
# Level database
# ---------------------------------------------------------------------------
func _test_level_data() -> void:
	print("Checking all 30 level definitions...")
	var boss_levels := 0
	var total_platforms := 0
	var total_coins := 0
	var total_enemies := 0
	var total_hazards := 0
	var total_powerups := 0
	var worlds_with_shards := {}

	for i in GameManager.TOTAL_LEVELS:
		var world: int = i / WorldData.LEVELS_PER_WORLD
		var data: Dictionary = LevelData.get_level(i)
		var world_info: Dictionary = WorldData.get_world(world)
		# The original forest levels keep their hand-picked day/dusk/sunset
		# backgrounds, so world 1 accepts its three variants.
		var background_ok := int(data["background"]) == int(world_info["background"])
		if world == 0:
			background_ok = int(data["background"]) in [0, 1, 2]
		_check(
			int(data["index"]) == i
			and int(data["world"]) == world
			and String(data["name"]) == WorldData.level_name(i)
			and int(data["style"]) == int(world_info["style"])
			and background_ok,
			"Level %d metadata matches WorldData" % (i + 1)
		)

		var mission: Dictionary = data.get("mission", {})
		_check(
			(data["platforms"] as Array).size() > 0
			and (data["coins"] as Array).size() > 0
			and not mission.is_empty()
			and mission.has("main") and mission.has("optional")
			and mission.has("optional_kind") and mission.has("optional_target")
			and mission.has("reward") and mission.has("optional_reward")
			and data.get("shard") != null,
			"Level %d has platforms, coins, a mission and a shard" % (i + 1)
		)

		_check(
			data["start"] is Vector2 and data["finish"] is Vector2
			and float(data["width"]) >= 1700.0
			and float(data["height"]) >= 1200.0
			and float(data["kill_y"]) > float(data["height"]),
			"Level %d has valid bounds" % (i + 1)
		)

		var boss_ok := true
		if WorldData.is_boss_level(i):
			boss_levels += 1
			boss_ok = (
				bool(data["boss"])
				and int(data.get("boss_hp", 0)) == WorldData.boss_hp(world)
				and int(data.get("boss_world", -1)) == world
				and (data["enemies"] as Array).is_empty()
			)
		else:
			boss_ok = not bool(data["boss"])
		var optional_kind := String(mission.get("optional_kind", ""))
		_check(
			boss_ok
			and optional_kind in ["coins", "enemies", "checkpoints", "treasure", "shard"]
			and int(mission.get("optional_target", 0)) >= 1,
			"Level %d mission and boss flags are valid" % (i + 1)
		)

		total_platforms += (data["platforms"] as Array).size()
		total_coins += (data["coins"] as Array).size()
		total_enemies += (data["enemies"] as Array).size()
		total_hazards += (data.get("hazards", []) as Array).size()
		total_powerups += (data.get("powerups", []) as Array).size()
		if data.get("shard") != null:
			worlds_with_shards[world] = true

	_check(boss_levels == 6, "Exactly six boss levels exist")
	_check(total_platforms > 200, "All levels together contain a large platform set")
	_check(total_coins > 300, "All levels together contain a large coin set")
	_check(total_enemies > 100, "All levels together contain a large enemy set")
	_check(total_hazards > 10, "All levels together contain the new hazards")
	_check(total_powerups >= 30, "Every level includes at least one power-up")
	_check(worlds_with_shards.size() == 6, "Every world contains crystal shards")

	# Original level layouts are still present under the new world names.
	var original_1: Dictionary = LevelData.get_level(0)
	var original_2: Dictionary = LevelData.get_level(1)
	var original_3: Dictionary = LevelData.get_level(2)
	_check(String(original_1["name"]) == "Forest Beginning", "Original level 1 keeps its name")
	_check(String(original_2["name"]) == "Hidden Coin Valley", "Original level 2 keeps its name")
	_check(String(original_3["name"]) == "Wooden Bridge", "Original level 3 keeps its name")
	_check((original_1["platforms"] as Array).size() > 10, "Original level 1 still has its platforms")
	_check((original_2["enemies"] as Array).size() > 10, "Original level 2 still has its enemies")
	_check((original_3["moving_platforms"] as Array).size() > 0, "Original level 3 still has moving platforms")

	_check(WorldData.world_index_for_level(0) == 0, "World lookup maps level 1 to world 1")
	_check(WorldData.world_index_for_level(29) == 5, "World lookup maps level 30 to world 6")
	_check(WorldData.is_boss_level(4) and WorldData.is_boss_level(29), "World finales are marked as boss levels")
	_check(not WorldData.is_boss_level(3) and not WorldData.is_boss_level(28), "Regular levels are not boss levels")
	_check(WorldData.level_number(29) == 30, "Level numbers are one-based")


# ---------------------------------------------------------------------------
# Every level scene
# ---------------------------------------------------------------------------
func _test_all_level_scenes() -> void:
	print("Loading all 30 level scenes...")
	for i in GameManager.TOTAL_LEVELS:
		var data: Dictionary = LevelData.get_level(i)
		var world: int = i / WorldData.LEVELS_PER_WORLD
		var packed: PackedScene = load(GameManager.LEVEL_PATHS[i])
		var level = packed.instantiate()
		add_child(level)
		await _frames(2)

		_check(
			level.level_index == i
			and level.player != null
			and level.hud != null
			and level.story_card != null
			and level.world.get_child_count() > 2,
			"Level %d scene builds its world and UI" % (i + 1)
		)

		_check(
			get_tree().get_nodes_in_group("coins").size() == (data["coins"] as Array).size()
			and get_tree().get_nodes_in_group("enemies").size() == (data["enemies"] as Array).size()
			and get_tree().get_nodes_in_group("hazards").size() == (data.get("hazards", []) as Array).size()
			and get_tree().get_nodes_in_group("powerups").size() == (data.get("powerups", []) as Array).size()
			and get_tree().get_nodes_in_group("treasure").size() == (data.get("treasure", []) as Array).size()
			and get_tree().get_nodes_in_group("crystal_shards").size() == 1
			and get_tree().get_nodes_in_group("breakable_platforms").size() == (data.get("breakable_platforms", []) as Array).size()
			and get_tree().get_nodes_in_group("disappearing_platforms").size() == (data.get("disappearing_platforms", []) as Array).size(),
			"Level %d spawns its coins, enemies, hazards and collectibles" % (i + 1)
		)

		if bool(data["boss"]):
			var boss_nodes := get_tree().get_nodes_in_group("bosses")
			var boss_ok := false
			if boss_nodes.size() == 1:
				var boss = boss_nodes[0]
				boss_ok = (
					boss.world == world
					and boss.max_hp == WorldData.boss_hp(world)
					and level.hud.boss_bar.visible
					and level.hud.boss_name.text == WorldData.boss_name(world)
				)
			_check(
				boss_ok
				and get_tree().get_nodes_in_group("finish_flags").is_empty(),
				"Level %d spawns its boss and health bar instead of a flag" % (i + 1)
			)
		else:
			_check(
				get_tree().get_nodes_in_group("finish_flags").size() == 1
				and not level.hud.boss_bar.visible,
				"Level %d has a finish flag and no boss bar" % (i + 1)
			)

		var mission: Dictionary = data["mission"]
		_check(
			level.hud.mission_panel.visible
			and level.hud.mission_main.text == String(mission["main"])
			and level.hud.level_label.text.contains(WorldData.world_name(world)),
			"Level %d HUD shows its mission and world" % (i + 1)
		)

		level.queue_free()
		await _frames(2)

	_check(get_tree().get_nodes_in_group("bosses").is_empty(), "Freed levels leave no boss nodes behind")
	_check(get_tree().get_nodes_in_group("hazards").is_empty(), "Freed levels leave no hazard nodes behind")


# ---------------------------------------------------------------------------
# Boss arena and defeat completion
# ---------------------------------------------------------------------------
func _test_boss_level() -> void:
	print("Testing boss arena, HP bar and boss-defeat completion...")
	GameManager.reset_progress()
	GameManager.level_deaths = 0
	var level = load(GameManager.LEVEL_PATHS[4]).instantiate()
	add_child(level)
	await _frames(3)

	var boss = level._boss
	_check(boss != null and boss.world == 0 and boss.max_hp == WorldData.boss_hp(0), "Boss arena spawns the world 1 boss")
	_check(level.hud.boss_bar.visible and level.hud.boss_name.text == WorldData.boss_name(0), "Boss HP bar names the boss")
	_check(level.hud.boss_progress.value == float(boss.max_hp), "Boss HP bar starts full")
	_check(String(level._mission.get("optional_kind", "")) == "shard", "Boss mission tracks the crystal shard")
	_check(get_tree().get_nodes_in_group("finish_flags").is_empty(), "Boss level has no finish flag")

	boss.take_damage(1)
	await _frames(2)
	_check(level.hud.boss_progress.value == float(boss.max_hp - 1), "Boss HP bar drops after a hit")

	await _wait(0.75)
	boss.take_damage(boss.hp)
	await _wait(1.3)
	_check(level.level_complete.visible, "Defeating the boss shows the results screen")
	_check(level.level_complete.title_label.text.contains("BOSS"), "Boss results use the boss title")
	_check(GameManager.is_level_complete(4), "Boss defeat records level completion")
	_check(GameManager.unlocked_level >= 5, "Boss defeat unlocks the next world")
	_check(bool(GameManager.world_crystals[0]), "Boss defeat awards the world crystal")
	_check(GameManager.has_achievement("forest_guardian"), "Boss defeat unlocks its achievement")
	_check(not level.hud.boss_bar.visible, "Boss bar hides after the fight")

	get_tree().paused = false
	AudioManager.set_music_paused(false)
	level.queue_free()
	await _frames(3)


# ---------------------------------------------------------------------------
# Progression and achievements
# ---------------------------------------------------------------------------
func _test_progression() -> void:
	print("Testing progression, stars, shards and achievements...")
	GameManager.reset_progress()
	GameManager.score = 0
	GameManager.level_deaths = 0
	_check(not GameManager.has_progress(), "Fresh progress reports no progress")
	_check(GameManager.first_incomplete_level() == 0, "Continue starts at level 1")

	GameManager.unlocked_level = 2
	GameManager.level_index = 0
	GameManager.play_level(9)
	_check(GameManager.level_index == 0, "Locked levels cannot be started directly")

	GameManager.unlocked_level = 0
	GameManager.level_index = 0
	GameManager.score = 1200
	var final_first := GameManager.record_completion(2, 7, false, false)
	_check(not final_first, "Level 1 is not the final level")
	_check(GameManager.is_level_complete(0) and GameManager.level_stars(0) == 2, "Completion stores stars")
	_check(GameManager.unlocked_level == 1 and GameManager.is_level_unlocked(1), "Completion unlocks the next level")
	_check(GameManager.level_best_score(0) >= 1200, "Completion stores the level best score")
	_check(GameManager.has_progress() and GameManager.first_incomplete_level() == 1, "Continue targets the first incomplete level")

	GameManager.level_index = 1
	GameManager.record_completion(1, 3, false, false)
	_check(GameManager.unlocked_level == 2, "A second completion unlocks level 3")

	# Complete the whole adventure with optional missions and every shard.
	GameManager.reset_progress()
	GameManager.score = 0
	GameManager.level_deaths = 0
	var finals := 0
	for i in GameManager.TOTAL_LEVELS:
		GameManager.level_index = i
		if GameManager.record_completion(3, 12, true, true):
			finals += 1

	_check(finals == 1, "Exactly one level reports final completion")
	_check(GameManager.completed_count() == 30, "All 30 levels are recorded complete")
	_check(GameManager.star_count() == 90, "Three stars are recorded on all 30 levels")
	_check(GameManager.shard_count() == 30, "All 30 crystal shards are recorded")
	_check(GameManager.crystal_count() == 6, "All six world crystals are awarded by bosses")
	_check(GameManager.unlocked_level == 29, "All levels are unlocked at the end")
	_check(GameManager.is_final_level(29), "Level 30 is the final level")

	var expected := [
		"first_steps", "forest_guardian", "ice_breaker", "desert_ruler",
		"shadow_bane", "dragon_slayer", "dark_lord_defeated", "crystal_hunter",
		"crystal_master", "world_savior", "boss_slayer", "perfectionist",
		"mission_master", "untouchable", "adventure_complete",
	]
	for id in expected:
		_check(GameManager.has_achievement(id), "Achievement unlocked: %s" % id)

	GameManager.add_coin(500)
	_check(GameManager.has_achievement("coin_hoarder"), "Coin Hoarder unlocks after 500 lifetime coins")
	_check(
		GameManager.achievement_count() == GameManager.ACHIEVEMENTS.size(),
		"Every defined achievement can be unlocked"
	)


# ---------------------------------------------------------------------------
# Save migration and corruption recovery
# ---------------------------------------------------------------------------
func _test_save_compatibility() -> void:
	print("Testing save migration, corruption recovery and compatibility...")

	# --- Original (version 0) save -----------------------------------------
	var old := ConfigFile.new()
	old.set_value("progress", "unlocked", 2)
	old.set_value("progress", "best_score", 4321)
	old.set_value("settings", "music", 0.42)
	old.set_value("settings", "sfx", 0.33)
	old.set_value("settings", "touch", 1)
	_check(old.save(GameManager.SAVE_PATH) == OK, "Old-format save file written")
	GameManager.load_data()
	_check(GameManager.unlocked_level == 2, "Old save keeps its unlock point")
	_check(
		bool(GameManager.completed[0]) and bool(GameManager.completed[1])
		and not bool(GameManager.completed[2]),
		"Old save marks cleared levels complete"
	)
	_check(GameManager.level_stars(0) == 1 and GameManager.level_stars(1) == 1, "Old save gives one star per cleared level")
	_check(GameManager.best_score == 4321, "Old save keeps the best score")
	_check(
		absf(GameManager.music_volume - 0.42) < 0.01
		and absf(GameManager.sfx_volume - 0.33) < 0.01
		and GameManager.touch_mode == 1,
		"Old save keeps settings"
	)
	_check(
		GameManager.has_achievement("first_steps") and GameManager.story_key_seen("migrated"),
		"Old save migrates achievements and story flags"
	)

	# --- Version 2 save with malformed values ------------------------------
	var versioned := ConfigFile.new()
	versioned.set_value("save", "version", 2)
	versioned.set_value("progress", "unlocked", 5)
	versioned.set_value("progress", "best_score", -50)
	versioned.set_value("progress", "completed", [true])
	versioned.set_value("progress", "stars", [9, 2, 2, -3, 2, -3])
	versioned.set_value("progress", "level_scores", [999999999])
	versioned.set_value("progress", "level_coins", [-10])
	versioned.set_value("progress", "optional", [true])
	versioned.set_value("progress", "shards", [true])
	versioned.set_value("progress", "crystals", [true, false])
	versioned.set_value("progress", "lifetime_coins", -5)
	versioned.set_value("progress", "achievements", ["first_steps", "bogus_id"])
	versioned.set_value("progress", "story", ["intro"])
	versioned.set_value("settings", "music", 2.5)
	versioned.set_value("settings", "sfx", -1.0)
	versioned.set_value("settings", "touch", 9)
	_check(versioned.save(GameManager.SAVE_PATH) == OK, "Version 2 test save written")
	GameManager.load_data()
	_check(GameManager.unlocked_level == 5, "Version 2 unlock point is clamped")
	_check(
		GameManager.completed.size() == 30 and GameManager.stars.size() == 30
		and GameManager.level_best_scores.size() == 30
		and GameManager.optional_completed.size() == 30
		and GameManager.shards_found.size() == 30,
		"Progress arrays are resized to 30"
	)
	_check(
		GameManager.level_stars(0) == 3
		and GameManager.level_stars(2) == 2
		and GameManager.level_stars(5) == 0,
		"Stars are clamped to 0-3"
	)
	_check(GameManager.level_best_score(0) == 99999999, "Best score is clamped to the maximum")
	_check(GameManager.level_best_coin_count(0) == 0, "Negative coin counts are clamped to zero")
	_check(GameManager.lifetime_coins == 0, "Negative lifetime coins are clamped to zero")
	_check(GameManager.best_score == 0, "Negative best score is clamped to zero")
	_check(
		GameManager.has_achievement("first_steps") and not GameManager.has_achievement("bogus_id"),
		"Only known achievements load from a save"
	)
	_check(
		GameManager.world_crystals.size() == 6
		and bool(GameManager.world_crystals[0])
		and not bool(GameManager.world_crystals[1]),
		"Crystal flags are padded and loaded"
	)
	_check(
		GameManager.music_volume == 1.0 and GameManager.sfx_volume == 0.0
		and GameManager.touch_mode == 2,
		"Out-of-range settings are clamped"
	)
	_check(GameManager.completed_count() == 5, "Levels below the saved unlock point are filled as complete")

	# --- Corrupt file -------------------------------------------------------
	var corrupt := FileAccess.open(GameManager.SAVE_PATH, FileAccess.WRITE)
	_check(corrupt != null, "Corrupt save file opened for writing")
	if corrupt != null:
		corrupt.store_string("### not a config file ###\n[[[")
		corrupt.close()
	GameManager.load_data()
	_check(
		GameManager.unlocked_level == 0 and GameManager.completed_count() == 0
		and GameManager.best_score == 0,
		"Corrupt save resets safely"
	)
	_check(
		GameManager.achievement_count() == 0 and GameManager.shard_count() == 0
		and GameManager.crystal_count() == 0,
		"Corrupt save clears achievements, shards and crystals"
	)

	# --- Missing file -------------------------------------------------------
	DirAccess.remove_absolute(GameManager.SAVE_PATH)
	GameManager.load_data()
	_check(not FileAccess.file_exists(GameManager.SAVE_PATH), "Missing save stays missing until the next save")
	_check(
		GameManager.unlocked_level == 0 and GameManager.completed.size() == 30
		and GameManager.world_crystals.size() == 6,
		"Missing save starts fresh with full arrays"
	)


# ---------------------------------------------------------------------------
# UI: level select, achievements and main menu
# ---------------------------------------------------------------------------
func _test_ui() -> void:
	print("Testing the 30-level select screen, achievements and main menu...")
	GameManager.reset_progress()
	var menu = load(MENU_PATH).instantiate()
	add_child(menu)
	await _frames(3)

	_check(menu.play_button.text == "START ADVENTURE" and menu.play_button.disabled, "Main menu starts without progress")
	_check(menu.new_game_button != null and menu.achievements_button != null, "Main menu has New Game and Achievements buttons")
	_check(menu.level_select.play_buttons.size() == 30, "Main menu hosts all 30 level buttons")
	_check(menu.level_select._world_info_labels.size() == 6, "Level select builds six world headers")

	GameManager.unlocked_level = 2
	menu.levels_button.pressed.emit()
	await _frames(2)
	_check(menu.level_select.visible, "Level Select button opens the 30-level grid")
	_check(
		not menu.level_select.play_buttons[0].disabled
		and not menu.level_select.play_buttons[2].disabled,
		"Unlocked levels are playable"
	)
	_check(menu.level_select.play_buttons[3].disabled, "Locked levels are disabled")
	_check("LOCKED" in menu.level_select.play_buttons[3].text, "Locked level cards show a lock label")
	_check(
		"☆" in menu.level_select.play_buttons[0].text
		and "◇" in menu.level_select.play_buttons[0].text,
		"Level cards show stars and shard state"
	)
	_check(
		menu.level_select.best_label.text.contains("STARS")
		and menu.level_select.best_label.text.contains("/ 90"),
		"Level select summary includes stars"
	)
	_check(menu.level_select.world_list.get_child_count() == 24, "Level select lists six worlds with subtitles and grids")
	_check(
		menu.level_select.scroll is ScrollContainer
		and menu.level_select.scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED,
		"Level select is vertically scrollable"
	)
	_check(menu.level_select._world_info_labels[0].text.contains("SHARDS"), "World headers show shard progress")
	menu.level_select.close()
	await _frames(1)
	_check(not menu.level_select.visible, "Level select closes")

	menu.achievements_button.pressed.emit()
	await _frames(2)
	_check(menu.achievements.visible, "Achievements button opens the browser")
	_check(
		menu.achievements.list.get_child_count() == GameManager.ACHIEVEMENTS.size(),
		"Achievements list shows every achievement"
	)
	_check(menu.achievements.summary_label.text.contains("0 / 16"), "Achievements summary starts at zero")
	menu.achievements.close()
	await _frames(1)
	_check(not menu.achievements.visible, "Achievements panel closes")

	menu.queue_free()
	await _frames(3)


# ---------------------------------------------------------------------------
# Story cards
# ---------------------------------------------------------------------------
func _test_story() -> void:
	print("Testing skippable story cards...")
	GameManager.suppress_story = false
	var card = load(STORY_SCENE).instantiate()
	add_child(card)
	await _frames(1)
	var finished := [0]
	card.finished.connect(func() -> void: finished[0] += 1)

	card.show_story(
		["Line one.", "Line two.", "Line three."],
		"PROLOGUE", "TEST STORY", "Subtitle"
	)
	await _frames(2)
	_check(card.visible and get_tree().paused, "Story card shows and pauses gameplay")
	_check(
		card.chapter_label.text == "PROLOGUE" and card.title_label.text == "TEST STORY",
		"Story card shows the chapter and title"
	)
	_check(
		card.body_label.text.contains("Line one.")
		and card.progress_label.text == "1 / 3",
		"Story card shows the first line"
	)

	card.continue_button.pressed.emit()
	await _frames(1)
	_check(
		card.body_label.text == "Line two." and card.progress_label.text == "2 / 3",
		"Continue advances the story"
	)
	card.continue_button.pressed.emit()
	await _frames(1)
	_check(
		card.progress_label.text == "3 / 3" and card.continue_button.text == "LET'S GO",
		"Final story page shows the go button"
	)
	card.continue_button.pressed.emit()
	await _wait(0.4)
	_check(not card.visible and not get_tree().paused, "Finishing the story resumes gameplay")
	_check(finished[0] == 1, "Story card emits finished once")

	card.show_story(["Skip me.", "And me."], "WORLD 1", "GREEN FOREST", "")
	await _frames(2)
	_check(card.visible and get_tree().paused, "A second story card opens")
	card.skip_button.pressed.emit()
	await _wait(0.4)
	_check(
		not card.visible and not get_tree().paused and finished[0] == 2,
		"Skip closes the story and resumes gameplay"
	)

	GameManager.suppress_story = true
	card.show_story(["Ignored."], "TEST", "IGNORED", "")
	await _wait(0.15)
	_check(not card.visible and finished[0] == 3, "Suppressed story closes immediately")

	card.queue_free()
	await _frames(2)


# ---------------------------------------------------------------------------
# Player power-ups and environment status
# ---------------------------------------------------------------------------
func _test_player_status() -> void:
	print("Testing power-ups, shields, wind and quicksand status...")
	GameManager.suppress_story = true
	var level = load(GameManager.LEVEL_PATHS[0]).instantiate()
	add_child(level)
	await _frames(3)
	var player = level.player
	var gained := [0]
	player.powerup_gained.connect(func(_kind: int) -> void: gained[0] += 1)

	player.apply_powerup(0)
	_check(player.has_shield() and player.shield_time > 0.0, "Shield power-up activates the shield")
	var health_before: int = player.health
	player.invulnerable_time = 0.0
	var hurt: bool = player.take_damage(1, Vector2.ZERO)
	_check(not hurt and player.health == health_before, "Shield absorbs damage")

	player.shield_time = 0.0
	player.invulnerable_time = 0.0
	hurt = player.take_damage(1, Vector2.ZERO)
	_check(hurt and player.health == health_before - 1, "Damage removes a heart without a shield")

	player.apply_powerup(1)
	_check(player.has_speed() and player.speed_time > 0.0, "Speed power-up activates the speed boost")
	player.apply_powerup(3)
	_check(player.health == health_before, "Heal power-up restores a heart")
	_check(gained[0] == 3, "Power-up signal fires for every pickup")

	player.set_wind(Vector2(48.0, 0.0))
	_check(player.wind_force.x == 48.0, "Wind zones apply a push force")
	player.set_quicksand(true)
	_check(player.in_quicksand, "Quicksand slows the player")
	player.set_quicksand(false)
	_check(not player.in_quicksand, "Leaving quicksand clears the slow")

	player.shield_time = 5.0
	player.speed_time = 5.0
	player.in_quicksand = true
	await _frames(2)
	_check(
		level.hud.status_label.visible
		and level.hud.status_label.text.contains("SHIELD")
		and level.hud.status_label.text.contains("SPEED")
		and level.hud.status_label.text.contains("SLOWED"),
		"HUD shows shield, speed and quicksand status"
	)
	player.set_quicksand(false)

	level.queue_free()
	await _frames(2)
