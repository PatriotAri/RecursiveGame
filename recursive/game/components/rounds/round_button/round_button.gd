class_name RoundButton

extends Node2D

## Starts the map's next round when used. Shows what's going on in its
## prompt, and greys out while a round is running or once they're all done.

@export var idle_texture: Texture2D
@export var pressed_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var interactable: Interactable = $Interactable

var rounds: RoundManager

func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	_connect.call_deferred()

func _connect() -> void:
	var map := Map.of(self)
	rounds = map.get_round_manager() if map else null
	if rounds == null:
		push_warning("%s: no RoundManager in this map." % name)
		interactable.enabled = false
		return
	rounds.round_started.connect(func(_n): _refresh())
	rounds.round_completed.connect(func(_n): _refresh())
	_refresh()

func _on_interacted(_player: Node) -> void:
	if rounds: rounds.start_round()

func _refresh() -> void:
	var can := rounds.can_start()
	interactable.enabled = can
	sprite.texture = idle_texture if can else pressed_texture
	if can:
		interactable.set_prompt("Start Round %d" % (rounds.current_round + 1))
