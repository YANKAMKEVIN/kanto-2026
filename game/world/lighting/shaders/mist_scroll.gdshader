// Brume lente de la Tour Pokémon (MistLayer, jalon 19 T19). Une texture de bruit qui se répète,
// lue deux fois à deux échelles et dans deux sens, décalée par TIME : aucun _process côté script.
// Mélange normal (jamais additif) : la brume voile sans éclairer. L'alpha final = bruit × alpha
// du sprite (≤ MistLayer.ALPHA_MAX).
shader_type canvas_item;

uniform sampler2D mist : repeat_enable, filter_linear;
uniform vec3 tint : source_color = vec3(0.78, 0.74, 0.9);
uniform vec2 drift_a = vec2(0.006, 0.002);
uniform vec2 drift_b = vec2(-0.004, 0.0025);

void fragment() {
	float a = texture(mist, UV + drift_a * TIME).r;
	float b = texture(mist, UV * 0.6 + vec2(0.37, 0.61) + drift_b * TIME).r;
	float cloud = smoothstep(0.25, 0.85, a * 0.6 + b * 0.55);
	COLOR = vec4(tint, cloud * COLOR.a);
}
