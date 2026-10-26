class_name LevelNavigation

extends NavigationRegion2D

## Builds and bakes the level's navigation map when the level loads: the
## ground's painted area, minus a margin around everything on the blocking
## physics layers. Baking at load keeps the map in step with the walls however
## they're edited, so there's no manual bake step to forget.

## The walkable area is this layer's painted cells.
@export var ground: TileMapLayer
## Nodes in this group have their collision cut out of the walkable area.
@export var obstacle_group: StringName = &"navigation_obstacles"
## Physics layers that block walking: Environment and Low Obstacles. Flyers
## will want a second map without Low Obstacles.
@export_flags_2d_physics var blocking_layers := 1 | 64
## How far paths keep from walls — about the half-width of the widest
## walking enemy, so they don't scrape along corners.
@export var agent_radius := 10.0

func _ready() -> void:
	if ground == null or ground.tile_set == null:
		push_error("%s: no ground layer to build navigation from." % name)
		return
	var polygon := NavigationPolygon.new()
	polygon.add_outline(_ground_outline())
	polygon.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	polygon.parsed_collision_mask = blocking_layers
	polygon.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_EXPLICIT
	polygon.source_geometry_group_name = obstacle_group
	polygon.agent_radius = agent_radius
	navigation_polygon = polygon
	# Not on a thread: enemies spawned this frame should find a map waiting.
	bake_navigation_polygon(false)

## The painted ground's bounding rectangle, in this node's space.
func _ground_outline() -> PackedVector2Array:
	var rect := ground.get_used_rect()
	var half_tile := Vector2(ground.tile_set.tile_size) / 2.0
	# map_to_local() gives cell centres; step out half a tile to the edges.
	var top_left := ground.map_to_local(rect.position) - half_tile
	var bottom_right := ground.map_to_local(rect.end - Vector2i.ONE) + half_tile
	var corners := [
		top_left,
		Vector2(bottom_right.x, top_left.y),
		bottom_right,
		Vector2(top_left.x, bottom_right.y),
	]
	var outline := PackedVector2Array()
	for corner in corners:
		outline.append(to_local(ground.to_global(corner)))
	return outline
