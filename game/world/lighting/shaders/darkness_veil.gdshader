// Voile d'obscurité des grottes obscures (DarknessVeil ; docs/tech/jalon-18.md §2.3, J17 T9) :
// noir bleuté d'opacité « outside » percé d'un trou radial doux centré sur le corps du joueur
// et de trous plus petits aux halos fixes (LightGlow). Calcul en coordonnées du monde
// (MODEL_MATRIX) : indépendant de la caméra et de l'étirement de l'écran. Aucune texture, aucune
// lecture de l'écran. Miroir en GDScript : VeilMath.alpha_at (tests).
shader_type canvas_item;
render_mode unshaded, blend_mix;

const int MAX_SOURCES = 16;

uniform vec3 veil_color : source_color = vec3(0.016, 0.024, 0.047);
// Monde (px) : centre du corps du joueur.
uniform vec2 center = vec2(0.0);
// px : trou net, fin du fondu.
uniform float clear_radius = 240.0;
uniform float fade_radius = 384.0;
// Opacité hors du halo (< 1 : jamais de noir total).
uniform float outside = 0.6;
// Battement du halo : amplitude relative (0 : « Réduire les animations »), période (s).
uniform float breath = 0.0;
uniform float breath_period = 3.5;
// Tramage contre les bandes du dégradé sombre (0 : aucun).
uniform float dither = 0.0;
// x, y (monde, px), rayon (px), force (0..1).
uniform vec4 sources[MAX_SOURCES];
uniform int source_count = 0;

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float k = 1.0 + breath * sin(TIME * 6.2831853 / breath_period);
	float lit = 1.0 - smoothstep(clear_radius * k, fade_radius * k, distance(world, center));
	for (int i = 0; i < MAX_SOURCES; i++) {
		if (i >= source_count) {
			break;
		}
		vec4 s = sources[i];
		lit = max(lit, s.w * (1.0 - smoothstep(s.z * 0.4, s.z, distance(world, s.xy))));
	}
	float noise = fract(sin(dot(FRAGCOORD.xy, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
	COLOR = vec4(veil_color, clamp(outside * (1.0 - lit) + noise * dither, 0.0, 1.0));
}
