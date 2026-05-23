shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

uniform sampler2D trail_texture : source_color, repeat_enable;

uniform float uv_rotation : hint_range(-1.0, 1.0) = 0.0;
uniform float uv_spin_speed = 0.0;
uniform float uv_scroll_speed = 0.0;

void fragment() {
	vec2 uv = UV;

	uv.x += TIME * uv_scroll_speed;

	float angle = (uv_rotation + TIME * uv_spin_speed) * 3.14159265;

	vec2 center = vec2(0.0, 0.5);
	vec2 offset = uv - center;

	float c = cos(angle);
	float s = sin(angle);

	vec2 rotated_uv = vec2(
		offset.x * c - offset.y * s,
		offset.x * s + offset.y * c
	) + center;

	vec4 tex_color = texture(trail_texture, rotated_uv);

	ALBEDO = tex_color.rgb * COLOR.rgb;
	ALPHA = tex_color.a * COLOR.a;
}