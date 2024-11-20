class_name BetterCamera
extends Camera3D

enum CameraModes{BACK,DRIVER,FRONT}

@export var camera_mode = CameraModes.BACK
var car:Car

const MAX_POSITION_LENGTH = 8

var position_length_ema = MAX_POSITION_LENGTH
const POSITION_LENGTH_MOMENTUM = 0.99

func _ready() -> void:
	_process(0)

func _process(_delta) -> void:
	if network.game_state == network.GameState.ONLINE_SERVER:
		return
	
	car = get_node_or_null(
		"../%s" % (
			str(multiplayer.get_unique_id()) 
			if network.game_state == network.GameState.ONLINE_CLIENT else 
			"Car"
		)
	)
	if car == null:
		return
	
	if Input.is_action_just_pressed("back_camera"):
		@warning_ignore("int_as_enum_without_cast")
		camera_mode += 1
		@warning_ignore("int_as_enum_without_cast")
		camera_mode %= len(CameraModes)
	
	match camera_mode:
		CameraModes.DRIVER:
			global_position = car.driver_marker.global_position
			global_rotation = car.driver_marker.global_rotation
		_: # BACK AND FRONT
			var cast = car.back_raycast if camera_mode == CameraModes.BACK else car.front_raycast
			var castend = cast.get_node("CastEnd").global_position
			var cast_point = (
				cast.get_collision_point() 
				if cast.is_colliding() else 
				castend
			)
			var position_length = (cast_point - cast.global_position).length()
			
			position_length_ema = (
				position_length_ema * 
				POSITION_LENGTH_MOMENTUM + 
				position_length * (1 - POSITION_LENGTH_MOMENTUM)
			) if position_length > position_length_ema else position_length
			
			var camera_distance = position_length_ema / MAX_POSITION_LENGTH
			
			global_position = cast.global_position.lerp(castend, camera_distance)
			
			
			look_at(car.position)
