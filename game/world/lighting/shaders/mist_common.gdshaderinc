// Calcul de la brume de la Tour (MistLayer), partagé par mist_scroll.gdshader (calque de brume)
// et baked_ground_mist.gdshader (sol cuit qui porte la brume, J21) : mêmes lectures, mêmes
// dérives, mêmes seuils. uv : coordonnées de la texture de bruit (1 = 512 px).
const vec3 MIST_TINT = vec3(0.78, 0.74, 0.9);
const vec2 MIST_DRIFT_A = vec2(0.006, 0.002);
const vec2 MIST_DRIFT_B = vec2(-0.004, 0.0025);

float mist_cloud(sampler2D noise, vec2 uv, float time) {
	float a = texture(noise, uv + MIST_DRIFT_A * time).r;
	float b = texture(noise, uv * 0.6 + vec2(0.37, 0.61) + MIST_DRIFT_B * time).r;
	return smoothstep(0.25, 0.85, a * 0.6 + b * 0.55);
}
