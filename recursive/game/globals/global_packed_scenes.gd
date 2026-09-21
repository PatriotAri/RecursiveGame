class_name GlobalPackedScenes

# Actors
static var crawler_scene = preload(
	"res://game/actors/enemies/types/fodder/crawler/core/crawler.tscn"
	)
	
static var player_scene = preload(
	"res://game/actors/player/core/player.tscn"
	)

# Hitboxes
static var player_unarmed_hitbox = preload(
	"res://game/actors/player/hitboxes/PlayerUnarmedHitbox.tscn"
	)

# Items
static var gold_sack = preload("res://game/items/drops/gold_sack/gold_sack.tscn")
static var soul = preload("res://game/items/drops/soul/soul.tscn")
static var health_potion_pickup = preload("res://game/items/consumables/potions/health_potion/health_potion_pickup.tscn")
static var stamina_potion_pickup = preload("res://game/items/consumables/potions/stamina_potion/stamina_potion_pickup.tscn")
