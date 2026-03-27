class_name HitboxManagerBase

extends RefCounted

var body: CharacterBody2D
var target_layer: int

var active_hitboxes: Array[HitboxBase] = []
var hitbox_registry: Dictionary = {}

func _init(body_ref: CharacterBody2D, layer: int) -> void:
	body = body_ref
	target_layer = layer

func get_facing() -> Vector2:
	push_warning("HitboxManagerBase.get_facing() not overridden")
	return Vector2.ZERO

func register_hitbox(attack_name: StringName, scene: PackedScene, offsets: HitboxOffsetData) -> void:
	hitbox_registry[attack_name] = {"scene": scene, "offsets": offsets}

func spawn_hitbox(attack_name: StringName, damage: float, knockback_strength: float, windup_time: float, lifetime: float) -> HitboxBase:
	var entry = hitbox_registry.get(attack_name)
	if entry == null:
		push_warning("No hitbox registered for: %s" % attack_name)
		return null

	var facing := get_facing()

	var hitbox: HitboxBase = entry.scene.instantiate()
	var offset = get_directional_offset(attack_name, facing)

	hitbox.position = offset
	hitbox.knockback_direction = facing
	hitbox.knockback_strength = knockback_strength
	hitbox.damage = damage
	hitbox.target_layer = target_layer
	hitbox.windup_time = windup_time
	hitbox.lifetime = lifetime

	body.add_child(hitbox)
	hitbox.begin_attack()

	active_hitboxes.append(hitbox)
	hitbox.tree_exited.connect(on_hitbox_removed.bind(hitbox))

	return hitbox

func get_active_count() -> int:
	return active_hitboxes.size()

func has_active_hitbox(attack_name: StringName) -> bool:
	for hitbox in active_hitboxes:
		if hitbox.name.begins_with(str(attack_name)):
			return true
	return false

func clear_all() -> void:
	for hitbox in active_hitboxes:
		if is_instance_valid(hitbox):
			hitbox.queue_free()
	active_hitboxes.clear()

func on_hitbox_removed(hitbox: HitboxBase) -> void:
	active_hitboxes.erase(hitbox)

func get_directional_offset(attack_name: StringName, facing: Vector2) -> Vector2:
	var entry = hitbox_registry.get(attack_name)
	if entry == null or entry.offsets == null:
		return Vector2.ZERO
	var dir_str := FacingHelper.facing_to_string(facing)
	return entry.offsets.get_offset(dir_str)
