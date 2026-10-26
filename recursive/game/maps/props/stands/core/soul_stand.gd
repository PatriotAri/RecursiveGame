class_name SoulStand

extends Stand

## Raises max health, stamina and mana for souls, a step at a time, each step
## dearer than the last. The steps, prices and caps are the SoulUpgrades
## below. Rules: PlayerUpgradeSystem.

@export var upgrades: Array[SoulUpgrade] = []
@export var buy_sound: SoundEffect

func list_rows(player: Node, selected: Variant) -> Array[StandRow]:
	var rows: Array[StandRow] = []
	var progress: PlayerUpgradeSystem = player.player_upgrade_system
	for upgrade in upgrades:
		var row := StandRow.make("%s   %d/%d" % [upgrade.display_name, progress.purchases(player.data, upgrade),
			upgrade.max_purchases], func() -> Variant: return upgrade)
		row.selected = upgrade == selected
		rows.append(row)
	return rows

func detail(player: Node, selected: Variant) -> StandDetail:
	var upgrade := selected as SoulUpgrade
	if upgrade == null: return null
	var progress: PlayerUpgradeSystem = player.player_upgrade_system
	var info := StandDetail.new()
	info.title = upgrade.display_name
	var bought := progress.purchases(player.data, upgrade)
	info.text = "Now %s. Bought %d of %d." % [_current(player, upgrade), bought, upgrade.max_purchases]
	var cost := progress.next_soul_cost(player.data, upgrade)
	var row: StandRow
	if cost < 0:
		row = StandRow.make("Bought out")
	else:
		row = StandRow.make("+%d %s   %d soul%s" % [upgrade.amount, upgrade.display_name.to_lower(), cost,
			"" if cost == 1 else "s"], _buy.bind(player, upgrade))
		if count_of(player, soul_item) < cost:
			row.note = "Not enough souls."
		row.disabled = row.note != ""
	info.rows.append(row)
	return info

## The stat's maximum as it stands, gear included.
func _current(player: Node, upgrade: SoulUpgrade) -> String:
	var stat: Stat
	match upgrade.stat:
		SoulUpgrade.Stat.MAX_HEALTH: stat = player.stats.health
		SoulUpgrade.Stat.MAX_STAMINA: stat = player.stats.stamina
		SoulUpgrade.Stat.MAX_MANA: stat = player.stats.mana
	return String.num(stat.maximum) if stat else "?"

func _buy(player: Node, upgrade: SoulUpgrade) -> Variant:
	if player.player_upgrade_system.buy(player.data, upgrade, soul_item):
		Sfx.play(buy_sound)
	return upgrade
