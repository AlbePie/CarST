extends Camera3D

enum CameraModes{BACK,DRIVER,FRONT}

@export var camera_mode = CameraModes.BACK
@export_group("Node References")
@export var car:VehicleBody3D

func _ready():
	_process(0)

func _process(_delta):
	if Input.is_action_just_pressed("back_camera"):
		@warning_ignore("int_as_enum_without_cast")
		camera_mode += 1
		@warning_ignore("int_as_enum_without_cast")
		camera_mode %= len(CameraModes)
	
	match camera_mode:
		_: # BACK AND FRONT, TEMPORARY DRIVER
			rotation.y = car.rotation.y + (PI if camera_mode != CameraModes.FRONT else 0.)
			position.x = car.position.x + 6 * sin(rotation.y)
			position.z = car.position.z + 6 * cos(rotation.y)
			position.y = 4 + car.position.y
