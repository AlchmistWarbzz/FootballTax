extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	match LevelManager.task_to_load_UI:
		1:
			$"Stop & Go".visible = true
		2:
			$"Colour Shift".visible = true
		3:
			$"Digit Span".visible = true
	
	await get_tree().create_timer(5.0).timeout
	deactivate()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func deactivate() -> void:
	hide()
	set_process_unhandled_input(false)
	set_process_input(false)
	set_physics_process(false)
	set_process(false)
