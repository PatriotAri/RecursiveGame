extends CharacterBody2D

#type casts DetectionArea as DetectionSystem, allows script to send signals
@onready var crawler_detection_system: CrawlerDetectionSystem = $DetectionArea as CrawlerDetectionSystem
@onready var sprite: AnimatedSprite2D = $Sprite
var crawler_state_machine: CrawlerStateMachine
var crawler_movement_system: CrawlerMovementSystem
var crawler_attack_system: CrawlerAttackSystem
var crawler_animation_system: CrawlerAnimationSystem

#health and damage components
@onready var health: EnemyHealthComponent = $HealthComponent

#hitbox variables
@export_group("Hitbox Variables")
@export_subgroup("Hitbox Type")
@export var crawler_hitbox: PackedScene
@export_subgroup("Attack Tuning")
@export var windup_time = 0.5   # Enemy windup
@export var lifetime = 0.3       # How long hitbox stays active
@export var damage = 10.0    # Damage done by enemy
@export var attack_detection_range = 32.0 #must be 32 minimum to properly detect player

#patrol variables
@export_group("Patrol Tuning")
@export var patrol_wait_time:= 3.5
@export var patrol_timer:= 0.0
@export var min_patrol_distance:= 40.0

var data: EnemyData

func _ready() -> void:
	
	data = EnemyData.new()
	
	health.initialize(data)
	
	$Hurtbox.knockback_received.connect(_on_knockback_received)
	
	health.died.connect(_on_died)
	
	#injects data
	crawler_detection_system.initialize(data, self)
	
	crawler_state_machine = CrawlerStateMachine.new()
	crawler_movement_system = CrawlerMovementSystem.new(self, data)
	crawler_attack_system = CrawlerAttackSystem.new(self)
	crawler_animation_system = CrawlerAnimationSystem.new(sprite, data)

func _physics_process(delta: float) -> void:
	crawler_detection_system.update()
	crawler_state_machine.update(data, delta)
	crawler_movement_system.update(delta)
	crawler_attack_system.update(data, delta)
	crawler_animation_system.update()

func _on_knockback_received(direction: Vector2, strength: float, decay: float) -> void:
	var knockback := MovementModifier.create_impulse(&"knockback", direction, strength, decay)
	data.modifiers.add(knockback)

func _on_died():
	set_physics_process(false)
	sprite.play("died")
	await sprite.animation_finished
	await get_tree().create_timer(0.5).timeout
	queue_free()
