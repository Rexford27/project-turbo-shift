extends Node3D
class_name ControlFrame

# -------------------------
# Input values other scripts can read
# -------------------------

var throttle_input: float = 0.0
var steer_input: float = 0.0
var pitch_input: float = 0.0

# -------------------------
# Follow target
# This should be your VehicleBody RigidBody3D
# -------------------------

@export var follow_target: Node3D

# This moves the ControlFrame slightly above/around the target.
# Usually keep this small.
@export var target_position_offset: Vector3 = Vector3(0.0, 1.2, 0.0)

@export var snap_to_target: bool = true
@export var position_follow_speed: float = 60.0
@export var max_follow_distance: float = 5.0

# -------------------------
# Camera settings
# These control the actual camera view.
# -------------------------

@export var camera_pivot: Node3D
@export var gameplay_camera: Camera3D

# x = left/right, y = up/down, z = forward/back
# Positive Z usually means behind the ControlFrame in Godot.
@export var camera_position_offset: Vector3 = Vector3(0.0, 4.0, 8.0)

# Rotation in degrees.
# X negative means camera looks downward.
@export var camera_rotation_offset: Vector3 = Vector3(-12.0, 0.0, 0.0)

@export var camera_position_smoothness: float = 10.0
@export var camera_rotation_smoothness: float = 10.0

# -------------------------
# Steering settings
# -------------------------

@export var turn_speed: float = 2.8
@export var only_turn_while_moving: bool = false

# -------------------------
# Debug/free movement settings
# Used only when follow_target is empty
# -------------------------

@export var max_forward_speed: float = 22.0
@export var max_reverse_speed: float = 10.0
@export var acceleration: float = 20.0
@export var deceleration: float = 28.0

# -------------------------
# Flight settings
# -------------------------

@export var enable_flight: bool = false
@export var flight_pitch_speed: float = 75.0
@export var min_flight_pitch: float = -90.0
@export var max_flight_pitch: float = 90.0

# -------------------------
# Ground following settings
# Used only when there is no follow_target
# -------------------------

@export var height_above_ground: float = 2.0
@export var ground_follow_speed: float = 12.0

@onready var ground_ray: RayCast3D = $GroundRay

var current_speed: float = 0.0


func _ready() -> void:
	if camera_pivot == null and has_node("CameraPivot"):
		camera_pivot = $CameraPivot
	
	if gameplay_camera == null and has_node("CameraPivot/GameplayCamera"):
		gameplay_camera = $CameraPivot/GameplayCamera


func _physics_process(delta: float) -> void:
	read_input()
	handle_speed(delta)
	follow_target_position(delta)
	handle_turning(delta)
	handle_flight_pitch(delta)
	update_camera_offset(delta)

	if follow_target == null:
		handle_debug_movement(delta)

		if not enable_flight:
			follow_ground(delta)


func read_input() -> void:
	throttle_input = Input.get_action_strength("accelerate") - Input.get_action_strength("brake")#Input.get_axis("brake", "accelerate")
	steer_input = Input.get_axis("steer_left", "steer_right")
	pitch_input = Input.get_axis("steer_up", "steer_down")


func handle_speed(delta: float) -> void:
	if throttle_input > 0.0:
		current_speed = move_toward(
			current_speed,
			max_forward_speed * throttle_input,
			acceleration * delta
		)

	elif throttle_input < 0.0:
		current_speed = move_toward(
			current_speed,
			max_reverse_speed * throttle_input,
			acceleration * delta
		)

	else:
		current_speed = move_toward(
			current_speed,
			0.0,
			deceleration * delta
		)


func follow_target_position(delta: float) -> void:
	if follow_target == null:
		return

	var target_position := follow_target.global_position + target_position_offset
	var distance_to_target := global_position.distance_to(target_position)

	if snap_to_target:
		global_position = target_position
		return

	if distance_to_target > max_follow_distance:
		global_position = target_position
		return

	var smooth_amount = clamp(position_follow_speed * delta, 0.0, 1.0)
	global_position = global_position.lerp(target_position, smooth_amount)


func handle_turning(delta: float) -> void:
	if only_turn_while_moving and abs(current_speed) < 0.2:
		return

	rotate_y(-steer_input * turn_speed * delta)


func handle_flight_pitch(delta: float) -> void:
	if not enable_flight:
		rotation_degrees.x = lerp(rotation_degrees.x, 0.0, 8.0 * delta)
		return

	rotation_degrees.x += pitch_input * flight_pitch_speed * delta

	rotation_degrees.x = clamp(
		rotation_degrees.x,
		min_flight_pitch,
		max_flight_pitch
	)


func update_camera_offset(delta: float) -> void:
	if camera_pivot == null:
		return

	var position_amount = clamp(camera_position_smoothness * delta, 0.0, 1.0)
	var rotation_amount = clamp(camera_rotation_smoothness * delta, 0.0, 1.0)

	camera_pivot.position = camera_pivot.position.lerp(
		camera_position_offset,
		position_amount
	)

	camera_pivot.rotation_degrees.x = lerp(
		camera_pivot.rotation_degrees.x,
		camera_rotation_offset.x,
		rotation_amount
	)

	camera_pivot.rotation_degrees.y = lerp(
		camera_pivot.rotation_degrees.y,
		camera_rotation_offset.y,
		rotation_amount
	)

	camera_pivot.rotation_degrees.z = lerp(
		camera_pivot.rotation_degrees.z,
		camera_rotation_offset.z,
		rotation_amount
	)


func handle_debug_movement(delta: float) -> void:
	var forward_direction := -global_transform.basis.z.normalized()
	global_position += forward_direction * current_speed * delta


func follow_ground(delta: float) -> void:
	if ground_ray == null:
		return

	ground_ray.force_raycast_update()

	if ground_ray.is_colliding():
		var ground_y := ground_ray.get_collision_point().y
		var target_y := ground_y + height_above_ground

		var smooth_amount = clamp(ground_follow_speed * delta, 0.0, 1.0)
		global_position.y = lerp(global_position.y, target_y, smooth_amount)
