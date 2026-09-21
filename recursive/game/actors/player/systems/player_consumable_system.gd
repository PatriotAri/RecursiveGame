class_name PlayerConsumableSystem

var player: CharacterBody2D

var _cooldown:= 0.0

func _init(player_ref: CharacterBody2D) -> void:
	player = player_ref

func update(_data: PlayerData, delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)

func can_use(data: PlayerData, item: ConsumableItem) -> bool:
	if item == null: return false
	# Same gates the attack system uses — nothing acts out of hitstun.
	if data.is_dead or data.is_hurt or data.is_attacking: return false
	if _cooldown > 0.0: return false
	if data.inventory.get_count(item.id) <= 0: return false
	return _any_effect_lands(item)

func try_use(data: PlayerData, item: ConsumableItem) -> bool:
	if not can_use(data, item): return false
	# Decrement first. If an effect throws, a failed use can never leave the
	# item in the inventory after its effect already landed.
	if not data.inventory.remove(item.id, 1): return false
	for effect in item.effects:
		effect.apply(player.stats)
	_cooldown = item.cooldown
	return true

## An item with no effects, or whose every effect is already maxed out, is
## refused rather than spent.
func _any_effect_lands(item: ConsumableItem) -> bool:
	for effect in item.effects:
		if effect.would_do_anything(player.stats):
			return true
	return false
