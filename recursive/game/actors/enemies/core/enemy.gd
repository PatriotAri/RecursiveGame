class_name Enemy

extends Actor

## Shared body for every enemy type. Owns the AI systems; hits, hitstun,
## knockback and death come from Actor. A type only describes itself: its
## exports in the scene, and _register_attacks() / perform_attack() when it
## needs more than one melee swing.
##
## Expected children: Actor's, plus DetectionArea (EnemyDetectionSystem).

#type casts DetectionArea as DetectionSystem, allows script to send signals
@onready var detection_system: EnemyDetectionSystem = $DetectionArea as EnemyDetectionSystem
var state_machine: EnemyStateMachine
var movement_system: EnemyMovementSystem
var attack_system: EnemyAttackSystem
var animation_system: EnemyAnimationSystem
var hitbox_manager: HitboxManagerBase

## The type's tuning: stats, attack, AI ranges, movement, flee, patrol,
## drops. Shared by every enemy of the type and treated as read-only.
@export var profile: EnemyProfile

## Which registered attack the state machine commits to. A type with several
## attacks can change this between swings.
var primary_attack: StringName = &"melee"

## Derived in _ready() from the primary attack's own geometry.
var attack_range:= 0.0

var data: EnemyData

## False while off screen: the sprite stops animating. Nobody can see it,
## and with a big wave most of the field is off screen at once.
var _on_screen:= true

## Paths round walls; see EnemyNavigation.
var navigation: EnemyNavigation

func _ready() -> void:
	stats = StatSystem.new(Stat.new(profile.max_health))
	stats.armor = profile.armor

	data = EnemyData.new()
	_setup_actor(data)
	data.patrol_speed = profile.patrol_speed
	data.walk_speed = profile.walk_speed
	data.acceleration = profile.acceleration
	data.friction = profile.friction
	
	navigation = EnemyNavigation.new(self)
	
	# Headless runs (servers, tests) draw nothing and never report on-screen
	# changes, so there's nothing to save and the notifier is skipped.
	if DisplayServer.get_name() != "headless":
		var notifier := VisibleOnScreenNotifier2D.new()
		notifier.rect = Rect2(-40, -80, 80, 96)
		notifier.screen_entered.connect(_set_on_screen.bind(true))
		notifier.screen_exited.connect(_set_on_screen.bind(false))
		add_child(notifier)
		# The signals only fire on a change. One spawned off screen never
		# changes, so take the real state once the notifier has had a frame.
		_sync_on_screen.call_deferred(notifier)

	hitbox_manager = HitboxManagerBase.new(self, HitboxManagerBase.LAYER_PLAYER_HURTBOX, func(): return data.facing_dir)
	_register_attacks()

	# Commit range comes from the attack instead of a hand-typed number.
	# Must be computed before the detection system initialises below.
	attack_range = _compute_attack_range()

	#injects data
	detection_system.initialize(data, self)

	state_machine = EnemyStateMachine.new(self)
	movement_system = EnemyMovementSystem.new(self, data)
	attack_system = EnemyAttackSystem.new(self, data)
	animation_system = EnemyAnimationSystem.new(sprite, data)

func _actor_process(delta: float) -> void:
	detection_system.update(delta)
	state_machine.update(data, delta)
	movement_system.update(delta)
	attack_system.update(delta)
	if _on_screen:
		animation_system.update(attack_system.attack_duration)

func _sync_on_screen(notifier: VisibleOnScreenNotifier2D) -> void:
	await get_tree().process_frame
	if is_instance_valid(notifier):
		_set_on_screen(notifier.is_on_screen())

func _set_on_screen(on_screen: bool) -> void:
	_on_screen = on_screen
	# The death animation always plays out — something waits on it finishing.
	if data.is_dead: return
	if on_screen:
		sprite.play()
	else:
		sprite.pause()

# --- navigation -------------------------------------------------------------

## Whether this enemy routes round walls. A flyer doesn't, but its
## navigation still snaps patrol points onto the floor.
func uses_pathfinding() -> bool:
	return true

## Everything added on top of the enemy's own locomotion each frame, besides
## knockback. Spacing by default; override to add more (a flyer's flutter).
func steering_velocity() -> Vector2:
	return spacing_velocity()

## Push away from nearby enemies, as a velocity. Only the grid cells within
## spacing_radius are searched; see SpacingGrid.
func spacing_velocity() -> Vector2:
	if profile.spacing_radius <= 0.0: return Vector2.ZERO
	var push := Vector2.ZERO
	var here := SpacingGrid.cell_of(global_position)
	var reach := ceili(profile.spacing_radius / SpacingGrid.CELL)
	var radius_sq := profile.spacing_radius * profile.spacing_radius
	var tree := get_tree()
	for cy in range(here.y - reach, here.y + reach + 1):
		for cx in range(here.x - reach, here.x + reach + 1):
			for other in SpacingGrid.bucket(tree, Vector2i(cx, cy)):
				if other == self:
					continue
				var away := global_position - other.global_position
				var dist_sq := away.length_squared()
				if dist_sq >= radius_sq:
					continue
				var dist := sqrt(dist_sq)
				if dist < 0.01:
					# Exactly stacked (two spawns on one point): pick a
					# direction rather than dividing by zero.
					away = Vector2.RIGHT.rotated(randf() * TAU)
					dist = 0.01
				push += away / dist * (1.0 - dist / profile.spacing_radius)
	return push * profile.spacing_strength

# --- overridable ------------------------------------------------------------

## Registers every attack this enemy can use with hitbox_manager. The default
## registers `attack` as primary_attack, which is all most enemies need.
## Override to add more, and set primary_attack to the one to commit to.
func _register_attacks() -> void:
	if profile.attack == null:
		push_error("%s: its profile has no attack." % name)
		return
	hitbox_manager.register_attack(primary_attack, profile.attack)

## How close the target has to be before the state machine commits to an
## attack. Override for attacks that don't come from a melee hitbox.
func _compute_attack_range() -> float:
	var spec := hitbox_manager.get_spec(primary_attack)
	if spec == null:
		push_error("%s: primary attack '%s' isn't registered." % [name, primary_attack])
		return 0.0
	return spec.min_reach() + profile.target_radius

## Starts the attack. Called once, on the frame the state machine enters
## ATTACK. Override for anything that isn't a hitbox swing.
func perform_attack(attack_name: StringName) -> void:
	hitbox_manager.spawn_hitbox(attack_name)

## How long ATTACK lasts before the state machine moves to cooldown.
func attack_duration(attack_name: StringName) -> float:
	var spec := hitbox_manager.get_spec(attack_name)
	if spec == null: return 0.0
	return spec.windup_time + spec.lifetime

## Stops anything an attack left running. Called on stagger and on death.
func cancel_attacks() -> void:
	hitbox_manager.cancel_all()

# --- damage / death ---------------------------------------------------------

## Getting hit drops the swing — but only when the stagger lands.
func _on_staggered() -> void:
	cancel_attacks()

func _handle_death() -> void:
	# Hitboxes are children with their own _physics_process — this node's
	# death doesn't stop theirs. A swing started before the killing blow
	# would still land from the corpse.
	cancel_attacks()
	# Stops being a wall and being hittable, and plays the death sound.
	super()
	# A swing's tuned speed would otherwise carry into the death animation.
	sprite.speed_scale = 1.0
	sprite.play("died")
	_try_spawn_drops()
	await sprite.animation_finished
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _try_spawn_drops() -> void:
	if profile.drop_table == null: return
	profile.drop_table.roll(get_parent(), global_position)
