shader_type spatial;

render_mode world_vertex_coords, cull_back, depth_draw_opaque;

const float TAU_VALUE = 6.28318530718;

uniform float water_time = 0.0;

// -------------------------
// Main water color
// -------------------------

uniform vec4 deep_water_color : source_color = vec4(0.015, 0.08, 0.14, 1.0);
uniform vec4 shallow_water_color : source_color = vec4(0.00, 0.34, 0.50, 1.0);
uniform vec4 foam_color : source_color = vec4(0.85, 0.95, 1.0, 1.0);

uniform float roughness_value : hint_range(0.0, 1.0) = 0.12;
uniform float specular_value : hint_range(0.0, 1.0) = 0.75;

// -------------------------
// World-space normal maps
// -------------------------

uniform sampler2D large_normal_map : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D small_normal_map : hint_normal, filter_linear_mipmap, repeat_enable;

uniform float large_normal_tile_size = 35.0;
uniform float small_normal_tile_size = 14.0;

uniform vec2 large_normal_scroll = vec2(0.004, 0.003);
uniform vec2 small_normal_scroll = vec2(-0.008, 0.006);

uniform float large_normal_strength : hint_range(0.0, 2.0) = 0.35;
uniform float small_normal_strength : hint_range(0.0, 2.0) = 0.12;

// -------------------------
// Foam
// -------------------------

uniform sampler2D foam_noise : filter_linear_mipmap, repeat_enable;

uniform float foam_tile_size = 20.0;
uniform float foam_strength : hint_range(0.0, 1.0) = 0.12;
uniform float foam_cutoff : hint_range(0.0, 1.0) = 0.78;

// -------------------------
// Large Swell
// -------------------------

uniform vec2 swell_direction = vec2(1.0, 0.2);
uniform float swell_amplitude = 0.24;
uniform float swell_wavelength = 18.0;
uniform float swell_speed = 1.45;
uniform float swell_steepness = 0.34;

// -------------------------
// Rolling Wave
// -------------------------

uniform vec2 rolling_direction = vec2(0.25, 1.0);
uniform float rolling_amplitude = 0.13;
uniform float rolling_wavelength = 8.0;
uniform float rolling_speed = 1.05;
uniform float rolling_steepness = 0.30;

// -------------------------
// Surface Chop
// -------------------------

uniform vec2 chop_direction = vec2(-0.8, 0.45);
uniform float chop_amplitude = 0.04;
uniform float chop_wavelength = 4.2;
uniform float chop_speed = 0.85;
uniform float chop_steepness = 0.22;

// -------------------------
// Cross Wave
// -------------------------

uniform vec2 cross_direction = vec2(0.65, -0.75);
uniform float cross_amplitude = 0.022;
uniform float cross_wavelength = 2.8;
uniform float cross_speed = 0.65;
uniform float cross_steepness = 0.16;

varying vec2 stable_world_xz_for_texture;
varying float wave_height_amount;
varying float crest_amount;
varying float top_facing_amount;


// -------------------------
// Helper functions
// -------------------------

vec2 safe_direction(vec2 direction) {
	float length_value = length(direction);

	if (length_value < 0.0001) {
		return vec2(1.0, 0.0);
	}

	return direction / length_value;
}


vec3 gerstner_wave_offset(
	vec2 direction,
	float amplitude,
	float wavelength,
	float speed,
	float steepness,
	vec2 world_xz,
	float time
) {
	vec2 dir = safe_direction(direction);

	float safe_wavelength = max(wavelength, 0.001);
	float wave_number = TAU_VALUE / safe_wavelength;

	float phase = wave_number * (dot(dir, world_xz) - speed * time);

	float sine_value = sin(phase);
	float cosine_value = cos(phase);

	vec3 offset = vec3(0.0);

	offset.x = dir.x * steepness * amplitude * cosine_value;
	offset.z = dir.y * steepness * amplitude * cosine_value;
	offset.y = amplitude * sine_value;

	return offset;
}


float gerstner_crest_value(
	vec2 direction,
	float wavelength,
	float speed,
	vec2 world_xz,
	float time
) {
	vec2 dir = safe_direction(direction);

	float safe_wavelength = max(wavelength, 0.001);
	float wave_number = TAU_VALUE / safe_wavelength;

	float phase = wave_number * (dot(dir, world_xz) - speed * time);

	return sin(phase) * 0.5 + 0.5;
}


vec3 get_total_wave_offset(vec2 world_xz, float time) {
	vec3 total = vec3(0.0);

	total += gerstner_wave_offset(
		swell_direction,
		swell_amplitude,
		swell_wavelength,
		swell_speed,
		swell_steepness,
		world_xz,
		time
	);

	total += gerstner_wave_offset(
		rolling_direction,
		rolling_amplitude,
		rolling_wavelength,
		rolling_speed,
		rolling_steepness,
		world_xz,
		time
	);

	total += gerstner_wave_offset(
		chop_direction,
		chop_amplitude,
		chop_wavelength,
		chop_speed,
		chop_steepness,
		world_xz,
		time
	);

	total += gerstner_wave_offset(
		cross_direction,
		cross_amplitude,
		cross_wavelength,
		cross_speed,
		cross_steepness,
		world_xz,
		time
	);

	return total;
}


float get_total_crest(vec2 world_xz, float time) {
	float crest = 0.0;

	crest = max(crest, gerstner_crest_value(swell_direction, swell_wavelength, swell_speed, world_xz, time));
	crest = max(crest, gerstner_crest_value(rolling_direction, rolling_wavelength, rolling_speed, world_xz, time));
	crest = max(crest, gerstner_crest_value(chop_direction, chop_wavelength, chop_speed, world_xz, time));
	crest = max(crest, gerstner_crest_value(cross_direction, cross_wavelength, cross_speed, world_xz, time));

	return crest;
}


// -------------------------
// Vertex shader
// -------------------------

void vertex() {
	vec2 base_world_xz = VERTEX.xz;

	stable_world_xz_for_texture = base_world_xz;

	vec3 wave_offset = get_total_wave_offset(base_world_xz, water_time);

	VERTEX += wave_offset;

	wave_height_amount = wave_offset.y;
	crest_amount = get_total_crest(base_world_xz, water_time);

	float normal_sample_distance = 0.45;

	vec2 xz_center = base_world_xz;
	vec2 xz_right = base_world_xz + vec2(normal_sample_distance, 0.0);
	vec2 xz_forward = base_world_xz + vec2(0.0, normal_sample_distance);

	vec3 center_position = vec3(xz_center.x, 0.0, xz_center.y) + get_total_wave_offset(xz_center, water_time);
	vec3 right_position = vec3(xz_right.x, 0.0, xz_right.y) + get_total_wave_offset(xz_right, water_time);
	vec3 forward_position = vec3(xz_forward.x, 0.0, xz_forward.y) + get_total_wave_offset(xz_forward, water_time);

	vec3 tangent_x = right_position - center_position;
	vec3 tangent_z = forward_position - center_position;

	NORMAL = normalize(cross(tangent_z, tangent_x));

	// 1.0 = flat/top-facing water.
	// 0.0 = steep side wall of a wave.
	// We use this to hide noisy detail on vertical wave walls.
	top_facing_amount = smoothstep(0.15, 0.85, NORMAL.y);
}


// -------------------------
// Fragment shader
// -------------------------

void fragment() {
	vec2 large_normal_uv = stable_world_xz_for_texture / max(large_normal_tile_size, 0.001);
	vec2 small_normal_uv = stable_world_xz_for_texture / max(small_normal_tile_size, 0.001);

	large_normal_uv += large_normal_scroll * water_time;
	small_normal_uv += small_normal_scroll * water_time;

	vec3 large_normal = texture(large_normal_map, large_normal_uv).rgb * 2.0 - 1.0;
	vec3 small_normal = texture(small_normal_map, small_normal_uv).rgb * 2.0 - 1.0;

	float normal_detail_fade = top_facing_amount;

	vec3 combined_normal = normalize(vec3(
		large_normal.xy * large_normal_strength * normal_detail_fade +
		small_normal.xy * small_normal_strength * normal_detail_fade,
		1.0
	));

	NORMAL_MAP = combined_normal * 0.5 + 0.5;

	float height_mix = clamp(wave_height_amount * 0.65 + 0.5, 0.0, 1.0);
	vec3 water_color = mix(deep_water_color.rgb, shallow_water_color.rgb, height_mix);

	vec2 foam_uv = stable_world_xz_for_texture / max(foam_tile_size, 0.001);
	foam_uv += vec2(0.012, -0.008) * water_time;

	float foam_noise_value = texture(foam_noise, foam_uv).r;

	float crest_foam = smoothstep(foam_cutoff, 1.0, crest_amount);
	float noise_foam = smoothstep(0.58, 1.0, foam_noise_value);

	float final_foam = crest_foam * noise_foam * foam_strength;

	// Hide foam on steep vertical wave walls.
	final_foam *= top_facing_amount;

	ALBEDO = mix(water_color, foam_color.rgb, final_foam);

	ROUGHNESS = roughness_value;
	SPECULAR = specular_value;
}