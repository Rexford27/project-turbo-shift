shader_type spatial;

render_mode unshaded, blend_mix, depth_prepass_alpha, cull_disabled;
uniform sampler2D foam_texture;
uniform sampler2D noise_texture;

uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float scroll_speed = 0.7;
uniform vec2 scroll_direction = vec2(0.0, -1.0);

uniform vec2 foam_tiling = vec2(2.0, 3.0);
uniform vec2 noise_tiling = vec2(1.5, 2.5);

uniform float noise_strength = 0.15;
uniform float alpha_strength = 0.8;
uniform float foam_cutoff = 0.35;

uniform float side_fade = 0.45;
uniform float end_fade = 0.25;


void fragment() {
	// Base UVs from the plane
	vec2 uv = UV;

	// Scroll direction over time
	vec2 scroll = scroll_direction * TIME * scroll_speed;

	// Noise distortion
	vec2 noise_uv = uv * noise_tiling + scroll * 0.5;
	float noise_value = texture(noise_texture, noise_uv).r;

	vec2 distorted_uv = uv;
	distorted_uv += (noise_value - 0.5) * noise_strength;

	// Moving foam texture
	vec2 foam_uv = distorted_uv * foam_tiling + scroll;
	float foam_value = texture(foam_texture, foam_uv).r;

	// Make the foam sharper
	float foam_mask = smoothstep(foam_cutoff, 1.0, foam_value);

	// Fade left and right edges of the plane
	float distance_from_center = abs(uv.x - 0.5) * 2.0;
	float side_mask = 1.0 - smoothstep(1.0 - side_fade, 1.0, distance_from_center);

	// Fade front and back of the plane
	float front_mask = smoothstep(0.0, end_fade, uv.y);
	float back_mask = 1.0 - smoothstep(1.0 - end_fade, 1.0, uv.y);

	float shape_mask = side_mask * front_mask * back_mask;

	float final_alpha = foam_mask * shape_mask * alpha_strength;

	ALBEDO = foam_color.rgb;
	ALPHA = final_alpha;
}