class_name HitboxManagerBase

extends RefCounted

## Physics layers, from project.godot [layer_names].
const LAYER_PLAYER_HURTBOX := 16   # layer 5
const LAYER_ENEMY_HURTBOX := 32    # layer 6

var body: Actor
var target_layer: int

## Returns the actor's current facing. Supplied by the actor, so this class
## needs no per-actor subclass.
var facing_provider: Callable

var active_hitboxes: Array[HitboxBase] = []
var attack_registry: Dictionary = {}

func _init(body_ref: Actor, layer: int, facing_source: Callable) -> void:
	body = body_ref
	target_layer = layer
	facing_provider = facing_source

func get_facing() -> Vector2:
	if not facing_provider.is_valid():
		push_warning("HitboxManagerBase on %s: no facing provider." % body.name)
		return Vector2.ZERO
	return facing_provider.call()

func register_attack(attack_name: StringName, spec: AttackSpec) -> void:
	if spec == null:
		push_error("register_attack(%s) on %s: spec is null." % [attack_name, body.name])
		return
	if spec.scene == null:
		# Still register it — spawn_hitbox() then fails gracefully instead of
		# reporting the misleading "no attack registered".
		push_error("register_attack(%s) on %s: no scene assigned." % [attack_name, body.name])
	attack_registry[attack_name] = spec

func get_spec(attack_name: StringName) -> AttackSpec:
	return attack_registry.get(attack_name)

func spawn_hitbox(attack_name: StringName) -> HitboxBase:
	var spec: AttackSpec = attack_registry.get(attack_name)
	if spec == null:
		push_warning("No attack registered for: %s" % attack_name)
		return null
	if spec.scene == null:
		push_error("Attack '%s' on %s has no scene assigned." % [attack_name, body.name])
		return null

	var instance := spec.scene.instantiate()
	var hitbox := instance as HitboxBase
	if hitbox == null:
		push_error("Attack '%s' on %s: scene root is not a HitboxBase." % [attack_name, body.name])
		instance.queue_free()
		return null

	var facing := get_facing()

	hitbox.attack_name = attack_name
	hitbox.position = spec.offset_for(facing)
	hitbox.knockback_direction = facing
	hitbox.knockback_strength = spec.knockback_strength
	hitbox.knockback_decay = spec.knockback_decay
	hitbox.hitstun_chance = spec.hitstun_chance
	hitbox.knockback_chance = spec.knockback_chance
	hitbox.damage = spec.damage
	hitbox.target_layer = target_layer
	hitbox.windup_time = spec.windup_time
	hitbox.lifetime = spec.lifetime
	hitbox.offsets = spec.offsets
	hitbox.facing_provider = facing_provider
	
	var projectile := hitbox as Projectile
	if projectile:
		projectile.configure_flight(spec.projectile_speed, spec.projectile_range,
			spec.projectile_pierce, spec.impact_sound)
		projectile.thrower = body
		# World space, beside the thrower rather than under it — a child would
		# be dragged along by every step its thrower takes after letting go.
		body.get_parent().add_child(projectile)
		projectile.global_position = body.global_position + hitbox.position
	else:
		body.add_child(hitbox)
	hitbox.begin_attack()

	active_hitboxes.append(hitbox)
	hitbox.tree_exited.connect(on_hitbox_removed.bind(hitbox))

	return hitbox

func get_active_count() -> int:
	return active_hitboxes.size()

func has_active_hitbox(attack_name: StringName) -> bool:
	for hitbox in active_hitboxes:
		if is_instance_valid(hitbox) and hitbox.attack_name == attack_name:
			return true
	return false

## Kills every in-flight swing. Phase 3 calls this on hitstun, Phase 4 on death.
func cancel_all() -> void:
	# Iterate a copy: cancel() queue_frees, which fires tree_exited, which
	# erases from active_hitboxes.
	for hitbox in active_hitboxes.duplicate():
		if not is_instance_valid(hitbox):
			continue
		# A projectile already in flight has left the hand. Getting hit
		# shouldn't pluck it out of the air.
		if hitbox is Projectile and hitbox.is_launched():
			continue
		hitbox.cancel()
	# Rebuilt rather than cleared: launched projectiles are still in flight
	# and still ours until they land.
	var still_active: Array[HitboxBase] = []
	for hitbox in active_hitboxes:
		if is_instance_valid(hitbox) and not hitbox.is_queued_for_deletion():
			still_active.append(hitbox)
	active_hitboxes = still_active

func on_hitbox_removed(hitbox: HitboxBase) -> void:
	active_hitboxes.erase(hitbox)
