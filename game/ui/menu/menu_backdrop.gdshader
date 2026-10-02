shader_type canvas_item;
// Fond du Menu Dresseur : le monde derrière, flouté (9 prises sur les mipmaps de l'écran) et
// assombri. `amount` va de 0 (monde net) à 1 (flou et voile complets) ; les valeurs viennent de
// UiTokens (MENU_BLUR_*, MENU_DIM, SURFACE_DARK), posées par TrainerMenu.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform float blur_radius = 5.0;
uniform float blur_lod = 1.5;
uniform float dim = 0.5;
uniform vec4 dim_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * blur_radius * amount;
	float lod = blur_lod * amount;
	vec3 sum = textureLod(screen_tex, SCREEN_UV, lod).rgb * 4.0;
	sum += textureLod(screen_tex, SCREEN_UV + vec2(px.x, 0.0), lod).rgb * 2.0;
	sum += textureLod(screen_tex, SCREEN_UV - vec2(px.x, 0.0), lod).rgb * 2.0;
	sum += textureLod(screen_tex, SCREEN_UV + vec2(0.0, px.y), lod).rgb * 2.0;
	sum += textureLod(screen_tex, SCREEN_UV - vec2(0.0, px.y), lod).rgb * 2.0;
	sum += textureLod(screen_tex, SCREEN_UV + px, lod).rgb;
	sum += textureLod(screen_tex, SCREEN_UV - px, lod).rgb;
	sum += textureLod(screen_tex, SCREEN_UV + vec2(px.x, -px.y), lod).rgb;
	sum += textureLod(screen_tex, SCREEN_UV + vec2(-px.x, px.y), lod).rgb;
	vec3 blurred = sum / 16.0;
	COLOR = vec4(mix(blurred, dim_color.rgb, dim * amount), 1.0);
}
