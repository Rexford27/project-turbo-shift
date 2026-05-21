extends Node
class_name VehicleVisualController

@export var body: RigidBody3D
@export var control_frame: Node3D
@export var visual_body: Node3D
@export var visual_root: Node3D

# Moves the visible model up/down/forward/back from the rigid body.
@export var visual_position_offset: Vector3 = Vector3(0.0, 0.0, 0.0)

# If your model faces backward, try 180.
@export var model_yaw_offset_degrees: float = 0.0

# How fast the visual follows the physics body.
@export var position_follow_speed: float = 30.0
@export var rotation_follow_speed: float = 18.0

# Extra fake pose when steering.
@export var steering_yaw_degrees: float = 12.0
@export var steering_lean_degrees: float = 8.0
@export var pose_follow_speed: float = 12.0


func _physics_process(delta: float) -> void:
	if body == null or visual_body == null:
		return

	update_visual_position(delta)
	update_visual_rotation(delta)
	update_visual_pose(delta)


func update_visual_position(delta: float) -> void:
	var target_position := body.global_position + visual_position_offset
	var amount = clamp(position_follow_speed * delta, 0.0, 1.0)

	visual_body.global_position = visual_body.global_position.lerp(
		target_position,
		amount
	)


func update_visual_rotation(delta: float) -> void:
	if control_frame == null:
		return

	# We use the ControlFrame direction instead of the RigidBody rotation.
	# This prevents the visual from spinning with bad physics rotation.
	var forward := -control_frame.global_transform.basis.z
	forward.y = 0.0

	if forward.length() < 0.01:
		return

	forward = forward.normalized()

	var target_yaw := atan2(-forward.x, -forward.z)
	target_yaw += deg_to_rad(model_yaw_offset_degrees)

	var current_rotation := visual_body.global_rotation
	current_rotation.x = 0.0
	current_rotation.z = 0.0

	current_rotation.y = lerp_angle(
		current_rotation.y,
		target_yaw,
		clamp(rotation_follow_speed * delta, 0.0, 1.0)
	)

	visual_body.global_rotation = current_rotation


func update_visual_pose(delta: float) -> void:
	if visual_root == null or control_frame == null:
		return

	var steer := float(control_frame.get("steer_input"))

	var target_yaw := deg_to_rad(-steer * steering_yaw_degrees)
	var target_roll := deg_to_rad(steer * steering_lean_degrees)

	var amount = clamp(pose_follow_speed * delta, 0.0, 1.0)

	visual_root.rotation.y = lerp_angle(
		visual_root.rotation.y,
		target_yaw,
		amount
	)

	visual_root.rotation.z = lerp_angle(
		visual_root.rotation.z,
		target_roll,
		amount
	)

	# Keep pitch clean for now.
	visual_root.rotation.x = lerp_angle(
		visual_root.rotation.x,
		0.0,
		amount
	)
