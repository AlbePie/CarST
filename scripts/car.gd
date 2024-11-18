class_name Car
extends VehicleBody3D

var hull_material = preload("res://materials/cars/car-hull.tres")

@export var uddetector:Area3D
@export var exhaust_one:GPUParticles3D
@export var exhaust_two:GPUParticles3D
@export var exhaust_material:ParticleProcessMaterial

var startpos:Marker3D

@export var controlled = true

var is_flipped = false

var pressed_actions = []

var additional_data:
	get:
		return null
	set(val):
		update_client(AdditionalClientData.from_bytes(val))


func _ready() -> void:
	startpos = get_node_or_null("../CarStart")
	if startpos != null:
		position = startpos.position
	
	hull_material = hull_material.duplicate(true)
	var hull = $"Car hull/Ferrari Testarossa"
	update_color()
	hull.set_surface_override_material(0, hull_material)

func _process(_delta) -> void:
	if controlled and network.game_state != network.GameState.ONLINE_CLIENT:
		var velocity = linear_velocity.length()
		
		var ratio = clamp(1 - velocity / 80, 0.5, 1)
		engine_force = 0
		var forward = linear_velocity.dot(transform.basis.z)
		if custom_is_action_pressed("ui_up"): engine_force += 150 * ratio
		if custom_is_action_pressed("ui_down"): engine_force -= 150 if forward > 0 else 50
		brake = 3 if custom_is_action_pressed("brake") else 0
		
		ratio = clamp(1 - velocity / 20, 0, 1)
		steering = 0
		if custom_is_action_pressed("ui_left"): steering += 0.3 * ratio + 0.2
		if custom_is_action_pressed("ui_right"): steering -= 0.3 * ratio + 0.2
		if network.game_state == network.GameState.OFFLINE:
			additional_data = AdditionalClientData.new(
				custom_is_action_pressed("ui_up") or custom_is_action_pressed("ui_down")
			).to_bytes()
	is_flipped = uddetector.has_overlapping_bodies()

func _physics_process(_delta) -> void:
	if controlled and network.game_state != network.GameState.ONLINE_CLIENT:
		if custom_is_action_pressed("reset") and is_flipped:
			rotation.x = 0
			rotation.z = 0
			position.y += 1.5

func update_color(to=null) -> void:
	hull_material.albedo_color = management.car_color if to == null else to
	hull_material.next_pass.set_shader_parameter("albedo", management.car_color if to == null else to)

func custom_is_action_pressed(action:String) -> bool:
	if network.game_state != network.GameState.OFFLINE:
		if action in pressed_actions:
			return true
		return false
	else:
		return Input.is_action_pressed(action)

func update_client(data:AdditionalClientData):
	exhaust_one.emitting = data.motor_running
	exhaust_two.emitting = data.motor_running
