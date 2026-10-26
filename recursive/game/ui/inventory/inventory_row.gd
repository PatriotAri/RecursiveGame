class_name InventoryRow

extends Button

## Pointed at — mouse hover or keyboard focus. Drives the detail panel.
signal hovered(item: Item)
## Left click, or Enter/Space while focused. Uses or equips.
signal activated(item: Item)
## The same two for a row in the Spells tab, which lists spells, not items.
signal spell_hovered(spell: Spell)
signal spell_activated(spell: Spell)

@onready var item_name: Label = $Margin/HBox/ItemName
@onready var count: Label = $Margin/HBox/Count
@onready var equipped_marker: ColorRect = $Margin/HBox/EquippedMarker

var item: Item
var spell: Spell

func _ready() -> void:
	# Button.pressed already fires on left click only — button_mask defaults to
	# the left mouse button — so click-to-use needs no custom input handling.
	# It also fires on Enter/Space while focused, which gives keyboard parity
	# for free.
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_pointed_at)
	focus_entered.connect(_on_pointed_at)

func display(stack: ItemStack, equipped := false) -> void:
	item = stack.item
	item_name.text = stack.item.display_name
	# Faded rather than hidden: a hidden child is skipped entirely by the
	# HBoxContainer, so toggling visibility would shunt every name left and
	# right as things get equipped.
	equipped_marker.modulate = Color(1, 1, 1, 1.0 if equipped else 0.0)
	count.text = str(stack.count)

## A known spell at its level: the key it's on in the count's place, the
## marker if it's the one readied.
func display_spell(spell_ref: Spell, level: int, key: int, readied: bool) -> void:
	spell = spell_ref
	item_name.text = spell.name_at(level)
	equipped_marker.modulate = Color(1, 1, 1, 1.0 if readied else 0.0)
	count.text = "[%d]" % (key + 1) if key >= 0 else ""

func _on_pointed_at() -> void:
	if spell:
		spell_hovered.emit(spell)
	elif item:
		hovered.emit(item)

func _on_pressed() -> void:
	if spell:
		spell_activated.emit(spell)
	elif item:
		activated.emit(item)
