class_name Stat

signal changed(new_value: int, new_maximum: int)
signal emptied
signal filled

var current: int
var maximum: int
var regen_per_second: float
var regen_delay: float          # seconds of regen pause after a loss

var _accumulator: float = 0.0   # fractional regen carry
var _blocked_for: float = 0.0

func _init(max_value: int, regen_rate: float = 0.0, delay_after_loss: float = 0.0) -> void:
	maximum = maxi(max_value, 1)
	current = maximum
	regen_per_second = regen_rate
	regen_delay = delay_after_loss

func is_empty() -> bool:
	return current <= 0

func is_full() -> bool:
	return current >= maximum

func ratio() -> float:
	return float(current) / float(maximum)

func add(amount: int) -> void:
	if amount <= 0: return
	_apply(current + amount)

func remove(amount: int) -> void:
	if amount <= 0: return
	_blocked_for = regen_delay
	_apply(current - amount)

func fill() -> void:
	_apply(maximum)

func empty() -> void:
	_apply(0)

func set_maximum(value: int, keep_ratio: bool = false) -> void:
	var old_ratio := ratio()
	maximum = maxi(value, 1)
	var target := int(round(old_ratio * maximum)) if keep_ratio else current
	current = clampi(target, 0, maximum)
	changed.emit(current, maximum)

func tick(delta: float) -> void:
	if _blocked_for > 0.0:
		_blocked_for -= delta
		return
	if regen_per_second <= 0.0 or is_full():
		_accumulator = 0.0
		return
	_accumulator += regen_per_second * delta
	var whole := int(_accumulator)
	if whole > 0:
		_accumulator -= float(whole)
		add(whole)

func _apply(value: int) -> void:
	var clamped := clampi(value, 0, maximum)
	if clamped == current: return
	current = clamped
	changed.emit(current, maximum)
	if current == 0:
		emptied.emit()
	elif current == maximum:
		filled.emit()
