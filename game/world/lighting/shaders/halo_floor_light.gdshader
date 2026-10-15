// Lueur du halo au sol (HaloFloorLight, J17 T25) : le halo du joueur n'assombrit pas seulement
// autour de lui, il éclaire le sol dedans. Ajout (blend_add) sous les personnages, mêmes
// rayons et même profil que le trou du voile (darkness_veil.gdshader : 1 - smoothstep).
// Sans lecture de l'écran ; coordonnées du monde, indépendant de la caméra.
shader_type canvas_item;
render_mode unshaded, blend_add;

uniform vec3 glow_color : source_color = vec3(0.80, 0.90, 1.0);
uniform vec2 center = vec2(0.0);
uniform float clear_radius = 240.0;
uniform float fade_radius = 384.0;
// Force de l'éclaircissement au centre (0..1, ajoutée à la couleur du sol).
uniform float strength = 0.07;

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float lit = 1.0 - smoothstep(clear_radius, fade_radius, distance(world, center));
	COLOR = vec4(glow_color, strength * lit);
}
