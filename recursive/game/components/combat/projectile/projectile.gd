class_name Projectile

extends HitboxBase

## A hitbox that leaves its owner. Damage, knockback, target layers and the
## one-hit-per-target rule all come from HitboxBase; this adds flight.
##
## Lifecycle, driven by the same windup clock as a melee hitbox:
##   windup — rides along with the thrower, invisible and harmless, re-aimed
##            at their facing every frame;
##   launch — at the end of windup, locks its direction and flies;
##   impact — on a target (until pierce runs out), a wall, or max range.
##
## Spawned by HitboxManagerBase, which parents it to the thrower's parent
## rather than the thrower, so it doesn't drag along behind them.

## Emitted once, wherever the projectile stops for any reason except cancel().
signal impacted(at: Vector2)

const LAYER_ENVIRONMENT := 1   # layer 1, from project.godot [layer_names]

var speed:= 300.0
var max_distance:= 300.0
## How many targets it passes through before stopping. 0 = stops on the first.
var pierce:= 0
var hits_walls:= true
## Played where it lands. Null is silent.
var impact_sound: SoundEffect
## Points the art the way it flies. 0 means the art points right; art drawn
## pointing up wants 90.
@export_range(-180.0, 180.0) var art_angle_degrees:= 90.0

## The actor that threw it. Only read during windup.
var thrower: Node2D

var _direction:= Vector2.RIGHT
var _travelled:= 0.0
var _launched:= false
var _hits_left:= 0

func _ready() -> void:
	super()
	body_entered.connect(_on_body_entered)
	# Hidden until it actually leaves the hand — during windup it would just
	# be a dagger floating in front of the thrower.
	visible = false

## Called by the manager before begin_attack().
func configure_flight(flight_speed: float, distance: float, pierce_count: int, sound: SoundEffect) -> void:
	speed = flight_speed
	max_distance = distance
	pierce = pierce_count
	impact_sound = sound

func get_target_layer() -> void:
	super()
	if hits_walls:
		collision_mask |= LAYER_ENVIRONMENT

func is_launched() -> bool:
	return _launched

func _physics_process(delta: float) -> void:
	if not _launched:
		_elapsed += delta
		_follow_thrower()
		if _elapsed >= windup_time:
			_launch()
		return

	var step := speed * delta
	global_position += _direction * step
	_travelled += step
	if _travelled >= max_distance:
		_impact()

func _follow_thrower() -> void:
	if not is_instance_valid(thrower):
		# Thrower died mid-windup. Nothing to throw from.
		cancel()
		return
	var facing := _current_facing()
	var offset := offsets.get_offset(FacingHelper.facing_to_string(facing)) if offsets else Vector2.ZERO
	global_position = thrower.global_position + offset

func _current_facing() -> Vector2:
	if facing_provider.is_valid():
		var facing: Vector2 = facing_provider.call()
		if facing != Vector2.ZERO:
			return facing.normalized()
	return _direction

func _launch() -> void:
	_launched = true
	_direction = _current_facing()
	knockback_direction = _direction
	rotation = _direction.angle() + deg_to_rad(art_angle_degrees)
	_hits_left = pierce
	visible = true
	_activate()

func _on_area_entered(area: Area2D) -> void:
	var already_hit := _hit_ids.has(area.get_instance_id())
	super(area)
	if not _active or already_hit:
		return
	if not (area is Hurtbox):
		return
	if _hits_left <= 0:
		_impact()
	else:
		_hits_left -= 1

func _on_body_entered(_body: Node) -> void:
	if not _active: return
	_impact()

func _impact() -> void:
	if is_queued_for_deletion(): return
	AudioManager.play_sfx(impact_sound, global_position)
	impacted.emit(global_position)
	_on_impact()
	cancel()

## Override for anything that should happen where it lands — an explosion,
## a dropped item. Called before the projectile frees itself.
func _on_impact() -> void:
	pass
