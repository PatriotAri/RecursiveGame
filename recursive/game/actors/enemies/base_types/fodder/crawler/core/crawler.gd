extends CharacterBody2D

#type casts DetectionArea as DetectionSystem, allows script to send signals
@onready var detection_system: DetectionSystem = $DetectionArea as DetectionSystem
@onready var sprite: AnimatedSprite2D = $Sprite
var enemy_state_machine: EnemyStateMachine
var movement_system: EnemyMovementSystem
var animation_system: EnemyAnimationSystem

#health and damage components
@onready var health = $HealthComponent

#hitbox variables
@export_group("Hitbox Variables")
@export_subgroup("Hitbox Type")
@export var melee_hitbox_scene = GlobalPackedScenes.melee_attack_hitbox
@export_subgroup("Attack Tuning")
@export var melee_attack_distance:= 20
@export var windup_time:= 0.5   # Enemy windup
@export var lifetime:= 0.3       # How long hitbox stays active
@export var damage:= 10.0    # Damage done by enemy

#patrol variables
@export_group("Patrol Tuning")

var data: EnemyFodderData

func _ready() -> void:
	#listens for the signal "died" emitting from HealthComponent, 
	#then connects the _on_died method to run when it does emit.
	health.died.connect(_on_died)
	data = EnemyFodderData.new()
	
	#injects shared data
	detection_system.initialize(data)
	
	enemy_state_machine = EnemyStateMachine.new()
	movement_system = EnemyMovementSystem.new(self, data)
	animation_system = EnemyAnimationSystem.new(sprite, data)

func _physics_process(delta: float) -> void:
	detection_system.update()
	enemy_state_machine.update(data, delta)
	movement_system.update(delta)
	animation_system.update()

#instance melee hitbox
func perform_melee_attack():
	print("Enemy attacking!")
	#instances hitbox scene
	var hitbox = melee_hitbox_scene.instantiate()
	
	# NEW: Configure hitbox to hit player (layer 5 = bit value 16)
	hitbox.target_layer = 16
	
	# Override timing values for enemy attacks
	hitbox.windup_time = windup_time   # Enemy windup (adjust as needed)
	hitbox.lifetime = lifetime       # How long hitbox stays active
	hitbox.damage = damage        # Enemy damage (adjust as needed)
	
	#adds scene to world
	add_child(hitbox)
	
	#positions hitbox relative to enemy
	var facing:= data.last_facing if data.last_facing != Vector2.ZERO else Vector2.DOWN
	hitbox.position = facing.normalized() * melee_attack_distance

#kills the character
func _on_died():
	#queues node to be deleted at end of frame
	queue_free()
