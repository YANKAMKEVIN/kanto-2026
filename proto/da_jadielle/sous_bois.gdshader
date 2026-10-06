// Sous-bois de la Route 1 : sol sombre sous les cases de forêt (masque 1 pixel = 1 case),
// frontière irrégulière, pour que l'herbe claire ne se voie jamais entre les arbres.
shader_type canvas_item;

uniform sampler2D masque : filter_linear;
uniform float taille_case = 96.0;
uniform vec4 fonce : source_color = vec4(0.10, 0.26, 0.16, 1.0);
uniform vec4 clair : source_color = vec4(0.17, 0.36, 0.20, 1.0);

varying vec2 monde;

float hachage(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hachage(i), hachage(i + vec2(1.0, 0.0)), u.x),
		mix(hachage(i + vec2(0.0, 1.0)), hachage(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	monde = VERTEX;
}

void fragment() {
	vec2 cases = vec2(textureSize(masque, 0));
	float m = texture(masque, monde / taille_case / cases).r;
	float n = (bruit(monde * 0.025) - 0.5) * 0.35 + (bruit(monde * 0.1) - 0.5) * 0.15;
	float part = smoothstep(0.42, 0.58, m + n);
	vec3 c = mix(fonce.rgb, clair.rgb, bruit(monde * 0.04) * 0.7 + bruit(monde * 0.2) * 0.3);
	COLOR = vec4(c, part);
}
