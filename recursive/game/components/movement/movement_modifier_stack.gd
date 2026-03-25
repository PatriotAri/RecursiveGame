class_name MovementModifierStack

var modifiers: Array[MovementModifier] = []

func add(mod: MovementModifier) -> void:
	remove(mod.id)
	modifiers.append(mod)

func remove(id: StringName) -> void:
	for i in range(modifiers.size() -1, -1, -1):
		if modifiers[i].id == id:
			modifiers.remove_at(i)

func has(id: StringName) -> bool:
	for mod in modifiers:
		if mod.id == id:
			return true
	return false

func update(delta: float) -> void:
	for mod in modifiers:
		mod.update(delta)
	# Purge expired — iterate backwards so removals don't skip entries
	for i in range(modifiers.size() -1, -1, -1):
		if modifiers[i].is_expired():
			modifiers.remove_at(i)

func get_impulse_sum() -> Vector2:
	var total := Vector2.ZERO
	for mod in modifiers:
		if mod.type == MovementModifier.Type.IMPULSE:
			total += mod.impulse_velocity
	return total

func get_speed_scale() -> float:
	var total:= 1.0
	for mod in modifiers:
		if mod.type == MovementModifier.Type.SPEED_SCALE:
			total *= mod.speed_scale
	return total

func has_velocity_override() -> bool:
	for mod in modifiers:
		if mod.type == MovementModifier.Type.VELOCITY_OVERRIDE:
			return true
	return false

func get_velocity_override() -> Vector2:
	#last override wins
	for i in range(modifiers.size() -1, -1, -1):
		if modifiers[i].type == MovementModifier.Type.VELOCITY_OVERRIDE:
			return modifiers[i].override_velocity
	return Vector2.INF
