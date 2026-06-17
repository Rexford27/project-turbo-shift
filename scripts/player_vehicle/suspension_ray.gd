@tool
extends RayCast3D
class_name SuspensionRay2

@export_group("Suspension Setup")

## The RigidBody3D that this suspension ray will push.
## If left empty, the script tries to use the parent-parent node.
@export var physics_ball: RigidBody3D

## Spring strength.
## Higher values push the vehicle upward harder.
## Increase this if the car sinks too much.
@export var k: float = 60.0

## Damping strength.
## Higher values reduce bouncing.
## Increase this if the car keeps bouncing after landing.
@export var damping: float = 2.0

## Maximum suspension distance.
## This controls how far down the ray checks for the ground.
@export var suspension_length: float = 0.9:
	set(value):
		suspension_length = max(value, 0.01)
		_update_ray_length()

## Maximum force this suspension ray can apply.
## Increase this if the suspension feels too weak.
## Decrease this if the car launches upward too hard.
@export var max_force: float = 200.0

## Turns this suspension ray on or off.
## Disable this if you want this ray to stop applying suspension force.
@export var active: bool = true:
	set(value):
		active = value
		if is_inside_tree():
			set_physics_process(active)

@export_group("")

# === INTERNALS ===
var rest_length: float


func _ready() -> void:
	if physics_ball == null:
		physics_ball = $"../.." as RigidBody3D

	if physics_ball != null:
		add_exception(physics_ball)

	enabled = true
	rest_length = suspension_length
	_update_ray_length()
	set_physics_process(active)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_update_ray_length()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if active == false:
		return

	if physics_ball == null:
		return

	force_raycast_update()

	if not is_colliding():
		return

	var p1: Vector3 = global_position
	var hit_point: Vector3 = get_collision_point()
	var collision_normal: Vector3 = get_collision_normal().normalized()

	var current_length: float = p1.distance_to(hit_point)
	var x: float = current_length - rest_length

	# Hooke's law force
	var f: float = -k * x

	# Add damping based on velocity at the hit point
	var point_vel: Vector3 = get_point_velocity(hit_point)
	f += -damping * point_vel.dot(collision_normal)

	# Suspension should only push, not pull down
	f = clamp(f, 0.0, max_force)

	# Final force direction is aligned with collision normal
	var force: Vector3 = collision_normal * f

	# Apply force at the hit point
	physics_ball.apply_force(force, hit_point - physics_ball.global_position)


func _update_ray_length() -> void:
	target_position = Vector3(0.0, -suspension_length, 0.0)
	rest_length = suspension_length


func get_point_velocity(point: Vector3) -> Vector3:
	return physics_ball.linear_velocity + physics_ball.angular_velocity.cross(point - physics_ball.global_position)
