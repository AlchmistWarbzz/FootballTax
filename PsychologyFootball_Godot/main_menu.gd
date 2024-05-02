extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass




func _on_button_pressed():
	LevelManager.load_level(1, 1)
	deactivate()

func _on_button_2_pressed() -> void:
	LevelManager.load_level(1, 2)
	deactivate()

func _on_button_3_pressed() -> void:
	LevelManager.load_level(1, 3)
	deactivate()

func deactivate() -> void:
	hide()
	set_process_unhandled_input(false)
	set_process_input(false)
	set_physics_process(false)
	set_process(false)






