@tool
extends Node3D
class_name VisualBody2

@export var physics_ball: RigidBody3D
@export var ground_sensor: GroundSensor

@export_group("Follow")
@export var position_offset: Vector3 = Vector3.ZERO
@export var follow_smoothly: bool = false
@export var follow_speed: float = 30.0

@export_group("Ground Tilt")
@export var align_to_ground: bool = true
@export var align_speed: float = 12.0

@export var enable_follow_ball = true 

func _physics_process(delta: float) -> void:
	if enable_follow_ball == false:
		return
	if physics_ball == null:
		return

	_follow_ball(delta)

	if not Engine.is_editor_hint():
		_tilt_to_ground(delta)


func _follow_ball(delta: float) -> void:
	var target_position := physics_ball.global_position + position_offset

	if follow_smoothly:
		global_position = global_position.lerp(target_position, clamp(follow_speed * delta, 0.0, 1.0))
	else:
		global_position = target_position


func _tilt_to_ground(delta: float) -> void:
	if not align_to_ground:
		return

	if ground_sensor == null:
		return

	if not ground_sensor.is_grounded:
		return

	var normal := ground_sensor.ground_normal

	var forward := -global_transform.basis.z
	forward = forward.slide(normal)

	if forward.length() < 0.01:
		return

	forward = forward.normalized()

	var right := forward.cross(normal).normalized()
	var target_basis := Basis(right, normal, -forward).orthonormalized()

	global_basis = global_basis.slerp(target_basis, clamp(align_speed * delta, 0.0, 1.0))
