extends Control
@export_category("Visuals")
@export var lock_background : TextureRect
@export var pick : Node2D 
@export var stabilizer :TextureRect

@export_category("Pick Zone")
@export var limit : Area2D
@export var safety : float
@export var pick_limits : Vector2

var move_pick : bool 
var pick_speed : float = 4
var higher : bool
var mouse_speed : float

var in_range : bool

var solve_speed_max = 5
var solve_speed_min = .1
var solve_speed = 1
var solved : bool

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var new_rot = (randf_range(deg_to_rad(pick_limits.x), deg_to_rad(pick_limits.y)))
	limit.rotation = new_rot
	print(rad_to_deg(new_rot))
	print(rad_to_deg(limit.rotation))
	
	limit.scale.y = randf_range(1,safety)

func _process(delta):
	_handle_pick_rotation()
	print(rad_to_deg(pick.rotation))
	print((rad_to_deg(limit.rotation)))
	
	if (Input.is_action_pressed("interact")):
		if (lock_background.rotation > deg_to_rad(-90)):
			lock_background.rotation -= delta * solve_speed
		else:
			solved = true
			print("solved")
		if(in_range):
			#lock_background.rotation = lerp_angle(lock_background.rotation, deg_to_rad(-90), delta  3)
			print(lock_background.rotation)
		else:
			print("INCORRECT")
	else:
		if(lock_background.rotation < 0):
			lock_background.rotation += delta * 3
		else:
			return

func _handle_pick_rotation():
	if (move_pick):
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

func _on_pick_check_area_entered(area):
	if(area.is_in_group("limit")):
		in_range = true

func _on_pick_check_area_exited(area):
	if(area.is_in_group("limit")):
		in_range = false
