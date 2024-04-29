extends Resource
class_name ClientData

# CLIENT PROPERTIES
var nickname:String
var car_model:PackedScene
var _model_id:String
var car_color:Color

# SERVER PROPERTIES
var car:VehicleBody3D
var ticks_to_full_state:int = 0
var prev_state:MapState = MapState.new()

func _init(nick:String, model_id:String, c_color:Color):
	nickname = nick
	car_model = load("res://models/cars/%s.glb" % model_id)
	_model_id = model_id
	car_color = c_color

func to_bytes():
	return var_to_bytes_with_objects([nickname, _model_id, car_color])

static func from_bytes(data:PackedByteArray): # wrong usage is not handled
	return ClientData.new.callv(bytes_to_var_with_objects(data)) # creates new resource with parameters
	# specified as array in data
