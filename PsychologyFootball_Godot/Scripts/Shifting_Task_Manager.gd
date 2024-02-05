extends Node3D

# spawnables
const BALL_FEEDER_SCENE = preload("res://SubScenes/Ball_Feeder.tscn")

# time
const TICKS_BETWEEN_TRIALS_MSEC: int = 1000
const READY_TICKS_MSEC: int = 1000
const TRIAL_TICKS_MSEC: int = 2000
@onready var ticks_msec_bookmark: int = 0

# counters
const PRACTICE_BLOCKS: int = 1
const TEST_BLOCKS: int = 4
const SHIFT_TRIALS_PER_PRACTICE_BLOCK: int = 5
const NON_SHIFT_TRIALS_PER_PRACTICE_BLOCK: int = 15
const SHIFT_TRIALS_PER_TEST_BLOCK: int = 12
const NON_SHIFT_TRIALS_PER_TEST_BLOCK: int = 36

var is_practice_block: bool = true
var shift_trials_per_block: int = SHIFT_TRIALS_PER_PRACTICE_BLOCK
var non_shift_trials_per_block: int = NON_SHIFT_TRIALS_PER_PRACTICE_BLOCK
var block_counter: int = 0
var trial_counter: int = 0
var shift_trial_counter: int = 0
var shift_trials_passed: int = 0
var non_shift_trial_counter: int = 0
var non_shift_trials_passed: int = 0

# metrics
@onready var metrics_array = Array()
@onready var start_datetime = Time.get_datetime_dict_from_system()

# states
enum scene_state {WAIT, READY, TRIAL}
# TODO create dict of states and corresponding func callables for defensive prog.
@onready var current_state = scene_state.WAIT

# signals
signal trial_started
signal ball_kicked

# flags
var is_feeder_left: bool = false
var is_trial_passed: bool = false
var is_blue_ball: bool = false
var is_shift_trial: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.ambience_sfx.play()
	
	scene_reset() # ensure scene and scene_state are in agreement


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("save_log"):
		#scene_trial_start(true)
		write_sst_raw_log(start_datetime)
		write_sst_summary_log(start_datetime)
	
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
				
				# determine shift or non shift trial
				var rand_is_shift_trial = (randf() < 0.25)
				if rand_is_shift_trial and shift_trial_counter < shift_trials_per_block:
					# shift is rand selected and shifts remain
					is_shift_trial = true
				elif non_shift_trial_counter < non_shift_trials_per_block:
					# out of shifts but non-shifts remain, force non-shift
					is_shift_trial = false
				elif not rand_is_shift_trial and non_shift_trial_counter < non_shift_trials_per_block:
					# non-shift is rand selected and non-shifts remain
					is_shift_trial = false
				elif shift_trial_counter < shift_trials_per_block:
					# out of non-shifts but shifts remain, force shift
					is_shift_trial = true
				else:
					print("block finished. is_practice_block: " + str(is_practice_block))
					# TODO block finished, load next block
				
				scene_trial_start()
				current_state = scene_state.TRIAL
				ticks_msec_bookmark = Time.get_ticks_msec()
		
		
		scene_state.TRIAL:
			if (Time.get_ticks_msec() - ticks_msec_bookmark) > TRIAL_TICKS_MSEC:
				# trial time is up
				
				if not is_trial_passed:
					#go_trial_failed.emit()
					print("non_shift_trial_failed")
					append_new_metrics_entry(0)
				
				scene_reset()
				
				current_state = scene_state.WAIT
				ticks_msec_bookmark = Time.get_ticks_msec()
			
			elif Input.is_action_just_pressed("kick_left") and not is_trial_passed:
				if check_correct_kick(true): # is kick left
					ball_kicked.emit($GoalPostLeft.global_position)
					is_trial_passed = true
					non_shift_trials_passed += 1
					print("non_shift_trial_passed")
				else:
					#go_trial_failed.emit()
					print("non_shift_trial_failed")
				append_new_metrics_entry(Time.get_ticks_msec() - ticks_msec_bookmark)
			
			elif Input.is_action_just_pressed("kick_right") and not is_trial_passed:
				if check_correct_kick(false): # is kick right
					ball_kicked.emit($GoalPostRight.global_position)
					is_trial_passed = true
					non_shift_trials_passed += 1
					print("non_shift_trial_passed")
				else:
					#go_trial_failed.emit()
					print("non_shift_trial_failed")
				append_new_metrics_entry(Time.get_ticks_msec() - ticks_msec_bookmark)

func scene_reset():
	print("scene_reset")
	
	# remove left ball feeder
	if $PlaceholderBallFeederLeft.get_child_count() != 0:
		$PlaceholderBallFeederLeft/BallFeeder.free()
	
	# remove right ball feeder
	if $PlaceholderBallFeederRight.get_child_count() != 0:
		$PlaceholderBallFeederRight/BallFeeder.free()

func scene_ready():
	print("scene_ready")

func scene_trial_start():
	var bool_string = "shift" if is_shift_trial else "non_shift"
	print("scene_trial_start " + bool_string)
	
	# update trial counters
	trial_counter += 1
	if is_shift_trial:
		shift_trial_counter += 1
	else:
		non_shift_trial_counter += 1
	
	# set up flags
	is_trial_passed = false
	
	# spawn ball feeder, randomly choosing left or right side
	var new_ball_feeder = BALL_FEEDER_SCENE.instantiate()
	if randf() > 0.5:
		is_feeder_left = true
		$PlaceholderBallFeederLeft.add_child(new_ball_feeder)
	else:
		is_feeder_left = false
		$PlaceholderBallFeederRight.add_child(new_ball_feeder)
	
	# emit signal for ball feeder
	trial_started.emit(is_blue_ball)

func check_correct_kick(is_kick_left: bool) -> bool:
	if is_kick_left:
		if is_feeder_left:
			return not is_blue_ball
		else:
			return is_blue_ball
	else:
		if is_feeder_left:
			return is_blue_ball
		else:
			return not is_blue_ball

func append_new_metrics_entry(response_time: int):
	metrics_array.append([block_counter, trial_counter, is_feeder_left, is_blue_ball, is_shift_trial, is_trial_passed, response_time])

func write_sst_raw_log(datetime_dict):
	# open/create file
	var raw_log_file_path: String = "res://TaskLogs/shifting_{year}-{month}-{day}-{hour}-{minute}-{second}_raw.txt".format(datetime_dict) # TODO let user choose dir
	var raw_log_file = FileAccess.open(raw_log_file_path, FileAccess.WRITE)
	print("raw log file created at " + raw_log_file_path + " with error code " + str(FileAccess.get_open_error()))
	
	# format guide
	# block_counter: int, trial_counter: int, stimulus_left: bool, stop_trial: bool,
	# correct_response: bool, response_time: int (ms), stop_signal_delay: int (ms)
	if raw_log_file:
		# write date, time, subject, group, format guide
		raw_log_file.store_line("PsychologyFootball - Shifting Task - Raw Data Log")
		raw_log_file.store_line("date: {day}-{month}-{year}".format(datetime_dict))
		raw_log_file.store_line("time: {hour}:{minute}:{second}".format(datetime_dict))
		raw_log_file.store_line("subject: test") # TODO fill user-input subject and group
		raw_log_file.store_line("group: test")
		raw_log_file.store_string("\n-Format Guide-\n\nblock_counter, trial_counter, stimulus_left (ball feeder side), is_blue_ball, is_shift_trial, correct_response, response_time (ms)")
		raw_log_file.store_string("\n\n-Raw Data-\n\n")
		
		for sub_array in metrics_array:
			var line = "{0}, {1}, {2}, {3}, {4}, {5}, {6}"
			raw_log_file.store_line(line.format(sub_array))
		
		raw_log_file.close()

func write_sst_summary_log(datetime_dict):
	# open/create file
	var summary_log_file_path: String = "res://TaskLogs/shifting_{year}-{month}-{day}-{hour}-{minute}-{second}_summary.txt".format(datetime_dict) # TODO let user choose dir
	var summary_log_file = FileAccess.open(summary_log_file_path, FileAccess.WRITE)
	print("summary log file created at " + summary_log_file_path + " with error code " + str(FileAccess.get_open_error()))
	
	if summary_log_file:
		# write date, time, subject, group, format guide
		summary_log_file.store_line("PsychologyFootball - Shifting Task - Summary Data Log")
		summary_log_file.store_line("date: {day}-{month}-{year}".format(datetime_dict))
		summary_log_file.store_line("time: {hour}:{minute}:{second}".format(datetime_dict))
		summary_log_file.store_line("subject: test") # TODO fill user-input subject and group
		summary_log_file.store_line("group: test")
		summary_log_file.store_string("\n-Final States of Counters-\n\n")
		
		# write counters
		summary_log_file.store_line("is_practice_block: " + str(is_practice_block))
		summary_log_file.store_line("non_shift_trials_per_block: " + str(non_shift_trials_per_block))
		summary_log_file.store_line("shift_trials_per_block: " + str(shift_trials_per_block))
		summary_log_file.store_line("block_counter: " + str(block_counter))
		summary_log_file.store_line("trial_counter: " + str(trial_counter))
		summary_log_file.store_line("non_shift_trial_counter: " + str(non_shift_trial_counter))
		summary_log_file.store_line("non_shift_trials_passed: " + str(non_shift_trials_passed))
		summary_log_file.store_line("shift_trial_counter: " + str(shift_trial_counter))
		summary_log_file.store_line("shift_trials_passed: " + str(shift_trials_passed))
		
		# calculate probability of reacting in Stop Signal Trials (prob(response|signal))
		#var p_rs: float = float(stop_trial_counter - stop_trials_passed) / float(stop_trial_counter) # fails / total
		
		# collect rolling totals for calculating means
		var rolling_total_stop_signal_delay: int = 0
		var rolling_total_reaction_time: int = 0
		
		for sub_array in metrics_array:
			if sub_array[3]:
				# if stop signal
				rolling_total_stop_signal_delay += sub_array[6]
				rolling_total_reaction_time += sub_array[5]
		
		# calculate mean stop signal delays (in ms) in Stop Signal trials
		#var ssd = float(rolling_total_stop_signal_delay) / float(stop_trial_counter)
		
		# calculate mean reaction time (in ms) in Stop Signal trials (response times of incorrectly hitting a response key)
		#var sr_rt = float(rolling_total_reaction_time) / float(stop_trial_counter - stop_trials_passed) # (stops failed)
		
		# write summary data
		summary_log_file.store_string("\n-Calculated Summary Values-\n\n")
		#summary_log_file.store_line("probability of reacting in Stop Signal Trials (prob(response|signal)), p_rs: " + str(p_rs))
		#summary_log_file.store_line("mean stop signal delays (in ms) in Stop Signal trials, ssd: " + str(ssd))
		#summary_log_file.store_line("mean reaction time (in ms) in Stop Signal trials (response times of incorrectly hitting a response key), sr_rt: " + str(sr_rt))
		
		summary_log_file.close()



