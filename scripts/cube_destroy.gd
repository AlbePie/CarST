class_name DestroyableCube
extends RigidBody3D

@export_category("Destroyable Cube")
@export var destroy = true # If the cube will destroy after collision

var detecting = false

var last_pos = Vector3.ZERO
@export var min_length_of_moving_vector = 0.001

@export var cube:MeshInstance3D
@export var collision:CollisionShape3D
@export var particles:GPUParticles3D

var should_be_deleted:bool = false

func _ready() -> void:
	last_pos = position


func _on_destroy_timer_timeout() -> void:
	delete_cube()

func _process(_delta) -> void:
	if detecting and (position - last_pos).length() > min_length_of_moving_vector:
		detecting = false
		$DestroyTimer.wait_time = randf_range(1.5, 2.5)
		$DestroyTimer.start()
	
	last_pos = position

func _on_detect_timer_timeout() -> void:
	detecting = true

func delete_cube() -> void:
	if network.game_state == network.GameState.OFFLINE:
		explode()
	else:
		should_be_deleted = true

func explode():
	if network.game_state != network.GameState.ONLINE_SERVER:
		cube.hide()
		collision.queue_free()
		particles.emitting = true
		await particles.finished
	queue_free()
