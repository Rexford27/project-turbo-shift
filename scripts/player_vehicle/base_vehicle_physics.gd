extends Node
class_name BaseVehiclePhysics

@export var body: RigidBody3D
@export var control_frame: ControlFrame

@export_group("Speed")
@export var max_forward_speed: float = 28.0
@export var max_reverse_speed: float = 10.0
@export var max_accel_force: float = 12000.0

@export_group("Grip")
@export var side_grip_force: float = 9000.0

@export_group("Rotation")
@export var align_strength: float = 5000.0
@export var align_damping: float = 700.0


func _physics_process(delta: float) -> void:
	if body == null or control_frame == null:
		return

	apply_forward_force(delta)
	apply_side_grip(delta)
	align_body_to_control_frame(delta)


func apply_forward_force(delta: float) -> void:
	var throttle := control_frame.throttle_input

	var forward_dir := -control_frame.global_transform.basis.z.normalized()

	var target_speed := max_forward_speed * throttle

	if throttle < 0.0:
		target_speed = max_reverse_speed * throttle

	var current_forward_speed := body.linear_velocity.dot(forward_dir)

	var needed_accel := (target_speed - current_forward_speed) / delta
	var force_amount := body.mass * needed_accel

	force_amount = clamp(force_amount, -max_accel_force, max_accel_force)

	body.apply_central_force(forward_dir * force_amount)


func apply_side_grip(delta: float) -> void:
	var side_dir := control_frame.global_transform.basis.x.normalized()

	var current_side_speed := body.linear_velocity.dot(side_dir)

	var needed_accel := (0.0 - current_side_speed) / delta
	var force_amount := body.mass * needed_accel

	force_amount = clamp(force_amount, -side_grip_force, side_grip_force)

	body.apply_central_force(side_dir * force_amount)


func align_body_to_control_frame(delta: float) -> void:
	var body_forward := -body.global_transform.basis.z
	var target_forward := -control_frame.global_transform.basis.z

	body_forward.y = 0.0
	target_forward.y = 0.0

	if body_forward.length() < 0.01 or target_forward.length() < 0.01:
		return

	body_forward = body_forward.normalized()
	target_forward = target_forward.normalized()

	var angle := body_forward.signed_angle_to(target_forward, Vector3.UP)

	var torque_amount := (angle * align_strength) - (body.angular_velocity.y * align_damping)

	body.apply_torque(Vector3.UP * torque_amount)
