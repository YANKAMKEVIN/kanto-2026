// Sol peint d'une carte : herbe, pavés et chemin de terre mélangés par un masque de cases
// (1 pixel = 1 case ; R = pavés, G = chemin) dont la frontière est rendue irrégulière par du
// bruit, avec une fine bande de terre. Repris de proto/da_jadielle/sol.gdshader (mêmes bruits,
// mêmes seuils) ; le chemin est le second canal (la Route 22 du prototype le mettait à la
// place des pavés). Le TileMapLayer `Ground` reste dans la carte, invisible : il porte la
// logique (solide, herbes hautes, rebords), ce sol ne fait qu'afficher.
// Rivage (DA.2, facultatif : has_shore) : second masque (R sable, G eau) ; sable puis mer par
// dessus, frange d'écume claire au bord de l'eau, eau qui ondule doucement (repris de
// proto/da_jadielle/sol_bourg.gdshader, mêmes seuils).
// Eau réglable (jalon 13 T6) : water_texture choisie par la carte (PaintedGround), à sa propre
// échelle (water_texture_size) ; force de l'écume (foam_strength, 0,8 = la mer de
// Bourg Palette) ; rivage à angles droits (square_shore : l'eau couvre exactement ses cases, sans
// bruit ni frange ; canaux d'Azuria, dont les bords sont des quais posés par-dessus).
// Défauts = rendu d'avant le J13.
// Passes (moteur commun, perf A17) : pass_mode 0 = tout (défaut, rendu d'avant) ; 1 = la terre
// seule (sol cuit par morceaux, GroundChunks : tout sauf l'eau, qui dépend du temps) ; 2 = l'eau
// seule (calque animé GroundWater, posé sur la terre cuite) : eau et écume avec un alpha tel que
// le mélange normal sur la terre redonne exactement le mix() de la passe 0.
shader_type canvas_item;

uniform sampler2D grass_texture : repeat_enable, filter_linear_mipmap;
uniform sampler2D paving_texture : repeat_enable, filter_linear_mipmap;
uniform sampler2D path_texture : repeat_enable, filter_linear_mipmap;
uniform sampler2D ground_mask : filter_linear;
uniform float tile_size = 96.0;
// Côté d'une texture de sol, en pixels (384 = 4 × 4 cases).
uniform float texture_size = 384.0;
uniform float paving_scale = 0.7;
uniform float path_scale = 0.7;
uniform vec4 earth_color : source_color = vec4(0.54, 0.42, 0.29, 1.0);
uniform bool has_shore = false;
uniform sampler2D shore_mask : filter_linear;
uniform sampler2D sand_texture : repeat_enable, filter_linear_mipmap;
uniform sampler2D water_texture : repeat_enable, filter_linear_mipmap;
uniform vec4 foam_color : source_color = vec4(0.95, 0.97, 0.98, 1.0);
// Côté de la texture d'eau, en pixels (réglé par PaintedGround pour une eau autre que la mer).
uniform float water_texture_size = 384.0;
uniform float foam_strength = 0.8;
uniform bool square_shore = false;
uniform int pass_mode = 0;

varying vec2 world;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Fine bande de terre autour de la frontière (v = masque + bruit).
float earth_band(float v) {
	return smoothstep(0.40, 0.48, v) * (1.0 - smoothstep(0.51, 0.57, v));
}

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

// Eau et écume au-dessus de la terre (passe 2), en couleur et alpha pour un mélange normal :
// terre × (1 − a) + eau × a puis écume par-dessus, comme les deux mix() de la passe 0.
vec4 water_layer(vec2 cells, vec2 p, float time) {
	vec2 s = texture(shore_mask, p / tile_size / cells).rg;
	float v_water;
	if (square_shore) {
		ivec2 cell = clamp(ivec2(floor(p / tile_size)), ivec2(0), ivec2(cells) - 1);
		v_water = texelFetch(shore_mask, cell, 0).g;
	} else if (s.g >= 0.78) {
		// Le bruit déplace v_water d'au plus ± 0,15 : au large, ni frange ni écume.
		v_water = 1.0;
	} else if (s.g <= 0.27) {
		// Sur la terre : ni eau ni écume.
		return vec4(0.0);
	} else {
		float n = (noise(p * 0.02) - 0.5) * 0.30 + (noise(p * 0.09) - 0.5) * 0.14;
		v_water = s.g + n * 0.5 + (noise(p * 0.03 + vec2(time * 0.15, 0.0)) - 0.5) * 0.08;
	}
	float a_water = smoothstep(0.5, 0.56, v_water);
	float foam = smoothstep(0.42, 0.5, v_water) * (1.0 - smoothstep(0.5, 0.62, v_water));
	float a_foam = foam * foam_strength;
	float alpha = 1.0 - (1.0 - a_water) * (1.0 - a_foam);
	if (alpha <= 0.0) {
		return vec4(0.0);
	}
	vec2 swell = vec2(sin(time * 0.4 + p.y * 0.01), cos(time * 0.3 + p.x * 0.008)) * 6.0;
	vec3 water = texture(water_texture, (p + swell) / (water_texture_size * 1.5)).rgb;
	vec3 premultiplied = water * a_water * (1.0 - a_foam) + foam_color.rgb * a_foam;
	return vec4(premultiplied / alpha, alpha);
}

// Sol de la passe 0 (eau comprise) ou de la passe 1 (sans l'eau ni l'écume).
vec3 ground_color(vec2 cells, vec2 p, float time) {
	vec2 m = texture(ground_mask, p / tile_size / cells).rg;
	float n = (noise(p * 0.02) - 0.5) * 0.30 + (noise(p * 0.09) - 0.5) * 0.14;
	float v_paving = m.r + n;
	float v_path = m.g + n;
	float paving = smoothstep(0.49, 0.53, v_paving);
	float path = smoothstep(0.49, 0.53, v_path);
	float band = max(earth_band(v_paving), earth_band(v_path));
	vec3 c = texture(grass_texture, p / texture_size).rgb;
	c = mix(c, texture(path_texture, p / (texture_size * path_scale)).rgb, path);
	c = mix(c, texture(paving_texture, p / (texture_size * paving_scale)).rgb, paving);
	vec3 earth = earth_color.rgb * (0.85 + 0.3 * noise(p * 0.25));
	c = mix(c, earth, band * 0.75);
	if (has_shore) {
		vec2 s = texture(shore_mask, p / tile_size / cells).rg;
		float v_sand = s.r + n * 0.6;
		c = mix(c, texture(sand_texture, p / texture_size).rgb, smoothstep(0.45, 0.55, v_sand));
		if (pass_mode == 0) {
			float v_water = s.g + n * 0.5
				+ (noise(p * 0.03 + vec2(time * 0.15, 0.0)) - 0.5) * 0.08;
			if (square_shore) {
				ivec2 cell = clamp(ivec2(floor(p / tile_size)), ivec2(0), ivec2(cells) - 1);
				v_water = texelFetch(shore_mask, cell, 0).g;
			}
			vec2 swell = vec2(sin(time * 0.4 + p.y * 0.01), cos(time * 0.3 + p.x * 0.008))
				* 6.0;
			// Période de l'eau = sa propre taille × 1,5 (mer de 384 px : 576, comme avant le J13).
			vec3 water = texture(water_texture, (p + swell) / (water_texture_size * 1.5)).rgb;
			float foam = smoothstep(0.42, 0.5, v_water) * (1.0 - smoothstep(0.5, 0.62, v_water));
			c = mix(c, water, smoothstep(0.5, 0.56, v_water));
			c = mix(c, foam_color.rgb, foam * foam_strength);
		}
	}
	return c;
}

void fragment() {
	vec2 cells = vec2(textureSize(ground_mask, 0));
	if (pass_mode == 2) {
		COLOR = water_layer(cells, world, TIME);
	} else {
		COLOR = vec4(ground_color(cells, world, TIME), 1.0);
	}
}
