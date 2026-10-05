// Étalonnage d'écran de la lumière du monde (méthode C : assets neutres, lumière portée par
// Godot). Ce n'est pas un voile coloré : chaque zone de luminance reçoit son propre gain
// (ombres, tons moyens, hautes lumières), mesuré sur les paires d'assets GH / NE de la série 01.
// Repris de proto/da_jadielle/etalonnage.gdshader ; gains en « global uniform » posés par
// WorldLighting. Intensité 0 : le calque est caché (aucun coût).
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

global uniform vec3 world_grade_shadows;
global uniform vec3 world_grade_midtones;
global uniform vec3 world_grade_highlights;
global uniform float world_grade_strength;

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	// Les contours très sombres restent neutres (lisibilité).
	float outline = smoothstep(0.04, 0.14, l);
	vec3 gain = mix(world_grade_shadows, world_grade_midtones, smoothstep(0.15, 0.45, l));
	gain = mix(gain, world_grade_highlights, smoothstep(0.50, 0.85, l));
	gain = mix(vec3(1.0), gain, outline * world_grade_strength);
	COLOR = vec4(clamp(c * gain, 0.0, 1.0), 1.0);
}
