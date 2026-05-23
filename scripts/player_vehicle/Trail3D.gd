extends MeshInstance3D
class_name Trail3D

# -------------------------
# Target
# -------------------------

@export var target: Node3D
@export var use_parent_as_target: bool = true
@export var position_offset: Vector3 = Vector3.ZERO


# -------------------------
# Trail controls
# -------------------------

@export var trail_enabled: bool = true
@export var use_input_to_show_trail: bool = true
@export var drift_input_action: StringName = "drift"

@export var start_width: float = 0.35
@export var end_width: float = 0.05

@export var motion_delta: float = 0.25
@export var lifespan: float = 0.7
@export var max_points_per_segment: int = 40


# -------------------------
# Color
# -------------------------

@export var start_color: Color = Color(1.0, 1.0, 1.0, 0.8)
@export var end_color: Color = Color(1.0, 1.0, 1.0, 0.0)


# -------------------------
# Texture / shader controls
# -------------------------

@export var shader_material: ShaderMaterial
@export var trail_texture: Texture2D

# Lower = texture repeats more often.
# Higher = texture stretches more.
@export var texture_repeat_distance: float = 0.8

# These get passed to your shader.
@export_range(-1.0, 1.0) var uv_rotation: float = 0.0
@export var uv_spin_speed: float = 0.0
@export var uv_scroll_speed: float = 0.0


# -------------------------
# Camera
# -------------------------

@export var camera: Camera3D


# -------------------------
# Internal data
# -------------------------

var trail_mesh: ImmediateMesh

var segments: Array = []

var current_segment_index: int = -1
var last_point: Vector3
var has_last_point: bool = false
var was_trailing: bool = false


func _ready() -> void:
	trail_mesh = ImmediateMesh.new()
	mesh = trail_mesh

	if target == null and use_parent_as_target and get_parent() is Node3D:
		target = get_parent()

	set_as_top_level(true)
	setup_material()


func _process(delta: float) -> void:
	if target == null:
		return

	update_shader_values()
	age_segments(delta)

	var should_make_trail := trail_enabled

	if use_input_to_show_trail:
		should_make_trail = trail_enabled and Input.is_action_pressed(drift_input_action)

	if should_make_trail:
		var target_position := target.global_position + position_offset
		global_position = target_position

		if not was_trailing:
			start_new_segment()
			has_last_point = false
			was_trailing = true

		add_point_if_needed(target_position)

	else:
		# Lift the pen so the next trail does not connect to the old one.
		was_trailing = false
		has_last_point = false
		current_segment_index = -1

	draw_trail()


func setup_material() -> void:
	if shader_material != null:
		material_override = shader_material
		update_shader_values()
		return

	# Fallback material, just in case no shader material is assigned.
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color.WHITE
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	if trail_texture != null:
		mat.albedo_texture = trail_texture

	material_override = mat


func update_shader_values() -> void:
	if shader_material == null:
		return

	if trail_texture != null:
		shader_material.set_shader_parameter("trail_texture", trail_texture)

	shader_material.set_shader_parameter("uv_rotation", uv_rotation)
	shader_material.set_shader_parameter("uv_spin_speed", uv_spin_speed)
	shader_material.set_shader_parameter("uv_scroll_speed", uv_scroll_speed)


func start_new_segment() -> void:
	segments.append({
		"points": [],
		"ages": []
	})

	current_segment_index = segments.size() - 1


func add_point_if_needed(point: Vector3) -> void:
	if current_segment_index < 0 or current_segment_index >= segments.size():
		start_new_segment()

	if not has_last_point:
		add_point(point)
		last_point = point
		has_last_point = true
		return

	if last_point.distance_to(point) >= motion_delta:
		add_point(point)
		last_point = point


func add_point(point: Vector3) -> void:
	if current_segment_index < 0 or current_segment_index >= segments.size():
		start_new_segment()

	var segment = segments[current_segment_index]

	segment["points"].append(point)
	segment["ages"].append(0.0)

	if segment["points"].size() > max_points_per_segment:
		segment["points"].remove_at(0)
		segment["ages"].remove_at(0)


func age_segments(delta: float) -> void:
	for s in range(segments.size() - 1, -1, -1):
		var segment = segments[s]
		var points: Array = segment["points"]
		var ages: Array = segment["ages"]

		for i in range(ages.size() - 1, -1, -1):
			ages[i] += delta

			if ages[i] > lifespan:
				ages.remove_at(i)
				points.remove_at(i)

		if points.size() == 0:
			segments.remove_at(s)

			if s < current_segment_index:
				current_segment_index -= 1

			elif s == current_segment_index:
				current_segment_index = -1
				has_last_point = false

	if current_segment_index >= segments.size():
		current_segment_index = -1
		has_last_point = false


func draw_trail() -> void:
	trail_mesh.clear_surfaces()

	if segments.size() == 0:
		return

	var width_direction := get_camera_right_direction()

	for segment in segments:
		var points: Array = segment["points"]
		var ages: Array = segment["ages"]

		if points.size() < 2:
			continue

		trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

		var distance_along_trail: float = 0.0

		for i in range(points.size()):
			if i > 0:
				distance_along_trail += points[i - 1].distance_to(points[i])

			var age_percent: float = ages[i] / lifespan

			var current_color := start_color.lerp(end_color, age_percent)
			trail_mesh.surface_set_color(current_color)

			var current_width = lerp(start_width, end_width, age_percent)
			var right = width_direction * current_width

			var point_a: Vector3 = points[i] + right
			var point_b: Vector3 = points[i] - right

			var safe_repeat_distance = max(texture_repeat_distance, 0.01)
			var uv_x = distance_along_trail / safe_repeat_distance

			# Keep UVs simple.
			# The shader handles rotation/spin/scroll.
			trail_mesh.surface_set_uv(Vector2(uv_x, 0.0))
			trail_mesh.surface_add_vertex(to_local(point_a))

			trail_mesh.surface_set_uv(Vector2(uv_x, 1.0))
			trail_mesh.surface_add_vertex(to_local(point_b))

		trail_mesh.surface_end()


func get_camera_right_direction() -> Vector3:
	var cam := camera

	if cam == null:
		cam = get_viewport().get_camera_3d()

	if cam == null:
		return Vector3.RIGHT

	return cam.global_transform.basis.x.normalized()


func clear_trail() -> void:
	segments.clear()
	current_segment_index = -1
	has_last_point = false
	was_trailing = false

	if trail_mesh != null:
		trail_mesh.clear_surfaces()
