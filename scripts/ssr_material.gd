@tool
class_name SSRMaterial
extends ShaderMaterial


@export var base_shader:Material:
	set(val):
		base_shader = val
		if val is ShaderMaterial:
			shader = Shader.new()
			shader.code = insert_ssr(val.shader.code)
			
			var params = val.shader.get_shader_uniform_list()
			for param in params:
				var value = val.get_shader_parameter(param.name)
				set_shader_parameter(param.name, value)
	get:
		return base_shader

@export var ssr_propeties:SSRProperties:
	set(val):
		if val == null:
			return
		
		ssr_propeties = val
		var params = val.get_as_shader_parameters()
		for param in params.keys():
			set_shader_parameter(param, params[param])

func insert_ssr(code:String) -> String:
	var variables = RegEx.create_from_string("uniform .+;")
	var last_match = variables.search_all(code)[-1]
	code = code.insert(last_match.get_end(), '\n#include "res://scripts/shaders/ssr.gdshaderinc"')
	
	var fragment = RegEx.create_from_string("void fragment\\(\\) {[\\s\\S]+}")
	var fmatch = fragment.search(code)
	code = code.insert(fmatch.get_end() - 1, "\tALBEDO = applySSR(ALBEDO);\n")
	
	return code
