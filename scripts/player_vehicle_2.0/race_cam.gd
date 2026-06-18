extends Camera3D
class_name VehicleCameraFollow2


@export_group("Follow")

## The object the camera follows.
## Usually this should be your VisualBody.
@export var target: Node3D

## The object used to read speed from.
## Usually this should be your PhysicsBall.
@export var speed_source: RigidBody3D

## Normal camera offset.
## This is used if Use Speed Based Offsets is turned off.
@export var follow_offset: Vector3 = Vector3(0.0, 2.0, 5.5)

## How high above the target the camera looks.
@export var look_height: float = 1.0

## How quickly the camera moves to its follow position.
@export var follow_speed: float = 8.0

## How quickly the camera rotates to look at the target.
@export var look_speed: float = 10.0


@export_group("Speed Based Offsets")

## Turn this on to use different camera offsets for forward, idle, and reverse.
## Turn this off to only use Follow Offset.
@export var use_speed_based_offsets: bool = true

## Camera offset while driving forward.
## Copy your current perfect forward camera values here.
@export var forward_offset: Vector3 = Vector3(0.0, 2.2, 2.2)

## Camera offset when the vehicle is not moving.
## Use this to make sure you can see the car while stopped.
@export var idle_offset: Vector3 = Vector3(0.0, 2.5, 4.0)

## Camera offset while reversing.
## This does NOT flip the camera. It only changes distance/height.
@export var reverse_offset: Vector3 = Vector3(0.0, 2.5, 5.0)

## Speed below this counts as idle/stopped.
@export var idle_speed_deadzone: float = 0.5

## Speed needed to fully use the forward offset.
@export var speed_for_full_forward_offset: float = 10.0

## Speed needed to fully use the reverse offset.
@export var speed_for_full_reverse_offset: float = 6.0

## How quickly the camera changes between forward, idle, and reverse offsets.
@export var offset_lerp_speed: float = 6.0


@export_group("FOV")

## The normal camera FOV when the vehicle is slow or stopped.
@export var min_fov: float = 75.0

## The widest FOV when the vehicle is moving fast.
@export var max_fov: float = 90.0

## The speed needed to reach max_fov.
@export var speed_for_max_fov: float = 30.0

## How quickly the FOV changes.
@export var fov_change_speed: float = 5.0


var current_offset: Vector3


func _ready() -> void:
	current_offset = follow_offset


func _physics_process(delta: float) -> void:
	if target == null:
		return

	_update_offset(delta)
	_follow_target(delta)
	_look_at_target(delta)
	_update_fov(delta)


func _update_offset(delta: float) -> void:
	if not use_speed_based_offsets:
		current_offset = current_offset.lerp(
			follow_offset,
			clamp(offset_lerp_speed * delta, 0.0, 1.0)
		)
		return

	var signed_speed := _get_signed_speed()
	var target_offset := idle_offset

	if signed_speed > idle_speed_deadzone:
		var amount = clamp(signed_speed / speed_for_full_forward_offset, 0.0, 1.0)
		target_offset = idle_offset.lerp(forward_offset, amount)

	elif signed_speed < -idle_speed_deadzone:
		var amount = clamp(abs(signed_speed) / speed_for_full_reverse_offset, 0.0, 1.0)
		target_offset = idle_offset.lerp(reverse_offset, amount)

	current_offset = current_offset.lerp(
		target_offset,
		clamp(offset_lerp_speed * delta, 0.0, 1.0)
	)


func _follow_target(delta: float) -> void:
	var target_position := target.global_position + target.global_transform.basis * current_offset

	global_position = global_position.lerp(
		target_position,
		clamp(follow_speed * delta, 0.0, 1.0)
	)


func _look_at_target(delta: float) -> void:
	var look_position := target.global_position + Vector3.UP * look_height

	var wanted_transform := global_transform.looking_at(look_position, Vector3.UP)

	global_transform.basis = global_transform.basis.slerp(
		wanted_transform.basis,
		clamp(look_speed * delta, 0.0, 1.0)
	)


func _update_fov(delta: float) -> void:
	var speed := 0.0

	if speed_source != null:
		speed = speed_source.linear_velocity.length()

	var speed_percent = clamp(speed / speed_for_max_fov, 0.0, 1.0)
	var target_fov = lerp(min_fov, max_fov, speed_percent)

	fov = lerp(fov, target_fov, clamp(fov_change_speed * delta, 0.0, 1.0))


func _get_signed_speed() -> float:
	if speed_source == null:
		return 0.0

	var forward := -target.global_transform.basis.z
	forward.y = 0.0

	if forward.length() < 0.01:
		return 0.0

	forward = forward.normalized()

	var flat_velocity := speed_source.linear_velocity
	flat_velocity.y = 0.0

	return flat_velocity.dot(forward)
