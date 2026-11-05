shader_type canvas_item;
render_mode blend_add;
// Le Réveil (JOHP0, dossier JOH-11 §13.2) : la lumière sort de l'autel en trois couleurs
// (gris de la terre, bleu de la mer, blanc du ciel), trois éventails qui tournent lentement.
// `power` : 0 = rien, 1 = le Sanctuaire est plein de lumière. Additif : l'image dessous reste.

uniform float power : hint_range(0.0, 1.5) = 0.0;
uniform vec2 center = vec2(0.5, 0.46);
uniform float aspect = 1.78;
uniform vec4 earth : source_color = vec4(0.72, 0.66, 0.58, 1.0);
uniform vec4 sea : source_color = vec4(0.25, 0.55, 1.0, 1.0);
uniform vec4 sky : source_color = vec4(1.0, 1.0, 1.0, 1.0);

float lobe(float angle, float at) {
	float c = 0.5 + 0.5 * cos(angle - at);
	return c * c * c;
}

void fragment() {
	vec2 p = (UV - center) * vec2(aspect, 1.0);
	float r = length(p);
	float a = atan(p.y, p.x);
	float t = TIME * 0.11;
	// Trois lobes à 120 degrés : chaque couleur tient son tiers du ciel.
	float we = lobe(a, t);
	float ws = lobe(a, t + 2.094);
	float wk = lobe(a, t + 4.189);
	vec3 tint = (earth.rgb * we + sea.rgb * ws + sky.rgb * wk) / max(we + ws + wk, 0.001);
	// Rayons qui respirent, plus serrés que les lobes.
	float rays = 0.55 + 0.45 * sin(a * 11.0 + TIME * 0.5) * sin(a * 5.0 - TIME * 0.33);
	float reach = 0.25 + power * 1.25;
	float beam = rays * smoothstep(reach, 0.0, r);
	float core = 0.11 / (0.11 + r * r * 9.0);
	float glow = (beam * 0.75 + core) * power;
	// Au plus fort, la lumière emplit tout l'écran.
	float fill = smoothstep(0.7, 1.3, power) * 0.8;
	COLOR = vec4(tint * (glow + fill), 1.0);
}
