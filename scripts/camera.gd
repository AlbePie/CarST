extends Camera3D

enum CameraModes{BACK,DRIVER,FRONT}

@export var camera_mode = CameraModes.BACK
var car:VehicleBody3D

const driver_offset = Vector3(-0.3, .8, .1)

func _ready():
	_process(0)

func _process(_delta):
	if network.game_state == network.GameState.ONLINE_SERVER:
		return
	
	car = get_node_or_null("../%s" % (str(multiplayer.get_unique_id()) if network.game_state == network.GameState.ONLINE_CLIENT \
		else "Car"))
	if car == null:
		return
	
	if Input.is_action_just_pressed("back_camera"):
		@warning_ignore("int_as_enum_without_cast")
		camera_mode += 1
		@warning_ignore("int_as_enum_without_cast")
		camera_mode %= len(CameraModes)
	
	match camera_mode:
		CameraModes.DRIVER:
			position = car.position
			rotation = car.rotation
			basis = basis.rotated(basis.y.normalized(), PI)
			for i in range(3):
				position += driver_offset[i] * basis[i]
		_: # BACK AND FRONT
			rotation_degrees = Vector3(-15, 0, 0)
			rotation.y = car.rotation.y + (PI if camera_mode != CameraModes.FRONT else 0.)
			position.x = car.position.x + 6 * sin(rotation.y)
			position.z = car.position.z + 6 * cos(rotation.y)
			position.y = 4 + car.position.y
