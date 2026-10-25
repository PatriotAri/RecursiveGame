class_name Fireball

extends Projectile

## A projectile that explodes where it lands. The direct hit does the
## AttackSpec's damage; the explosion does its own to everything around it,
## the direct target included.

@export var explosion_radius:= 40.0
@export var explosion_damage:= 5.0
@export var explosion_knockback:= 120.0
@export var explosion_sound: SoundEffect = preload("res://game/audio/sfx/fireball_hit.tres")

@onready var sprite: Sprite2D = $Sprite2D

var _flicker:= 0.0

func _process(delta: float) -> void:
	if not visible: return
	_flicker += delta
	# Cheap flame: a fast irregular pulse instead of an animation.
	var pulse := 1.0 + 0.12 * sin(_flicker * 31.0) + 0.06 * sin(_flicker * 53.0)
	sprite.scale = Vector2(pulse, pulse)

func _on_impact() -> void:
	var explosion := Explosion.new()
	explosion.radius = explosion_radius
	explosion.damage = explosion_damage
	explosion.knockback_strength = explosion_knockback
	explosion.knockback_decay = knockback_decay
	explosion.hitstun_chance = hitstun_chance
	explosion.knockback_chance = 1.0
	explosion.target_layer = target_layer
	explosion.lifetime = 0.1
	explosion.global_position = global_position
	# Deferred: impact is usually reached from inside a physics callback,
	# where adding an Area2D to the tree is refused.
	get_parent().add_child.call_deferred(explosion)
	AudioManager.play_sfx(explosion_sound, global_position)
