shader_type canvas_item;
// Intégration d'un artwork officiel dans le décor peint (prototype) : le trait noir est
// rapproché d'une teinte sombre colorée (comme le contour du monde, jamais noir), les couleurs
// très légèrement réchauffées et adoucies. `strength` = 0 : artwork intact.

uniform float strength : hint_range(0.0, 1.0) = 1.0;
// Teinte des traits sombres (brun-violet profond du monde).
uniform vec3 line_tint = vec3(0.20, 0.13, 0.17);
// Seuil de luminance sous lequel un pixel compte comme trait.
uniform float line_threshold : hint_range(0.0, 0.5) = 0.22;
uniform float line_mix : hint_range(0.0, 1.0) = 0.65;
// Réchauffement et désaturation légère des aplats.
uniform vec3 warm = vec3(1.03, 1.0, 0.95);
uniform float soften : hint_range(0.0, 0.3) = 0.06;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float luma = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float line = 1.0 - smoothstep(0.0, line_threshold, luma);
	vec3 graded = mix(c.rgb, line_tint + c.rgb * 0.5, line * line_mix);
	graded = mix(graded, vec3(luma), soften) * warm;
	COLOR = vec4(mix(c.rgb, graded, strength), c.a);
}
