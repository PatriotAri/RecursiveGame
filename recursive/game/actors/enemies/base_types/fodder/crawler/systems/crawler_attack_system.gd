class_name CrawlerAttackSystem

var crawler_melee_hitbox = GlobalPackedScenes.crawler_melee_hitbox

var body: CharacterBody2D
var windup_time: float
var lifetime: float
var damage: float

var attack_performed := false
var attack_timer := 0.0

# Hitbox positioning offsets based on 8-directional facing.
# Crawler origin is at body center (capsule), so Y=0 is mid-body,
const HITBOX_OFFSETS := {
	"right": Vector2(10, -10),
	"down_right": Vector2(10, -5),
	"down": Vector2( 0, 0),
	"down_left": Vector2(-10, -5),
	"left": Vector2(-10, -10),
	"up_left": Vector2(-5, -20),
	"up": Vector2( 0, -20),
	"up_right": Vector2(5, -20)
}

func _init(body_ref: CharacterBody2D) -> void:
	body = body_ref
	windup_time = body.windup_time
	lifetime = body.lifetime
	damage = body.damage
	
func update(data: EnemyData, delta: float) -> void:
	#resets state whenever attack begins
	if data.current_state != CrawlerStateMachine.State.ATTACK:
		return
	
	if data.state_just_changed:
		attack_performed = false
		attack_timer = 0.0
		execute_attack(data)
		attack_performed = true
		return

	attack_timer += delta
	if attack_timer >= windup_time + lifetime:
		data.attack_finished = true

func execute_attack(data: EnemyData) -> void:
	var facing:= data.last_facing if data.last_facing != Vector2.ZERO else Vector2.DOWN
	var dir:= FacingHelper.facing_to_string(facing)
	spawn_hitbox(dir)
	
func spawn_hitbox(direction: String) -> void:
	if crawler_melee_hitbox == null:
		push_error("Crawler: Melee hitbox scene not loaded!")
		return

	var hitbox = crawler_melee_hitbox.instantiate()
	hitbox.target_layer = 16  # hits player hurtbox (physics layer 5)
	hitbox.windup_time = windup_time
	hitbox.lifetime = lifetime
	hitbox.damage = damage

	var offset = HITBOX_OFFSETS.get(direction, Vector2.ZERO)
	body.add_child(hitbox)
	hitbox.position = offset
