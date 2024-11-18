class_name NetworkSingleton
extends Node


enum GameState{MENU,OFFLINE,ONLINE_SERVER,ONLINE_CLIENT}
var game_state = GameState.MENU

const DEFAULT_PORT = 16000
var PORT_RANGE = range(1001, 50001):
	set(val):
		PORT_RANGE = range(1001, 50001)


# SERVER STARTUP

func start_server() -> void:
	var params = {}
	for param in OS.get_cmdline_args():
		if not param.begins_with("--"):
			continue
		
		match param.trim_prefix("--").get_slice("=", 0): # when given --port=4567 returns port
			"map":
				params["map"] = param.get_slice("=", 1) # when given --map=world returns world
			"port":
				params["port"] = int(param.get_slice("=", 1)) # when given --port=4567 returns 4567
	
	if params.has("map"):
		if not params.has("port"):
			params.port = DEFAULT_PORT
		elif params.port not in PORT_RANGE:
			push_error('Parameter "port" is not a valid integer') 
			get_tree().quit(1)
			return
		
		if not map_scene_valid(params.map):
			push_error("Parameter \"map\" is not valid")
			get_tree().quit(1)
			return
		
		start_dedicated(int(params.port), load(get_map_scene_full_path(params.map)))
	else:
		push_error("Missing parameter \"map\"")
		get_tree().quit(1)

func get_map_scene_full_path(map:String) -> String:
	return "res://scenes/levels/%s.tscn" % map

func map_scene_valid(map:String) -> bool:
	var map_path = get_map_scene_full_path(map).get_basename() + ".tres"
	if not FileAccess.file_exists(map_path) or load(map_path) is not Map:
		return false
	return true

func get_map_scene(map:String) -> PackedScene:
	return load(get_map_scene_full_path(map))

# SERVER CODE

var server_map_path:String
var clients = {} # stored in format client_id:ClientData
var car_scene:PackedScene = load("res://scenes/car.tscn")

const client_full_state_time = 100 # how often is full state sended instead of diff

var destroyed_cube_paths:Array[Array] = []


func start_dedicated(port:int, map:PackedScene) -> void:
	print("Dedicated server on port %d with map resource %s is starting" % [port, map])
	game_state = GameState.ONLINE_SERVER
	
	server_map_path = map.resource_path
	add_child(map.instantiate())
	
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(port, 8)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_disconnected.connect(self.client_left)


@rpc("any_peer", "call_remote", "reliable")
func register_client(client_data_bytes:PackedByteArray) -> void:
	var client_data = ClientData.from_bytes(client_data_bytes)
	
	print("Registering client %d (%s)" % [multiplayer.get_remote_sender_id(), client_data.nickname])
	
	rpc_id(multiplayer.get_remote_sender_id(), "set_client_scene", server_map_path)
	rpc_id(multiplayer.get_remote_sender_id(), "destroy_cubes", destroyed_cube_paths)
	
	var client_car = add_local_car(multiplayer.get_remote_sender_id(), client_data_bytes)
	client_data.car = client_car
	client_data.ticks_to_full_state = client_full_state_time
	
	for client_id in clients.keys():
		rpc_id(multiplayer.get_remote_sender_id(), "add_local_car", client_id, clients[client_id].to_bytes())
		# add all previous cars on new joined client
	
	clients[multiplayer.get_remote_sender_id()] = client_data
	
	for client_id in clients.keys():
		rpc_id(client_id, "add_local_car", multiplayer.get_remote_sender_id(), client_data_bytes)
		# add new joined clients's car to all clients (including the new one)

func client_left(id:int) -> void:
	print("Unregistering client %d (%s)" % [id, clients[id].nickname])
	
	remove_local_car(id)
	clients.erase(id)
	for client_id in clients.keys():
		rpc_id(client_id, "remove_local_car", id)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func client_input(actions:Dictionary) -> void:
	var client = get_client_data(multiplayer.get_remote_sender_id())
	if client == null:
		return
	client.car.pressed_actions = \
		actions.keys().filter(func(action): return actions[action])
	# actions are structured like actions:is_pressed - lambda returns is_pressed of "action" parameter
	
	send_server_state(multiplayer.get_remote_sender_id())

func send_server_state(client_id:int) -> void:
	var client = get_client_data(client_id)
	if client == null:
		return
	var cars = {}
	var blocks = {}
	
	for car in get_child(0).get_node("Cars").get_children(): # serialize cars
		if not (car is VehicleBody3D):
			continue
		
		for obj_path in [".", "FR", "FL", "RR", "RL"]: # for path in object that needs to be saved - car and wheels
			var obj = car.get_node(obj_path)
			var obj_send = {
				"position": obj.position, 
				"rotation": obj.rotation, 
			}
			if obj is Car: # store velocity if a car for speedmeter purposes
				obj_send.linear_velocity = obj.linear_velocity
				obj_send.is_flipped = obj.is_flipped
				obj_send.additional_data = AdditionalClientData.new(
					obj.pressed_actions.has("ui_up") or obj.pressed_actions.has("ui_down")
				).to_bytes()
			cars[[car.name, obj_path]] = obj_send
	
	for wall in get_child(0).get_node("Map/Cubes").get_children(): # serialize cubes
		var wall_id = wall.name.trim_prefix("Wall")
		for cube in wall.get_children():
			var cube_path = [wall_id, cube.name.trim_prefix("Cube")]
			var cube_send = {"position": cube.position, "rotation": cube.rotation}
			if cube.should_be_deleted:
				destroyed_cube_paths.append(cube_path)
				
				delete_local_cube(cube_path)
				for client_rpc_id in clients:
					rpc_id(client_rpc_id, "delete_local_cube", cube_path)
				continue
			
			blocks[cube_path] = cube_send
	
	var state = MapState.new(cars, blocks)
	
	if client.ticks_to_full_state <= 0:
		rpc_id(client_id, "set_client_state", state.to_bytes())
		client.ticks_to_full_state = client_full_state_time
	else:
		rpc_id(client_id, "set_client_state", state.compare_to(client.prev_state).to_bytes())
		client.ticks_to_full_state -= 1
	
	client.prev_state = state

func get_client_data(client_id:int) -> ClientData:
	if not clients.has(client_id):
		return null
	return clients[client_id]


# CLIENT STARTUP

var client_connected = false

func start_client(adress:String, port:int, nickname:String, car_model:String, color:Color) -> int:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(adress, port)
	if err != OK:
		return err
	
	game_state = GameState.ONLINE_CLIENT
	
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = peer
	
	client_connected = false
	
	await get_tree().create_timer(.1).timeout
	rpc_id(1, "register_client", ClientData.new(nickname, car_model, color).to_bytes())
	
	await get_tree().create_timer(1).timeout
	return OK if client_connected else ERR_CANT_CONNECT

@rpc("authority", "call_remote", "reliable")
func set_client_scene(scene_path:String) -> void:
	client_connected = true
	
	get_tree().unload_current_scene()
	add_child(load(scene_path).instantiate())
	get_child(0).process_mode = Node.PROCESS_MODE_DISABLED

@rpc("authority", "call_remote", "reliable")
func destroy_cubes(paths:Array) -> void:
	for path in paths:
		get_cube(path).queue_free()

@rpc("authority", "call_remote", "unreliable")
func set_client_state(state_bytes:PackedByteArray) -> void:
	var state = MapState.from_bytes(state_bytes)
	
	for path in state.cars.keys():
		var obj = get_car(path)
		if obj == null:
			continue
		
		var obj_vals = state.cars[path]
		for prop_path in obj_vals.keys():
			obj.set_indexed(prop_path, obj_vals[prop_path])
		
		var nick_node = obj.get_node_or_null("Nick")
		if nick_node != null:
			nick_node.position = obj.position + Vector3.UP * 2
	
	for path in state.blocks.keys():
		var cube = get_cube(path)
		if cube == null:
			continue
		
		var cube_vals = state.blocks[path]
		for prop_path in cube_vals.keys():
			cube.set(prop_path, cube_vals[prop_path])

func _physics_process(_delta) -> void:
	if game_state == GameState.ONLINE_CLIENT and client_connected:
		if multiplayer.multiplayer_peer.get_connection_status() == multiplayer.multiplayer_peer.CONNECTION_DISCONNECTED:
			terminate_game()
		
		rpc_id(1, "client_input", {
			"ui_up": Input.is_action_pressed("ui_up"),
			"ui_down": Input.is_action_pressed("ui_down"),
			"ui_left": Input.is_action_pressed("ui_left"),
			"ui_right": Input.is_action_pressed("ui_right"),
			"brake": Input.is_action_pressed("brake"),
			"reset": Input.is_action_pressed("reset"),
		})

# BOTH ONLINE MODES

@rpc("authority", "call_remote", "reliable")
func add_local_car(id:int, car_data_bytes:PackedByteArray) -> Car:
	var car_data = ClientData.from_bytes(car_data_bytes)
	
	var client_car = car_scene.instantiate()
	client_car.name = str(id)
	client_car.get_node("Nick").text = " %s " % (car_data.nickname if id != multiplayer.get_unique_id() else "")
	client_car.get_node("Nick").visible = \
		multiplayer.multiplayer_peer.get_connection_status() == ENetMultiplayerPeer.CONNECTION_CONNECTED
	get_child(0).get_node("Cars").add_child(client_car)
	client_car.update_color(car_data.car_color)
	return client_car

@rpc("authority", "call_remote", "reliable")
func remove_local_car(id:int) -> void:
	get_child(0).get_node("Cars/%d" % id).queue_free()

@rpc("authority", "call_remote", "reliable")
func delete_local_cube(path:Array) -> void:
	var cube = get_cube(path)
	if cube != null:
		cube.explode()

func get_car(path) -> Car:
	return get_child(0).get_node_or_null("Cars/%s/%s" % path)

func get_cube(path) -> DestroyableCube:
	return get_child(0).get_node_or_null("Map/Cubes/Wall%s/Cube%s" % path)

# LOCAL GAME

func start_local(map:String, _model:String) -> void:
	game_state = GameState.OFFLINE
	
	get_tree().unload_current_scene.call_deferred()
	add_child(get_map_scene(map).instantiate())
	
	var car = car_scene.instantiate()
	car.name = "Car"
	get_child(0).get_node("Cars").add_child(car)

# MISC

func terminate_game() -> void:
	if game_state == GameState.MENU:
		return
	
	multiplayer.multiplayer_peer.close()
	get_child(0).queue_free()
	game_state = GameState.MENU
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _exit_tree():
	terminate_game()
