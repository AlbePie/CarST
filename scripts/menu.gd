class_name Menu
extends Node3D

@export_category("Menu Options")
@export var turn:float = 10. ## how much time takes the car to turn around
@export var start_immediately = false ## if the game should start immediately

@export_group("Node References")
@export var car:VehicleBody3D
@export var serveradress:LineEdit
@export var publicpopup:PopupPanel
@export var publicserverlist:VBoxContainer
@export var publicserverscene:PackedScene
@export var map_pick:PopupPanel
@export var nickname:LineEdit
@export var colorpicker:ColorPicker
@export var coloroptions:OptionButton
@export var errordialog:AcceptDialog

var uses_custom_color = false

var colors = [Color("770f0f"), Color("0f0f77"), Color("0f550f"), Color("bbbb1f")]

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		network.start_server()
	
	get_window().min_size = Vector2i(1280, 768)
	TranslationServer.set_locale("en_US")
	
	
	if start_immediately:
		_on_play_button_pressed()
	
	management.color_updated.connect(car.update_color)
	_on_color_selected(coloroptions.selected)

func _process(delta) -> void:
	car.rotation_degrees.y += delta * (360 / turn)


func _on_color_selected(index) -> void:
	if coloroptions.get_item_text(index) == "{color.custom}":
		uses_custom_color = true
		management.set_color(colorpicker.color)
	else:
		uses_custom_color = false
		management.set_color(colors[index])
	
	colorpicker.visible = uses_custom_color


func _on_play_button_pressed() -> void:
	var map = await map_pick.get_map()
	if map == "":
		return
	
	network.start_local(map, "car-hull")


func _on_color_picker_color_changed(color) -> void:
	management.set_color(color)


func _on_play_public_pressed() -> void:
	publicpopup.popup_centered(get_window().size - Vector2i.ONE * 50)


func _on_join_pressed() -> void:
	var adress_and_port = serveradress.text.split(":", false)
	match len(adress_and_port):
		0:
			errordialog.dialog_text = "{error.emptyaddress}"
			errordialog.popup_centered(Vector2i(300, 300))
			return
		1:
			adress_and_port.append(str(network.DEFAULT_PORT))
		_:
			if int(adress_and_port[1]) not in range(1001, 50001):
				errordialog.dialog_text = "{error.invalidport}"
				errordialog.popup_centered(Vector2i(300, 300))
				return
	
	if not nickname.text:
		errordialog.dialog_text = "{error.emptynick}"
		errordialog.popup_centered(Vector2i(300, 300))
		return
	
	var err = await network.start_client(
		adress_and_port[0], 
		int(adress_and_port[1]), 
		nickname.text, "car-hull", 
		management.car_color
	)
	
	if err != OK:
		errordialog.dialog_text = tr("{error.stringerror}") % error_string(err)
		errordialog.popup_centered(Vector2i(300, 300))
