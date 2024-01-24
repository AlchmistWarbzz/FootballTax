extends Node3D

# spawnables
var ball_feeder_scene = preload("res://SubScenes/Ball_Feeder.tscn")
var defender_scene = preload("res://SubScenes/Defender.tscn")
var fixation_cone_scene = preload("res://SubScenes/Fixation_Cone.tscn")
var teammate_scene = preload("res://SubScenes/Teammate.tscn")

# time
const TICKS_BETWEEN_TRIALS_MSEC: int = 3000
const READY_TICKS_MSEC: int = 1000
const TRIAL_TICKS_MSEC: int = 500
@onready var ticks_msec_bookmark: int = 0

# counters
const GO_TRIALS_PER_BLOCK = 75
const STOP_TRIALS_PER_BLOCK = 25
var block_counter: int = 0
var trial_counter: int = 0
var go_trial_counter: int = 0
var stop_trial_counter: int = 0

# metrics
@onready var metrics_array = Array()

# states
enum scene_state {WAIT, READY, GO_TRIAL, STOP_TRIAL}
# TODO create dict of states and corresponding func callables for defensive prog.
@onready var current_state = scene_state.WAIT

# signals
signal trial_started
signal ball_kicked
signal go_trial_failed
signal stop_trial_failed

# flags
var is_feeder_left: bool = false
var is_trial_passed = false

func _ready():
	scene_reset() # ensure scene and scene_state are in agreement

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#if trial_counter > 9:
		#var file = FileAccess.open("/sst_log.txt", FileAccess.WRITE)
		#file.store_var(metrics_array)
	
	# Manual Keypress Sequencing
	#if Input.is_action_just_pressed("r"):
		#scene_reset()
	#
	#if Input.is_action_just_pressed("t"):
		#scene_ready()
	#
	#if Input.is_action_just_pressed("g"):
		#scene_trial_start(false)
	
	if Input.is_action_just_pressed("save_log"):
		#scene_trial_start(true)
		write_sst_raw_log()
		#write_sst_summary_log()
	
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
				
				# determine go or stop trial
				var is_stop: bool = (randf() < 0.25)
				if is_stop and stop_trial_counter < STOP_TRIALS_PER_BLOCK:
					scene_trial_start(is_stop)
				elif not is_stop and go_trial_counter < GO_TRIALS_PER_BLOCK:
					scene_trial_start(is_stop)
				else:
					# 100-trial block finished
					pass
				
				if is_stop:
					current_state = scene_state.STOP_TRIAL
				else:
					current_state = scene_state.GO_TRIAL
				ticks_msec_bookmark = Time.get_ticks_msec()
		
		scene_state.GO_TRIAL:
			if (Time.get_ticks_msec() - ticks_msec_bookmark) > TRIAL_TICKS_MSEC:
				# trial time is up
				
				if not is_trial_passed:
					go_trial_failed.emit()
					print("go_trial_failed")
					append_new_metrics_entry(false, is_trial_passed, 0)
				
				scene_reset()
				
				current_state = scene_state.WAIT
				ticks_msec_bookmark = Time.get_ticks_msec()
			
			elif Input.is_action_just_pressed("kick_left") and not is_trial_passed:
				if is_feeder_left:
					ball_kicked.emit()
					is_trial_passed = true
					print("go_trial_passed")
				else:
					go_trial_failed.emit()
					print("go_trial_failed")
				append_new_metrics_entry(false, is_trial_passed, Time.get_ticks_msec() - ticks_msec_bookmark)
			
			elif Input.is_action_just_pressed("kick_right") and not is_trial_passed:
				if not is_feeder_left: # is feeder right
					ball_kicked.emit()
					is_trial_passed = true
					print("go_trial_passed")
				else:
					go_trial_failed.emit()
					print("go_trial_failed")
				append_new_metrics_entry(false, is_trial_passed, Time.get_ticks_msec() - ticks_msec_bookmark)
		
		scene_state.STOP_TRIAL:
			if (Time.get_ticks_msec() - ticks_msec_bookmark) > TRIAL_TICKS_MSEC:
				# trial time is up
				scene_reset()
				
				if is_trial_passed:
					print("stop_trial_passed")
					append_new_metrics_entry(true, is_trial_passed, 0)
				
				current_state = scene_state.WAIT
				ticks_msec_bookmark = Time.get_ticks_msec()
				
			elif Input.is_action_just_pressed("kick_left") or Input.is_action_just_pressed("kick_right"):
				is_trial_passed = false
				stop_trial_failed.emit()
				print("stop_trial_failed")
				append_new_metrics_entry(true, is_trial_passed, Time.get_ticks_msec() - ticks_msec_bookmark)

func scene_reset():
	print("scene_reset")
	
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
	
	# update trial counters
	trial_counter += 1
	if is_stop_trial:
		stop_trial_counter += 1
	else:
		go_trial_counter += 1
	
	# set flags
	is_trial_passed = is_stop_trial
	
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

func append_new_metrics_entry(stop_signal: bool, correct_response: bool, response_time: int):
		metrics_array.append([block_counter, trial_counter, is_feeder_left, stop_signal, correct_response, response_time])

func write_sst_raw_log():
	var datetime_dict = Time.get_datetime_dict_from_system()
	
	# raw log
	var raw_log_file_path: String = "res://TaskLogs/stop_signal_raw_{year}-{month}-{day}-{hour}-{minute}-{second}.txt".format(datetime_dict)
	print("raw log created at " + raw_log_file_path)
	var raw_log_file = FileAccess.open(raw_log_file_path, FileAccess.WRITE)
	print(FileAccess.get_open_error())
	
	# format guide
	# block_counter: int, trial_counter: int, TODO ssd: int (msec), stimulus_left: bool,
	# stop_signal: bool, correct_response: bool, response_time: int (msec)
	
	# write date, time, subject, group, format guide
	raw_log_file.store_line("PsychologyFootball - Stop Signal Task - Raw Data Log")
	raw_log_file.store_line("date: {year}-{month}-{day}".format(datetime_dict))
	raw_log_file.store_line("time: {hour}-{minute}-{second}".format(datetime_dict))
	raw_log_file.store_line("subject: test")
	raw_log_file.store_line("group: test")
	raw_log_file.store_string("format guide:\n\nblock_counter: int, trial_counter: int, stop signal delay: int (msec), stimulus_side: bool (true = left, false = right), stop_signal_shown: bool, correct_response: bool, response_time: int (msec)\n\n")
	
	for sub_array in metrics_array:
		var line = "{0}, {1}, {2}, {3}, {4}, {5}"
		raw_log_file.store_line(line.format(sub_array))
	
	raw_log_file.close()

func write_sst_summary_log():
	var datetime_dict = Time.get_datetime_dict_from_system()
	
	# summary log
	var summary_log_file_path: String = "res://TaskLogs/stop_signal_summary_{year}-{month}-{day}-{hour}-{minute}-{second}.txt".format(datetime_dict)
	print("summary log created at " + summary_log_file_path)
	var summary_log_file = FileAccess.open(summary_log_file_path, FileAccess.WRITE)
	print(FileAccess.get_open_error())
	
	var go_successes: int
	for sub_array in metrics_array:
		if sub_array[0] == "go":
			pass
		elif sub_array[0] == "stop":
			pass
	
	summary_log_file.close()



