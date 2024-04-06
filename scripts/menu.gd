extends Node3D

@export_category("Menu Options")
@export var turn:float = 10. ## how much time takes the car to turn around
@export var start_immediately = false ## if the game should start immediately

@onready var car = $Car
@onready var colorpicker = $Menu/ColorPick/ColorPicker
@onready var coloroptions = $Menu/ColorPick/Options

var uses_custom_color = false

var colors = [Color("770f0f"), Color("0f0f77"), Color("0f550f"), Color("bbbb1f")]

func _ready():
	if start_immediately:
		_on_play_button_pressed()
	management.color_updated.connect(car.update_color)
	_on_color_selected($Menu/ColorPick/Options.selected)

func _process(delta):
	car.rotation_degrees.y += delta * (360 / turn)


func _on_color_selected(index):
	if coloroptions.get_item_text(index) == "Custom":
		uses_custom_color = true
		management.set_color(colorpicker.color)
	else:
		uses_custom_color = false
		management.set_color(colors[index])
	
	colorpicker.visible = uses_custom_color


func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/world.tscn")


func _on_color_picker_color_changed(color):
	management.set_color(color)
