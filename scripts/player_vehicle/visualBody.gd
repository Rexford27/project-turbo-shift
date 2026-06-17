@tool
extends Node3D
class_name VisualBody

@export var physics_ball: RigidBody3D:
	set(value):
		physics_ball = value
		_update_editor_preview()

@export var control_frame: ControlFrame:
	set(value):
		control_frame = value
		_update_editor_preview()

# Optional:
# Drag your ground ray here if it has a variable called last_ground_normal.
# Example: ControlFrame/ground_ray or ground_cast.
@export var ground_normal_source: Node

@export_group("Follow")

@export var visual_position_offset: Vector3 = Vector3.ZERO:
	set(value):
		visual_position_offset = value
		_update_editor_preview()

# Keep this ON if VisualBody is a child of PhysicsBall.
# This lets it stay organized under PhysicsBall without inheriting the ball's rolling spin.
@export var ignore_parent_rotation: bool = true

@export_group("Rotation")

# Use 0 if your model faces forward correctly.
# Use 180 if the model faces backward.
@export var model_yaw_offset_degrees: float = 180.0:
	set(value):
		model_yaw_offset_degrees = value
		_update_editor_preview()

# Higher = faster visual alignment.
# Lower = softer, less stiff.
@export var rotation_follow_speed: float = 8.0

# Higher = follows ramp/ground normal faster.
@export var ground_align_speed: float = 10.0

@export_group("Editor Preview")

@export var preview_in_editor: bool = true:
	set(value):
		preview_in_editor = value
		_update_editor_preview()


func _ready() -> void:
	# Important:
	# If VisualBody is under PhysicsBall, this prevents it from inheriting
	# the ball's rolling/spinning rotation.
	if not Engine.is_editor_hint() and ignore_parent_rotation:
		set_as_top_level(true)

	_update_editor_preview()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_update_editor_preview()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if ignore_parent_rotation and not is_set_as_top_level():
		set_as_top_level(true)

	_follow_ball()
	_align_to_camera_and_ground(delta)


func _follow_ball() -> void:
	if physics_ball == null:
		return

	global_position = physics_ball.global_position + visual_position_offset


func _align_to_camera_and_ground(delta: float) -> void:
	if control_frame == null:
		return

	var amount = clamp(rotation_follow_speed * delta, 0.0, 1.0)

	var target_up := _get_target_up()
	var target_forward := _get_target_forward_on_ground(target_up)

	if target_forward.length_squared() < 0.001:
		return

	var target_basis := _make_vehicle_basis(target_forward, target_up)

	global_basis = global_basis.slerp(target_basis, amount).orthonormalized()


func _get_target_up() -> Vector3:
	# Best option: use the ground/ramp normal from your raycast.
	if ground_normal_source != null:
		var normal = ground_normal_source.get("last_ground_normal")

		if normal is Vector3:
			if normal.length_squared() > 0.001:
				return normal.normalized()

	# Fallback: use current up so it does not suddenly snap.
	if global_basis.y.length_squared() > 0.001:
		return global_basis.y.normalized()

	return Vector3.UP


func _get_target_forward_on_ground(up_axis: Vector3) -> Vector3:
	var forward := -control_frame.global_basis.z

	# Remove the part going into the ground/up direction.
	# This means the car faces the camera direction while still respecting the ramp angle.
	forward = forward.slide(up_axis)

	if forward.length_squared() < 0.001:
		return -global_basis.z.slide(up_axis).normalized()

	forward = forward.normalized()

	if abs(model_yaw_offset_degrees) > 0.001:
		forward = forward.rotated(up_axis, deg_to_rad(model_yaw_offset_degrees))

	return forward.normalized()


func _make_vehicle_basis(forward: Vector3, up_axis: Vector3) -> Basis:
	# Godot vehicle forward is usually -Z.
	var right := forward.cross(up_axis).normalized()
	var corrected_forward := up_axis.cross(right).normalized()

	return Basis(
		right,
		up_axis,
		-corrected_forward
	).orthonormalized()


func _update_editor_preview() -> void:
	if not Engine.is_editor_hint():
		return

	if not preview_in_editor:
		return

	if physics_ball == null:
		return

	global_position = physics_ball.global_position + visual_position_offset
