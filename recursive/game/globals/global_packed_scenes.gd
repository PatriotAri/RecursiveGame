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
static var melee_attack_hitbox = preload(
	"res://game/components/health/hitboxes/MeleeAttackHitBox.tscn"
	)

# Spawners
static var slime_spawner = preload(
	"res://game/components/spawner/slime_spawner.tscn"
	)

# Levels
