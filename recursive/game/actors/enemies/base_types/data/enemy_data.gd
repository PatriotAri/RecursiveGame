class_name EnemyData

#read/written by DetectionSystem
var player_detected:= false
var in_attack_range:= false
var player_pos:= Vector2.ZERO

#read/written by state machine
var current_state: int = 0
var previous_state: int = 0
var state_just_changed:= false
var attack_finished:= false
var is_hurt:= false
var is_dead:= false

#read/written by movement system
var patrol_speed:= 50.0
var walk_speed:= 65.0
var run_speed:= 130.0
var last_facing:= Vector2.ZERO
