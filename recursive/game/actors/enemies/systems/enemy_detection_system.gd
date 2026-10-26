class_name EnemyDetectionSystem

extends Area2D

## Walls and closed doors block sight; low obstacles don't.
const SIGHT_BLOCKERS := 1

#data injected from Enemy._ready()
var data: EnemyData
var body: Enemy

#defaults player ref to null(empty)
var player: CharacterBody2D = null

var attack_range: float
var forget_delay: float
var max_range_sq: float

# Offset of the detection shape, read from the scene. The range check measures
# from wherever the shape is tuned to sit, so the two can't drift apart.
var _shape_offset := Vector2.ZERO

var _player_inside := false
var _forget_timer := 0.0

func initialize(data_ref: EnemyData, body_ref: Enemy) -> void:
	data = data_ref
	body = body_ref
	
	attack_range = body.attack_range
	forget_delay = body.target_forget_delay
	
	max_range_sq = attack_range * attack_range

func _ready() -> void:
	#connects _on_body_entered func to body_entered Area2D func
	body_entered.connect(_on_body_entered)
	#connects _on_body_exited func to body_exited Area2D func
	body_exited.connect(_on_body_exited)
	
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		push_warning("%s: no CollisionShape2D — range will measure from the body origin." % name)
	else:
		_shape_offset = shape_node.position

## The one point detection is measured from: the centre of the detection
## shape. Entry already used it (the shape IS the trigger); the range check
## used the body origin instead. Now they agree.
func detection_anchor() -> Vector2:
	return to_global(_shape_offset)

func update(delta: float) -> void:
	if not is_instance_valid(player):
		clear_target()
		return
	
	# Hysteresis: leaving the shape starts a countdown rather than dropping
	# aggro instantly.
	if not _player_inside:
		_forget_timer -= delta
		if _forget_timer <= 0.0:
			clear_target()
			return
	
	data.player_pos = player.global_position
	data.player_anchor = _player_anchor()
	data.has_line_of_sight = _can_see(data.player_anchor)
	update_attack_range()

# Parameter renamed from `body` — the original shadowed the member above it,
# so inside this function `body` meant the player, not the enemy.
func _on_body_entered(entered: Node) -> void:
	#if player enters detection area then
	if entered.is_in_group(&"player"):
		player = entered as CharacterBody2D
		_player_inside = true
		data.player_detected = true
		data.has_last_seen = false

func _on_body_exited(exited: Node) -> void:
	#if player leaves the detection area, start forgetting
	if exited == player:
		_player_inside = false
		_forget_timer = forget_delay

func has_player() -> bool:
	return is_instance_valid(player)

func clear_target() -> void:
	# Losing the player leaves behind where they were last known to be, so
	# the enemy goes to look instead of forgetting on the spot.
	if is_instance_valid(player) and data.player_detected:
		data.has_last_seen = true
		data.last_seen_pos = data.player_pos
	player = null
	_player_inside = false
	data.player_detected = false
	data.in_attack_range = false
	data.has_line_of_sight = false

func update_attack_range() -> void:
	# Anchor to anchor. Measuring our torso against the player's feet made the
	# 31px shape offset eat most of the range budget on the horizontal axis.
	data.in_attack_range = detection_anchor().distance_squared_to(data.player_anchor) <= max_range_sq

func _can_see(point: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(detection_anchor(), point, SIGHT_BLOCKERS)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _player_anchor() -> Vector2:
	if player.has_method("combat_anchor"):
		return player.combat_anchor()
	return player.global_position
