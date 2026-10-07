shader_type canvas_item;
// Image d'une zone dans le menu (MM.2) : aperçu peint de la zone (ou recadrage de l'illustration
// de Kanto, `region` en UV de la texture) qui couvre le rectangle du nœud sans déformation (rogné
// autour de `focus`), coins arrondis, dégradé vers `fade_color` dans le bas (un nom se lit dessus)
// et voile `dim` (vignette grisée). Un seul tracé. Même méthode que menu_card_art.gdshader.

uniform vec2 rect_size = vec2(400.0, 300.0);
// Taille en pixels de la partie de texture utilisée (la région).
uniform vec2 texture_size = vec2(768.0, 432.0);
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 focus = vec2(0.5, 0.5);
uniform float radius = 20.0;
uniform vec4 fade_color : source_color = vec4(0.03, 0.06, 0.10, 0.9);
uniform float fade_from = 0.5;
uniform float dim = 0.0;

varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	float rect_aspect = rect_size.x / max(rect_size.y, 1.0);
	float tex_aspect = texture_size.x / max(texture_size.y, 1.0);
	vec2 scale = vec2(1.0);
	if (rect_aspect > tex_aspect) {
		scale.y = tex_aspect / rect_aspect;
	} else {
		scale.x = rect_aspect / tex_aspect;
	}
	vec2 offset = (vec2(1.0) - scale) * focus;
	vec4 color = texture(TEXTURE, region.xy + (offset + UV * scale) * region.zw);
	color.rgb = mix(color.rgb, fade_color.rgb, dim);
	float t = smoothstep(fade_from, 1.0, UV.y);
	color.rgb = mix(color.rgb, fade_color.rgb, t * fade_color.a);
	vec2 p = UV * rect_size;
	vec2 q = abs(p - rect_size * 0.5) - (rect_size * 0.5 - vec2(radius));
	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	color.a *= clamp(0.5 - d, 0.0, 1.0);
	COLOR = color * modulate;
}
