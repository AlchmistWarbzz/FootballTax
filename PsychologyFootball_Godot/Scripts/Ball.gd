extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	apply_central_impulse(get_global_transform().basis.z * 20)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("spacebar"):
		set_linear_velocity(Vector3.ZERO)
		apply_central_impulse(Vector3.LEFT * 8)
