extends Node2D
## Spawn/despawn cost: fresh instance + free vs Pools. Not a pass/fail test.
const N := 3000
func _ready() -> void:
	for path in ["res://game/actors/player/hitboxes/sword_hitbox.tscn", "res://game/items/equipment/weapons/tier_1/throwing_dagger/throwing_dagger_projectile.tscn", "res://game/spells/fireball/fireball_projectile.tscn"]:
		if not ResourceLoader.exists(path): print("missing ", path); continue
		var scene: PackedScene = load(path)
		var t := Time.get_ticks_usec()
		for i in N:
			var n := scene.instantiate()
			n.damage = 1.0; n.lifetime = 1.0
			add_child(n); remove_child(n); n.free()
		var fresh := (Time.get_ticks_usec() - t) / float(N)
		t = Time.get_ticks_usec()
		for i in N:
			var n := Pools.acquire(scene)
			n.damage = 1.0; n.lifetime = 1.0; n.reset()
			add_child(n); remove_child(n); Pools.release(n)
		var pooled := (Time.get_ticks_usec() - t) / float(N)
		print("%s fresh %.1f us  pooled %.1f us" % [path.get_file(), fresh, pooled])
	var t2 := Time.get_ticks_usec()
	for i in N:
		var d := DamageNumber.new(); add_child(d); remove_child(d); d.free()
	print("DamageNumber fresh %.1f us" % ((Time.get_ticks_usec() - t2) / float(N)))
	t2 = Time.get_ticks_usec()
	for i in N:
		var s := HitSpark.new(); add_child(s); remove_child(s); s.free()
	print("HitSpark fresh %.1f us (pooled = reuse, ~0)" % ((Time.get_ticks_usec() - t2) / float(N)))
	get_tree().quit()
