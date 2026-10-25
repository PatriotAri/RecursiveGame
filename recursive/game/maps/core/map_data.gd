class_name MapData

extends Resource

## One loadable map. Listed in a MapRegistry; looked up by id.

@export var id: StringName
@export var display_name: String
## A path rather than a PackedScene so the registry doesn't load every map
## in the game the moment it's opened.
@export_file("*.tscn") var scene_path: String
## Played on entering. Null leaves whatever is playing alone.
@export var music: AudioStream
