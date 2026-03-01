extends CharacterBody2D

#type casts DetectionArea as DetectionSystem, allows script to send signals
@onready var crawler_detection_system: CrawlerDetectionSystem = $DetectionArea as CrawlerDetectionSystem
@onready var sprite: AnimatedSprite2D = $Sprite
var crawler_state_machine: CrawlerStateMachine
var crawler_movement_system: CrawlerMovementSystem
var crawler_animation_system: CrawlerAnimationSystem

#health and damage components
@onready var health = $HealthComponent

#hitbox variables
@export_group("Hitbox Variables")
@export_subgroup("Hitbox Type")
@export var crawler_melee_scene = GlobalPackedScenes.crawler_melee_hitbox
@export_subgroup("Attack Tuning")
@export var melee_attack_distance:= 20
@export var windup_time:= 0.5   # Enemy windup
@export var lifetime:= 0.3       # How long hitbox stays active
@export var damage:= 10.0    # Damage done by enemy

#patrol variables
@export_group("Patrol Tuning")

var data: EnemyData

func _ready() -> void:
	#listens for the signal "died" emitting from HealthComponent, 
	#then connects the _on_died method to run when it does emit.
	health.died.connect(_on_died)
	data = EnemyData.new()
	
	#injects shared data
	crawler_detection_system.initialize(data)
	
	crawler_state_machine = CrawlerStateMachine.new()
	crawler_movement_system = CrawlerMovementSystem.new(self, data)
	crawler_animation_system = CrawlerAnimationSystem.new(sprite, data)

func _physics_process(delta: float) -> void:
	crawler_detection_system.update()
	crawler_state_machine.update(data, delta)
	crawler_movement_system.update(delta)
	crawler_animation_system.update()

#instance melee hitbox
func perform_melee_attack():
	print("Enemy attacking!")
	#instances hitbox scene
	var hitbox = crawler_melee_scene.instantiate()
	
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
	print("Enemy killed.")
	#queues node to be deleted at end of frame
	queue_free()
