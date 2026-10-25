extends Control

## A framed bar for one Stat. The fill snaps to the new value; a pale "ghost"
## behind it drains down afterwards, so a hit reads as a chunk taken out
## rather than a bar sliding. Heals do the reverse: the ghost leads and the
## fill catches up.

@export var fill_color: Color = Color(0.95, 0.01, 0.01)
@export var ghost_color: Color = Color(1.0, 0.9, 0.6, 0.85)
@export var drain_speed: float = 1.5       # ratio units per second
@export var empty_from_right: bool = true  # false = empty space opens on the left
@export var show_numbers: bool = true

@onready var fill: ColorRect = $Fill
@onready var ghost: ColorRect = $Ghost
@onready var value_label: Label = $Value

var _stat: Stat
## What the fill shows and what the ghost shows; they meet at the target.
var _fill_ratio: float = 1.0
var _ghost_ratio: float = 1.0
var _target_ratio: float = 1.0

func _ready() -> void:
	fill.color = fill_color
	ghost.color = ghost_color
	value_label.visible = show_numbers
	set_process(false)

func bind(stat: Stat) -> void:
	if _stat != null and _stat.changed.is_connected(_on_stat_changed):
		_stat.changed.disconnect(_on_stat_changed)
	_stat = stat
	if _stat == null:
		visible = false
		return
	visible = true
	_stat.changed.connect(_on_stat_changed)
	_target_ratio = _stat.ratio()
	_fill_ratio = _target_ratio
	_ghost_ratio = _target_ratio
	_update_label(_stat.current, _stat.maximum)
	_redraw()

func _on_stat_changed(new_value: int, new_maximum: int) -> void:
	_target_ratio = float(new_value) / float(new_maximum)
	if _target_ratio < _fill_ratio:
		# Loss: the fill drops at once, the ghost stays behind to drain.
		_fill_ratio = _target_ratio
	else:
		# Gain: the ghost jumps ahead to show where the fill is heading.
		_ghost_ratio = _target_ratio
	_update_label(new_value, new_maximum)
	_redraw()
	set_process(true)

func _process(delta: float) -> void:
	_fill_ratio = move_toward(_fill_ratio, _target_ratio, drain_speed * delta)
	_ghost_ratio = move_toward(_ghost_ratio, _target_ratio, drain_speed * delta)
	_redraw()
	if is_equal_approx(_fill_ratio, _target_ratio) and is_equal_approx(_ghost_ratio, _target_ratio):
		set_process(false)

func _update_label(value: int, maximum: int) -> void:
	value_label.text = "%d / %d" % [value, maximum]

func _redraw() -> void:
	_place(fill, _fill_ratio)
	_place(ghost, maxf(_ghost_ratio, _fill_ratio))

func _place(rect: ColorRect, ratio: float) -> void:
	if empty_from_right:
		rect.anchor_left = 0.0
		rect.anchor_right = ratio
	else:
		rect.anchor_left = 1.0 - ratio
		rect.anchor_right = 1.0
