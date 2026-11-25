## Global game state, save data, input setup and scene navigation.
## The save file is a ConfigFile in user:// and migrates the original
## three-level save format without losing anything the player earned.
extends Node

signal score_changed(value: int)
signal coins_changed(collected: int, total: int)
signal lives_changed(value: int)
signal settings_changed
signal achievement_unlocked(id: String, title: String, description: String)
signal crystals_changed(count: int, total: int)

const MAX_LIVES := 3
const MAX_HEARTS := 3
const MAX_EXTRA_LIVES := 9
const TOTAL_LEVELS := 30
const WORLD_COUNT := 6
const LEVELS_PER_WORLD := 5
const SAVE_VERSION := 2
const SAVE_PATH := "user://mohit_adventure.cfg"
const MENU_PATH := "res://Scenes/MainMenu.tscn"

const ACHIEVEMENTS := {
	"first_steps": {
		"name": "First Steps",
		"desc": "Complete the first level of Mohit Adventure.",
	},
	"forest_guardian": {
		"name": "Forest Guardian",
		"desc": "Defeat the ancient guardian of the Green Forest.",
	},
	"ice_breaker": {
		"name": "Ice Breaker",
		"desc": "Defeat the Ice Monster in the frozen kingdom.",
	},
	"desert_ruler": {
		"name": "Desert Ruler",
		"desc": "Defeat the Desert King and free the dunes.",
	},
	"shadow_bane": {
		"name": "Shadow Bane",
		"desc": "Defeat the Shadow Knight in the Dark Castle.",
	},
	"dragon_slayer": {
		"name": "Dragon Slayer",
		"desc": "Defeat the Lava Dragon in the burning mountain.",
	},
	"dark_lord_defeated": {
		"name": "Dark Lord Defeated",
		"desc": "Defeat the Dark Lord and save all six kingdoms.",
	},
	"crystal_hunter": {
		"name": "Crystal Hunter",
		"desc": "Find 5 crystal shards hidden across the kingdoms.",
	},
	"crystal_master": {
		"name": "Crystal Master",
		"desc": "Find every crystal shard in all 30 levels.",
	},
	"world_savior": {
		"name": "World Savior",
		"desc": "Collect all six world crystals.",
	},
	"coin_hoarder": {
		"name": "Coin Hoarder",
		"desc": "Collect 500 coins across all your adventures.",
	},
	"boss_slayer": {
		"name": "Boss Slayer",
		"desc": "Defeat three different bosses.",
	},
	"perfectionist": {
		"name": "Perfectionist",
		"desc": "Earn 3 stars on 10 different levels.",
	},
	"mission_master": {
		"name": "Mission Master",
		"desc": "Finish the optional mission on 10 levels.",
	},
	"untouchable": {
		"name": "Untouchable",
		"desc": "Complete a level without losing a single life.",
	},
	"adventure_complete": {
		"name": "Adventure Complete",
		"desc": "Complete all 30 levels of Mohit Adventure.",
	},
}

var LEVEL_PATHS: Array[String] = []

# --- Run state -------------------------------------------------------------
var score := 0
var run_coins := 0
var level_coins := 0
var level_coin_total := 0
var lives := MAX_LIVES
var level_index := 0
var level_deaths := 0
var in_game := false
var current_mission: Dictionary = {}

# --- Saved progression -----------------------------------------------------
var unlocked_level := 0
var best_score := 0
var completed: Array = []
var stars: Array = []
var level_best_scores: Array = []
var level_best_coins: Array = []
var optional_completed: Array = []
var shards_found: Array = []
var world_crystals: Array = []
var lifetime_coins := 0
var achievements: Dictionary = {}
var story_seen: Dictionary = {}
var suppress_story := false
var test_mode := false

# Snapshot used by "Restart Level" so coins cannot be farmed by restarting.
var _level_start_score := 0
var _level_start_run_coins := 0

# --- Settings --------------------------------------------------------------
var music_volume := 0.65
var sfx_volume := 0.85
var touch_mode := 0 # 0 = auto, 1 = always on, 2 = off

var _changing_scene := false


func _init() -> void:
	LEVEL_PATHS.clear()
	for i in TOTAL_LEVELS:
		LEVEL_PATHS.append("res://Levels/Level%d.tscn" % (i + 1))
	_reset_progress_arrays()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input_map()
	load_data()
	call_deferred("_apply_audio_settings")


func _reset_progress_arrays() -> void:
	completed = []
	stars = []
	level_best_scores = []
	level_best_coins = []
	optional_completed = []
	shards_found = []
	world_crystals = []
	completed.resize(TOTAL_LEVELS)
	completed.fill(false)
	stars.resize(TOTAL_LEVELS)
	stars.fill(0)
	level_best_scores.resize(TOTAL_LEVELS)
	level_best_scores.fill(0)
	level_best_coins.resize(TOTAL_LEVELS)
	level_best_coins.fill(0)
	optional_completed.resize(TOTAL_LEVELS)
	optional_completed.fill(false)
	shards_found.resize(TOTAL_LEVELS)
	shards_found.fill(false)
	world_crystals.resize(WORLD_COUNT)
	world_crystals.fill(false)


# ---------------------------------------------------------------------------
# Input ---------------------------------------------------------------------
# ---------------------------------------------------------------------------
func _setup_input_map() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_key_action("pause", [KEY_ESCAPE, KEY_P])

	# Optional gamepad support. This makes desktop testing nicer too.
	_add_joy_button("jump", JOY_BUTTON_A)
	_add_joy_button("pause", JOY_BUTTON_START)
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)


func _add_key_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_set_deadzone(action, 0.2)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


func _add_joy_button(action: StringName, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _add_joy_axis(action: StringName, axis: JoyAxis, value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


# ---------------------------------------------------------------------------
# Run flow -------------------------------------------------------------------
# ---------------------------------------------------------------------------
func start_new_game() -> void:
	_reset_run()
	level_index = 0
	_begin_level()


## Continue from the first level that has not been finished yet.
func continue_game() -> void:
	_reset_run()
	level_index = first_incomplete_level()
	_begin_level()


func has_progress() -> bool:
	if unlocked_level > 0 or lifetime_coins > 0:
		return true
	for value in completed:
		if bool(value):
			return true
	return false


func first_incomplete_level() -> int:
	for i in TOTAL_LEVELS:
		if not bool(completed[i]):
			return i
	return TOTAL_LEVELS - 1


func reset_progress() -> void:
	_reset_progress_arrays()
	unlocked_level = 0
	best_score = 0
	lifetime_coins = 0
	achievements.clear()
	story_seen.clear()
	save_data()


func _reset_run() -> void:
	score = 0
	run_coins = 0
	level_coins = 0
	level_coin_total = 0
	lives = MAX_LIVES
	level_deaths = 0
	current_mission = {}


func play_level(index: int) -> void:
	if index < 0 or index >= TOTAL_LEVELS:
		return
	if index > unlocked_level:
		return
	_reset_run()
	level_index = index
	_begin_level()


func next_level() -> void:
	if level_index >= TOTAL_LEVELS - 1:
		start_new_game()
		return
	level_index += 1
	level_coins = 0
	level_coin_total = 0
	level_deaths = 0
	_begin_level()


func replay_current_level() -> void:
	# Restore the score snapshot from the moment this level started.
	score = _level_start_score
	run_coins = _level_start_run_coins
	level_coins = 0
	level_coin_total = 0
	level_deaths = 0
	lives = MAX_LIVES
	_begin_level()


func retry_after_game_over() -> void:
	replay_current_level()


func return_to_menu() -> void:
	in_game = false
	get_tree().paused = false
	_change_scene(MENU_PATH)


func complete_current_level() -> bool:
	"""Kept for compatibility; awards a basic completion."""
	var final_level := is_final_level(level_index)
	record_completion(1, level_coins, false)
	return final_level


func record_completion(stars_earned: int, coins: int, optional_done: bool, shard: bool = false) -> bool:
	var index := clampi(level_index, 0, TOTAL_LEVELS - 1)
	var world := index / LEVELS_PER_WORLD
	if shard:
		collect_shard(index)
	completed[index] = true
	stars[index] = maxi(int(stars[index]), clampi(stars_earned, 1, 3))
	level_best_coins[index] = maxi(int(level_best_coins[index]), coins)
	level_best_scores[index] = maxi(int(level_best_scores[index]), score)
	optional_completed[index] = bool(optional_completed[index]) or optional_done
	best_score = maxi(best_score, score)
	unlocked_level = maxi(unlocked_level, mini(TOTAL_LEVELS - 1, index + 1))
	if is_boss_level(index) and world_crystals[world] == false:
		world_crystals[world] = true
		crystals_changed.emit(crystal_count(), WORLD_COUNT)
	_evaluate_achievements(index, optional_done)
	save_data()
	return is_final_level(index)


func record_game_over() -> void:
	best_score = maxi(best_score, score)
	save_data()


func _begin_level() -> void:
	in_game = true
	_level_start_score = score
	_level_start_run_coins = run_coins
	_change_scene(LEVEL_PATHS[clampi(level_index, 0, TOTAL_LEVELS - 1)])


func _change_scene(path: String) -> void:
	# Wait for any in-progress transition instead of dropping this request.
	while _changing_scene:
		await get_tree().process_frame
	_changing_scene = true
	get_tree().paused = false
	if is_instance_valid(SceneFader):
		await SceneFader.change_scene(path)
	else:
		get_tree().change_scene_to_file(path)
	_changing_scene = false


# ---------------------------------------------------------------------------
# Level metadata / story ------------------------------------------------------
# ---------------------------------------------------------------------------
func get_level_name(index: int = -1) -> String:
	var i := level_index if index < 0 else index
	return WorldData.level_name(i)


func get_level_subtitle(index: int = -1) -> String:
	var i := level_index if index < 0 else index
	return WorldData.level_subtitle(i)


func get_world_name(index: int = -1) -> String:
	var i := level_index if index < 0 else index
	return WorldData.world_name(WorldData.world_index_for_level(i))


func is_boss_level(index: int) -> bool:
	return WorldData.is_boss_level(index)


func is_final_level(index: int) -> bool:
	return clampi(index, 0, TOTAL_LEVELS - 1) >= TOTAL_LEVELS - 1


func level_stars(index: int) -> int:
	return int(stars[clampi(index, 0, TOTAL_LEVELS - 1)])


func level_best_score(index: int) -> int:
	return int(level_best_scores[clampi(index, 0, TOTAL_LEVELS - 1)])


func level_best_coin_count(index: int) -> int:
	return int(level_best_coins[clampi(index, 0, TOTAL_LEVELS - 1)])


func is_level_complete(index: int) -> bool:
	return bool(completed[clampi(index, 0, TOTAL_LEVELS - 1)])


func is_level_unlocked(index: int) -> bool:
	return clampi(index, 0, TOTAL_LEVELS - 1) <= unlocked_level


func has_shard(index: int) -> bool:
	return bool(shards_found[clampi(index, 0, TOTAL_LEVELS - 1)])


func collect_shard(index: int) -> void:
	var i := clampi(index, 0, TOTAL_LEVELS - 1)
	if shards_found[i]:
		return
	shards_found[i] = true
	_evaluate_achievements(i, false)
	save_data()


func shard_count() -> int:
	var count := 0
	for value in shards_found:
		if bool(value):
			count += 1
	return count


func crystal_count() -> int:
	var count := 0
	for value in world_crystals:
		if bool(value):
			count += 1
	return count


func completed_count() -> int:
	var count := 0
	for value in completed:
		if bool(value):
			count += 1
	return count


func star_count() -> int:
	var count := 0
	for value in stars:
		count += int(value)
	return count


func story_key_seen(key: String) -> bool:
	return story_seen.has(key)


func mark_story_seen(key: String) -> void:
	story_seen[key] = true
	save_data()


# ---------------------------------------------------------------------------
# Achievements ---------------------------------------------------------------
# ---------------------------------------------------------------------------
func unlock_achievement(id: String) -> void:
	if achievements.has(id):
		return
	if not ACHIEVEMENTS.has(id):
		return
	achievements[id] = true
	var info: Dictionary = ACHIEVEMENTS[id]
	achievement_unlocked.emit(id, String(info["name"]), String(info["desc"]))
	save_data()


func has_achievement(id: String) -> bool:
	return achievements.has(id)


func achievement_count() -> int:
	return achievements.size()


func _evaluate_achievements(index: int, optional_done: bool) -> void:
	if index == 0:
		unlock_achievement("first_steps")
	if int(stars[index]) >= 3:
		var three_star_count := 0
		for value in stars:
			if int(value) >= 3:
				three_star_count += 1
		if three_star_count >= 10:
			unlock_achievement("perfectionist")
	var shard_total := shard_count()
	if shard_total >= 5:
		unlock_achievement("crystal_hunter")
	if shard_total >= TOTAL_LEVELS:
		unlock_achievement("crystal_master")
	if crystal_count() >= WORLD_COUNT:
		unlock_achievement("world_savior")
	if lifetime_coins >= 500:
		unlock_achievement("coin_hoarder")
	var boss_count := 0
	for world in WORLD_COUNT:
		if bool(world_crystals[world]):
			boss_count += 1
			unlock_achievement(_boss_achievement(world))
	if boss_count >= 3:
		unlock_achievement("boss_slayer")
	var optional_count := 0
	for value in optional_completed:
		if bool(value):
			optional_count += 1
	if optional_count >= 10:
		unlock_achievement("mission_master")
	if completed_count() >= TOTAL_LEVELS:
		unlock_achievement("adventure_complete")
	if optional_done and level_deaths == 0:
		unlock_achievement("untouchable")


func _boss_achievement(world: int) -> String:
	return [
		"forest_guardian",
		"ice_breaker",
		"desert_ruler",
		"shadow_bane",
		"dragon_slayer",
		"dark_lord_defeated",
	][clampi(world, 0, WORLD_COUNT - 1)]


# ---------------------------------------------------------------------------
# Score / coins / lives ------------------------------------------------------
# ---------------------------------------------------------------------------
func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func add_coin(amount: int = 1) -> void:
	level_coins += amount
	run_coins += amount
	lifetime_coins += amount
	add_score(10 * amount)
	coins_changed.emit(level_coins, level_coin_total)
	if lifetime_coins >= 500:
		unlock_achievement("coin_hoarder")


func set_level_coin_total(total: int) -> void:
	level_coins = 0
	level_coin_total = total
	coins_changed.emit(level_coins, level_coin_total)


func lose_life() -> int:
	lives = maxi(0, lives - 1)
	level_deaths += 1
	lives_changed.emit(lives)
	return lives


func add_life() -> int:
	lives = mini(MAX_EXTRA_LIVES, lives + 1)
	lives_changed.emit(lives)
	return lives


func reset_lives() -> void:
	lives = MAX_LIVES
	lives_changed.emit(lives)


# ---------------------------------------------------------------------------
# Settings -------------------------------------------------------------------
# ---------------------------------------------------------------------------
func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if is_instance_valid(AudioManager):
		AudioManager.set_music_volume(music_volume)
	save_data()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	if is_instance_valid(AudioManager):
		AudioManager.set_sfx_volume(sfx_volume)
	save_data()


func set_touch_mode(mode: int) -> void:
	touch_mode = clampi(mode, 0, 2)
	settings_changed.emit()
	save_data()


func should_show_touch_controls() -> bool:
	if touch_mode == 1:
		return true
	if touch_mode == 2:
		return false
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")


func _apply_audio_settings() -> void:
	if is_instance_valid(AudioManager):
		AudioManager.set_music_volume(music_volume)
		AudioManager.set_sfx_volume(sfx_volume)


# ---------------------------------------------------------------------------
# Save file ------------------------------------------------------------------
# ---------------------------------------------------------------------------
func load_data() -> void:
	_reset_progress_arrays()
	unlocked_level = 0
	best_score = 0
	lifetime_coins = 0
	achievements.clear()
	story_seen.clear()

	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		# Missing or unreadable save: a fresh player simply starts clean.
		return

	var version := int(config.get_value("save", "version", 0))
	unlocked_level = clampi(int(config.get_value("progress", "unlocked", 0)), 0, TOTAL_LEVELS - 1)
	best_score = maxi(0, int(config.get_value("progress", "best_score", 0)))
	music_volume = clampf(float(config.get_value("settings", "music", 0.65)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("settings", "sfx", 0.85)), 0.0, 1.0)
	touch_mode = clampi(int(config.get_value("settings", "touch", 0)), 0, 2)

	if version <= 0:
		_migrate_old_save()
	else:
		completed = _sanitize_bool_array(config.get_value("progress", "completed", []), TOTAL_LEVELS)
		stars = _sanitize_int_array(config.get_value("progress", "stars", []), TOTAL_LEVELS, 0, 3)
		level_best_scores = _sanitize_int_array(config.get_value("progress", "level_scores", []), TOTAL_LEVELS, 0, 99999999)
		level_best_coins = _sanitize_int_array(config.get_value("progress", "level_coins", []), TOTAL_LEVELS, 0, 99999999)
		optional_completed = _sanitize_bool_array(config.get_value("progress", "optional", []), TOTAL_LEVELS)
		shards_found = _sanitize_bool_array(config.get_value("progress", "shards", []), TOTAL_LEVELS)
		world_crystals = _sanitize_bool_array(config.get_value("progress", "crystals", []), WORLD_COUNT)
		lifetime_coins = maxi(0, int(config.get_value("progress", "lifetime_coins", 0)))
		for id in _sanitize_string_array(config.get_value("progress", "achievements", [])):
			if ACHIEVEMENTS.has(id):
				achievements[id] = true
		for key in _sanitize_string_array(config.get_value("progress", "story", [])):
			story_seen[key] = true

	# A save that claims progress but has no completed levels still unlocks
	# everything below the saved unlock point.
	for i in range(0, unlocked_level):
		if not bool(completed[i]):
			completed[i] = true
			stars[i] = maxi(1, int(stars[i]))


func _migrate_old_save() -> void:
	# Version 0 only stored progress/unlocked and the global best score.
	for i in range(0, unlocked_level):
		completed[i] = true
		stars[i] = 1
	# Give returning players a friendly, honest starting point.
	if has_progress():
		unlock_achievement("first_steps")
	story_seen["migrated"] = true


func _sanitize_bool_array(value: Variant, size: int) -> Array:
	var out: Array = []
	out.resize(size)
	out.fill(false)
	var kind := typeof(value)
	if kind == TYPE_ARRAY or kind == TYPE_PACKED_INT32_ARRAY or kind == TYPE_PACKED_BYTE_ARRAY:
		var source: Array = []
		source.assign(value)
		for i in mini(size, source.size()):
			out[i] = bool(source[i])
	return out


func _sanitize_int_array(value: Variant, size: int, minimum: int, maximum: int) -> Array:
	var out: Array = []
	out.resize(size)
	out.fill(minimum)
	if value is Array:
		for i in mini(size, value.size()):
			out[i] = clampi(int(value[i]), minimum, maximum)
	return out


func _sanitize_string_array(value: Variant) -> Array:
	var out: Array = []
	var kind := typeof(value)
	if kind == TYPE_ARRAY or kind == TYPE_PACKED_STRING_ARRAY:
		for item in value:
			out.append(String(item))
	return out


func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("save", "version", SAVE_VERSION)
	config.set_value("progress", "unlocked", unlocked_level)
	config.set_value("progress", "best_score", best_score)
	config.set_value("progress", "completed", completed)
	config.set_value("progress", "stars", stars)
	config.set_value("progress", "level_scores", level_best_scores)
	config.set_value("progress", "level_coins", level_best_coins)
	config.set_value("progress", "optional", optional_completed)
	config.set_value("progress", "shards", shards_found)
	config.set_value("progress", "crystals", world_crystals)
	config.set_value("progress", "lifetime_coins", lifetime_coins)
	config.set_value("progress", "achievements", achievements.keys())
	var seen_keys: Array = story_seen.keys()
	config.set_value("progress", "story", seen_keys)
	config.set_value("settings", "music", music_volume)
	config.set_value("settings", "sfx", sfx_volume)
	config.set_value("settings", "touch", touch_mode)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Could not save Mohit Adventure data: %s" % error)
