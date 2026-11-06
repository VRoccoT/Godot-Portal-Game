shader_type spatial;
render_mode unshaded, diffuse_burley, specular_schlick_ggx;

uniform sampler2D reflection_texture : source_color, filter_linear_mipmap, repeat_disable;

void fragment() {
    // Projeção baseada estritamente nas coordenadas da tela em tempo real
    vec2 screen_uv = SCREEN_UV;
    
    // Inversão do eixo X para efeito natural de espelho
    screen_uv.x = 1.0 - screen_uv.x;
    
    // Mostra o reflexo e impede que seja afetado por escurecimento de distância
    ALBEDO = texture(reflection_texture, screen_uv).rgb;
}