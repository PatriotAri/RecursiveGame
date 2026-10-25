class_name PlayerSpellSystem

## Which spells the player can cast right now, which one is selected, and
## their cooldowns. Spells come from whatever EnchantedEquippableItem is in
## the weapon slot. Casting itself goes through PlayerAttackSystem like any
## other attack; this only decides whether a cast request is allowed through.

## Emitted when the castable set or the selection changes, for the HUD.
signal spells_changed

var player: CharacterBody2D

var _spells: Array[Spell] = []
var _selected := 0
var _cooldowns: Dictionary = {}  # Spell.id -> seconds left

func _init(player_ref: CharacterBody2D) -> void:
	player = player_ref

## Rebuilds the castable set from the equipped weapon. Called by
## PlayerEquipmentSystem after every equipment change.
func refresh(data: PlayerData) -> void:
	var weapon := data.equipment.get_item(EquippableItem.Slot.WEAPON) as EnchantedEquippableItem
	_spells.clear()
	if weapon:
		for spell in weapon.spells:
			if spell == null or spell.attack == null:
				push_warning("%s has a spell slot with no spell or no attack." % weapon.id)
				continue
			_spells.append(spell)
			player.player_hitbox_manager.register_attack(spell.attack_name(), spell.attack)
	_selected = clampi(_selected, 0, maxi(_spells.size() - 1, 0))
	_sync(data)

func update(data: PlayerData, delta: float) -> void:
	# Cooldowns tick whether or not the staff is held, so swapping weapons
	# can't be used to reset one.
	for id in _cooldowns.keys():
		_cooldowns[id] = maxf(_cooldowns[id] - delta, 0.0)
	
	if data.cycle_spell_requested and _spells.size() > 1:
		_selected = (_selected + 1) % _spells.size()
		_sync(data)
	
	# Refused here, before PlayerAttackSystem sees it, for the same reason
	# player.gd refuses an unaffordable swing: so nothing plays for free.
	if data.cast_requested and not can_cast():
		data.cast_requested = false

func can_cast() -> bool:
	var spell := selected_spell()
	return spell != null and cooldown_left(spell) <= 0.0

## Called by player.gd on the frame an attack actually starts.
func on_attack_started(attack_name: StringName) -> void:
	for spell in _spells:
		if spell.attack_name() == attack_name:
			_cooldowns[spell.id] = spell.cooldown
			return

func selected_spell() -> Spell:
	if _spells.is_empty(): return null
	return _spells[_selected]

func get_spells() -> Array[Spell]:
	return _spells

func cooldown_left(spell: Spell) -> float:
	return _cooldowns.get(spell.id, 0.0)

func _sync(data: PlayerData) -> void:
	var spell := selected_spell()
	data.current_spell_attack = spell.attack_name() if spell else &""
	spells_changed.emit()
