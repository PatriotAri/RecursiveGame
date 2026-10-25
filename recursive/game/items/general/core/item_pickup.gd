extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

@export var item: Item
@export var amount: int = 1
@export var pickup_sound: SoundEffect = preload("res://game/audio/sfx/pickup.tres")
## Idle bob, in pixels. 0 holds it still.
@export var bob_height:= 2.0

var _bob_time:= randf() * TAU
var _sprite_rest:= Vector2.ZERO

func _ready() -> void:
	if item == null:
		push_error("%s: no item assigned; pickup disabled." % name)
		set_deferred("monitoring", false)
		return
	# The pickup's look comes from the item, so a new item needs no new scene.
	sprite.texture = item.icon
	_sprite_rest = sprite.position
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_bob_time += delta * 3.0
	sprite.position = _sprite_rest + Vector2(0, sin(_bob_time) * bob_height)

## A soft shadow under the bob, so a floating item still reads as sitting
## on the ground.
func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 8.0, Color(0, 0, 0, 0.3))

func _on_body_entered(body: Node) -> void:
	var player := body as Player
	if player == null:
		return
	player.data.inventory.add(item, amount)
	AudioManager.play_sfx(pickup_sound, global_position)
	set_deferred("monitoring", false)
	queue_free()
