// Silhouette d'une espèce inconnue du Pokédex (refonte, décision D2 de Kevin) : seule la forme
// (l'alpha de l'image) est tracée, dans la teinte [tint] ; couleurs, traits et yeux jamais.
// Le modulate du nœud (couleur des sommets : fondus, estompage) s'applique toujours.
// Attention : dans fragment(), COLOR vaut déjà « modulate × texture » ; le multiplier ferait
// réapparaître les couleurs et les traits de l'artwork (corrigé au T4). Le modulate est donc
// relevé dans vertex(), avant le mélange avec la texture.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.05, 0.07, 0.10, 0.88);

varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	COLOR = vec4(tint.rgb, tint.a * texture(TEXTURE, UV).a) * modulate;
}
