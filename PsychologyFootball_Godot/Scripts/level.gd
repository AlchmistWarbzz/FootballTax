extends Node

class_name Level

@export var level_id : int
var level_data : LevelData


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_data = LevelManager.get_level_data_by_id(level_id)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
