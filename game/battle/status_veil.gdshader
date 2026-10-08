shader_type canvas_item;
// Voile du poison (jalon 9, T5) : fond la couleur du sprite vers une teinte violette, sans
// toucher à la transparence (le modulate multiplie : un voile violet tournerait au rouge sur
// Salamèche). Posé sur un seul sprite pendant 0,35 s, jamais sur tout l'écran.
uniform vec4 tint : source_color = vec4(0.7, 0.3, 0.8, 1.0);
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(base.rgb, tint.rgb, amount), base.a);
}
