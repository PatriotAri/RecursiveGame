class_name EnemyNavigation

## Pathing for one enemy: the next corner round the walls toward a target,
## the nearest walkable point to anywhere, and whether there's a navmesh to
## do either on. Owns the NavigationAgent2D, created in code so enemy scenes
## need no extra node. With no navmesh in the level, movement falls back to
## straight lines.

## Re-query the path only when the target has moved this far. Chasing a
## moving player otherwise asks for a new path every single frame.
const REPATH_DISTANCE_SQ := 16.0 * 16.0

var body: Enemy
var agent: NavigationAgent2D

func _init(body_ref: Enemy) -> void:
	body = body_ref
	agent = NavigationAgent2D.new()
	agent.path_desired_distance = 8.0
	agent.target_desired_distance = 8.0
	agent.radius = body.profile.spacing_radius * 0.5
	body.add_child(agent)

## Where to head next on the way to `target`: the next corner of a path
## around walls, or `target` itself when there's no navmesh to path on.
func next_path_position(target: Vector2) -> Vector2:
	if not body.uses_pathfinding() or not has_navigation():
		return target
	if agent.target_position.distance_squared_to(target) > REPATH_DISTANCE_SQ:
		agent.target_position = target
	if agent.is_navigation_finished():
		return target
	var next := agent.get_next_path_position()
	# No path (the query found nothing): head straight for the target. Seen
	# once in testing as an enemy frozen in place for the rest of a fight,
	# returning its own position as the next point forever.
	if agent.get_current_navigation_path().is_empty():
		return target
	return next

## The nearest walkable point to `point`, for picking destinations that
## aren't inside a wall. Unchanged when there's no navmesh.
func closest_walkable(point: Vector2) -> Vector2:
	if not has_navigation():
		return point
	return NavigationServer2D.map_get_closest_point(agent.get_navigation_map(), point)

func has_navigation() -> bool:
	var map := agent.get_navigation_map()
	# Iteration 0 means the map has never synced.
	if not map.is_valid() or NavigationServer2D.map_get_iteration_id(map) == 0:
		return false
	# A region sits on the map from the moment the level loads, before its
	# navmesh is baked into it. Until there's a polygon to stand on, there's
	# nothing to path over or snap to.
	return NavigationServer2D.map_get_closest_point_owner(map, body.global_position).is_valid()
