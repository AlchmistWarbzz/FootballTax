extends Node3D

var ball_feeder_scene = preload("res://SubScenes/Ball_Feeder.tscn")
var defender_scene = preload("res://SubScenes/Defender.tscn")
var fixation_cone_scene = preload("res://SubScenes/Fixation_Cone.tscn")
var teammate_scene = preload("res://SubScenes/Teammate.tscn")

var ticks_msec_bookmark = 0
const MSEC_BETWEEN_TRIALS = 3000

enum scene_state {WAIT, READY, GO_TRIAL, STOP_TRIAL}
var current_state = scene_state.WAIT

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("r"):
		scene_reset()
	
	if Input.is_action_just_pressed("t"):
		scene_ready()
	
	if Input.is_action_just_pressed("g"):
		trial_start(false)
	
	if Input.is_action_just_pressed("s"):
		trial_start(true)
	
	# tick-based scene sequencing
	

func scene_reset():
	# remove left ball feeder
	if $PlaceholderBallFeederLeft.get_child_count() != 0:
		$PlaceholderBallFeederLeft/BallFeeder.free()
	
	# remove left ball feeder
	if $PlaceholderBallFeederRight.get_child_count() != 0:
		$PlaceholderBallFeederRight/BallFeeder.free()
	
	# remove teammate
	if $PlaceholderFixation.get_child_count() != 0:
		$PlaceholderFixation/Teammate.free()
	
	# remove and respawn left defender
	if $PlaceholderDefenderLeft.get_child_count() != 0:
		$PlaceholderDefenderLeft/Defender.free()
		var new_defender_left = defender_scene.instantiate()
		$PlaceholderDefenderLeft.add_child(new_defender_left)
	
	# remove and respawn left defender
	if $PlaceholderDefenderRight.get_child_count() != 0:
		$PlaceholderDefenderRight/Defender.free()
		var new_defender_right = defender_scene.instantiate()
		$PlaceholderDefenderRight.add_child(new_defender_right)

func scene_ready():
	# spawn new ball feeder, randomly choosing left or right side
	var new_ball_feeder = ball_feeder_scene.instantiate()
	if randf() > 0.5:
		$PlaceholderBallFeederLeft.add_child(new_ball_feeder)
	else:
		$PlaceholderBallFeederRight.add_child(new_ball_feeder)
	
	# spawn fixation cone
	var new_fixation_cone = fixation_cone_scene.instantiate()
	$PlaceholderFixation.add_child(new_fixation_cone)

func trial_start(is_stop_trial: bool):
	# remove fixation cone
	if $PlaceholderFixation.get_child_count() != 0:
		$PlaceholderFixation/FixationCone.free()
	
	# spawn teammate
	var new_teammate = teammate_scene.instantiate()
	$PlaceholderFixation.add_child(new_teammate)

#func stop_trial_start():
	## remove fixation cone
	#if $PlaceholderFixation.get_child_count() != 0:
		#$PlaceholderFixation/FixationCone.free()

