class_name DropEntry

extends Resource

@export var scene: PackedScene
## Defaults to zero deliberately. Godot omits values matching the default when
## it saves, so a forgotten chance has to mean "never drops" — something you
## notice in a minute of testing — rather than "drops half the time", which
## sat unnoticed in crawler_drops.tres for three versions.
@export_range(0.0, 1.0) var chance: float = 0.0
@export var min_amount: int = 1
@export var max_amount: int = 1
