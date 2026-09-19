class_name CrawlerDetectionSystem

extends Area2D

#data injected from crawler.gd _ready(), 
var data: EnemyData
var body: CharacterBody2D

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

func initialize(data_ref: EnemyData, body_ref: CharacterBody2D) -> void:
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
	update_attack_range()

# Parameter renamed from `body` — the original shadowed the member above it,
# so inside this function `body` meant the player, not the crawler.
func _on_body_entered(entered: Node) -> void:
	#if player enters detection area then
	if entered.is_in_group(&"player"):
		player = entered as CharacterBody2D
		_player_inside = true
		data.player_detected = true

func _on_body_exited(exited: Node) -> void:
	#if player leaves the detection area, start forgetting
	if exited == player:
		_player_inside = false
		_forget_timer = forget_delay

func has_player() -> bool:
	return is_instance_valid(player)

func clear_target() -> void:
	player = null
	_player_inside = false
	data.player_detected = false
	data.in_attack_range = false

func update_attack_range() -> void:
	# Anchor to anchor. Measuring our torso against the player's feet made the
	# 31px shape offset eat most of the range budget on the horizontal axis.
	data.in_attack_range = detection_anchor().distance_squared_to(data.player_anchor) <= max_range_sq

func _player_anchor() -> Vector2:
	if player.has_method("combat_anchor"):
		return player.combat_anchor()
	return player.global_position
