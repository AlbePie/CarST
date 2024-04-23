extends RigidBody3D

@export_category("Destroyable Cube")
@export var destroy = true # If the cube will destroy after collision

var time = 0
var fade = false
var detecting = false

var last_pos = Vector3.ZERO
@export var min_length_of_moving_vector = 0.001

@onready var cube = $Mesh
var cube_mat = StandardMaterial3D.new()

var should_be_deleted:bool = false

func _ready():
	last_pos = position
	cube_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cube_mat.albedo_color = Color("a65f03", 1)
	
	cube.material_override = cube_mat


func _on_destroy_timer_timeout():
	$DestroyAnimation.play("cube_fadeout")

func _process(delta):
	if not fade:
		if detecting and (position - last_pos).length() > min_length_of_moving_vector:
			detecting = false
			$DestroyTimer.wait_time = randf_range(1.5, 2.5)
			$DestroyTimer.start()
		last_pos = position
		return
	
	time += delta
	position += basis.y * Vector3(0, delta * 0.25, 0)
	
	cube.material_override.albedo_color.a = 1 - time

func start_fading():
	fade = true
	# custom_integrator = true
	$Collision.disabled = true

func _on_detect_timer_timeout():
	detecting = true

func delete_cube():
	if network.game_state == network.GameState.OFFLINE:
		queue_free()
	else:
		should_be_deleted = true
