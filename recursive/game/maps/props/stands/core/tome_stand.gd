class_name TomeStand

extends Stand

## Researches a known spell's next level for souls. The new level is ready
## once the next round is cleared, and one spell is researched at a time.
## Each spell's levels and their costs are set on the spell. Rules:
## PlayerSpellSystem.

@export var research_sound: SoundEffect

func list_rows(player: Node, selected: Variant) -> Array[StandRow]:
	var rows: Array[StandRow] = []
	var spells: PlayerSpellSystem = player.player_spell_system
	for spell in player.data.known_spells:
		var row := StandRow.make(spell.name_at(spells.level_of(player.data, spell)), func() -> Variant: return spell)
		row.icon = spell.icon
		row.selected = spell == selected
		if player.data.researching == spell:
			row.note = "Researching"
		rows.append(row)
	return rows

func empty_text() -> String:
	return "No spells to research. Tomes teach them."

func detail(player: Node, selected: Variant) -> StandDetail:
	var spell := selected as Spell
	var data: PlayerData = player.data
	if spell == null or not data.known_spells.has(spell): return null
	var spells: PlayerSpellSystem = player.player_spell_system
	var level := spells.level_of(data, spell)
	var info := StandDetail.new()
	info.title = spell.name_at(level)
	info.icon = spell.icon
	var lines := PackedStringArray([spell.description, "", "Now: " + _numbers(spell.attack_at(level))])
	if level < spell.max_level():
		lines.append("%s: %s" % [spell.name_at(level + 1), _numbers(spell.attack_at(level + 1))])
	if data.researching == spell:
		lines.append_array(["", "Researching %s. Ready after your next round." % spell.name_at(level + 1)])
	info.text = "\n".join(lines)
	var cost := spells.research_cost(data, spell)
	var row: StandRow
	if cost < 0:
		row = StandRow.make("Fully researched")
	else:
		row = StandRow.make("Research %s   %d soul%s" % [spell.name_at(level + 1), cost, "" if cost == 1 else "s"],
			_research.bind(player, spell))
		row.note = spells.research_block_reason(data, spell)
		if row.note == "" and count_of(player, soul_item) < cost:
			row.note = "Not enough souls."
		row.disabled = row.note != ""
	info.rows.append(row)
	return info

## "11 damage, 48px blast, 3 mana".
func _numbers(attack: ProjectileAttackSpec) -> String:
	var parts := PackedStringArray(["%s damage" % String.num(attack.damage)])
	if attack.blast_radius > 0.0:
		parts.append("%dpx blast" % roundi(attack.blast_radius))
	parts.append("%d mana" % attack.mana_cost)
	return ", ".join(parts)

func _research(player: Node, spell: Spell) -> Variant:
	if player.player_spell_system.start_research(player.data, spell, soul_item):
		Sfx.play(research_sound)
	return spell
