extends Node3D
class_name GroundSensor

@export var alignment_ray: RayCast3D
@export var ground_ray: RayCast3D

@export var physics_ball: RigidBody3D
@export var visual_body: Node3D

@export_group("Update")
@export var auto_update: bool = true

@export_group("Air Alignment")

## Turn this on/off in the inspector.
@export var align_body_in_air: bool = true

## How fast the body rotates to match the ground normal while in air.
@export var air_align_speed: float = 5.0

## The body we want to rotate.
## Drag your VisualBody here.
## If you really want to rotate the RigidBody ball, drag PhysicsBall here instead.
@export var body_to_align: Node3D


var is_grounded: bool = false
var is_aligned: bool = false

var ground_normal: Vector3 = Vector3.UP
var ground_point: Vector3 = Vector3.ZERO

var alignment_normal: Vector3 = Vector3.UP
var alignment_point: Vector3 = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if auto_update:
		update_sensor()

	align_body_to_ground_in_air(delta)


func update_sensor() -> void:
	_update_ray_positions()

	if alignment_ray != null:
		alignment_ray.force_raycast_update()

	if ground_ray != null:
		ground_ray.force_raycast_update()

	_check_rays()


func _update_ray_positions() -> void:
	# The alignment ray follows the physics ball.
	# This ray is usually longer and helps us find the ground while the kart is in air.
	if physics_ball != null and alignment_ray != null:
		alignment_ray.global_position = physics_ball.global_position

	# The ground ray follows the visual body.
	# This ray is usually shorter and tells us if the kart is actually grounded.
	if visual_body != null and ground_ray != null:
		ground_ray.global_position = visual_body.global_position + (Vector3.UP * 1 )
		ground_ray.global_rotation = visual_body.global_rotation


func _check_rays() -> void:
	is_aligned = alignment_ray != null and alignment_ray.is_colliding()
	is_grounded = ground_ray != null and ground_ray.is_colliding()

	if is_aligned:
		alignment_normal = alignment_ray.get_collision_normal()
		alignment_point = alignment_ray.get_collision_point()
	else:
		alignment_normal = Vector3.UP
		alignment_point = Vector3.ZERO

	if is_grounded:
		ground_normal = ground_ray.get_collision_normal()
		ground_point = ground_ray.get_collision_point()
	elif is_aligned:
		# When we are in air, the ground ray may not touch.
		# So we use the longer alignment ray to still know the ground direction.
		ground_normal = alignment_normal
		ground_point = alignment_point
	else:
		ground_normal = Vector3.UP
		ground_point = Vector3.ZERO


func align_body_to_ground_in_air(delta: float) -> void:
	if not align_body_in_air:
		return

	if body_to_align == null:
		return

	# Important:
	# We only align while in the air.
	# If the ground ray is touching, the kart is grounded, so we stop.
	if is_grounded:
		return

	var target_normal := Vector3.UP

	# If the long alignment ray sees the ground, use that ground normal.
	if is_aligned:
		target_normal = alignment_normal
	print("yiiooo")
	var target_transform := align_body_with_y(
		body_to_align.global_transform,
		target_normal
	)

	body_to_align.global_transform = body_to_align.global_transform.interpolate_with(
		target_transform,
		clamp(air_align_speed * delta, 0.0, 1.0)
	)


func align_body_with_y(xform: Transform3D, new_y: Vector3) -> Transform3D:

	
	# This makes the body's local Y axis point in the same direction as the ground normal.

	new_y = new_y.normalized()

	xform.basis.y = new_y

	# Rebuild the X axis so the body does not become crooked.
	xform.basis.x = -xform.basis.z.cross(new_y)

	# Clean up the rotation so the axes stay proper.
	xform.basis = xform.basis.orthonormalized()

	return xform
