extends Node

var player_status_path = "res://DATA/STATUS.json"
var player_inventory_path = "res://DATA/INVENTORY.json"

@export_category("Pause Menu")
@export var menu_UI : Control
@export var save_game : Button
@export var exit_game : Button
var pause_game : bool

var access_player : Node3D

func _ready():
	menu_UI.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if(Input.is_action_just_pressed("pause")):
		pause_game = !pause_game

func _process(delta):
	if(pause_game && !menu_UI.visible):
		menu_UI.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED
	if(!pause_game && menu_UI.visible):
		menu_UI.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _JSON_to_dictionary(data_path:String): #returns true if JSON contains key
	var file = FileAccess.get_file_as_string(data_path)
	var dict = JSON.parse_string(file)
	return dict

func _save_JSON_file(data_path:String, game_data):
	var json = JSON.stringify(game_data, "\t")
	var file = FileAccess.open(data_path, FileAccess.WRITE)
	file.store_line(json)
	file.close()
