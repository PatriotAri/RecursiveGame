class_name PlayerAttackSystem

#import packed global scenes
var global_packed_scenes:= GlobalPackedScenes

#packed scenes
var melee_hitbox_scene = global_packed_scenes.melee_attack_hitbox

var player: CharacterBody2D

var attack_timer:= 0.0

#hitbox variables
var windup_time: float
var lifetime: float
var damage: float

# Hitbox positioning offsets based on facing direction
const HITBOX_OFFSETS := {
	"right": Vector2(30, -15),
	"down_right": Vector2(25, 0),
	"down": Vector2(0, 15),
	"down_left": Vector2(-25, 0),
	"left": Vector2(-30, -15),
	"up_left": Vector2(-25, -30),
	"up": Vector2(0, -40),
	"up_right": Vector2(25, -30)
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
	if melee_hitbox_scene == null:
		push_error("Player: Melee hitbox scene not loaded!")
		return
	
	var hitbox = melee_hitbox_scene.instantiate()
	
	# Configure hitbox to hit enemies (layer 6 = bit value 32)
	hitbox.target_layer = 32
	hitbox.windup_time = windup_time
	hitbox.lifetime = lifetime
	hitbox.damage = damage
	
	var offset = HITBOX_OFFSETS.get(direction, Vector2.ZERO)
	
	player.add_child(hitbox)
	hitbox.position = offset
