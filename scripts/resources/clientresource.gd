class_name ClientData
extends Resource


# CLIENT PROPERTIES
var nickname:String
var car_model:PackedScene
var _model_id:String
var car_color:Color

# SERVER PROPERTIES
var car:VehicleBody3D


func _init(nick:String, model_id:String, c_color:Color) -> void:
	nickname = nick
	car_model = load("res://models/cars/%s.glb" % model_id)
	_model_id = model_id
	car_color = c_color


func to_bytes() -> PackedByteArray:
	return management.encode_packed_byte_arrays([
		nickname.to_utf8_buffer(),
		_model_id.to_ascii_buffer(),
		PackedByteArray([
			car_color.r8, car_color.g8, car_color.b8
		])
	])

static func from_bytes(data:PackedByteArray) -> ClientData: # wrong usage is not handled
	var bytearrays = management.decode_packed_byte_arrays(data)
	
	return ClientData.new(
		bytearrays[0].get_string_from_utf8(),
		bytearrays[1].get_string_from_ascii(),
		Color8(
			bytearrays[2][0], bytearrays[2][1], bytearrays[2][2]
		)
	)
