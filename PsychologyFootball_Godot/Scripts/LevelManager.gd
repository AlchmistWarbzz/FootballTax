extends Node

var Levels : Array[LevelData]

var main_scene : Node3D = null
var loaded_level : Level = null 
var task_to_load_UI

func unload_level() -> void:
	if is_instance_valid(loaded_level):
		loaded_level.queue_free()
		
	loaded_level = null 

func load_level(level_id : int, task_to_load) -> void:
	print ("Loading Level: %s" % level_id)
	unload_level()
	
	var level_data = get_level_data_by_id(level_id)
	
	if not level_data:
		return
		
	var level_path = "res://%s.tscn" % level_data.level_path
	var level_res := load(level_path)
	
	if level_res:
		loaded_level = level_res.instantiate()
		
		main_scene.add_child(loaded_level)
		
		task_to_load_UI = task_to_load
		match task_to_load:
			1:
				loaded_level.task_to_load = loaded_level.SST_TASK_MANAGER
			2:
				loaded_level.task_to_load = loaded_level.SHIFTING_TASK_MANAGER
			3:
				loaded_level.task_to_load = loaded_level.BDS_TASK_MANAGER
			4:
				loaded_level.task_to_load = loaded_level.main_menu
	else:
		print ("Level does not exist")
	
func get_level_data_by_id(id : int) -> LevelData:
	var level_to_return : LevelData = null
	
	for lvl : LevelData in Levels:
		if lvl.level_id == id:
			level_to_return = lvl
			
	return level_to_return
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

