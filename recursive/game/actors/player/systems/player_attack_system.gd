class_name PlayerAttackSystem

#packed scenes
var player_unarmed_hitbox = GlobalPackedScenes.player_unarmed_hitbox

var player: CharacterBody2D

var attack_timer:= 0.0

#hitbox variables
var windup_time: float
var lifetime: float
var damage: float

var pending_spawn:= false
var active_hitbox: Area2D = null

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
		if attack_timer <= 0.0:
			data.is_attacking = false
	
	# Start new attack if input received and not currently attacking
	if data.attack_requested and not data.is_attacking:
		data.attack_requested = false
		data.is_attacking = true
		attack_timer = windup_time + lifetime
		pending_spawn = true

func post_update(data: PlayerData) -> void:
	var dir:= FacingHelper.facing_to_string(data.facing_dir)
	if pending_spawn:
		pending_spawn = false
		active_hitbox = spawn_hitbox(dir)
	elif is_instance_valid(active_hitbox):
		active_hitbox.position = HITBOX_OFFSETS.get(dir, Vector2.ZERO)
		
func spawn_hitbox(direction: String) -> Area2D:
	if player_unarmed_hitbox == null:
		push_error("Player: Melee hitbox scene not loaded!")
		return null
	
	var hitbox: Area2D = player_unarmed_hitbox.instantiate()
	hitbox.target_layer = 32
	hitbox.windup_time = windup_time
	hitbox.lifetime = lifetime
	hitbox.damage = damage
	hitbox.position = HITBOX_OFFSETS.get(direction, Vector2.ZERO)
	player.add_child(hitbox)
	return hitbox
