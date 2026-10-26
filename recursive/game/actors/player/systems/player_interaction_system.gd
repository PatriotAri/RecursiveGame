class_name PlayerInteractionSystem

var player: CharacterBody2D

var _in_range: Array[Interactable] = []
var _focused: Interactable

func _init(player_ref: CharacterBody2D) -> void:
	player = player_ref

func add(interactable: Interactable) -> void:
	if not _in_range.has(interactable):
		_in_range.append(interactable)

func remove(interactable: Interactable) -> void:
	_in_range.erase(interactable)
	if interactable == _focused:
		interactable.show_prompt(false)
		_focused = null

func update(data: PlayerData) -> void:
	# An interactable can leave the tree without a body_exited — its level
	# set aside while the player is on the airship, say — so stale entries
	# are dropped here.
	_in_range = _in_range.filter(func(i: Interactable) -> bool:
		return is_instance_valid(i) and i.is_inside_tree())
	var nearest := _nearest_enabled()
	if nearest != _focused:
		if is_instance_valid(_focused):
			_focused.show_prompt(false)
		_focused = nearest
	if _focused:
		# Re-shown every frame, so a prompt whose text or enabled state
		# changed while focused stays correct.
		_focused.show_prompt(not data.is_dead)
	if data.interact_requested and _focused and not data.is_dead:
		_focused.interact(player)

func _nearest_enabled() -> Interactable:
	var best: Interactable = null
	var best_distance := INF
	for interactable in _in_range:
		if not interactable.enabled: continue
		var distance := player.global_position.distance_squared_to(interactable.global_position)
		if distance < best_distance:
			best_distance = distance
			best = interactable
	return best
