class_name Stat

## A pool like health, stamina or mana. Values keep their fractions, so
## percent armour can take 16% off a 3-damage hit and the bar shows exactly
## what was lost. Regen and drain run continuously rather than in whole steps.

signal changed(new_value: float, new_maximum: float)
signal emptied
signal filled

## Values this close to empty or full count as there, so a long run of
## fractional changes can't leave 0.0000001 health keeping someone alive.
const SNAP := 0.0001

var current: float
var maximum: float
var regen_per_second: float
var regen_delay: float          # seconds of regen pause after a loss

var _blocked_for: float = 0.0

func _init(max_value: float, regen_rate: float = 0.0, delay_after_loss: float = 0.0) -> void:
	maximum = maxf(max_value, 1.0)
	current = maximum
	regen_per_second = regen_rate
	regen_delay = delay_after_loss

func is_empty() -> bool:
	return current <= 0.0

func is_full() -> bool:
	return current >= maximum

func ratio() -> float:
	return current / maximum

func add(amount: float) -> void:
	if amount <= 0.0: return
	_apply(current + amount)

func remove(amount: float) -> void:
	if amount <= 0.0: return
	_blocked_for = regen_delay
	_apply(current - amount)

func fill() -> void:
	_apply(maximum)

func empty() -> void:
	_apply(0.0)

func set_maximum(value: float, keep_ratio: bool = false) -> void:
	var old_ratio := ratio()
	maximum = maxf(value, 1.0)
	var target := old_ratio * maximum if keep_ratio else current
	current = clampf(target, 0.0, maximum)
	changed.emit(current, maximum)

func tick(delta: float) -> void:
	if _blocked_for > 0.0:
		_blocked_for -= delta
		return
	if regen_per_second <= 0.0 or is_full():
		return
	add(regen_per_second * delta)

func _apply(value: float) -> void:
	var clamped := clampf(value, 0.0, maximum)
	if clamped < SNAP:
		clamped = 0.0
	elif clamped > maximum - SNAP:
		clamped = maximum
	if clamped == current: return
	current = clamped
	changed.emit(current, maximum)
	if current == 0.0:
		emptied.emit()
	elif current == maximum:
		filled.emit()

func can_afford(amount: float) -> bool:
	return current >= amount

# Spends `rate` points per second. Re-arms the regen block on every call, so
# an in-progress drain can never be out-raced by tick() no matter how rate and
# regen_delay compare.
func drain(rate: float, delta: float) -> void:
	if rate <= 0.0: return
	_blocked_for = regen_delay
	_apply(current - rate * delta)
