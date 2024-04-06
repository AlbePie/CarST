extends VehicleBody3D

var hull_material = preload("res://materials/car-hull.tres")

@onready var uddetector = $UDDetector

@export var controlled = true

var is_flipped = false

func _ready():
	#$"Car hull/Ferrari Testarossa".get_active_material(0).albedo_color = Color(113. / 255, 11. / 255, 18. / 255)
	hull_material = hull_material.duplicate(true)
	var hull = $"Car hull/Ferrari Testarossa"
	update_color()
	hull.set_surface_override_material(0, hull_material)

func _process(_delta):
	if controlled:
		var velocity = linear_velocity.length()
		
		var ratio = clamp(1 - velocity / 80, 0.5, 1)
		engine_force = 0
		var forward = linear_velocity.dot(transform.basis.z)
		if Input.is_action_pressed("ui_up"): engine_force += 150 * ratio
		if Input.is_action_pressed("ui_down"): engine_force -= 150 if forward > 0 else 50
		brake = 3 if Input.is_action_pressed("brake") else 0
		
		ratio = clamp(1 - velocity / 20, 0, 1)
		steering = 0
		if Input.is_action_pressed("ui_left"): steering += 0.3 * ratio + 0.2
		if Input.is_action_pressed("ui_right"): steering -= 0.3 * ratio + 0.2
	is_flipped = uddetector.has_overlapping_bodies()

func _physics_process(_delta):
	if controlled:
		if Input.is_action_just_pressed("reset") and is_flipped:
			rotation.x = 0
			rotation.z = 0
			position.y += 1.5

func update_color(to=null):
	hull_material.albedo_color = management.car_color if to == null else to
