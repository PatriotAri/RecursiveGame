class_name PlayerHitboxManager

extends RefCounted

var player: CharacterBody2D
var data: PlayerData

var active_hitboxes: Array[HitboxBase] = []

var hitbox_registry: Dictionary = {}

func _init(player_ref: CharacterBody2D,data_ref: PlayerData) -> void:
	player = player_ref
	data = data_ref

func register_hitbox(attack_name: StringName, scene: PackedScene) -> void:
	hitbox_registry[attack_name] = scene

func spawn_hitbox(attack_name: StringName) -> HitboxBase:
	var scene: PackedScene = hitbox_registry.get(attack_name)
	if scene == null:
		push_warning("No hitbox registered for: %s" % attack_name)
		return null
		
	var hitbox: HitboxBase = scene.instantiate()
	var offset = get_directional_offset(attack_name)
	
	hitbox.position = offset
	hitbox.knockback_direction = data.facing_dir
	player.add_child(hitbox)
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
	var dir_str:= FacingHelper.facing_to_string(data.facing_dir)
	var offset_distance:= 20.0
	
	match dir_str:
		"right": return Vector2(offset_distance, offset_distance)
		"left": return Vector2(-offset_distance, offset_distance)
		"up": return Vector2(offset_distance, -offset_distance)
		"down": return Vector2(offset_distance, offset_distance)
		"up_right": return Vector2(offset_distance, -offset_distance) * 0.707
		"up_left": return Vector2(-offset_distance, -offset_distance) * 0.707
		"down_right": return Vector2(offset_distance, offset_distance) * 0.707
		"down_left": return Vector2(-offset_distance, offset_distance) * 0.707
		_: return Vector2.ZERO
