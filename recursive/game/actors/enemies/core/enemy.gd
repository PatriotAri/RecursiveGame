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

@export_group("Stat Tuning")
@export var max_health: int = 10
## Armor points. See StatSystem.mitigate().
@export var armor: int = 0

@export_group("Attack Tuning")
## What a swing (or shot) is: hitbox or projectile scene, damage, timing,
## sound. A resource like a weapon's, so attacks are tuned and shared as
## data rather than as a dozen exports per enemy.
@export var attack: AttackSpec
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
## Size of the box, centred on the spawn point's surroundings, that patrol
## points are picked from. Zero stands still. A plain value rather than an
## Area2D: the old PatrolZone area was only ever read for its size, but sat
## on the Environment layer overlapping every wall and every other zone —
## measured as the single biggest physics cost with many enemies.
@export var patrol_size:= Vector2(300, 275)
@export var patrol_wait_time:= 3.5
@export var patrol_timer:= 0.0
@export var min_patrol_distance:= 40.0

@export_group("Drop Tuning")
@export var drop_table: DropTable

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
	stats.armor = armor

	data = EnemyData.new()
	_setup_actor(data)
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

	#injects data
	detection_system.initialize(data, self)

	state_machine = EnemyStateMachine.new(attack_cooldown)
	movement_system = EnemyMovementSystem.new(self, data)
	attack_system = EnemyAttackSystem.new(self, data)
	animation_system = EnemyAnimationSystem.new(sprite, data)

func _actor_process(delta: float) -> void:
	detection_system.update(delta)
	_update_danger(delta)
	state_machine.update(data, delta)
	movement_system.update(delta)
	attack_system.update(delta)
	animation_system.update(attack_system.attack_duration)

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
	var next := nav_agent.get_next_path_position()
	# No path (the query found nothing): head straight for the target. Seen
	# once in testing as an enemy frozen in place for the rest of a fight,
	# returning its own position as the next point forever.
	if nav_agent.get_current_navigation_path().is_empty():
		return target
	return next

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
	# Iteration 0 means the map has never synced.
	if not map.is_valid() or NavigationServer2D.map_get_iteration_id(map) == 0:
		return false
	# A region sits on the map from the moment the level loads, before its
	# navmesh is baked into it. Until there's a polygon to stand on, there's
	# nothing to path over or snap to.
	return NavigationServer2D.map_get_closest_point_owner(map, global_position).is_valid()

## Everything added on top of the enemy's own locomotion each frame, besides
## knockback. Spacing by default; override to add more (a flyer's flutter).
func steering_velocity() -> Vector2:
	return spacing_velocity()

## Push away from nearby enemies, as a velocity. Only the grid cells within
## spacing_radius are searched; see SpacingGrid.
func spacing_velocity() -> Vector2:
	if spacing_radius <= 0.0: return Vector2.ZERO
	var push := Vector2.ZERO
	var here := SpacingGrid.cell_of(global_position)
	var reach := ceili(spacing_radius / SpacingGrid.CELL)
	var radius_sq := spacing_radius * spacing_radius
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
				push += away / dist * (1.0 - dist / spacing_radius)
	return push * spacing_strength

# --- overridable ------------------------------------------------------------

## Registers every attack this enemy can use with hitbox_manager. The default
## registers `attack` as primary_attack, which is all most enemies need.
## Override to add more, and set primary_attack to the one to commit to.
func _register_attacks() -> void:
	if attack == null:
		push_error("%s: no attack assigned." % name)
		return
	hitbox_manager.register_attack(primary_attack, attack)

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
	if drop_table == null: return
	drop_table.roll(get_parent(), global_position)
