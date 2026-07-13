extends Node3D
@export var locked : bool
@export var lock_picking : Control

func _ready():
	lock_picking.visible = false
