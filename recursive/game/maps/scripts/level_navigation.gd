class_name LevelNavigation

extends NavigationRegion2D

## Builds and bakes the level's navigation maps when the level loads: the
## ground's painted area, minus a margin around everything on the blocking
## physics layers. Baking at load keeps the maps in step with the walls
## however they're edited, so there's no manual bake step to forget.
##
## Two maps. Walkers use the world's own map, from this region: around walls
## and low obstacles. Flyers use a separate map, from a child region built
## here: around walls only. Separate maps rather than navigation layers on one
## map, because spawning and patrolling ask a map for its closest point with no
## layer filter, and a walker must never be handed a spot only a flyer can
## reach.

## Low Obstacles, which flyers pass over.
const LOW_OBSTACLES := 64

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

## The flyers' map. A flyer's agent switches onto it when the flyer spawns.
var flyer_map: RID

var _rebake_queued := false
var _flyer_region: NavigationRegion2D

func _ready() -> void:
	add_to_group(&"level_navigation")
	if ground == null or ground.tile_set == null:
		push_error("%s: no ground layer to build navigation from." % name)
		return
	navigation_polygon = _make_polygon(blocking_layers)
	flyer_map = NavigationServer2D.map_create()
	NavigationServer2D.map_set_active(flyer_map, true)
	_flyer_region = NavigationRegion2D.new()
	_flyer_region.name = "FlyerNavigation"
	_flyer_region.navigation_polygon = _make_polygon(blocking_layers & ~LOW_OBSTACLES)
	add_child(_flyer_region)
	_flyer_region.set_navigation_map(flyer_map)
	# Not on a thread: enemies spawned this frame should find a map waiting.
	bake_navigation_polygon(false)
	_flyer_region.bake_navigation_polygon(false)

## The flyer map isn't the world's, so nothing else frees it.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and flyer_map.is_valid():
		NavigationServer2D.free_rid(flyer_map)

func _make_polygon(blocked_by: int) -> NavigationPolygon:
	var polygon := NavigationPolygon.new()
	polygon.add_outline(_ground_outline())
	polygon.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	polygon.parsed_collision_mask = blocked_by
	polygon.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_EXPLICIT
	polygon.source_geometry_group_name = obstacle_group
	polygon.agent_radius = agent_radius
	return polygon

## Bakes again from the current obstacles — after a door opens or closes.
## Several requests in one frame become a single bake.
func rebake() -> void:
	if _rebake_queued or navigation_polygon == null: return
	_rebake_queued = true
	_rebake.call_deferred()

func _rebake() -> void:
	_rebake_queued = false
	# Set aside while the player is on the airship: bake when it's back.
	if not is_inside_tree():
		if not tree_entered.is_connected(rebake):
			tree_entered.connect(rebake, CONNECT_ONE_SHOT)
		return
	bake_navigation_polygon(false)
	_flyer_region.bake_navigation_polygon(false)

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
