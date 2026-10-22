// Sol cuit (PaintedGround.bake, J21) qui porte la brume de la Tour : une seule passe opaque au
// lieu du sol puis du calque de brume par-dessus (QA A17, Mali-G57 : chaque calque plein écran
// coûte plusieurs i/s). Même résultat que le mélange normal de MistLayer sur le sol :
// mix(sol, teinte, nuage × alpha). mist_alpha = 0 : le sol seul.
shader_type canvas_item;

#include "res://game/world/lighting/shaders/mist_common.gdshaderinc"

uniform sampler2D mist : repeat_enable, filter_linear;
uniform float mist_alpha = 0.0;
// Taille du sol (px) ; origine de la brume relative au sol (px) ; côté du bruit (px).
uniform vec2 ground_size = vec2(1920.0, 1728.0);
uniform vec2 mist_offset = vec2(0.0);
uniform float mist_texture_size = 512.0;

// Couleur du sommet (modulate, CanvasModulate de l'étalonnage à plat) : appliquée au sol comme à
// la teinte de la brume, comme sur deux calques séparés.
varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	if (mist_alpha > 0.0) {
		vec2 uv = (UV * ground_size - mist_offset) / mist_texture_size;
		c = mix(c, MIST_TINT, mist_cloud(mist, uv, TIME) * mist_alpha);
	}
	COLOR = vec4(c, 1.0) * vertex_color;
}
