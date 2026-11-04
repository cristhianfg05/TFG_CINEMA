shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D poster_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform float wear_strength : hint_range(0.0, 1.0) = 0.65;

float grain(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec3 print_color = texture(poster_texture, UV).rgb;
	float border = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float broad_dirt = grain(floor(UV * 17.0));
	float edge_wear = (1.0 - smoothstep(0.015, 0.15, border)) * (0.45 + broad_dirt * 0.55);
	float freckles = step(0.965, grain(floor(UV * 570.0)));
	float stains = step(0.84, grain(floor(UV * 31.0))) * (0.25 + edge_wear * 0.75);
	float paper_variation = grain(floor(UV * 94.0)) - 0.5;
	vec3 aged = print_color * vec3(1.045, 1.015, 0.92);
	aged *= 1.0 - wear_strength * (edge_wear * 0.58 + freckles * 0.38 + stains * 0.18);
	aged += paper_variation * wear_strength * 0.025;
	ALBEDO = mix(print_color, aged, 0.9);
}
