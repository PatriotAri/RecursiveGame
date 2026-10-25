class_name MenuExit

extends Node2D

## Returns to the main menu when used. For the end of a world, or anywhere a
## run should end on the player's say-so.

const MAIN_MENU := "res://main.tscn"

@onready var interactable: Interactable = $Interactable

func _ready() -> void:
	interactable.interacted.connect(_on_interacted)

func _on_interacted(_player: Node) -> void:
	get_tree().paused = false
	# Deferred: this runs inside the player's _physics_process, and
	# change_scene_to_file() pulls the current scene out of the tree on the
	# spot — the player would finish its frame (move_and_slide) outside it.
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU)
