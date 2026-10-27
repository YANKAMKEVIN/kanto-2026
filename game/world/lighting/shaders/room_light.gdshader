// Lumière de pièce des intérieurs (DAF.6, « vraie DA » des références `chambre-joueur-v1`,
// `labo-chen-v1`, `centre-pokemon-v1`) : pénombre au pourtour de la pièce et flaque de lumière
// chaude venue des fenêtres du mur nord, étirée dans le sens du soleil. Un seul rectangle de la
// taille de la pièce, en mélange normal, **sans lecture de l'écran ni texture** (une passe
// légère, perf A17). Posé par RoomLight au-dessus des personnages et des meubles.
shader_type canvas_item;

// Taille de la pièce (px) ; le rectangle est dessiné de (0, 0) à room_size.
uniform vec2 room_size = vec2(960.0, 960.0);
// Pénombre : couleur et opacité au bord, largeur (px) ; le mur sud (devant) pèse front_weight.
uniform vec4 edge_color : source_color = vec4(0.1, 0.06, 0.04, 1.0);
uniform float edge_alpha = 0.0;
uniform float edge_width = 192.0;
uniform float front_weight = 0.6;
// Flaque : couleur et opacité au centre, centre (fraction de la pièce), rayon (fraction de la
// hauteur de la pièce), direction du soleil (vers où la lumière s'étire).
uniform vec4 pool_color : source_color = vec4(1.0, 0.77, 0.48, 1.0);
uniform float pool_alpha = 0.0;
uniform vec2 pool_center = vec2(0.4, 0.3);
uniform float pool_radius = 0.6;
uniform vec2 sun_dir = vec2(0.7071, 0.7071);

varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec2 p = local;
	float side = min(p.x, room_size.x - p.x);
	float top = p.y;
	float front = (room_size.y - p.y) / max(front_weight, 0.001);
	float d = min(side, min(top, front));
	float edge = 1.0 - smoothstep(0.0, edge_width, d);
	edge = edge * edge * edge_alpha;
	vec2 q = (p - pool_center * room_size) / max(pool_radius * room_size.y, 1.0);
	vec2 along = normalize(sun_dir);
	vec2 across = vec2(-along.y, along.x);
	float r = length(vec2(dot(q, along) * 0.65, dot(q, across)));
	float pool = (1.0 - smoothstep(0.0, 1.0, r)) * pool_alpha * (1.0 - edge);
	float a = 1.0 - (1.0 - edge) * (1.0 - pool);
	vec3 c = (edge_color.rgb * edge + pool_color.rgb * pool) / max(edge + pool, 0.0001);
	COLOR = vec4(c, a);
}
