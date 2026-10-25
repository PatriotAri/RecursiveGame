class_name LevelNavigation

extends NavigationRegion2D

## Bakes the level's navmesh at load from what's actually there: walkable
## area = the Ground layer's used rectangle, minus every collider in the
## obstacle group (the Walls layer). Repainting a level needs no rebake step
## in the editor — the next run picks it up.

@export var ground: TileMapLayer
## Nodes in this group (and their children) carve holes in the navmesh.
@export var obstacle_group:= &"navigation_obstacles"
## How far paths keep from walls. Roughly the widest enemy's collision radius.
@export var agent_radius:= 12.0

func _ready() -> void:
	add_to_group(&"level_navigation")
	if ground == null:
		push_warning("%s: no ground layer assigned; navigation disabled." % name)
		return
	# Tile layers build their collision on their first update, not on entering
	# the tree. One frame later it's all there to parse.
	await get_tree().process_frame
	bake()

## Rebuilds the navmesh, on the main thread. A threaded bake was tried for
## door rebakes and came back empty, and a synchronous one measured under
## half a millisecond on the largest map here, so it isn't worth the risk.
func bake() -> void:
	var poly := NavigationPolygon.new()
	poly.agent_radius = agent_radius
	poly.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	poly.parsed_collision_mask = 1   # Environment
	poly.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	poly.source_geometry_group_name = obstacle_group
	poly.add_outline(_ground_outline())
	navigation_polygon = poly
	bake_navigation_polygon(false)

## The ground's used rectangle, in this node's local space.
func _ground_outline() -> PackedVector2Array:
	var cells := ground.get_used_rect()
	var half := Vector2(ground.tile_set.tile_size) * 0.5
	var top_left := ground.map_to_local(cells.position) - half
	var bottom_right := ground.map_to_local(cells.end - Vector2i.ONE) + half
	var corners := [top_left, Vector2(bottom_right.x, top_left.y), bottom_right, Vector2(top_left.x, bottom_right.y)]
	var outline := PackedVector2Array()
	for corner in corners:
		outline.append(to_local(ground.to_global(corner)))
	return outline
