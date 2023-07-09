extends Camera3D

func _ready():
	_process(0)

func _process(_delta):
	rotation.y = PI + $"../Car".rotation.y
	position.x = $"../Car".position.x + 6 * sin(rotation.y)	
	position.z = $"../Car".position.z + 6 * cos(rotation.y)
	position.y = 4 + $"../Car".position.y
