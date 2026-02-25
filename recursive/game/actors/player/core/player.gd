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
	
	health.died.connect(_on_died)

func _physics_process(delta: float) -> void:
	player_input_system.update(data)
	player_state_machine.update(data)
	player_attack_system.update(data, delta)
	player_movement_system.update(data, delta)
	player_animation_system.update(data)

func _on_died() -> void:
	print("Player died!")
	queue_free()  # Remove player from scene
