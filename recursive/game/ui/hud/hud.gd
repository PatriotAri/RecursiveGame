extends CanvasLayer

@onready var health_bar: Control = $Bars/VBox/HealthBar
@onready var stamina_bar: Control = $Bars/VBox/StaminaBar
@onready var mana_bar: Control = $Bars/VBox/ManaBar

@onready var gold_counter: Control = $Counters/GoldCounter
@onready var soul_counter: Control = $Counters/SoulCounter
## The readied spell's icon, in the bottom-left corner.
@onready var readied_spell: TextureRect = $ReadiedSpell
## A line across the top for news that happens away from any menu, like
## research finishing. Fades out on its own.
@onready var notice: Label = $Notice

## Seconds a notice stays up before it fades.
const NOTICE_TIME := 3.0

var _notice_tween: Tween

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
	mana_bar.bind(player.stats.mana)
	
	gold_counter.bind(player.data.inventory)
	soul_counter.bind(player.data.inventory)
	
	player.player_spell_system.readied_changed.connect(_show_readied_spell)
	player.player_spell_system.research_finished.connect(
		func(spell: Spell, level: int) -> void: show_notice("%s is ready." % spell.name_at(level)))
	# A loaded save may have readied one before the HUD was listening.
	_show_readied_spell(player.data.readied_spell)

func _show_readied_spell(spell: Spell) -> void:
	readied_spell.texture = spell.icon if spell else null
	readied_spell.visible = spell != null

func show_notice(text: String) -> void:
	if _notice_tween and _notice_tween.is_valid():
		_notice_tween.kill()
	notice.text = text
	notice.visible = true
	notice.modulate.a = 1.0
	_notice_tween = create_tween()
	_notice_tween.tween_interval(NOTICE_TIME)
	_notice_tween.tween_property(notice, "modulate:a", 0.0, 0.5)
	_notice_tween.tween_callback(notice.hide)
