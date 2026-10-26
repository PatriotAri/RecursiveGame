class_name MeleeEnemy

extends Enemy

## An enemy that fights up close with one swing: patrols, chases, and strikes
## when the player is in reach. The crawler and the grunt are both this, with
## their own numbers, art and sounds set in their scenes.

@export_group("Melee Attack")
@export var melee_hitbox: PackedScene
@export var melee_offsets: HitboxOffsetData
@export var windup_time:= 0.5
## How long the hitbox stays active.
@export var lifetime:= 0.3
@export var damage:= 10.0
## The radius of the CircleShape2D in melee_hitbox.
@export var reach_radius:= 10.0
@export var knockback_strength:= 50.0
@export_range(0.0, 1.0) var hitstun_chance:= 0.3
@export_range(0.0, 1.0) var knockback_chance:= 0.3
@export var melee_swing_sound: SoundEffect
@export var melee_hit_sound: SoundEffect

func _register_attacks() -> void:
	var melee := AttackSpec.new()
	melee.scene = melee_hitbox
	melee.offsets = melee_offsets
	melee.damage = damage
	melee.windup_time = windup_time
	melee.lifetime = lifetime
	melee.reach_radius = reach_radius
	melee.knockback_strength = knockback_strength
	melee.hitstun_chance = hitstun_chance
	melee.knockback_chance = knockback_chance
	melee.swing_sound = melee_swing_sound
	melee.hit_sound = melee_hit_sound

	primary_attack = &"melee"
	hitbox_manager.register_attack(primary_attack, melee)
