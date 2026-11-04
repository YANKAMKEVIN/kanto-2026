// Eau vive d'un décor (grotte marine, Chapitre Johto) : la texture du sprite (répétée) défile par
// TIME, aucun _process côté script, et s'efface sur les bords de son rectangle. Purement visuel :
// la logique des courants reste celle de la grille. Sprite à région : UV va de 0 à `extent`.
shader_type canvas_item;

// Défilement, en répétitions de texture par seconde.
uniform vec2 flow = vec2(0.0, -0.3);
// Taille de la région en répétitions de texture (0..1 = tout le rectangle après division).
uniform vec2 extent = vec2(1.0, 1.0);
// Part du rectangle qui s'efface à chaque bord : gauche, droite, haut, bas.
uniform vec4 fade = vec4(0.1, 0.1, 0.1, 0.1);
uniform float strength = 0.8;

void fragment() {
	vec2 p = UV / extent;
	float edge = smoothstep(0.0, max(fade.x, 0.001), p.x)
		* (1.0 - smoothstep(1.0 - max(fade.y, 0.001), 1.0, p.x))
		* smoothstep(0.0, max(fade.z, 0.001), p.y)
		* (1.0 - smoothstep(1.0 - max(fade.w, 0.001), 1.0, p.y));
	vec4 water = texture(TEXTURE, UV + flow * TIME);
	COLOR = vec4(water.rgb * COLOR.rgb, strength * edge * COLOR.a);
}
