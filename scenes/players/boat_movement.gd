extends Node3D

@export var vs:VehicleStats
@export var physics_ball: RigidBody3D

func _physics_process(delta: float) -> void:
	physics_ball.gravity_scale = vs.gravity
