extends CharacterBody2D

#type casts DetectionArea as DetectionSystem, allows script to send signals
@onready var crawler_detection_system: CrawlerDetectionSystem = $DetectionArea as CrawlerDetectionSystem
@onready var sprite: AnimatedSprite2D = $Sprite
var crawler_state_machine: CrawlerStateMachine
var crawler_movement_system: CrawlerMovementSystem
var crawler_attack_system: CrawlerAttackSystem
var crawler_animation_system: CrawlerAnimationSystem
var crawler_hitbox_manager: HitboxManagerBase

#health component
var stats: StatSystem
var death_handled := false

@export_group("Stat Tuning")
@export var max_health: int = 10

#hitbox variables
@export_group("Hitbox Type")
@export var crawler_hitbox: PackedScene
@export var crawler_melee_offsets: HitboxOffsetData

@export_group("Attack Tuning")
@export var windup_time:= 0.5   # Enemy windup
@export var lifetime:= 0.3       # How long hitbox stays active
@export var damage:= 10.0    # Damage done by enemy
## How long the crawler is locked in hitstun. Was implicitly the hurt
## animation's length; now independent of it.
@export var hurt_duration:= 0.2
@export var attack_detection_range:= 32.0 #must be 32 minimum to properly detect player

#patrol variables
@export_group("Patrol Tuning")
@export var patrol_wait_time:= 3.5
@export var patrol_timer:= 0.0
@export var min_patrol_distance:= 40.0

@export_group("Drop Tuning")
@export var gold_drop_chance: float = 0.3
@export var gold_min: int = 1
@export var gold_max: int = 4
@export var soul_drop_chance: float = 0.05
@export var soul_drop_amount: int = 1

var data: EnemyData

func _ready() -> void:
	stats = StatSystem.new(Stat.new(max_health))
	stats.health.emptied.connect(_on_health_emptied)
	
	data = EnemyData.new()
	
	var melee := AttackSpec.new()
	melee.scene = crawler_hitbox
	melee.offsets = crawler_melee_offsets
	melee.damage = damage
	melee.windup_time = windup_time
	melee.lifetime = lifetime
	melee.knockback_strength = 50.0
	
	crawler_hitbox_manager = HitboxManagerBase.new(self, HitboxManagerBase.LAYER_PLAYER_HURTBOX, func(): return data.facing_dir)
	crawler_hitbox_manager.register_attack(&"melee", melee)
	
	$Hurtbox._on_damage_received = _on_damage_received
	$Hurtbox.knockback_received.connect(_on_knockback_received)
	
	#injects data
	crawler_detection_system.initialize(data, self)
	
	crawler_state_machine = CrawlerStateMachine.new()
	crawler_movement_system = CrawlerMovementSystem.new(self, data)
	crawler_attack_system = CrawlerAttackSystem.new(self, crawler_hitbox_manager)
	crawler_animation_system = CrawlerAnimationSystem.new(sprite, data)

func _physics_process(delta: float) -> void:
	if data.is_dead:
		if not death_handled:
			death_handled = true
			_handle_death()
		return
	
	stats.update(delta)
	
	# Hitstun is a timer now. Ticked before the state machine so is_hurt is
	# current when the state resolves this frame.
	if data.hurt_timer > 0.0:
		data.hurt_timer -= delta
		if data.hurt_timer <= 0.0:
			data.is_hurt = false
	
	crawler_detection_system.update()
	crawler_state_machine.update(data, delta)
	crawler_movement_system.update(delta)
	crawler_attack_system.update(data, delta)
	crawler_animation_system.update()

func _on_damage_received(damage_amount: float) -> void:
	stats.health.remove(roundi(damage_amount))
	if data.is_dead:
		return
	data.is_hurt = true
	data.hurt_timer = hurt_duration
	data.hurt_seq += 1
	# Getting hit drops the swing. One punch into a cluster cancels every
	# crawler inside the hitbox — the player's answer to being mobbed.
	crawler_hitbox_manager.cancel_all()

func _on_health_emptied() -> void:
	data.is_dead = true
		
func _on_knockback_received(direction: Vector2, strength: float, decay: float) -> void:
	var knockback := MovementModifier.create_impulse(&"knockback", direction, strength, decay)
	data.modifiers.add(knockback)

func _handle_death() -> void:
	set_physics_process(false)
	sprite.play("died")
	_try_spawn_drops()
	await sprite.animation_finished
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _try_spawn_drops() -> void:
	if randf() < gold_drop_chance:
		var sack := GlobalPackedScenes.gold_sack.instantiate()
		sack.amount = randi_range(gold_min, gold_max)
		sack.global_position = global_position
		get_parent().add_child(sack)
	if randf() < soul_drop_chance:
		var soul := GlobalPackedScenes.soul.instantiate()
		soul.amount = soul_drop_amount
		soul.global_position = global_position
		get_parent().add_child(soul)
