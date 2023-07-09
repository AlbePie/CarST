extends VehicleBody3D

var hull_material = preload("res://materials/car-hull.tres")

func _ready():
	#$"Car hull/Ferrari Testarossa".get_active_material(0).albedo_color = Color(113. / 255, 11. / 255, 18. / 255)
	var hull = $"Car hull/Ferrari Testarossa"
	hull_material.albedo_color = Color(11. / 255, 11. / 255, 88. / 255)
	hull.set_surface_override_material(0, hull_material)

func _process(_delta):
	var velocity = linear_velocity.length()
	
	var ratio = clamp(1 - velocity / 80, 0.5, 1)
	engine_force = 0
	if Input.is_action_pressed("ui_up"): engine_force += 150 * ratio
	if Input.is_action_pressed("ui_down"): engine_force -= 150
	brake = 3 if Input.is_action_pressed("brake") else 0
	
	ratio = clamp(1 - velocity / 40, 0.5, 1)
	steering = 0
	if Input.is_action_pressed("ui_left"): steering += 0.35 * ratio
	if Input.is_action_pressed("ui_right"): steering -= 0.35 * ratio

func _physics_process(_delta):
	if Input.is_action_just_pressed("reset"):
		rotation.x = 0
		rotation.z = 0
		position.y += 1.5
