extends CanvasLayer

@onready var car = $"../Car"
@onready var speedmeter = $Speedmeter
@onready var speedlabel = $Speedmeter/Label

var speed_ema = 0
const speed_momentum = 0.01

func _process(delta):
	var velocity = car.linear_velocity.length()
	var speed = clamp(velocity / 40 * 100, 0, 100)
	var current_momentum = pow(speed_momentum, delta)
	speed_ema = speed_ema * current_momentum + speed * (1 - current_momentum)
	speedmeter.value = speed_ema
	speedlabel.text = str(round(speed_ema))
