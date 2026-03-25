class_name HitboxBase

extends Area2D

var damage:= 0.0
var windup_time:= 0.0
var lifetime:= 0.0
var target_layer:= 0

var knockback_direction:= Vector2.ZERO
var knockback_strength:= 0.0
var knockback_decay:= 800.0 #px/s^2

func _ready() -> void:
	if damage <= 0.0:
		push_warning("%s: damage is %.1f - was it set?" % [name, damage])
	if lifetime <= 0.0:
		push_warning("%s: lifetime is %.1f — was it set?" % [name, lifetime])
	get_target_layer()
	area_entered.connect(_on_area_entered)

func get_target_layer() -> void:
	#set collision mask if target_layer is specified
	if target_layer > 0:
		collision_mask = target_layer

func begin_attack() -> void:
	monitoring = false
	monitorable = false
	await get_tree().create_timer(windup_time, false, true).timeout
	monitoring = true
	monitorable = true
	attack_lifetime()

func attack_lifetime() -> void:
	await get_tree().create_timer(lifetime, false, true).timeout
	queue_free()

func get_knockback_direction() -> Vector2:
	return knockback_direction.normalized()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("receive_damage"):
		area.receive_damage(damage, self)
