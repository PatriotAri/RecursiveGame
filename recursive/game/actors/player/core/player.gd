extends CharacterBody2D

var data: PlayerData

var player_input_system: PlayerInputSystem
var player_state_machine: PlayerStateMachine
var player_attack_system: PlayerAttackSystem
var player_movement_system: PlayerMovementSystem
var player_animation_system: PlayerAnimationSystem

var player_hitbox_manager: PlayerHitboxManager

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var health: PlayerHealthComponent = $HealthComponent

@export_group("Attack Tuning")
@export var windup_time:= 0.1
@export var lifetime:= 0.1
@export var damage:= 10.0

@export_group("Movement Tuning")
@export var base_walk_speed:= 100.0
@export var base_run_speed:= 140.0
@export var acceleration:= 600.0
@export var friction:= 800.0
@export var backpedal_penalty:= 0.35

func _ready() -> void:
	data = PlayerData.new()
	
	player_hitbox_manager = PlayerHitboxManager.new(self, data)
	player_hitbox_manager.register_hitbox(&"unarmed", GlobalPackedScenes.player_unarmed_hitbox)
	
	player_input_system = PlayerInputSystem.new()
	player_state_machine = PlayerStateMachine.new()
	player_attack_system = PlayerAttackSystem.new(self, player_hitbox_manager)
	player_movement_system = PlayerMovementSystem.new(self)
	player_animation_system = PlayerAnimationSystem.new(sprite)
	
	health.initialize(data)
	
	$Hurtbox.knockback_received.connect(_on_knockback_received)
	
	health.died.connect(_on_died)
	sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta: float) -> void:
	if data.is_dead:
		return
		
	player_input_system.update(data)
	
	var to_cursor:= get_global_mouse_position() - global_position
	if to_cursor != Vector2.ZERO:
		var current_angle := data.facing_dir.angle()
		var target_angle := to_cursor.angle()
		var new_angle := lerp_angle(current_angle, target_angle, data.facing_turn_speed * delta)
		data.facing_dir = Vector2.from_angle(new_angle) * to_cursor.length()
		
	player_attack_system.update(data, delta)
	player_state_machine.update(data)
	player_attack_system.post_update(data)
	player_movement_system.update(data, delta)
	player_animation_system.update(data)

func _on_knockback_received(direction: Vector2, strength: float, decay: float) -> void:
	var knockback := MovementModifier.create_impulse(&"knockback", direction, strength, decay)
	data.modifiers.add(knockback)

func _on_animation_finished() -> void:
	if sprite.animation.begins_with("hurt"):
		data.is_hurt = false

func _on_died() -> void:
	$Collision.set_deferred("disabled", true) #removes body collider on death.
	player_state_machine.update(data)
	player_animation_system.update(data)
	await sprite.animation_finished
	await get_tree().create_timer(1.0).timeout
	queue_free()
