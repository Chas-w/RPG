extends Control
@export_category("Visuals")
@export var lock_background : TextureRect
@export var pick : Node2D 
@export var stabilizer :TextureRect

@export_category("Pick Zone")
@export var limit : Node2D
##how easy to get in range
@export_range(2,20,.5) var safety : float
@export var pick_limits : Vector2
@export var pick_tip : Node2D
@export var limit_tip : Node2D
@export var pivot : Node2D
@export var pick_amount : int
var move_pick : bool 
var pick_speed : float = 4
var higher : bool
var mouse_speed : float

##the target angle between limit and pick
var solution_value : float = 90
## how long the pick has to move before breaking
var pick_time_limit_max : float = 2
var pick_time_limit :float
var break_pick : bool
var break_buffer_max : float = .5
var break_buffer 

var solve_speed_max = 5
var solve_speed_min = .1
var solve_speed = 1
var solving : bool
var reset : bool 

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var new_rot = (randf_range(deg_to_rad(pick_limits.x), deg_to_rad(pick_limits.y)))
	limit.rotation = new_rot
	limit.scale.y = randf_range(1,safety)
	break_buffer = break_buffer_max
	pick_time_limit = pick_time_limit_max

func _process(delta):
	_handle_pick_rotation()
	_handle_solver()
	if (break_pick):
		_handle_break_pick()

func _handle_solver():
	if (Input.is_action_pressed("interact") && pick_amount > 0):
		solving = true
		if(_get_angle(pivot.global_position,pick_tip.global_position, limit_tip.global_position) <= 90 + safety && _get_angle(pivot.global_position,pick_tip.global_position, limit_tip.global_position) >= 90 - safety):
			if (lock_background.rotation > deg_to_rad(-90)):
				lock_background.rotation -=  get_process_delta_time() * solve_speed
		else:
			var time_modifier = (90 - _get_angle(pivot.global_position,pick_tip.global_position, limit_tip.global_position))/3
			if (pick_time_limit > 0):
				pick_time_limit -= get_process_delta_time() * time_modifier
				if (lock_background.rotation > deg_to_rad(-90)):
					lock_background.rotation -=  get_process_delta_time() * solve_speed
			else:
				break_pick = true
	else:
		solving = false
		if (!break_pick):
			if(lock_background.rotation < 0):
				lock_background.rotation +=  get_process_delta_time() * 3
			if(pick_time_limit != pick_time_limit_max):
				pick_time_limit = pick_time_limit_max

func _handle_break_pick():
	if(solving):
		if(break_buffer > 0):
			break_buffer -= get_process_delta_time()
		else:
			if(lock_background.rotation < 0):
				lock_background.rotation +=  get_process_delta_time() 
			else:
				break_pick = false
				break_buffer = break_buffer_max
				pick_amount -= 1
				print(pick_amount)
	else:
		break_pick = false
		break_buffer = break_buffer_max
		#break animation

	pass

func _handle_pick_rotation():
	if (move_pick && !solving && !break_pick):
		if(higher):
			pick.rotation += deg_to_rad(pick_speed * mouse_speed * get_process_delta_time())
		else:
			pick.rotation -= deg_to_rad(pick_speed * mouse_speed * get_process_delta_time())
	move_pick = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_speed = absf(event.relative.x)
		move_pick = true
		if(event.relative.x > 0):
			higher = true
		else:
			higher = false

func _get_angle(vec1 : Vector2, vec2 : Vector2, vec3 : Vector2):
	var length_a = sqrt(pow(vec2.x - vec1.x, 2) + pow(vec2.y - vec1.y,2))
	var length_b = sqrt(pow(vec3.x - vec2.x,2) + pow(vec3.y - vec2.y, 2))
	var length_c = sqrt(pow(vec3.x - vec1.x,2) + pow(vec3.y - vec1.y, 2))
	
	var calculation = ((length_a * length_a) + (length_b * length_b) - (length_c * length_c)) / (2 * length_a * length_b)
	return rad_to_deg(acos(calculation)) 
