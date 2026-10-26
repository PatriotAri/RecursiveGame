class_name MaterialRecolor

## Hands out the shader material that draws an item as what it's made of:
## worn armour, the weapon in hand, and item icons in menus. One material per
## ramp and saturation limit, shared, so a screen of iron icons is one
## material, not one each.

const SHADER := preload("res://game/items/equipment/materials/material_recolor.gdshader")

static var _cache: Dictionary = {}  # [ramp, max_saturation] -> ShaderMaterial

## The material to draw `item` with, or null when it's drawn as it is: an
## original, a non-equipment item, or a piece made of what its art shows.
static func for_item(item: Item) -> ShaderMaterial:
	if not item is EquippableItem: return null
	var ramp: GradientTexture1D = item.recolor_ramp()
	if ramp == null: return null
	var key := [ramp, item.recolor_max_saturation]
	if not _cache.has(key):
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter(&"ramp", ramp)
		material.set_shader_parameter(&"max_saturation", item.recolor_max_saturation)
		_cache[key] = material
	return _cache[key]
