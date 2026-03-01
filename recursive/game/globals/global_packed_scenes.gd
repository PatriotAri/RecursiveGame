#global packed scene class, will probably be expanded into multiple classes later
class_name GlobalPackedScenes

# Actors
static var enemy_scene = preload(
	"res://game/actors/enemies/base_types/fodder/crawler/core/crawler.tscn"
	)
	
static var player_scene = preload(
	"res://game/actors/player/core/player.tscn"
	)

# Hitboxes
static var crawler_melee_hitbox = preload(
	"res://game/actors/enemies/base_types/fodder/crawler/hitboxes/CrawlerMeleeHitbox.tscn"
	)

static var player_unarmed_hitbox = preload(
	"res://game/actors/player/hitboxes/PlayerUnarmedHitbox.tscn"
	)

# Spawners
static var slime_spawner = preload(
	"res://game/components/spawner/slime_spawner.tscn"
	)

# Levels
static var test_level_01 = preload(
	"res://game/maps/test_map/levels/test_level_01/test_level_01.tscn"
	)
