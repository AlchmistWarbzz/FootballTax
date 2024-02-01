extends Node3D

var ball_scene = preload("res://SubScenes/Ball.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	var task_manager_node
	
	var placeholder_node = get_parent()
	if placeholder_node != null:
		task_manager_node = placeholder_node.get_parent()
	
	if task_manager_node != null:
		task_manager_node.trial_started.connect(_on_task_manager_trial_started)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# manual keypress sequencing
	#if Input.is_action_just_pressed("g") or Input.is_action_just_pressed("s"):
		#instantiate_ball()
	pass

func _on_task_manager_trial_started(is_stop_trial: bool):
	instantiate_ball()
	AudioManager.ball_feeder_launch_sfx.set_pitch_scale(1.0 - (randf() / 10.0))
	AudioManager.ball_feeder_launch_sfx.play()

func instantiate_ball():
	var instance = ball_scene.instantiate()
	$BallSpawnPoint.add_child(instance)
	return instance
