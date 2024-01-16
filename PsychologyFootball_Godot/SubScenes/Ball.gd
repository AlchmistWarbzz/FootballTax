extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	kick()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func kick():
	apply_central_impulse(Vector3.MODEL_FRONT * 7)
