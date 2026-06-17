shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform sampler2D sprite_texture : source_color;
uniform float black_cutoff = 0.02;
uniform float softness = 0.2;
uniform float brightness_boost = 1.0;

void fragment() {
    vec4 tex = texture(sprite_texture, UV);

    float brightness = max(tex.r, max(tex.g, tex.b));
    float alpha = smoothstep(black_cutoff, black_cutoff + softness, brightness);

    ALBEDO = tex.rgb * brightness_boost;
    ALPHA = alpha * tex.a;
}