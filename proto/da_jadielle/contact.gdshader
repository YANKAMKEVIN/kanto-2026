// Ombre de contact : la base de la silhouette (bas de l'image) étirée vers le bas et floutée.
// Le sprite est posé `etendue` pixels plus bas que l'objet : seule la frange sous la base
// reste visible, l'objet recouvre le reste. Elle épouse la vraie forme de la base.
shader_type canvas_item;

uniform vec4 couleur : source_color = vec4(0.12, 0.10, 0.20, 0.62);
uniform float etendue = 22.0; // pixels de texture
uniform float part_base = 0.12; // part basse de l'objet prise en compte

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	float total = 0.0;
	for (int i = 0; i < 12; i++) {
		float dy = etendue * (float(i) + 0.5) / 12.0;
		float poids = 1.0 - dy / etendue;
		for (int j = -2; j <= 2; j++) {
			vec2 uv = UV + vec2(float(j) * 3.0 * px.x, -dy * px.y);
			if (uv.y < 1.0 - part_base || uv.y > 1.0 || uv.x < 0.0 || uv.x > 1.0) {
				continue;
			}
			total += texture(TEXTURE, uv).a * poids;
		}
	}
	float a = clamp(total / 5.0 / 3.0, 0.0, 1.0);
	COLOR = vec4(couleur.rgb, couleur.a * a);
}
