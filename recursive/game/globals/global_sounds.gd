class_name GlobalSounds

## Shared sound effects, preloaded once. Actors take their sounds as exports so
## each type can have its own; these are what the exports are set to today,
## and what code with no scene to export from (UI, pickups) falls back to.

const SFX_DIR := "res://game/audio/sfx/"

# Combat
static var swing: SoundEffect = preload(SFX_DIR + "swing.tres")
static var hit: SoundEffect = preload(SFX_DIR + "hit.tres")
static var player_hurt: SoundEffect = preload(SFX_DIR + "player_hurt.tres")
static var player_death: SoundEffect = preload(SFX_DIR + "player_death.tres")
static var enemy_attack: SoundEffect = preload(SFX_DIR + "enemy_attack.tres")
static var enemy_death: SoundEffect = preload(SFX_DIR + "enemy_death.tres")

# Items
static var pickup: SoundEffect = preload(SFX_DIR + "pickup.tres")
static var soul_pickup: SoundEffect = preload(SFX_DIR + "soul_pickup.tres")
static var potion: SoundEffect = preload(SFX_DIR + "potion.tres")
static var equip: SoundEffect = preload(SFX_DIR + "equip.tres")

# UI
static var ui_click: SoundEffect = preload(SFX_DIR + "ui_click.tres")
