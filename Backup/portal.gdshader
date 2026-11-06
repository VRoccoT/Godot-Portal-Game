shader_type spatial;
render_mode unshaded;

uniform sampler2D target_texture : source_color, filter_linear_mipmap, repeat_disable;

void fragment() {
    // Projeta a textura capturada na área de tela ocupada pelo portal
    vec2 screen_uv = SCREEN_UV;
    ALBEDO = texture(target_texture, screen_uv).rgb;
}