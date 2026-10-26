class_name EnemyAttackSystem

var body: Enemy
var hitbox_manager: HitboxManagerBase
## The registered attack this system swings. Comes from the enemy type.
var attack_name: StringName
var windup_time: float
var lifetime: float

var attack_performed := false
var attack_timer := 0.0

func _init(body_ref: Enemy, hb_ref: HitboxManagerBase) -> void:
	body = body_ref
	hitbox_manager = hb_ref
	attack_name = body.primary_attack
	var spec := hitbox_manager.get_spec(attack_name)
	if spec == null:
		push_error("EnemyAttackSystem on %s: no '%s' attack registered." % [body.name, attack_name])
		return
	# Timing comes from the spec, so the state lasts exactly as long as the
	# hitbox it spawned.
	windup_time = spec.windup_time
	lifetime = spec.lifetime

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
	hitbox_manager.spawn_hitbox(attack_name)
