class_name EnemyAttackSystem

var body: Enemy
var data: EnemyData

var attack_timer := 0.0
var attack_duration := 0.0

func _init(body_ref: Enemy, data_ref: EnemyData) -> void:
	body = body_ref
	data = data_ref
	if body.hitbox_manager.get_spec(body.primary_attack) == null:
		push_error("EnemyAttackSystem on %s: no '%s' attack registered." % [body.name, body.primary_attack])
	
func update(delta: float) -> void:
	#resets state whenever attack begins
	if data.current_state != EnemyData.State.ATTACK:
		return
	
	if data.state_just_changed:
		attack_timer = 0.0
		# Timing comes from the attack itself, so a slow swing and a quick
		# throw each hold the enemy for their own length.
		attack_duration = body.attack_duration(body.primary_attack)
		body.perform_attack(body.primary_attack)
		return

	attack_timer += delta
	if attack_timer >= attack_duration:
		data.attack_finished = true
