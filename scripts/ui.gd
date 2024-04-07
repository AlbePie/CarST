extends CanvasLayer

@export_group("Node References")
@export var car:VehicleBody3D
@export var speedmeter:ProgressBar
@export var speedlabel:Label
@export var flippedlabel:Label

var flipped_flashing = true
var flash_tween:Tween

var speed_ema = 0
const speed_momentum = 0.01

func _process(delta):
	var velocity = Vector2(car.linear_velocity.x, car.linear_velocity.z).length()
	var speed = clamp(velocity / 40 * 100, 0, 100)
	var current_momentum = pow(speed_momentum, delta)
	speed_ema = speed_ema * current_momentum + speed * (1 - current_momentum)
	speedmeter.value = speed_ema
	speedlabel.visible_ratio = 1
	speedlabel.text = "%d" % round(speed_ema)
	
	if not car.is_flipped:
		if flipped_flashing:
			stop_flipped_flashing()
			flipped_flashing = false
	else:
		if not flipped_flashing:
			start_flipped_flashing()
			flipped_flashing = true

func start_flipped_flashing():
	stop_flipped_flashing()
	
	flash_tween = create_tween()
	flash_tween.tween_property(flippedlabel, "visible", false, 0)
	flash_tween.tween_interval(0.5)
	flash_tween.tween_property(flippedlabel, "visible", true, 0)
	flash_tween.tween_interval(0.5)
	flash_tween.tween_callback(self.start_flipped_flashing)

func stop_flipped_flashing():
	if flash_tween != null:
		flash_tween.stop()
		flippedlabel.hide()
		flash_tween = null

func _on_quit_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_reset_pressed():
	get_tree().reload_current_scene()
