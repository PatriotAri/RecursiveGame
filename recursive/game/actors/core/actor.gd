class_name Actor

extends CharacterBody2D

## What the player and every enemy have in common: health and armor, taking
## hits (number, spark, flash, sound, hitstun, knockback), and dying.
## A subclass builds its own StatSystem and data, calls _setup_actor(), and
## does its per-frame work in _actor_process().
##
## Expected children: Sprite (AnimatedSprite2D), Collision, Hurtbox (Hurtbox).

## Emitted once, on the killing blow — before any death animation, so a
## round can count the kill without waiting for the corpse to fade.
signal died

@export_group("Combat Feel")
## How long a staggering hit locks this actor in hitstun.
@export var hurt_duration:= 0.2
@export var damage_number_color:= Color.WHITE
@export var hit_spark_color:= Color.WHITE

@export_group("Sounds")
@export var hurt_sound: SoundEffect
@export var death_sound: SoundEffect

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var _hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D

var stats: StatSystem
## The subclass's own data, seen through the fields every actor shares.
var actor_data: ActorData
var death_handled:= false

var _flash_tween: Tween

## Wires up the shared plumbing. Call from the subclass's _ready() once
## `stats` exists.
func _setup_actor(data_ref: ActorData) -> void:
	actor_data = data_ref
	stats.health.emptied.connect(_on_health_emptied)
	hurtbox.damaged.connect(_on_damage_received)
	hurtbox.knockback_received.connect(_on_knockback_received)

## The shared part of every physics frame. Subclasses override
## _actor_process(), not this.
func _physics_process(delta: float) -> void:
	if actor_data.is_dead:
		if not death_handled:
			death_handled = true
			_handle_death()
		return
	stats.update(delta)
	# Hitstun is a timer, ticked before the subclass resolves its state so
	# is_hurt is current this frame.
	if actor_data.hurt_timer > 0.0:
		actor_data.hurt_timer -= delta
		if actor_data.hurt_timer <= 0.0:
			actor_data.is_hurt = false
	_actor_process(delta)

## Everything this actor does in a frame, after hitstun and stats.
func _actor_process(_delta: float) -> void:
	pass

## The point other actors aim at. Movement wants the feet (global_position);
## combat wants the middle of what it has to hit.
func combat_anchor() -> Vector2:
	return _hurtbox_shape.global_position

## Plays a sound at this actor's position. Null is silent.
func play_sound(effect: SoundEffect) -> void:
	AudioManager.play_sfx(effect, global_position)

# --- hooks ------------------------------------------------------------------

## After every hit's feedback, whether or not it staggered or killed.
func _on_hit(_dealt: int) -> void:
	pass

## When a hit lands hitstun. Drop whatever swing was in progress.
func _on_staggered() -> void:
	pass

## Once, when health runs out. The default stops being a wall and stops
## being hittable; subclasses add their own and call super().
func _handle_death() -> void:
	# Deferred: death is usually reached from inside a physics callback.
	$Collision.set_deferred("disabled", true)
	hurtbox.set_deferred("monitorable", false)
	play_sound(death_sound)

# --- damage -----------------------------------------------------------------

func _on_damage_received(amount: float, apply_hitstun: bool) -> void:
	var dealt := stats.take_damage(amount)
	DamageNumber.spawn(get_parent(), combat_anchor() + Vector2(0, -16), dealt, damage_number_color)
	HitSpark.spawn(get_parent(), combat_anchor(), hit_spark_color)
	_on_hit(dealt)
	if actor_data.is_dead:
		return
	play_sound(hurt_sound)
	_flash_damage()
	if not apply_hitstun:
		return
	# Re-arming the timer on every hit is what kills the permanent freeze:
	# the old code waited on an animation_finished that never fires when the
	# hurt state is re-entered without the animation name changing.
	actor_data.is_hurt = true
	actor_data.hurt_timer = hurt_duration
	actor_data.hurt_seq += 1
	_on_staggered()

## Feedback that a hit landed, separate from whether it staggered. Every hit
## flashes; only some of them interrupt.
func _flash_damage() -> void:
	# A second hit mid-flash would otherwise leave two tweens fighting over
	# modulate, and the sprite can end up stuck tinted.
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	sprite.modulate = Color(1, 0.3, 0.3)
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func _on_health_emptied() -> void:
	if actor_data.is_dead: return
	actor_data.is_dead = true
	died.emit()

func _on_knockback_received(direction: Vector2, strength: float, decay: float) -> void:
	var knockback := MovementModifier.create_impulse(&"knockback", direction, strength, decay)
	actor_data.modifiers.add(knockback)
