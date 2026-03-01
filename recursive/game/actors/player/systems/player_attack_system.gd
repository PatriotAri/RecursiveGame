class_name PlayerAttackSystem

#import packed global scenes
var global_packed_scenes:= GlobalPackedScenes

#packed scenes
var player_unarmed_hitbox = global_packed_scenes.player_unarmed_hitbox

var player: CharacterBody2D

var attack_timer:= 0.0

#hitbox variables
var windup_time: float
var lifetime: float
var damage: float

# Hitbox positioning offsets based on facing direction
const HITBOX_OFFSETS := {
	"right": Vector2(5, -20),
	"down_right": Vector2(5, -10),
	"down": Vector2(0, -10),
	"down_left": Vector2(-5, -10),
	"left": Vector2(-5, -20),
	"up_left": Vector2(-5, -48),
	"up": Vector2(0, -50),
	"up_right": Vector2(5, -48)
}

func _init(player_ref: CharacterBody2D) -> void:
	player = player_ref
	
	windup_time = player.windup_time
	lifetime = player.lifetime
	damage = player.damage

func update(data: PlayerData, delta: float) -> void:
	# Update attack timer
	if data.is_attacking:
		attack_timer -= delta
		if attack_timer <= 0:
			data.is_attacking = false
	
	# Start new attack if input received and not currently attacking
	if data.attack_requested and not data.is_attacking:
		data.attack_requested = false
		_execute_attack(data)

func _execute_attack(data: PlayerData) -> void:
	data.is_attacking = true
	attack_timer = windup_time + lifetime
	
	var dir:= FacingHelper.facing_to_string(data.facing_dir)
	_spawn_hitbox(dir)

func _spawn_hitbox(direction: String) -> void:
	if player_unarmed_hitbox == null:
		push_error("Player: Melee hitbox scene not loaded!")
		return
	
	var hitbox = player_unarmed_hitbox.instantiate()
	
	# Configure hitbox to hit enemies (layer 6 = bit value 32)
	hitbox.target_layer = 32
	hitbox.windup_time = windup_time
	hitbox.lifetime = lifetime
	hitbox.damage = damage
	
	var offset = HITBOX_OFFSETS.get(direction, Vector2.ZERO)
	
	player.add_child(hitbox)
	hitbox.position = offset
