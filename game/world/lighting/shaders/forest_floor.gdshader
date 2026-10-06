// Sous-bois de la forêt serrée (ForestFloor) : sol sombre sous les cases de forêt (masque
// 1 pixel = 1 case, blanc = forêt), frontière irrégulière, pour que l'herbe claire ne se voie
// jamais entre les arbres. Repris de proto/da_jadielle/sous_bois.gdshader : mêmes bruits,
// mêmes seuils, mêmes couleurs (validés par Kevin sur S24, 2026-10-06). Dessiné par-dessus le
// sol peint ; hors forêt, transparent.
shader_type canvas_item;

uniform sampler2D forest_mask : filter_linear;
uniform float tile_size = 96.0;
uniform vec4 dark_color : source_color = vec4(0.10, 0.26, 0.16, 1.0);
uniform vec4 light_color : source_color = vec4(0.17, 0.36, 0.20, 1.0);

// Coordonnées du calque (pixels ; le calque est posé à l'origine de la carte).
varying vec2 local;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec2 cells = vec2(textureSize(forest_mask, 0));
	float m = texture(forest_mask, local / tile_size / cells).r;
	float n = (noise(local * 0.025) - 0.5) * 0.35 + (noise(local * 0.1) - 0.5) * 0.15;
	float part = smoothstep(0.42, 0.58, m + n);
	vec3 c = mix(dark_color.rgb, light_color.rgb,
		noise(local * 0.04) * 0.7 + noise(local * 0.2) * 0.3);
	COLOR = vec4(c, part);
}
