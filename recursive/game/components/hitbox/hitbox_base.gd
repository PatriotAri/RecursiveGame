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

var _elapsed:= 0.0
var _active:= false
var _hit_ids:= {}

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

# Starts the windup clock. Ticked rather than awaited: an awaited timer
# resumes on a freed instance if the swing is cancelled mid-windup. A tick
# just stops, and can be cancelled on demand.
func begin_attack() -> void:
	_elapsed = 0.0
	_active = false
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	_elapsed += delta
	if not _active:
		if _elapsed >= windup_time:
			_activate()
		return
	if _elapsed >= windup_time + lifetime:
		cancel()

func _activate() -> void:
	_active = true
	monitoring = true
	monitorable = true

## Ends the swing immediately. Safe at any point, including from inside a
## damage callback.
func cancel() -> void:
	if is_queued_for_deletion():
		return
	_active = false
	set_physics_process(false)
	# Deferred because cancel() is reachable from inside an area_entered
	# callback, where Area2D refuses direct monitoring changes.
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()

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
	if area.has_method("receive_damage"):
		# Rolled per target rather than per swing, so one swing into a cluster
		# can stagger some of them and not others.
		var stun := randf() < hitstun_chance
		var knock := randf() < knockback_chance
		area.receive_damage(damage, self, stun, knock)
