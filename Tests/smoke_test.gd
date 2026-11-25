## Automated smoke test used during development.
## Run with:
##   godot --path . res://Tests/SmokeTest.tscn
extends Node

var _passed := 0
var _failed := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.suppress_story = true
	await _run()
	print("---------------------------------------------")
	print("SMOKE TEST: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("SMOKE TEST PASSED")
	else:
		print("SMOKE TEST FAILED")
	get_tree().quit(0 if _failed == 0 else 1)


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  ", label)
	else:
		_failed += 1
		printerr("  FAIL  ", label)


func _wait_physics(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame


func _run() -> void:
	print("MOHT ADVENTURE SMOKE TEST")
	print("Checking level data...")
	_check(LevelData.get_level(0)["platforms"].size() > 10, "Level 1 has platforms")
	_check(LevelData.get_level(1)["enemies"].size() > 10, "Level 2 has enemies")
	_check(LevelData.get_level(2)["moving_platforms"].size() >= 3, "Level 3 has moving platforms")

	print("Loading Level 1...")
	var level = load("res://Levels/Level1.tscn").instantiate()
	add_child(level)
	await _wait_physics(20)

	_check(level.level_index == 0, "Level 1 index override works")
	_check(level.player != null, "Player spawned")
	_check(level.hud != null and level.pause_menu != null, "HUD and pause menu exist")
	_check(get_tree().get_nodes_in_group("coins").size() >= 30, "Coins spawned")
	_check(level.player.is_on_floor(), "Player is standing on the ground")
	_check(not level.touch_controls.visible, "Touch controls hidden on desktop (auto mode)")

	var start_x: float = level.player.global_position.x
	Input.action_press("move_right")
	await _wait_physics(50)
	Input.action_release("move_right")
	_check(level.player.global_position.x > start_x + 25.0, "Keyboard/touch action moves player right")

	await _wait_physics(60)
	var jump_y: float = level.player.global_position.y
	Input.action_press("jump")
	await _wait_physics(2)
	Input.action_release("jump")
	await _wait_physics(8)
	_check(level.player.global_position.y < jump_y - 8.0, "Jump action lifts player")
	await _wait_physics(70)

	var coins := get_tree().get_nodes_in_group("coins")
	var coins_before: int = GameManager.level_coins
	level.player.global_position = coins[0].global_position
	await _wait_physics(5)
	_check(GameManager.level_coins > coins_before, "Coin collection updates GameManager")
	_check(GameManager.score >= 10, "Coin collection awards score")

	var enemies := get_tree().get_nodes_in_group("enemies")
	_check(enemies.size() > 1, "Level has enemies")
	var score_before_stomp: int = GameManager.score
	var stomped_enemy = enemies[0]
	level.player.global_position = stomped_enemy.global_position + Vector2(0, -70)
	level.player.velocity = Vector2(0, 300)
	await _wait_physics(12)
	var defeated: bool = not is_instance_valid(stomped_enemy) or bool(stomped_enemy.get("_dead"))
	_check(defeated, "Stomping an enemy from above defeats it")
	_check(GameManager.score >= score_before_stomp + 50, "Stomping an enemy awards score")

	var side_enemy = enemies[1]
	level.player.invulnerable_time = 0.0
	var side_health: int = level.player.health
	level.player.global_position = side_enemy.global_position + Vector2(0, -8)
	level.player.velocity = Vector2.ZERO
	await _wait_physics(10)
	_check(level.player.health == side_health - 1, "Touching an enemy from the side hurts")
	await _wait_physics(20)

	level.player.invulnerable_time = 0.0
	var health_before: int = level.player.health
	level.player.take_damage(1, level.player.global_position + Vector2(100, 0))
	await _wait_physics(2)
	_check(level.player.health == health_before - 1, "Enemy/spike damage removes a heart")

	level.pause_menu.open()
	_check(get_tree().paused, "Pause menu pauses the tree")
	level.pause_menu.close()
	_check(not get_tree().paused, "Resume unpauses the tree")

	var checkpoint = get_tree().get_first_node_in_group("checkpoints")
	_check(checkpoint != null, "Level has a checkpoint")
	if checkpoint != null:
		level.player.global_position = checkpoint.global_position + Vector2(0, -30)
		await _wait_physics(8)
		_check(checkpoint.get("_active"), "Checkpoint activates when touched")

	var lives_before: int = GameManager.lives
	level.player.invulnerable_time = 0.0
	level.player.die()
	await get_tree().create_timer(1.4).timeout
	_check(GameManager.lives == lives_before - 1, "Dying removes one life")
	_check(level.player.alive, "Player respawns after losing a life")
	if checkpoint != null:
		_check(absf(level.player.global_position.x - checkpoint.global_position.x) < 5.0, "Respawn uses the checkpoint")

	var flag = get_tree().get_first_node_in_group("finish_flags")
	_check(flag != null, "Level has a finish flag")
	if flag != null:
		level.player.global_position = flag.global_position + Vector2(0, -30)
		await _wait_physics(8)
	await get_tree().create_timer(1.1).timeout
	_check(level.level_complete.visible, "Touching the finish flag shows level complete")
	_check(get_tree().paused, "Level complete screen pauses gameplay")
	get_tree().paused = false
	AudioManager.set_music_paused(false)
	level.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame

	print("Loading Levels 2 and 3...")
	for index in [1, 2]:
		var path: String = GameManager.LEVEL_PATHS[index]
		var next_level = load(path).instantiate()
		add_child(next_level)
		await _wait_physics(20)
		_check(next_level.level_index == index, "Level %d index override works" % (index + 1))
		_check(next_level.player != null, "Level %d player spawned" % (index + 1))
		_check(next_level.player.is_on_floor(), "Level %d ground collision works" % (index + 1))
		_check(get_tree().get_nodes_in_group("coins").size() > 20, "Level %d coins spawned" % (index + 1))
		if index == 2:
			var movers := get_tree().get_nodes_in_group("moving_platforms")
			_check(movers.size() >= 3, "Level 3 moving platforms spawned")
			if movers.size() > 0:
				var start_pos: Vector2 = movers[0].position
				await _wait_physics(40)
				_check(movers[0].position.distance_to(start_pos) > 1.0, "Moving platform animates")
				var mover = movers[0]
				var top_y: float = mover.position.y - mover.size.y * 0.5
				next_level.player.global_position = Vector2(mover.position.x, top_y - 35.0)
				next_level.player.velocity = Vector2.ZERO
				await _wait_physics(20)
				var ride_start: Vector2 = next_level.player.global_position
				await _wait_physics(40)
				_check(absf(next_level.player.global_position.x - ride_start.x) > 1.0, "Player rides a moving platform")
		next_level.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
