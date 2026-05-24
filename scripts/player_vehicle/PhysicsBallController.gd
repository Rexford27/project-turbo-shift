extends RigidBody3D
class_name PhysicsBallController

# The ControlFrame tells us:
# - what direction the player/camera is facing
# - throttle input
# - steering input
@export var control_frame: ControlFrame


# -------------------------
# Speed settings
# -------------------------

@export var max_forward_speed: float = 28.0
@export var max_reverse_speed: float = 20.0

@export var acceleration_force: float = 30#12000.0
@export var brake_force: float = 30#9000.0


# -------------------------
# Grip / sliding settings
# -------------------------

# Higher = less sideways sliding.
# Lower = more drift/sliding.
@export var side_grip_force: float = 2#10#8000.0

# Small drag to calm the ball down.
@export var drag: float = 0.8


# -------------------------
# Safety
# -------------------------

@export var max_total_speed: float = 40.0

@export var flight_direction_grip: float = 20#9000.0
var flight_correction_time: float = 0.35
var flight_deadzone_speed: float = 0.4

func _ready() -> void:
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -1.5, 0) # lower than the body origin

func _physics_process(delta: float) -> void:
	if control_frame == null:
		return

	apply_drive_force(delta)
	apply_side_grip(delta)
	if control_frame.enable_flight:
		apply_flight_direction_grip(delta)
	apply_drag(delta)
	limit_speed()



func apply_flight_direction_grip(delta: float) -> void:
	# Direction the camera/control frame is looking.
	var desired_direction := -control_frame.global_transform.basis.z.normalized()

	# Current ball velocity.
	var current_velocity := linear_velocity

	# If the ball is barely moving, don't try to correct it.
	if current_velocity.length() < 0.1:
		return

	# This is how much of our current speed is already going in the desired direction.
	var forward_speed := current_velocity.dot(desired_direction)

	# This is the part of our velocity NOT facing the camera direction.
	# This is the part we want to gently remove.
	var unwanted_velocity := current_velocity - (desired_direction * forward_speed)

	# Tiny corrections can cause jitter, so ignore them.
	if unwanted_velocity.length() < flight_deadzone_speed:
		return

	# Instead of correcting instantly in 1 frame, correct over time.
	var needed_acceleration := -unwanted_velocity / flight_correction_time
	var force := needed_acceleration * mass

	# Limit force so it does not violently snap.
	if force.length() > flight_direction_grip:
		force = force.normalized() * flight_direction_grip

	apply_central_force(force)

func apply_drive_force(delta: float) -> void:
	var throttle := control_frame.throttle_input

	# No throttle? Do not push.
	if abs(throttle) < 0.01:
		return

	# Godot forward is usually -Z.
	var forward_dir := -control_frame.global_transform.basis.z.normalized()

	var target_speed := max_forward_speed * throttle

	if throttle < 0.0:
		target_speed = max_reverse_speed * throttle

	var current_forward_speed := linear_velocity.dot(forward_dir)

	var speed_difference := target_speed - current_forward_speed

	var force_to_use := acceleration_force

	if throttle < 0.0:
		force_to_use = brake_force

	var force_amount = clamp(
		speed_difference * mass / delta,
		-force_to_use,
		force_to_use
	)

	apply_central_force(forward_dir * force_amount)


func apply_side_grip(delta: float) -> void:
	# This finds the sideways direction of the ControlFrame.
	var side_dir := control_frame.global_transform.basis.x.normalized()

	# This checks how much the ball is sliding sideways.
	var side_speed := linear_velocity.dot(side_dir)

	# We want sideways speed to become 0.
	var needed_acceleration := -side_speed / delta

	var force_amount := mass * needed_acceleration

	force_amount = clamp(
		force_amount,
		-side_grip_force,
		side_grip_force
	)

	apply_central_force(side_dir * force_amount)


func apply_drag(delta: float) -> void:
	# Simple drag that slows the ball down a little over time.
	linear_velocity.x = move_toward(linear_velocity.x, 0.0, drag * delta)
	linear_velocity.z = move_toward(linear_velocity.z, 0.0, drag * delta)


func limit_speed() -> void:
	var horizontal_velocity := Vector3(linear_velocity.x, 0.0, linear_velocity.z)

	if horizontal_velocity.length() > max_total_speed:
		horizontal_velocity = horizontal_velocity.normalized() * max_total_speed

		linear_velocity.x = horizontal_velocity.x
		linear_velocity.z = horizontal_velocity.z
