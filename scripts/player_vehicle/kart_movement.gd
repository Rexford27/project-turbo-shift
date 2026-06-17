extends Node3D

@export var vs:VehicleStats
@export var physics_ball: RigidBody3D
@export var visual_body: VisualBody 

func _ready() -> void:
	visual_body.visual_position_offset.y = -1.20
	#print(physics_ball.center_of_mass)
	#physics_ball.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	#physics_ball.center_of_mass = Vector3(0, 0, 0) # lower than the body origin

func _physics_process(delta: float) -> void:
	physics_ball.gravity_scale = vs.gravity
