extends Node3D

@export_category("Character Traits")
@export var random_traits : bool
@export var who : String
@export_range(0,100,1) var grit : float
@export_range(0,100,1) var aggression : float
@export_range(0,100,1) var morality : float

@export var random_status : bool
@export var status : Dictionary 
