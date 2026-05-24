@tool
extends Node3D
class_name StaticWorldOcean

@export var ocean_mesh: MeshInstance3D

@export_group("Editor Preview")
@export var animate_in_editor: bool = true
@export var reset_time: bool = false

# This fixes editor-camera jank.
# When the editor viewport lags, delta can jump.
# This prevents the shader time from jumping too far in one frame.
@export var clamp_time_step: bool = true
@export var max_editor_time_step: float = 0.0167
@export var max_game_time_step: float = 0.0333

@export_group("Water Level")
@export var water_level: float = 0.0
@export var keep_node_on_water_level: bool = true

@export_group("Time")
@export var time_scale: float = 1.0

@export_group("Large Swell - big slow ocean shape")
@export var swell_direction: Vector2 = Vector2(1.0, 0.2)
@export var swell_amplitude: float = 0.24
@export var swell_wavelength: float = 18.0
@export var swell_speed: float = 1.45
@export var swell_steepness: float = 0.34

@export_group("Rolling Wave - medium visible waves")
@export var rolling_direction: Vector2 = Vector2(0.25, 1.0)
@export var rolling_amplitude: float = 0.13
@export var rolling_wavelength: float = 8.0
@export var rolling_speed: float = 1.05
@export var rolling_steepness: float = 0.30

@export_group("Surface Chop - smaller rough water")
@export var chop_direction: Vector2 = Vector2(-0.8, 0.45)
@export var chop_amplitude: float = 0.04
@export var chop_wavelength: float = 4.2
@export var chop_speed: float = 0.85
@export var chop_steepness: float = 0.22

@export_group("Cross Wave - breaks up repetition")
@export var cross_direction: Vector2 = Vector2(0.65, -0.75)
@export var cross_amplitude: float = 0.022
@export var cross_wavelength: float = 2.8
@export var cross_speed: float = 0.65
@export var cross_steepness: float = 0.16

var water_time: float = 0.0
var water_material: ShaderMaterial


func _ready() -> void:
	set_process(true)
	_find_water_material()
	_send_all_values_to_shader()


func _process(delta: float) -> void:
	_find_water_material()

	if reset_time:
		water_time = 0.0
		reset_time = false

	if keep_node_on_water_level:
		global_position.y = water_level

	var in_editor := Engine.is_editor_hint()

	var safe_delta := delta

	if clamp_time_step:
		if in_editor:
			safe_delta = min(delta, max_editor_time_step)
		else:
			safe_delta = min(delta, max_game_time_step)

	if in_editor:
		if animate_in_editor:
			water_time += safe_delta * time_scale
	else:
		water_time += safe_delta * time_scale

	_send_all_values_to_shader()


func _find_water_material() -> void:
	if ocean_mesh == null:
		water_material = null
		return

	var material := ocean_mesh.get_active_material(0)

	if material is ShaderMaterial:
		water_material = material
	else:
		water_material = null


func _send_all_values_to_shader() -> void:
	if water_material == null:
		return

	water_material.set_shader_parameter("water_time", water_time)

	_send_wave_group_to_shader(
		"swell",
		swell_direction,
		swell_amplitude,
		swell_wavelength,
		swell_speed,
		swell_steepness
	)

	_send_wave_group_to_shader(
		"rolling",
		rolling_direction,
		rolling_amplitude,
		rolling_wavelength,
		rolling_speed,
		rolling_steepness
	)

	_send_wave_group_to_shader(
		"chop",
		chop_direction,
		chop_amplitude,
		chop_wavelength,
		chop_speed,
		chop_steepness
	)

	_send_wave_group_to_shader(
		"cross",
		cross_direction,
		cross_amplitude,
		cross_wavelength,
		cross_speed,
		cross_steepness
	)


func _send_wave_group_to_shader(
	group_name: String,
	direction: Vector2,
	amplitude: float,
	wavelength: float,
	speed: float,
	steepness: float
) -> void:
	var safe_direction := _safe_direction(direction)

	water_material.set_shader_parameter(group_name + "_direction", safe_direction)
	water_material.set_shader_parameter(group_name + "_amplitude", amplitude)
	water_material.set_shader_parameter(group_name + "_wavelength", wavelength)
	water_material.set_shader_parameter(group_name + "_speed", speed)
	water_material.set_shader_parameter(group_name + "_steepness", steepness)


func _safe_direction(direction: Vector2) -> Vector2:
	if direction.length() < 0.0001:
		return Vector2.RIGHT

	return direction.normalized()


func get_water_height(world_position: Vector3, iterations: int = 3) -> float:
	var asked_xz := Vector2(world_position.x, world_position.z)
	var sample_xz := asked_xz

	for i in range(iterations):
		var offset := _get_total_wave_offset(sample_xz, water_time)
		sample_xz = asked_xz - Vector2(offset.x, offset.z)

	var final_offset := _get_total_wave_offset(sample_xz, water_time)

	return water_level + final_offset.y


func get_water_normal(world_position: Vector3) -> Vector3:
	var sample_distance := 0.45

	var center_height := get_water_height(world_position)
	var right_height := get_water_height(world_position + Vector3(sample_distance, 0.0, 0.0))
	var forward_height := get_water_height(world_position + Vector3(0.0, 0.0, sample_distance))

	var center := Vector3(world_position.x, center_height, world_position.z)
	var right := Vector3(world_position.x + sample_distance, right_height, world_position.z)
	var forward := Vector3(world_position.x, forward_height, world_position.z + sample_distance)

	var tangent_x := right - center
	var tangent_z := forward - center

	return tangent_z.cross(tangent_x).normalized()


func _get_total_wave_offset(world_xz: Vector2, time: float) -> Vector3:
	var total := Vector3.ZERO

	total += _get_gerstner_offset(
		swell_direction,
		swell_amplitude,
		swell_wavelength,
		swell_speed,
		swell_steepness,
		world_xz,
		time
	)

	total += _get_gerstner_offset(
		rolling_direction,
		rolling_amplitude,
		rolling_wavelength,
		rolling_speed,
		rolling_steepness,
		world_xz,
		time
	)

	total += _get_gerstner_offset(
		chop_direction,
		chop_amplitude,
		chop_wavelength,
		chop_speed,
		chop_steepness,
		world_xz,
		time
	)

	total += _get_gerstner_offset(
		cross_direction,
		cross_amplitude,
		cross_wavelength,
		cross_speed,
		cross_steepness,
		world_xz,
		time
	)

	return total


func _get_gerstner_offset(
	direction: Vector2,
	amplitude: float,
	wavelength: float,
	speed: float,
	steepness: float,
	world_xz: Vector2,
	time: float
) -> Vector3:
	var dir := _safe_direction(direction)

	var safe_wavelength = max(wavelength, 0.001)
	var wave_number = TAU / safe_wavelength

	var phase = wave_number * (dir.dot(world_xz) - speed * time)

	var sine_value := sin(phase)
	var cosine_value := cos(phase)

	var offset := Vector3.ZERO

	offset.x = dir.x * steepness * amplitude * cosine_value
	offset.z = dir.y * steepness * amplitude * cosine_value
	offset.y = amplitude * sine_value

	return offset
	
func get_submersion_depth(world_position: Vector3, iterations: int = 3) -> float:
	# Water height at this X/Z position.
	var water_surface_y := get_water_height(world_position, iterations)

	# If the point is above water, depth is 0.
	if world_position.y >= water_surface_y:
		return 0.0

	# If the point is below water, return how far below.
	return water_surface_y - world_position.y


func get_water_up_direction() -> Vector3:
	# Simple ocean/lake mode.
	# Buoyancy pushes upward in world space.
	return Vector3.UP
