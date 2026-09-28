shader_type canvas_item;
render_mode unshaded;
// Fond de la vue de combat (jalon-04.md §14.4) : le décor réel, légèrement flouté (profondeur
// de champ), assombri par un voile et un vignettage. `amount` va de 0 (exploration, image
// intacte) à 1 (combat). Le flou lit les mipmaps de la copie de l'écran (peu coûteux) ;
// `blur_lod = 0` le coupe.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 veil_color = vec3(0.02, 0.03, 0.05);
uniform float veil : hint_range(0.0, 1.0) = 0.2;
uniform float blur_lod : hint_range(0.0, 4.0) = 1.0;
uniform float blur_radius = 1.5;
uniform float vignette : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	float lod = blur_lod * amount;
	vec3 color = textureLod(screen_tex, SCREEN_UV, lod).rgb;
	if (lod > 0.01) {
		vec2 px = SCREEN_PIXEL_SIZE * blur_radius * exp2(lod);
		color += textureLod(screen_tex, SCREEN_UV + vec2(px.x, px.y), lod).rgb;
		color += textureLod(screen_tex, SCREEN_UV + vec2(-px.x, px.y), lod).rgb;
		color += textureLod(screen_tex, SCREEN_UV + vec2(px.x, -px.y), lod).rgb;
		color += textureLod(screen_tex, SCREEN_UV + vec2(-px.x, -px.y), lod).rgb;
		color /= 5.0;
	}
	color = mix(color, veil_color, veil * amount);
	vec2 d = (SCREEN_UV - vec2(0.5)) * vec2(1.0, 1.3);
	float edge = smoothstep(0.38, 0.9, length(d));
	color = mix(color, veil_color, edge * vignette * amount);
	COLOR = vec4(color, 1.0);
}
