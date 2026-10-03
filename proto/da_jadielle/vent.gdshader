// Balancement du feuillage : le haut du sprite se décale, le pied reste fixe.
shader_type canvas_item;

uniform float force = 5.0;
uniform float vitesse = 1.1;

void vertex() {
	float hauteur = 1.0 - UV.y;
	float phase = MODEL_MATRIX[3].x * 0.013;
	VERTEX.x += sin(TIME * vitesse + phase) * force * hauteur * hauteur;
}
