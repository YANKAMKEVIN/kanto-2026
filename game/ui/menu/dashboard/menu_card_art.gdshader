shader_type canvas_item;
// Illustration d'une grande carte du tableau de bord (MM.1) : couvre le rectangle du nœud sans
// déformation (rognée autour de focus), coins arrondis, et dégradé vers la teinte de la carte
// dans le bas (le titre et la légende se lisent dessus). Un seul tracé, aucune lecture en plus.

uniform vec2 rect_size = vec2(400.0, 300.0);
uniform vec2 texture_size = vec2(640.0, 427.0);
uniform vec2 focus = vec2(0.5, 0.2);
uniform float radius = 24.0;
uniform vec4 fade_color : source_color = vec4(0.1, 0.1, 0.15, 0.96);
uniform float fade_from = 0.38;

// COLOR vaut déjà « modulate × texture » dans fragment() : le modulate est relevé ici.
varying vec4 modulate;

void vertex() {
	modulate = COLOR;
}

void fragment() {
	float rect_aspect = rect_size.x / max(rect_size.y, 1.0);
	float tex_aspect = texture_size.x / max(texture_size.y, 1.0);
	vec2 scale = vec2(1.0);
	if (rect_aspect > tex_aspect) {
		scale.y = tex_aspect / rect_aspect;
	} else {
		scale.x = rect_aspect / tex_aspect;
	}
	vec2 offset = (vec2(1.0) - scale) * focus;
	vec4 color = texture(TEXTURE, offset + UV * scale);
	float t = smoothstep(fade_from, 1.0, UV.y);
	color.rgb = mix(color.rgb, fade_color.rgb, t * fade_color.a);
	vec2 p = UV * rect_size;
	vec2 q = abs(p - rect_size * 0.5) - (rect_size * 0.5 - vec2(radius));
	float d = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
	color.a *= clamp(0.5 - d, 0.0, 1.0);
	COLOR = color * modulate;
}
