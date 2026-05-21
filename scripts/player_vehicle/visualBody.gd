extends Node3D
class_name VisualBody

# The invisible physics ball.
@export var physics_ball: RigidBody3D

# The control/camera direction.
@export var control_frame: ControlFrame

# The visible vehicle node.
#@export var visual_body: Node3D
@export var visual_body: Node3D = self


# Use this if the model is too high/low/forward/back.
@export var visual_position_offset: Vector3 = Vector3.ZERO

# If the model faces backward, try 180.
@export var model_yaw_offset_degrees: float = 0.0

# How fast the visual rotates toward the ControlFrame.
@export var rotation_follow_speed: float = 10.0

# If true, the visual will pitch up/down when flight is enabled.
@export var match_pitch_when_flying: bool = true


func _physics_process(delta: float) -> void:
	follow_ball_position()
	rotate_toward_control_frame(delta)


func follow_ball_position() -> void:
	if physics_ball == null or visual_body == null:
		return

	# The visual sits exactly where the physics ball is.
	visual_body.global_position = physics_ball.global_position + visual_position_offset


func rotate_toward_control_frame(delta: float) -> void:
	if control_frame == null or visual_body == null:
		return

	var amount = clamp(rotation_follow_speed * delta, 0.0, 1.0)

	var current_rotation := visual_body.global_rotation
	var target_rotation := control_frame.global_rotation

	# Always match left/right camera direction.
	current_rotation.y = lerp_angle(
		current_rotation.y,
		target_rotation.y + deg_to_rad(model_yaw_offset_degrees+180),
		amount
	)

	# Only match up/down pitch during flight.
	if match_pitch_when_flying and control_frame.enable_flight:
		current_rotation.x = lerp_angle(
			current_rotation.x,
			target_rotation.x,
			amount
		)
	else:
		current_rotation.x = lerp_angle(
			current_rotation.x,
			0.0,
			amount
		)

	# Keep roll clean for now.
	current_rotation.z = lerp_angle(
		current_rotation.z,
		0.0,
		amount
	)

	visual_body.global_rotation = current_rotation
