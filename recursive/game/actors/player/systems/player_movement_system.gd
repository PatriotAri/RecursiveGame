class_name PlayerMovementSystem

var player: Player
var locomotion:= Locomotion.new()

func _init(player_ref: Player) -> void:
	player = player_ref

func update(data: PlayerData, delta: float) -> void:
	data.modifiers.update(delta)
	
	#velocity override takes full control (dash, charge, etc.)
	if locomotion.run_override(player, data.modifiers):
		return
	
	var speed := data.run_speed if data.is_running else data.walk_speed
	
	#apply speed scale modifiers (slows, buffs)
	speed *= data.modifiers.get_speed_scale()
	
	var target_velocity := data.move_vector * speed
	
	if target_velocity.length() > 0.0:
		#accelerate player
		locomotion.accelerate(target_velocity, data.acceleration, delta)
	else:
		#decelerates to zero
		locomotion.brake(data.friction, delta)
	
	#layer impulse modifiers on top (knockback, recoil) — this frame only
	locomotion.commit(player, data.modifiers)
