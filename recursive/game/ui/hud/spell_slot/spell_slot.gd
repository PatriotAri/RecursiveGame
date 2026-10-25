extends HBoxContainer

## The selected spell: its icon, name, and cooldown. Hidden while nothing
## castable is equipped.

@onready var icon: TextureRect = $Icon
@onready var label: Label = $Label

var _spell_system: PlayerSpellSystem

func bind(spell_system: PlayerSpellSystem) -> void:
	if _spell_system and _spell_system.spells_changed.is_connected(_refresh):
		_spell_system.spells_changed.disconnect(_refresh)
	_spell_system = spell_system
	if _spell_system:
		_spell_system.spells_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	var spell := _spell_system.selected_spell() if _spell_system else null
	visible = spell != null
	# Only ticks while there's a cooldown that could need showing.
	set_process(visible)
	if spell == null: return
	icon.texture = spell.icon
	_update_label(spell)

func _process(_delta: float) -> void:
	var spell := _spell_system.selected_spell() if _spell_system else null
	if spell: _update_label(spell)

func _update_label(spell: Spell) -> void:
	var left := _spell_system.cooldown_left(spell)
	var count := _spell_system.get_spells().size()
	var cycle := "  [Q]" if count > 1 else ""
	if left > 0.0:
		label.text = "%s  %.1fs%s" % [spell.display_name, left, cycle]
		label.modulate = Color(1, 1, 1, 0.5)
	else:
		label.text = "%s  (%d mana)%s" % [spell.display_name, spell.attack.mana_cost, cycle]
		label.modulate = Color.WHITE
