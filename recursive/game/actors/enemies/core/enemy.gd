class_name Enemy

extends CharacterBody2D

## Emitted once, on the killing blow — before the death animation, so a
## round can count the kill without waiting for the corpse to fade.
signal died

## Shared body for every enemy type. Owns the systems and the health, hurt,
## knockback and death plumbing. A type only describes itself: its exports in
## the scene, and _register_attacks() / perform_attack() when it needs more
## than one melee swing.
##
## Expected children: Sprite (AnimatedSprite2D), Collision, Hurtbox,
## DetectionArea (EnemyDetectionSystem). PatrolZone is optional.

#type casts DetectionArea as DetectionSystem, allows script to send signals
@onready var detection_system: EnemyDetectionSystem = $DetectionArea as EnemyDetectionSystem
@onready var sprite: AnimatedSprite2D = $Sprite
var state_machine: EnemyStateMachine
var movement_system: EnemyMovementSystem
var attack_system: EnemyAttackSystem
var animation_system: EnemyAnimationSystem
var hitbox_manager: HitboxManagerBase

#health component
var stats: StatSystem
var _flash_tween: Tween
var death_handled := false

@export_group("Stat Tuning")
@export var max_health: int = 10

#hitbox variables
@export_group("Hitbox Type")
@export var melee_hitbox: PackedScene
@export var melee_offsets: HitboxOffsetData
## Radius of melee_hitbox's CircleShape2D. See AttackSpec.reach_radius.
@export var melee_reach_radius:= 10.0

@export_group("Attack Tuning")
@export var windup_time:= 0.5   # Enemy windup
@export var lifetime:= 0.3       # How long hitbox stays active
@export var damage:= 10.0    # Damage done by enemy
@export var knockback_strength:= 50.0
@export_range(0.0, 1.0) var hitstun_chance:= 0.3
@export_range(0.0, 1.0) var knockback_chance:= 0.3
## How long the enemy is locked in hitstun. Was implicitly the hurt
## animation's length; now independent of it.
@export var hurt_duration:= 0.2
## Pause between swings. Owed after a completed attack and after an
## interrupted one.
@export var attack_cooldown:= 1.5
## Half-width of what this enemy is trying to hit — the player's hurtbox is
## 32 wide, so 16. The narrow axis, so the derived range stays conservative.
@export var target_radius:= 16.0
## Grace period after the player leaves the detection shape before aggro drops.
## Stops a target walking the boundary from flickering CHASE/PATROL every frame.
@export var target_forget_delay:= 1.0
## Once aggroed, the player has to get this far away before the forget
## countdown even starts. Pathing round a wall routinely carries an enemy
## out of its detection shape mid-chase; without this it would give up.
@export var leash_distance:= 320.0
## Only commit to an attack with a clear line to the target. For anything
## that shoots — melee can't hit through a wall anyway.
@export var needs_line_of_sight:= false
## Backs away while cooling down if the player is closer than this. For
## enemies that want to fight from range. 0 = holds position.
@export var preferred_distance:= 0.0

#movement variables
@export_group("Movement Tuning")
@export var patrol_speed:= 50.0
@export var walk_speed:= 65.0
@export var acceleration:= 500.0 #px/s^2
@export var friction:= 600.0 #px/s^2

#spacing variables
@export_group("Spacing Tuning")
## Other enemies closer than this get pushed apart, so a group doesn't
## collapse into one stacked sprite.
@export var spacing_radius:= 28.0
## Push speed at full overlap, in px/s. Fades to zero at spacing_radius.
@export var spacing_strength:= 60.0

#flee variables
@export_group("Flee Tuning")
## Flees when health falls to this fraction with the player nearby.
## 0 = never flees.
@export_range(0.0, 1.0) var flee_health_ratio:= 0.0
@export var flee_speed:= 110.0
## Stops running once the player is this far away.
@export var flee_safe_distance:= 220.0
## A single flee gives up after this long...
@export var flee_max_time:= 3.0
## ...and can't start again until this much later.
@export var flee_recover_time:= 2.5

#patrol variables
@export_group("Patrol Tuning")
@export var patrol_wait_time:= 3.5
@export var patrol_timer:= 0.0
@export var min_patrol_distance:= 40.0

@export_group("Drop Tuning")
@export var drop_table: DropTable

@export_group("Sounds")
## Given to the default melee attack. A type that registers its own attacks
## sets AttackSpec.sound on each instead.
@export var attack_sound: SoundEffect = preload("res://game/audio/sfx/enemy_attack.tres")
@export var hurt_sound: SoundEffect = preload("res://game/audio/sfx/hit.tres")
@export var death_sound: SoundEffect = preload("res://game/audio/sfx/enemy_death.tres")

## Which registered attack the state machine commits to. A type with several
## attacks can change this between swings.
var primary_attack: StringName = &"melee"

## Derived in _ready() from the primary attack's own geometry.
var attack_range:= 0.0

var data: EnemyData

## Paths around walls. Created in code so enemy scenes need no extra node;
## with no navmesh in the level, movement falls back to straight lines.
var nav_agent: NavigationAgent2D

## Re-query the path only when the target has moved this far. Chasing a
## moving player otherwise asks for a new path every single frame.
const REPATH_DISTANCE_SQ := 16.0 * 16.0

func _ready() -> void:
	stats = StatSystem.new(Stat.new(max_health))
	stats.health.emptied.connect(_on_health_emptied)

	data = EnemyData.new()
	data.patrol_speed = patrol_speed
	data.walk_speed = walk_speed
	data.acceleration = acceleration
	data.friction = friction
	
	nav_agent = NavigationAgent2D.new()
	nav_agent.path_desired_distance = 8.0
	nav_agent.target_desired_distance = 8.0
	nav_agent.radius = spacing_radius * 0.5
	add_child(nav_agent)

	hitbox_manager = HitboxManagerBase.new(self, HitboxManagerBase.LAYER_PLAYER_HURTBOX, func(): return data.facing_dir)
	_register_attacks()

	# Commit range comes from the attack instead of a hand-typed number.
	# Must be computed before the detection system initialises below.
	attack_range = _compute_attack_range()

	$Hurtbox._on_damage_received = _on_damage_received
	$Hurtbox.knockback_received.connect(_on_knockback_received)

	#injects data
	detection_system.initialize(data, self)

	state_machine = EnemyStateMachine.new(attack_cooldown)
	movement_system = EnemyMovementSystem.new(self, data)
	attack_system = EnemyAttackSystem.new(self, data)
	animation_system = EnemyAnimationSystem.new(sprite, data)

func _physics_process(delta: float) -> void:
	if data.is_dead:
		if not death_handled:
			death_handled = true
			_handle_death()
		return

	stats.update(delta)

	# Hitstun is a timer now. Ticked before the state machine so is_hurt is
	# current when the state resolves this frame.
	if data.hurt_timer > 0.0:
		data.hurt_timer -= delta
		if data.hurt_timer <= 0.0:
			data.is_hurt = false

	detection_system.update(delta)
	_update_danger(delta)
	state_machine.update(data, delta)
	movement_system.update(delta)
	attack_system.update(delta)
	animation_system.update()

## Decides whether this enemy wants to run, and keeps the flee timers.
func _update_danger(delta: float) -> void:
	if data.flee_block_timer > 0.0:
		data.flee_block_timer -= delta
	if data.current_state == EnemyData.State.FLEE:
		data.flee_timer += delta
		if data.flee_timer >= flee_max_time:
			data.flee_timer = 0.0
			data.flee_block_timer = flee_recover_time
	else:
		data.flee_timer = 0.0
	
	data.in_danger = flee_health_ratio > 0.0 \
		and data.flee_block_timer <= 0.0 \
		and data.player_detected \
		and stats.health.ratio() <= flee_health_ratio \
		and global_position.distance_to(data.player_pos) < flee_safe_distance

# --- navigation -------------------------------------------------------------

## Where to head next on the way to `target`: the next corner of a path
## around walls, or `target` itself when there's no navmesh to path on.
func next_path_position(target: Vector2) -> Vector2:
	if not uses_pathfinding() or not has_navigation():
		return target
	if nav_agent.target_position.distance_squared_to(target) > REPATH_DISTANCE_SQ:
		nav_agent.target_position = target
	if nav_agent.is_navigation_finished():
		return target
	return nav_agent.get_next_path_position()

## The nearest walkable point to `point`, for picking destinations that
## aren't inside a wall. Unchanged when there's no navmesh.
func closest_walkable(point: Vector2) -> Vector2:
	if not has_navigation():
		return point
	return NavigationServer2D.map_get_closest_point(nav_agent.get_navigation_map(), point)

## Whether this enemy routes round walls. A flyer doesn't, but still wants
## has_navigation() for picking destinations on the floor.
func uses_pathfinding() -> bool:
	return true

func has_navigation() -> bool:
	var map := nav_agent.get_navigation_map()
	# Iteration 0 means the map has never synced — no region baked yet.
	return map.is_valid() and NavigationServer2D.map_get_iteration_id(map) > 0 \
		and not NavigationServer2D.map_get_regions(map).is_empty()

## Everything added on top of the enemy's own locomotion each frame, besides
## knockback. Spacing by default; override to add more (a flyer's flutter).
func steering_velocity() -> Vector2:
	return spacing_velocity()

## Every enemy, fetched once per physics frame and shared. Each enemy asking
## the tree itself meant copying the whole group n times a frame.
static var _group_cache: Array[Node] = []
static var _group_cache_frame:= -1

func _enemies() -> Array[Node]:
	var frame := Engine.get_physics_frames()
	if frame != _group_cache_frame:
		_group_cache_frame = frame
		_group_cache = get_tree().get_nodes_in_group(&"enemy")
	return _group_cache

## Push away from nearby enemies, as a velocity.
func spacing_velocity() -> Vector2:
	var push := Vector2.ZERO
	for other in _enemies():
		if other == self or not is_instance_valid(other) or not (other is Enemy) or other.data == null or other.data.is_dead:
			continue
		var away: Vector2 = global_position - other.global_position
		var dist := away.length()
		if dist >= spacing_radius:
			continue
		if dist < 0.01:
			# Exactly stacked (two spawns on one point): pick a direction
			# rather than dividing by zero.
			away = Vector2.RIGHT.rotated(randf() * TAU)
			dist = 0.01
		push += away / dist * (1.0 - dist / spacing_radius)
	return push * spacing_strength

# --- overridable ------------------------------------------------------------

## Registers every attack this enemy can use with hitbox_manager. The default
## builds one melee swing from the exports above, which is all a fodder enemy
## needs. Override to add more, and set primary_attack to the one to commit to.
func _register_attacks() -> void:
	var melee := AttackSpec.new()
	melee.scene = melee_hitbox
	melee.offsets = melee_offsets
	melee.damage = damage
	melee.windup_time = windup_time
	melee.lifetime = lifetime
	melee.reach_radius = melee_reach_radius
	melee.knockback_strength = knockback_strength
	melee.hitstun_chance = hitstun_chance
	melee.knockback_chance = knockback_chance
	melee.sound = attack_sound
	hitbox_manager.register_attack(&"melee", melee)

## How close the target has to be before the state machine commits to an
## attack. Override for attacks that don't come from a melee hitbox.
func _compute_attack_range() -> float:
	var spec := hitbox_manager.get_spec(primary_attack)
	if spec == null:
		push_error("%s: primary attack '%s' isn't registered." % [name, primary_attack])
		return 0.0
	return spec.min_reach() + target_radius

## Starts the attack. Called once, on the frame the state machine enters
## ATTACK. Override for anything that isn't a hitbox swing.
func perform_attack(attack_name: StringName) -> void:
	hitbox_manager.spawn_hitbox(attack_name)

## How long ATTACK lasts before the state machine moves to cooldown.
func attack_duration(attack_name: StringName) -> float:
	var spec := hitbox_manager.get_spec(attack_name)
	if spec == null: return 0.0
	return spec.windup_time + spec.lifetime

## Plays a sound at this enemy's position. Null is silent.
func play_sound(effect: SoundEffect) -> void:
	AudioManager.play_sfx(effect, global_position)

## Stops anything an attack left running. Called on stagger and on death.
func cancel_attacks() -> void:
	hitbox_manager.cancel_all()

# --- damage / death ---------------------------------------------------------

func _on_damage_received(damage_amount: float, apply_hitstun: bool) -> void:
	stats.health.remove(roundi(damage_amount))
	_show_hit(roundi(damage_amount))
	if data.is_dead:
		return
	play_sound(hurt_sound)
	_flash_damage()
	if not apply_hitstun:
		return
	data.is_hurt = true
	data.hurt_timer = hurt_duration
	data.hurt_seq += 1
	# Getting hit drops the swing — but only when the stagger lands.
	cancel_attacks()

## Where hits are shown: the middle of the hurtbox, not the feet.
func _show_hit(amount: int) -> void:
	var at: Vector2 = $Hurtbox/CollisionShape2D.global_position
	DamageNumber.spawn(get_parent(), at + Vector2(0, -14), amount, Color.WHITE)
	HitSpark.spawn(get_parent(), at)

## Feedback that a hit landed, separate from whether it staggered. Every hit
## flashes; only some of them interrupt.
func _flash_damage() -> void:
	# A second hit mid-flash would otherwise leave two tweens fighting over
	# modulate, and the sprite can end up stuck tinted.
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	sprite.modulate = Color(1, 0.3, 0.3)
	_flash_tween = create_tween()
	_flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func _on_health_emptied() -> void:
	if data.is_dead: return
	data.is_dead = true
	died.emit()

func _on_knockback_received(direction: Vector2, strength: float, decay: float) -> void:
	var knockback := MovementModifier.create_impulse(&"knockback", direction, strength, decay)
	data.modifiers.add(knockback)

func _handle_death() -> void:
	set_physics_process(false)
	# Hitboxes are children with their own _physics_process — killing this
	# node's processing doesn't stop theirs. A swing started before the
	# killing blow would still land from the corpse.
	cancel_attacks()
	# Stop being a wall, and stop eating the player's attacks.
	$Collision.set_deferred("disabled", true)
	$Hurtbox.set_deferred("monitorable", false)
	sprite.play("died")
	play_sound(death_sound)
	_try_spawn_drops()
	await sprite.animation_finished
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _try_spawn_drops() -> void:
	if drop_table == null: return
	drop_table.roll(get_parent(), global_position)
