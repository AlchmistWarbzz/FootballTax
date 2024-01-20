extends Node3D

var ball_scene = preload("res://SubScenes/Ball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var ball_to_spawn = false
	
	if Input.is_action_just_pressed("s"):
		ball_to_spawn = true
		
	if ball_to_spawn:
		var spawned_ball = instantiate_ball()
		spawned_ball.position = $BallSpawnPoint.position
		#spawned_ball.get_script().kick()

func instantiate_ball():
	var instance = ball_scene.instantiate()
	add_child(instance)
	return instance
