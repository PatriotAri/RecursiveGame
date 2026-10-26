class_name Archer

extends Enemy

## Fights from a distance. Shoots arrows from between `near` and `far` when
## it can see the player, moves to a new spot after every shot, backs away
## when they come closer than `near`, and runs when they're within
## `flee_distance`. Arrows are projectiles: visible, dodgeable, stopped by
## walls.

@export_group("Bow")
@export var arrow_scene: PackedScene
@export var arrow_damage:= 3.0
## Seconds drawing before the arrow leaves; the tell to dodge.
@export var draw_time:= 0.4
@export var arrow_speed:= 250.0
@export var arrow_range:= 250.0
@export var draw_sound: SoundEffect
@export var arrow_hit_sound: SoundEffect

@export_group("Distance")
## Closer than this, it backs away between shots.
@export var near:= 150.0
## Further than this, or out of sight, it closes in.
@export var far:= 200.0
## Closer than this, it runs.
@export var flee_distance:= 100.0
## Longest it spends moving to a new spot after a shot.
@export var reposition_time:= 1.2

func _register_attacks() -> void:
	var shot := ProjectileAttackSpec.new()
	shot.scene = arrow_scene
	shot.damage = arrow_damage
	shot.windup_time = draw_time
	shot.lifetime = 0.2
	shot.speed = arrow_speed
	shot.max_range = arrow_range
	shot.knockback_strength = 40.0
	shot.hitstun_chance = 0.3
	shot.knockback_chance = 0.3
	shot.swing_sound = draw_sound
	shot.hit_sound = arrow_hit_sound
	primary_attack = &"shot"
	hitbox_manager.register_attack(primary_attack, shot)
	# Aimed at the middle of the player, not their feet.
	hitbox_manager.aim_provider = func() -> Vector2: return data.player_anchor

func _create_state_machine() -> EnemyStateMachine:
	return ArcherStateMachine.new(attack_cooldown, self)

func _create_movement_system() -> EnemyMovementSystem:
	return ArcherMovementSystem.new(self, data)
