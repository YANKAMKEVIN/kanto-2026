// Sol de la place : herbe et pavés validés, mélangés par un masque de cases
// (1 pixel = 1 case, 1 = pavé) dont la frontière est rendue irrégulière par du bruit,
// avec une fine bande de terre. Cahier de l'art du monde §5, fiche du sol (série 01).
shader_type canvas_item;

uniform sampler2D herbe : repeat_enable, filter_linear_mipmap;
uniform sampler2D paves : repeat_enable, filter_linear_mipmap;
uniform sampler2D masque : filter_linear;
uniform float taille_case = 96.0;
uniform float taille_texture = 384.0;
uniform float echelle_paves = 0.7;
uniform vec4 terre : source_color = vec4(0.54, 0.42, 0.29, 1.0);
uniform vec4 teinte : source_color = vec4(1.0, 1.0, 1.0, 1.0);

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
	float n = (bruit(monde * 0.02) - 0.5) * 0.30 + (bruit(monde * 0.09) - 0.5) * 0.14;
	float v = m + n;
	float part_paves = smoothstep(0.49, 0.53, v);
	float bande = smoothstep(0.40, 0.48, v) * (1.0 - smoothstep(0.51, 0.57, v));
	vec3 c_herbe = texture(herbe, monde / taille_texture).rgb;
	vec3 c_paves = texture(paves, monde / (taille_texture * echelle_paves)).rgb;
	vec3 c = mix(c_herbe, c_paves, part_paves);
	vec3 c_terre = terre.rgb * (0.85 + 0.3 * bruit(monde * 0.25));
	c = mix(c, c_terre, bande * 0.75);
	COLOR = vec4(c * teinte.rgb, 1.0);
}
