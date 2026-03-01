extends CharacterBody2D

var data: PlayerData

var player_input_system: PlayerInputSystem
var player_state_machine: PlayerStateMachine
var player_attack_system: PlayerAttackSystem
var player_movement_system: PlayerMovementSystem
var player_animation_system: PlayerAnimationSystem

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var health = $HealthComponent

@export_group("Attack Tuning")
@export var windup_time:= 0.1
@export var lifetime:= 0.3
@export var damage:= 10.0

func _ready() -> void:
	data = PlayerData.new()
	
	player_input_system = PlayerInputSystem.new()
	player_state_machine = PlayerStateMachine.new()
	player_attack_system = PlayerAttackSystem.new(self)
	player_movement_system = PlayerMovementSystem.new(self)
	player_animation_system = PlayerAnimationSystem.new(sprite)
	
	health.died.connect(on_died)
	health.hurt.connect(on_hurt)
	sprite.animation_finished.connect(on_animation_finished)

func _physics_process(delta: float) -> void:
	player_input_system.update(data)
	player_state_machine.update(data)
	player_attack_system.update(data, delta)
	player_movement_system.update(data, delta)
	player_animation_system.update(data)

func on_hurt() -> void:
	data.is_attacking = false
	data.is_hurt = true
	
func on_animation_finished() -> void:
	if sprite.animation == "hurt":
		data.is_hurt = false

func on_died() -> void:
	print("You died.")
	#removes player from scene
	queue_free()
