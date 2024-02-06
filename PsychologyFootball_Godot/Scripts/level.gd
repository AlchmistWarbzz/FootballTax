extends Node

class_name Level

@export var level_id : int
var level_data : LevelData

const SHIFTING_TASK_MANAGER = preload("res://SubScenes/Shifting_Task_Manager.tscn")
const SST_TASK_MANAGER = preload("res://SubScenes/SST_Task_Manager.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_data = LevelManager.get_level_data_by_id(level_id)
	
	await get_tree().create_timer(10.0).timeout
	
	# temp task manager selection
	var instance = SHIFTING_TASK_MANAGER.instantiate()
	add_child(instance)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
