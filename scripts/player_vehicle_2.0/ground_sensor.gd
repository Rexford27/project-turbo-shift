extends Node3D
class_name GroundSensor

@export var alignment_ray: RayCast3D
@export var ground_ray: RayCast3D

@export var physics_ball: RigidBody3D
@export var visual_body: Node3D
#
#@export var alignment_ray_name: String = "AligmentRay"
#@export var ground_ray_name: String = "groundRay"

@export_group("Alignment")
@export var align_visual_body: bool = true
@export var align_speed: float = 12.0

var is_grounded: bool = false
var is_aligned: bool = false
var ground_normal: Vector3 = Vector3.UP
var ground_point: Vector3 = Vector3.ZERO





#func _ready() -> void:
	#alignment_ray = get_node(alignment_ray_name)
	#ground_ray = get_node(ground_ray_name)


func _physics_process(delta: float) -> void:
	_update_ray_positions()
	_check_rays()
	_align_visual_body(delta)


func _update_ray_positions() -> void:
	if physics_ball != null:
		alignment_ray.global_position = physics_ball.global_position

	if visual_body != null:
		ground_ray.global_position = visual_body.global_position
		ground_ray.global_rotation = visual_body.global_rotation

	#alignment_ray.force_raycast_update()
	#ground_ray.force_raycast_update()


func _check_rays() -> void:
	is_aligned = alignment_ray.is_colliding()
	is_grounded = ground_ray.is_colliding()

	if ground_ray.is_colliding():
		ground_normal = ground_ray.get_collision_normal()
		ground_point = ground_ray.get_collision_point()
	else:
		ground_normal = Vector3.UP
		ground_point = Vector3.ZERO


func _align_visual_body(delta: float) -> void:
	if not align_visual_body:
		return

	if visual_body == null:
		return

	if not alignment_ray.is_colliding():
		return

	var new_y := alignment_ray.get_collision_normal()

	var target_transform := align_with_y(visual_body.global_transform, new_y)

	visual_body.global_transform = visual_body.global_transform.interpolate_with(
		target_transform,
		clamp(align_speed * delta, 0.0, 1.0)
	)


func align_with_y(xform: Transform3D, new_y: Vector3) -> Transform3D:
	xform.basis.y = new_y.normalized()
	xform.basis.x = -xform.basis.z.cross(new_y.normalized())
	xform.basis = xform.basis.orthonormalized()
	return xform
