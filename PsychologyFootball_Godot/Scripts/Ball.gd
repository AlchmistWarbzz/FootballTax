extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var task_manager_node
	
	var placeholder_node = get_parent()
	if placeholder_node != null:
		task_manager_node = placeholder_node.get_parent()
	
	if task_manager_node != null:
		task_manager_node.ball_kicked.connect(_on_task_manager_ball_kicked)
	
	# ball feeder launch
	apply_central_impulse(get_global_transform().basis.z * 20)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("space"):
		kick()


func _on_task_manager_ball_kicked():
	kick()


func kick():
	set_linear_velocity(Vector3.ZERO)
	apply_central_impulse(Vector3.LEFT * 8)
