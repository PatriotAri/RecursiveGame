class_name CrawlerAttackSystem

var body: CharacterBody2D
var hitbox_manager: CrawlerHitboxManager
var windup_time: float
var lifetime: float
var damage: float

var attack_performed := false
var attack_timer := 0.0

func _init(body_ref: CharacterBody2D, hb_ref: CrawlerHitboxManager) -> void:
	body = body_ref
	hitbox_manager = hb_ref
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
		execute_attack()
		attack_performed = true
		return

	attack_timer += delta
	if attack_timer >= windup_time + lifetime:
		data.attack_finished = true

func execute_attack() -> void:
	hitbox_manager.spawn_hitbox(&"melee", damage, 40.0, windup_time, lifetime)
	
