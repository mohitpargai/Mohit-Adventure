## Metadata for the six worlds of Mohit Adventure.
## Keeping names, palettes and story text in one place makes the 30 levels
## easy to maintain and lets the UI group them consistently.
class_name WorldData

const WORLD_COUNT := 6
const LEVELS_PER_WORLD := 5
const TOTAL_LEVELS := 30

const LEVEL_NAMES := [
	"Forest Beginning",
	"Hidden Coin Valley",
	"Wooden Bridge",
	"Dangerous Forest",
	"Forest Guardian",
	"Frozen Entrance",
	"Ice Cave",
	"Snowfall Valley",
	"Frozen Bridge",
	"Ice Monster",
	"Desert Entrance",
	"Lost Pyramid",
	"Sandstorm Run",
	"Ancient Temple",
	"Desert King",
	"Haunted Forest",
	"Ghost Dungeon",
	"Dark Corridor",
	"Castle Tower",
	"Shadow Knight",
	"Burning Entrance",
	"Lava Bridge",
	"Volcano Cave",
	"Fire Temple",
	"Lava Dragon",
	"Sky Entrance",
	"Floating Islands",
	"Cloud Adventure",
	"Sky Castle",
	"Dark Lord",
]

const LEVEL_SUBTITLES := [
	"A gentle walk through the sunny woods",
	"Every shining coin is worth the climb",
	"Cross the old wooden path above the ferns",
	"The forest grows wilder and the slimes grow bolder",
	"The ancient guardian awakens",
	"Cold winds and slippery steps",
	"Blue ice crystals light the way down",
	"Snow drifts hide more than one surprise",
	"The frozen bridge cracks underfoot",
	"The mountain itself has awakened",
	"Golden sand stretches to the horizon",
	"An ancient pyramid keeps its secrets",
	"Run before the sandstorm swallows the trail",
	"Temple traps guard a forgotten treasure",
	"The desert king demands respect",
	"The trees whisper warnings in the dark",
	"Lost souls wander the dungeon halls",
	"Firelight is the only guide here",
	"Climb the tower before midnight",
	"The shadow knight has been waiting",
	"The mountain breathes fire",
	"Cross the bridge before it melts",
	"Lava falls like rain in the volcano cave",
	"The fire temple tests every hero",
	"The lava dragon guards the hottest crystal",
	"A path of clouds and courage",
	"Islands drift above the endless sky",
	"Bounce from cloud to cloud",
	"The sky castle hides the final crystal",
	"The Dark Lord has one last trick",
]

const WORLD_NAMES := [
	"GREEN FOREST",
	"ICE KINGDOM",
	"DESERT KINGDOM",
	"DARK CASTLE",
	"LAVA KINGDOM",
	"SKY KINGDOM",
]

const WORLD_SUBTITLES := [
	"Sunlight, leaves and new beginnings",
	"Snow, ice and frozen bridges",
	"Sand, pyramids and ancient secrets",
	"Ghosts, towers and shadow magic",
	"Fire, lava and burning courage",
	"Clouds, islands and the final battle",
]

const WORLD_STORIES := [
	"The first crystal sleeps beneath the ancient trees of the Green Forest. Find it, Mohit, and the forest will breathe again.",
	"The Ice Kingdom has frozen in the Dark Lord's grip. Its crystal lies deep in the blue caves, guarded by a creature of snow and stone.",
	"Beyond the dunes, the Desert Kingdom hides its crystal inside a forgotten pyramid. The sand remembers every trespasser.",
	"Night never ends in the Dark Castle. Its crystal is locked in the highest tower, where a shadow knight keeps watch.",
	"The Lava Kingdom burns without rest. Its crystal waits at the heart of the volcano, guarded by a dragon of living flame.",
	"The Sky Kingdom drifts above the world, the last crystal shining in its castle. The Dark Lord is waiting there.",
]

const BOSS_NAMES := [
	"THE FOREST GUARDIAN",
	"THE ICE MONSTER",
	"THE DESERT KING",
	"THE SHADOW KNIGHT",
	"THE LAVA DRAGON",
	"THE DARK LORD",
]

const BOSS_STORIES := [
	"The ancient guardian steps out of the trees. It is not evil, only angry. Show it that the crystal belongs to the forest.",
	"The ice cracks and something enormous rises. The Ice Monster wants to keep the crystal frozen forever.",
	"The Desert King rises from a sea of sand. Prove that a small explorer can stand tall.",
	"The Shadow Knight draws a blade of smoke. Behind its visor, two red lights promise a long fight.",
	"The Lava Dragon unfolds its burning wings. The whole mountain shakes with every beat.",
	"The Dark Lord descends from the storm. This is the final battle for all six kingdoms.",
]

const WORLD_VICTORY := [
	"The forest crystal shines again. The trees whisper a grateful song.",
	"The ice begins to melt. Somewhere below, a river remembers how to sing.",
	"The desert blooms for the first time in years. The pyramid opens a hidden door.",
	"Dawn breaks over the castle. The ghosts finally rest.",
	"The volcano quiets. Warm light replaces the fire.",
	"Six crystals shine together. The sky is free.",
]

const INTRO_LINES := [
	"Six magical crystals kept the kingdoms in balance.",
	"One stormy night, the Dark Lord stole them all.",
	"Now forests freeze, deserts burn and the sky grows dark.",
	"Only one brave explorer can bring the light back.",
]

const FINAL_LINES := [
	"The Dark Lord's storm fades away.",
	"Six crystals rise into the sky and the kingdoms heal.",
	"Mohit Adventure is complete. Thank you for playing!",
]


static func world_index_for_level(level_index: int) -> int:
	return clampi(level_index, 0, TOTAL_LEVELS - 1) / LEVELS_PER_WORLD


static func local_index(level_index: int) -> int:
	return clampi(level_index, 0, TOTAL_LEVELS - 1) % LEVELS_PER_WORLD


static func level_name(level_index: int) -> String:
	return LEVEL_NAMES[clampi(level_index, 0, TOTAL_LEVELS - 1)]


static func level_subtitle(level_index: int) -> String:
	return LEVEL_SUBTITLES[clampi(level_index, 0, TOTAL_LEVELS - 1)]


static func world_name(world: int) -> String:
	return WORLD_NAMES[clampi(world, 0, WORLD_COUNT - 1)]


static func world_subtitle(world: int) -> String:
	return WORLD_SUBTITLES[clampi(world, 0, WORLD_COUNT - 1)]


static func boss_name(world: int) -> String:
	return BOSS_NAMES[clampi(world, 0, WORLD_COUNT - 1)]


static func is_boss_level(level_index: int) -> bool:
	return local_index(level_index) == LEVELS_PER_WORLD - 1


static func boss_hp(world: int) -> int:
	return 5 + clampi(world, 0, WORLD_COUNT - 1)


static func level_number(level_index: int) -> int:
	return clampi(level_index, 0, TOTAL_LEVELS - 1) + 1


## Decoration kinds that suit each world. New kinds live in decoration.gd.
static func decor_kinds(world: int) -> Array:
	return [
		[0, 1, 2, 3, 4, 5, 6],
		[8, 8, 9, 10, 3, 2],
		[11, 12, 13, 3, 11],
		[14, 15, 16, 3, 14],
		[17, 18, 19, 3, 18],
		[20, 21, 22, 20, 3],
	][clampi(world, 0, WORLD_COUNT - 1)]


## Ambient colour used by mission cards, world banners and bosses.
static func accent(world: int) -> Color:
	return [
		Color(0.53, 0.85, 0.42),
		Color(0.62, 0.88, 1.0),
		Color(1.0, 0.78, 0.38),
		Color(0.70, 0.58, 1.0),
		Color(1.0, 0.48, 0.24),
		Color(0.72, 0.86, 1.0),
	][clampi(world, 0, WORLD_COUNT - 1)]


## Visual and difficulty settings used by the level generator.
static func get_world(world: int) -> Dictionary:
	var w := clampi(world, 0, WORLD_COUNT - 1)
	var background: int = [0, 3, 4, 5, 6, 7][w]
	var style: int = [0, 3, 4, 5, 6, 7][w]
	var gaps: Vector2 = [
		Vector2(130.0, 185.0),
		Vector2(150.0, 205.0),
		Vector2(155.0, 215.0),
		Vector2(165.0, 225.0),
		Vector2(175.0, 235.0),
		Vector2(185.0, 250.0),
	][w]
	var accents: Array = [
		Color(0.53, 0.85, 0.42),
		Color(0.62, 0.88, 1.0),
		Color(1.0, 0.78, 0.38),
		Color(0.70, 0.58, 1.0),
		Color(1.0, 0.48, 0.24),
		Color(0.72, 0.86, 1.0),
	]
	return {
		"index": w,
		"name": WORLD_NAMES[w],
		"subtitle": WORLD_SUBTITLES[w],
		"story": WORLD_STORIES[w],
		"boss_name": BOSS_NAMES[w],
		"boss_story": BOSS_STORIES[w],
		"victory": WORLD_VICTORY[w],
		"background": background,
		"style": style,
		"accent": accents[w],
		"gap_min": gaps.x,
		"gap_max": gaps.y,
		"enemy_ground": [
			[0, 0, 0],
			[2, 2, 0],
			[3, 3, 0],
			[0, 4, 4],
			[5, 5, 0],
			[0, 2, 3],
		][w],
		"enemy_flying": [
			[1],
			[1, 2],
			[1],
			[4, 1],
			[1, 5],
			[6, 6, 1],
		][w],
		"optional": ["coins", "enemies", "checkpoints", "treasure", "enemies", "coins"][w],
	}
