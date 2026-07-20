extends RigidBody3D

@export var mount_location : Marker3D
@export var dismount_location : Marker3D
@export var interact_prompt : Label3D
var player
var can_mount : bool 
var database

@export_category("States")
var mounted : bool
@export var use_stamina : bool
enum Mount_State{Idle,Moving, Null}
@export var mount_state : Mount_State = Mount_State.Idle
var mount_buffer_max = 1
var mount_buffer

@export_category("Movement")
@export_range(1,20,1) var mount_default_speed : float
@export_range(1,20,1) var mount_sprint_speed : float
var strafe_speed : float
var mount_speed : float
@export_range(0,100,1) var max_stamina : float
##what stamina is subtracted from sprinting
@export_range(0,50,1) var effort : float
var stamina : float
var stamina_fully_depleated : bool
var stamina_fully_recovered : bool
var sprinting : bool

# Called when the node enters the scene tree for the first time.
func _ready():
	mount_buffer = mount_buffer_max
	interact_prompt.text = "E"
	stamina = max_stamina
	strafe_speed = mount_default_speed/3
	mount_speed = mount_default_speed
	for game_obj_1 in get_tree().get_nodes_in_group("Player Controller"): #assign database
		player = game_obj_1
	for game_obj in get_tree().get_nodes_in_group("Database"): #assign database
		database = game_obj

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	freeze = !mounted
	if(can_mount):
		if(Input.is_action_just_pressed("interact")):
			if(!mounted):
				mounted = true
				player._set_move_state(player.Move_State.Mounted)
	if(mounted):
		player.player_body.global_position = mount_location.global_position
		if(player.direction && mount_state != Mount_State.Moving):
			_set_mount_state(Mount_State.Moving)
		if(mount_buffer > 0):
			mount_buffer -= delta
		else:
			if(Input.is_action_just_pressed("interact") && player.move_state ==  player.Move_State.Mounted):
				mounted = false
				player._set_move_state(player.Move_State.Idle)
				player.player_body.global_position = dismount_location.global_position
				_set_mount_state(Mount_State.Null)
				mount_buffer = mount_buffer_max


func _physics_process(delta):
	if (mounted):
		rotation.y = player.lower_body_visual.rotation.y
		match(mount_state):
			Mount_State.Idle:
				pass
			Mount_State.Moving:
				_handle_mount_movement()
				pass

func _handle_mount_movement():
	if (Input.is_action_pressed("sprint") && stamina > 0 && !stamina_fully_depleated):
		mount_speed = mount_sprint_speed
		stamina -= effort * get_process_delta_time()
		sprinting = true
	else:
		sprinting = false
		mount_speed = mount_default_speed
	# Get the input direction and handle the movement/deceleration.
	if player.direction:
		if(absf(player.input_dir.x) >= .96):
			mount_speed = strafe_speed
		else:
			mount_speed = mount_default_speed
		linear_velocity.x = player.direction.x *  mount_speed
		linear_velocity.z = player.direction.z * mount_speed
	else:
		linear_velocity.x = lerp(linear_velocity.x, player.direction.x * mount_speed, get_process_delta_time()   * 7.0)
		linear_velocity.z = lerp(linear_velocity.z, player.direction.z * mount_speed, get_process_delta_time()   * 7.0)
	position.normalized()
	#exit move
	if(linear_velocity.x <= 0 && linear_velocity.y <= 0):
		_set_mount_state(Mount_State.Idle)

func _set_mount_state(next_state:int):
	var prev_state := mount_state
	mount_state = next_state
		
	#check last state
	match(prev_state):
		Mount_State.Null:
			pass
		Mount_State.Moving:
			pass
		Mount_State.Idle:
			pass
	#check upcoming state
	match(next_state):
		Mount_State.Null:
			linear_velocity.x = 0
			linear_velocity.z = 0
			pass
		Mount_State.Moving:
			pass
		Mount_State.Idle:
			pass
func _on_mount_trigger_body_entered(body):
	if (body.is_in_group("Player")):
		can_mount = true
		interact_prompt.visible = true

func _on_mount_trigger_body_exited(body):
	if (body.is_in_group("Player")):
		can_mount = false
		interact_prompt.visible = false
