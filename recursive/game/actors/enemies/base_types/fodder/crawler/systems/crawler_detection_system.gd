class_name CrawlerDetectionSystem

extends Area2D

#data injected from crawler.gd _ready(), 
#so data can be called without writing as a parameter in functions
var data: EnemyData

#defaults player ref to null(empty)
var player: CharacterBody2D = null

#attacks when player enters range "max_range"
var max_range:= 40
var max_range_sq: float

func initialize(data_ref: EnemyData) -> void:
	data = data_ref
	max_range_sq = max_range * max_range

func _ready() -> void:
	#connects _on_body_entered func to body_entered Area2D func
	body_entered.connect(_on_body_entered)
	#connects _on_body_exited func to body_exited Area2D func
	body_exited.connect(_on_body_exited)
	
func update() -> void:
	if not has_player():
		data.in_attack_range = false
		return
	
	data.player_pos = player.global_position
	update_attack_range()

func _on_body_entered(body: Node) -> void:
	#if player enters detection area then
	if body.is_in_group("Player"):
		#recasts body as CharacterBody2D
		player = body as CharacterBody2D
		data.player_detected = true

func _on_body_exited(body: Node) -> void:
	#if player exits detection area then
	if body == player:
		player = null
		data.player_detected = false
		data.in_attack_range = false

func has_player() -> bool:
	return player != null

func update_attack_range() -> void:
	data.in_attack_range = global_position.distance_squared_to(data.player_pos) <= max_range_sq
