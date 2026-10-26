class_name StandDetail

extends RefCounted

## The right side of a stand's menu: what's selected, and what can be done
## with it.

var title := ""
var icon: Texture2D
var icon_material: Material
var text := ""
var rows: Array[StandRow] = []
