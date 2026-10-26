class_name Crawler

extends Enemy

## Weak fodder: patrols, chases, and lunges in with a short melee bite.
## Everything else — health, hitstun, death, drops, movement — comes from
## Enemy.

#hitbox variables
@export_group("Hitbox Type")
@export var crawler_hitbox: PackedScene
@export var crawler_melee_offsets: HitboxOffsetData

@export_group("Attack Tuning")
@export var windup_time:= 0.5   # Enemy windup
@export var lifetime:= 0.3       # How long hitbox stays active
@export var damage:= 10.0    # Damage done by enemy

func _register_attacks() -> void:
	var melee := AttackSpec.new()
	melee.scene = crawler_hitbox
	melee.offsets = crawler_melee_offsets
	melee.damage = damage
	melee.windup_time = windup_time
	melee.lifetime = lifetime
	melee.reach_radius = 10.0   # crawler_melee_hitbox.tscn's CircleShape2D
	melee.knockback_strength = 50.0
	melee.hitstun_chance = 0.3
	melee.knockback_chance = 0.3

	primary_attack = &"melee"
	hitbox_manager.register_attack(primary_attack, melee)
