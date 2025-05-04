class_name ManagementSingleton
extends Node


# CAR COLOR
var car_color = Color(11. / 255, 11. / 255, 88. / 255)

signal color_updated

func set_color(to:Color) -> void:
	car_color = to
	color_updated.emit()


# GET MAP
const level_path = "res://scenes/levels/"

func get_maps() -> Array[Map]:
	var result:Array[Map] = []
	
	for map_path in DirAccess.get_files_at(level_path):
		if map_path.get_extension() != "tres": # ignore all non-tres files to not load scenes etc...
			continue
		
		var cfg = load(level_path.path_join(map_path))
		if not (cfg is Map):
			continue
		
		result.append(cfg)
	
	return result

# TOOLS

func encode_packed_byte_arrays(arrays: Array[PackedByteArray]) -> PackedByteArray:
	var bytearray = PackedByteArray()
	
	for array in arrays:
		var index = len(bytearray)
		bytearray.append_array(PackedByteArray([0, 0]))
		bytearray.encode_u16(index, len(array))
		bytearray.append_array(array)
	
	return bytearray

func decode_packed_byte_arrays(data: PackedByteArray) -> Array[PackedByteArray]:
	var bytearrays:Array[PackedByteArray] = []
	
	var index = 0
	while index < len(data):
		var length = data.decode_u16(index)
		index += 2
		var bytearray = PackedByteArray()
		for i in range(length):
			bytearray.append(data[index])
			index += 1
		bytearrays.append(bytearray)
	
	return bytearrays

func _ready():
	randomize()
