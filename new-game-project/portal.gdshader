shader_type spatial;
render_mode unshaded, cull_back;

uniform sampler2D portal_texture : source_color, filter_linear;
uniform bool portal_ativo = false;
uniform vec3 cor_fechado : source_color = vec3(0.35, 0.35, 0.35); // Cinza médio

void fragment() {
	if (portal_ativo) {
		ALBEDO = texture(portal_texture, SCREEN_UV).rgb;
	} else {
		ALBEDO = cor_fechado;
	}
}