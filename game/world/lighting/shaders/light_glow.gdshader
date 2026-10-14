// Halo additif qui vacille lentement (LightGlow, jalon 12 : lampes de chantier). Intensité =
// alpha de la couleur du sprite × dégradé radial de la texture ; le vacillement baisse
// l'intensité d'au plus « amplitude » (0 = fixe : « Réduire les animations »). Phase tirée de
// la position du halo : deux lampes voisines ne battent pas ensemble.
shader_type canvas_item;
render_mode blend_add;

uniform float amplitude = 0.0;
uniform float speed = 1.1;

varying float phase;

void vertex() {
	vec2 origin = MODEL_MATRIX[3].xy;
	phase = fract(sin(dot(origin, vec2(12.9898, 78.233))) * 43758.5453) * 6.2831;
}

void fragment() {
	float t = TIME * speed + phase;
	// Deux sinus lents et incommensurables : un battement irrégulier, jamais un clignotement.
	float wave = 0.5 + 0.3 * sin(t) + 0.2 * sin(t * 2.37 + 1.3);
	COLOR = texture(TEXTURE, UV) * COLOR;
	COLOR.a *= 1.0 - amplitude * clamp(wave, 0.0, 1.0);
}
