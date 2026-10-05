// Sol de Bourg Palette : herbe en fond, puis pavés, terre battue, sable et océan, chacun
// donné par un canal du masque (1 pixel = 1 case ; r pavés, g terre, b sable, a eau).
// Frontières rendues irrégulières par du bruit, comme sol.gdshader ; l'eau ondule
// doucement. Série 06.
shader_type canvas_item;

uniform sampler2D herbe : repeat_enable, filter_linear_mipmap;
uniform sampler2D paves : repeat_enable, filter_linear_mipmap;
uniform sampler2D chemin : repeat_enable, filter_linear_mipmap;
uniform sampler2D sable : repeat_enable, filter_linear_mipmap;
uniform sampler2D eau : repeat_enable, filter_linear_mipmap;
uniform sampler2D masque : filter_linear;
uniform float taille_case = 96.0;
uniform float taille_texture = 384.0;
uniform vec4 terre : source_color = vec4(0.54, 0.42, 0.29, 1.0);

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
	vec4 m = texture(masque, monde / taille_case / cases);
	float n = (bruit(monde * 0.02) - 0.5) * 0.30 + (bruit(monde * 0.09) - 0.5) * 0.14;
	vec3 c = texture(herbe, monde / taille_texture).rgb;
	// Terre battue (Route 1, sentier côtier), avec une fine bande plus sombre au bord.
	float v = m.g + n;
	float part = smoothstep(0.49, 0.53, v);
	float bande = smoothstep(0.40, 0.48, v) * (1.0 - smoothstep(0.51, 0.57, v));
	c = mix(c, texture(chemin, monde / taille_texture).rgb, part);
	c = mix(c, terre.rgb * (0.85 + 0.3 * bruit(monde * 0.25)), bande * 0.6);
	// Pavés (allées, place, parvis du labo).
	v = m.r + n;
	part = smoothstep(0.49, 0.53, v);
	bande = smoothstep(0.40, 0.48, v) * (1.0 - smoothstep(0.51, 0.57, v));
	c = mix(c, terre.rgb * (0.85 + 0.3 * bruit(monde * 0.25)), bande * 0.75);
	c = mix(c, texture(paves, monde / (taille_texture * 0.7)).rgb, part);
	// Sable, puis l'eau par-dessus avec une frange d'écume claire au rivage.
	v = m.b + n * 0.6;
	c = mix(c, texture(sable, monde / taille_texture).rgb, smoothstep(0.45, 0.55, v));
	v = m.a + n * 0.5 + (bruit(monde * 0.03 + vec2(TIME * 0.15, 0.0)) - 0.5) * 0.08;
	vec2 houle = vec2(sin(TIME * 0.4 + monde.y * 0.01), cos(TIME * 0.3 + monde.x * 0.008)) * 6.0;
	vec3 c_eau = texture(eau, (monde + houle) / (taille_texture * 1.5)).rgb;
	float ecume = smoothstep(0.42, 0.5, v) * (1.0 - smoothstep(0.5, 0.62, v));
	c = mix(c, c_eau, smoothstep(0.5, 0.56, v));
	c = mix(c, vec3(0.95, 0.97, 0.98), ecume * 0.8);
	COLOR = vec4(c, 1.0);
}
