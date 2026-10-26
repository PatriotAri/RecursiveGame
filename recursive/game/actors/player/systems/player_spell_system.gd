class_name PlayerSpellSystem

## Learning, assigning and readying spells. A spell key readies its spell in
## the player's hands. A held melee weapon is put away (stowed) to free them,
## and pressing the same key again puts the spell away and brings the weapon
## back. A staff stays in hand and amplifies whatever is readied. Equipping
## any other weapon puts the spell away.

const SLOT_COUNT := 4

## The readied spell changed; null when one is put away. The HUD listens.
signal readied_changed(spell: Spell)
## Spells were learned or moved between keys. The Spells tab listens.
signal spells_changed
## Research at the tome stand finished: `spell` is now `level`.
signal research_finished(spell: Spell, level: int)

var player: CharacterBody2D
## Played when a spell is readied or put away.
var ready_sound: SoundEffect

func _init(player_ref: CharacterBody2D, ready_sound_ref: SoundEffect) -> void:
	player = player_ref
	ready_sound = ready_sound_ref

## Teaches the tome's spell and uses up the tome. Refused, keeping the tome,
## if the spell is already known.
func learn(data: PlayerData, tome: TomeItem) -> bool:
	if tome == null or tome.spell == null or data.is_dead: return false
	if data.known_spells.has(tome.spell) or data.inventory.get_count(tome.id) <= 0:
		Sfx.play(Sfx.refused)
		return false
	if not data.inventory.remove(tome.id, 1): return false
	data.known_spells.append(tome.spell)
	Sfx.play(tome.use_sound)
	spells_changed.emit()
	return true

## Puts a known spell on key `slot` (0 to 3), replacing whatever was there. A
## spell sits on one key at a time, so moving it clears its old key.
func assign(data: PlayerData, spell: Spell, slot: int) -> void:
	if slot < 0 or slot >= SLOT_COUNT or not data.known_spells.has(spell): return
	for i in SLOT_COUNT:
		if data.spell_slots[i] == spell:
			data.spell_slots[i] = null
	data.spell_slots[slot] = spell
	spells_changed.emit()

## A spell key: readies its spell, or puts it away if it's the one in hand.
## An empty key does nothing.
func press_slot(data: PlayerData, slot: int) -> void:
	if slot < 0 or slot >= SLOT_COUNT: return
	var spell: Spell = data.spell_slots[slot]
	if spell == null: return
	if data.readied_spell == spell:
		put_away(data, true)
	else:
		ready_spell(data, spell)

func ready_spell(data: PlayerData, spell: Spell) -> void:
	if data.is_dead or spell == null or data.readied_spell == spell: return
	var weapon: EquippableItem = data.equipment.get_item(EquippableItem.Slot.WEAPON)
	if weapon and not weapon.casting_focus:
		data.stowed_weapon = weapon
		data.equipment.unequip(EquippableItem.Slot.WEAPON)
	data.readied_spell = spell
	player.player_equipment_system.refresh(data)
	Sfx.play(ready_sound)
	readied_changed.emit(spell)

## Puts the readied spell away. `bring_back_weapon` re-equips the stowed
## weapon, if it's still carried: the spell's own key does that, equipping a
## different weapon doesn't.
func put_away(data: PlayerData, bring_back_weapon: bool) -> void:
	if data.readied_spell == null: return
	data.readied_spell = null
	var weapon := data.stowed_weapon
	data.stowed_weapon = null
	if bring_back_weapon and weapon and data.inventory.get_count(weapon.id) > 0 \
			and data.equipment.get_item(EquippableItem.Slot.WEAPON) == null:
		data.equipment.equip(weapon)
	player.player_equipment_system.refresh(data)
	Sfx.play(ready_sound)
	readied_changed.emit(null)

# --- levels and research ---------------------------------------------------

func level_of(data: PlayerData, spell: Spell) -> int:
	return int(data.spell_levels.get(spell.id, 1))

## What casting `spell` does at the level the player has it.
func attack_for(data: PlayerData, spell: Spell) -> ProjectileAttackSpec:
	return spell.attack_at(level_of(data, spell))

## Why `spell` can't be researched to its next level now, or "" if it can.
## Souls aren't checked here.
func research_block_reason(data: PlayerData, spell: Spell) -> String:
	if not data.known_spells.has(spell):
		return "You don't know %s." % spell.display_name
	if data.researching:
		return "Already researching %s." % data.researching.name_at(level_of(data, data.researching) + 1)
	if level_of(data, spell) >= spell.max_level():
		return "%s is at its highest level." % spell.name_at(level_of(data, spell))
	return ""

## What researching `spell` to its next level costs in souls, or -1 at the top.
func research_cost(data: PlayerData, spell: Spell) -> int:
	var level := level_of(data, spell)
	return spell.levels[level - 1].research_cost if level < spell.max_level() else -1

## Pays for and starts researching `spell`'s next level. It's ready once the
## next round is cleared; see finish_research().
func start_research(data: PlayerData, spell: Spell, souls: Item) -> bool:
	var cost := research_cost(data, spell)
	if data.is_dead or research_block_reason(data, spell) != "" \
			or not (cost <= 0 or data.inventory.remove(souls.id, cost)):
		Sfx.play(Sfx.refused)
		return false
	data.researching = spell
	return true

## Called when a round is cleared: the spell being researched goes up a
## level.
func finish_research(data: PlayerData) -> void:
	var spell := data.researching
	if spell == null: return
	data.researching = null
	var level := level_of(data, spell) + 1
	data.spell_levels[spell.id] = level
	# A readied spell is registered at its old numbers until refreshed.
	if data.readied_spell == spell:
		player.player_equipment_system.refresh(data)
	research_finished.emit(spell, level)
	spells_changed.emit()

## Restores spells from a save, without sounds. Unknown ids are skipped.
func load_save_data(data: PlayerData, saved: Dictionary) -> void:
	for id in saved.get("spells", []):
		var spell := ContentRegistry.get_spell(StringName(id))
		if spell == null:
			push_warning("Save has an unknown spell '%s'; skipped." % id)
		elif not data.known_spells.has(spell):
			data.known_spells.append(spell)
	var slots: Array = saved.get("spell_slots", [])
	for i in mini(slots.size(), SLOT_COUNT):
		var spell := ContentRegistry.get_spell(StringName(slots[i]))
		data.spell_slots[i] = spell if data.known_spells.has(spell) else null
	for id in saved.get("spell_levels", {}):
		data.spell_levels[StringName(id)] = int(saved["spell_levels"][id])
	var researching := ContentRegistry.get_spell(StringName(saved.get("researching", "")))
	data.researching = researching if data.known_spells.has(researching) else null
	# A copy made at a stand is in the inventory, not the registry.
	var stowed := player.resolve_item(StringName(saved.get("stowed_weapon", ""))) as EquippableItem
	var readied := ContentRegistry.get_spell(StringName(saved.get("readied_spell", "")))
	if readied and data.known_spells.has(readied):
		data.readied_spell = readied
		data.stowed_weapon = stowed
		player.player_equipment_system.refresh(data)
		readied_changed.emit(readied)
	spells_changed.emit()

func get_save_data(data: PlayerData) -> Dictionary:
	var slots: Array[String] = []
	for spell in data.spell_slots:
		slots.append(String(spell.id) if spell else "")
	return {
		"spells": data.known_spells.map(func(spell: Spell) -> String: return String(spell.id)),
		"spell_slots": slots,
		"readied_spell": String(data.readied_spell.id) if data.readied_spell else "",
		"stowed_weapon": String(data.stowed_weapon.id) if data.stowed_weapon else "",
		"spell_levels": data.spell_levels.duplicate(),
		"researching": String(data.researching.id) if data.researching else "",
	}
