class_name Interactable

extends Area2D

## Something the player can use with the interact key. Add one (with a
## CollisionShape2D child for its reach) to anything usable and connect
## `interacted`, or extend it and override interact().
##
## The player's PlayerInteractionSystem decides which interactable in reach
## is focused — the nearest — and only that one shows its prompt.

signal interacted(player: Node)

## Shown above it while focused, after the key: "[E] Open".
@export var prompt:= "Interact"
@export var enabled:= true
## Where the prompt sits, relative to this node.
@export var prompt_offset:= Vector2(0, -48)

var _label: Label

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # Player
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override(&"font_size", 10)
	_label.add_theme_constant_override(&"outline_size", 4)
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.visible = false
	# Drawn above the Y-sorted world regardless of where the owner sits.
	_label.z_index = 100
	add_child(_label)
	_refresh_label()

func can_interact(_player: Node) -> bool:
	return enabled

func interact(player: Node) -> void:
	if not can_interact(player): return
	interacted.emit(player)

## Called by the player's interaction system when this becomes, or stops
## being, the one the interact key would use.
func set_focused(focused: bool) -> void:
	_label.visible = focused
	if focused: _refresh_label()

func set_prompt(text: String) -> void:
	prompt = text
	_refresh_label()

func _refresh_label() -> void:
	if _label == null: return
	_label.text = "[E] " + prompt
	# Centred on prompt_offset. size is only known after the text is set.
	_label.reset_size()
	_label.position = prompt_offset - Vector2(_label.size.x * 0.5, _label.size.y)

func _on_body_entered(body: Node) -> void:
	if body.has_method("register_interactable"):
		body.register_interactable(self)

func _on_body_exited(body: Node) -> void:
	if body.has_method("unregister_interactable"):
		body.unregister_interactable(self)
