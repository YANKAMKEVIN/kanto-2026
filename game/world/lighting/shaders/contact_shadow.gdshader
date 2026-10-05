// Ombre de contact : la base de la silhouette étirée vers le bas et floutée, pré-calculée par
// tools/art/preparer.py (<id>_contact.png, alpha seul, demi-résolution). Une lecture par pixel
// (le prototype, contact.gdshader, en faisait 60). Couleur et opacité : profil de lumière.
shader_type canvas_item;

global uniform vec4 world_contact_color;

void fragment() {
	float a = texture(TEXTURE, UV).a;
	COLOR = vec4(world_contact_color.rgb, world_contact_color.a * a);
}
