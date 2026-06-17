@tool
extends RayCast3D
class_name GroundRay

@export var physics_ball: RigidBody3D

@export_group("Ray Settings")

# The actual RayCast3D length.
# This can be very long so it can find any surface below the ball.
@export var ray_length: float = 50.0:
	set(value):
		ray_length = max(value, 0.1)
		_update_ray_length()

# The max distance allowed before we say the ball is NOT touching the ground.
# Example: ray may hit something 40 units below, but the ball is only grounded if it is 5 or less.
@export var touching_distance: float = 5.0

@export_group("Air Alignment")

@export var align_speed: float = 5#20.0
@export var align_ball_while_airborne: bool = true

@export_group("Debug")

@export var print_debug: bool = false

var is_airborne: bool = false
var is_touching_ground: bool = false
var has_surface_below: bool = false

var distance_to_surface: float = 0.0
var last_ground_normal: Vector3 = Vector3.UP


func _ready() -> void:
	enabled = true
	_update_ray_length()

	if physics_ball != null:
		add_exception(physics_ball)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_update_ray_length()

		if physics_ball != null:
			follow_physics_ball()
			keep_raycast_pointing_down()


func _physics_process(delta: float) -> void:
	if physics_ball == null:
		return

	follow_physics_ball()
	keep_raycast_pointing_down()

	force_raycast_update()

	if is_colliding():
		has_surface_below = true

		var hit_position := get_collision_point()
		distance_to_surface = global_position.distance_to(hit_position)

		last_ground_normal = get_collision_normal()

		# The ray hit something, but we only count as grounded if it is close enough.
		is_touching_ground = distance_to_surface <= touching_distance
		is_airborne = not is_touching_ground

		if print_debug:
			print(
				"Surface below: true",
				" | Distance: ", distance_to_surface,
				" | Touching: ", is_touching_ground,
				" | Airborne: ", is_airborne
			)

		# If we are airborne but still see a surface below, align to that surface normal.
		if is_airborne and align_ball_while_airborne:
			align_ball(delta, last_ground_normal)

	else:
		has_surface_below = false
		is_touching_ground = false
		is_airborne = true
		distance_to_surface = ray_length

		if print_debug:
			print("No surface below | Airborne: true")

		# No surface below, so fall back to world up.
		if align_ball_while_airborne:
			align_ball(delta, Vector3.UP)


func follow_physics_ball() -> void:
	global_position = physics_ball.global_position


func keep_raycast_pointing_down() -> void:
	# Keeps the ray pointing straight down in world space.
	global_rotation = Vector3.ZERO


func _update_ray_length() -> void:
	target_position = Vector3.DOWN * ray_length


func align_ball(delta: float, ground_normal: Vector3) -> void:
	var current_transform := physics_ball.global_transform

	var target_transform := align_transform_with_y_axis(
		current_transform,
		ground_normal
	)

	var amount = clamp(align_speed * delta, 0.0, 1.0)

	physics_ball.global_transform = current_transform.interpolate_with(
		target_transform,
		amount
	)


func align_transform_with_y_axis(xform: Transform3D, new_y: Vector3) -> Transform3D:
	new_y = new_y.normalized()

	var forward := -xform.basis.z

	# Remove the part of forward that points into the ground normal.
	forward = forward - new_y * forward.dot(new_y)

	if forward.length() < 0.001:
		forward = Vector3.FORWARD

	forward = forward.normalized()

	xform.basis.y = new_y
	xform.basis.z = -forward
	xform.basis.x = xform.basis.y.cross(xform.basis.z).normalized()
	xform.basis = xform.basis.orthonormalized()

	return xform
