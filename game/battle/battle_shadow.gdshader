// Ombre au sol d'un Pokémon en combat (CB.1) : ellipse douce (texture dégradée radiale), de la
// couleur de l'ombre de contact du lieu (« global uniform » de WorldLighting) ; profil sans
// ombre de contact : `fallback`. Respecte le modulate (fondus des animations).
shader_type canvas_item;

global uniform vec4 world_contact_color;

uniform vec4 fallback : source_color = vec4(0.06, 0.08, 0.05, 0.45);
// Opacité de l'ombre de contact du lieu reprise ici (elle est forte sous les objets du monde).
uniform float contact_gain = 0.7;

varying vec4 modulate_color;

void vertex() {
	// Couleur du sommet = modulate (fondus et teintes des animations du combat).
	modulate_color = COLOR;
}

void fragment() {
	float a = texture(TEXTURE, UV).a;
	vec4 tint = world_contact_color.a > 0.0
		? vec4(world_contact_color.rgb, world_contact_color.a * contact_gain) : fallback;
	COLOR = vec4(tint.rgb, tint.a * a) * modulate_color;
}
