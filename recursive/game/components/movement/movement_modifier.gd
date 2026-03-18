class_name MovementModifier

enum Type {
	IMPULSE,
	SPEED_SCALE,
	VELOCITY_OVERRIDE,
}

#mod parameters
var id: StringName #unique name, e.g. &"knockback", &"ice_slow"
var type: Type
var duration: float #total lifetime (-1.0 = infinite, removed manually)
var elapsed: float = 0.0

var impulse_velocity := Vector2.ZERO
var impulse_decay := 0.0   # px/s^2

var speed_scale := 1.0

var override_velocity := Vector2.ZERO

func is_expired() -> bool:
	if duration < 0.0:
		return false
	return elapsed >= duration
	
func update(delta: float) -> void:
	elapsed += delta
	match type:
		Type.IMPULSE:
			impulse_velocity = impulse_velocity.move_toward(Vector2.ZERO, impulse_decay * delta)
			if impulse_velocity.length() < 0.1:
				impulse_velocity = Vector2.ZERO
				elapsed = duration

static func create_impulse(mod_id: StringName, direction: Vector2, strength: float, decay: float) -> MovementModifier:
	var mod:= MovementModifier.new()
	mod.id = mod_id
	mod.type = Type.IMPULSE
	mod.duration = -1.0
	mod.impulse_velocity = direction.normalized() * strength
	mod.impulse_decay = decay
	return mod

static func create_speed_scale(mod_id: StringName, scale: float, duration: float) -> MovementModifier:
	var mod:= MovementModifier.new()
	mod.id = mod_id
	mod.type = Type.SPEED_SCALE
	mod.speed_scale = scale
	mod.duration = duration
	return mod

static func create_velocity_override(mod_id: StringName, velocity: Vector2, duration: float) -> MovementModifier:
	var mod:= MovementModifier.new()
	mod.id = mod_id
	mod.type = Type.VELOCITY_OVERRIDE
	mod.override_velocity = velocity
	mod.duration = duration
	return mod
