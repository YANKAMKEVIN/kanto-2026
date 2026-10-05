// Fond peint du Plateau Indigo (Route 22) : bords droit et bas fondus dans la forêt et le sol,
// pour qu'il n'y ait pas de raccord net. Repris du prototype (proto_route22.gd). L'image est
// rognée (`region_rect` du Sprite2D) : `region` = (début x, début y, largeur, hauteur) de la
// rognure en UV de la texture, pour que les fondus suivent les bords de la rognure.
shader_type canvas_item;

uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 local = (UV - region.xy) / region.zw;
	c.a *= 1.0 - smoothstep(0.86, 1.0, local.x);
	c.a *= 1.0 - smoothstep(0.88, 1.0, local.y);
	COLOR = c;
}
