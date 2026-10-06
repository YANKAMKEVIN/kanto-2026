shader_type canvas_item;
// Décor du grand portrait du Pokédex (refonte T4) : l'image floutée en « couverture » du cadre
// (rapport gardé, recadrée au centre), coins arrondis, lumière douce et chaude, vignettage léger
// et fondu vers le fond du panneau en bas (la description reste lisible). Un seul tracé ; les
// valeurs viennent de UiTokens (DEX_SCENE_*), posées par PokedexPortrait.

uniform vec2 rect_size = vec2(512.0, 512.0);
uniform vec2 texture_size = vec2(512.0, 512.0);
uniform float radius = 28.0;
// Lumière : centre (part du cadre), couleur, force ; éclaircissement global.
uniform vec2 light_center = vec2(0.5, 0.38);
uniform vec4 light_color : source_color = vec4(1.0, 0.86, 0.62, 1.0);
uniform float light_strength = 0.35;
uniform float lift = 0.06;
uniform float saturation = 1.0;
uniform float vignette = 0.35;
// Fondu du bas : de fade_start à fade_end (part de la hauteur), vers fade_color.
uniform float fade_start = 0.55;
uniform float fade_end = 0.85;
uniform vec4 fade_color : source_color = vec4(0.07, 0.10, 0.15, 0.9);
uniform float opacity = 1.0;

float rounded_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + vec2(r);
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	// Couverture : le côté le plus court du cadre remplit l'image, l'autre est recadré.
	float frame_ratio = rect_size.x / max(rect_size.y, 1.0);
	float tex_ratio = texture_size.x / max(texture_size.y, 1.0);
	vec2 scale = frame_ratio > tex_ratio ? vec2(1.0, tex_ratio / frame_ratio)
		: vec2(frame_ratio / tex_ratio, 1.0);
	vec2 uv = (UV - 0.5) * scale + 0.5;
	vec3 color = texture(TEXTURE, uv).rgb;
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(grey), color, saturation) + lift;
	float glow = 1.0 - smoothstep(0.0, 0.75, distance(UV * vec2(frame_ratio, 1.0),
		light_center * vec2(frame_ratio, 1.0)));
	color = mix(color, color * light_color.rgb + light_color.rgb * 0.25, glow * light_strength);
	vec2 centered = UV - 0.5;
	color *= 1.0 - vignette * smoothstep(0.35, 0.75, length(centered * vec2(1.0, 1.1)));
	float fade = smoothstep(fade_start, fade_end, UV.y) * fade_color.a;
	color = mix(color, fade_color.rgb, fade);
	vec2 p = (UV - 0.5) * rect_size;
	float d = rounded_box(p, rect_size * 0.5, radius);
	float mask = 1.0 - smoothstep(-0.75, 0.75, d);
	COLOR = vec4(min(color, vec3(1.0)), mask * opacity * COLOR.a);
}
