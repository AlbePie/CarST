class_name MinigameManager
extends Node3D

# -- get and set state --
var state:
	get:
		if network.game_state == network.GameState.ONLINE_CLIENT:
			return
	set(val):
		if not (val is PackedByteArray):
			return
		
		set_state_from(val)

func set_state_from(arr:PackedByteArray) -> void:
	var state_new = bytes_to_var_with_objects(arr)

# -- minigames --

enum Minigames{FREE_RIDE,RACE,CRASH,STUNTS}
var minigame_mode:Minigames = Minigames.FREE_RIDE

# voting

const min_start_percent = 70/100.

func vote_for_minigame(amout:int, minigame:Minigames) -> void:
	if amout / get_car_amount() > min_start_percent:
		print("TODO")

func get_car_amount() -> float:
	return len(get_node("../Cars").get_children().filter(func(car): return car is Car))
