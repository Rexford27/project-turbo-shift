@tool
extends Node3D
class_name VisualBody2

@export var physics_ball: RigidBody3D

@export_group("Follow")
@export var position_offset: Vector3 = Vector3.ZERO
@export var follow_smoothly: bool = false
@export var follow_speed: float = 30.0

@export var enable_follow_ball: bool = true


func _physics_process(delta: float) -> void:
	if not enable_follow_ball:
		return

	if physics_ball == null:
		return

	_follow_ball(delta)


func _follow_ball(delta: float) -> void:
	var target_position := physics_ball.global_position + position_offset

	if follow_smoothly:
		global_position = global_position.lerp(
			target_position,
			clamp(follow_speed * delta, 0.0, 1.0)
		)
	else:
		global_position = target_position
