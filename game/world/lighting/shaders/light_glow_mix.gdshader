// Variante « mélange » de light_glow.gdshader (type avec "blend": "mix", lueur d'aide du jalon 14).
// Un halo additif se perd sur un décor clair (bois, pierre) : ici la couleur se mêle au décor
// et le teinte sans l'effacer (alpha <= ALPHA_MAX). Même vacillement lent (amplitude 0 = fixe).
shader_type canvas_item;
render_mode blend_mix;

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
