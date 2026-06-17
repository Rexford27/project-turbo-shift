extends MeshInstance3D
class_name Trail3D

# -------------------------
# Main control
# -------------------------

# Turn this on/off from any script.
@export var emitting: bool = true

# Optional local offset from this node.
# Example: (0, 0, -1) emits slightly behind the node.
@export var emission_offset: Vector3 = Vector3.ZERO


# -------------------------
# Trail shape
# -------------------------

@export var start_width: float = 0.35
@export var end_width: float = 0.05

# Bigger = chunkier and cheaper.
# Smaller = smoother but more points.
@export var motion_delta: float = 0.25

@export var lifespan: float = 0.7
@export var max_points_per_segment: int = 40
@export var max_segments: int = 8


# -------------------------
# Color
# -------------------------

@export var start_color: Color = Color(1.0, 1.0, 1.0, 0.8)
@export var end_color: Color = Color(1.0, 1.0, 1.0, 0.0)


# -------------------------
# Texture / shader
# -------------------------

@export var shader_material: ShaderMaterial
@export var trail_texture: Texture2D

# Lower = repeats more often.
# Higher = stretches more.
@export var texture_repeat_distance: float = 0.8

# These are passed to your shader if it has these uniforms.
@export_range(-1.0, 1.0) var uv_rotation: float = 0.0
@export var uv_spin_speed: float = 0.0
@export var uv_scroll_speed: float = 0.0


# -------------------------
# Camera
# -------------------------

# Optional. If empty, it uses the current viewport camera.
@export var camera: Camera3D


# -------------------------
# Internal data
# -------------------------

var trail_mesh: ImmediateMesh
var active_shader_material: ShaderMaterial

var segments: Array = []

var current_segment_index: int = -1
var last_point: Vector3
var has_last_point: bool = false
var was_emitting: bool = false


func _ready() -> void:
	trail_mesh = ImmediateMesh.new()
	mesh = trail_mesh

	setup_material()


func _process(delta: float) -> void:
	update_shader_values()
	age_segments(delta)

	if emitting:
		var emit_position := get_emit_position()

		if not was_emitting:
			start_new_segment()
			has_last_point = false
			was_emitting = true

		add_point_if_needed(emit_position)

	else:
		# Lift the pen.
		# This prevents the next trail from connecting to the old one.
		was_emitting = false
		has_last_point = false
		current_segment_index = -1

	draw_trail()


func get_emit_position() -> Vector3:
	return global_transform.origin + (global_transform.basis * emission_offset)


func setup_material() -> void:
	if shader_material != null:
		active_shader_material = shader_material.duplicate()
		material_override = active_shader_material
		update_shader_values()
		return

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
	if active_shader_material == null:
		return

	if trail_texture != null:
		active_shader_material.set_shader_parameter("trail_texture", trail_texture)

	active_shader_material.set_shader_parameter("uv_rotation", uv_rotation)
	active_shader_material.set_shader_parameter("uv_spin_speed", uv_spin_speed)
	active_shader_material.set_shader_parameter("uv_scroll_speed", uv_scroll_speed)


func start_new_segment() -> void:
	segments.append({
		"points": [],
		"ages": []
	})

	current_segment_index = segments.size() - 1

	if segments.size() > max_segments:
		segments.remove_at(0)
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

			var color := start_color.lerp(end_color, age_percent)
			trail_mesh.surface_set_color(color)

			var width = lerp(start_width, end_width, age_percent)
			var right = width_direction * width

			var point_a: Vector3 = points[i] + right
			var point_b: Vector3 = points[i] - right

			var repeat_distance = max(texture_repeat_distance, 0.01)
			var uv_x = distance_along_trail / repeat_distance

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
	was_emitting = false

	if trail_mesh != null:
		trail_mesh.clear_surfaces()
