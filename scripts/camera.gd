extends Camera3D

@export_group("Node References")
@export var car:VehicleBody3D

func _ready():
	_process(0)

func _process(_delta):
	rotation.y = car.rotation.y + (PI if not Input.is_action_pressed("back_camera") else 0.)
	position.x = car.position.x + 6 * sin(rotation.y)
	position.z = car.position.z + 6 * cos(rotation.y)
	position.y = 4 + car.position.y
