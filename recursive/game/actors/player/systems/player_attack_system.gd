class_name PlayerAttackSystem

var player: CharacterBody2D
var player_hitbox_manager: PlayerHitboxManager

var attack_timer:= 0.0

#hitbox variables
var windup_time: float
var lifetime: float
var damage: float

var pending_spawn:= false

func _init(player_ref: CharacterBody2D, hb_ref: PlayerHitboxManager) -> void:
	player = player_ref
	player_hitbox_manager = hb_ref
	windup_time = player.windup_time
	lifetime = player.lifetime
	damage = player.damage

func update(data: PlayerData, delta: float) -> void:
	# Update attack timer
	if data.is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			data.is_attacking = false
	
	# Start new attack if input received and not currently attacking
	if data.attack_requested and not data.is_attacking:
		data.attack_requested = false
		data.is_attacking = true
		attack_timer = windup_time + lifetime
		pending_spawn = true

func post_update(data: PlayerData) -> void:
	if not data.is_attacking:
		pending_spawn = false
		return
	
	if pending_spawn:
		pending_spawn = false
		player_hitbox_manager.spawn_hitbox(&"unarmed", damage, windup_time, lifetime)
