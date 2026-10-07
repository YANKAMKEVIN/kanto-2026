shader_type canvas_item;
// Fond du cadre de la Carte (MM.2) : l'illustration de Kanto étirée pour couvrir tout le cadre,
// lue sur une mipmap lointaine (très floue) et assombrie. Elle prolonge l'image entière (posée
// par-dessus, rapport gardé) jusqu'aux bords du cadre quand l'écran est plus large qu'elle.
// Un seul tracé ; la texture doit avoir des mipmaps (import).

uniform vec2 rect_size = vec2(400.0, 300.0);
uniform vec2 texture_size = vec2(1586.0, 992.0);
uniform float lod = 5.0;
uniform vec4 dim_color : source_color = vec4(0.03, 0.06, 0.10, 1.0);
uniform float dim = 0.5;

void fragment() {
	float rect_aspect = rect_size.x / max(rect_size.y, 1.0);
	float tex_aspect = texture_size.x / max(texture_size.y, 1.0);
	vec2 scale = vec2(1.0);
	if (rect_aspect > tex_aspect) {
		scale.y = tex_aspect / rect_aspect;
	} else {
		scale.x = rect_aspect / tex_aspect;
	}
	vec2 uv = (vec2(1.0) - scale) * 0.5 + UV * scale;
	vec3 color = textureLod(TEXTURE, uv, lod).rgb;
	COLOR = vec4(mix(color, dim_color.rgb, dim), 1.0);
}
