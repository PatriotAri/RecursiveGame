class_name SpellLevel

extends Resource

## One level a spell can be researched to at the tome stand: its numbers at
## that level, and the souls the research costs.

@export var damage := 0.0
## 0 for a spell with no blast.
@export var blast_radius := 0.0
@export var mana_cost := 0
@export var research_cost := 1
