class_name PlayerInteractionSystem

## Tracks the interactables in reach and uses the nearest on the interact
## key. Interactables add and remove themselves as the player walks in and
## out of their shapes.

var player: CharacterBody2D

var _in_reach: Array[Interactable] = []
var _focused: Interactable

func _init(player_ref: CharacterBody2D) -> void:
	player = player_ref

func register(interactable: Interactable) -> void:
	if not _in_reach.has(interactable):
		_in_reach.append(interactable)

func unregister(interactable: Interactable) -> void:
	_in_reach.erase(interactable)
	if _focused == interactable:
		_set_focus(null)

func update(data: PlayerData) -> void:
	_set_focus(_nearest())
	if data.interact_requested and _focused != null and not data.is_dead:
		data.interact_requested = false
		_focused.interact(player)

func focused() -> Interactable:
	return _focused

## Called when the player leaves a map: whatever was in reach there is gone.
func clear() -> void:
	_set_focus(null)
	_in_reach.clear()

func _nearest() -> Interactable:
	var best: Interactable = null
	var best_dist := INF
	for i in range(_in_reach.size() - 1, -1, -1):
		var candidate := _in_reach[i]
		if not is_instance_valid(candidate):
			_in_reach.remove_at(i)
			continue
		if not candidate.can_interact(player):
			continue
		var dist := player.global_position.distance_squared_to(candidate.global_position)
		if dist < best_dist:
			best_dist = dist
			best = candidate
	return best

func _set_focus(interactable: Interactable) -> void:
	if interactable == _focused: return
	if is_instance_valid(_focused):
		_focused.set_focused(false)
	_focused = interactable
	if _focused:
		_focused.set_focused(true)
