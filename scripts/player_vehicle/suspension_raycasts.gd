extends Node3D
class_name VehicleSuspension

# The RigidBody3D we are applying forces to.
@export var physics_ball: RigidBody3D

# Optional. Used so we can disable suspension during flight.
@export var control_frame: ControlFrame

# If true, suspension turns off when flight is enabled.
@export var disable_in_flight: bool = true


# -------------------------
# Suspension settings
# -------------------------

# How far each ray point wants to stay above the ground.
@export var rest_distance: float = 1#0.8

# Higher = stronger push upward.
@export var spring_strength: float = 30#30#4500.0

# Higher = less bouncing.
@export var spring_damping: float = 6#50.0

# Safety cap so the suspension does not explode.
@export var max_suspension_force: float = 30#000.0

# If true, the raycast rig follows the ball position every physics frame.
@export var follow_ball_position: bool = true

# If true, the raycast rig uses the ControlFrame yaw instead of spinning with the ball.
@export var use_control_frame_yaw: bool = true


var suspension_rays: Array[RayCast3D] = []


func _ready() -> void:
	find_suspension_rays()
	for ray in suspension_rays:
		ray.add_exception(physics_ball)



func _physics_process(delta: float) -> void:
	if physics_ball == null:
		return

	if disable_in_flight and control_frame != null and control_frame.enable_flight:
		return

	update_raycast_rig()

	for ray in suspension_rays:
		apply_suspension_force(ray)


func find_suspension_rays() -> void:
	suspension_rays.clear()

	for child in get_children():
		if child is RayCast3D:
			suspension_rays.append(child)
			child.enabled = true

	print("Suspension rays found: ", suspension_rays.size())


func update_raycast_rig() -> void:
	# Keep the raycast rig centered on the physics ball.
	if follow_ball_position:
		global_position = physics_ball.global_position

	# Important for ball collision:
	# The ball may spin, but we do NOT want the suspension raycasts spinning with it.
	if use_control_frame_yaw and control_frame != null:
		rotation_degrees.x = 0.0
		rotation_degrees.z = 0.0
		global_rotation.y = control_frame.global_rotation.y


func apply_suspension_force(ray: RayCast3D) -> void:
	if ray == null:
		return

	ray.force_raycast_update()

	if not ray.is_colliding():
		return


	var ray_world_position := ray.global_position
	var hit_position := ray.get_collision_point()

	var hit_distance := ray_world_position.distance_to(hit_position)

	# If the ray is farther from the ground than the rest distance,
	# the spring is not compressed, so it should not push.
	var compression := rest_distance - hit_distance

	if compression <= 0.0:
		return

	# We push upward.
	# Start with global up because it is stable and beginner-friendly.
	var force_direction := Vector3.UP

	# How fast this point on the physics ball is moving upward/downward.
	var point_velocity := get_point_velocity(ray_world_position)
	var velocity_along_spring := point_velocity.dot(force_direction)

	# Spring force pushes up based on compression.
	var spring_force := compression * spring_strength

	# Damping reduces bouncing.
	var damping_force := velocity_along_spring * spring_damping

	var final_force_amount := spring_force - damping_force

	final_force_amount = clamp(
		final_force_amount,
		0.0,
		max_suspension_force
	)

	var final_force := force_direction * final_force_amount

	# Apply force at this ray's position relative to the ball.
	var force_position := ray_world_position - physics_ball.global_position

	physics_ball.apply_force(final_force, force_position)


func get_point_velocity(world_point: Vector3) -> Vector3:
	# This gets the velocity of one point on the rigid body.
	# It includes normal linear movement plus rotation movement.
	var radius_from_center := world_point - physics_ball.global_position

	return physics_ball.linear_velocity + physics_ball.angular_velocity.cross(radius_from_center)
