// Ombre portée douce : silhouette floutée, plus dense au pied qu'à l'extrémité.
shader_type canvas_item;

uniform vec4 couleur : source_color = vec4(0.10, 0.09, 0.22, 0.34);
uniform float flou = 10.0; // rayon en pixels de texture

void fragment() {
	vec2 pas = TEXTURE_PIXEL_SIZE * flou;
	float a = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			a += texture(TEXTURE, UV + vec2(float(x), float(y)) * pas * 0.5).a;
		}
	}
	a /= 25.0;
	// Le pied est en bas de la texture (UV.y = 1) : l'ombre s'efface en s'en éloignant.
	float fondu = mix(0.25, 1.0, smoothstep(0.0, 1.0, UV.y));
	COLOR = vec4(couleur.rgb, couleur.a * a * fondu);
}
