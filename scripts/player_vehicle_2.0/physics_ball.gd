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

var throttle: float = 0.0
var steer: float = 0.0

func _ready():
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.5, 0)

func _physics_process(delta: float) -> void:
	if stats == null or visual_body == null:
		return

	_read_input()
	_turn_visual_body(delta)
	_drive()
	_apply_side_grip() #kOnly
	_apply_drag() #Konly
	_snap_to_ground() #kOnly
	_limit_speed()


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

	#kart only code fix later working code 
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

	if ground_sensor.is_grounded:
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
		# Old simple behavior.
		# Keeps thrust flat on the world X/Z plane.
		forward.y = 0.0

	if forward.length() < 0.01:
		return Vector3.FORWARD

	return forward.normalized()
