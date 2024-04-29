extends Resource
class_name MapState

var cars:Dictionary = {}
var blocks:Dictionary = {}

func _init(cars_init:Dictionary = {}, blocks_init:Dictionary = {}):
	cars = cars_init
	blocks = blocks_init

@warning_ignore("unused_parameter")
func compare_to(other:MapState):
	var compared_cars = {}
	var compared_blocks = {}
	
	for car in cars.keys():
		if not other.cars.has(car):
			compared_cars[car] = cars[car]
			continue
		
		var this_car:Dictionary = cars[car]
		var other_car:Dictionary = other.cars[car]
		var compared_car = {}
		for property_path in this_car.keys():
			if not other_car.has(property_path) or this_car[property_path] != other_car[property_path]:
				compared_car[property_path] = this_car[property_path]
		
		compared_cars[car] = compared_car
	
	for block in blocks.keys():
		if not other.blocks.has(block):
			compared_blocks[block] = blocks[block]
			continue
		
		var this_block:Dictionary = blocks[block]
		var other_block:Dictionary = other.blocks[block]
		var compared_block = {}
		for property_path in this_block.keys():
			if not other_block.has(property_path) or this_block[property_path] != other_block[property_path]:
				compared_block[property_path] = this_block[property_path]
		
		compared_blocks[block] = compared_block
	
	return MapState.new(compared_cars, compared_blocks)


func to_bytes():
	return var_to_bytes_with_objects({"cars": var_to_str(cars), "blocks": var_to_str(blocks)})

static func from_bytes(data:PackedByteArray): # wrong usage is not handled
	var unpacked = bytes_to_var_with_objects(data)
	return MapState.new(str_to_var(unpacked.cars), str_to_var(unpacked.blocks))
