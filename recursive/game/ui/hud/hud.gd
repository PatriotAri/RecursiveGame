extends CanvasLayer

@onready var health_bar: Control = $HealthBar
@onready var stamina_bar: Control = $StaminaBar

@onready var gold_counter: Control = $GoldCounter
@onready var soul_counter: Control = $SoulCounter

func _ready() -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	if player == null:
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group(&"player")
	if player == null or not ("stats" in player):
		push_warning("Hud: no player found to bind to.")
		return
	health_bar.bind(player.stats.health)
	stamina_bar.bind(player.stats.stamina)
	gold_counter.bind(player.data.inventory)
	soul_counter.bind(player.data.inventory)
