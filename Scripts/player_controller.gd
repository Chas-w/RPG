extends Node3D
@export_category("Movement")
@export var player_body : RigidBody3D
@export var lower_body_visual : MeshInstance3D
var speed
var input_dir 
var direction 
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.8
const SENSITIVITY = 0.0004
#fov variables
const DEFAULT_FOV = 75.0
const ZOOM_FOV = 50
const SPRINT_FOV = 100

@export_category("Camera")
@export var cam : Camera3D
@export var default_cam : PhantomCamera3D
@export var zoom_cam : PhantomCamera3D
@export var center_point : Marker3D
@export var follow_buffer: Vector4
@export var cam_follow_weight : float
@export var cam_origin : Node3D
@export var zoomed_origin : Node3D
var zoomed : bool

@export_category("Player Data Info")
@export var health : float
@export var morality : float
@export var gun : MeshInstance3D
var status_dictionary
var inventory_dictionary #consider inventory in sep. node
var database

@export_category("States")
enum Move_State{Idle,Moving,Null}
@export var move_state : Move_State = Move_State.Idle
enum Interact_State{Talk,Threaten, Inspect, Attack, In_Menu, Null}
@export var interact_state : Interact_State = Interact_State.Null

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	speed = WALK_SPEED
	for game_obj in get_tree().get_nodes_in_group("Database"): #assign database
		database = game_obj
	status_dictionary = database._JSON_to_dictionary(database.player_status_path)
	inventory_dictionary = database._JSON_to_dictionary(database.player_inventory_path)
	health = status_dictionary.Health
	morality = status_dictionary.Morality

func _process(delta):
	input_dir = Input.get_vector("left", "right", "up", "down")
	direction = (player_body.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	#gun and zoom
	if (Input.is_action_just_pressed("gun")):
		inventory_dictionary.Permanent.Gun.Active = !inventory_dictionary.Permanent.Gun.Active
		gun.visible = !gun.visible
	_handle_zoom(delta)
	
	#camera
	_handle_follow_cam(delta)
	
	#set up moving
	if(direction && move_state != Move_State.Moving):
		_set_move_state(Move_State.Moving)

func _physics_process(delta):
	#rotation
	player_body.rotation.y = cam_origin.rotation.y
	# jump
	if(Input.is_action_just_pressed("jump") && player_body.linear_velocity.y <= 0):
		player_body.linear_velocity.y += JUMP_VELOCITY * 45 * delta
	#visual 
	lower_body_visual.global_position = player_body.global_position #only when the rotation has reached a certain edge
	
	#movement state machine
	match(move_state):
		Move_State.Moving:
			_handle_movement(delta)
			pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		cam_origin.rotation.x -= event.relative.y * SENSITIVITY
		# Prevent the camera from rotating too far up or down.
		cam_origin.rotation.x = clampf(cam_origin.rotation.x, -90, 90)
		cam_origin.rotation.y += -event.relative.x * SENSITIVITY

func _handle_movement(delta):
		# Handle Sprint.
	if(!zoomed):
		if Input.is_action_pressed("sprint"):
			speed = SPRINT_SPEED
		else:
			speed = WALK_SPEED
	# Get the input direction and handle the movement/deceleration.
	if direction:
		player_body.linear_velocity.x = direction.x *  speed
		player_body.linear_velocity.z = direction.z * speed
	else:
		player_body.linear_velocity.x = lerp(player_body.linear_velocity.x, direction.x * speed, delta * 7.0)
		player_body.linear_velocity.z = lerp(player_body.linear_velocity.z, direction.z * speed, delta * 7.0)
	player_body.position.normalized()
	#exit move
	if(player_body.linear_velocity.x <= 0 && player_body.linear_velocity.y <= 0):
		_set_move_state(Move_State.Idle)

func _handle_zoom(delta):
	if(Input.is_action_pressed("zoom")):
		if (inventory_dictionary.Permanent.Gun.Active && interact_state != Interact_State.Threaten):
			zoom_cam.priority = 10
			default_cam.priority = 0
			_set_interact_state(Interact_State.Threaten)
		cam.fov = lerpf(cam.fov, ZOOM_FOV, delta * 2)
		if(!zoomed):
			zoomed = true
	else:
		if (interact_state == Interact_State.Threaten):
			zoom_cam.priority = 0
			default_cam.priority = 10
			_set_interact_state(Interact_State.Null)
		cam.fov = lerpf(cam.fov, DEFAULT_FOV, delta * 2)
		if(zoomed):
			zoomed = false

func _handle_follow_cam(delta): #needs some tweaking later, maybe figure out some ease?
	##zoom cam
	zoomed_origin.global_rotation = cam_origin.global_rotation
	##x
	if (absf(player_body.global_position.x - cam_origin.global_position.x) > follow_buffer.x):
		cam_origin.global_position.x = lerpf(cam_origin.global_position.x, player_body.global_position.x, cam_follow_weight/2 * delta)
	##y
	cam_origin.global_position.y = lerpf(cam_origin.global_position.y, center_point.global_position.y, cam_follow_weight * delta)
	##z
	cam_origin.global_position.z = lerpf(cam_origin.global_position.z, center_point.global_position.z, cam_follow_weight * delta)
	cam_origin.position.normalized()

func _set_move_state(next_move_state:int):
	var prev_move_state := move_state
	move_state = next_move_state
		
	#check last state
	match(prev_move_state):
		pass
	#check upcoming state
	match(next_move_state):
		Move_State.Moving:
			pass

func _set_interact_state(next_interact_state:int):
	var prev_interact_state := interact_state
	interact_state = next_interact_state
		
	#check last state
	match(prev_interact_state):
		Interact_State.Threaten:
			pass
	#check upcoming state
	match(next_interact_state):
		Interact_State.Threaten:
			pass

func _update_JSON_data():
	status_dictionary.Health = health
	status_dictionary.Morality = morality
	
	status_dictionary.Position[0] = global_position.x
	status_dictionary.Position[1] = global_position.y
	status_dictionary.Position[2] = global_position.z
	
	database._save_JSON_file(database.player_status_path, status_dictionary)
	database._save_JSON_file(database.player_inventory_path, inventory_dictionary)
