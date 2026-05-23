extends RayCast3D
class_name SuspensionRay

@export var physics_ball: RigidBody3D

# How high this ray wants to stay above the ground.
@export var rest_distance: float = 0.8

# Higher = pushes the ball up harder.
@export var spring_strength: float = 60.0

# Higher = less bouncing.
@export var damping: float = 8.0

# Maximum force this ray can apply.
@export var max_force: float = 90.0


func _ready() -> void:
	enabled = true


func _physics_process(delta: float) -> void:
	if physics_ball == null:
		return

	force_raycast_update()

	if not is_colliding():
		return

	var ray_position := global_position
	var hit_position := get_collision_point()

	var distance_to_ground := ray_position.distance_to(hit_position)

	var compression := rest_distance - distance_to_ground

	if compression <= 0.0:
		return

	var force_direction := Vector3.UP

	var point_velocity := get_point_velocity(ray_position)
	var vertical_speed := point_velocity.dot(force_direction)

	var spring_force := compression * spring_strength
	var damping_force := vertical_speed * damping

	var final_force_amount := spring_force - damping_force

	final_force_amount = clamp(final_force_amount, 0.0, max_force)

	var final_force := force_direction * final_force_amount

	var force_position := ray_position - physics_ball.global_position

	physics_ball.apply_force(final_force, force_position)


func get_point_velocity(world_point: Vector3) -> Vector3:
	var offset_from_center := world_point - physics_ball.global_position

	return physics_ball.linear_velocity + physics_ball.angular_velocity.cross(offset_from_center)
