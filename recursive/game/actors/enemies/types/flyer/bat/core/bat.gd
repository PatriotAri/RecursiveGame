class_name Bat

extends Enemy

## A flyer. Circles just out of reach, dives in for a quick bite, then pulls
## back out before the next dive. Flies over low obstacles (its own
## navigation map, and its body doesn't collide with them) but not walls.
## Below half health it flees out of reach for a few seconds, once.

@export_group("Bite")
@export var bite_hitbox: PackedScene
@export var bite_offsets: HitboxOffsetData
@export var bite_damage:= 2.0
## The radius of the CircleShape2D in bite_hitbox.
@export var bite_radius:= 10.0
@export var dive_sound: SoundEffect
@export var bite_sound: SoundEffect

@export_group("Flight")
## How far out it circles between dives.
@export var circle_radius:= 70.0
## How fast it dives.
@export var dive_speed:= 220.0
## How long a dive lasts; the bite is live for all of it.
@export var dive_time:= 0.45
## How long it pulls back for after a dive.
@export var retreat_time:= 0.6

@export_group("Fleeing")
## Below this share of its health, it flees.
@export_range(0.0, 1.0) var flee_below:= 0.5
@export var flee_time:= 3.0

var _has_fled:= false

func _ready() -> void:
	super()
	# Onto the level's flyer map, which ignores low obstacles.
	var level_navigation := get_tree().get_first_node_in_group(&"level_navigation") as LevelNavigation
	if level_navigation and navigation_agent:
		navigation_agent.set_navigation_map(level_navigation.flyer_map)

func _register_attacks() -> void:
	var bite := AttackSpec.new()
	bite.scene = bite_hitbox
	bite.offsets = bite_offsets
	bite.damage = bite_damage
	bite.windup_time = 0.1
	bite.lifetime = dive_time
	bite.reach_radius = bite_radius
	bite.knockback_strength = 60.0
	bite.hitstun_chance = 0.3
	bite.knockback_chance = 0.5
	bite.swing_sound = dive_sound
	bite.hit_sound = bite_sound
	primary_attack = &"bite"
	hitbox_manager.register_attack(primary_attack, bite)

func _create_state_machine() -> EnemyStateMachine:
	return BatStateMachine.new(attack_cooldown, self)

func _create_movement_system() -> EnemyMovementSystem:
	return BatMovementSystem.new(self, data)

func _on_damage_received(damage_amount: float, apply_hitstun: bool) -> void:
	super(damage_amount, apply_hitstun)
	if data.is_dead or _has_fled: return
	if stats.health.ratio() < flee_below:
		_has_fled = true
		data.flee_left = flee_time
		# A bite in progress is dropped; it's leaving.
		hitbox_manager.cancel_all()
