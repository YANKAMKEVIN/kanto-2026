// Artwork officiel de l'adversaire dans la lumière du lieu (CB.1 ; repris du prototype
// proto/battle_faceoff/artwork_grade.gdshader de la branche art/pokemon-pilote) : le trait noir
// est rapproché d'une teinte sombre colorée (comme le contour du monde, jamais noir), les aplats
// très légèrement réchauffés et adoucis, puis le liseré de soleil du lieu (mêmes « global
// uniform » que les objets du monde, posés par WorldLighting : profil vide ou Économie = aucun
// liseré). L'étalonnage d'écran du lieu (calque WorldLighting, au-dessus du combat) s'applique
// ensuite comme au décor. `strength` = 0 : artwork intact.
// Respecte le modulate (couleur du sommet).
// Voile du poison (jalon 9) : `tint` / `amount`, mêmes paramètres et même fondu que
// status_veil.gdshader (BattleStage.play_poison pose une copie de ce matériau pendant le voile,
// pour garder l'étalonnage de l'artwork).
shader_type canvas_item;

global uniform vec2 world_sun_dir;
global uniform vec4 world_rim_color;
global uniform float world_rim_strength;
global uniform float world_rim_width;

uniform float strength : hint_range(0.0, 1.0) = 1.0;
// Teinte des traits sombres (brun-violet profond du monde).
uniform vec3 line_tint = vec3(0.20, 0.13, 0.17);
// Seuil de luminance sous lequel un pixel compte comme trait.
uniform float line_threshold : hint_range(0.0, 0.5) = 0.22;
uniform float line_mix : hint_range(0.0, 1.0) = 0.65;
// Réchauffement et désaturation légère des aplats.
uniform vec3 warm = vec3(1.03, 1.0, 0.95);
uniform float soften : hint_range(0.0, 0.3) = 0.06;
// Texels de l'artwork par pixel d'écran (1 / échelle d'affichage) : le liseré garde la
// largeur du monde à l'écran.
uniform float texels_per_pixel = 1.0;

uniform vec4 tint : source_color = vec4(0.7, 0.3, 0.8, 1.0);
uniform float amount : hint_range(0.0, 1.0) = 0.0;

const float RIM_GAIN = 1.45;
const float RIM_AMOUNT = 0.55;

varying vec4 modulate_color;

void vertex() {
	// Couleur du sommet = modulate (fondus et teintes des animations du combat).
	modulate_color = COLOR;
}

void fragment() {
	vec4 t = texture(TEXTURE, UV);
	float luma = dot(t.rgb, vec3(0.299, 0.587, 0.114));
	float line = 1.0 - smoothstep(0.0, line_threshold, luma);
	vec3 graded = mix(t.rgb, line_tint + t.rgb * 0.5, line * line_mix);
	graded = mix(graded, vec3(luma), soften) * warm;
	vec3 c = mix(t.rgb, graded, strength);
	if (world_rim_strength > 0.0 && world_rim_width > 0.0 && t.a > 0.5) {
		vec2 step_uv = normalize(world_sun_dir) * TEXTURE_PIXEL_SIZE
			* world_rim_width * texels_per_pixel;
		float empty = 0.0;
		for (int i = 1; i <= 4; i++) {
			empty += 1.0 - texture(TEXTURE, UV + step_uv * float(i) / 4.0).a;
		}
		empty = clamp(empty / 2.0, 0.0, 1.0);
		float rim_amount = empty * world_rim_strength * smoothstep(0.12, 0.4, luma) * RIM_AMOUNT;
		c = mix(c, c * world_rim_color.rgb * RIM_GAIN, rim_amount);
	}
	vec4 base = vec4(c, t.a) * modulate_color;
	COLOR = vec4(mix(base.rgb, tint.rgb, amount), base.a);
}
