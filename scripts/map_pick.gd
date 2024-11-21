class_name MapPicker
extends PopupPanel


@export_group("Node References")
@export var ui:VBoxContainer
@export var map_scroll:ScrollContainer
@export var map_select:VBoxContainer

const map_scene = preload("res://scenes/map_select_template.tscn")

signal _map_value_changed(map:String)


func _ready() -> void:
	hide()
	
	map_scroll.set.call_deferred("scroll_vertical", 0)
	map_select.custom_minimum_size.y = 0
	
	var maps = management.get_maps()
	for map in maps:
		var map_instance = map_scene.instantiate()
		map_select.custom_minimum_size.y += map_instance.custom_minimum_size.y
		
		map_instance.get_node("Icon").texture = map.map_icon
		map_instance.get_node("Name").text = map.map_name
		map_instance.get_node("Play").pressed.connect(self._send_map_value.bind(map.map_scene_code))
		# binds the "pressed" signal to emit the "_map_value_changed" with "map.map_scene_code" parameter
		
		map_select.add_child(map_instance)

func get_map() -> String:
	popup_centered(get_tree().get_root().size - Vector2i.ONE * 50)
	return await _map_value_changed


func _on_close_requested() -> void:
	_map_value_changed.emit("")

func _send_map_value(code:String) -> void:
	_map_value_changed.emit(code)
