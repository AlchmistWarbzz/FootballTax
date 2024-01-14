extends Node3D

var ball_node = preload("res://SubScenes/Ball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	instantiate_ball()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func instantiate_ball():
	var instance = ball_node.instantiate()
	add_child(instance)
