extends Node3D

var ball_node = preload("res://SubScenes/Ball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	instantiate_ball(Vector3(0,0,0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func instantiate_ball(pos):
	var instance = ball_node.instantiate()
	instance.position = pos
	add_child(instance)
