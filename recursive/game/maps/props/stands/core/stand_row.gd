class_name StandRow

extends RefCounted

## One line in a stand's menu: a button, or plain text when it does nothing.

var text := ""
var icon: Texture2D
## Draws `icon` recoloured, for gear made of another material.
var icon_material: Material
## Greyed out and unpressable, with `note` saying why.
var disabled := false
## A short line under the row, e.g. why it's disabled.
var note := ""
## Shown as the current choice.
var selected := false
## Called when pressed. Returns what the menu should select next (a stand
## decides what its selections are), or null to keep the current one. Unset,
## the row is plain text.
var on_pressed: Callable

static func make(row_text: String, pressed := Callable()) -> StandRow:
	var row := StandRow.new()
	row.text = row_text
	row.on_pressed = pressed
	return row
