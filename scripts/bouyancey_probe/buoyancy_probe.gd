extends Node3D
class_name BuoyancyProbe

@export var water: StaticWorldOcean

@export_group("Buoyancy")
@export var buoyancy_strength: float = 80.0
@export var submersion_depth: float = 1.0
@export var vertical_damping: float = 8.0
@export var water_drag: float = 2.0

@export_group("Debug")
@export var print_debug: bool = false

var body: RigidBody3D


func _ready() -> void:
	body = _find_parent_rigidbody()

	if body == null:
		push_warning("BuoyancyProbe needs to be a child of a RigidBody3D.")

	if water == null:
		water = get_tree().get_first_node_in_group("water") as StaticWorldOcean

	if water == null:
		push_warning("BuoyancyProbe has no water assigned. Drag OceanWater into the water slot or add OceanWater to group 'water'.")


func _physics_process(_delta: float) -> void:
	if body == null:
		return

	if water == null:
		return

	_apply_buoyancy()


func _apply_buoyancy() -> void:
	var probe_world_position: Vector3 = global_position

	var depth_under_water: float = water.get_submersion_depth(probe_world_position)

	if depth_under_water <= 0.0:
		if print_debug:
			print(name, " is above water. Probe Y: ", probe_world_position.y)
		return

	var submersion_amount: float = clamp(depth_under_water / submersion_depth, 0.0, 1.0)

	var water_up: Vector3 = water.get_water_up_direction().normalized()

	var point_velocity: Vector3 = _get_velocity_at_world_point(probe_world_position)

	var velocity_along_water_up: float = point_velocity.dot(water_up)

	var buoyancy_force: Vector3 = water_up * buoyancy_strength * submersion_amount

	var damping_force: Vector3 = water_up * (-velocity_along_water_up * vertical_damping * submersion_amount)

	var velocity_sideways: Vector3 = point_velocity - water_up * velocity_along_water_up
	var drag_force: Vector3 = -velocity_sideways * water_drag * submersion_amount

	var final_force: Vector3 = buoyancy_force + damping_force + drag_force

	var force_offset_from_body_center: Vector3 = probe_world_position - body.global_position

	body.apply_force(final_force, force_offset_from_body_center)

	if print_debug:
		print(
			name,
			" | Depth: ", depth_under_water,
			" | Submersion: ", submersion_amount,
			" | Probe Y: ", probe_world_position.y,
			" | Water Height: ", water.get_water_height(probe_world_position),
			" | Force: ", final_force
		)


func _get_velocity_at_world_point(world_point: Vector3) -> Vector3:
	var offset_from_center: Vector3 = world_point - body.global_position

	return body.linear_velocity + body.angular_velocity.cross(offset_from_center)


func _find_parent_rigidbody() -> RigidBody3D:
	var current_node: Node = get_parent()

	while current_node != null:
		if current_node is RigidBody3D:
			return current_node

		current_node = current_node.get_parent()

	return null
