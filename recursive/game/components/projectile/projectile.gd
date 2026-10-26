class_name Projectile

extends HitboxBase

## A thrown or fired attack. Through the windup it's held like a swing, a
## hidden child of its thrower that a stagger can still cancel. At release it
## leaves for the world: it's reparented beside the thrower, which also takes
## it off the hitbox manager's list (leaving the tree fires tree_exited), so
## nothing that happens to the thrower afterwards can touch it. It then flies
## straight at the aim point until it hits a wall, runs out of range, or has
## hit as many targets as it can.

## Walls stop it. Low obstacles don't: it flies over them.
const LAYER_ENVIRONMENT := 1

var speed := 400.0
## Targets it passes through after the first.
var pierce := 0
## Where it leaves from, relative to the thrower's feet.
var launch_offset := Vector2.ZERO
## Returns the world point it's aimed at. Unset, it flies along the thrower's
## facing.
var aim_provider: Callable

var direction := Vector2.RIGHT
var _hits_left := 1

func _ready() -> void:
	super()
	# In the hand until release; the hand already shows the weapon.
	visible = false
	body_entered.connect(_on_body_entered)

func get_target_layer() -> void:
	super()
	collision_mask |= LAYER_ENVIRONMENT

func _physics_process(delta: float) -> void:
	if _active:
		global_position += direction * speed * delta
	super(delta)

## Held projectiles never follow the thrower's facing; they aim at release.
func _track_facing() -> void:
	pass

func _activate() -> void:
	var thrower := get_parent() as Node2D
	var origin := thrower.global_position + launch_offset
	direction = _aim_direction(origin)
	knockback_direction = direction
	_hits_left = pierce + 1
	reparent(thrower.get_parent())
	global_position = origin
	rotation = direction.angle()
	visible = true
	super()

func _aim_direction(origin: Vector2) -> Vector2:
	if aim_provider.is_valid():
		var to_target: Vector2 = aim_provider.call() - origin
		if to_target.length() > 1.0:
			return to_target.normalized()
	var facing: Vector2 = facing_provider.call() if facing_provider.is_valid() else Vector2.ZERO
	return facing.normalized() if facing != Vector2.ZERO else Vector2.RIGHT

func _on_area_entered(area: Area2D) -> void:
	# Only something that takes damage stops it. Watching the Environment
	# layer for walls also turns up any plain area left on that layer, and
	# those it flies straight through.
	if not _active or _hits_left <= 0 or not area.has_method("receive_damage"):
		return
	var hits_before := _hit_ids.size()
	super(area)
	if _hit_ids.size() > hits_before:
		_hits_left -= 1
		if _hits_left <= 0:
			cancel()

func _on_body_entered(_body: Node2D) -> void:
	if _active:
		cancel()
