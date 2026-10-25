class_name DamageNumber

extends Node2D

## A number that pops up off a hit, drifts upward and fades. Pooled by the
## Effects autoload — show_number() reuses the same node every time.

signal done(number: DamageNumber)

const RISE := 18.0
const LIFETIME := 0.6

var _label: Label
var _tween: Tween

func _init() -> void:
	_label = Label.new()
	_label.add_theme_font_size_override(&"font_size", 12)
	_label.add_theme_constant_override(&"outline_size", 4)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	add_child(_label)

func show_number(at: Vector2, amount: int, color: Color) -> void:
	_label.text = str(amount)
	_label.add_theme_color_override(&"font_color", color)
	_label.reset_size()
	_label.position = -_label.size * 0.5
	global_position = at + Vector2(randf_range(-6, 6), 0)
	modulate.a = 1.0
	visible = true
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "position:y", position.y - RISE, LIFETIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "modulate:a", 0.0, LIFETIME).set_delay(LIFETIME * 0.4)
	_tween.chain().tween_callback(func(): done.emit(self))
