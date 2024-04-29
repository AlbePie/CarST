extends Node

# CAR COLOR
var car_color = Color(11. / 255, 11. / 255, 88. / 255)

signal color_updated

func set_color(to:Color):
	car_color = to
	color_updated.emit()

# GET MAP
const level_path = "res://scenes/levels/"

func get_maps():
	var result:Array[MapRepresentation] = []
	
	for map_path in DirAccess.get_files_at(level_path):
		if map_path.get_extension() != "tres": # ignore all non-tres files to not load scenes etc...
			continue
		
		var cfg = load(level_path.path_join(map_path))
		if not (cfg is MapRepresentation):
			continue
		
		result.append(cfg)
	
	return result

func _ready():
	randomize()
