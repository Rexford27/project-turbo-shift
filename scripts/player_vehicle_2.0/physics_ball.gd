extends RigidBody3D
class_name PhysicsBallController2

@export var stats: VehicleStats2
@export var visual_body: Node3D
@export var ground_sensor: GroundSensor

@export_group("Input Actions")
@export var accelerate_action: StringName = "accelerate"
@export var brake_action: StringName = "brake"
@export var steer_left_action: StringName = "steer_left"
@export var steer_right_action: StringName = "steer_right"

@export_group("Ground Direction")

## When this is on, forward thrust follows the floor angle.
## This stops the ball from flying upward just because the VisualBody is tilted.
@export var align_thrust_to_ground_normal: bool = true


@export_group("Simple Wall Fix")

## Turn this on/off in the inspector.
## This stops the physics ball from climbing walls.
@export var prevent_wall_climb: bool = true

## Ground has high Y.
## Wall has low Y.
## If the collision normal Y is lower than this, we treat it like a wall.
@export var wall_normal_y_limit: float = 0.4

## If true, the ball cannot move upward while touching a wall.
@export var stop_upward_wall_velocity: bool = true

## If true, the ball cannot spin while touching a wall.
## This helps stop the sphere from rolling up the wall.
@export var stop_wall_spin: bool = true


var throttle: float = 0.0
var steer: float = 0.0


func _ready():
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.5, 0)

	# Needed so _integrate_forces can read collision contacts.
	contact_monitor = true
	max_contacts_reported = 8


func _physics_process(delta: float) -> void:
	if stats == null or visual_body == null:
		return

	_read_input()
	_turn_visual_body(delta)
	_drive()
	_apply_side_grip()
	_apply_drag()
	_snap_to_ground()
	_limit_speed()


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_prevent_wall_climb(state)


func _read_input() -> void:
	throttle = Input.get_action_strength(accelerate_action) - Input.get_action_strength(brake_action)
	steer = Input.get_action_strength(steer_right_action) - Input.get_action_strength(steer_left_action)


func _turn_visual_body(delta: float) -> void:
	if abs(steer) < 0.01:
		return

	var flat_speed := Vector3(linear_velocity.x, 0.0, linear_velocity.z).length()

	if flat_speed < stats.min_speed_to_turn and abs(throttle) < 0.1:
		return

	var turn_power = stats.turn_speed

	# Later, when you add air state:
	#if ground_sensor != null and not ground_sensor.is_grounded:
		#turn_power = stats.air_turn_speed

	visual_body.rotate_y(-steer * turn_power * delta)


func _drive() -> void:
	var forward := _get_visual_forward()
	var forward_speed := linear_velocity.dot(forward)

	if throttle > 0.0:
		if forward_speed < stats.max_forward_speed:
			apply_central_force(forward * throttle * stats.acceleration_force)

	elif throttle < 0.0:
		if forward_speed > 1.0:
			apply_central_force(-forward * stats.brake_force)
		elif abs(forward_speed) < stats.max_reverse_speed:
			apply_central_force(forward * throttle * stats.reverse_force)


func _apply_side_grip() -> void:
	var right = visual_body.global_transform.basis.x

	if align_thrust_to_ground_normal and ground_sensor != null and ground_sensor.is_grounded:
		right = right.slide(ground_sensor.ground_normal)
	else:
		right.y = 0.0

	if right.length() < 0.01:
		return

	right = right.normalized()

	var side_velocity = right * linear_velocity.dot(right)
	apply_central_force(-side_velocity * stats.side_grip_force)


func _apply_drag() -> void:
	var drag = stats.ground_drag

	if ground_sensor != null and not ground_sensor.is_grounded:
		drag = stats.air_drag

	var flat_velocity := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	apply_central_force(-flat_velocity * drag)


func _snap_to_ground() -> void:
	if ground_sensor == null:
		return

	if not ground_sensor.is_grounded:
		return

	# Only snap to actual floor-like surfaces.
	# If the ray hits a steep wall, do not snap into it.
	if ground_sensor.ground_normal.y < 0.5:
		return

	apply_central_force(-ground_sensor.ground_normal * stats.ground_snap_force)


func _limit_speed() -> void:
	var flat_velocity := Vector3(linear_velocity.x, 0.0, linear_velocity.z)

	if flat_velocity.length() > stats.max_total_speed:
		flat_velocity = flat_velocity.normalized() * stats.max_total_speed
		linear_velocity.x = flat_velocity.x
		linear_velocity.z = flat_velocity.z


func _get_visual_forward() -> Vector3:
	var forward := -visual_body.global_transform.basis.z

	if align_thrust_to_ground_normal and ground_sensor != null and ground_sensor.is_grounded:
		# This removes the part of the direction that points into/out of the floor.
		# The result is a forward direction that runs along the road surface.
		forward = forward.slide(ground_sensor.ground_normal)
	else:
		# Keeps thrust flat on the world X/Z plane.
		forward.y = 0.0

	if forward.length() < 0.01:
		return Vector3.FORWARD

	return forward.normalized()


func _prevent_wall_climb(state: PhysicsDirectBodyState3D) -> void:
	if not prevent_wall_climb:
		return

	var touching_wall := false

	for i in range(state.get_contact_count()):
		var local_normal := state.get_contact_local_normal(i)

		# Convert the collision normal from local space to world space.
		var world_normal := state.transform.basis * local_normal
		world_normal = world_normal.normalized()

		# Floor normal has high Y.
		# Wall normal has low Y.
		if abs(world_normal.y) < wall_normal_y_limit:
			touching_wall = true
			break

	if not touching_wall:
		return

	var velocity := state.linear_velocity

	# Main simple fix:
	# If the ball touches a wall, it cannot keep upward speed.
	# It can still slide left/right along the wall.
	if stop_upward_wall_velocity and velocity.y > 0.0:
		velocity.y = 0.0
		state.linear_velocity = velocity

	# Optional:
	# Stop spin so the ball does not roll itself up the wall.
	if stop_wall_spin:
		state.angular_velocity = Vector3.ZERO
