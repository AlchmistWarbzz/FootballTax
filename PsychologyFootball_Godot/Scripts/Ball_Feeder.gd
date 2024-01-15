extends Node3D

var ball_node = preload("res://SubScenes/Ball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var ball_to_spawn = false
	
	if Input.is_action_just_pressed("ui_accept"):
		ball_to_spawn = true
		
	if ball_to_spawn:
		instantiate_ball($BallSpawnPoint.position)

func instantiate_ball(pos):
	var instance = ball_node.instantiate()
	instance.position = pos
	add_child(instance)
