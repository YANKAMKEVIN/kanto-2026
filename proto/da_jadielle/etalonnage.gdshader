// Étalonnage d'écran de la lumière « golden hour » (méthode C : assets neutres, lumière
// portée par Godot). Ce n'est pas un voile jaune : chaque zone de luminance reçoit son propre
// gain, mesuré sur les paires d'assets GH / NE de la série 01 (référence A) :
// ombres relevées et réchauffées, tons moyens chauds, hautes lumières dorées (bleu retiré).
shader_type canvas_item;

uniform sampler2D ecran : hint_screen_texture, filter_linear;
uniform vec3 gain_ombres = vec3(1.16, 1.07, 0.97);
uniform vec3 gain_moyens = vec3(1.06, 1.01, 0.91);
uniform vec3 gain_lumieres = vec3(1.01, 0.97, 0.85);
uniform float intensite : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec3 c = texture(ecran, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	// Les contours très sombres restent neutres (lisibilité).
	float contour = smoothstep(0.04, 0.14, l);
	vec3 gain = mix(gain_ombres, gain_moyens, smoothstep(0.15, 0.45, l));
	gain = mix(gain, gain_lumieres, smoothstep(0.50, 0.85, l));
	gain = mix(vec3(1.0), gain, contour * intensite);
	COLOR = vec4(clamp(c * gain, 0.0, 1.0), 1.0);
}
