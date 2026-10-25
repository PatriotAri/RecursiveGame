class_name HitboxBase

extends Area2D

## Which attack spawned this hitbox. Set by the manager in step 7.
var attack_name: StringName = &""

var damage:= 0.0
var windup_time:= 0.0
var lifetime:= 0.0
var target_layer:= 0

var knockback_direction:= Vector2.ZERO
var knockback_strength:= 0.0
var knockback_decay:= 800.0 #px/s^2
var hitstun_chance:= 1.0
var knockback_chance:= 1.0

## Supplied at spawn so the hitbox can re-aim itself. Leave either unset and
## it stays pinned to the offset it was given, which is what a hitbox that
## shouldn't follow its owner wants.
var offsets: HitboxOffsetData
var facing_provider: Callable

var _elapsed:= 0.0
var _active:= false
var _hit_ids:= {}
## True from cancel() until the pool hands this hitbox out again. Pooled
## hitboxes are never freed, so this replaces is_queued_for_deletion().
var _released:= false

func _ready() -> void:
	if damage <= 0.0:
		push_warning("%s: damage is %.1f - was it set?" % [name, damage])
	if lifetime <= 0.0:
		push_warning("%s: lifetime is %.1f — was it set?" % [name, lifetime])
	get_target_layer()
	area_entered.connect(_on_area_entered)
	monitoring = false
	monitorable = false
	set_physics_process(false)

func get_target_layer() -> void:
	#set collision mask if target_layer is specified
	if target_layer > 0:
		collision_mask = target_layer

## Clears everything one swing left behind, so a pooled hitbox starts the
## next one fresh. Called by the manager before the spawn properties are set.
## _ready() only runs the first time, so per-swing setup belongs here.
func reset() -> void:
	_elapsed = 0.0
	_active = false
	_released = false
	_hit_ids.clear()
	monitoring = false
	monitorable = false
	set_physics_process(false)

func is_released() -> bool:
	return _released

# Starts the windup clock. Ticked rather than awaited: an awaited timer
# resumes on a freed instance if the swing is cancelled mid-windup. A tick
# just stops, and can be cancelled on demand.
func begin_attack() -> void:
	# Spawn properties are set after reset(), so the mask is re-derived here.
	get_target_layer()
	_elapsed = 0.0
	_active = false
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	_elapsed += delta
	_track_facing()
	if not _active:
		if _elapsed >= windup_time:
			_activate()
		return
	if _elapsed >= windup_time + lifetime:
		cancel()

## Re-aims at the actor's current facing. Without this the hitbox keeps the
## offset it was handed at spawn, so turning mid-swing leaves the damage where
## you used to be pointing while the weapon sprite follows you round.
func _track_facing() -> void:
	if offsets == null or not facing_provider.is_valid():
		return
	var facing: Vector2 = facing_provider.call()
	if facing == Vector2.ZERO:
		return
	position = offsets.get_offset_at(FacingHelper.facing_index(facing))
	# Knockback too — otherwise a hit landed after turning shoves the target
	# in the direction you were facing when the swing started.
	knockback_direction = facing

func _activate() -> void:
	_active = true
	monitoring = true
	monitorable = true

## Ends the swing immediately and hands the hitbox back to Pools. Safe at
## any point, including from inside a damage callback.
func cancel() -> void:
	if _released:
		return
	_released = true
	_active = false
	set_physics_process(false)
	# Deferred because cancel() is reachable from inside an area_entered
	# callback, where Area2D refuses direct monitoring changes and removal.
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	_return_to_pool.call_deferred()

func _return_to_pool() -> void:
	var parent := get_parent()
	if parent:
		parent.remove_child(self)
	Pools.release(self)

func get_knockback_direction() -> Vector2:
	return knockback_direction.normalized()

func _on_area_entered(area: Area2D) -> void:
	if not _active:
		return
	# One hit per target per swing, however many times it enters.
	var id := area.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = true
	var hurtbox := area as Hurtbox
	if hurtbox:
		# Rolled per target rather than per swing, so one swing into a cluster
		# can stagger some of them and not others.
		var stun := randf() < hitstun_chance
		var knock := randf() < knockback_chance
		hurtbox.receive_damage(damage, self, stun, knock)
