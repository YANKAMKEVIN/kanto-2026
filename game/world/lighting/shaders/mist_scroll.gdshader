// Brume lente de la Tour Pokémon (MistLayer, jalon 19 T19). Une texture de bruit qui se répète,
// lue deux fois à deux échelles et dans deux sens, décalée par TIME : aucun _process côté script.
// Mélange normal (jamais additif) : la brume voile sans éclairer. L'alpha final = bruit × alpha
// du sprite (≤ MistLayer.ALPHA_MAX). Calcul partagé avec le sol cuit (mist_common.gdshaderinc).
shader_type canvas_item;

#include "res://game/world/lighting/shaders/mist_common.gdshaderinc"

uniform sampler2D mist : repeat_enable, filter_linear;

void fragment() {
	COLOR = vec4(MIST_TINT, mist_cloud(mist, UV, TIME) * COLOR.a);
}
