## Development flow test: exercises menus, settings, level select, pause,
## level-complete, game-over and the scene transitions between them.
##
## It runs as a bootstrap scene but keeps its real work in a watcher node that
## is added directly to the tree root, so it survives the scene changes it is
## testing.
##
## Run with:
##   godot --path . res://Tests/FlowTest.tscn
extends Node


func _ready() -> void:
	var watcher := FlowWatcher.new()
	watcher.name = "FlowWatcher"
	get_tree().root.add_child.call_deferred(watcher)


class FlowWatcher extends Node:
	var _passed := 0
	var _failed := 0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		GameManager.suppress_story = true
		await get_tree().process_frame
		await _run()
		print("---------------------------------------------")
		print("FLOW TEST: %d passed, %d failed" % [_passed, _failed])
		print("FLOW TEST PASSED" if _failed == 0 else "FLOW TEST FAILED")
		get_tree().quit(0 if _failed == 0 else 1)

	func _check(condition: bool, label: String) -> void:
		if condition:
			_passed += 1
			print("  PASS  ", label)
		else:
			_failed += 1
			printerr("  FAIL  ", label)

	func _run() -> void:
		print("MOHT ADVENTURE FLOW TEST")
		# Let the autoload startup fade finish so scene changes are accepted.
		await _wait(0.6)
		# Start from a deterministic state so lock checks are meaningful.
		GameManager.unlocked_level = 0
		GameManager.touch_mode = 0

		await _test_menu_ui()
		await _test_new_game()
		await _test_pause()
		await _test_level_complete()
		await _test_game_over()
		await _test_level_select_and_restart()

		# Tidy up so the next launch starts on the menu.
		GameManager.return_to_menu()
		await _wait_scene(GameManager.MENU_PATH)

	func _test_menu_ui() -> void:
		print("Testing menu UI...")
		var menu = load(GameManager.MENU_PATH).instantiate()
		add_child(menu)
		await get_tree().process_frame
		await get_tree().process_frame

		menu.settings_button.pressed.emit()
		await get_tree().process_frame
		_check(menu.settings_panel.visible, "Settings button opens the settings panel")
		menu.settings_panel.music_slider.value = 30.0
		await get_tree().process_frame
		_check(absf(GameManager.music_volume - 0.30) < 0.02, "Music slider updates the volume")
		menu.settings_panel.touch_option.select(1)
		menu.settings_panel.touch_option.item_selected.emit(1)
		await get_tree().process_frame
		_check(GameManager.touch_mode == 1, "Touch option updates the setting")
		menu.settings_panel.close()
		await get_tree().process_frame
		_check(not menu.settings_panel.visible, "Settings panel closes")

		menu.levels_button.pressed.emit()
		await get_tree().process_frame
		_check(menu.level_select.visible, "Level select opens")
		_check(not menu.level_select.play_buttons[0].disabled, "Level 1 is playable")
		_check(menu.level_select.play_buttons[1].disabled, "Level 2 is locked at the start")
		menu.level_select.close()
		await get_tree().process_frame

		menu.free()
		# Restore default settings.
		GameManager.set_music_volume(0.65)
		GameManager.set_touch_mode(0)

	func _test_new_game() -> void:
		print("Testing Play and the first level...")
		GameManager.start_new_game()
		await _wait_scene(GameManager.LEVEL_PATHS[0])
		var level := get_tree().current_scene
		_check(level.level_index == 0, "Play starts Level 1")
		_check(GameManager.level_index == 0, "GameManager tracks the level index")
		_check(level.player != null and level.player.alive, "Player is alive in the level")
		await _wait(0.2)

	func _test_pause() -> void:
		print("Testing the pause menu...")
		var level := get_tree().current_scene
		var event := InputEventAction.new()
		event.action = &"pause"
		event.pressed = true
		Input.parse_input_event(event)
		await get_tree().process_frame
		await get_tree().process_frame
		_check(get_tree().paused and level.pause_menu.visible, "Escape action opens the pause menu")
		level.pause_menu.close()
		await get_tree().process_frame
		_check(not get_tree().paused and not level.pause_menu.visible, "Pause menu closes and resumes")

	func _test_level_complete() -> void:
		print("Testing level completion and progression...")
		var level := get_tree().current_scene
		level.call("_on_level_finished")
		await _wait(1.3)
		_check(level.level_complete.visible, "Level complete overlay shows")
		_check(GameManager.unlocked_level >= 1, "Completing Level 1 unlocks Level 2")
		level.level_complete.next_button.pressed.emit()
		await _wait_scene(GameManager.LEVEL_PATHS[1])
		_check(get_tree().current_scene.level_index == 1, "Next Level loads Level 2")

	func _test_game_over() -> void:
		print("Testing game over and retry...")
		var level := get_tree().current_scene
		level.call("_show_game_over")
		await get_tree().process_frame
		_check(level.game_over.visible and get_tree().paused, "Game over overlay shows and pauses")
		level.game_over.retry_button.pressed.emit()
		await _wait_scene(GameManager.LEVEL_PATHS[1])
		_check(get_tree().current_scene.level_index == 1, "Retry reloads the current level")
		_check(not get_tree().paused, "Retry unpauses the game")

	func _test_level_select_and_restart() -> void:
		print("Testing level select and pause restart...")
		GameManager.return_to_menu()
		await _wait_scene(GameManager.MENU_PATH)
		var menu = get_tree().current_scene
		_check(menu.level_select != null, "Main menu loads with its level select")
		menu.level_select.open()
		await get_tree().process_frame
		_check(not menu.level_select.play_buttons[1].disabled, "Unlocked Level 2 is now playable")
		menu.level_select.close()

		GameManager.play_level(1)
		await _wait_scene(GameManager.LEVEL_PATHS[1])
		var level := get_tree().current_scene
		level.pause_menu.open()
		await get_tree().process_frame
		level.pause_menu.restart_button.pressed.emit()
		await _wait_scene(GameManager.LEVEL_PATHS[1])
		_check(get_tree().current_scene.level_index == 1, "Pause restart reloads the level")
		_check(not get_tree().paused, "Restart unpauses the game")

	func _wait(seconds: float) -> void:
		await get_tree().create_timer(seconds).timeout

	func _wait_scene(path: String) -> void:
		var timeout := 240
		while timeout > 0:
			var current := get_tree().current_scene
			if current != null and current.scene_file_path == path:
				# Give the level a couple of frames to finish _ready().
				await get_tree().process_frame
				await get_tree().process_frame
				return
			await get_tree().process_frame
			timeout -= 1
		_check(false, "Scene transition reached %s" % path)
