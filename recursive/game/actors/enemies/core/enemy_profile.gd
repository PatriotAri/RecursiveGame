class_name EnemyProfile

extends Resource

## Everything that makes an enemy type play the way it does, as one
## shareable resource: its stats, its attack, how it chases, keeps its
## distance, flees and patrols, and what it drops. Enemy scenes then only
## hold art and collision; a variant is a different profile, not a dozen
## overridden exports. Shared between every enemy of a type — read-only at
## runtime.

@export_group("Stat Tuning")
@export var max_health: int = 10
## Armor points. See StatSystem.mitigate().
@export var armor: int = 0

@export_group("Attack Tuning")
## What a swing (or shot) is: hitbox or projectile scene, damage, timing,
## sound.
@export var attack: AttackSpec
## Pause between swings. Owed after a completed attack and after an
## interrupted one.
@export var attack_cooldown:= 1.5
## Half-width of what this enemy is trying to hit — the player's hurtbox is
## 32 wide, so 16. The narrow axis, so the derived range stays conservative.
@export var target_radius:= 16.0
## Grace period after the player leaves the detection shape before aggro drops.
## Stops a target walking the boundary from flickering CHASE/PATROL every frame.
@export var target_forget_delay:= 1.0
## Once aggroed, the player has to get this far away before the forget
## countdown even starts. Pathing round a wall routinely carries an enemy
## out of its detection shape mid-chase; without this it would give up.
@export var leash_distance:= 320.0
## Only commit to an attack with a clear line to the target. For anything
## that shoots — melee can't hit through a wall anyway.
@export var needs_line_of_sight:= false
## Backs away while cooling down if the player is closer than this. For
## enemies that want to fight from range. 0 = holds position.
@export var preferred_distance:= 0.0

#movement variables
@export_group("Movement Tuning")
@export var patrol_speed:= 50.0
@export var walk_speed:= 65.0
@export var acceleration:= 500.0 #px/s^2
@export var friction:= 600.0 #px/s^2

#spacing variables
@export_group("Spacing Tuning")
## Other enemies closer than this get pushed apart, so a group doesn't
## collapse into one stacked sprite.
@export var spacing_radius:= 28.0
## Push speed at full overlap, in px/s. Fades to zero at spacing_radius.
@export var spacing_strength:= 60.0

#flee variables
@export_group("Flee Tuning")
## Flees when health falls to this fraction with the player nearby.
## 0 = never flees.
@export_range(0.0, 1.0) var flee_health_ratio:= 0.0
@export var flee_speed:= 110.0
## Stops running once the player is this far away.
@export var flee_safe_distance:= 220.0
## A single flee gives up after this long...
@export var flee_max_time:= 3.0
## ...and can't start again until this much later.
@export var flee_recover_time:= 2.5

#patrol variables
@export_group("Patrol Tuning")
## Size of the box around the enemy that patrol points are picked from.
## Zero stands still.
@export var patrol_size:= Vector2(300, 275)
@export var patrol_wait_time:= 3.5
@export var min_patrol_distance:= 40.0

@export_group("Drop Tuning")
@export var drop_table: DropTable
