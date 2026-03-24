class_name CrawlerHitboxManager

extends RefCounted

var body: CharacterBody2D
var data: EnemyData

var active_hitboxes: Array[HitboxBase] = []
var hitbox_registry: Dictionary = {}

func _init(body_ref: CharacterBody2D,data_ref: EnemyData) -> void:
	body = body_ref
	data = data_ref

func register_hitbox(attack_name: StringName, scene: PackedScene, offsets: HitboxOffsetData) -> void:
	hitbox_registry[attack_name] = {"scene": scene, "offsets": offsets}

func spawn_hitbox(attack_name: StringName, damage: float, windup_time: float, lifetime: float) -> HitboxBase:
	var entry = hitbox_registry.get(attack_name)
	if entry == null:
		push_warning("No hitbox registered for: %s" % attack_name)
		return null
		
	var hitbox: HitboxBase = entry.scene.instantiate()
	var offset = get_directional_offset(attack_name)
	
	hitbox.position = offset
	hitbox.knockback_direction = data.facing_dir
	hitbox.damage = damage
	hitbox.target_layer = 16
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

func get_directional_offset(attack_name: StringName) -> Vector2:
	var entry = hitbox_registry.get(attack_name)
	if entry == null or entry.offsets == null:
		return Vector2.ZERO
	var dir_str:= FacingHelper.facing_to_string(data.facing_dir)
	return entry.offsets.get_offset(dir_str)
