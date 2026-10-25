extends CanvasLayer

@onready var health_bar: Control = $Bars/VBox/HealthBar
@onready var stamina_bar: Control = $Bars/VBox/StaminaBar
@onready var mana_bar: Control = $Bars/VBox/ManaBar
@onready var spell_slot: Control = $Bars/VBox/SpellSlot
@onready var round_label: Label = $RoundLabel
@onready var toast: Label = $Toast
var _toast_tween: Tween

var _rounds: RoundManager

@onready var gold_counter: Control = $Counters/GoldCounter
@onready var soul_counter: Control = $Counters/SoulCounter

func _ready() -> void:
	SaveManager.saved.connect(_show_toast.bind("Game saved"))
	var player := get_tree().get_first_node_in_group(&"player")
	if player == null:
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group(&"player")
	if player == null or not ("stats" in player):
		push_warning("Hud: no player found to bind to.")
		return
	health_bar.bind(player.stats.health)
	stamina_bar.bind(player.stats.stamina)
	mana_bar.bind(player.stats.mana)
	spell_slot.bind(player.player_spell_system)
	
	gold_counter.bind(player.data.inventory)
	soul_counter.bind(player.data.inventory)
	
	# The map was loaded before this ran, so bind to it now and follow every
	# later map change.
	var game := get_tree().get_first_node_in_group(&"game")
	if game:
		game.map_changed.connect(_on_map_changed)
		if game.current_map: _on_map_changed(game.current_map)

## A line of text in the corner that fades out on its own.
func _show_toast(text: String) -> void:
	toast.text = text
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.5)
	_toast_tween.tween_property(toast, "modulate:a", 0.0, 0.6)

func _on_map_changed(map: Map) -> void:
	if _rounds and is_instance_valid(_rounds):
		for sig in [_rounds.round_started, _rounds.round_completed, _rounds.remaining_changed]:
			if sig.is_connected(_on_round_event): sig.disconnect(_on_round_event)
	_rounds = map.get_round_manager()
	if _rounds:
		_rounds.round_started.connect(_on_round_event)
		_rounds.round_completed.connect(_on_round_event)
		_rounds.remaining_changed.connect(_on_round_event)
	_refresh_round()

## Every round signal carries one int; none of them matter here, the label
## reads the manager's state directly.
func _on_round_event(_value: int) -> void:
	_refresh_round()

func _refresh_round() -> void:
	if _rounds == null:
		round_label.visible = false
		return
	round_label.visible = true
	var of_total := "/%d" % _rounds.total_rounds if _rounds.total_rounds > 0 else ""
	if _rounds.active:
		round_label.text = "Round %d%s — %d left" % [_rounds.current_round, of_total, _rounds.remaining()]
	elif _rounds.is_finished():
		round_label.text = "All rounds cleared!"
	elif _rounds.current_round > 0:
		round_label.text = "Round %d cleared" % _rounds.current_round
	else:
		round_label.text = "Start the round when ready"
