// Sol peint d'une carte : herbe, pavés et chemin de terre mélangés par un masque de cases
// (1 pixel = 1 case ; R = pavés, G = chemin) dont la frontière est rendue irrégulière par du
// bruit, avec une fine bande de terre. Repris de proto/da_jadielle/sol.gdshader (mêmes bruits,
// mêmes seuils) ; le chemin est le second canal (la Route 22 du prototype le mettait à la
// place des pavés). Le TileMapLayer `Ground` reste dans la carte, invisible : il porte la
// logique (solide, herbes hautes, rebords), ce sol ne fait qu'afficher.
// Rivage (DA.2, facultatif : has_shore) : second masque (R sable, G eau) ; sable puis mer par
// dessus, frange d'écume claire au bord de l'eau, eau qui ondule doucement (repris de
// proto/da_jadielle/sol_bourg.gdshader, mêmes seuils).
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

void fragment() {
	vec2 cells = vec2(textureSize(ground_mask, 0));
	vec2 m = texture(ground_mask, world / tile_size / cells).rg;
	float n = (noise(world * 0.02) - 0.5) * 0.30 + (noise(world * 0.09) - 0.5) * 0.14;
	float v_paving = m.r + n;
	float v_path = m.g + n;
	float paving = smoothstep(0.49, 0.53, v_paving);
	float path = smoothstep(0.49, 0.53, v_path);
	float band = max(earth_band(v_paving), earth_band(v_path));
	vec3 c = texture(grass_texture, world / texture_size).rgb;
	c = mix(c, texture(path_texture, world / (texture_size * path_scale)).rgb, path);
	c = mix(c, texture(paving_texture, world / (texture_size * paving_scale)).rgb, paving);
	vec3 earth = earth_color.rgb * (0.85 + 0.3 * noise(world * 0.25));
	c = mix(c, earth, band * 0.75);
	if (has_shore) {
		vec2 s = texture(shore_mask, world / tile_size / cells).rg;
		float v_sand = s.r + n * 0.6;
		c = mix(c, texture(sand_texture, world / texture_size).rgb, smoothstep(0.45, 0.55, v_sand));
		float v_water = s.g + n * 0.5
			+ (noise(world * 0.03 + vec2(TIME * 0.15, 0.0)) - 0.5) * 0.08;
		vec2 swell = vec2(sin(TIME * 0.4 + world.y * 0.01), cos(TIME * 0.3 + world.x * 0.008))
			* 6.0;
		vec3 water = texture(water_texture, (world + swell) / (texture_size * 1.5)).rgb;
		float foam = smoothstep(0.42, 0.5, v_water) * (1.0 - smoothstep(0.5, 0.62, v_water));
		c = mix(c, water, smoothstep(0.5, 0.56, v_water));
		c = mix(c, foam_color.rgb, foam * 0.8);
	}
	COLOR = vec4(c, 1.0);
}
