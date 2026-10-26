class_name Interactable

extends Area2D

## Something the player can use with the interact key: a stand, a door, a
## vendor. Give it a collision shape for its reach and connect to
## `interacted`. When several are in range, the player uses the nearest one,
## and only that one shows its prompt.

signal interacted(player: Node)

## Shown above the object as "<key>  <text>", e.g. "E  Start round".
@export var prompt_text := "Use"
## Disabled interactables can't be used and never show a prompt, e.g. the
## airship ramp during a round.
@export var enabled := true:
	set(value):
		enabled = value
		if not enabled:
			show_prompt(false)
## Where the prompt sits, relative to this node.
@export var prompt_offset := Vector2(0, -48)

var _prompt: Label

func _ready() -> void:
	# Only the player's body matters; nothing needs to detect this area.
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.add_theme_font_size_override(&"font_size", 10)
	_prompt.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override(&"outline_size", 4)
	_prompt.z_index = 10
	_prompt.visible = false
	add_child(_prompt)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func show_prompt(on: bool) -> void:
	if _prompt == null: return
	_prompt.visible = on and enabled
	if _prompt.visible:
		_prompt.text = "%s  %s" % [_key_name(), prompt_text]
		# Centre the label on the offset point once it knows its own size.
		_prompt.reset_size()
		_prompt.position = prompt_offset - Vector2(_prompt.size.x / 2.0, _prompt.size.y)

func interact(player: Node) -> void:
	if not enabled: return
	interacted.emit(player)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group(&"player") and "player_interaction_system" in body:
		body.player_interaction_system.add(self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group(&"player") and "player_interaction_system" in body:
		body.player_interaction_system.remove(self)

## Read from the input map, so the prompt follows a rebound key.
func _key_name() -> String:
	for event in InputMap.action_get_events(&"interact"):
		if event is InputEventKey:
			return event.as_text_physical_keycode()
	return "?"
