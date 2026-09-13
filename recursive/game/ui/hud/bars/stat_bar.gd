extends Control

@export var fill_color: Color = Color(0.95, 0.01, 0.01)
@export var drain_speed: float = 1.5       # ratio units per second
@export var empty_from_right: bool = true  # false = empty space opens on the left

@onready var fill: ColorRect = $Fill

var _stat: Stat
var _display_ratio: float = 1.0
var _target_ratio: float = 1.0

func _ready() -> void:
	fill.color = fill_color
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
	_display_ratio = _stat.ratio()
	_target_ratio = _display_ratio
	_redraw()

func _on_stat_changed(new_value: int, new_maximum: int) -> void:
	_target_ratio = float(new_value) / float(new_maximum)
	set_process(true)

func _process(delta: float) -> void:
	_display_ratio = move_toward(_display_ratio, _target_ratio, drain_speed * delta)
	_redraw()
	if is_equal_approx(_display_ratio, _target_ratio):
		set_process(false)

func _redraw() -> void:
	if empty_from_right:
		fill.anchor_left = 0.0
		fill.anchor_right = _display_ratio
	else:
		fill.anchor_left = 1.0 - _display_ratio
		fill.anchor_right = 1.0
