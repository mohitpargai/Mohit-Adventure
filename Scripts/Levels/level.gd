## Builds a playable level from LevelData, wires the HUD and overlays, and
## owns the gameplay flow: coins, deaths, missions, bosses, checkpoints,
## crystal shards, story cards, finish and game over.
extends Node2D

const PLAYER_SCENE := preload("res://Scenes/Player.tscn")
const PLATFORM_SCENE := preload("res://Scenes/Platform.tscn")
const COIN_SCENE := preload("res://Scenes/Coin.tscn")
const ENEMY_SCENE := preload("res://Scenes/Enemy.tscn")
const SPIKES_SCENE := preload("res://Scenes/Spikes.tscn")
const MOVING_PLATFORM_SCENE := preload("res://Scenes/MovingPlatform.tscn")
const CHECKPOINT_SCENE := preload("res://Scenes/Checkpoint.tscn")
const FLAG_SCENE := preload("res://Scenes/FinishFlag.tscn")
const DECORATION_SCENE := preload("res://Scenes/Decoration.tscn")
const BURST_SCENE := preload("res://Scenes/BurstEffect.tscn")
const HAZARD_SCENE := preload("res://Scenes/Hazard.tscn")
const POWERUP_SCENE := preload("res://Scenes/PowerUp.tscn")
const TREASURE_SCENE := preload("res://Scenes/Treasure.tscn")
const SHARD_SCENE := preload("res://Scenes/CrystalShard.tscn")
const BREAKABLE_SCENE := preload("res://Scenes/BreakablePlatform.tscn")
const DISAPPEARING_SCENE := preload("res://Scenes/DisappearingPlatform.tscn")
const BOSS_SCENE := preload("res://Scenes/Boss.tscn")

@export var level_index := 0

@onready var world: Node2D = $World
@onready var background: Control = $Background/ForestBackground
@onready var hud: Control = $UI/HUD
@onready var touch_controls: Control = $UI/TouchControls
@onready var pause_menu: Control = $UI/PauseMenu
@onready var level_complete: Control = $UI/LevelComplete
@onready var game_over: Control = $UI/GameOver
@onready var story_card: Control = $UI/StoryCard

var player: CharacterBody2D
var _data: Dictionary
var _respawn_point := Vector2.ZERO
var _coins_total := 0
var _level_over := false
var _death_in_progress := false

# Missions -----------------------------------------------------------------
var _mission: Dictionary = {}
var _mission_kind := ""
var _mission_target := 1
var _mission_progress := 0
var _mission_done := false

# World progress -----------------------------------------------------------
var _world := 0
var _shard_collected := false
var _treasures_opened := 0
var _checkpoints_activated := 0
var _boss: Node = null
var _boss_defeated := false


func _ready() -> void:
	GameManager.in_game = true
	# Keep the autoload in sync even when a level scene is run directly from
	# the editor. Normal scene transitions already set this value.
	GameManager.level_index = level_index
	_data = LevelData.get_level(level_index)
	_world = WorldData.world_index_for_level(level_index)
	_respawn_point = _data["start"]
	_mission = _data.get("mission", {})
	_mission_kind = String(_mission.get("optional_kind", ""))
	_mission_target = maxi(1, int(_mission.get("optional_target", 1)))

	background.call("set_variant", int(_data["background"]))
	build_world()
	_spawn_player()
	_configure_ui()

	GameManager.set_level_coin_total(_coins_total)
	GameManager.current_mission = _mission
	hud.call("set_level", level_index)
	hud.call("set_mission", _mission)
	hud.call("show_intro")
	hud.call("bind_player", player)
	call_deferred("_show_entry_story")


func build_world() -> void:
	for child in world.get_children():
		child.queue_free()

	_add_boundary_walls()
	_build_platforms()
	_build_decorations()
	_build_coins()
	_build_enemies()
	_build_spikes()
	_build_moving_platforms()
	_build_checkpoints()
	_build_hazards()
	_build_powerups()
	_build_treasure()
	_build_shard()
	_build_breakables()
	_build_disappearing()
	_build_boss()
	if not bool(_data.get("boss", false)):
		_build_finish()


func _build_platforms() -> void:
	var index := 0
	for info in _data["platforms"]:
		var platform = PLATFORM_SCENE.instantiate()
		platform.position = Vector2(float(info["x"]) + float(info["w"]) * 0.5, float(info["y"]) + float(info["h"]) * 0.5)
		platform.call("setup", Vector2(float(info["w"]), float(info["h"])), int(info["style"]), 8000 + level_index * 977 + index * 31)
		world.add_child(platform)
		index += 1


func _build_coins() -> void:
	for pos in _data["coins"]:
		var coin = COIN_SCENE.instantiate()
		coin.position = pos
		coin.picked_up.connect(_on_coin_picked)
		world.add_child(coin)
		_coins_total += 1


func _build_enemies() -> void:
	for info in _data["enemies"]:
		var enemy = ENEMY_SCENE.instantiate()
		enemy.kind = int(info["kind"])
		enemy.patrol_left = float(info["left"])
		enemy.patrol_right = float(info["right"])
		enemy.speed = float(info["speed"])
		enemy.phase = float(info["phase"])
		enemy.position = Vector2(float(info["x"]), float(info["y"]))
		if enemy.kind == 0:
			enemy.tint = Color(0.30, 0.76, 0.37) if int(info["phase"] * 3.0) % 2 == 0 else Color(0.42, 0.68, 0.92)
		enemy.defeated.connect(_on_enemy_defeated)
		world.add_child(enemy)


func _build_spikes() -> void:
	for info in _data["spikes"]:
		var spikes = SPIKES_SCENE.instantiate()
		spikes.position = Vector2(float(info["x"]), float(info["y"]))
		spikes.call("setup", Vector2(float(info["w"]), 32.0), int(info["count"]))
		world.add_child(spikes)


func _build_moving_platforms() -> void:
	for info in _data["moving_platforms"]:
		var platform = MOVING_PLATFORM_SCENE.instantiate()
		platform.position = Vector2(float(info["x"]), float(info["y"]))
		platform.call("setup", info["travel"], info["size"], float(info["speed"]), float(info["phase"]), int(info.get("style", _data.get("style", 0))))
		world.add_child(platform)


func _build_checkpoints() -> void:
	for pos in _data.get("checkpoints", []):
		var checkpoint = CHECKPOINT_SCENE.instantiate()
		checkpoint.position = pos
		checkpoint.activated.connect(_on_checkpoint_activated)
		world.add_child(checkpoint)


func _build_finish() -> void:
	var flag = FLAG_SCENE.instantiate()
	flag.position = _data["finish"]
	flag.reached.connect(_on_level_finished)
	world.add_child(flag)


# ---------------------------------------------------------------------------
# New world objects
# ---------------------------------------------------------------------------
func _build_hazards() -> void:
	for info in _data.get("hazards", []):
		var hazard = HAZARD_SCENE.instantiate()
		hazard.position = Vector2(float(info.get("x", 0.0)), float(info.get("y", 0.0)))
		hazard.call("setup", info, _world)
		world.add_child(hazard)


func _build_powerups() -> void:
	for info in _data.get("powerups", []):
		var powerup = POWERUP_SCENE.instantiate()
		powerup.kind = int(info.get("kind", 0))
		powerup.position = Vector2(float(info.get("x", 0.0)), float(info.get("y", 0.0)))
		powerup.collected.connect(_on_powerup_collected)
		world.add_child(powerup)


func _build_treasure() -> void:
	for pos in _data.get("treasure", []):
		var treasure = TREASURE_SCENE.instantiate()
		treasure.position = pos
		treasure.bonus = 5
		treasure.opened.connect(_on_treasure_opened)
		world.add_child(treasure)


func _build_shard() -> void:
	var shard_pos = _data.get("shard", null)
	if shard_pos == null:
		return
	var shard = SHARD_SCENE.instantiate()
	shard.position = shard_pos
	shard.color = WorldData.accent(_world).lerp(Color(1, 1, 1), 0.35)
	shard.collected.connect(_on_shard_collected)
	world.add_child(shard)


func _build_breakables() -> void:
	for info in _data.get("breakable_platforms", []):
		var platform = BREAKABLE_SCENE.instantiate()
		var size := Vector2(float(info["w"]), float(info["h"]))
		platform.position = Vector2(float(info["x"]) + size.x * 0.5, float(info["y"]) + size.y * 0.5)
		platform.call("setup", size, int(info.get("style", 0)), 5000 + level_index * 131 + int(info["x"]))
		world.add_child(platform)


func _build_disappearing() -> void:
	for info in _data.get("disappearing_platforms", []):
		var platform = DISAPPEARING_SCENE.instantiate()
		var size := Vector2(float(info["w"]), float(info["h"]))
		platform.position = Vector2(float(info["x"]) + size.x * 0.5, float(info["y"]) + size.y * 0.5)
		platform.call("setup", size, int(info.get("style", 0)), float(info.get("phase", 0.0)), float(info.get("period", 3.0)))
		world.add_child(platform)


func _build_boss() -> void:
	if not bool(_data.get("boss", false)):
		return
	_boss = BOSS_SCENE.instantiate()
	_boss.position = Vector2(float(_data.get("boss_x", 1180.0)), float(_data.get("boss_y", 528.0)))
	_boss.call("setup", _world, int(_data.get("boss_hp", 6)), Rect2(0.0, 0.0, float(_data["width"]), float(_data["height"])))
	_boss.health_changed.connect(_on_boss_health_changed)
	_boss.defeated.connect(_on_boss_defeated)
	world.add_child(_boss)
	var boss_title := WorldData.boss_name(_world)
	hud.call("show_boss_bar", boss_title, int(_data.get("boss_hp", 6)), int(_data.get("boss_hp", 6)))


func _build_decorations() -> void:
	for info in _data.get("decorations", []):
		_add_decoration(int(info["kind"]), float(info["scale"]), int(info["seed"]), Vector2(float(info["x"]), float(info["y"])))

	# Scatter extra props from the current world along every ground strip.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4100 + level_index * 601
	var start_x: float = _data["start"].x
	var finish_x: float = _data["finish"].x
	var pool: Array = WorldData.decor_kinds(_world)
	for platform in _data["platforms"]:
		if float(platform["h"]) < 150.0:
			continue
		var left := float(platform["x"])
		var right := float(platform["x"]) + float(platform["w"])
		var x := left + rng.randf_range(70.0, 160.0)
		while x < right - 80.0:
			if absf(x - start_x) < 300.0 or absf(x - finish_x) < 300.0:
				x += rng.randf_range(140.0, 220.0)
				continue
			if _near_spike(x):
				x += rng.randf_range(100.0, 160.0)
				continue
			var kind: int = int(pool[rng.randi_range(0, pool.size() - 1)])
			if kind == 3 and rng.randf() < 0.5:
				kind = int(pool[0])
			var deco_scale := rng.randf_range(0.8, 1.2)
			if kind == 0 or kind == 1 or kind == 4:
				deco_scale = rng.randf_range(0.9, 1.3)
			var deco_seed := int(x) * 13 + level_index * 191 + rng.randi_range(0, 999)
			_add_decoration(kind, deco_scale, deco_seed, Vector2(x, float(platform["y"])))
			x += rng.randf_range(150.0, 290.0)


func _add_decoration(kind: int, scale_value: float, seed_value: int, at: Vector2) -> void:
	var deco = DECORATION_SCENE.instantiate()
	deco.position = at
	deco.z_index = 1 if kind == 7 else -6
	deco.call("setup", kind, scale_value, seed_value)
	world.add_child(deco)


func _near_spike(x: float) -> bool:
	for spike in _data["spikes"]:
		if absf(x - float(spike["x"])) < 110.0:
			return true
	return false


func _add_boundary_walls() -> void:
	var width: float = _data["width"]
	var height: float = _data["height"]
	_add_wall(-22.0, height * 0.5, 44.0, height + 400.0)
	_add_wall(width + 22.0, height * 0.5, 44.0, height + 400.0)


func _add_wall(x: float, y: float, width: float, height: float) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(x, y)
	body.collision_layer = 2
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, height)
	shape.shape = rect
	body.add_child(shape)
	world.add_child(body)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = _data["start"]
	player.kill_y = float(_data["kill_y"])
	player.spawn_position = _data["start"]
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_player_damaged)
	world.add_child(player)
	player.setup_camera(Rect2(0.0, 0.0, float(_data["width"]), float(_data["height"])))


func _configure_ui() -> void:
	hud.pause_pressed.connect(pause_menu.open)
	pause_menu.paused_state_changed.connect(_on_pause_state_changed)
	touch_controls.set_controls_enabled(not _level_over)
	touch_controls.add_to_group("touch_controls")


# ---------------------------------------------------------------------------
# Story
# ---------------------------------------------------------------------------
func _show_entry_story() -> void:
	if GameManager.suppress_story:
		return
	var local := WorldData.local_index(level_index)
	if level_index == 0 and not GameManager.story_key_seen("intro"):
		await _show_story(
			"intro", "PROLOGUE", "THE STOLEN CRYSTALS",
			WorldData.INTRO_LINES, ""
		)
	if local == 0 and not GameManager.story_key_seen("world_%d" % _world):
		await _show_story(
			"world_%d" % _world,
			"WORLD %d" % (_world + 1),
			WorldData.world_name(_world),
			[WorldData.WORLD_STORIES[_world]],
			WorldData.world_subtitle(_world)
		)
	elif bool(_data.get("boss", false)) and not GameManager.story_key_seen("boss_%d" % _world):
		await _show_story(
			"boss_%d" % _world,
			"WORLD %d BOSS" % (_world + 1),
			WorldData.boss_name(_world),
			[WorldData.BOSS_STORIES[_world]],
			""
		)


func _show_story(key: String, chapter: String, title: String, lines: Array, subtitle: String = "") -> void:
	if GameManager.suppress_story or lines.is_empty() or GameManager.story_key_seen(key):
		return
	if not is_instance_valid(story_card):
		return
	pause_menu.call("set_enabled", false)
	touch_controls.set_controls_enabled(false)
	story_card.call("show_story", lines, chapter, title, subtitle)
	await story_card.finished
	GameManager.mark_story_seen(key)
	pause_menu.call("set_enabled", not _level_over)
	touch_controls.set_controls_enabled(not _level_over and player.alive)


# ---------------------------------------------------------------------------
# Gameplay events
# ---------------------------------------------------------------------------
func _on_coin_picked(value: int, at: Vector2) -> void:
	GameManager.add_coin(value)
	_spawn_popup("+%d" % (10 * value), at + Vector2(0, -20), Color(1.0, 0.87, 0.40))
	_spawn_burst(at, Color(1.0, 0.82, 0.30), 10)
	if _mission_kind == "coins":
		_advance_mission(GameManager.level_coins, true)


func _on_enemy_defeated(_enemy: Node, at: Vector2) -> void:
	GameManager.add_score(50)
	_spawn_popup("+50", at + Vector2(0, -26), Color(0.76, 1.0, 0.58))
	if _mission_kind == "enemies":
		_advance_mission(1)


func _on_checkpoint_activated(at: Vector2) -> void:
	_checkpoints_activated += 1
	_respawn_point = Vector2(at.x, at.y - 30.0)
	player.call("heal", 1)
	_spawn_popup("CHECKPOINT!", at + Vector2(0, -120), Color(0.68, 1.0, 0.62))
	_spawn_burst(at + Vector2(0, -100), Color(0.68, 1.0, 0.62), 18)
	if _mission_kind == "checkpoints":
		_advance_mission(1)


func _on_powerup_collected(kind: int, at: Vector2) -> void:
	if kind == 2:
		GameManager.add_life()
		_spawn_popup("EXTRA LIFE!", at + Vector2(0, -34), Color(1.0, 0.66, 0.72))
	else:
		player.call("apply_powerup", kind)
		var label := "SHIELD!" if kind == 0 else ("SPEED!" if kind == 1 else "HEALED!")
		var color := Color(0.62, 0.90, 1.0) if kind == 0 else (Color(1.0, 0.88, 0.42) if kind == 1 else Color(0.66, 1.0, 0.68))
		_spawn_popup(label, at + Vector2(0, -34), color)
	_spawn_burst(at, Color(1.0, 0.92, 0.62), 14)


func _on_treasure_opened(at: Vector2, bonus: int) -> void:
	_treasures_opened += 1
	for i in bonus:
		GameManager.add_coin(1)
	_spawn_popup("TREASURE +%d" % bonus, at + Vector2(0, -70), Color(1.0, 0.86, 0.36))
	_spawn_burst(at + Vector2(0, -24), Color(1.0, 0.84, 0.32), 26)
	if _mission_kind == "treasure":
		_advance_mission(1)


func _on_shard_collected(at: Vector2) -> void:
	if _shard_collected:
		return
	_shard_collected = true
	GameManager.collect_shard(level_index)
	_spawn_popup("CRYSTAL SHARD!", at + Vector2(0, -40), Color(0.66, 0.92, 1.0))
	_spawn_burst(at, Color(0.62, 0.90, 1.0), 26)
	if _mission_kind == "shard":
		_advance_mission(1)


func _advance_mission(amount: int, absolute: bool = false) -> void:
	if _mission_done or _mission.is_empty():
		return
	if absolute:
		_mission_progress = maxi(_mission_progress, amount)
	else:
		_mission_progress += amount
	if _mission_progress >= _mission_target:
		_mission_done = true
		AudioManager.play_sfx("unlock")
		_spawn_popup("MISSION COMPLETE!", player.global_position + Vector2(0, -80), Color(0.66, 1.0, 0.68))
	hud.call("update_mission", _mission_progress, _mission_done)


func _on_player_damaged() -> void:
	hud.call("show_hurt_flash")


func _on_player_died() -> void:
	if _level_over or _death_in_progress:
		return
	_death_in_progress = true
	touch_controls.set_controls_enabled(false)
	var remaining := GameManager.lose_life()
	await get_tree().create_timer(1.1).timeout
	if _level_over:
		return
	if remaining > 0:
		player.call("respawn", _respawn_point)
		player.call("setup_camera", Rect2(0.0, 0.0, float(_data["width"]), float(_data["height"])))
		touch_controls.set_controls_enabled(true)
		_death_in_progress = false
		hud.call("show_intro", "Try again!")
	else:
		_show_game_over()


func _show_game_over() -> void:
	_level_over = true
	GameManager.record_game_over()
	pause_menu.call("set_enabled", false)
	touch_controls.set_controls_enabled(false)
	game_over.call("show_game_over", GameManager.score)


# ---------------------------------------------------------------------------
# Boss
# ---------------------------------------------------------------------------
func _on_boss_health_changed(current: int, maximum: int) -> void:
	hud.call("update_boss_bar", current, maximum)


func _on_boss_defeated(at: Vector2) -> void:
	if _boss_defeated or _level_over:
		return
	_boss_defeated = true
	hud.call("update_boss_bar", 0, int(_data.get("boss_hp", 6)))
	_spawn_burst(at + Vector2(0, -20), WorldData.accent(_world), 32)
	await get_tree().create_timer(0.55).timeout
	hud.call("hide_boss_bar")
	_complete_level(true)


# ---------------------------------------------------------------------------
# Level completion
# ---------------------------------------------------------------------------
func _on_level_finished() -> void:
	_complete_level(false)


func _complete_level(from_boss: bool) -> void:
	if _level_over:
		return
	_level_over = true
	player.call("set_controllable", false)
	player.invulnerable_time = 10.0
	touch_controls.set_controls_enabled(false)
	pause_menu.call("set_enabled", false)

	if _mission_kind == "shard":
		_mission_done = _shard_collected
	if _mission_done:
		hud.call("update_mission", _mission_progress, true)

	var coin_ratio := float(GameManager.level_coins) / float(maxi(1, _coins_total))
	var stars := 1
	if coin_ratio >= 0.60:
		stars = 2
	if coin_ratio >= 0.90:
		stars = 3
	if _mission_done and stars < 3:
		stars += 1

	var reward := int(_mission.get("reward", 100))
	var optional_reward := int(_mission.get("optional_reward", 150))
	GameManager.add_score(reward + (optional_reward if _mission_done else 0))
	_spawn_burst(_data["finish"] + Vector2(20, -130), Color(1.0, 0.86, 0.35), 30)
	var final_level: bool = GameManager.record_completion(
		stars, GameManager.level_coins, _mission_done, _shard_collected
	)

	var delay := 0.05 if GameManager.test_mode else 0.85
	await get_tree().create_timer(delay).timeout

	if from_boss and not GameManager.suppress_story:
		await _show_story(
			"victory_%d" % _world,
			"VICTORY",
			WorldData.world_name(_world),
			[WorldData.WORLD_VICTORY[_world]],
			""
		)
	if final_level and not GameManager.suppress_story:
		await _show_story(
			"ending", "THE END", "SIX CRYSTALS SHINE",
			WorldData.FINAL_LINES, ""
		)

	level_complete.call("show_result", final_level, GameManager.level_coins, _coins_total, GameManager.score, stars, {
		"optional_done": _mission_done,
		"optional_text": String(_mission.get("optional", "")),
		"shard": _shard_collected,
		"world": _world,
		"reward": reward,
		"optional_reward": optional_reward,
		"deaths": GameManager.level_deaths,
		"boss": from_boss,
	})


func _on_pause_state_changed(paused: bool) -> void:
	touch_controls.set_controls_enabled(not paused and not _level_over)


# ---------------------------------------------------------------------------
# Effects
# ---------------------------------------------------------------------------
func _spawn_popup(text: String, at: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = at + Vector2(-90, -30)
	label.size = Vector2(180, 36)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.08, 0.05, 1))
	label.add_theme_constant_override("outline_size", 7)
	label.z_index = 30
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 52.0, 0.85).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.5)
	tween.chain().tween_callback(label.queue_free)


func _spawn_burst(at: Vector2, color: Color, amount: int) -> void:
	var burst = BURST_SCENE.instantiate()
	burst.color = color
	burst.particle_count = amount
	burst.start_speed = 220.0
	burst.particle_size = 5.5
	burst.global_position = at
	world.add_child(burst)
