# THIS SCRIPT IS NOT USED IN-GAME, IT'S A TOOL TO GENERATE THE TURN MODEL
@tool
extends MeshInstance3D


@export var compile = false:
	set(val):
		compile = false
		if val:
			do_compiling()

func do_compiling():
	mesh = ArrayMesh.new()
	
	var inner_radius = 8.5
	var outer_radius = 15.5
	var segments = 16
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	for i in range(segments + 1):
		var u = float(i) / segments
		for j in range(1 + 1):
			var v = float(j)
			var radius = (1 - v) * outer_radius + v * inner_radius
			var x = sin(PI/2 + PI / 2 * (u + 0)) * radius - 4
			var z = cos(PI/2 + PI / 2 * (u + 0)) * radius + (inner_radius + outer_radius) / 2
			verts.append(Vector3(x, 0, z))
			uvs.append(Vector2(1 - u, v))
			normals.append(Vector3(0, 1, 0))
		if i:
			indices.append(2*i - 2)
			indices.append(2*i - 1)
			indices.append(2*i - 0)
			indices.append(2*i - 0)
			indices.append(2*i - 1)
			indices.append(2*i + 1)
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	ResourceSaver.save(mesh, "res://models/turn.tres", ResourceSaver.FLAG_NONE)
