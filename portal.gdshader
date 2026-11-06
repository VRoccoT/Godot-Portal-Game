shader_type spatial;
render_mode unshaded, cull_back;

uniform sampler2D target_texture : source_color, filter_linear_mipmap;

void fragment() {
	vec2 screen_uv = SCREEN_UV;
	vec4 col = texture(target_texture, screen_uv);
	ALBEDO = col.rgb;
}