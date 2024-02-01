extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
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
