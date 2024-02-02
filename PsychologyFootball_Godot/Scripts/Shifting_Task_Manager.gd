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
const TEST_BLOCKS: int = 2

var is_practice_block: bool = true
var block_counter: int = 0
var trial_counter: int = 0

# metrics
@onready var metrics_array = Array()
@onready var start_datetime = Time.get_datetime_dict_from_system()

# states
enum scene_state {WAIT, READY, GO_TRIAL, STOP_TRIAL}
# TODO create dict of states and corresponding func callables for defensive prog.
@onready var current_state = scene_state.WAIT

# signals
signal trial_started
signal ball_kicked

# flags
var is_feeder_left: bool = false
var is_trial_passed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
