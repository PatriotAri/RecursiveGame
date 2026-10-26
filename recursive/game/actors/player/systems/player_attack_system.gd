class_name PlayerAttackSystem

var player: CharacterBody2D
var player_hitbox_manager: HitboxManagerBase

var attack_timer:= 0.0
var attack_duration:= 0.0

var pending_spawn:= false

## Time left before each projectile attack can be used again, by attack
## name. Kept per attack, so swapping weapons or spells neither resets a
## cooldown nor hands it to the next attack. Melee attacks have no cooldown
## beyond their own length.
var _cooldowns:= {}
## Counts down the current throw's windup; below zero it has left the hand.
var _release_timer:= -1.0
## The attack whose windup _release_timer is counting.
var _releasing: StringName = &""

func _init(player_ref: CharacterBody2D, hb_ref: HitboxManagerBase) -> void:
	player = player_ref
	player_hitbox_manager = hb_ref
	# unarmed is the permanent fallback, so it's the one attack that must
	# always exist. Everything else is registered and unregistered by
	# equipment at runtime.
	if player_hitbox_manager.get_spec(&"unarmed") == null:
		push_error("PlayerAttackSystem: no 'unarmed' attack registered.")

func update(data: PlayerData, delta: float) -> void:
	# Ticks even through hitstun: a weapon already thrown comes back on time
	# whatever happens to the thrower.
	for attack_name in _cooldowns.keys():
		_cooldowns[attack_name] -= delta
		if _cooldowns[attack_name] <= 0.0:
			_cooldowns.erase(attack_name)
	if _release_timer >= 0.0:
		_release_timer -= delta
	# Empty-handed from release until the attack in hand is ready again.
	data.cooling_down = _release_timer < 0.0 and cooldown_left(data.current_attack) > 0.0
	
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
	if data.attack_requested and not data.is_attacking and cooldown_left(data.current_attack) <= 0.0:
		data.attack_requested = false
		# A staff with no spell readied has nothing to attack with.
		if data.current_attack == &"": return
		var spec := player_hitbox_manager.get_spec(data.current_attack)
		if spec == null:
			push_warning("PlayerAttackSystem: no attack registered for '%s'." % data.current_attack)
			return
		if spec.mana_cost > player.stats.mana.current:
			Sfx.play(Sfx.refused)
			return
		data.is_attacking = true
		# Timing comes from the spec, so a weapon with a slower windup locks
		# the player out for its own duration rather than the punch's.
		attack_timer = spec.windup_time + spec.lifetime
		attack_duration = attack_timer
		pending_spawn = true
		if spec is ProjectileAttackSpec:
			_cooldowns[data.current_attack] = spec.cooldown
			_release_timer = spec.windup_time
			_releasing = data.current_attack

## Drops any in-progress swing. pending_spawn surviving an interrupt would
## spawn the hitbox a frame later, after the attack was already cancelled.
func cancel(data: PlayerData) -> void:
	data.is_attacking = false
	data.attack_requested = false
	attack_timer = 0.0
	attack_duration = 0.0
	pending_spawn = false
	# Interrupted before it left the hand, nothing was thrown: no cooldown.
	if _release_timer >= 0.0:
		_cooldowns.erase(_releasing)
		_release_timer = -1.0

## Seconds before `attack_name` can be used again; 0 when it's ready.
func cooldown_left(attack_name: StringName) -> float:
	return _cooldowns.get(attack_name, 0.0)

func post_update(data: PlayerData) -> void:
	if not data.is_attacking:
		pending_spawn = false
		return
	
	if pending_spawn:
		pending_spawn = false
		player_hitbox_manager.spawn_hitbox(data.current_attack)
		
## 0 at the start of a swing, 1 at the end. Anything animating off the swing
## reads this rather than running its own timer, so a visual can't drift out
## of sync with the hitbox it's supposed to be selling.
func swing_progress() -> float:
	if attack_duration <= 0.0: return 0.0
	return clampf(1.0 - attack_timer / attack_duration, 0.0, 1.0)
