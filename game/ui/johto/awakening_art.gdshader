shader_type canvas_item;
// Le Réveil (JOHP0) : le Pokémon passe de la silhouette de lumière aux couleurs.
// `white` : 0 = couleurs, 1 = silhouette teintée par `tint`.

uniform float white : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	COLOR = vec4(mix(color.rgb, tint.rgb, white), color.a) * COLOR;
}
