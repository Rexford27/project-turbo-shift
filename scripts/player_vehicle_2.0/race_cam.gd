extends Camera3D
class_name VehicleCameraFollow2


@export_group("Follow")

## The object the camera follows.
## Usually this should be your VisualBody, not the PhysicsBall.
@export var target: Node3D

## The object used to read speed from.
## Usually this should be your PhysicsBall because it has linear_velocity.
@export var speed_source: RigidBody3D

## The camera's distance from the target.
## X = left/right offset.
## Y = height above the target.
## Z = distance behind the target.
## Positive Z means behind the target.
@export var follow_offset: Vector3 = Vector3(0.0, 2.0, 5.5)

## How high above the target the camera looks.
## Higher = camera looks more toward the top of the vehicle.
## Lower = camera looks closer to the ground/body center.
@export var look_height: float = 1.0

## How quickly the camera moves to its follow position.
## Higher = tighter/faster camera.
## Lower = smoother/slower camera.
@export var follow_speed: float = 8.0

## How quickly the camera rotates to look at the target.
## Higher = camera aims faster.
## Lower = camera turns more smoothly.
@export var look_speed: float = 10.0


@export_group("FOV")

## The normal camera FOV when the vehicle is slow or stopped.
## Lower = more zoomed in.
## Higher = wider view.
@export var min_fov: float = 75.0

## The widest FOV when the vehicle is moving fast.
## Higher = stronger speed effect.
@export var max_fov: float = 90.0

## The speed needed to reach max_fov.
## Lower = FOV widens sooner.
## Higher = vehicle must go faster before reaching max FOV.
@export var speed_for_max_fov: float = 30.0

## How quickly the FOV changes.
## Higher = FOV reacts faster.
## Lower = FOV changes more smoothly.
@export var fov_change_speed: float = 5.0


func _physics_process(delta: float) -> void:
	if target == null:
		return

	_follow_target(delta)
	_look_at_target(delta)
	_update_fov(delta)


func _follow_target(delta: float) -> void:
	# Offset follows the target rotation.
	# This keeps the camera behind the vehicle.
	var target_position := target.global_position + target.global_transform.basis * follow_offset

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
