extends Node2D

## Autoloaded as Effects. Hit feedback — damage numbers and sparks — drawn
## from pools, so a big fight doesn't build and free a Label and a particle
## system for every hit. Lives above any map, in world space (the camera
## moves it like everything else), so an effect also outlives the map
## changing under it.

var _idle_numbers: Array[DamageNumber] = []
var _idle_sparks: Array[HitSpark] = []

func _ready() -> void:
	# Over the Y-sorted world (z 2) and anything in it.
	z_index = 50

func damage_number(at: Vector2, amount: int, color: Color) -> void:
	if amount <= 0: return
	var number: DamageNumber = _idle_numbers.pop_back() if not _idle_numbers.is_empty() else _new_number()
	number.show_number(at, amount, color)

func hit_spark(at: Vector2, color := Color.WHITE) -> void:
	var spark: HitSpark = _idle_sparks.pop_back() if not _idle_sparks.is_empty() else _new_spark()
	spark.burst(at, color)

func _new_number() -> DamageNumber:
	var number := DamageNumber.new()
	number.done.connect(_on_number_done)
	add_child(number)
	return number

func _new_spark() -> HitSpark:
	var spark := HitSpark.new()
	spark.done.connect(_on_spark_done)
	add_child(spark)
	return spark

func _on_number_done(number: DamageNumber) -> void:
	number.visible = false
	_idle_numbers.append(number)

func _on_spark_done(spark: HitSpark) -> void:
	_idle_sparks.append(spark)
