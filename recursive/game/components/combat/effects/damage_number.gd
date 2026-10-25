class_name DamageNumber

extends Node2D

## A number that pops up off a hit, drifts upward and fades. Spawn with
## DamageNumber.spawn(); it frees itself.

const RISE := 18.0
const LIFETIME := 0.6

var _label: Label

static func spawn(parent: Node, at: Vector2, amount: int, color: Color) -> void:
	if parent == null or amount <= 0: return
	var number := DamageNumber.new()
	number.z_index = 50
	parent.add_child(number)
	number.global_position = at + Vector2(randf_range(-6, 6), 0)
	number._show(amount, color)

func _show(amount: int, color: Color) -> void:
	_label = Label.new()
	_label.text = str(amount)
	_label.add_theme_font_size_override(&"font_size", 12)
	_label.add_theme_color_override(&"font_color", color)
	_label.add_theme_constant_override(&"outline_size", 4)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	add_child(_label)
	_label.reset_size()
	_label.position = -_label.size * 0.5
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - RISE, LIFETIME).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME).set_delay(LIFETIME * 0.4)
	tween.chain().tween_callback(queue_free)
