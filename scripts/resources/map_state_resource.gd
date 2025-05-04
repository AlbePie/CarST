class_name MapState
extends Resource


class TransformRecord extends Resource:
	var position: Vector3
	var rotation: Vector3
	
	func _init(p: Vector3, r: Vector3):
		position = p
		rotation = r
	
	func to_bytes() -> PackedByteArray:
		return PackedFloat32Array([
			position.x, position.y, position.z,
			rotation.x, rotation.y, rotation.z
		]).to_byte_array()
	
	static func from_bytes(data: PackedByteArray) -> TransformRecord:
		var floatarray = data.to_float32_array()
		return TransformRecord.new(
			Vector3(
				floatarray[0],
				floatarray[1],
				floatarray[2]
			),
			Vector3(
				floatarray[3],
				floatarray[4],
				floatarray[5]
			)
		)

class CarRecord extends Resource:
	var transform: TransformRecord
	var is_flipped: bool
	var motor_running: bool
	var wheels:Dictionary[Car.Wheels, TransformRecord]
	
	func to_bytes() -> PackedByteArray:
		var wheels_bytes:Array[PackedByteArray]
		
		for wheel in wheels:
			wheels_bytes.append(PackedByteArray([wheel]) + wheels[wheel].to_bytes())
		
		return management.encode_packed_byte_arrays([
			transform.to_bytes(),
			PackedByteArray([int(is_flipped), int(motor_running)]),
			management.encode_packed_byte_arrays(wheels_bytes)
		])
	
	static func from_bytes(data: PackedByteArray) -> CarRecord:
		var car_record = CarRecord.new()
		var bytearrays = management.decode_packed_byte_arrays(data)
		
		car_record.transform = TransformRecord.from_bytes(bytearrays[0])
		car_record.is_flipped = bytearrays[1][0]
		car_record.motor_running = bytearrays[1][1]
		
		for wheel_bytes in management.decode_packed_byte_arrays(bytearrays[2]):
			car_record.wheels[wheel_bytes[0]] = TransformRecord.from_bytes(wheel_bytes.slice(1))
		
		return car_record

var cars:Dictionary[String, CarRecord] = {}
var blocks:Dictionary[String, TransformRecord] = {}


func _init(cars_init:Dictionary[String, CarRecord] = {}, blocks_init:Dictionary[String, TransformRecord] = {}) -> void:
	cars = cars_init
	blocks = blocks_init


func to_bytes() -> PackedByteArray:
	var cars_bytes:Array[PackedByteArray]
	for car in cars:
		cars_bytes.append(car.to_ascii_buffer())
		cars_bytes.append(cars[car].to_bytes())
	
	var block_bytes:Array[PackedByteArray]
	for block in blocks:
		block_bytes.append(block.to_ascii_buffer())
		block_bytes.append(blocks[block].to_bytes())
	
	return management.encode_packed_byte_arrays([
		management.encode_packed_byte_arrays(
			cars_bytes
		),
		management.encode_packed_byte_arrays(
			block_bytes
		)
	])

static func from_bytes(data:PackedByteArray) -> MapState:
	var cars_and_blocks = management.decode_packed_byte_arrays(data)
	
	var cars_bytes:Array[PackedByteArray] = management.decode_packed_byte_arrays(cars_and_blocks[0])
	@warning_ignore("shadowed_variable")
	var cars:Dictionary[String, CarRecord] = {}
	for idx in range(len(cars_bytes)):
		if idx % 2:
			continue
		
		cars[cars_bytes[idx].get_string_from_ascii()] = CarRecord.from_bytes(cars_bytes[idx + 1])
	
	var block_bytes:Array[PackedByteArray] = management.decode_packed_byte_arrays(cars_and_blocks[1])
	@warning_ignore("shadowed_variable")
	var blocks:Dictionary[String, TransformRecord] = {}
	for idx in range(len(block_bytes)):
		if idx % 2:
			continue
		
		blocks[block_bytes[idx].get_string_from_ascii()] = TransformRecord.from_bytes(block_bytes[idx + 1])
	
	return MapState.new(cars, blocks)
