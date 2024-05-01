extends Node3D

# spawnables
const BALL_FEEDER_SCENE = preload("res://SubScenes/Ball_Feeder.tscn")
const FIXATION_CONE = preload("res://SubScenes/Fixation_Cone.tscn")
const M_TEMP_GOAL = preload("res://Materials/M_TempGoal.tres")
const BLUE_BALL = preload("res://SubScenes/BlueBall.tscn")

# time
const TICKS_BETWEEN_TRIALS_MSEC: int = 3000
const READY_TICKS_MSEC: int = 250
const TARGET_SHOW_TICKS_MSEC: int = 400
const TRIAL_TICKS_MSEC: int = 50000
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
var span_length: int = 3
#var shift_trial_counter: int = 0
var trials_passed: int = 0
#var non_shift_trial_counter: int = 0
#var non_shift_trials_passed: int = 0

# metrics
@onready var metrics_array = Array()
@onready var start_datetime = Time.get_datetime_dict_from_system()

# states
enum scene_state {WAIT, READY, SHOW_TARGET, TRIAL}
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

# spans
@onready var targets = [$"0/MeshInstance3D", $"1/MeshInstance3D", $"2/MeshInstance3D", $"3/MeshInstance3D", $"4/MeshInstance3D", $"5/MeshInstance3D", $"6/MeshInstance3D"]
@onready var random_span = Array()
@onready var random_span_numbers = Array()
@onready var player_input_span = Array()

# span pointers
var current_target_show_index: int = -1
#var next_target_show_index: int = current_target_show_index + 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	AudioManager.ambience_sfx.play()
	
	scene_reset() # ensure scene and scene_state are in agreement


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
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
				
				if current_target_show_index < span_length:
					scene_show_target()
					current_state = scene_state.SHOW_TARGET
					ticks_msec_bookmark = Time.get_ticks_msec()
				else:
					scene_trial_start()
					current_state = scene_state.TRIAL
					ticks_msec_bookmark = Time.get_ticks_msec()
		
		
		scene_state.SHOW_TARGET:
			if (Time.get_ticks_msec() - ticks_msec_bookmark) > TARGET_SHOW_TICKS_MSEC:
				# show time is up
				scene_hide_target()
				scene_ready()
				current_state = scene_state.READY
				ticks_msec_bookmark = Time.get_ticks_msec()
				
		
		scene_state.TRIAL:
			if (Time.get_ticks_msec() - ticks_msec_bookmark) > TRIAL_TICKS_MSEC:
				# trial time is up
				
				if not is_trial_passed:
					#go_trial_failed.emit()
					print("trial_failed")
				
				append_new_metrics_entry()
				
				scene_reset()
				
				current_state = scene_state.WAIT
				ticks_msec_bookmark = Time.get_ticks_msec()
			
			if Input.is_action_just_pressed("select"):
				var raycast_length = 1000
				var space_state = get_world_3d().get_direct_space_state()
				var mouse_position = get_viewport().get_mouse_position()
				var params = PhysicsRayQueryParameters3D.new()
				params.from = get_viewport().get_camera_3d().project_ray_origin(mouse_position)
				params.to = params.from + get_viewport().get_camera_3d().project_ray_normal(mouse_position) * raycast_length
				params.collision_mask = 2
				var result = space_state.intersect_ray(params)
				if result: #if mouse clicked target
					print("mouse ray hit target " + result.collider.name)
					player_input_span.append(result.collider.name)
					
					# destroy previous ball if found
					var old_ball = $Player/PlaceholderBall/Child.get_child(0)
					if old_ball != null:
						old_ball.queue_free()
					
					# create new ball
					var instance
					instance = BLUE_BALL.instantiate()
					$Player/PlaceholderBall/Child.add_child(instance)
					ball_kicked.emit(result.collider.get_global_position() + (Vector3.UP * 3))
				
				for n in random_span:
					var n_stringname = str(targets.find(n))
					random_span_numbers.append(StringName(n_stringname))
				
				if player_input_span == random_span_numbers:
					# trial passed
					print("trial passed")
					is_trial_passed = true
					trials_passed += 1
					
					span_length += 1
					
					append_new_metrics_entry()
					
					scene_reset()
					
					current_state = scene_state.WAIT
					ticks_msec_bookmark = Time.get_ticks_msec()
				
				elif player_input_span.size() >= random_span.size():
					print("trial failed")
					
					append_new_metrics_entry()
					
					scene_reset()
					
					current_state = scene_state.WAIT
					ticks_msec_bookmark = Time.get_ticks_msec()
				
				random_span_numbers = Array()
			
			
			#elif Input.is_action_just_pressed("kick_left") and not is_trial_passed:
				#if check_correct_kick(true): # is kick left
					#ball_kicked.emit($GoalPostLeft.global_position)
					#is_trial_passed = true
					# 
					#if is_shift_trial:
						#shift_trials_passed += 1
						#print("shift_trial_passed")
					#else:
						#non_shift_trials_passed += 1
						#print("non_shift_trial_passed")
				#else:
					##go_trial_failed.emit()
					#print("non_shift_trial_failed")
				#append_new_metrics_entry(Time.get_ticks_msec() - ticks_msec_bookmark)
			
			#elif Input.is_action_just_pressed("kick_right") and not is_trial_passed:
				#if check_correct_kick(false): # is kick right
					#ball_kicked.emit($GoalPostRight.global_position)
					#is_trial_passed = true
					#
					#if is_shift_trial:
						#shift_trials_passed += 1
						#print("shift_trial_passed")
					#else:
						#non_shift_trials_passed += 1
						#print("non_shift_trial_passed")
				#else:
					##go_trial_failed.emit()
					#if is_shift_trial:
						#print("shift_trial_failed")
					#else:
						#print("non_shift_trial_failed")
				#append_new_metrics_entry(Time.get_ticks_msec() - ticks_msec_bookmark)

func scene_reset():
	print("scene_reset")
	
	## remove left ball feeder
	#if $PlaceholderBallFeederLeft.get_child_count() != 0:
		#$PlaceholderBallFeederLeft/BallFeeder.free()
	
	# reset span stuff
	current_target_show_index = -1
	player_input_span = Array()
	
	# calculate new span stuff
	var new_span = targets.duplicate(true)
	new_span.shuffle()
	random_span = new_span.slice(0, span_length, 1)
	
	# spawn fixation cone
	var new_fixation_cone = FIXATION_CONE.instantiate()
	$PlaceholderFixation.add_child(new_fixation_cone)

func scene_ready():
	print("scene_ready")
	
	current_target_show_index += 1
	
	# spawn fixation cone
	var new_fixation_cone = FIXATION_CONE.instantiate()
	$PlaceholderFixation.add_child(new_fixation_cone)

func scene_show_target():
	#random_span[next_target_to_show_index].set_surface_override_material(0, M_TEMP_GOAL)
	random_span[current_target_show_index].set_surface_override_material(0, M_TEMP_GOAL)

func scene_hide_target():
	random_span[current_target_show_index].set_surface_override_material(0, null)

func scene_trial_start():
	print("scene_trial_start")
	
	# remove fixation cone
	if $PlaceholderFixation.get_child_count() != 0:
		$PlaceholderFixation/FixationCone.free()
	
	# update trial counters
	trial_counter += 1
	
	# set up flags
	is_trial_passed = false
	
	# spawn ball feeder, randomly choosing left or right side
	var new_ball_feeder = BALL_FEEDER_SCENE.instantiate()
	$PlaceholderBallFeederLeft.add_child(new_ball_feeder)
	#if randf() > 0.5:
		#is_feeder_left = true
		#$PlaceholderBallFeederLeft.add_child(new_ball_feeder)
	#else:
		#is_feeder_left = false
		#$PlaceholderBallFeederRight.add_child(new_ball_feeder)
	
	# determine ball colour
	if is_shift_trial:
		is_blue_ball = not is_blue_ball
	
	# emit signal for ball feeder
	#trial_started.emit(is_blue_ball)

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

func append_new_metrics_entry():
	metrics_array.append([block_counter, trial_counter, is_trial_passed])

func write_sst_raw_log(datetime_dict):
	# open/create file
	var raw_log_file_path: String = "bds_{year}-{month}-{day}-{hour}-{minute}-{second}_raw.txt".format(datetime_dict) # TODO let user choose dir
	var raw_log_file = FileAccess.open(raw_log_file_path, FileAccess.WRITE)
	print("raw log file created at " + raw_log_file_path + " with error code " + str(FileAccess.get_open_error()))
	
	# format guide
	# block_counter: int, trial_counter: int, stimulus_left: bool, stop_trial: bool,
	# correct_response: bool, response_time: int (ms), stop_signal_delay: int (ms)
	if raw_log_file:
		# write date, time, subject, group, format guide
		raw_log_file.store_line("PsychologyFootball - BDS Task - Raw Data Log")
		raw_log_file.store_line("date: {day}-{month}-{year}".format(datetime_dict))
		raw_log_file.store_line("time: {hour}:{minute}:{second}".format(datetime_dict))
		raw_log_file.store_line("subject: test") # TODO fill user-input subject and group
		raw_log_file.store_line("group: test")
		raw_log_file.store_string("\n-Format Guide-\n\nblock_counter, trial_counter, correct_response")
		raw_log_file.store_string("\n\n-Raw Data-\n\n")
		
		for sub_array in metrics_array:
			#var line = "{0}, {1}, {2}, {3}, {4}, {5}, {6}"
			#raw_log_file.store_line(line.format(sub_array))
			for item in sub_array:
				raw_log_file.store_string(str(item) + ", ")
			
			raw_log_file.store_string("\n")
		
		raw_log_file.close()

func write_sst_summary_log(datetime_dict):
	# open/create file
	var summary_log_file_path: String = "bds_{year}-{month}-{day}-{hour}-{minute}-{second}_summary.txt".format(datetime_dict) # TODO let user choose dir
	var summary_log_file = FileAccess.open(summary_log_file_path, FileAccess.WRITE)
	print("summary log file created at " + summary_log_file_path + " with error code " + str(FileAccess.get_open_error()))
	
	if summary_log_file:
		# write date, time, subject, group, format guide
		summary_log_file.store_line("PsychologyFootball - BDS Task - Summary Data Log")
		summary_log_file.store_line("date: {day}-{month}-{year}".format(datetime_dict))
		summary_log_file.store_line("time: {hour}:{minute}:{second}".format(datetime_dict))
		summary_log_file.store_line("subject: test") # TODO fill user-input subject and group
		summary_log_file.store_line("group: test")
		summary_log_file.store_string("\n-Final States of Counters-\n\n")
		
		# write counters
		summary_log_file.store_line("is_practice_block: " + str(is_practice_block))
		#summary_log_file.store_line("non_shift_trials_per_block: " + str(non_shift_trials_per_block))
		#summary_log_file.store_line("shift_trials_per_block: " + str(shift_trials_per_block))
		summary_log_file.store_line("block_counter: " + str(block_counter))
		summary_log_file.store_line("trial_counter: " + str(trial_counter))
		#summary_log_file.store_line("trial_counter: " + str(trial_counter))
		summary_log_file.store_line("trials_passed: " + str(trials_passed))
		#summary_log_file.store_line("shift_trial_counter: " + str(shift_trial_counter))
		#summary_log_file.store_line("shift_trials_passed: " + str(shift_trials_passed))
		
		# calculate probability of passing Shift Trials
		var p_rs: float = float(trials_passed) / float(trial_counter) # successes / total
		
		## collect rolling totals for calculating means
		#var rolling_total_shift_reaction_time: int = 0
		#var rolling_total_non_shift_reaction_time: int = 0
		
		#for sub_array in metrics_array:
			#if sub_array[4] and sub_array[5]:
				## if shift trial passed
				#rolling_total_shift_reaction_time += sub_array[6]
			#if not sub_array[4] and sub_array[5]:
				## if non shift trial passed
				#rolling_total_non_shift_reaction_time += sub_array[6]
		
		## calculate mean reaction time (in ms) in Shift trials that were passed
		#var sr_rt = float(rolling_total_shift_reaction_time) / float(shift_trials_passed)
		#
		## calculate mean reaction time (in ms) in Non Shift trials that were passed
		#var nsr_rt = float(rolling_total_non_shift_reaction_time) / float(non_shift_trials_passed)
		
		# write summary data
		summary_log_file.store_string("\n-Calculated Summary Values-\n\n")
		summary_log_file.store_line("probability of passing Shift Trials: " + str(p_rs))
		#summary_log_file.store_line("mean reaction time (in ms) in Shift trials that were passed: " + str(sr_rt))
		#summary_log_file.store_line("mean reaction time (in ms) in Non Shift trials that were passed: " + str(nsr_rt))
		
		summary_log_file.close()



