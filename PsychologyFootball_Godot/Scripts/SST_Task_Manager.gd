extends Node3D

# spawnables
var ball_feeder_scene = preload("res://SubScenes/Ball_Feeder.tscn")
var defender_scene = preload("res://SubScenes/Defender.tscn")
var fixation_cone_scene = preload("res://SubScenes/Fixation_Cone.tscn")
var teammate_scene = preload("res://SubScenes/Teammate.tscn")

# time
const TICKS_BETWEEN_TRIALS_MSEC = 3000
const READY_TICKS_MSEC = 1000
const TRIAL_TICKS_MSEC = 500
@onready var ticks_msec_bookmark = 0

# states
enum scene_state {WAIT, READY, GO_TRIAL, STOP_TRIAL}
# TODO create dict of states and corresponding funcs for defensive prog.
@onready var current_state = scene_state.WAIT

# signals
signal trial_started
signal ball_kicked
signal go_trial_failed
signal stop_trial_failed

# flags
var is_feeder_left: bool = false
var is_go_trial_passed = false

func _ready():
	scene_reset() # ensure scene and scene_state are in agreement

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Manual Keypress Sequencing
	if Input.is_action_just_pressed("r"):
		scene_reset()
	
	if Input.is_action_just_pressed("t"):
		scene_ready()
	
	if Input.is_action_just_pressed("g"):
		scene_trial_start(false)
	
	if Input.is_action_just_pressed("s"):
		scene_trial_start(true)
	
	# tick-based scene sequencing
	match current_state:
		scene_state.WAIT:
			if (Time.get_ticks_msec() - ticks_msec_bookmark) > TICKS_BETWEEN_TRIALS_MSEC:
				# wait time is up
				scene_ready()
				current_state = scene_state.READY
				ticks_msec_bookmark = Time.get_ticks_msec()
		
		scene_state.READY:
			if (Time.get_ticks_msec() - ticks_msec_bookmark) > READY_TICKS_MSEC:
				# ready time is up
				
				# TODO determine go or stop trial
				var is_stop: bool = (randf() < 0.25)
				
				# TODO call go or stop trial
				scene_trial_start(is_stop)
				
				if is_stop:
					current_state = scene_state.STOP_TRIAL
				else:
					current_state = scene_state.GO_TRIAL
				ticks_msec_bookmark = Time.get_ticks_msec()
		
		scene_state.GO_TRIAL:
			if (Time.get_ticks_msec() - ticks_msec_bookmark) > TRIAL_TICKS_MSEC:
				# trial time is up
				scene_reset()
				current_state = scene_state.WAIT
				ticks_msec_bookmark = Time.get_ticks_msec()
			
			elif Input.is_action_just_pressed("kick_left") and not is_go_trial_passed:
				if is_feeder_left:
					ball_kicked.emit()
					is_go_trial_passed = true
					print("go_trial_passed")
				else:
					go_trial_failed.emit()
					print("go_trial_failed")
			
			elif Input.is_action_just_pressed("kick_right") and not is_go_trial_passed:
				if not is_feeder_left: # is feeder right
					ball_kicked.emit()
					is_go_trial_passed = true
					print("go_trial_passed")
				else:
					go_trial_failed.emit()
					print("go_trial_failed")
		
		scene_state.STOP_TRIAL:
			if (Time.get_ticks_msec() - ticks_msec_bookmark) > TRIAL_TICKS_MSEC:
				# trial time is up
				scene_reset()
				current_state = scene_state.WAIT
				ticks_msec_bookmark = Time.get_ticks_msec()
				
			elif Input.is_action_just_pressed("kick_left") or Input.is_action_just_pressed("kick_right"):
				stop_trial_failed.emit()
				print("stop_trial_failed")

func scene_reset():
	print("scene_reset")
	
	# reset flags
	is_go_trial_passed = false
	
	# remove left ball feeder
	if $PlaceholderBallFeederLeft.get_child_count() != 0:
		$PlaceholderBallFeederLeft/BallFeeder.free()
	
	# remove right ball feeder
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
	
	# remove and respawn right defender
	if $PlaceholderDefenderRight.get_child_count() != 0:
		$PlaceholderDefenderRight/Defender.free()
		var new_defender_right = defender_scene.instantiate()
		$PlaceholderDefenderRight.add_child(new_defender_right)

func scene_ready():
	print("scene_ready")
	
	# spawn ball feeder, randomly choosing left or right side
	var new_ball_feeder = ball_feeder_scene.instantiate()
	if randf() > 0.5:
		is_feeder_left = true
		$PlaceholderBallFeederLeft.add_child(new_ball_feeder)
	else:
		is_feeder_left = false
		$PlaceholderBallFeederRight.add_child(new_ball_feeder)
	
	# spawn fixation cone
	var new_fixation_cone = fixation_cone_scene.instantiate()
	$PlaceholderFixation.add_child(new_fixation_cone)

func scene_trial_start(is_stop_trial: bool):
	var bool_string = "stop" if is_stop_trial else "go"
	print("scene_trial_start " + bool_string)
	
	# remove fixation cone
	if $PlaceholderFixation.get_child_count() != 0:
		$PlaceholderFixation/FixationCone.free()
	
	# spawn teammate
	var new_teammate = teammate_scene.instantiate()
	$PlaceholderFixation.add_child(new_teammate)
	
	# emit signal for ball feeder and defenders
	trial_started.emit(is_stop_trial)

#func stop_trial_start():
	## remove fixation cone
	#if $PlaceholderFixation.get_child_count() != 0:
		#$PlaceholderFixation/FixationCone.free()

