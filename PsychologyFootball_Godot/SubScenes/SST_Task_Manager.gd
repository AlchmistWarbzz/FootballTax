extends Node3D

var ball_feeder_scene = preload("res://SubScenes/Ball_Feeder.tscn")
var defender_scene = preload("res://SubScenes/Defender.tscn")
#var ball_scene = preload("res://SubScenes/Ball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("r"):
		scene_reset()
			
	if Input.is_action_just_pressed("t"):
		scene_setup()

func scene_reset():
	if $PlaceholderBallFeederLeft.get_child_count() != 0:
		$PlaceholderBallFeederLeft/BallFeeder.free()
		
	if $PlaceholderBallFeederRight.get_child_count() != 0:
		$PlaceholderBallFeederRight/BallFeeder.free()

func scene_setup():
	var new_ball_feeder = ball_feeder_scene.instantiate()
	if randf() > 0.5:
		$PlaceholderBallFeederLeft.add_child(new_ball_feeder)
	else:
		$PlaceholderBallFeederRight.add_child(new_ball_feeder)
