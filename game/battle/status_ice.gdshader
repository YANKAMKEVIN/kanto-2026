shader_type canvas_item;
// Gel (jalon 11, T7) : copie du sprite posée par-dessus (StatusAura), recolorée en bleu glacé
// d'après sa luminance (un simple mélange tourne au gris sur un Pokémon orange), transparence
// gardée. Jamais sur le sprite lui-même : l'artwork officiel garde son matériau étalonné.
uniform vec4 tint : source_color = vec4(0.37, 0.72, 0.94, 1.0);
uniform float amount : hint_range(0.0, 1.0) = 0.7;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	float lum = dot(base.rgb, vec3(0.3, 0.59, 0.11));
	vec3 ice = tint.rgb * (0.55 + 0.75 * lum);
	COLOR = vec4(mix(base.rgb, ice, amount), base.a);
}
