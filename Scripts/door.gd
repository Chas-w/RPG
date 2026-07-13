extends Node3D
@export var locked : bool
@export var lock_picking : Control
var player

func _ready():
	if (!locked):
		lock_picking.queue_free() #if the door isn't locked get rid of this node
	else:
		lock_picking.visible = false #hide this node
	

func _process(delta):
	if (player != null):
		print(player)

func _on_open_trigger_body_entered(body):
	if(body.is_in_group("Player")):
		player = body.get_parent()


func _on_open_trigger_body_exited(body):
	player = null # Replace with function body.
