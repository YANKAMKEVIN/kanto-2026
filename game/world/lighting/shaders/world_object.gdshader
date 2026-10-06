// Objets peints du monde (méthode C, lumière C2) : vent dans les feuillages et liseré de soleil.
// Repris de proto/da_jadielle/objet.gdshader (mêmes calculs, 4 lectures au plus par pixel).
// Le liseré éclaire en doré les bords de la silhouette tournés vers le soleil : c'est ce que la
// lumière peinte (référence A) avait et qu'un étalonnage d'écran ne crée pas.
// Les paramètres d'ambiance sont des « global uniform » posés par WorldLighting : changer
// d'ambiance ne touche aucun nœud. Profil vide = liseré 0 et vent 0 (aucun effet).
shader_type canvas_item;

// D'où vient la lumière (haut-gauche : (-0.7, -0.7)).
global uniform vec2 world_sun_dir;
global uniform vec4 world_rim_color;
// 0 = aucun liseré, 1 = plein.
global uniform float world_rim_strength;
// Largeur du liseré, en pixels de texture.
global uniform float world_rim_width;
// Amplitude du vent (pixels) ; 0 = immobile.
global uniform float world_wind;

// 1 pour les feuillages (arbres), 0 pour le reste : un matériau partagé par famille.
uniform float wind_factor = 0.0;

// Constantes de technique (jalon-07.md §15.2 n° 4), pas d'ambiance.
const float WIND_SPEED = 1.1;
const float RIM_GAIN = 1.45;
const float RIM_AMOUNT = 0.55;

varying vec4 modulate_color;

void vertex() {
	// Couleur du sommet = modulate (fondu des toits et des cimes qui cachent le joueur).
	modulate_color = COLOR;
	float height = 1.0 - UV.y;
	float phase = MODEL_MATRIX[3].x * 0.013;
	VERTEX.x += sin(TIME * WIND_SPEED + phase) * world_wind * wind_factor * height * height;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (world_rim_strength > 0.0 && world_rim_width > 0.0 && c.a > 0.5) {
		vec2 step_uv = normalize(world_sun_dir) * TEXTURE_PIXEL_SIZE;
		float empty = 0.0;
		for (int i = 1; i <= 4; i++) {
			empty += 1.0 - texture(TEXTURE, UV + step_uv * world_rim_width * float(i) / 4.0).a;
		}
		empty = clamp(empty / 2.0, 0.0, 1.0);
		float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
		// Plus fort sur les tons clairs, absent des contours sombres.
		float amount = empty * world_rim_strength * smoothstep(0.12, 0.4, l) * RIM_AMOUNT;
		c.rgb = mix(c.rgb, c.rgb * world_rim_color.rgb * RIM_GAIN, amount);
	}
	COLOR = c * modulate_color;
}
