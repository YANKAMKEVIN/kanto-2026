// Silhouette d'une espèce inconnue du Pokédex (refonte, décision D2 de Kevin) : seule la forme
// (l'alpha de l'image) est tracée, dans la teinte [tint] ; couleurs, traits et yeux jamais.
// Le modulate du nœud (COLOR en entrée : fondus, estompage) s'applique toujours.
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.05, 0.07, 0.10, 0.88);

void fragment() {
	COLOR = vec4(tint.rgb, tint.a * texture(TEXTURE, UV).a) * COLOR;
}
