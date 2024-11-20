@tool
class_name SSRProperties
extends Resource

@export_range(0, 1) var ssr_intensity:float = 0.5
@export var ssr_max_distance:float = 15.0
@export_range(1, 1000) var ssr_max_guess_steps:int = 100
@export_range(1, 1000) var ssr_correction_steps:int = 10
@export var ssr_thickness:float = 0.5


func get_as_shader_parameters() -> Dictionary:
	return {
		"ssrIntensity": ssr_intensity,
		"ssrMaxDistance": ssr_max_distance, 
		"ssrMaxGuessSteps": ssr_max_guess_steps, 
		"ssrCorrectionSteps": ssr_correction_steps,
		"ssrThickness": ssr_thickness
	}
