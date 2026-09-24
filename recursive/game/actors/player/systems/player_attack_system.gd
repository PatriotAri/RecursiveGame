class_name PlayerAttackSystem

var player: CharacterBody2D
var player_hitbox_manager: HitboxManagerBase

var attack_timer:= 0.0

var pending_spawn:= false

func _init(player_ref: CharacterBody2D, hb_ref: HitboxManagerBase) -> void:
	player = player_ref
	player_hitbox_manager = hb_ref
	# unarmed is the permanent fallback, so it's the one attack that must
	# always exist. Everything else is registered and unregistered by
	# equipment at runtime.
	if player_hitbox_manager.get_spec(&"unarmed") == null:
		push_error("PlayerAttackSystem: no 'unarmed' attack registered.")

func update(data: PlayerData, delta: float) -> void:
	# No swinging out of hitstun. Without this the player could start an
	# attack and spawn a hitbox while the hurt state was still active.
	if data.is_hurt:
		cancel(data)
		return
	
	# Update attack timer
	if data.is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			data.is_attacking = false
	
	# Start new attack if input received and not currently attacking
	if data.attack_requested and not data.is_attacking:
		data.attack_requested = false
		var spec := player_hitbox_manager.get_spec(data.current_attack)
		if spec == null:
			push_warning("PlayerAttackSystem: no attack registered for '%s'." % data.current_attack)
			return
		data.is_attacking = true
		# Timing comes from the spec, so a weapon with a slower windup locks
		# the player out for its own duration rather than the punch's.
		attack_timer = spec.windup_time + spec.lifetime
		pending_spawn = true

## Drops any in-progress swing. pending_spawn surviving an interrupt would
## spawn the hitbox a frame later, after the attack was already cancelled.
func cancel(data: PlayerData) -> void:
	data.is_attacking = false
	data.attack_requested = false
	attack_timer = 0.0
	pending_spawn = false

func post_update(data: PlayerData) -> void:
	if not data.is_attacking:
		pending_spawn = false
		return
	
	if pending_spawn:
		pending_spawn = false
		player_hitbox_manager.spawn_hitbox(data.current_attack)
