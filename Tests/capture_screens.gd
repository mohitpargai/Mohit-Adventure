## Development helper: renders the menu, the 30-level select, story overlay and
## one stage plus one boss arena from each of the six worlds, saving PNGs so
## the expansion can be checked without playing every level by hand.
##
## It backs up and restores the real save file so capturing never changes
## progression.
##
## Run with (a real window is required; --headless cannot render images):
##   godot --path . res://Tests/CaptureScreens.tscn
extends Node

const OUTPUT_DIR := "res://Screenshots"

var _save_backup: PackedByteArray
var _had_save := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_backup_save()
	GameManager.suppress_story = true
	GameManager.test_mode = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	await _capture_menu()
	await _capture_worlds()
	await _capture_story_and_complete()
	_restore_save()
	print("SCREENSHOTS SAVED")
	get_tree().quit(0)


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
# Menu and new UI screens
# ---------------------------------------------------------------------------
func _capture_menu() -> void:
	var menu = load("res://Scenes/MainMenu.tscn").instantiate()
	add_child(menu)
	await _wait_frames(40)
	await _save("menu")

	menu.settings_button.pressed.emit()
	await _wait_frames(4)
	await _save("menu_settings")
	menu.settings_panel.close()
	await _wait_frames(2)

	menu.levels_button.pressed.emit()
	await _wait_frames(6)
	await _save("level_select")
	menu.level_select.scroll.scroll_vertical = int(menu.level_select.scroll.get_v_scroll_bar().max_value)
	await _wait_frames(6)
	await _save("level_select_worlds")
	menu.level_select.close()
	await _wait_frames(2)

	menu.achievements_button.pressed.emit()
	await _wait_frames(6)
	await _save("achievements")
	menu.achievements.close()
	await _wait_frames(2)

	menu.queue_free()
	await _wait_frames(3)


# ---------------------------------------------------------------------------
# One regular stage and one boss arena per world
# ---------------------------------------------------------------------------
func _capture_worlds() -> void:
	for world in WorldData.WORLD_COUNT:
		var slug: String = WorldData.world_name(world).to_lower().replace(" ", "_")
		var regular := world * WorldData.LEVELS_PER_WORLD
		var boss := regular + WorldData.LEVELS_PER_WORLD - 1
		await _capture_level(regular, "world%d_%s" % [world + 1, slug])
		await _capture_level(boss, "world%d_%s_boss" % [world + 1, slug])


func _capture_level(index: int, file_name: String) -> void:
	GameManager.score = 0
	var level = load(GameManager.LEVEL_PATHS[index]).instantiate()
	add_child(level)
	await _wait_frames(4)
	# The animated level-title banner would cover the stage and the boss.
	level.hud.intro_banner.visible = false
	# Disable player collision before staging so no coin, enemy or hazard is
	# touched by the capture pose.
	level.player.set_deferred("collision_layer", 0)
	await _wait_frames(20)
	_place_player_mid(level)
	level.player.heal(level.player.MAX_HEALTH)
	level.player.invulnerable_time = 0.0
	await _wait_frames(34)
	level.player.heal(level.player.MAX_HEALTH)
	level.player.visual.modulate.a = 1.0
	# Clear anything picked up during the first frames after spawning.
	GameManager.score = 0
	GameManager.score_changed.emit(0)
	GameManager.set_level_coin_total(level._coins_total)
	await _save(file_name)
	level.queue_free()
	await _wait_frames(4)


func _place_player_mid(level: Node) -> void:
	var data: Dictionary = LevelData.get_level(level.level_index)
	var best: Dictionary = {}
	for platform in data["platforms"]:
		if float(platform["h"]) < 150.0:
			continue
		if best.is_empty() or float(platform["w"]) > float(best["w"]):
			best = platform
	if best.is_empty():
		return
	var center := float(best["x"]) + float(best["w"]) * 0.5
	var chosen := center
	for offset in [0.0, -150.0, 150.0, -300.0, 300.0, -450.0, 450.0]:
		var candidate := clampf(
			center + offset,
			float(best["x"]) + 80.0,
			float(best["x"]) + float(best["w"]) - 80.0
		)
		if _is_safe_spot(data, candidate):
			chosen = candidate
			break
	level.player.global_position = Vector2(chosen, float(best["y"]) - 40.0)
	level.player.velocity = Vector2.ZERO
	level.player.setup_camera(Rect2(0.0, 0.0, float(data["width"]), float(data["height"])))


func _is_safe_spot(data: Dictionary, x: float) -> bool:
	for spike in data["spikes"]:
		if absf(x - float(spike["x"])) < 130.0:
			return false
	for hazard in data.get("hazards", []):
		if absf(x - float(hazard.get("x", 0.0))) < 150.0:
			return false
	for enemy in data["enemies"]:
		if absf(x - float(enemy["x"])) < 120.0:
			return false
	for coin in data["coins"]:
		if coin is Vector2 and absf(x - coin.x) < 90.0:
			return false
	for powerup in data.get("powerups", []):
		if absf(x - float(powerup.get("x", 0.0))) < 80.0:
			return false
	for treasure in data.get("treasure", []):
		if treasure is Vector2 and absf(x - treasure.x) < 90.0:
			return false
	var shard = data.get("shard")
	if shard != null and shard is Vector2 and absf(x - shard.x) < 90.0:
		return false
	return true


# ---------------------------------------------------------------------------
# Story overlay and level-complete screen
# ---------------------------------------------------------------------------
func _capture_story_and_complete() -> void:
	var level = load(GameManager.LEVEL_PATHS[0]).instantiate()
	add_child(level)
	await _wait_frames(4)
	level.hud.intro_banner.visible = false
	await _wait_frames(30)

	GameManager.suppress_story = false
	level.story_card.show_story(
		WorldData.INTRO_LINES, "PROLOGUE", "THE STOLEN CRYSTALS", ""
	)
	await _wait_frames(18)
	await _save("story_intro")
	level.story_card.skip_button.pressed.emit()
	await _wait_frames(30)
	GameManager.suppress_story = true

	GameManager.set_touch_mode(1)
	await _wait_frames(6)
	await _save("level1_touch")
	GameManager.set_touch_mode(0)
	await _wait_frames(2)

	level.call("_on_level_finished")
	var guard := 0
	while not level.level_complete.visible and guard < 180:
		await _wait_frames(1)
		guard += 1
	await _save("level_complete")
	get_tree().paused = false
	AudioManager.set_music_paused(false)
	level.queue_free()
	await _wait_frames(4)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
func _save(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [OUTPUT_DIR, file_name]
	var error := image.save_png(ProjectSettings.globalize_path(path))
	print("  saved %s (error %d)" % [path, error])


func _wait_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
