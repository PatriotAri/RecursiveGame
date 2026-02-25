extends Area2D

var damage:= 5.0
var windup_time:= 0.1
var lifetime:= 0.2
var knockback: Vector2 = Vector2.ZERO
var target_layer:= 0

func _ready() -> void:
	get_target_layer()
	attack_delay()
	
	#connect collision signals
	area_entered.connect(_on_area_entered)
	
func _on_area_entered(area: Area2D) -> void:
	#checks for method "receive_damage" in invaded Area2D hitbox, applies damage
	if area.has_method("receive_damage"):
		area.receive_damage(damage, self)

func attack_lifetime() -> void:
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func attack_delay() -> void:
	# Start disabled
	monitoring = false
	monitorable = false
	
	# Wait for windup
	await get_tree().create_timer(windup_time).timeout
	
	# Now activate
	monitoring = true
	monitorable = true
	
	attack_lifetime()
	
func get_target_layer() -> void:
	# NEW: Set collision mask if target_layer is specified
	if target_layer > 0:
		collision_mask = target_layer
