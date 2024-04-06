extends Node

var car_color = Color(11. / 255, 11. / 255, 88. / 255)

signal color_updated

func set_color(to:Color):
	car_color = to
	color_updated.emit()

func _ready():
	randomize()
