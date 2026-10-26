class_name Item

extends Resource

enum Category {NONE, ARMOR, WEAPON, CONSUMABLE, CURRENCY} #always append enum, never insert in middle

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var category: Category = Category.NONE
## Price in gold at a vendor. Selling pays half, rounded down.
@export var value := 0
## Played when it's picked up. Leave empty for the shared pickup sound.
@export var pickup_sound: SoundEffect

## The text a menu shows for it: its description, plus anything a kind of
## item adds, like gear's material and enchantments.
func details() -> String:
	return description
