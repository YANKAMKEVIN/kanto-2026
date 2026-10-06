shader_type canvas_item;
// Coins arrondis pour tout ce qu'un Control dessine (carte d'habitat du Pokédex, refonte T4) :
// la position locale de chaque sommet sert de repère, le masque est une boîte arrondie de
// rect_size. Rien d'autre ne change (couleur et texture des tracés gardées).

uniform vec2 rect_size = vec2(100.0, 100.0);
uniform float radius = 16.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

float rounded_box(vec2 p, vec2 half_size, float r) {
	vec2 q = abs(p) - half_size + vec2(r);
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	float d = rounded_box(local_position - rect_size * 0.5, rect_size * 0.5, radius);
	COLOR.a *= 1.0 - smoothstep(-0.75, 0.75, d);
}
