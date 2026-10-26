class_name DropTable

extends Resource

@export var entries: Array[DropEntry] = []

## Each entry rolls independently — a kill can drop everything or nothing.
func roll(parent: Node, at: Vector2) -> void:
	var dropped := false
	for entry in entries:
		if entry.scene == null: continue
		if randf() >= entry.chance: continue
		var drop := entry.scene.instantiate()
		drop.amount = randi_range(entry.min_amount, entry.max_amount)
		drop.global_position = at
		parent.add_child(drop)
		dropped = true
	# One sound for the whole drop, however many items came out.
	if dropped:
		Sfx.play(Sfx.item_drop, at)
