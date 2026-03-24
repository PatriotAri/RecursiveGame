class_name CrawlerAttackSystem

var crawler_melee_hitbox = GlobalPackedScenes.crawler_melee_hitbox

var body: CharacterBody2D
var windup_time: float
var lifetime: float
var damage: float

var attack_performed := false
var attack_timer := 0.0

func _init(body_ref: CharacterBody2D, hb_ref: CrawlerHitboxManager) -> void:
	body = body_ref
	windup_time = body.windup_time
	lifetime = body.lifetime
	damage = body.damage
	
func update(data: EnemyData, delta: float) -> void:
	#resets state whenever attack begins
	if data.current_state != EnemyData.State.ATTACK:
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
	
