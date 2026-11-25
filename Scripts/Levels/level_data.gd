## All 30 level layouts live here. The original three forest levels keep their
## exact hand-tuned geometry; the other 27 are built deterministically from the
## world themes in world_data.gd so every stage is playable and distinct without
## duplicating hundreds of nodes by hand.
class_name LevelData

const GROUND_Y := 620.0


static func get_level(index: int) -> Dictionary:
	var i := clampi(index, 0, WorldData.TOTAL_LEVELS - 1)
	match i:
		0:
			return _finalize(_level_1(), i)
		1:
			return _finalize(_level_2(), i)
		2:
			return _finalize(_level_3(), i)
	if WorldData.is_boss_level(i):
		return _finalize(_boss_level(i), i)
	return _finalize(_generated_level(i), i)


# ---------------------------------------------------------------------------
# Original three levels (layouts untouched)
# ---------------------------------------------------------------------------
static func _level_1() -> Dictionary:
	var coins: Array = []
	coins.append_array(_row(300, 575, 3, 55))
	coins.append_array(_row(735, 455, 3, 65))
	coins.append_array(_row(1175, 400, 3, 55))
	coins.append_array(_arc(1550, 545, 3, 60, 55))
	coins.append_array(_row(1735, 460, 3, 65))
	coins.append_array(_row(2100, 385, 2, 55))
	coins.append_array(_row(2515, 455, 3, 65))
	coins.append_array(_row(3000, 415, 3, 65))
	coins.append_array(_row(3385, 465, 3, 65))
	coins.append_array(_row(3775, 385, 2, 55))
	coins.append_array(_row(4185, 460, 3, 65))
	coins.append_array(_row(4450, 575, 3, 55))
	coins.append_array(_row(4665, 425, 2, 55))
	coins.append_array(_row(4870, 575, 2, 55))

	return {
		"width": 5300.0,
		"height": 1200.0,
		"background": 0,
		"start": Vector2(180, 590),
		"finish": Vector2(5070, 620),
		"kill_y": 1500.0,
		"platforms": [
			_platform(0, 620, 1520, 300, 0),
			_platform(1660, 620, 1260, 300, 0),
			_platform(3060, 620, 1080, 300, 0),
			_platform(4280, 620, 920, 300, 0),
			_platform(690, 500, 300, 30, 0),
			_platform(1130, 445, 230, 30, 0),
			_platform(1690, 505, 260, 30, 0),
			_platform(2050, 430, 230, 30, 0),
			_platform(2470, 500, 260, 30, 1),
			_platform(2960, 460, 280, 30, 0),
			_platform(3340, 510, 300, 30, 0),
			_platform(3730, 430, 230, 30, 0),
			_platform(4140, 505, 280, 30, 2),
			_platform(4620, 470, 280, 30, 0),
		],
		"coins": coins,
		"enemies": [
			_enemy(0, 1080, 602, 900, 1220, 52, 0.0),
			_enemy(0, 760, 482, 710, 970, 46, 1.5),
			_enemy(0, 2300, 602, 2100, 2550, 60, 0.0),
			_enemy(0, 3420, 492, 3370, 3610, 54, 1.2),
			_enemy(0, 4650, 602, 4350, 4850, 62, 0.0),
		],
		"spikes": [
			_spikes(1380, 620, 104, 4),
			_spikes(3920, 620, 104, 4),
		],
		"moving_platforms": [],
		"checkpoints": [Vector2(3260, 620)],
		"decorations": [
			{"kind": 7, "x": 330, "y": 620, "scale": 0.88, "seed": 2},
			{"kind": 4, "x": 500, "y": 620, "scale": 1.2, "seed": 4},
			{"kind": 3, "x": 1425, "y": 620, "scale": 0.9, "seed": 5},
			{"kind": 5, "x": 4300, "y": 620, "scale": 1.1, "seed": 6},
		],
		"powerups": [{"kind": 1, "x": 2515, "y": 505}],
		"treasure": [Vector2(4900, 610)],
		"shard": Vector2(2960, 380),
		"hazards": [],
		"breakable_platforms": [],
		"disappearing_platforms": [],
	}


static func _level_2() -> Dictionary:
	var coins: Array = []
	coins.append_array(_row(300, 575, 4, 55))
	coins.append_array(_row(600, 455, 3, 65))
	coins.append_array(_row(1035, 385, 3, 60))
	coins.append_array(_arc(1290, 545, 3, 55, 55))
	coins.append_array(_row(1540, 460, 3, 60))
	coins.append_array(_row(1905, 375, 2, 55))
	coins.append_array(_row(2290, 450, 3, 60))
	coins.append_array(_arc(2490, 540, 3, 55, 55))
	coins.append_array(_row(2840, 395, 3, 60))
	coins.append_array(_row(3165, 475, 3, 55))
	coins.append_array(_row(3300, 520, 2, 55))
	coins.append_array(_row(3720, 425, 3, 60))
	coins.append_array(_row(4090, 380, 2, 55))
	coins.append_array(_row(4445, 460, 3, 60))
	coins.append_array(_row(4590, 575, 2, 55))
	coins.append_array(_row(4840, 405, 3, 60))
	coins.append_array(_row(5290, 455, 3, 60))
	coins.append_array(_row(5690, 375, 2, 55))
	coins.append_array(_row(6040, 445, 3, 60))
	coins.append_array(_row(6300, 575, 2, 55))

	return {
		"width": 6600.0,
		"height": 1200.0,
		"background": 1,
		"start": Vector2(180, 590),
		"finish": Vector2(6320, 620),
		"kill_y": 1500.0,
		"platforms": [
			_platform(0, 620, 1250, 300, 0),
			_platform(1450, 620, 1000, 300, 0),
			_platform(2650, 620, 1000, 300, 0),
			_platform(3860, 620, 990, 300, 0),
			_platform(5050, 620, 1550, 300, 0),
			_platform(560, 500, 280, 30, 0),
			_platform(990, 430, 240, 30, 0),
			_platform(1500, 505, 260, 30, 1),
			_platform(1860, 420, 220, 30, 0),
			_platform(2250, 495, 250, 30, 0),
			_platform(2800, 440, 250, 30, 2),
			_platform(3130, 520, 250, 30, 0),
			_platform(3680, 470, 240, 30, 0),
			_platform(4050, 425, 240, 30, 1),
			_platform(4400, 505, 260, 30, 0),
			_platform(4800, 450, 250, 30, 0),
			_platform(5250, 500, 280, 30, 0),
			_platform(5650, 420, 230, 30, 2),
			_platform(6000, 490, 250, 30, 0),
		],
		"coins": coins,
		"enemies": [
			_enemy(0, 760, 602, 620, 1150, 55, 0.0),
			_enemy(0, 620, 482, 580, 800, 45, 1.0),
			_enemy(0, 1900, 602, 1550, 2350, 65, 0.0),
			_enemy(0, 1910, 402, 1880, 2040, 50, 0.7),
			_enemy(0, 3000, 602, 2750, 3500, 60, 0.0),
			_enemy(0, 2860, 422, 2820, 3010, 48, 1.4),
			_enemy(0, 4200, 602, 3950, 4700, 70, 0.0),
			_enemy(0, 5480, 602, 5150, 5900, 58, 0.0),
			_enemy(0, 5330, 482, 5290, 5490, 50, 1.2),
			_enemy(0, 6120, 472, 6040, 6220, 52, 0.4),
			_enemy(1, 2350, 360, 2250, 2500, 55, 0.5),
			_enemy(1, 4150, 340, 4000, 4300, 55, 2.0),
			_enemy(1, 5800, 330, 5650, 5950, 55, 3.2),
		],
		"spikes": [
			_spikes(2050, 620, 104, 4),
			_spikes(3400, 620, 104, 4),
			_spikes(4550, 620, 104, 4),
			_spikes(6250, 620, 104, 4),
		],
		"moving_platforms": [
			{"x": 2480, "y": 545, "travel": Vector2(150, 0), "size": Vector2(150, 26), "speed": 1.05, "phase": 0.0},
		],
		"checkpoints": [Vector2(3980, 620)],
		"decorations": [
			{"kind": 7, "x": 330, "y": 620, "scale": 0.88, "seed": 12},
			{"kind": 4, "x": 470, "y": 620, "scale": 1.8, "seed": 13},
			{"kind": 4, "x": 1720, "y": 620, "scale": 1.2, "seed": 14},
			{"kind": 4, "x": 3560, "y": 620, "scale": 2.1, "seed": 15},
			{"kind": 4, "x": 4540, "y": 620, "scale": 1.3, "seed": 16},
			{"kind": 4, "x": 5960, "y": 620, "scale": 1.9, "seed": 17},
			{"kind": 3, "x": 2160, "y": 620, "scale": 1.0, "seed": 18},
		],
		"powerups": [{"kind": 0, "x": 4800, "y": 380}],
		"treasure": [Vector2(5150, 610)],
		"shard": Vector2(5650, 350),
		"hazards": [],
		"breakable_platforms": [],
		"disappearing_platforms": [],
	}


static func _level_3() -> Dictionary:
	var coins: Array = []
	coins.append_array(_row(300, 575, 4, 55))
	coins.append_array(_row(510, 475, 3, 65))
	coins.append_array(_row(880, 395, 2, 55))
	coins.append_array(_arc(1140, 550, 3, 55, 55))
	coins.append_array(_row(1460, 460, 2, 60))
	coins.append_array(_row(1785, 365, 2, 50))
	coins.append_array(_row(2090, 455, 2, 55))
	coins.append_array(_arc(2290, 545, 3, 55, 55))
	coins.append_array(_row(2540, 390, 3, 60))
	coins.append_array(_row(2850, 480, 2, 55))
	coins.append_array(_row(3150, 405, 2, 55))
	coins.append_array(_row(3370, 420, 3, 55))
	coins.append_array(_row(3690, 460, 2, 55))
	coins.append_array(_row(3990, 365, 2, 55))
	coins.append_array(_row(4240, 455, 2, 55))
	coins.append_array(_row(4435, 410, 3, 55))
	coins.append_array(_row(4740, 460, 3, 60))
	coins.append_array(_row(5035, 355, 2, 55))
	coins.append_array(_row(5335, 450, 2, 55))
	coins.append_array(_row(5485, 425, 3, 55))
	coins.append_array(_row(5790, 390, 2, 55))
	coins.append_array(_row(6140, 470, 3, 60))
	coins.append_array(_row(6535, 415, 2, 55))
	coins.append_array(_row(6790, 455, 3, 60))
	coins.append_array(_row(7140, 375, 2, 55))
	coins.append_array(_row(7440, 450, 3, 60))
	coins.append_array(_row(7625, 575, 2, 55))

	return {
		"width": 7900.0,
		"height": 1250.0,
		"background": 2,
		"start": Vector2(180, 590),
		"finish": Vector2(7650, 620),
		"kill_y": 1550.0,
		"platforms": [
			_platform(0, 620, 1100, 300, 0),
			_platform(1310, 620, 940, 300, 0),
			_platform(2460, 620, 840, 300, 0),
			_platform(3520, 620, 830, 300, 0),
			_platform(4560, 620, 840, 300, 0),
			_platform(5620, 620, 830, 300, 0),
			_platform(6660, 620, 1140, 300, 0),
			_platform(480, 520, 260, 30, 0),
			_platform(850, 440, 220, 30, 1),
			_platform(1420, 505, 240, 30, 0),
			_platform(1750, 410, 200, 30, 2),
			_platform(2050, 500, 240, 30, 0),
			_platform(2500, 435, 240, 30, 0),
			_platform(2820, 525, 220, 30, 1),
			_platform(3120, 450, 200, 30, 0),
			_platform(3340, 465, 210, 30, 2),
			_platform(3650, 505, 240, 30, 0),
			_platform(3950, 410, 220, 30, 1),
			_platform(4200, 500, 220, 30, 0),
			_platform(4400, 455, 220, 30, 2),
			_platform(4700, 505, 260, 30, 0),
			_platform(5000, 400, 200, 30, 0),
			_platform(5300, 495, 220, 30, 1),
			_platform(5450, 470, 210, 30, 2),
			_platform(5750, 435, 240, 30, 0),
			_platform(6100, 515, 240, 30, 0),
			_platform(6500, 460, 210, 30, 2),
			_platform(6750, 500, 240, 30, 0),
			_platform(7100, 420, 220, 30, 1),
			_platform(7400, 495, 240, 30, 0),
		],
		"coins": coins,
		"enemies": [
			_enemy(0, 650, 602, 450, 1000, 60, 0.0),
			_enemy(0, 560, 502, 510, 710, 50, 0.7),
			_enemy(0, 880, 422, 870, 1040, 48, 1.3),
			_enemy(0, 1750, 602, 1400, 2100, 70, 0.0),
			_enemy(0, 1800, 392, 1770, 1920, 55, 1.8),
			_enemy(0, 2850, 602, 2550, 3150, 65, 0.0),
			_enemy(0, 2560, 417, 2520, 2700, 55, 0.4),
			_enemy(0, 3900, 602, 3650, 4200, 72, 0.0),
			_enemy(0, 4000, 392, 3970, 4140, 58, 1.1),
			_enemy(0, 4900, 602, 4700, 5250, 68, 0.0),
			_enemy(0, 5050, 382, 5020, 5180, 55, 2.1),
			_enemy(0, 6000, 602, 5750, 6300, 70, 0.0),
			_enemy(0, 6800, 602, 6700, 7050, 62, 0.0),
			_enemy(0, 6150, 497, 6120, 6310, 52, 1.5),
			_enemy(0, 7150, 402, 7120, 7290, 56, 0.2),
			_enemy(1, 1500, 340, 1400, 1700, 55, 0.3),
			_enemy(1, 2600, 330, 2450, 2800, 55, 1.8),
			_enemy(1, 3800, 310, 3600, 4050, 55, 3.1),
			_enemy(1, 4800, 320, 4600, 5050, 55, 4.4),
			_enemy(1, 5900, 305, 5700, 6150, 55, 2.4),
			_enemy(1, 7000, 330, 6800, 7250, 55, 5.6),
		],
		"spikes": [
			_spikes(900, 620, 104, 4),
			_spikes(2000, 620, 104, 4),
			_spikes(2950, 620, 104, 4),
			_spikes(3800, 620, 104, 4),
			_spikes(4950, 620, 104, 4),
			_spikes(6000, 620, 104, 4),
			_spikes(6900, 620, 104, 4),
			_spikes(7300, 620, 104, 4),
		],
		"moving_platforms": [
			{"x": 1120, "y": 545, "travel": Vector2(150, 0), "size": Vector2(150, 26), "speed": 1.15, "phase": 0.0},
			{"x": 5420, "y": 560, "travel": Vector2(160, 0), "size": Vector2(150, 26), "speed": 1.25, "phase": 1.6},
			{"x": 6900, "y": 520, "travel": Vector2(0, -180), "size": Vector2(150, 26), "speed": 1.0, "phase": 0.8},
		],
		"checkpoints": [Vector2(3600, 620), Vector2(5850, 620)],
		"decorations": [
			{"kind": 7, "x": 330, "y": 620, "scale": 0.88, "seed": 22},
			{"kind": 4, "x": 450, "y": 620, "scale": 1.4, "seed": 23},
			{"kind": 4, "x": 2350, "y": 620, "scale": 2.2, "seed": 24},
			{"kind": 4, "x": 3680, "y": 620, "scale": 1.7, "seed": 25},
			{"kind": 4, "x": 5450, "y": 620, "scale": 2.0, "seed": 26},
			{"kind": 4, "x": 7100, "y": 620, "scale": 1.5, "seed": 27},
			{"kind": 3, "x": 3250, "y": 620, "scale": 1.2, "seed": 28},
		],
		"powerups": [{"kind": 3, "x": 5750, "y": 365}],
		"treasure": [Vector2(7000, 610)],
		"shard": Vector2(7100, 350),
		"hazards": [],
		"breakable_platforms": [],
		"disappearing_platforms": [],
	}


# ---------------------------------------------------------------------------
# Generated story levels (indexes 3-28, excluding boss levels)
# ---------------------------------------------------------------------------
static func _generated_level(index: int) -> Dictionary:
	var world := WorldData.world_index_for_level(index)
	var local := WorldData.local_index(index)
	var info := WorldData.get_world(world)
	var style := int(info["style"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 9109 + index * 733 + world * 191

	var background := int(info["background"])
	if world == 0:
		background = [0, 1, 2, 0, 1][local]

	var width := 4500.0 + float(local) * 420.0 + float(world) * 260.0 + rng.randf_range(0.0, 260.0)
	var height := 1250.0

	var platforms: Array = []
	var segments: Array = []
	var gap_ranges: Array = []
	var x := 0.0
	var first := true
	while x < width - 200.0:
		var seg_w := 900.0 if first else rng.randf_range(640.0, 920.0)
		if x + seg_w > width:
			seg_w = maxf(420.0, width - x)
		platforms.append(_platform(x, GROUND_Y, seg_w, 300.0, style))
		segments.append(Vector2(x, x + seg_w))
		x += seg_w
		if x >= width - 100.0:
			break
		var gap := rng.randf_range(float(info["gap_min"]), minf(float(info["gap_max"]), 198.0))
		gap_ranges.append(Vector2(x, x + gap))
		x += gap
		first = false
	if segments.is_empty():
		platforms.append(_platform(0, GROUND_Y, width, 300.0, style))
		segments.append(Vector2(0, width))

	var last_segment: Vector2 = segments[segments.size() - 1]
	var finish_x := last_segment.y - 160.0
	var start := Vector2(150, GROUND_Y - 30.0)

	# Helpful stepping platforms over wider gaps.
	for gap in gap_ranges:
		if rng.randf() < 0.55:
			var center: float = (gap.x + gap.y) * 0.5
			platforms.append(_platform(center - 90.0, GROUND_Y - rng.randf_range(82.0, 112.0), 180.0, 26.0, style))

	# Floating platforms above the ground strips.
	var float_count := 5 + local * 2 + world
	for i in float_count:
		var seg: Vector2 = segments[rng.randi_range(0, segments.size() - 1)]
		if seg.y - seg.x < 400.0:
			continue
		var fw := rng.randf_range(180.0, 260.0)
		var fx := rng.randf_range(seg.x + 80.0, seg.y - fw - 80.0)
		if absf(fx - finish_x) < 260.0 or absf(fx - start.x) < 260.0:
			continue
		var fy := rng.randf_range(380.0, 510.0)
		platforms.append(_platform(fx, fy, fw, 28.0, style if rng.randf() < 0.8 else 1))

	# Coins along the ground, above floating platforms and in little arcs.
	var coins: Array = []
	for seg: Vector2 in segments:
		var count := rng.randi_range(2, 4)
		var cx: float = seg.x + rng.randf_range(150.0, 260.0)
		if cx + float(count) * 52.0 > seg.y - 100.0:
			cx = maxf(seg.x + 80.0, seg.y - 100.0 - float(count) * 52.0)
		for k in count:
			coins.append(Vector2(cx + float(k) * 52.0, GROUND_Y - 52.0))
	for p in platforms:
		if float(p["y"]) < GROUND_Y - 40.0 and float(p["w"]) >= 150.0 and rng.randf() < 0.75:
			var n := rng.randi_range(2, 3)
			var center_x: float = float(p["x"]) + float(p["w"]) * 0.5
			for k in n:
				coins.append(Vector2(center_x + (float(k) - float(n - 1) * 0.5) * 52.0, float(p["y"]) - 70.0))
	for gap in gap_ranges:
		if rng.randf() < 0.7:
			var center: float = (gap.x + gap.y) * 0.5
			for k in 3:
				coins.append(Vector2(center + (float(k) - 1.0) * 55.0, GROUND_Y - 110.0 - (1.0 - absf(float(k) - 1.0)) * 55.0))

	# Enemies from the world's own roster.
	var enemies: Array = []
	var ground_kinds: Array = info["enemy_ground"]
	var flying_kinds: Array = info["enemy_flying"]
	for si in range(1, segments.size()):
		var seg: Vector2 = segments[si]
		if si == segments.size() - 1 and rng.randf() < 0.5:
			continue
		if rng.randf() < 0.84:
			var kind: int = int(ground_kinds[rng.randi_range(0, ground_kinds.size() - 1)])
			var ex := rng.randf_range(seg.x + 170.0, seg.y - 170.0)
			enemies.append(_enemy(
				kind, ex, GROUND_Y - 18.0, seg.x + 45.0, seg.y - 45.0,
				48.0 + float(world) * 4.0 + rng.randf_range(0.0, 14.0), rng.randf() * TAU
			))
	var fly_count := 2 + local + world
	for i in fly_count:
		var seg: Vector2 = segments[rng.randi_range(0, segments.size() - 1)]
		var fx := rng.randf_range(seg.x + 120.0, seg.y - 120.0)
		var fy := rng.randf_range(290.0, 470.0)
		var kind: int = int(flying_kinds[rng.randi_range(0, flying_kinds.size() - 1)])
		enemies.append(_enemy(
			kind, fx, fy, fx - 150.0, fx + 150.0,
			44.0 + float(world) * 4.5, rng.randf() * TAU
		))

	# Spikes sit on the ground, never right next to the goal.
	var spikes: Array = []
	for si in range(1, segments.size()):
		var seg: Vector2 = segments[si]
		if rng.randf() < 0.52:
			var sx := rng.randf_range(seg.x + 140.0, seg.y - 220.0)
			if absf(sx - finish_x) > 220.0:
				spikes.append(_spikes(sx, GROUND_Y, 104.0, 4))

	# Checkpoints at the middle and, on longer worlds, three quarters in.
	var checkpoints: Array = []
	var mid: Vector2 = segments[clampi(int(segments.size() / 2), 0, segments.size() - 1)]
	checkpoints.append(Vector2((mid.x + mid.y) * 0.5, GROUND_Y))
	if world >= 2 and local >= 2 and segments.size() > 3:
		var q: Vector2 = segments[int(segments.size() * 3 / 4)]
		checkpoints.append(Vector2((q.x + q.y) * 0.5, GROUND_Y))

	# Moving platforms over some gaps, plus a vertical lift in later worlds.
	var movers: Array = []
	for gap in gap_ranges:
		if rng.randf() < 0.5:
			var center: float = (gap.x + gap.y) * 0.5
			var travel_x := rng.randf_range(60.0, 110.0)
			movers.append({
				"x": center - travel_x * 0.5, "y": GROUND_Y - 85.0,
				"travel": Vector2(travel_x, 0.0), "size": Vector2(140.0, 26.0),
				"speed": 0.85 + rng.randf() * 0.4, "phase": rng.randf() * TAU, "style": style,
			})
	if world >= 3 and segments.size() > 2:
		var seg: Vector2 = segments[rng.randi_range(1, segments.size() - 1)]
		movers.append({
			"x": (seg.x + seg.y) * 0.5, "y": GROUND_Y - 120.0,
			"travel": Vector2(0.0, -150.0), "size": Vector2(140.0, 26.0),
			"speed": 0.9, "phase": rng.randf() * TAU, "style": style,
		})

	# Breakables in the gentler worlds, vanishing platforms in the tricky ones.
	var breakables: Array = []
	if world == 0 or world == 1 or world == 4:
		for i in 2:
			var seg: Vector2 = segments[rng.randi_range(1, segments.size() - 1)]
			var bw := 170.0
			if seg.y - seg.x < bw + 160.0:
				continue
			var bx := rng.randf_range(seg.x + 80.0, seg.y - bw - 80.0)
			breakables.append(_platform(bx, rng.randf_range(430.0, 500.0), bw, 24.0, style))
	var disappearing: Array = []
	if world == 3 or world == 5:
		for gap in gap_ranges:
			if rng.randf() < 0.65:
				var center: float = (gap.x + gap.y) * 0.5
				disappearing.append({
					"x": center - 80.0, "y": GROUND_Y - 100.0,
					"w": 160.0, "h": 24.0, "style": style,
					"phase": rng.randf() * TAU, "period": 3.0,
				})

	# Environmental hazards for the world.
	var hazards: Array = []
	match world:
		1:
			for i in 2:
				var seg: Vector2 = segments[rng.randi_range(1, segments.size() - 1)]
				hazards.append({
					"kind": "icicle", "x": rng.randf_range(seg.x + 120.0, seg.y - 120.0),
					"y": 150.0, "w": 34.0, "h": 48.0,
					"target_y": GROUND_Y - 30.0, "speed": 280.0,
					"interval": 1.8 + rng.randf(), "phase": rng.randf() * TAU,
				})
			var ws: Vector2 = segments[rng.randi_range(0, segments.size() - 1)]
			hazards.append({
				"kind": "wind", "x": (ws.x + ws.y) * 0.5, "y": 300.0,
				"w": minf(640.0, ws.y - ws.x - 120.0), "h": 430.0,
				"push": Vector2(-48.0, 0.0), "snow": true,
			})
		2:
			for i in 2:
				var seg: Vector2 = segments[rng.randi_range(1, segments.size() - 1)]
				if seg.y - seg.x < 520.0:
					continue
				var qx := rng.randf_range(seg.x + 160.0, seg.y - 320.0)
				hazards.append({"kind": "quicksand", "x": qx + 80.0, "y": GROUND_Y - 20.0, "w": 160.0, "h": 60.0})
			for i in 2:
				var seg: Vector2 = segments[rng.randi_range(1, segments.size() - 1)]
				hazards.append({
					"kind": "rock", "x": rng.randf_range(seg.x + 140.0, seg.y - 140.0),
					"y": 140.0, "w": 40.0, "h": 40.0,
					"target_y": GROUND_Y - 24.0, "speed": 250.0,
					"interval": 1.6 + rng.randf(), "phase": rng.randf() * TAU,
				})
			var ws2: Vector2 = segments[rng.randi_range(0, segments.size() - 1)]
			hazards.append({
				"kind": "wind", "x": (ws2.x + ws2.y) * 0.5, "y": 300.0,
				"w": minf(660.0, ws2.y - ws2.x - 120.0), "h": 430.0,
				"push": Vector2(70.0, 0.0), "sand": true,
			})
		3:
			for i in 2:
				var seg: Vector2 = segments[rng.randi_range(1, segments.size() - 1)]
				hazards.append({
					"kind": "fire", "x": rng.randf_range(seg.x + 140.0, seg.y - 140.0),
					"y": GROUND_Y - 18.0, "w": 120.0, "h": 46.0,
				})
			for i in 2:
				var seg: Vector2 = segments[rng.randi_range(1, segments.size() - 1)]
				var mx := rng.randf_range(seg.x + 180.0, seg.y - 180.0)
				hazards.append({
					"kind": "moving_spike", "x": mx, "y": GROUND_Y - 22.0,
					"w": 96.0, "h": 32.0, "range": 130.0,
					"speed": 0.8 + rng.randf() * 0.4, "phase": rng.randf() * TAU,
				})
		4:
			for gap in gap_ranges:
				if rng.randf() < 0.8:
					var center: float = (gap.x + gap.y) * 0.5
					hazards.append({
						"kind": "lava", "x": center, "y": GROUND_Y + 72.0,
						"w": maxf(80.0, gap.y - gap.x + 14.0), "h": 150.0,
					})
			for i in 2:
				var seg: Vector2 = segments[rng.randi_range(1, segments.size() - 1)]
				hazards.append({
					"kind": "fireball", "x": rng.randf_range(seg.x + 140.0, seg.y - 140.0),
					"y": 130.0, "w": 36.0, "h": 36.0,
					"target_y": GROUND_Y - 26.0, "speed": 320.0,
					"interval": 1.5 + rng.randf() * 0.8, "phase": rng.randf() * TAU,
				})
		5:
			for i in 2:
				var seg: Vector2 = segments[rng.randi_range(0, segments.size() - 1)]
				hazards.append({
					"kind": "wind", "x": (seg.x + seg.y) * 0.5, "y": 300.0,
					"w": minf(640.0, seg.y - seg.x - 120.0), "h": 430.0,
					"push": Vector2(72.0 if i % 2 == 0 else -72.0, 0.0),
					"clouds": true,
				})

	# One helpful power-up, plus a heal on longer stages.
	var powerups: Array = []
	var p_kinds := [0, 1, 3, 0, 2]
	var pk: int = p_kinds[(local + world) % p_kinds.size()]
	var candidates: Array = []
	for p in platforms:
		if float(p["y"]) < GROUND_Y - 30.0 and float(p["w"]) >= 150.0:
			candidates.append(p)
	if candidates.is_empty():
		powerups.append({"kind": pk, "x": finish_x - 380.0, "y": GROUND_Y - 80.0})
	else:
		var chosen: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
		powerups.append({
			"kind": pk, "x": float(chosen["x"]) + float(chosen["w"]) * 0.5,
			"y": float(chosen["y"]) - 65.0,
		})
	if local >= 2:
		powerups.append({"kind": 3, "x": last_segment.y - 360.0, "y": GROUND_Y - 120.0})

	# Hidden treasure near the end and a crystal shard on the highest platform.
	var treasures: Array = [Vector2(last_segment.y - 320.0, GROUND_Y - 20.0)]
	var shard := Vector2(finish_x - 260.0, GROUND_Y - 120.0)
	var highest: Dictionary = {}
	for p in platforms:
		if float(p["y"]) < GROUND_Y - 60.0:
			if highest.is_empty() or float(p["y"]) < float(highest["y"]):
				highest = p
	if not highest.is_empty():
		shard = Vector2(float(highest["x"]) + float(highest["w"]) * 0.5, float(highest["y"]) - 70.0)

	# Theme decorations sprinkled on every ground strip.
	var decorations: Array = []
	var deco_kinds: Array = WorldData.decor_kinds(world)
	for seg in segments:
		if rng.randf() < 0.85:
			decorations.append({
				"kind": int(deco_kinds[rng.randi_range(0, deco_kinds.size() - 1)]),
				"x": rng.randf_range(seg.x + 120.0, seg.y - 120.0),
				"y": GROUND_Y, "scale": rng.randf_range(0.8, 1.2),
				"seed": rng.randi_range(1, 99999),
			})

	return {
		"width": width, "height": height, "background": background,
		"start": start, "finish": Vector2(finish_x, GROUND_Y), "kill_y": 1500.0,
		"platforms": platforms, "coins": coins, "enemies": enemies, "spikes": spikes,
		"moving_platforms": movers, "checkpoints": checkpoints, "decorations": decorations,
		"breakable_platforms": breakables, "disappearing_platforms": disappearing,
		"hazards": hazards, "powerups": powerups, "treasure": treasures, "shard": shard,
		"boss": false,
	}


# ---------------------------------------------------------------------------
# Boss arenas (indexes 4, 9, 14, 19, 24, 29)
# ---------------------------------------------------------------------------
static func _boss_level(index: int) -> Dictionary:
	var world := WorldData.world_index_for_level(index)
	var info := WorldData.get_world(world)
	var style := int(info["style"])
	var width := 1700.0
	var platforms: Array = [
		_platform(0, 620, 1700, 300, style),
		_platform(320, 470, 240, 26, style),
		_platform(740, 390, 220, 26, style),
		_platform(1160, 470, 240, 26, style),
	]
	var coins: Array = []
	coins.append_array(_row(260, 575, 3, 55))
	coins.append_array(_row(370, 430, 3, 60))
	coins.append_array(_row(790, 350, 2, 55))
	coins.append_array(_row(1210, 430, 3, 60))
	coins.append_array(_row(1440, 575, 2, 55))

	var decorations: Array = []
	var deco_kinds: Array = WorldData.decor_kinds(world)
	decorations.append({"kind": int(deco_kinds[0]), "x": 100.0, "y": 620, "scale": 1.1, "seed": 501 + index})
	decorations.append({"kind": int(deco_kinds[1]), "x": 1620.0, "y": 620, "scale": 1.1, "seed": 601 + index})

	return {
		"width": width, "height": 1250.0,
		"background": int(info["background"]),
		"start": Vector2(150, 590), "finish": Vector2(1600, 620), "kill_y": 1500.0,
		"platforms": platforms, "coins": coins, "enemies": [], "spikes": [],
		"moving_platforms": [], "checkpoints": [], "decorations": decorations,
		"breakable_platforms": [], "disappearing_platforms": [], "hazards": [],
		"powerups": [
			{"kind": 3, "x": 440.0, "y": 405.0},
			{"kind": 0, "x": 1280.0, "y": 405.0},
		],
		"treasure": [],
		"shard": Vector2(850.0, 320.0),
		"boss": true, "boss_world": world, "boss_hp": WorldData.boss_hp(world),
		"boss_x": 1180.0, "boss_y": GROUND_Y - 92.0,
	}


# ---------------------------------------------------------------------------
# Shared metadata / mission builder
# ---------------------------------------------------------------------------
static func _finalize(data: Dictionary, index: int) -> Dictionary:
	var world := WorldData.world_index_for_level(index)
	var info := WorldData.get_world(world)
	data["index"] = index
	data["world"] = world
	data["name"] = WorldData.level_name(index)
	data["subtitle"] = WorldData.level_subtitle(index)
	data["style"] = int(info["style"])
	if not data.has("background"):
		data["background"] = int(info["background"])
	if not data.has("decor_theme"):
		data["decor_theme"] = world
	for key in [
		"platforms", "coins", "enemies", "spikes", "moving_platforms",
		"checkpoints", "decorations", "hazards", "powerups", "treasure",
		"breakable_platforms", "disappearing_platforms",
	]:
		if not data.has(key):
			data[key] = []
	if not data.has("shard"):
		data["shard"] = null
	if not data.has("boss"):
		data["boss"] = false

	var boss: bool = bool(data["boss"])
	var optional_kind := "shard" if boss else String(info["optional"])
	var coins_count: int = (data["coins"] as Array).size()
	var enemies_count: int = (data["enemies"] as Array).size()
	var checkpoints_count: int = (data["checkpoints"] as Array).size()
	var target := 1
	match optional_kind:
		"coins":
			target = maxi(5, int(round(float(coins_count) * 0.6)))
		"enemies":
			target = maxi(1, int(round(float(enemies_count) * 0.6)))
		"checkpoints":
			target = maxi(1, checkpoints_count)
		"treasure":
			target = 1
		"shard":
			target = 1

	var optional_text := "Find the crystal shard"
	match optional_kind:
		"coins":
			optional_text = "Collect %d coins" % target
		"enemies":
			optional_text = "Defeat %d enemies" % target
		"checkpoints":
			optional_text = "Activate %d checkpoint%s" % [target, "" if target == 1 else "s"]
		"treasure":
			optional_text = "Find the hidden treasure"
		"shard":
			optional_text = "Find the crystal shard"

	var main_text := "Reach the finish flag"
	if boss:
		main_text = "Defeat %s" % WorldData.boss_name(world)

	data["mission"] = {
		"main": main_text,
		"optional": optional_text,
		"optional_kind": optional_kind,
		"optional_target": target,
		"reward": 100 + world * 40,
		"optional_reward": 150 + world * 30,
	}
	return data


# ---------------------------------------------------------------------------
# Data helpers
# ---------------------------------------------------------------------------
static func _platform(x: float, y: float, width: float, height: float, style: int) -> Dictionary:
	return {"x": x, "y": y, "w": width, "h": height, "style": style}


static func _enemy(kind: int, x: float, y: float, left: float, right: float, speed: float, phase: float) -> Dictionary:
	return {
		"kind": kind, "x": x, "y": y,
		"left": left, "right": right,
		"speed": speed, "phase": phase,
	}


static func _spikes(x: float, y: float, width: float, count: int) -> Dictionary:
	return {"x": x, "y": y, "w": width, "count": count}


static func _row(x: float, y: float, count: int, spacing: float) -> Array:
	var out: Array = []
	for i in count:
		out.append(Vector2(x + float(i) * spacing, y))
	return out


static func _arc(start_x: float, base_y: float, count: int, spacing: float, height: float) -> Array:
	var out: Array = []
	for i in count:
		var t := float(i) / float(maxi(1, count - 1))
		out.append(Vector2(start_x + float(i) * spacing, base_y - sin(t * PI) * height))
	return out
