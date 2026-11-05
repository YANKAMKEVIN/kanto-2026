shader_type canvas_item;
// Souvenir (JOH6) : sépia plein écran et bord adouci. `amount` : 0 = image normale, 1 = sépia.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float vignette : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float grey = dot(color, vec3(0.299, 0.587, 0.114));
	vec3 sepia = vec3(grey * 1.07, grey * 0.88, grey * 0.64) + vec3(0.05, 0.02, 0.0);
	// Bord adouci : assombri et voilé vers le papier jauni.
	vec2 centered = SCREEN_UV - vec2(0.5);
	float edge = smoothstep(0.32, 0.75, length(centered * vec2(1.0, 1.25)));
	sepia = mix(sepia, vec3(0.42, 0.33, 0.22), edge * vignette);
	COLOR = vec4(mix(color, sepia, amount), 1.0);
}
