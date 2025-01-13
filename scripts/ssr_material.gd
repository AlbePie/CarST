@tool
class_name SSRMaterial
extends ShaderMaterial


@export_file("*.material") var base_shader_path:
	set(val):
		if not Engine.is_editor_hint():
			return
		base_shader_path = val
		if val != null and FileAccess.file_exists(val):
			var mat = load(val)
			if mat is Material:
				base_shader = mat.duplicate()

@export var base_shader:Material:
	set(val):
		if val != null:
			val.next_pass = null
		
		base_shader = val
		if val is ShaderMaterial:
			shader = Shader.new()
			shader.code = insert_ssr(val.shader.code)
			
			var params = val.shader.get_shader_uniform_list()
			for param in params:
				var value = val.get_shader_parameter(param.name)
				set_shader_parameter(param.name, value)
			
			print("SSR shader has been updated")
	get:
		return base_shader

func insert_ssr(code:String) -> String:
	var variables = RegEx.create_from_string("uniform .+;")
	var last_match = variables.search_all(code)[-1]
	code = code.insert(last_match.get_end(), '\n#include "res://scripts/shaders/ssr.gdshaderinc"')
	
	var fragment = RegEx.create_from_string("void fragment\\(\\) {[\\s\\S]+}")
	var fmatch = fragment.search(code)
	code = code.insert(fmatch.get_end() - 1, "\tALBEDO = applySSR(ALBEDO);\n")
	
	return code


@export var ssr_propeties:SSRProperties:
	set(val):
		if val == null:
			return
		
		ssr_propeties = val
		var params = val.get_as_shader_parameters()
		for param in params.keys():
			set_shader_parameter(param, params[param])

@export var ssr_intensity_texture:Texture2D:
	set(val):
		ssr_intensity_texture = val
		set_shader_parameter("ssrIntensityTexture", val)
