// Objets du monde (méthode C) : vent optionnel et lisere de soleil. Le lisere éclaire en doré
// les bords de la silhouette tournés vers le soleil (haut-gauche) : c'est ce que la lumière
// peinte (référence A) avait et qu'un étalonnage d'écran ne crée pas.
shader_type canvas_item;

uniform float force_vent = 0.0;
uniform float vitesse_vent = 1.1;
uniform float force_lisere = 0.0; // 0 = aucun, 1 = plein
uniform vec4 couleur_lisere : source_color = vec4(1.0, 0.82, 0.48, 1.0);
uniform float largeur_lisere = 5.0; // pixels de texture
uniform vec2 soleil = vec2(-0.7, -0.7); // direction d'où vient la lumière

void vertex() {
	float hauteur = 1.0 - UV.y;
	float phase = MODEL_MATRIX[3].x * 0.013;
	VERTEX.x += sin(TIME * vitesse_vent + phase) * force_vent * hauteur * hauteur;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (force_lisere > 0.0 && c.a > 0.5) {
		vec2 pas = normalize(soleil) * TEXTURE_PIXEL_SIZE;
		float vide = 0.0;
		for (int i = 1; i <= 4; i++) {
			vide += 1.0 - texture(TEXTURE, UV + pas * largeur_lisere * float(i) / 4.0).a;
		}
		vide = clamp(vide / 2.0, 0.0, 1.0);
		float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		// Plus fort sur les tons clairs, absent des contours sombres.
		float force = vide * force_lisere * smoothstep(0.12, 0.4, l) * 0.55;
		c.rgb = mix(c.rgb, c.rgb * couleur_lisere.rgb * 1.45, force);
	}
	COLOR = c;
}
