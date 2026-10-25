class_name Spitter

extends Enemy

## Ranged: keeps its distance and lobs acid. Commits to a shot from
## shoot_range with a clear line, then backs off to preferred_distance while
## it reloads.

@export_group("Ranged Tuning")
@export var projectile_scene: PackedScene
## Spawn point per facing, relative to the feet — roughly the mouth.
@export var projectile_offsets: HitboxOffsetData
@export var shoot_range:= 150.0
@export var projectile_speed:= 170.0
@export var projectile_range:= 260.0
@export var shot_sound: SoundEffect = preload("res://game/audio/sfx/throw.tres")
@export var impact_sound: SoundEffect = preload("res://game/audio/sfx/projectile_hit.tres")

func _ready() -> void:
	primary_attack = &"spit"
	super()

func _register_attacks() -> void:
	var spit := AttackSpec.new()
	spit.scene = projectile_scene
	spit.offsets = projectile_offsets
	spit.damage = damage
	spit.windup_time = windup_time
	spit.lifetime = lifetime
	spit.knockback_strength = knockback_strength
	spit.hitstun_chance = hitstun_chance
	spit.knockback_chance = knockback_chance
	spit.projectile_speed = projectile_speed
	spit.projectile_range = projectile_range
	spit.sound = shot_sound
	spit.impact_sound = impact_sound
	hitbox_manager.register_attack(&"spit", spit)

func _compute_attack_range() -> float:
	return shoot_range
