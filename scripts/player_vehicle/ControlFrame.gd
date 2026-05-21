extends Node3D
class_name ControlFrame

# -------------------------
# Input values
# Other scripts can read these.
# -------------------------

var throttle_input: float = 0.0
var steer_input: float = 0.0
var pitch_input: float = 0.0


# -------------------------
# Target to follow
# This should be your PhysicsBall / RigidBody3D.
# -------------------------

@export var follow_target: Node3D

# Moves the ControlFrame slightly above the ball.
@export var target_offset: Vector3 = Vector3(0.0, 1.2, 0.0)

# Keep this true for now so the camera stays attached to the ball.
@export var snap_to_target: bool = true

# Only used if snap_to_target is false.
@export var follow_speed: float = 20.0


# -------------------------
# Steering
# -------------------------

@export var turn_speed: float = 2.8


# -------------------------
# Flight pitch
# This only works when enable_flight is true.
# -------------------------

@export var enable_flight: bool = true
@export var flight_pitch_speed: float = 75.0
@export var min_flight_pitch: float = -70.0
@export var max_flight_pitch: float = 70.0


# -------------------------
# Camera
# -------------------------

@export var camera_pivot: Node3D

# X = left/right
# Y = up/down
# Z = forward/back
# Positive Z means behind the vehicle/control direction.
@export var camera_offset: Vector3 = Vector3(0.0, 1.153, 4.224)

# Negative X looks downward.
@export var camera_rotation: Vector3 = Vector3(-12.0, 0.0, 0.0)

@export var camera_smoothness: float = 80.0


func _ready() -> void:
	if camera_pivot == null and has_node("CameraPivot"):
		camera_pivot = $CameraPivot


func _physics_process(delta: float) -> void:
	read_input()
	follow_target_position(delta)
	rotate_control_frame(delta)
	handle_flight_pitch(delta)
	update_camera(delta)


func read_input() -> void:
	throttle_input = Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
	steer_input = Input.get_axis("steer_left", "steer_right")

	# This is still read every frame, but only used when enable_flight is true.
	pitch_input = Input.get_axis("steer_up", "steer_down")


func follow_target_position(delta: float) -> void:
	if follow_target == null:
		return

	var target_position := follow_target.global_position + target_offset

	if snap_to_target:
		global_position = target_position
	else:
		var amount = clamp(follow_speed * delta, 0.0, 1.0)
		global_position = global_position.lerp(target_position, amount)


func rotate_control_frame(delta: float) -> void:
	# A/D rotates left and right.
	rotate_y(-steer_input * turn_speed * delta)


func handle_flight_pitch(delta: float) -> void:
	# If flight is off, slowly return the camera/control pitch back to normal.
	if enable_flight == false:
		rotation_degrees.x = lerp(rotation_degrees.x, 0.0, 8.0 * delta)
		return

	# If flight is on, steer_up / steer_down controls pitch.
	rotation_degrees.x += pitch_input * flight_pitch_speed * delta

	rotation_degrees.x = clamp(
		rotation_degrees.x,
		min_flight_pitch,
		max_flight_pitch
	)


func update_camera(delta: float) -> void:
	if camera_pivot == null:
		return

	var amount = clamp(camera_smoothness * delta, 0.0, 1.0)

	camera_pivot.position = camera_pivot.position.lerp(camera_offset, amount)
 
	camera_pivot.rotation_degrees.x = lerp(
		camera_pivot.rotation_degrees.x,
		camera_rotation.x,
		amount
	)

	camera_pivot.rotation_degrees.y = lerp(
		camera_pivot.rotation_degrees.y,
		camera_rotation.y,
		amount
	)

	camera_pivot.rotation_degrees.z = lerp(
		camera_pivot.rotation_degrees.z,
		camera_rotation.z,
		amount
	)
