@tool
class_name MinigameStartZone
extends Node3D


@export var zone_size:int = 5:
	set(val):
		if val < 5:
			return
		
		$Zone/Mesh.mesh.size.x = val
		$BordersAndText/Border1.position.x = -0.5 - val / 2.
		$BordersAndText/Border2.position.x = 0.5 + val / 2.
		$BordersAndText/TextLine.size.x = val + 1
		
		var col = BoxShape3D.new()
		col.size = Vector3(val, 3, 3)
		$Zone/CollisionShape3D.shape = col
		
		zone_size = val

@export var zone_color:Color = Color.WHITE:
	set(val):
		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		mat.albedo_color = Color(val.r, val.g, val.b, 0.75)
		$Zone/Mesh.mesh.material = mat
		
		zone_color =Color(val.r, val.g, val.b, 1)

@export var minigame_name:String:
	set(val):
		$BordersAndText/TextLine/Text.text = val
		
		minigame_name = val

var bodies_in = []

signal car_amount_changed(amount:int)


func _on_zone_body_entered(body) -> void:
	if body is Car:
		bodies_in.append(body)
		car_amount_changed.emit(len(bodies_in))

func _on_zone_body_exited(body) -> void:
	if body is Car:
		bodies_in.erase(body)
		car_amount_changed.emit(len(bodies_in))
