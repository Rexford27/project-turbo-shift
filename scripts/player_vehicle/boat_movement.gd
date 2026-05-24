extends Node3D

@export var vs:VehicleStats
@export var physics_ball: RigidBody3D

func _ready() -> void:
	pass
	#physics_ball.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	#physics_ball.center_of_mass = Vector3(0, -1.5, 0) # lower than the body origin
func _physics_process(delta: float) -> void:
	physics_ball.gravity_scale = vs.gravity
