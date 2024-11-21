class_name AdditionalClientData
extends Node


var motor_running:bool


func _init(mrun:bool) -> void:
	motor_running = mrun


func to_bytes() -> PackedByteArray:
	return var_to_bytes([motor_running])

static func from_bytes(arr:PackedByteArray) -> AdditionalClientData:
	return AdditionalClientData.new.callv(bytes_to_var(arr))
