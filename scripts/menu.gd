extends Node3D

@export_category("Menu Options")
@export var turn:float = 10. ## how much time takes the car to turn around
@export var start_immediately = false ## if the game should start immediately

@export_group("Node References")
@export var car:VehicleBody3D
@export var publicpopup:PopupPanel
@export var colorpicker:ColorPicker
@export var coloroptions:OptionButton

var uses_custom_color = false

var colors = [Color("770f0f"), Color("0f0f77"), Color("0f550f"), Color("bbbb1f")]

func _ready():
	get_window().min_size = Vector2i(1280, 768)
	TranslationServer.set_locale("en_US")
	
	
	if start_immediately:
		_on_play_button_pressed()
	
	management.color_updated.connect(car.update_color)
	_on_color_selected(coloroptions.selected)

func _process(delta):
	car.rotation_degrees.y += delta * (360 / turn)


func _on_color_selected(index):
	if coloroptions.get_item_text(index) == "{color.custom}":
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


func _on_play_public_pressed():
	publicpopup.popup_centered(get_window().size - Vector2i.ONE * 50)
