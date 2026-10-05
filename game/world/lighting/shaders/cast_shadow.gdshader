// Ombre portée d'un objet peint : la silhouette est pré-floutée, retournée, écrasée, inclinée et
// fondue vers l'extrémité par tools/art/preparer.py (<id>_shadow.png, alpha seul, demi-résolution).
// Une seule lecture par pixel (le prototype, ombre.gdshader, en faisait 25). La couleur et
// l'opacité viennent du profil de lumière (WorldLighting) ; l'écrasement et l'inclinaison sont
// posés une fois sur le nœud (WorldLighting.shadow_transform).
shader_type canvas_item;

global uniform vec4 world_cast_shadow_color;

void fragment() {
	float a = texture(TEXTURE, UV).a;
	COLOR = vec4(world_cast_shadow_color.rgb, world_cast_shadow_color.a * a);
}
