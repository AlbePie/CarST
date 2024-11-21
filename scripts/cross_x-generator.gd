# THIS SCRIPT IS NOT USED IN-GAME, IT'S A TOOL TO GENERATE THE X AND T CROSS MODEL
@tool
extends MeshInstance3D


@export_enum("X", "T") var mode:String = "X"
@export var compile = false:
	set(val):
		compile = false
		if val:
			do_compiling()

func do_compiling():
	mesh = ArrayMesh.new()
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	
	for x_sign in [-1, 1]:
		for z_sign in [-1, 1]:
			verts.append(Vector3(4 * x_sign, 0, 3.5 * z_sign))
			uvs.append(Vector2(0.5 + 4/8. * x_sign, 0.5 + 3.5/8. * z_sign))
			normals.append(Vector3(0, 1, 0))
			
			if z_sign == 1 and mode == "T":
				continue
				
			verts.append(Vector3(3.5 * x_sign, 0, 3.5 * z_sign))
			uvs.append(Vector2(0.5 + 3.5/8. * x_sign, 0.5 + 3.5/8. * z_sign))
			normals.append(Vector3(0, 1, 0))
			
			verts.append(Vector3(3.5 * x_sign, 0, 4 * z_sign))
			uvs.append(Vector2(0.5 + 3.5/8. * x_sign, 0.5 + 4/8. * z_sign))
			normals.append(Vector3(0, 1, 0))
	
	var indices
	if mode == "X":
		indices = PackedInt32Array([
			1, 2, 8,
			1, 8, 7,
			0, 6, 3,
			3, 6, 9,
			5, 4, 10,
			5, 10, 11,
		])
	else:
		indices = PackedInt32Array([
			1, 2, 6,
			1, 6, 5,
			0, 4, 3,
			3, 4, 7,
		])
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	ResourceSaver.save(mesh, "res://models/cross_%s.tres" % mode.to_lower(), ResourceSaver.FLAG_NONE)
